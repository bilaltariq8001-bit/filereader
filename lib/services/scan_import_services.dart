import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_services.dart';

class CachedFileData {
  final List<File> allFiles;
  CachedFileData(this.allFiles);
}

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

    List<String> paths = List<String>.from(jsonDecode(data));
    return paths
        .map((p) => File(p))
        .where((file) => file.existsSync())
        .toList();
  }
}
