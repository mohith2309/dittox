import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../model/pdfFile.dart';
import '../../utils/color_pallets.dart';
import '../../widgets/common/pill_appbar_title.dart';

class PdfPreviewScreen extends StatelessWidget {
  final PdfData pdf;

  const PdfPreviewScreen({
    super.key,
    required this.pdf,
  });

  String _cleanDocumentRef(String ref) {
    var value = ref.trim();
    if (value.startsWith('uploaded://')) {
      value = value.replaceFirst('uploaded://', '').trim();
    }
    if (value.startsWith('local://')) {
      value = value.replaceFirst('local://', '').trim();
    }
    return value;
  }

  Widget _buildViewer() {
    final ref = _cleanDocumentRef(pdf.documents);
    final uri = Uri.tryParse(ref);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return SfPdfViewer.network(ref);
    }
    if (uri != null && uri.scheme == 'file') {
      return SfPdfViewer.file(File(uri.toFilePath()));
    }
    if (ref.startsWith('/')) {
      return SfPdfViewer.file(File(ref));
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Preview unavailable for this document reference.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColorPallets.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PillAppBarTitle(
          title: pdf.name,
          icon: Icons.picture_as_pdf_rounded,
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ColorPallets.deepBlue.withValues(alpha: 0.08),
            child: Text(
              '${pdf.totalPages} page(s) • ${pdf.size} • ${pdf.color}',
              style: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: _buildViewer()),
        ],
      ),
    );
  }
}
