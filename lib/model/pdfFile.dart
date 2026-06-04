class PdfData {
  String? id;
  String documents;
  String name;
  String size;
  int totalPages;
  int copies;
  String binding;
  String paperSize;
  String pdfSides;
  String pdfPrintLayout;
  String color;
  bool bondPages;
  String pageRange;
  String colorParPageNumbers;
  String colorParDesciption;
  int colorParTotal;
  String additionDesciption;
  bool collateCopies;
  bool numberCopies;

  PdfData({
    this.id,
    required this.name,
    required this.size,
    required this.totalPages,
    required this.copies,
    required this.binding,
    required this.paperSize,
    required this.pdfSides,
    required this.pdfPrintLayout,
    required this.color,
    required this.pageRange,
    required this.colorParDesciption,
    required this.colorParPageNumbers,
    required this.colorParTotal,
    required this.additionDesciption,
    required this.documents,
    required this.bondPages,
    this.collateCopies = false,
    this.numberCopies = false,
  });

  PdfData copyWith({
    String? id,
    String? documents,
    String? name,
    String? size,
    int? totalPages,
    int? copies,
    String? binding,
    String? paperSize,
    String? pdfSides,
    String? pdfPrintLayout,
    String? color,
    bool? bondPages,
    String? pageRange,
    String? colorParPageNumbers,
    String? colorParDesciption,
    int? colorParTotal,
    String? additionDesciption,
    bool? collateCopies,
    bool? numberCopies,
  }) {
    return PdfData(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      totalPages: totalPages ?? this.totalPages,
      copies: copies ?? this.copies,
      binding: binding ?? this.binding,
      paperSize: paperSize ?? this.paperSize,
      pdfSides: pdfSides ?? this.pdfSides,
      pdfPrintLayout: pdfPrintLayout ?? this.pdfPrintLayout,
      color: color ?? this.color,
      pageRange: pageRange ?? this.pageRange,
      colorParDesciption: colorParDesciption ?? this.colorParDesciption,
      colorParPageNumbers: colorParPageNumbers ?? this.colorParPageNumbers,
      colorParTotal: colorParTotal ?? this.colorParTotal,
      additionDesciption: additionDesciption ?? this.additionDesciption,
      documents: documents ?? this.documents,
      bondPages: bondPages ?? this.bondPages,
      collateCopies: collateCopies ?? this.collateCopies,
      numberCopies: numberCopies ?? this.numberCopies,
    );
  }

  int get selectedPagesCount {
    final text = pageRange.trim();
    if (text.isEmpty) return totalPages;
    final selected = <int>{};
    for (final part in text.split(',')) {
      final token = part.trim().replaceAll(' ', '');
      if (token.isEmpty) continue;
      if (token.contains('-')) {
        final pieces = token.split('-');
        if (pieces.length != 2) return totalPages;
        final start = int.tryParse(pieces[0]);
        final end = int.tryParse(pieces[1]);
        if (start == null || end == null || start < 1 || end < start) {
          return totalPages;
        }
        for (var page = start; page <= end && page <= totalPages; page++) {
          selected.add(page);
        }
      } else {
        final page = int.tryParse(token);
        if (page == null || page < 1 || page > totalPages) return totalPages;
        selected.add(page);
      }
    }
    return selected.isEmpty ? totalPages : selected.length;
  }

  Map<String, dynamic> get toMap {
    return {
      "id": id,
      "name": name,
      "size": size,
      "totalPages": totalPages,
      "copies": copies,
      "binding": binding,
      "paperSize": paperSize,
      "pdfSides": pdfSides,
      "pdfPrintLayout": pdfPrintLayout,
      "color": color,
      "pageRange": pageRange,
      "colorParDesciption": colorParDesciption,
      "colorParPageNumbers": colorParPageNumbers,
      "colorParTotal": colorParTotal,
      "documents": documents,
      "bondpages": bondPages,
      "additionDesciption": additionDesciption,
      "collateCopies": collateCopies,
      "numberCopies": numberCopies,
    };
  }
}
