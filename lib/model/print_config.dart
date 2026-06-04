import 'package:dittox/model/pdfFile.dart';
import '../utils/enums/print_enums.dart';

/// Configuration model for PDF print settings
/// Immutable for better state management
class PrintConfig {
  final PageOrientation orientation;
  final PrintingSides printingSide;
  final JobTypes jobType;
  final SheetSize sheetSize;
  final BindingType bindingType;
  final int copies;
  final int startPage;
  final int endPage;
  final int? colorStartPage;
  final int? colorEndPage;
  final int? bondStartPage;
  final int? bondEndPage;
  final String? instructions;
  final bool useColorPages;
  final bool useBondPages;

  const PrintConfig({
    this.orientation = PageOrientation.portrait,
    this.printingSide = PrintingSides.singleSided,
    this.jobType = JobTypes.blackAndWhite,
    this.sheetSize = SheetSize.a4,
    this.bindingType = BindingType.noBinding,
    this.copies = 1,
    this.startPage = 1,
    this.endPage = 1,
    this.colorStartPage,
    this.colorEndPage,
    this.bondStartPage,
    this.bondEndPage,
    this.instructions,
    this.useColorPages = false,
    this.useBondPages = false,
  });

  /// Create initial config from PDF data
  factory PrintConfig.fromPdfData(PdfData pdf) {
    return PrintConfig(
      startPage: 1,
      endPage: pdf.totalPages,
      copies: 1,
    );
  }

  /// Copy with modified fields
  PrintConfig copyWith({
    PageOrientation? orientation,
    PrintingSides? printingSide,
    JobTypes? jobType,
    SheetSize? sheetSize,
    BindingType? bindingType,
    int? copies,
    int? startPage,
    int? endPage,
    int? colorStartPage,
    int? colorEndPage,
    int? bondStartPage,
    int? bondEndPage,
    String? instructions,
    bool? useColorPages,
    bool? useBondPages,
  }) {
    return PrintConfig(
      orientation: orientation ?? this.orientation,
      printingSide: printingSide ?? this.printingSide,
      jobType: jobType ?? this.jobType,
      sheetSize: sheetSize ?? this.sheetSize,
      bindingType: bindingType ?? this.bindingType,
      copies: copies ?? this.copies,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      colorStartPage: colorStartPage ?? this.colorStartPage,
      colorEndPage: colorEndPage ?? this.colorEndPage,
      bondStartPage: bondStartPage ?? this.bondStartPage,
      bondEndPage: bondEndPage ?? this.bondEndPage,
      instructions: instructions ?? this.instructions,
      useColorPages: useColorPages ?? this.useColorPages,
      useBondPages: useBondPages ?? this.useBondPages,
    );
  }

  /// Convert to API-compatible map
  Map<String, dynamic> toMap() {
    return {
      'orientation': orientation.name,
      'printingSide': printingSide.name,
      'jobType': jobType.name,
      'sheetSize': sheetSize.name,
      'bindingType': bindingType.name,
      'copies': copies,
      'pageRange': {'start': startPage, 'end': endPage},
      if (useColorPages && colorStartPage != null && colorEndPage != null)
        'colorPageRange': {'start': colorStartPage, 'end': colorEndPage},
      if (useBondPages && bondStartPage != null && bondEndPage != null)
        'bondPageRange': {'start': bondStartPage, 'end': bondEndPage},
      if (instructions != null && instructions!.isNotEmpty)
        'instructions': instructions,
    };
  }

  /// Calculate total pages to be printed
  int get totalPagesToPrint {
    final pageRange = endPage - startPage + 1;
    return pageRange * copies;
  }

  /// Check if config is valid
  bool get isValid {
    return startPage > 0 &&
        endPage >= startPage &&
        copies > 0 &&
        (!useColorPages ||
            (colorStartPage != null &&
                colorEndPage != null &&
                colorStartPage! > 0 &&
                colorEndPage! >= colorStartPage!)) &&
        (!useBondPages ||
            (bondStartPage != null &&
                bondEndPage != null &&
                bondStartPage! > 0 &&
                bondEndPage! >= bondStartPage!));
  }

  @override
  String toString() => 'PrintConfig(${toMap()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrintConfig &&
        other.orientation == orientation &&
        other.printingSide == printingSide &&
        other.jobType == jobType &&
        other.sheetSize == sheetSize &&
        other.bindingType == bindingType &&
        other.copies == copies &&
        other.startPage == startPage &&
        other.endPage == endPage &&
        other.colorStartPage == colorStartPage &&
        other.colorEndPage == colorEndPage &&
        other.bondStartPage == bondStartPage &&
        other.bondEndPage == bondEndPage &&
        other.instructions == instructions &&
        other.useColorPages == useColorPages &&
        other.useBondPages == useBondPages;
  }

  @override
  int get hashCode => Object.hash(
        orientation,
        printingSide,
        jobType,
        sheetSize,
        bindingType,
        copies,
        startPage,
        endPage,
        colorStartPage,
        colorEndPage,
        bondStartPage,
        bondEndPage,
        instructions,
        useColorPages,
        useBondPages,
      );
}
