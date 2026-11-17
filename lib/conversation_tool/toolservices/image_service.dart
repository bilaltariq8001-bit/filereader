import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageService {
  /// Check if image is landscape
  static Future<bool> isLandscape(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('Could not decode image');
      }

      return decodedImage.width > decodedImage.height;
    } catch (e) {
      throw Exception('Failed to check image orientation: $e');
    }
  }

  /// Get image bytes
  static Future<Uint8List> getImageBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read image: $e');
    }
  }

  /// Validate image file
  static Future<bool> validateImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      return decodedImage != null;
    } catch (e) {
      return false;
    }
  }
}