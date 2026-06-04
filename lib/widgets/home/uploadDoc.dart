// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// import '../../model/custom_pdf_modal.dart';
// import '../../screens/pdf/cutom_pdf_Render_Screen.dart';
import '../../model/pdfFile.dart';
import '../../providers/ListOfPdfFiles.dart';
import '../../screens/pdf/pdfFilter.dart';
import '../../utils/color_pallets.dart';
import '../../utils/pill_notifications.dart';

class UploadDoc extends StatefulWidget {
  final BuildContext ctx;
  final String accessToken;

  const UploadDoc({
    super.key,
    required this.ctx,
    required this.accessToken,
  });

  @override
  State<UploadDoc> createState() => _UploadDocState();
}

class _UploadDocState extends State<UploadDoc> {
  bool isPdfLoading = false;
  static const Duration _networkTimeout = Duration(seconds: 20);
  static const Duration _downloadUrlTimeout = Duration(seconds: 12);

  String bytesToMB(int bytes) {
    const int bytesInKB = 1024;
    const int bytesInMB = bytesInKB * 1024;

    if (bytes >= bytesInMB) {
      double sizeInMB = bytes / bytesInMB;
      return '${sizeInMB.toStringAsFixed(2)} MB';
    } else {
      double sizeInKB = bytes / bytesInKB;
      return '${sizeInKB.toStringAsFixed(2)} KB';

      // File 1:
      // Name: Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf
      // Size : 279.59 KB
      // Page Count: 11
    }
  }

  Future<String?> uploadFileGetDownloadUrl(
      File pdffile, String fileName, String filePath) async {
    try {
      final url = Uri.parse(
          "https://dittox.in/xerox/v1/cloud-services/file/getSignedUrl");
      final headers = {"X-auth-token": "bearer ${widget.accessToken}"};
      final params = {"fileName": fileName};

      var urlGet = Uri.https(url.authority, url.path, params);
      var response =
          await http.get(urlGet, headers: headers).timeout(_networkTimeout);
      final signed = json.decode(response.body);
      if (signed["responseCode"] == "OK") {
        final filePath = signed["result"]["filePath"];
        final signedUrl = signed["result"]["signedUrl"];

        final headersUploadUrl = {
          "Content-Type": "multipart/form-data",
          "X-auth-token": "bearer ${widget.accessToken}"
        };

        // final file = File("/content/2310.03046.pdf");
        final responseUpload = await http
            .put(Uri.parse(signedUrl),
                body: await pdffile.readAsBytes(), headers: headersUploadUrl)
            .timeout(_networkTimeout);

        if (responseUpload.statusCode == 200) {
          final urlDownload = Uri.parse(
              "https://dittox.in/xerox/v1/cloud-services/file/getDownloadableUrl");
          final paramsDownloadUrl = {"filePath": filePath};
          final urlDownloadGet = Uri.https(
              urlDownload.authority, urlDownload.path, paramsDownloadUrl);
          try {
            final responseDownloadUrl = await http
                .get(urlDownloadGet, headers: headers)
                .timeout(_downloadUrlTimeout);
            if (responseDownloadUrl.statusCode == 200) {
              final responseDownloadUrlJson =
                  json.decode(responseDownloadUrl.body);
              if (responseDownloadUrlJson["responseCode"] == "OK") {
                return responseDownloadUrlJson["result"];
              }
            }
          } catch (_) {
            // fallback below
          }
          // Uploaded successfully; URL API can be slow. Use local file ref so
          // store printing still works immediately in this session.
          return "local://${pdffile.path}";
        } else {
          throw Exception(
              "Error: Try uploading again. Sorry for the inconvenience.");
        }
      } else {
        throw Exception(signed["message"]);
      }
    } catch (e) {
      // Let caller handle fallback without crashing upload flow.
      rethrow;
    }
  }

  Future<bool> pickFiles(
      BuildContext ctx, ListOfPDFFiles listofpdffiles) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ["pdf", "jpg", "jpeg", "png"],
      withData: kIsWeb,
    );
    if (result == null) {
      return false;
    }

    listofpdffiles.emptyPDFfile();
    int addedCount = 0;
    for (int i = 0; i < result.count; i++) {
      final picked = result.files[i];
      final bytes = picked.bytes;
      final path = picked.path;
      final extension = picked.extension?.toLowerCase() ??
          picked.name.split('.').last.toLowerCase();
      final isPdf = extension == 'pdf';
      int pageCount = 1;
      if (isPdf) {
        try {
          final pdfDocument = PdfDocument(
            inputBytes: kIsWeb && bytes != null
                ? bytes
                : await File(path as String).readAsBytes(),
          );
          pageCount = pdfDocument.pages.count;
          pdfDocument.dispose();
        } catch (_) {
          pageCount = 1;
        }
      }
      String docRef;
      bool uploadedToCloud = true;
      if (kIsWeb || path == null || path.isEmpty) {
        uploadedToCloud = false;
        docRef = "web://${picked.name}";
      } else {
        final pdfFile = File(path);
        try {
          docRef = (await uploadFileGetDownloadUrl(
              pdfFile, picked.name, path.toString()))!;
        } catch (e) {
          uploadedToCloud = false;
          docRef = "local://$path";
        }
      }

      final pdf = PdfData(
        name: picked.name,
        bondPages: false,
        size: bytesToMB(picked.size),
        totalPages: pageCount,
        copies: 1,
        binding: "No binding",
        paperSize: "A4",
        pdfSides: "Single side",
        pdfPrintLayout: "Portrait",
        color: "Black & White",
        pageRange: "1 - $pageCount",
        colorParDesciption: "",
        colorParPageNumbers: "",
        colorParTotal: 0,
        additionDesciption: uploadedToCloud
            ? ""
            : kIsWeb
                ? "Browser upload selected. Continue with web checkout."
                : "Cloud upload failed. File kept locally for editing.",
        documents: docRef,
      );
      listofpdffiles.addPDFFile(pdf);
      addedCount++;
    }
    return addedCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    ListOfPDFFiles listofpdffiles =
        Provider.of<ListOfPDFFiles>(context, listen: true);
    return InkWell(
      onTap: () async {
        final hasFirebaseUser = FirebaseAuth.instance.currentUser != null;
        final hasAccessToken = widget.accessToken.trim().isNotEmpty;
        if (!hasFirebaseUser && !hasAccessToken) {
          PillNotifications.show(
            context,
            message: "Please login first to upload documents.",
            type: PillType.error,
          );
          return;
        }
        setState(() {
          isPdfLoading = true;
        });
        try {
          var fileIsPicked = await pickFiles(context, listofpdffiles);
          if (fileIsPicked && listofpdffiles.pdfFilesList.isNotEmpty) {
            Navigator.of(context).pushNamed(PDFFilters.routeName);
          } else {
            PillNotifications.show(
              context,
              message:
                  "No valid file uploaded. Please try again with a PDF or image.",
              type: PillType.error,
            );
          }
        } catch (e) {
          PillNotifications.show(
            context,
            message:
                "Error while uploading file. Try again. For large files, upload one by one.",
            type: PillType.error,
          );
        } finally {
          setState(() {
            isPdfLoading = false;
          });
        }
      },
      // openFile(context, file);

      splashColor: ColorPallets.swiggyOrangeLight,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                    "assets/image/documentUpload.png",
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
                    "Upload Document",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "PDF, JPG, PNG",
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  isPdfLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Container(
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

  // void openFile(BuildContext ctx, File file) {
  //   setState(() {
  //     isPdfLoading = false;
  //   });
  //   // Navigator.of(ctx).pushNamed(CustomPDFPreview.routeName, arguments: file);
  //   // setState(() {
  //   //   isPdfLoading = false;
  //   // });
  // }
}
