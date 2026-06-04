import 'package:flutter/material.dart';

import '../model/pdfFile.dart';

class ListOfPDFFiles with ChangeNotifier {
  List<PdfData> pdfFilesList = [];

  void emptyPDFfile() {
    pdfFilesList = [];
    notifyListeners();
  }

  void addPDFFile(PdfData pdf) {
    pdfFilesList.add(pdf);
    notifyListeners();
  }

  PdfData getPDFFileAtIndex(int index) {
    return pdfFilesList[index];
  }

  void printPDFFile() {
    debugPrint(pdfFilesList[0].toMap.toString());
  }

  void printALLPDFfile() {
    for (int i = 0; i < pdfFilesList.length; i++) {
      debugPrint(pdfFilesList[i].toMap.toString());
    }
  }

  void replacePDFAtIndex(int index, PdfData newPdfData) {
    pdfFilesList[index] = newPdfData;
    // print(pdfFilesList[0].toMap);
    notifyListeners();
  }

  List<PdfData> get allPdfList {
    return List.unmodifiable(pdfFilesList);
  }
}
