import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:docx_creator/docx_creator.dart';
import 'storage_service.dart';

class ConversionService {
  // ── Excel → PDF ──────────────────────────────────────────────

  Future<File?> pickAndConvertExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return null;

    final file = File(result.files.single.path!);
    final bytes = file.readAsBytesSync();
    final tableData = _parseXlsx(bytes);

    if (tableData.isEmpty) throw Exception('Excel file is empty.');

    final pdfDocument = PdfDocument();
    final page = pdfDocument.pages.add();
    final grid = PdfGrid();

    final colCount = tableData
        .map((r) => r.length)
        .reduce((a, b) => a > b ? a : b);

    grid.columns.add(count: colCount);

    for (int i = 0; i < tableData.length; i++) {
      final pdfRow = grid.rows.add();
      for (int j = 0; j < colCount; j++) {
        pdfRow.cells[j].value = tableData[i].length > j ? tableData[i][j] : '';
      }
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 0),
    );

    final pdfFile = await _saveDocument(await pdfDocument.save(), 'pdf');
    pdfDocument.dispose();
    return pdfFile;
  }

  List<List<String>> _parseXlsx(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    return sheet.rows.map((row) {
      return List.generate(
        sheet.maxColumns,
        (j) => j < row.length ? (row[j]?.value?.toString() ?? '') : '',
      );
    }).toList();
  }

  // ── Images → PDF ─────────────────────────────────────────────

  static Future<String> generatePdf(List<File> images) async {
    final pdf = pw.Document();

    for (var image in images) {
      final img = pw.MemoryImage(image.readAsBytesSync());
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(img))));
    }

    final dir = await StorageService.getAppDirectory();
    final fileName = "conv_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final filePath = "${dir.path}/$fileName";

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  // ── Word (.docx) → PDF ───────────────────────────────────────

  Future<File?> pickAndConvertWordToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result == null) return null;

    final bytes = File(result.files.single.path!).readAsBytesSync();
    final text = docxToText(bytes);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          ...text.split('\n').map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    line.trim(),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ),
        ],
      ),
    );

    return await _saveDocument(await pdf.save(), 'pdf');
  }

  // ── PDF → Word (.docx) ───────────────────────────────────────
  
  Future<File?> pickAndConvertPdfToWord() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return null;

    final bytes = await File(result.files.single.path!).readAsBytes();
    
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(document).extractText();
    
    final docx = Docx();
    docx.addParagraph(text);
    final docxBytes = await docx.save();
    
    document.dispose();
    
    return await _saveDocument(docxBytes!, 'docx');
  }

  // ── Text → Word (.docx) ──────────────────────────────────────

  Future<File?> convertTextToWord(String text) async {
    final docx = Docx();
    docx.addParagraph(text);
    final docxBytes = await docx.save();
    
    return await _saveDocument(docxBytes!, 'docx');
  }

  // ── PowerPoint (.pptx) → PDF ─────────────────────────────────

  Future<File?> pickAndConvertPowerPoint() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx'],
    );

    if (result == null) return null;

    final bytes = File(result.files.single.path!).readAsBytesSync();
    final slides = _extractPptxText(bytes);

    final pdf = pw.Document();

    for (final slideText in slides) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: slideText
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return await _saveDocument(await pdf.save(), 'pdf');
  }

  List<String> _extractPptxText(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final slideTexts = <int, String>{};

    for (final file in archive) {
      final match = RegExp(r'ppt/slides/slide(\d+)\.xml').firstMatch(file.name);
      if (match == null) continue;

      final slideIndex = int.parse(match.group(1)!);
      final xmlString = String.fromCharCodes(file.content as List<int>);
      final document = XmlDocument.parse(xmlString);

      final buffer = StringBuffer();
      for (final node in document.findAllElements('a:t')) {
        final t = node.innerText.trim();
        if (t.isNotEmpty) buffer.writeln(t);
      }

      slideTexts[slideIndex] = buffer.toString();
    }

    final sorted = slideTexts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) => e.value).toList();
  }

  // ── Shared helper ─────────────────────────────────────────────

  Future<File> _saveDocument(List<int> bytes, String extension) async {
    final dir = await StorageService.getAppDirectory();
    final fileName = "conv_${DateTime.now().millisecondsSinceEpoch}.$extension";
    final filePath = "${dir.path}/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
