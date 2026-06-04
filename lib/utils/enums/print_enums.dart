/// Print-related enums and their string representations
/// Extracted from singlePDfFilter.dart for better organization
library;

enum PageOrientation { landscape, portrait }

enum PrintingSides { singleSided, doubleSided }

enum JobTypes { blackAndWhite, fullColor, partialColor }

enum BindingType { noBinding, spiral, stickFile, staples }

enum SheetSize {
  a4, a5, legal, letter, b5, a6, postCard, size5x7, size4x6, size35x5
}

/// Extension methods for string conversions
extension PageOrientationExtension on PageOrientation {
  String get displayName {
    switch (this) {
      case PageOrientation.landscape:
        return "Landscape";
      case PageOrientation.portrait:
        return "Portrait";
    }
  }
}

extension PrintingSidesExtension on PrintingSides {
  String get displayName {
    switch (this) {
      case PrintingSides.singleSided:
        return "Single Side";
      case PrintingSides.doubleSided:
        return "Double Side";
    }
  }
}

extension JobTypesExtension on JobTypes {
  String get displayName {
    switch (this) {
      case JobTypes.blackAndWhite:
        return "Black & White";
      case JobTypes.fullColor:
        return "All Color";
      case JobTypes.partialColor:
        return "Partial Color";
    }
  }
}

extension BindingTypeExtension on BindingType {
  String get displayName {
    switch (this) {
      case BindingType.noBinding:
        return "No Binding";
      case BindingType.spiral:
        return "Spiral";
      case BindingType.stickFile:
        return "Stick File";
      case BindingType.staples:
        return "Staples";
    }
  }
}

extension SheetSizeExtension on SheetSize {
  String get displayName {
    switch (this) {
      case SheetSize.a4:
        return "A4";
      case SheetSize.a5:
        return "A5";
      case SheetSize.legal:
        return "Legal";
      case SheetSize.letter:
        return "Letter";
      case SheetSize.b5:
        return "B5";
      case SheetSize.a6:
        return "A6";
      case SheetSize.postCard:
        return "Post Card";
      case SheetSize.size5x7:
        return "5*7";
      case SheetSize.size4x6:
        return "4*6";
      case SheetSize.size35x5:
        return "35*5";
    }
  }

  static List<SheetSize> get all => SheetSize.values;
  static List<String> get allDisplayNames =>
      SheetSize.values.map((e) => e.displayName).toList();
}

extension BindingTypeList on BindingType {
  static List<BindingType> get all => BindingType.values;
  static List<String> get allDisplayNames =>
      BindingType.values.map((e) => e.displayName).toList();
}

// Legacy compatibility functions (deprecated, use extensions instead)
@Deprecated('Use PageOrientation.displayName instead')
String getStringPageOrientations(PageOrientation orient) => orient.displayName;

@Deprecated('Use PrintingSides.displayName instead')
String getStringPrintingSides(PrintingSides side) => side.displayName;

@Deprecated('Use JobTypes.displayName instead')
String getStringJobType(JobTypes job) => job.displayName;
