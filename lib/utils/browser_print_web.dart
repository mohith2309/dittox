// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

bool triggerBrowserPrintHtml({
  required String title,
  required String bodyHtml,
}) {
  final style = html.StyleElement()
    ..id = 'dittox-print-style'
    ..text = '''
@media print {
  body > *:not(#dittox-print-root) { display: none !important; }
  #dittox-print-root { display: block !important; position: static !important; width: 100% !important; }
}
''';
  final root = html.DivElement()
    ..id = 'dittox-print-root'
    ..style.position = 'fixed'
    ..style.left = '-10000px'
    ..style.top = '0'
    ..style.width = '210mm'
    ..setInnerHtml(
      _document(title, bodyHtml),
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    );

  html.document.getElementById('dittox-print-style')?.remove();
  html.document.getElementById('dittox-print-root')?.remove();
  html.document.head?.append(style);
  html.document.body?.append(root);
  Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
    html.window.print();
  });
  Future<void>.delayed(const Duration(seconds: 12)).then((_) {
    style.remove();
    root.remove();
  });
  return true;
}

String _document(String title, String bodyHtml) {
  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>${_escape(title)}</title>
  <style>
    @page { size: A4; margin: 14mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: #111827;
      font-family: Arial, Helvetica, sans-serif;
      font-size: 13px;
      line-height: 1.45;
      background: #fff;
    }
    .sheet { width: 100%; }
    .print-page { page-break-after: always; break-after: page; }
    .print-page:last-child { page-break-after: auto; break-after: auto; }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      padding-bottom: 12px;
      border-bottom: 2px solid #0b5e5f;
      margin-bottom: 16px;
    }
    h1 { margin: 0; color: #0b5e5f; font-size: 24px; }
    h2 { margin: 18px 0 8px; color: #0b5e5f; font-size: 15px; }
    .muted { color: #6b7280; }
    .pill {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 999px;
      background: #eef8f8;
      color: #0b5e5f;
      font-weight: 700;
      margin: 0 5px 5px 0;
    }
    table { width: 100%; border-collapse: collapse; }
    td, th { padding: 8px; border: 1px solid #d8e4e5; text-align: left; }
    th { background: #eef8f8; color: #0b5e5f; }
    .total { font-size: 20px; font-weight: 800; color: #0b5e5f; }
    .footer { margin-top: 20px; padding-top: 10px; border-top: 1px solid #d8e4e5; }
    .invoice-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
      margin-top: 14px;
    }
    .signature-row {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      margin-top: 18px;
    }
    .signature-row > div {
      min-height: 58px;
      padding: 10px;
      border: 1px solid #d8e4e5;
      border-radius: 8px;
    }
    .customer-file-page { min-height: 265mm; }
    .doc-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid #d8e4e5;
      color: #0b5e5f;
    }
    .doc-header span { color: #6b7280; font-size: 12px; }
    .doc-stage {
      min-height: 250mm;
      display: flex;
      align-items: center;
      justify-content: center;
      padding-top: 10px;
    }
    .doc-image {
      display: block;
      max-width: 100%;
      max-height: 250mm;
      object-fit: contain;
    }
    .doc-frame {
      width: 100%;
      height: 250mm;
      border: 0;
      margin-top: 10px;
    }
    .doc-fallback {
      margin-top: 24px;
      padding: 28px;
      border: 2px dashed #9ccfd0;
      border-radius: 14px;
      background: #f6fbfb;
      text-align: center;
    }
  </style>
</head>
<body><div class="sheet">$bodyHtml</div></body>
</html>
''';
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
