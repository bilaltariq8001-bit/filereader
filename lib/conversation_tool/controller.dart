import 'dart:io';
import 'dart:typed_data';
import 'package:documentreader/conversation_tool/toolservices/image_service.dart';
import 'package:documentreader/conversation_tool/toolservices/pdftool_services.dart';
import 'package:documentreader/conversation_tool/toolservices/words_services.dart';
import 'package:documentreader/conversation_tool/utilities/constants.dart';
import 'package:documentreader/conversation_tool/utilities/file_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart' show Rect, ChangeNotifier;


import 'model/conversion_history.dart';
import 'model/conversion_status.dart';

class DocumentConverterProvider extends ChangeNotifier {
  // State
  ConversionStatus _status = const ConversionStatus(
    state: ConversionState.idle,
  );
  List<ConversionHistory> _history = [];

  // Getters
  ConversionStatus get status => _status;
  List<ConversionHistory> get history => List.unmodifiable(_history);
  bool get isConverting => _status.isLoading;

  // Update status
  void _updateStatus(ConversionStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // Add to history
  void _addToHistory(ConversionHistory item) {
    _history.insert(0, item);
    notifyListeners();
  }

  // Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ===============================
  // PDF to Word Conversion
  // ===============================
  Future<File?> convertPdfToWord(File pdfFile) async {
    try {
      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Preparing conversion...',
        progress: 0.2,
      ));

      _updateStatus(_status.copyWith(
        message: 'Checking DOCX generator support...',
        progress: 0.6,
      ));

      throw Exception(
        'PDF to Word is currently unavailable because DOCX writer dependency '
        'conflicts with current package versions.',
      );

    } catch (e) {
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'PDF to Word conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // Word to PDF Conversion
  // ===============================
  Future<File?> convertWordToPdf(File wordFile) async {
    try {
      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading Word document...',
        progress: 0.0,
      ));

      // Read Word file
      final bytes = await wordFile.readAsBytes();

      _updateStatus(_status.copyWith(
        message: 'Extracting text...',
        progress: 0.2,
      ));

      // Extract text
      final extractedText = await WordService.extractTextFromDocx(bytes);

      _updateStatus(_status.copyWith(
        message: 'Creating PDF...',
        progress: 0.5,
      ));

      // Create PDF
      final pdfBytes = await PdfService.createPdfFromText(extractedText);

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.8,
      ));

      // Save file
      final fileName = FileHelper.generateFileName('word_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      // Add to history
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
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'Word to PDF conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // Image to PDF Conversion
  // ===============================
  Future<File?> convertImageToPdf(File imageFile) async {
    try {
      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Loading image...',
        progress: 0.0,
      ));

      // Validate image
      final isValid = await ImageService.validateImage(imageFile);
      if (!isValid) {
        throw Exception('Invalid image file');
      }

      _updateStatus(_status.copyWith(
        message: 'Processing image...',
        progress: 0.3,
      ));

      // Get image properties
      final imageBytes = await ImageService.getImageBytes(imageFile);
      final isLandscape = await ImageService.isLandscape(imageFile);

      _updateStatus(_status.copyWith(
        message: 'Creating PDF...',
        progress: 0.6,
      ));

      // Create PDF
      final pdfBytes = await PdfService.createPdfFromImage(
        imageBytes,
        isLandscape,
      );

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.8,
      ));

      // Save file
      final fileName = FileHelper.generateFileName('image_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      // Add to history
      _addToHistory(ConversionHistory.create(
        type: AppConstants.imageToPdf,

        inputPath: imageFile.path,
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'Image to PDF conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // Multiple Images to PDF
  // ===============================
  Future<File?> convertMultipleImagesToPdf(List<File> imageFiles) async {
    try {
      _updateStatus(ConversionStatus(
        state: ConversionState.loading,
        message: 'Processing ${imageFiles.length} images...',
        progress: 0.0,
      ));

      final imagesBytes = <Uint8List>[];
      final landscapeFlags = <bool>[];

      // Process each image
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];

        // Validate
        final isValid = await ImageService.validateImage(imageFile);
        if (!isValid) continue;

        // Get bytes and orientation
        final bytes = await ImageService.getImageBytes(imageFile);
        final isLandscape = await ImageService.isLandscape(imageFile);

        imagesBytes.add(bytes);
        landscapeFlags.add(isLandscape);

        _updateStatus(_status.copyWith(
          progress: (i + 1) / imageFiles.length * 0.7,
        ));
      }

      if (imagesBytes.isEmpty) {
        throw Exception('No valid images found');
      }

      _updateStatus(_status.copyWith(
        message: 'Creating PDF...',
        progress: 0.7,
      ));

      // Create PDF
      final pdfBytes = await PdfService.createPdfFromMultipleImages(
        imagesBytes,
        landscapeFlags,
      );

      _updateStatus(_status.copyWith(
        message: 'Saving file...',
        progress: 0.9,
      ));

      // Save file
      final fileName = FileHelper.generateFileName('merged_images', 'pdf');
      final outputFile = await FileHelper.saveFile(pdfBytes, fileName);

      // Add to history
      _addToHistory(ConversionHistory.create(
        type: AppConstants.multipleImagesToPdf,

        inputPath: 'Multiple files',
        outputPath: outputFile.path,
      ));

      _updateStatus(const ConversionStatus(
        state: ConversionState.success,
        message: AppStrings.conversionSuccess,
        progress: 1.0,
      ));

      return outputFile;
    } catch (e) {
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'Multiple images to PDF conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // File Picking Helpers
  // ===============================
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

  // ===============================
  // Excel to PDF Conversion
  // ===============================
  Future<File?> pickAndConvertExcelToPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return null;

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading Excel file...',
        progress: 0.1,
      ));

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null) throw Exception('Excel file is empty.');

      _updateStatus(_status.copyWith(
        message: 'Creating PDF layout...',
        progress: 0.4,
      ));

      final pdfDocument = sf_pdf.PdfDocument();
      final page = pdfDocument.pages.add();
      final grid = sf_pdf.PdfGrid();

      final tableData = sheet.rows.map((row) {
        return List.generate(
          sheet.maxColumns,
          (j) => j < row.length ? (row[j]?.value?.toString() ?? '') : '',
        );
      }).toList();

      final colCount = tableData.isEmpty ? 0 : tableData
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

      _updateStatus(_status.copyWith(
        message: 'Saving PDF...',
        progress: 0.8,
      ));

      final List<int> pdfBytes = await pdfDocument.save();
      pdfDocument.dispose();

      final fileName = FileHelper.generateFileName('excel_to_pdf', 'pdf');
      final outputFile = await FileHelper.saveFile(Uint8List.fromList(pdfBytes), fileName);

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
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'Excel to PDF conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // PowerPoint to PDF Conversion
  // ===============================
  Future<File?> pickAndConvertPptToPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx'],
      );

      if (result == null) return null;

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Reading PowerPoint file...',
        progress: 0.1,
      ));

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      final archive = ZipDecoder().decodeBytes(bytes);
      final slideTexts = <int, String>{};

      for (final zipFile in archive) {
        final match = RegExp(r'ppt/slides/slide(\d+)\.xml').firstMatch(zipFile.name);
        if (match == null) continue;

        final slideIndex = int.parse(match.group(1)!);
        final xmlString = String.fromCharCodes(zipFile.content as List<int>);
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
      final slides = sorted.map((e) => e.value).toList();

      _updateStatus(_status.copyWith(
        message: 'Generating PDF slides...',
        progress: 0.5,
      ));

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

      final pdfBytes = await pdf.save();
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
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'PowerPoint to PDF conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // Text to Word Conversion
  // ===============================
  Future<File?> convertTextToWord(String text) async {
    try {
      if (text.isEmpty) throw Exception('Text is empty');

      _updateStatus(const ConversionStatus(
        state: ConversionState.loading,
        message: 'Creating Word document...',
        progress: 0.4,
      ));

      throw Exception(
        'Text to Word is currently unavailable because DOCX writer dependency '
        'conflicts with current package versions.',
      );

    } catch (e) {
      _updateStatus(ConversionStatus(
        state: ConversionState.error,
        message: 'Text to Word conversion failed',
        errorMessage: e.toString(),
      ));
      return null;
    }
  }


  // Reset status to idle
  void resetStatus() {
    _updateStatus(const ConversionStatus(
      state: ConversionState.idle,
    ));
  }
}