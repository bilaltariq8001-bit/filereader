import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request storage permission
  Future<bool> requestStoragePermission({
    required VoidCallback onPermissionDenied,
  }) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final PermissionStatus storageStatus = await Permission.storage.status;
    final PermissionStatus manageStorageStatus =
    await Permission.manageExternalStorage.status;

    if (storageStatus.isGranted || manageStorageStatus.isGranted) {
      return true;
    }

    final Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    final bool granted = statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.manageExternalStorage]?.isGranted == true;

    if (!granted) {
      onPermissionDenied();
    }

    return granted;
  }

  /// Show permission denied dialog
  void showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to access your documents. '
              'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}