import 'package:dittox/screens/pdf/singlePDfFilter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../model/pdfFile.dart';
import '../../providers/ListOfPdfFiles.dart';
import '../../providers/ListOfShops.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_merge_service.dart';
import '../maps/selectShops.dart';
import 'pdf_preview_screen.dart';

class PDFFilters extends StatefulWidget {
  static const routeName = "/pdffilters";
  const PDFFilters({super.key});

  @override
  State<PDFFilters> createState() => _PDFFiltersState();
}

class _PDFFiltersState extends State<PDFFilters> {
  bool _isMerging = false;

  static const List<String> _paperTypes = <String>[
    'Standard bond',
    'Gloss',
    'Cardstock',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mqs = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqs.height;
    final double totalScreenWidth = mqs.width;
    final NearestShop shopsList =
        Provider.of<NearestShop>(context, listen: false);
    ListOfPDFFiles pdffileList =
        Provider.of<ListOfPDFFiles>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
          foregroundColor: ColorPallets.white,
          title: const Text("Print Settings")),
      body: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: false,
            )),
        margin: EdgeInsets.only(
          // bottom: 40,
          bottom: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 80,
            // heightSpecific: true,
          ),
        ),
        child: ListView.builder(
          itemCount: pdffileList.allPdfList.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _buildUploadEstimateCard(context, pdffileList);
            }
            // return pagesExpanded();
            // return EachPDfCustomizations(
            //     pdffileList.allPdfList[index], context, index);
            final pdf = pdffileList.allPdfList[index - 1];
            return Column(
              children: [
                _buildPreviewHeader(context, pdf, index - 1),
                SinglePageCustomization(
                  index: index - 1,
                ),
              ],
            );
          },
        ),
      ),
      bottomSheet: Container(
        height: 100,
        // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: false,
            )),
        decoration: BoxDecoration(
            color: ColorPallets.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                // 22,
                calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: true,
                ),
              ),
              topRight: Radius.circular(
                // 22,
                calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: true,
                ),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorPallets.lightBlue.withValues(alpha: 0.1),
                blurRadius: 40,
              )
            ]),
        child: InkWell(
          onTap: () {
            shopsList.emptyList();
            Navigator.of(context).pushReplacementNamed(SelectShops.routeName);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  "Proceed to select shop",
                  style: TextStyle(
                    // fontSize: 26,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: true,
                    ),
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                // width: 15,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 30,
                  // heightSpecific: false,
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.arrowRight,
                color: ColorPallets.deepBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mergeAllPdfs(ListOfPDFFiles pdffileList) async {
    if (_isMerging || pdffileList.allPdfList.length < 2) return;
    setState(() => _isMerging = true);
    try {
      final merged = await PdfMergeService.merge(pdffileList.allPdfList);
      if (!mounted) return;
      pdffileList.emptyPDFfile();
      pdffileList.addPDFFile(merged);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Merged into one PDF with ${merged.totalPages} page(s).',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not merge PDFs. Try local, unlocked PDF files.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  Widget _buildUploadEstimateCard(
    BuildContext context,
    ListOfPDFFiles pdffileList,
  ) {
    final pdfs = pdffileList.allPdfList;
    final docs = pdfs.length;
    final totalPages =
        pdfs.fold<int>(0, (sum, pdf) => sum + pdf.selectedPagesCount);
    final totalCopies = pdfs.fold<int>(0, (sum, pdf) => sum + pdf.copies);
    final estimatedCost = pdfs.fold<double>(
      0,
      (sum, pdf) => sum + (pdf.selectedPagesCount * pdf.copies * 2.0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorPallets.deepBlue, ColorPallets.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Upload Estimate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEstimateTile('Docs', docs.toString()),
              _buildEstimateTile('Pages', totalPages.toString()),
              _buildEstimateTile('Copies', totalCopies.toString()),
              _buildEstimateTile(
                  'Est.', CurrencyFormatter.formatCompact(estimatedCost)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Final price may change with color pages, binding, paper type, or shop pricing.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (docs > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isMerging ? null : () => _mergeAllPdfs(pdffileList),
                icon: _isMerging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.merge_type_rounded),
                label: Text(
                    _isMerging ? 'Merging PDFs...' : 'Merge all documents'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateTile(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context, PdfData pdf, int index) {
    final selectedPaperType = _paperTypeFromNotes(pdf.additionDesciption);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: ColorPallets.deepBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ColorPallets.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pdf.totalPages} page(s) • ${pdf.size}',
                    style: const TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSettingChip('${pdf.copies} copy'),
                      _buildSettingChip(pdf.color),
                      _buildSettingChip(pdf.paperSize),
                      _buildSettingChip(pdf.pdfSides),
                      _buildSettingChip(pdf.binding),
                      _buildSettingChip(selectedPaperType),
                      _buildSettingChip('Pages ${pdf.pageRange}'),
                      if (pdf.collateCopies) _buildSettingChip('Collate'),
                      if (pdf.numberCopies) _buildSettingChip('Number copies'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPaperType,
                    decoration: const InputDecoration(
                      labelText: 'Paper type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _paperTypes
                        .map(
                          (paperType) => DropdownMenuItem<String>(
                            value: paperType,
                            child: Text(paperType),
                          ),
                        )
                        .toList(),
                    onChanged: (paperType) {
                      if (paperType == null) return;
                      _updatePaperType(context, pdf, index, paperType);
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Collate copies'),
                    subtitle:
                        const Text('Print 1-2-3, 1-2-3 instead of 1-1, 2-2'),
                    value: pdf.collateCopies,
                    onChanged: (value) => _updateCopyOptions(
                      context,
                      pdf,
                      index,
                      collateCopies: value,
                    ),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Number copies'),
                    subtitle:
                        const Text('Add copy numbering to shop instructions'),
                    value: pdf.numberCopies,
                    onChanged: (value) => _updateCopyOptions(
                      context,
                      pdf,
                      index,
                      numberCopies: value,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(pdf: pdf),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Preview'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _editPageRange(context, pdf, index),
                  icon:
                      const Icon(Icons.format_list_numbered_rounded, size: 18),
                  label: const Text('Range'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _editNotes(context, pdf, index),
                  icon: const Icon(Icons.notes_rounded, size: 18),
                  label: const Text('Notes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPageRange(
    BuildContext context,
    PdfData pdf,
    int index,
  ) async {
    final controller = TextEditingController(text: pdf.pageRange);
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Page Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document has ${pdf.totalPages} page(s).'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Pages to print',
                      hintText: 'Example: 1-3,5,8-10',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final normalized = _normalizePageRange(
                      controller.text,
                      pdf.totalPages,
                    );
                    if (normalized == null) {
                      setDialogState(() {
                        errorText = 'Use pages between 1 and ${pdf.totalPages}';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(normalized);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (result == null || !context.mounted) return;
    _updatePageRange(context, pdf, index, result);
  }

  String? _normalizePageRange(String input, int totalPages) {
    final selected = <int>{};
    for (final part in input.split(',')) {
      final token = part.trim().replaceAll(' ', '');
      if (token.isEmpty) continue;
      if (token.contains('-')) {
        final pieces = token.split('-');
        if (pieces.length != 2) return null;
        final start = int.tryParse(pieces[0]);
        final end = int.tryParse(pieces[1]);
        if (start == null || end == null) return null;
        if (start < 1 || end > totalPages || start > end) return null;
        for (var page = start; page <= end; page++) {
          selected.add(page);
        }
      } else {
        final page = int.tryParse(token);
        if (page == null || page < 1 || page > totalPages) return null;
        selected.add(page);
      }
    }
    if (selected.isEmpty) return null;
    final sorted = selected.toList()..sort();
    final ranges = <String>[];
    var start = sorted.first;
    var previous = sorted.first;
    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if (current == previous + 1) {
        previous = current;
        continue;
      }
      ranges.add(start == previous ? '$start' : '$start-$previous');
      start = current;
      previous = current;
    }
    ranges.add(start == previous ? '$start' : '$start-$previous');
    return ranges.join(',');
  }

  void _updatePageRange(
    BuildContext context,
    PdfData pdf,
    int index,
    String pageRange,
  ) {
    final pdffileList = context.read<ListOfPDFFiles>();
    pdffileList.replacePDFAtIndex(
      index,
      PdfData(
        id: pdf.id,
        name: pdf.name,
        size: pdf.size,
        totalPages: pdf.totalPages,
        copies: pdf.copies,
        binding: pdf.binding,
        paperSize: pdf.paperSize,
        pdfSides: pdf.pdfSides,
        pdfPrintLayout: pdf.pdfPrintLayout,
        color: pdf.color,
        pageRange: pageRange,
        colorParDesciption: pdf.colorParDesciption,
        colorParPageNumbers: pdf.colorParPageNumbers,
        colorParTotal: pdf.colorParTotal,
        additionDesciption: pdf.additionDesciption,
        documents: pdf.documents,
        bondPages: pdf.bondPages,
        collateCopies: pdf.collateCopies,
        numberCopies: pdf.numberCopies,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Page range set to $pageRange')),
    );
  }

  Future<void> _editNotes(BuildContext context, PdfData pdf, int index) async {
    final controller = TextEditingController(
      text: _specialNotesFromNotes(pdf.additionDesciption),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Special Instructions'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Example: staple top-left, print first page separately',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;
    _updateNotes(context, pdf, index, result);
  }

  String _specialNotesFromNotes(String notes) {
    return notes
        .split('\n')
        .where((line) => !line.trim().startsWith('Paper type:'))
        .join('\n')
        .trim();
  }

  void _updateNotes(
      BuildContext context, PdfData pdf, int index, String notes) {
    final pdffileList = context.read<ListOfPDFFiles>();
    final paperType = _paperTypeFromNotes(pdf.additionDesciption);
    pdffileList.replacePDFAtIndex(
      index,
      PdfData(
        id: pdf.id,
        name: pdf.name,
        size: pdf.size,
        totalPages: pdf.totalPages,
        copies: pdf.copies,
        binding: pdf.binding,
        paperSize: pdf.paperSize,
        pdfSides: pdf.pdfSides,
        pdfPrintLayout: pdf.pdfPrintLayout,
        color: pdf.color,
        pageRange: pdf.pageRange,
        colorParDesciption: pdf.colorParDesciption,
        colorParPageNumbers: pdf.colorParPageNumbers,
        colorParTotal: pdf.colorParTotal,
        additionDesciption: _notesWithPaperType(notes, paperType),
        documents: pdf.documents,
        bondPages: pdf.bondPages,
        collateCopies: pdf.collateCopies,
        numberCopies: pdf.numberCopies,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions saved')),
    );
  }

  void _updateCopyOptions(
    BuildContext context,
    PdfData pdf,
    int index, {
    bool? collateCopies,
    bool? numberCopies,
  }) {
    final pdffileList = context.read<ListOfPDFFiles>();
    pdffileList.replacePDFAtIndex(
      index,
      PdfData(
        id: pdf.id,
        name: pdf.name,
        size: pdf.size,
        totalPages: pdf.totalPages,
        copies: pdf.copies,
        binding: pdf.binding,
        paperSize: pdf.paperSize,
        pdfSides: pdf.pdfSides,
        pdfPrintLayout: pdf.pdfPrintLayout,
        color: pdf.color,
        pageRange: pdf.pageRange,
        colorParDesciption: pdf.colorParDesciption,
        colorParPageNumbers: pdf.colorParPageNumbers,
        colorParTotal: pdf.colorParTotal,
        additionDesciption: pdf.additionDesciption,
        documents: pdf.documents,
        bondPages: pdf.bondPages,
        collateCopies: collateCopies ?? pdf.collateCopies,
        numberCopies: numberCopies ?? pdf.numberCopies,
      ),
    );
  }

  Widget _buildSettingChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorPallets.deepBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ColorPallets.deepBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _paperTypeFromNotes(String notes) {
    final match = RegExp(r'Paper type: ([^\n]+)').firstMatch(notes);
    final value = match?.group(1)?.trim();
    if (value != null && _paperTypes.contains(value)) return value;
    return _paperTypes.first;
  }

  String _notesWithPaperType(String notes, String paperType) {
    final clean = notes
        .split('\n')
        .where((line) => !line.trim().startsWith('Paper type:'))
        .join('\n')
        .trim();
    if (clean.isEmpty) return 'Paper type: $paperType';
    return 'Paper type: $paperType\n$clean';
  }

  void _updatePaperType(
    BuildContext context,
    PdfData pdf,
    int index,
    String paperType,
  ) {
    final pdffileList = context.read<ListOfPDFFiles>();
    pdffileList.replacePDFAtIndex(
      index,
      PdfData(
        id: pdf.id,
        name: pdf.name,
        size: pdf.size,
        totalPages: pdf.totalPages,
        copies: pdf.copies,
        binding: pdf.binding,
        paperSize: pdf.paperSize,
        pdfSides: pdf.pdfSides,
        pdfPrintLayout: pdf.pdfPrintLayout,
        color: pdf.color,
        pageRange: pdf.pageRange,
        colorParDesciption: pdf.colorParDesciption,
        colorParPageNumbers: pdf.colorParPageNumbers,
        colorParTotal: pdf.colorParTotal,
        additionDesciption: _notesWithPaperType(
          pdf.additionDesciption,
          paperType,
        ),
        documents: pdf.documents,
        bondPages: pdf.bondPages,
        collateCopies: pdf.collateCopies,
        numberCopies: pdf.numberCopies,
      ),
    );
  }
}
