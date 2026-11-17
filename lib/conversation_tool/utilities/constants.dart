import 'package:flutter/material.dart';

class AppConstants {
  // File extensions
  static const List<String> pdfExtensions = ['pdf'];
  static const List<String> wordExtensions = ['doc', 'docx'];
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];

  // Conversion types
  static const String pdfToWord = 'PDF to Word';
  static const String wordToPdf = 'Word to PDF';
  static const String imageToPdf = 'Image to PDF';
  static const String multipleImagesToPdf = 'Multiple Images to PDF';
  static const String excelToPdf = 'Excel to PDF';
  static const String pptToPdf = 'PowerPoint to PDF';
  static const String textToWord = 'Text to Word';


  // Colors
  static const Color pdfColor = Colors.red;
  static const Color wordColor = Colors.blue;
  static const Color imageColor = Colors.green;
  static const Color multipleColor = Colors.orange;
  static const Color excelColor = Colors.green;
  static const Color pptColor = Colors.deepOrange;
  static const Color textColor = Colors.teal;


  // Icons
  static const IconData pdfIcon = Icons.picture_as_pdf;
  static const IconData wordIcon = Icons.description;
  static const IconData imageIcon = Icons.image;
  static const IconData multipleIcon = Icons.collections;
  static const IconData excelIcon = Icons.table_chart;
  static const IconData pptIcon = Icons.slideshow;
  static const IconData textIcon = Icons.text_fields;


  // PDF settings
  static const int maxLinesPerPage = 40;
  static const double pdfFontSize = 12.0;
  static const double pdfLineSpacing = 5.0;
}

class AppStrings {
  static const String appTitle = 'Offline Document Converter';
  static const String noConversions = 'No conversions yet';
  static const String tapToStart = 'Tap the + button to start converting';
  static const String noInternet = 'No internet required!';
  static const String clearHistory = 'Clear History';

  // Error messages
  static const String filePickError = 'Error picking file';
  static const String conversionError = 'Conversion failed';
  static const String noTextFound = 'No text found in document';

  // Success messages
  static const String conversionSuccess = 'Conversion successful!';
}