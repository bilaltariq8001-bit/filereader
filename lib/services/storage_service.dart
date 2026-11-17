import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<Directory> getAppDirectory() async {
    // Return getApplicationDocumentsDirectory for general storage
    return await getApplicationDocumentsDirectory();
  }
}
