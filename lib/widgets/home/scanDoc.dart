import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// import '../../screens/pdf/images_grid_file.dart';
import '../../model/pdfFile.dart';
import '../../providers/ListOfPdfFiles.dart';
import '../../screens/pdf/pdfFilter.dart';
import '../../screens/pdf/scanImageToPdf.dart';
import '../../utils/color_pallets.dart';
import '../../utils/pill_notifications.dart';

class ScanDoc extends StatelessWidget {
  final BuildContext ctx;
  const ScanDoc({
    super.key,
    required this.ctx,
  });

  Future<void> _pickBrowserImages(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final files = context.read<ListOfPDFFiles>();
    files.emptyPDFfile();
    for (final image in result.files) {
      files.addPDFFile(
        PdfData(
          name: image.name,
          size: _bytesToMB(image.size),
          totalPages: 1,
          copies: 1,
          binding: 'No binding',
          paperSize: 'A4',
          pdfSides: 'Single side',
          pdfPrintLayout: 'Portrait',
          color: 'Black & White',
          pageRange: '1 - 1',
          colorParDesciption: '',
          colorParPageNumbers: '',
          colorParTotal: 0,
          additionDesciption: 'Browser image upload selected.',
          documents: 'web://${image.name}',
          bondPages: false,
        ),
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(PDFFilters.routeName);
  }

  String _bytesToMB(int bytes) {
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (kIsWeb) {
          _pickBrowserImages(context).catchError((_) {
            if (!context.mounted) return;
            PillNotifications.show(
              context,
              message: 'Could not open image picker. Try Upload Document.',
              type: PillType.error,
            );
          });
          return;
        }
        Navigator.of(context).pushNamed(ScaneImageToPdf.routeName);
      },
      splashColor: ColorPallets.swiggyOrangeLight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPallets.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/image/ImageUpload2.png",
                    fit: BoxFit.contain,
                  ),
                )),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Scan Document",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    kIsWeb ? "Pick image files" : "Use camera scanner",
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ColorPallets.swiggyOrangeLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.arrowRight,
                        color: ColorPallets.swiggyOrange,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
