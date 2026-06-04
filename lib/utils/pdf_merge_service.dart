import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../model/pdfFile.dart';
import 'security_utils.dart';

class PdfMergeService {
  static Future<PdfData> merge(List<PdfData> pdfs) async {
    if (pdfs.length < 2) {
      throw ArgumentError('Select at least two PDF files to merge.');
    }

    final output = PdfDocument();
    output.pageSettings.setMargins(0);
    var totalPages = 0;

    try {
      for (final pdf in pdfs) {
        final bytes = await _readDocumentBytes(pdf.documents);
        final source = PdfDocument(inputBytes: bytes);
        try {
          for (final i in _selectedPageIndexes(pdf, source.pages.count)) {
            final sourcePage = source.pages[i];
            final template = sourcePage.createTemplate();
            output.pageSettings.size = sourcePage.size;
            final page = output.pages.add();
            page.graphics.drawPdfTemplate(
              template,
              Offset.zero,
              Size(sourcePage.size.width, sourcePage.size.height),
            );
            totalPages++;
          }
        } finally {
          source.dispose();
        }
      }

      final bytes = await output.save();
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/dittox_merged_$timestamp.pdf');
      await file.writeAsBytes(bytes, flush: true);
      final first = pdfs.first;
      return PdfData(
        id: 'merged_$timestamp',
        name: 'Merged ${pdfs.length} documents.pdf',
        size: _bytesToSize(bytes.length),
        totalPages: totalPages,
        copies: first.copies,
        binding: first.binding,
        paperSize: first.paperSize,
        pdfSides: first.pdfSides,
        pdfPrintLayout: first.pdfPrintLayout,
        color: first.color,
        pageRange: '1-$totalPages',
        colorParDesciption: first.colorParDesciption,
        colorParPageNumbers: first.colorParPageNumbers,
        colorParTotal: first.colorParTotal,
        additionDesciption: _mergedNotes(first.additionDesciption, pdfs.length),
        documents: 'local://${file.path}',
        bondPages: first.bondPages,
        collateCopies: first.collateCopies,
        numberCopies: first.numberCopies,
      );
    } finally {
      output.dispose();
    }
  }

  static Future<List<int>> _readDocumentBytes(String ref) async {
    var value = ref.trim();
    if (value.startsWith('uploaded://')) {
      value = value.replaceFirst('uploaded://', '').trim();
    }
    if (value.startsWith('local://')) {
      value = value.replaceFirst('local://', '').trim();
      return File(value).readAsBytes();
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return File(uri.toFilePath()).readAsBytes();
    }
    if (value.startsWith('/')) {
      return File(value).readAsBytes();
    }
    final safeUri = SecurityUtils.safeWebUri(value, allowHttp: false);
    if (safeUri == null) {
      throw ArgumentError('Unsupported PDF reference.');
    }
    final response =
        await http.get(safeUri).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const HttpException('Failed to download PDF for merge.');
    }
    return response.bodyBytes;
  }

  static String _bytesToSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    return '${(bytes / kb).toStringAsFixed(2)} KB';
  }

  static List<int> _selectedPageIndexes(PdfData pdf, int pageCount) {
    final text = pdf.pageRange.trim();
    if (text.isEmpty) return List.generate(pageCount, (index) => index);

    final selected = <int>{};
    for (final part in text.split(',')) {
      final token = part.trim().replaceAll(' ', '');
      if (token.isEmpty) continue;
      if (token.contains('-')) {
        final pieces = token.split('-');
        if (pieces.length != 2) return List.generate(pageCount, (i) => i);
        final start = int.tryParse(pieces[0]);
        final end = int.tryParse(pieces[1]);
        if (start == null || end == null || start < 1 || end < start) {
          return List.generate(pageCount, (i) => i);
        }
        for (var page = start; page <= end && page <= pageCount; page++) {
          selected.add(page - 1);
        }
      } else {
        final page = int.tryParse(token);
        if (page == null || page < 1 || page > pageCount) {
          return List.generate(pageCount, (i) => i);
        }
        selected.add(page - 1);
      }
    }
    final indexes = selected.toList()..sort();
    return indexes.isEmpty ? List.generate(pageCount, (i) => i) : indexes;
  }

  static String _mergedNotes(String existing, int count) {
    final note = 'Merged from $count documents.';
    final clean = existing.trim();
    if (clean.isEmpty) return note;
    return '$note\n$clean';
  }
}
