import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/constant.dart';

class BookmarkData {
  final List<File> bookmarkedFiles;
  final List<File> bookmarkedPdfFiles;
  final List<File> bookmarkedWordFiles;
  final List<File> bookmarkedPptFiles;
  final List<File> bookmarkedExcelFiles;

  BookmarkData({
    required this.bookmarkedFiles,
    required this.bookmarkedPdfFiles,
    required this.bookmarkedWordFiles,
    required this.bookmarkedPptFiles,
    required this.bookmarkedExcelFiles,
  });
}

class BookmarkToggleResult {
  final bool isBookmarked;
  final List<File> bookmarkedFiles;
  final List<File> bookmarkedPdfFiles;
  final List<File> bookmarkedWordFiles;
  final List<File> bookmarkedPptFiles;
  final List<File> bookmarkedExcelFiles;

  BookmarkToggleResult({
    required this.isBookmarked,
    required this.bookmarkedFiles,
    required this.bookmarkedPdfFiles,
    required this.bookmarkedWordFiles,
    required this.bookmarkedPptFiles,
    required this.bookmarkedExcelFiles,
  });
}

class BookmarkService {
  List<File> _bookmarkedFiles = [];
  List<File> _bookmarkedPdfFiles = [];
  List<File> _bookmarkedWordFiles = [];
  List<File> _bookmarkedPptFiles = [];
  List<File> _bookmarkedExcelFiles = [];

  /// Load bookmarks from shared preferences
  Future<BookmarkData> loadBookmarks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? paths = prefs.getStringList("bookmarks");

    _bookmarkedFiles = paths?.map((path) => File(path)).toList() ?? [];

    _bookmarkedPdfFiles = _bookmarkedFiles
        .where((file) => file.path.toLowerCase().endsWith(Constants.pdf))
        .toList();

    _bookmarkedWordFiles = _bookmarkedFiles
        .where((file) =>
    file.path.toLowerCase().endsWith(Constants.doc) ||
        file.path.toLowerCase().endsWith(Constants.docx))
        .toList();

    _bookmarkedPptFiles = _bookmarkedFiles
        .where((file) =>
    file.path.toLowerCase().endsWith(Constants.ppt) ||
        file.path.toLowerCase().endsWith(Constants.pptx))
        .toList();

    _bookmarkedExcelFiles = _bookmarkedFiles
        .where((file) =>
    file.path.toLowerCase().endsWith(Constants.xlsx) ||
        file.path.toLowerCase().endsWith(Constants.xls))
        .toList();

    return BookmarkData(
      bookmarkedFiles: _bookmarkedFiles,
      bookmarkedPdfFiles: _bookmarkedPdfFiles,
      bookmarkedWordFiles: _bookmarkedWordFiles,
      bookmarkedPptFiles: _bookmarkedPptFiles,
      bookmarkedExcelFiles: _bookmarkedExcelFiles,
    );
  }

  /// Toggle bookmark for a file
  Future<BookmarkToggleResult> toggleBookmark(File file) async {
    final bool wasBookmarked = _bookmarkedFiles.contains(file);

    if (wasBookmarked) {
      _removeBookmark(file);
    } else {
      _addBookmark(file);
    }

    await _saveBookmarks();

    return BookmarkToggleResult(
      isBookmarked: !wasBookmarked,
      bookmarkedFiles: _bookmarkedFiles,
      bookmarkedPdfFiles: _bookmarkedPdfFiles,
      bookmarkedWordFiles: _bookmarkedWordFiles,
      bookmarkedPptFiles: _bookmarkedPptFiles,
      bookmarkedExcelFiles: _bookmarkedExcelFiles,
    );
  }

  /// Add a file to bookmarks
  void _addBookmark(File file) {
    _bookmarkedFiles.add(file);

    final String path = file.path.toLowerCase();

    if (path.endsWith(Constants.pdf)) {
      _bookmarkedPdfFiles.add(file);
    } else if (path.endsWith(Constants.doc) || path.endsWith(Constants.docx)) {
      _bookmarkedWordFiles.add(file);
    } else if (path.endsWith(Constants.ppt) || path.endsWith(Constants.pptx)) {
      _bookmarkedPptFiles.add(file);
    } else if (path.endsWith(Constants.xlsx) || path.endsWith(Constants.xls)) {
      _bookmarkedExcelFiles.add(file);
    }
  }

  /// Remove a file from bookmarks
  void _removeBookmark(File file) {
    _bookmarkedFiles.remove(file);
    _bookmarkedPdfFiles.remove(file);
    _bookmarkedWordFiles.remove(file);
    _bookmarkedPptFiles.remove(file);
    _bookmarkedExcelFiles.remove(file);
  }

  /// Save bookmarks to shared preferences
  Future<void> _saveBookmarks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> paths = _bookmarkedFiles.map((file) => file.path).toList();
    await prefs.setStringList("bookmarks", paths);
  }

  /// Update a bookmarked file after rename
  void updateBookmarkedFile(File oldFile, File newFile) {
    void updateFileInList(List<File> list) {
      final int index = list.indexWhere((f) => f.path == oldFile.path);
      if (index != -1) {
        list[index] = newFile;
      }
    }

    updateFileInList(_bookmarkedFiles);
    updateFileInList(_bookmarkedPdfFiles);
    updateFileInList(_bookmarkedWordFiles);
    updateFileInList(_bookmarkedPptFiles);
    updateFileInList(_bookmarkedExcelFiles);

    _saveBookmarks();
  }

  /// Check if a file is bookmarked
  bool isBookmarked(File file) {
    return _bookmarkedFiles.any((f) => f.path == file.path);
  }
}