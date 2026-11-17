

import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Constants for file extensions.
class Constants {
  static const String doc = '.doc';
  static const String docx = '.docx';
  static const String pdf = '.pdf';
  static const String ppt = '.ppt';
  static const String pptx = '.pptx';
  static const String xls = '.xls';
  static const String xlsx = '.xlsx';
}

List<File> allFiles = [];
List<File> pdfFiles = [];
List<File> wordFiles = [];
List<File> pptFiles = [];
List<File> excelFiles = [];

List<File> bookmarkedFiles = [];
List<File> bookmarkedPdfFiles = [];
List<File> bookmarkedWordFiles = [];
List<File> bookmarkedPptFiles = [];
List<File> bookmarkedExcelFiles = [];

Future<void> saveBookmarks() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> paths = bookmarkedFiles.map((file) => file.path).toList();
  prefs.setStringList("bookmarks", paths);
}

