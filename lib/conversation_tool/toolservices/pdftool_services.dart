import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../utilities/constants.dart';

class PdfService {
  /// Extract text from PDF file
  static Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final extractor = sf.PdfTextExtractor(document);

      String extractedText = '';

      for (int i = 0; i < document.pages.count; i++) {
        extractedText += extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        extractedText += '\n\n--- Page ${i + 1} ---\n\n';
      }

      document.dispose();

      return extractedText.isNotEmpty
          ? extractedText
          : AppStrings.noTextFound;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }
  static Future<Uint8List> createPdfFromText(String text) async {
    try {
      final pdf = pw.Document();

      final lines = text.split('\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => lines.map((line) {
            return _buildStyledLine(line);
          }).toList(),
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to create PDF: $e');
    }
  }

  static pw.Widget _buildStyledLine(String line) {
    if (line.trim().isEmpty) {
      return pw.SizedBox(height: AppConstants.pdfLineSpacing * 2);
    }

    if (line.startsWith('### ')) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: AppConstants.pdfLineSpacing),
        child: pw.Text(
          line.substring(4),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    if (line.startsWith('## ')) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: AppConstants.pdfLineSpacing + 1),
        child: pw.Text(
          line.substring(3),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    if (line.startsWith('# ')) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: AppConstants.pdfLineSpacing + 2),
        child: pw.Text(
          line.substring(2),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: AppConstants.pdfLineSpacing),
      child: pw.Text(
        line,
        style: pw.TextStyle(
          fontSize: AppConstants.pdfFontSize,
        ),
      ),
    );
  }

  /// Create PDF from text
  // static Future<Uint8List> createPdfFromText(String text) async {
  //   try {
  //     final pdf = pw.Document();
  //     final lines = text.split('\n');
  //     List<String> currentPageLines = [];
  //
  //     for (int i = 0; i < lines.length; i++) {
  //       currentPageLines.add(lines[i]);
  //
  //       if (currentPageLines.length >= AppConstants.maxLinesPerPage ||
  //           i == lines.length - 1) {
  //         pdf.addPage(
  //           pw.Page(
  //             pageFormat: PdfPageFormat.a4,
  //             build: (context) {
  //               return pw.pw.MultiPage( // ✅ prevents overflow
  //                 child: pw.Column(
  //                   crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                   children: currentPageLines.map((line) {
  //                     return pw.Padding(
  //                       padding: pw.EdgeInsets.only(
  //                         bottom: AppConstants.pdfLineSpacing,
  //                       ),
  //                       child: pw.Text(
  //                         line,
  //                         style: pw.TextStyle(
  //                           fontSize: AppConstants.pdfFontSize,
  //                         ),
  //                       ),
  //                     );
  //                   }).toList(),
  //                 ),
  //               );
  //             },
  //           ),
  //         );
  //         currentPageLines = [];
  //       }
  //     }
  //
  //     return await pdf.save();
  //   } catch (e) {
  //     throw Exception('Failed to create PDF: $e');
  //   }
  // }

  /// Create PDF from single image
  static Future<Uint8List> createPdfFromImage(
      Uint8List imageBytes,
      bool isLandscape,
      ) async {
    try {
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(imageBytes);

      final pageFormat = isLandscape
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4;

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          ),
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to create PDF from image: $e');
    }
  }

  /// Create PDF from multiple images
  static Future<Uint8List> createPdfFromMultipleImages(
      List<Uint8List> imagesBytes,
      List<bool> landscapeFlags,
      ) async {
    try {
      final pdf = pw.Document();

      for (int i = 0; i < imagesBytes.length; i++) {
        final pdfImage = pw.MemoryImage(imagesBytes[i]);
        final pageFormat = landscapeFlags[i]
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (_) => pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to create PDF from multiple images: $e');
    }
  }
}
