/// Utility functions for order processing
/// Extracted from payLater.dart and other files to reduce duplication
library;

/// Convert display color name to API color code
String getColorCode(String input) {
  switch (input.toLowerCase()) {
    case 'black & white':
      return 'bw';
    case 'all color':
      return 'multi';
    case 'partial color':
      return 'colpar';
    default:
      return '';
  }
}

/// Convert display paper size to API format
String getPaperSize(String input) {
  switch (input.toUpperCase()) {
    case 'A4':
      return 'a4';
    case 'A5':
      return 'a5';
    case 'LEGAL':
      return 'legal';
    case 'LETTER':
      return 'letter';
    case 'B5':
      return 'b5';
    case 'A6':
      return 'a6';
    case 'POST CARD':
      return 'postCard';
    case '5*7':
      return '5*7';
    case '4*6':
      return '4*6';
    case '3.5*5':
    case '35*5':
      return '3.5*5';
    default:
      return '';
  }
}

/// Convert display binding type to API format
String getBindingType(String input) {
  switch (input.toLowerCase()) {
    case 'no binding':
      return 'noBinding';
    case 'staples':
      return 'Staples';
    case 'spiral':
      return 'Spiral';
    case 'stick file':
      return 'Stick File';
    default:
      return '';
  }
}

/// Extract range values from string like "1-10"
List<int> extractRangeValues(String rangeString) {
  if (rangeString.isEmpty) return [];
  
  List<String> parts = rangeString.split('-');
  return parts
      .map((part) => int.tryParse(part.trim()))
      .where((n) => n != null)
      .cast<int>()
      .toList();
}

/// Generate list of page numbers from comma/range string like "1-3,5,7-10"
List<int> generateColorPageList(String input) {
  if (input.isEmpty) return [];
  
  List<int> result = [];
  List<String> ranges = input.split(',');

  for (String range in ranges) {
    range = range.trim();
    if (range.contains('-')) {
      List<String> rangeParts = range.split('-');
      if (rangeParts.length == 2) {
        int? start = int.tryParse(rangeParts[0].trim());
        int? end = int.tryParse(rangeParts[1].trim());
        if (start != null && end != null && start <= end) {
          for (int i = start; i <= end; i++) {
            result.add(i);
          }
        }
      }
    } else {
      int? page = int.tryParse(range);
      if (page != null) result.add(page);
    }
  }

  return result;
}

/// Format date string to display format
String formatDate(String? dateTimeString) {
  if (dateTimeString == null || dateTimeString.isEmpty) return '';
  
  try {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  } catch (e) {
    return dateTimeString;
  }
}
