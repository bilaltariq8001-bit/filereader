import 'dart:io';
import 'package:flutter/foundation.dart';
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

class BookmarkToggleResult extends BookmarkData {
  final bool isBookmarked;

  BookmarkToggleResult({
    required this.isBookmarked,
    required super.bookmarkedFiles,
    required super.bookmarkedPdfFiles,
    required super.bookmarkedWordFiles,
    required super.bookmarkedPptFiles,
    required super.bookmarkedExcelFiles,
  });
}

/// Single source of truth for bookmarks, shared by every screen.
///
/// Bookmarks are stored as file paths, and every comparison is done by path:
/// two `File` objects for the same path are not `==` in Dart, which used to
/// make toggling add duplicates instead of removing the bookmark.
class BookmarkService {
  static const String _prefsKey = 'bookmarks';

  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  final List<String> _paths = [];
  bool _loaded = false;

  List<String> get paths => List.unmodifiable(_paths);

  /// Forget the in-memory copy so the next call reloads from storage.
  @visibleForTesting
  void resetForTest() {
    _paths.clear();
    _loaded = false;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_prefsKey) ?? [];
    _paths
      ..clear()
      ..addAll(stored.toSet());
    _loaded = true;
  }

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, List<String>.from(_paths));
  }

  BookmarkData _snapshot() {
    final List<File> all = _paths.map((p) => File(p)).toList();
    List<File> by(List<String> exts) => all
        .where((f) => exts.any((e) => f.path.toLowerCase().endsWith(e)))
        .toList();
    return BookmarkData(
      bookmarkedFiles: all,
      bookmarkedPdfFiles: by([Constants.pdf]),
      bookmarkedWordFiles: by([Constants.doc, Constants.docx]),
      bookmarkedPptFiles: by([Constants.ppt, Constants.pptx]),
      bookmarkedExcelFiles: by([Constants.xls, Constants.xlsx]),
    );
  }

  /// Load bookmarks. When [dropMissing] is true, bookmarks whose file no
  /// longer exists are removed and the cleaned list is saved.
  Future<BookmarkData> loadBookmarks({bool dropMissing = false}) async {
    await _ensureLoaded();
    if (dropMissing) {
      final List<String> existing = [];
      for (final String p in _paths) {
        if (await File(p).exists()) existing.add(p);
      }
      if (existing.length != _paths.length) {
        _paths
          ..clear()
          ..addAll(existing);
        await _save();
      }
    }
    return _snapshot();
  }

  /// Toggle bookmark for a file
  Future<BookmarkToggleResult> toggleBookmark(File file) async {
    await _ensureLoaded();
    final bool wasBookmarked = _paths.contains(file.path);
    if (wasBookmarked) {
      _paths.remove(file.path);
    } else {
      _paths.add(file.path);
    }
    await _save();
    final BookmarkData d = _snapshot();
    return BookmarkToggleResult(
      isBookmarked: !wasBookmarked,
      bookmarkedFiles: d.bookmarkedFiles,
      bookmarkedPdfFiles: d.bookmarkedPdfFiles,
      bookmarkedWordFiles: d.bookmarkedWordFiles,
      bookmarkedPptFiles: d.bookmarkedPptFiles,
      bookmarkedExcelFiles: d.bookmarkedExcelFiles,
    );
  }

  Future<BookmarkData> addBookmark(String path) async {
    await _ensureLoaded();
    if (!_paths.contains(path)) {
      _paths.add(path);
      await _save();
    }
    return _snapshot();
  }

  Future<BookmarkData> removeBookmark(String path) async {
    await _ensureLoaded();
    if (_paths.remove(path)) await _save();
    return _snapshot();
  }

  /// Update a bookmarked file after rename
  Future<BookmarkData> updateBookmarkedFile(File oldFile, File newFile) async {
    await _ensureLoaded();
    final int index = _paths.indexOf(oldFile.path);
    if (index != -1) {
      _paths[index] = newFile.path;
      await _save();
    }
    return _snapshot();
  }

  /// Check if a file is bookmarked
  bool isBookmarked(File file) => _paths.contains(file.path);
}
