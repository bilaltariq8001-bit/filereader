import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_services.dart';

class CachedFileData {
  final List<File> allFiles;
  CachedFileData(this.allFiles);
}

List<String> _existingPaths(List<String> paths) =>
    paths.where((p) => File(p).existsSync()).toList();

extension FileCaching on FileService {
  Future<void> cacheFiles(List<File> files) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = files.map((f) => f.path).toList();
    await prefs.setString('cached_files', jsonEncode(paths));
  }

  Future<List<File>?> getCachedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_files');
    if (data == null) return null;

    final List<String> paths = List<String>.from(jsonDecode(data));
    // Checking thousands of paths is file system I/O, keep it off the UI thread.
    final List<String> existing = await Isolate.run(() => _existingPaths(paths));
    return existing.map((p) => File(p)).toList();
  }
}
