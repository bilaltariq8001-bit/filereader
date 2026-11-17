import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:documentreader/conversation_tool/controller.dart';
import 'package:documentreader/conversation_tool/toolservices/pdftool_services.dart';
import 'package:documentreader/conversation_tool/toolservices/words_services.dart';
import 'package:documentreader/services/bookmark_service.dart';
import 'package:documentreader/services/file_services.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';

Future<ByteData> _font() async =>
    ByteData.sublistView(await File('assets/fonts/Inter.ttf').readAsBytes());

String _pdfText(Uint8List bytes) {
  final doc = sf.PdfDocument(inputBytes: bytes);
  final text = sf.PdfTextExtractor(doc).extractText();
  doc.dispose();
  return text;
}

int _pdfPages(Uint8List bytes) {
  final doc = sf.PdfDocument(inputBytes: bytes);
  final count = doc.pages.count;
  doc.dispose();
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage scan', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('scan');
      File('${root.path}/a.pdf').createSync();
      File('${root.path}/b.DOCX').createSync(); // upper-case extension
      File('${root.path}/notes.txt').createSync();
      Directory('${root.path}/Download/deep').createSync(recursive: true);
      File('${root.path}/Download/deep/c.xlsx').createSync();
      File('${root.path}/Download/d.pptx').createSync();
      Directory('${root.path}/.hidden').createSync();
      File('${root.path}/.hidden/e.pdf').createSync();
      Directory('${root.path}/Android/data/x').createSync(recursive: true);
      File('${root.path}/Android/data/x/f.pdf').createSync();
      Directory('${root.path}/Android/media').createSync(recursive: true);
      File('${root.path}/Android/media/g.pdf').createSync();
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('finds documents, skips hidden folders and Android/data', () {
      final names = scanDocumentPaths(root.path)
          .map((p) => p.split('/').last)
          .toSet();
      expect(names, {'a.pdf', 'b.DOCX', 'c.xlsx', 'd.pptx', 'g.pdf'});
    });

    test('results split into tabs case-insensitively', () {
      final service = FileService();
      final result = service.buildResult(
          scanDocumentPaths(root.path).map((p) => File(p)).toList());
      expect(result.wordFiles.single.path.endsWith('b.DOCX'), isTrue);
      expect(result.pdfFiles.length, 2);
      expect(result.excelFiles.length, 1);
      expect(result.pptFiles.length, 1);
    });

    test('delete can be undone, and committed', () async {
      final service = FileService();
      final file = File('${root.path}/a.pdf')..writeAsStringSync('data');
      final staged = await service.stageDelete(file);
      expect(file.existsSync(), isFalse);
      // Staged files are hidden from the scan.
      expect(scanDocumentPaths(root.path).any((p) => p.endsWith('a.pdf')),
          isFalse);
      await service.restoreStaged(staged, file.path);
      expect(file.readAsStringSync(), 'data');

      final staged2 = await service.stageDelete(file);
      await service.commitDelete(staged2);
      expect(staged2.existsSync(), isFalse);
      expect(file.existsSync(), isFalse);
    });
  });

  group('Bookmarks', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'bookmarks': ['/x/one.pdf']
      });
      BookmarkService().resetForTest();
    });

    test('toggle compares by path, so a stored bookmark can be removed',
        () async {
      final service = BookmarkService();
      await service.loadBookmarks();
      // A fresh File object for the same path used to be treated as a
      // different file and added a duplicate.
      final result = await service.toggleBookmark(File('/x/one.pdf'));
      expect(result.isBookmarked, isFalse);
      expect(result.bookmarkedFiles, isEmpty);

      final again = await service.toggleBookmark(File('/x/one.pdf'));
      expect(again.isBookmarked, isTrue);
      expect(again.bookmarkedPdfFiles.length, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bookmarks'), ['/x/one.pdf']);
    });

    test('rename moves the bookmark to the new path', () async {
      final service = BookmarkService();
      await service.addBookmark('/x/old.docx');
      final data = await service.updateBookmarkedFile(
          File('/x/old.docx'), File('/x/new.docx'));
      expect(data.bookmarkedWordFiles.map((f) => f.path), ['/x/new.docx']);
    });
  });

  group('Word documents', () {
    test('DOCX written with non-ASCII and control characters reads back',
        () async {
      const text = 'Café – naïve résumé\nПривет мир\nbell\u0007char & <tag>';
      final bytes = await WordService.createDocxFromText(text);
      final archive = ZipDecoder().decodeBytes(bytes);
      final xml = utf8.decode(archive.findFile('word/document.xml')!.content);
      XmlDocument.parse(xml); // must be well-formed for Word to open it
      final back = await WordService.extractTextFromDocx(bytes);
      expect(back, 'Café – naïve résumé\nПривет мир\nbellchar & <tag>');
    });

    test('Text to Word creates a valid file', () async {
      final bytes = await WordService.createDocxFromPages(['Page one', 'Two']);
      final xml = utf8.decode(
          ZipDecoder().decodeBytes(bytes).findFile('word/document.xml')!.content);
      expect(xml.contains('w:type="page"'), isTrue);
    });
  });

  group('Conversions', () {
    test('PDF to Word extracts each page into the DOCX', () async {
      final doc = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Text('Hello first page')))
        ..addPage(pw.Page(build: (_) => pw.Text('Second page text')));
      final pdfBytes = await doc.save();

      final docx = await compute(pdfBytesToDocx, pdfBytes);
      final text = await WordService.extractTextFromDocx(docx);
      expect(text, contains('Hello first page'));
      expect(text, contains('Second page text'));
    });

    test('PDF to Word reports scanned PDFs instead of writing an empty file',
        () async {
      final doc = pw.Document()..addPage(pw.Page(build: (_) => pw.SizedBox()));
      final bytes = await doc.save();
      await expectLater(pdfBytesToDocx(bytes), throwsException);
    });

    test('Word to PDF keeps non-Latin text with the bundled font', () async {
      final docx = await WordService.createDocxFromText(
          'Heading\nПривет мир — café\n${List.filled(200, 'line').join('\n')}');
      final pdf = await compute(docxBytesToPdf, (docx, await _font()));
      expect(_pdfPages(pdf), greaterThan(1)); // long text paginates
      expect(_pdfText(pdf), contains('Привет'));
    });

    test('Excel to PDF draws the sheet', () async {
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow([excel_pkg.TextCellValue('Name'), excel_pkg.TextCellValue('Qty')]);
      for (int i = 0; i < 120; i++) {
        sheet.appendRow([excel_pkg.TextCellValue('Item $i'), excel_pkg.IntCellValue(i)]);
      }
      final xlsx = Uint8List.fromList(excel.encode()!);
      final pdf = await compute(excelBytesToPdf, xlsx);
      expect(_pdfPages(pdf), greaterThan(1));
      expect(_pdfText(pdf), contains('Item 119'));
    });

    test('Excel to PDF rejects an empty workbook', () async {
      final excel = excel_pkg.Excel.createExcel();
      final xlsx = Uint8List.fromList(excel.encode()!);
      await expectLater(excelBytesToPdf(xlsx), throwsException);
    });

    test('PPT to PDF keeps slide order and UTF-8 text', () async {
      String slide(String t) =>
          '<?xml version="1.0" encoding="UTF-8"?><p:sld xmlns:a="a" xmlns:p="p"><a:t>$t</a:t></p:sld>';
      final archive = Archive();
      void add(String name, String content) {
        final b = utf8.encode(content);
        archive.addFile(ArchiveFile(name, b.length, b));
      }

      add('ppt/slides/slide2.xml', slide('Zweite Folie – Grüße'));
      add('ppt/slides/slide1.xml', slide('First slide'));
      add('ppt/slides/_rels/slide1.xml.rels', '<x/>');
      final pptx = Uint8List.fromList(ZipEncoder().encode(archive)!);

      final pdf = await compute(pptxBytesToPdf, (pptx, await _font()));
      expect(_pdfPages(pdf), 2);
      final text = _pdfText(pdf);
      expect(text.indexOf('First slide'), lessThan(text.indexOf('Zweite')));
      expect(text, contains('Grüße'));
    });

    test('Images to PDF: one page per valid image, bad files skipped',
        () async {
      final dir = Directory.systemTemp.createTempSync('img');
      final wide = File('${dir.path}/wide.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 40, height: 20)));
      final tall = File('${dir.path}/tall.jpg')
        ..writeAsBytesSync(img.encodeJpg(img.Image(width: 20, height: 40)));
      final bmp = File('${dir.path}/pic.bmp')
        ..writeAsBytesSync(img.encodeBmp(img.Image(width: 10, height: 10)));
      final bad = File('${dir.path}/bad.png')..writeAsStringSync('nope');

      final pdf = await compute(
          imagesToPdf, [wide.path, tall.path, bmp.path, bad.path]);
      expect(_pdfPages(pdf), 3);

      await expectLater(imagesToPdf([bad.path]), throwsException);
      dir.deleteSync(recursive: true);
    });
  });

  test('PdfService splits text per page', () async {
    final doc = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('A')))
      ..addPage(pw.Page(build: (_) => pw.Text('B')));
    final pages = PdfService.extractPagesFromPdfBytes(await doc.save());
    expect(pages.length, 2);
    expect(pages[1], contains('B'));
  });
}
