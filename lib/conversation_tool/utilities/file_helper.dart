import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  /// Pick a single file with allowed extensions
  static Future<File?> pickFile({
    required List<String> allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      debugPrint('pickFile($allowedExtensions): '
          '${result == null ? 'cancelled' : result.files.map((f) => '${f.name} path=${f.path}').join(', ')}');

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
    return null;
  }

  /// Pick multiple files
  static Future<List<File>?> pickMultipleFiles({
    required FileType type,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
    } catch (e) {
      throw Exception('Failed to pick files: $e');
    }
    return null;
  }

  /// Save file to device
  static Future<File> saveFile(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generate unique filename
  static String generateFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  /// Get file extension
  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Check if file exists
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Delete file
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}