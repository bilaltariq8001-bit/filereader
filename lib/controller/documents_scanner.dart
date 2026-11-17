// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class DocumentProvider extends ChangeNotifier {
//   List<String> savedFiles = [];
//   bool isScanning = false;
//
//   Future<void> scanDocument() async {
//     isScanning = true;
//     notifyListeners();
//
//     try {
//       var result = await FlutterDocScanner().getScanDocuments(page: 5);
//
//       if (result != null) {
//         for (var path in result) {
//           String newPath = await _saveFilePermanently(File(path));
//           savedFiles.add(newPath);
//         }
//       }
//     } on PlatformException {
//       debugPrint("Scan failed");
//     }
//
//     isScanning = false;
//     notifyListeners();
//   }
//
//   Future<String> _saveFilePermanently(File file) async {
//     _requestPermission();
//     final directory = await getExternalStorageDirectory(); // SAFE location
//     var result = await FlutterDocScanner().getScanDocuments(page: 5);
//     print("Scanner result: $result");
//
//     final newPath =
//         '${directory!.path}/${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
//
//     final newFile = await file.copy(newPath);
//
//     return newFile.path;
//   }
//
//   Future<void> _requestPermission() async {
//     if (Platform.isAndroid) {
//       await Permission.camera.request();
//       await Permission.storage.request();
//       await Permission.manageExternalStorage.request();
//     }
//   }
//
// }
