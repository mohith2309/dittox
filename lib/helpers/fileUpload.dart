// import 'dart:io';
// import 'package:dittox/providers/ListOfPdfFiles.dart';
// import 'package:dittox/providers/singlePdf.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class fileUpload {
//   static String bytesToMB(int bytes) {
//     const int bytesInKB = 1024;
//     const int bytesInMB = bytesInKB * 1024;

//     if (bytes >= bytesInMB) {
//       double sizeInMB = bytes / bytesInMB;
//       return '${sizeInMB.toStringAsFixed(2)} MB';
//     } else {
//       double sizeInKB = bytes / bytesInKB;
//       return '${sizeInKB.toStringAsFixed(2)} KB';

//       // File 1:
//       // Name: Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf
//       // Size : 279.59 KB
//       // Page Count: 11
//     }
//   }

//   static Future<void> pickFiles(BuildContext ctx) async {
//     final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true, type: FileType.custom, allowedExtensions: ["pdf"]);
//     if (result == null) {
//       return null;
//     }
//     ListOfPDFFiles listofpdffiles =
//         Provider.of<ListOfPDFFiles>(ctx, listen: true);

//     listofpdffiles.emptyPDFfile();
//     for (int i = 0; i < result.count; i++) {
//       final pdfFile = File(result.files[i].path as String);
//       // Count pages
//       final pdfDocument = await PDFDocument.fromFile(pdfFile);
//       final pageCount = pdfDocument.count;
//       SinglePDfFile singlepdffile =
//           Provider.of<SinglePDfFile>(ctx, listen: true);

//       // singlepdffile.setPdfName(result.files[i].name);
//       // singlepdffile.setPdfSize(bytesToMB(result.files[i].size));
//       // singlepdffile.setPdfTotalPages(pageCount as int);
//       // singlepdffile.setUploadId("${i + 1}");
//       // singlepdffile.printSinglePDFalldata();

//       // print("File ${i + 1}:");
//       // print("Name: ${result.files[i].name}");
//       // print("Size: ${bytesToMB(result.files[i].size)}");
//       // print("Page Count: $pageCount");
//       print("------");
//       // listofpdffiles.addPDFFile(singlepdffile);
//     }
//     print(listofpdffiles.allPdfList);

//     // print("result ${result}");
//     // print("result.fliles ${result.files}");
//     // [PlatformFile(path /data/user/0/com.example.dittox/cache/file_picker/Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf,
//     // name: Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf, bytes: null, readStream: null, size: 286303)]

//     // print("result.files[0].size ${result.files[0].size}");
//     // print("size in MB is ${bytesToMB(result.files[0].size)}");
//     // print("result.names ${result.names}");
//     // [Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf]

//     // print("result.count ${result.count}"); //1

//     // print("result.paths ${result.paths}");
//     // [/data/user/0/com.example.dittox/cache/file_picker/Notfn_ Group-II_2023 with Syllabus_112023_07122023 (1).pdf]
//   }
// }
