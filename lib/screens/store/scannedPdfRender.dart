import 'dart:convert';
import 'dart:io';

import 'package:dittox/providers/ListOfPdfFiles.dart';
import 'package:dittox/screens/pdf/pdfFilter.dart';
import 'package:dittox/utils/color_pallets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../model/pdfFile.dart';
import '../../utils/dynamicSizing.dart';

class ScanPicrender extends StatefulWidget {
  static const routeName = "/scannedPicRender";
  final String accessToken;
  const ScanPicrender({
    super.key,
    required this.accessToken,
  });

  @override
  State<ScanPicrender> createState() => _ScanPicrenderState();
}

class _ScanPicrenderState extends State<ScanPicrender> {
  bool isPdfLoading = false;

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
      // print("Filename is ${fileName}");
      final params = {"fileName": fileName};

      var urlGet = Uri.https(url.authority, url.path, params);
      var response = await http.get(urlGet, headers: headers);
      final signed = json.decode(response.body);
      // print(signed);
      if (signed["responseCode"] == "OK") {
        final filePath = signed["result"]["filePath"];
        final signedUrl = signed["result"]["signedUrl"];
        // print("signed url is $signedUrl");
        // print("filepath is $filePath");

        final headersUploadUrl = {
          "Content-Type": "multipart/form-data",
          "X-auth-token": "bearer ${widget.accessToken}"
        };

        // final file = File("/content/2310.03046.pdf");
        final responseUpload = await http.put(Uri.parse(signedUrl),
            body: await pdffile.readAsBytes(), headers: headersUploadUrl);

        if (responseUpload.statusCode == 200) {
          // Print the status code
          // print("Status Code: ${responseUpload.statusCode}");
          // Print the content of the response
          // print("Content: ${responseUpload.body}");
          final urlDownload = Uri.parse(
              "https://dittox.in/xerox/v1/cloud-services/file/getDownloadableUrl");
          final paramsDownloadUrl = {"filePath": filePath};
          final urlDownloadGet = Uri.http(
              urlDownload.authority, urlDownload.path, paramsDownloadUrl);
          final responseDownloadUrl =
              await http.get(urlDownloadGet, headers: headers);
          if (responseDownloadUrl.statusCode == 200) {
            final responseDownloadUrlJson =
                json.decode(responseDownloadUrl.body);

            if (responseDownloadUrlJson["responseCode"] == "OK") {
              // print(responseDownloadUrlJson);
              return responseDownloadUrlJson["result"];
            } else {
              throw Exception(responseDownloadUrlJson["message"]);
            }
          } else {
            throw Exception(
                "Error: Try uploading again. Sorry for the inconvenience.");
          }
        } else {
          throw Exception(
              "Error: Try uploading again. Sorry for the inconvenience.");
        }
      } else {
        throw Exception(signed["message"]);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<bool> createPdfFile(
    BuildContext ctx,
    ListOfPDFFiles listofpdffiles,
    File scannedfile,
    String pdfName,
    String path,
  ) async {
    setState(() {
      isPdfLoading = true;
    });
    listofpdffiles.emptyPDFfile();
    final pdfDocument =
        PdfDocument(inputBytes: await scannedfile.readAsBytes());
    final pageCount = pdfDocument.pages.count;
    pdfDocument.dispose();
    try {
      String downloadDocumentUrl = "local://${scannedfile.path}";
      if (widget.accessToken != "demo_token") {
        try {
          downloadDocumentUrl =
              (await uploadFileGetDownloadUrl(scannedfile, pdfName, path))!;
        } catch (_) {
          // Keep printable local fallback when cloud URL generation fails.
          downloadDocumentUrl = "local://${scannedfile.path}";
        }
      }
      PdfData pdf = PdfData(
        name: pdfName,
        bondPages: false,
        size: bytesToMB(scannedfile.lengthSync()),
        totalPages: pageCount,
        copies: 1,
        binding: "No binding",
        paperSize: "A4",
        pdfSides: "Single side",
        pdfPrintLayout: "Portraint",
        color: "Black & White",
        pageRange: "1 - $pageCount",
        colorParDesciption: "",
        colorParPageNumbers: "",
        colorParTotal: 0,
        additionDesciption: "",
        documents: downloadDocumentUrl,
      );
      listofpdffiles.addPDFFile(pdf);
    } catch (e) {
      debugPrint('PDF creation error: $e');
    } finally {
      setState(() {
        isPdfLoading = false;
      });
    }

    return true;
  }

  void openFile(BuildContext ctx, File file, String fileName) {
    // setState(() {
    //   isUploadingToFirebase = false;
    // });

    // Navigator.of(ctx).pushNamed(DummyShops.routeName);

    // setState(() {
    //   isPdfLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    ListOfPDFFiles pdffileList =
        Provider.of<ListOfPDFFiles>(context, listen: true);
    File file = ModalRoute.of(context)!.settings.arguments as File;
    String displayName = basename(file.path).split('.')[0];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        title: Text(
          displayName,
          style: const TextStyle(
            color: ColorPallets.white,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: SfPdfViewer.file(
        file,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        pageLayoutMode: PdfPageLayoutMode.continuous,
        scrollDirection: PdfScrollDirection.vertical,
      ),
      bottomSheet: Container(
        height: 100,
        // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
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
                currentFontSize: 44,
                // heightSpecific: true,
              )),
              topRight: Radius.circular(
                  // 22,
                  calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 44,
                // heightSpecific: true,
              )),
            ),
            boxShadow: [
              BoxShadow(
                  color: ColorPallets.lightBlue.withValues(alpha: 0.1),
                  // blurRadius: 20,
                  blurRadius: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ))
            ]),
        child: InkWell(
          onTap: () async {
            debugPrint(file.path);
            setState(() {
              isPdfLoading = true;
            });
            try {
              var scannedCrt = await createPdfFile(
                  context, pdffileList, file, displayName, file.path);
              if (scannedCrt) {
                debugPrint("UPLOAD SUCCESSFULLY -----> ");
                if (!context.mounted) return;
                Navigator.of(context).pushNamed(PDFFilters.routeName);
              }
            } catch (e) {
              if (!context.mounted) return;
              // Display alert dialog on error
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      "Error",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      "Error while uploading file. Pls Try Again after!\nIf LARGE FILES  try upload them individually",
                      style: TextStyle(
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 36,
                          // heightSpecific: true,
                        ),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigator.of(context).pushNamed(PDFFilters.routeName);
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              // fontSize: 20,
                              fontSize: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 40,
                                // heightSpecific: true,
                              )),
                        ),
                      ),
                    ],
                  );
                },
              );
            } finally {
              setState(() {
                isPdfLoading = false;
              });
            }
            // Navigator.of(context).pushReplacementNamed(SelectShops.routeName);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                child: isPdfLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ColorPallets.deepBlue,
                        ),
                      )
                    : Text(
                        "Process to customize print",
                        style: TextStyle(
                          // fontSize: 26,
                          fontSize: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 52,
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
}
