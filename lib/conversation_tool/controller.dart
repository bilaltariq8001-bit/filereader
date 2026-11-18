import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:documentreader/conversation_tool/toolservices/pdftool_services.dart';
import 'package:documentreader/conversation_tool/toolservices/words_services.dart';
import 'package:documentreader/conversation_tool/utilities/constants.dart';
import 'package:documentreader/conversation_tool/utilities/file_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart' show Rect, ChangeNotifier;

import 'model/conversion_history.dart';
import 'model/conversion_status.dart';

/// All conversions below parse and build whole documents. They run in a
/// background isolate (compute) so the UI keeps animating; doing this on
/// the UI thread froze the app for seconds on larger files.

const String _fontAsset = 'assets/fonts/Inter.ttf';
const String _historyKey = 'conversion_history';

class DocumentConverterProvider extends ChangeNotifier {
  DocumentConverterProvider() {
    _loadHistory();
  }

  // State
  ConversionStatus _status = const ConversionStatus(
    state: ConversionState.idle,
  );
  final List<ConversionHistory> _history = [];
  ByteData? _font;

  // Getters
  ConversionStatus get status => _status;
  List<ConversionHistory> get history => List.unmodifiable(_history);
  bool get isConverting => _status.isLoading;

  // Update status
  void _updateStatus(ConversionStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<ByteData?> _loadFont() async {
    try {
      return _font ??= await rootBundle.load(_fontAsset);
    } catch (e) {
      debugPrint('Font load failed, using built-in PDF font: $e');
      return null;
    }
  }

  // History is kept across app restarts; entries whose output file was
  // removed are dropped.
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(_historyKey) ?? [];
      final List<ConversionHistory> items = [];
      for (final String raw in stored) {
        try {
          final item = ConversionHistory.fromJson(
              jsonDecode(raw) as Map<String, dynamic>);
          if (await File(item.outputPath).exists()) items.add(item);
        } catch (_) {}
      }
      _history
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load conversion history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _historyKey,
        _history.map((h) => jsonEncode(h.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('Could not save conversion history: $e');
    }
  }

  // Add to history
  void _addToHistory(ConversionHistory item) {
    _history.insert(0, item);
    notifyListeners();
    _saveHistory();
  }

  // Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
    _saveHistory();
  }

  ConversionStatus _error(String message, Object e) => ConversionStatus(
        state: ConversionState.error,
        message: message,
        errorMessage: e.toString(),
      );

  // ==================== PDF TO WORD ====================
  Future<File?> convertPdfToWord(File pdfFile) async {
    try {
      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading PDF...',
        progress: 0.1,
      ));

      final Uint8List bytes = await pdfFile.readAsBytes();

      _updateStatus(_status.copyWith(
        message: 'Extracting text...',
        progress: 0.3,
      ));

      final Uint8List docxBytes = await compute(pdfBytesToDocx, bytes);

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.8,
      ));

      final fileName = FileHelper.generateFileName('pdf_to_word', 'docx');
      final outputFile = await FileHelper.saveFile(docxBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: AppConstants.pdfToWord,
        inputPath: pdfFile.path,
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('PDF to Word conversion failed', e));
      return null;
    }
  }

  // ==================== WORD TO PDF ====================
  Future<File?> convertWordToPdf(File wordFile) async {
    try {
      if (wordFile.path.toLowerCase().endsWith('.doc')) {
        throw Exception(
            'Old .doc files are not supported. Please use a .docx file.');
      }

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading Word document...',
        progress: 0.0,
      ));

      final bytes = await wordFile.readAsBytes();
      final ByteData? font = await _loadFont();

      _updateStatus(_status.copyWith(
        message: 'Creating PDF...',
        progress: 0.4,
      ));

      final Uint8List pdfBytes = await compute(docxBytesToPdf, (bytes, font));

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.8,
      ));

      final fileName = FileHelper.generateFileName('word_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: AppConstants.wordToPdf,
        inputPath: wordFile.path,
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('Word to PDF conversion failed', e));
      return null;
    }
  }

  // ==================== IMAGE TO PDF ====================
  Future<File?> convertImageToPdf(File imageFile) async {
    final File? result = await convertMultipleImagesToPdf([imageFile]);
    return result;
  }

  // ==================== MULTIPLE IMAGES TO PDF ====================
  Future<File?> convertMultipleImagesToPdf(List<File> imageFiles) async {
    try {
      _updateStatus(ConversionStatus(
        state: ConversionState.loading,
        message: imageFiles.length == 1
            ? 'Processing image...'
            : 'Processing ${imageFiles.length} images...',
        progress: 0.1,
      ));

      final List<String> paths = imageFiles.map((f) => f.path).toList();
      final Uint8List pdfBytes = await compute(imagesToPdf, paths);

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.9,
      ));

      final bool single = imageFiles.length == 1;
      final fileName = FileHelper.generateFileName(
          single ? 'image_to_pdf' : 'merged_images', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: single
            ? AppConstants.imageToPdf
            : AppConstants.multipleImagesToPdf,
        inputPath: single ? imageFiles.first.path : 'Multiple files',
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('Images to PDF conversion failed', e));
      return null;
    }
  }

  // ==================== PICK AND CONVERT METHODS ====================

  Future<File?> pickAndConvertPdfToWord() async {
    final file = await FileHelper.pickFile(
      allowedExtensions: AppConstants.pdfExtensions,
    );
    if (file != null) {
      return await convertPdfToWord(file);
    }
    return null;
  }

  Future<File?> pickAndConvertWordToPdf() async {
    final file = await FileHelper.pickFile(
      allowedExtensions: AppConstants.wordExtensions,
    );
    if (file != null) {
      return await convertWordToPdf(file);
    }
    return null;
  }

  Future<void> pickAndConvertImageToPdf() async {
    final file = await FileHelper.pickFile(
      allowedExtensions: AppConstants.imageExtensions,
    );
    if (file != null) {
      await convertImageToPdf(file);
    }
  }

  Future<File?> pickAndConvertMultipleImagesToPdf() async {
    final files = await FileHelper.pickMultipleFiles(
      type: FileType.image,
    );
    if (files != null && files.isNotEmpty) {
      return await convertMultipleImagesToPdf(files);
    }
    return null;
  }

  // ==================== EXCEL TO PDF ====================
  Future<File?> pickAndConvertExcelToPdf() async {
    try {
      final file = await FileHelper.pickFile(allowedExtensions: ['xlsx']);
      if (file == null) return null;

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading Excel file...',
        progress: 0.1,
      ));

      final bytes = await file.readAsBytes();

      _updateStatus(_status.copyWith(
        message: 'Creating PDF layout...',
        progress: 0.4,
      ));

      final Uint8List pdfBytes = await compute(excelBytesToPdf, bytes);

      _updateStatus(_status.copyWith(
        message: 'Saving PDF...',
        progress: 0.8,
      ));

      final fileName = FileHelper.generateFileName('excel_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: AppConstants.excelToPdf,
        inputPath: file.path,
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: 'Excel converted to PDF successfully',
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('Excel to PDF conversion failed', e));
      return null;
    }
  }

  // ==================== PPT TO PDF ====================
  Future<File?> pickAndConvertPptToPdf() async {
    try {
      final file = await FileHelper.pickFile(allowedExtensions: ['pptx']);
      if (file == null) return null;

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading PowerPoint file...',
        progress: 0.1,
      ));

      final bytes = await file.readAsBytes();
      final ByteData? font = await _loadFont();

      _updateStatus(_status.copyWith(
        message: 'Generating PDF slides...',
        progress: 0.5,
      ));

      final Uint8List pdfBytes =
          await compute(pptxBytesToPdf, (bytes, font));

      final fileName = FileHelper.generateFileName('ppt_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: AppConstants.pptToPdf,
        inputPath: file.path,
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: 'PowerPoint converted to PDF successfully',
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('PowerPoint to PDF conversion failed', e));
      return null;
    }
  }

  // ==================== TEXT TO WORD ====================
  Future<File?> convertTextToWord(String text) async {
    try {
      if (text.trim().isEmpty) throw Exception('Text is empty');

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Creating Word document...',
        progress: 0.4,
      ));

      final Uint8List docxBytes = await WordService.createDocxFromText(text);

      final fileName = FileHelper.generateFileName('text_to_word', 'docx');
      final outputFile = await FileHelper.saveFile(docxBytes, fileName);

      _addToHistory(ConversionHistory.create(
        type: AppConstants.textToWord,
        inputPath: 'Typed text',
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(_error('Text to Word conversion failed', e));
      return null;
    }
  }

  // Reset status
  void resetStatus() {
    _updateStatus(const ConversionStatus(
      state: ConversionState.idle,
    ));
  }
}

// ==================== ISOLATE WORKERS ====================
// Top-level so compute() can send them to a background isolate.

Future<Uint8List> pdfBytesToDocx(Uint8List bytes) async {
  final List<String> pages = PdfService.extractPagesFromPdfBytes(bytes);
  if (pages.every((p) => p.trim().isEmpty)) {
    throw Exception('No text found in this PDF. It may be a scanned image.');
  }
  return WordService.createDocxFromPages(pages);
}

Future<Uint8List> docxBytesToPdf((Uint8List, ByteData?) input) async {
  final extractedText = await WordService.extractTextFromDocx(input.$1);
  return PdfService.createPdfFromText(extractedText, fontData: input.$2);
}

Future<Uint8List> imagesToPdf(List<String> paths) async {
  final pdf = pw.Document();
  int added = 0;
  for (final String path in paths) {
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      // Reading the header is enough to validate the image and get its
      // size; the old code fully decoded every photo twice.
      final img.Decoder? decoder = img.findDecoderForData(bytes);
      final img.DecodeInfo? info = decoder?.startDecode(bytes);
      if (info == null || info.width == 0 || info.height == 0) continue;

      final bool isLandscape = info.width > info.height;
      final pw.ImageProvider image = _pdfImage(bytes, decoder!);
      pdf.addPage(
        pw.Page(
          pageFormat: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
      added++;
    } catch (_) {
      // Skip unreadable images, like the original implementation.
    }
  }
  if (added == 0) throw Exception('No valid images found');
  return pdf.save();
}

/// JPEG and PNG embed directly; other formats (WebP, BMP, ...) are decoded
/// and re-encoded as PNG, which the PDF format supports.
pw.ImageProvider _pdfImage(Uint8List bytes, img.Decoder decoder) {
  if (decoder is img.JpegDecoder || decoder is img.PngDecoder) {
    return pw.MemoryImage(bytes);
  }
  final img.Image? decoded = decoder.decode(bytes);
  if (decoded == null) throw Exception('Could not decode image');
  return pw.MemoryImage(img.encodePng(decoded));
}

/// Many spreadsheet tools (Google Sheets, LibreOffice exports, openpyxl)
/// write absolute part paths such as `/xl/worksheets/sheet1.xml` in
/// `workbook.xml.rels`. The excel package only resolves relative paths and
/// crashes with a null check on those files, so rewrite them first.
Uint8List normalizeXlsxBytes(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final rels = archive.findFile('xl/_rels/workbook.xml.rels');
    if (rels == null) return bytes;
    final String xml = utf8.decode(rels.content as List<int>);
    if (!xml.contains('Target="/xl/')) return bytes;
    final fixed = utf8.encode(xml.replaceAll('Target="/xl/', 'Target="'));
    final out = Archive();
    for (final f in archive.files) {
      if (f.name == rels.name) {
        out.addFile(ArchiveFile(f.name, fixed.length, fixed));
      } else {
        out.addFile(f);
      }
    }
    final encoded = ZipEncoder().encode(out);
    return encoded == null ? bytes : Uint8List.fromList(encoded);
  } catch (_) {
    return bytes;
  }
}

Future<Uint8List> excelBytesToPdf(Uint8List bytes) async {
  final excel_pkg.Excel excel;
  try {
    excel = excel_pkg.Excel.decodeBytes(normalizeXlsxBytes(bytes));
  } catch (e) {
    throw Exception('This Excel file could not be read.');
  }
  if (excel.tables.isEmpty) throw Exception('Excel file is empty.');
  final sheet = excel.tables[excel.tables.keys.first];
  if (sheet == null || sheet.maxRows == 0 || sheet.maxColumns == 0) {
    throw Exception('Excel file is empty.');
  }

  final tableData = sheet.rows.map((row) {
    return List.generate(
      sheet.maxColumns,
      (j) => j < row.length ? (row[j]?.value?.toString() ?? '') : '',
    );
  }).toList();

  final pdfDocument = sf_pdf.PdfDocument();
  try {
    final page = pdfDocument.pages.add();
    final grid = sf_pdf.PdfGrid();
    grid.columns.add(count: sheet.maxColumns);
    for (final List<String> rowData in tableData) {
      final pdfRow = grid.rows.add();
      for (int j = 0; j < sheet.maxColumns; j++) {
        pdfRow.cells[j].value = rowData[j];
      }
    }
    // Draws across as many pages as the table needs.
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 0),
    );
    final List<int> pdfBytes = await pdfDocument.save();
    return Uint8List.fromList(pdfBytes);
  } finally {
    pdfDocument.dispose();
  }
}

Future<Uint8List> pptxBytesToPdf((Uint8List, ByteData?) input) async {
  final Uint8List bytes = input.$1;
  final ByteData? font = input.$2;
  final archive = ZipDecoder().decodeBytes(bytes);
  final slideTexts = <int, String>{};

  for (final zipFile in archive) {
    final match = RegExp(r'^ppt/slides/slide(\d+)\.xml$').firstMatch(zipFile.name);
    if (match == null) continue;

    final slideIndex = int.parse(match.group(1)!);
    // Slide XML is UTF-8; fromCharCodes garbled non-ASCII text.
    final xmlString =
        utf8.decode(zipFile.content as List<int>, allowMalformed: true);
    final document = XmlDocument.parse(xmlString);

    final buffer = StringBuffer();
    for (final node in document.findAllElements('a:t')) {
      final t = node.innerText.trim();
      if (t.isNotEmpty) buffer.writeln(t);
    }
    slideTexts[slideIndex] = buffer.toString();
  }

  if (slideTexts.isEmpty) {
    throw Exception('No slides found in this file.');
  }

  final sorted = slideTexts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final pdf = font == null
      ? pw.Document()
      : pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.ttf(font)));

  for (final entry in sorted) {
    final lines = entry.value
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    // MultiPage: a text-heavy slide continues on the next page instead of
    // failing with an overflow.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => lines.isEmpty
            ? [pw.SizedBox()]
            : lines
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
    );
  }

  return pdf.save();
}
