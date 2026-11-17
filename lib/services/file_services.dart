import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../constant/color.dart';
import '../../constant/constant.dart';

class FileLoadResult {
  final List<File> allFiles;
  final List<File> pdfFiles;
  final List<File> wordFiles;
  final List<File> pptFiles;
  final List<File> excelFiles;

  FileLoadResult({
    required this.allFiles,
    required this.pdfFiles,
    required this.wordFiles,
    required this.pptFiles,
    required this.excelFiles,
  });
}

class FileDeleteResult {
  final bool success;
  final List<File> allFiles;
  final List<File> pdfFiles;
  final List<File> wordFiles;
  final List<File> pptFiles;
  final List<File> excelFiles;
  final bool wasBookmarked;
  final List<File>? bookmarkedFiles;
  final List<File>? bookmarkedPdfFiles;
  final List<File>? bookmarkedWordFiles;
  final List<File>? bookmarkedPptFiles;
  final List<File>? bookmarkedExcelFiles;

  FileDeleteResult({
    required this.success,
    required this.allFiles,
    required this.pdfFiles,
    required this.wordFiles,
    required this.pptFiles,
    required this.excelFiles,
    required this.wasBookmarked,
    this.bookmarkedFiles,
    this.bookmarkedPdfFiles,
    this.bookmarkedWordFiles,
    this.bookmarkedPptFiles,
    this.bookmarkedExcelFiles,
  });
}

class FileService {
  /// Load all files from storage
  Future<FileLoadResult> loadAllFiles() async {
    final Directory rootDirectory = Directory('/storage/emulated/0/');

    if (!await rootDirectory.exists()) {
      return FileLoadResult(
        allFiles: [],
        pdfFiles: [],
        wordFiles: [],
        pptFiles: [],
        excelFiles: [],
      );
    }

    final List<FileSystemEntity> allFilesList =
    await _getAllFiles(rootDirectory);

    final List<File> allFiles = allFilesList.whereType<File>().where((file) {
      final String path = file.path.toLowerCase();
      return path.endsWith(Constants.pdf) ||
          path.endsWith(Constants.doc) ||
          path.endsWith(Constants.docx) ||
          path.endsWith(Constants.ppt) ||
          path.endsWith(Constants.pptx) ||
          path.endsWith(Constants.xlsx) ||
          path.endsWith(Constants.xls);
    }).toList();

    return FileLoadResult(
      allFiles: allFiles,
      pdfFiles: _filterFilesByExtension(allFiles, [Constants.pdf]),
      wordFiles: _filterFilesByExtension(allFiles, [Constants.doc, Constants.docx]),
      pptFiles: _filterFilesByExtension(allFiles, [Constants.ppt, Constants.pptx]),
      excelFiles: _filterFilesByExtension(allFiles, [Constants.xlsx, Constants.xls]),
    );
  }

  /// Get all files recursively from a directory
  Future<List<FileSystemEntity>> _getAllFiles(Directory directory) async {
    final List<FileSystemEntity> files = [];

    try {
      await for (final FileSystemEntity entity
      in directory.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        } else if (entity is Directory) {
          try {
            files.addAll(await _getAllFiles(entity));
          } catch (e) {
            // Ignore directories with permission issues
          }
        }
      }
    } catch (e) {
      // Handle directory access errors
    }

    return files;
  }

  /// Filter files by extensions
  List<File> _filterFilesByExtension(List<File> files, List<String> extensions) {
    return files.where((file) {
      final String path = file.path.toLowerCase();
      return extensions.any((ext) => path.endsWith(ext));
    }).toList();
  }

  /// Share a file
  Future<void> shareFile(File file, BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Check out this document",
      );
    } catch (e) {
      print('Error sharing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show rename dialog
  void showRenameDialog({
    required BuildContext context,
    required File file,
    required Function(File oldFile, File newFile) onRenamed,
  }) {
    final String fileName = file.path.split('/').last;
    final String fileExtension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';
    final TextEditingController renameController =
    TextEditingController(text: fileName.replaceAll(fileExtension, ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            "Rename",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: "Inter",
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: renameController,
                cursorColor: Colors.black,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: "Inter",
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Enter new file name",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color_hint),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100.w,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontFamily: "Inter",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100.w,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () async {
                        final String newName = renameController.text.trim();
                        if (newName.isNotEmpty) {
                          final String newFullName = newName + fileExtension;
                          Navigator.pop(context);
                          await _performRename(
                            file: file,
                            newName: newFullName,
                            context: context,
                            onRenamed: onRenamed,
                          );
                        }
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Inter",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Perform file rename
  Future<void> _performRename({
    required File file,
    required String newName,
    required BuildContext context,
    required Function(File oldFile, File newFile) onRenamed,
  }) async {
    try {
      final String newPath = '${file.parent.path}/$newName';
      final File newFile = await file.rename(newPath);

      onRenamed(file, newFile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File renamed successfully")),
      );
    } catch (e) {
      print('Error renaming file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error renaming file")),
      );
    }
  }

  /// Update file in multiple lists
  void updateFileInLists({
    required File oldFile,
    required File newFile,
    required List<File> allFiles,
    required List<File> pdfFiles,
    required List<File> wordFiles,
    required List<File> pptFiles,
    required List<File> excelFiles,
  }) {
    void updateFileInList(List<File> list) {
      final int index = list.indexWhere((f) => f.path == oldFile.path);
      if (index != -1) {
        list[index] = newFile;
      }
    }

    updateFileInList(allFiles);
    updateFileInList(pdfFiles);
    updateFileInList(wordFiles);
    updateFileInList(pptFiles);
    updateFileInList(excelFiles);
  }

  /// Show delete confirmation dialog
  void showDeleteConfirmation({
    required BuildContext context,
    required File file,
    required VoidCallback onDelete,
  }) {
    final String fileName = file.path.split('/').last;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete $fileName?",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to permanently delete this file?",
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100.w,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: "Inter",
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Inter",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Delete a file
  Future<FileDeleteResult> deleteFile({
    required File file,
    required BuildContext context,
    required List<File> allFiles,
    required List<File> pdfFiles,
    required List<File> wordFiles,
    required List<File> pptFiles,
    required List<File> excelFiles,
    required List<File> bookmarkedFiles,
  }) async {
    try {
      if (!await file.exists()) {
        return FileDeleteResult(
          success: false,
          allFiles: allFiles,
          pdfFiles: pdfFiles,
          wordFiles: wordFiles,
          pptFiles: pptFiles,
          excelFiles: excelFiles,
          wasBookmarked: false,
        );
      }

      final String filePath = file.path;
      final bool wasBookmarked = bookmarkedFiles.contains(file);

      await file.delete();

      // Remove from lists
      void removeFileFromList(List<File> list) {
        list.removeWhere((f) => f.path == filePath);
      }

      removeFileFromList(allFiles);
      removeFileFromList(pdfFiles);
      removeFileFromList(wordFiles);
      removeFileFromList(pptFiles);
      removeFileFromList(excelFiles);

      List<File>? updatedBookmarkedFiles;
      if (wasBookmarked) {
        removeFileFromList(bookmarkedFiles);
        updatedBookmarkedFiles = bookmarkedFiles;
      }

      _showDeleteSnackBar(context, file, filePath, wasBookmarked);

      return FileDeleteResult(
        success: true,
        allFiles: allFiles,
        pdfFiles: pdfFiles,
        wordFiles: wordFiles,
        pptFiles: pptFiles,
        excelFiles: excelFiles,
        wasBookmarked: wasBookmarked,
        bookmarkedFiles: updatedBookmarkedFiles,
      );
    } catch (e) {
      print('Error deleting file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting file")),
      );

      return FileDeleteResult(
        success: false,
        allFiles: allFiles,
        pdfFiles: pdfFiles,
        wordFiles: wordFiles,
        pptFiles: pptFiles,
        excelFiles: excelFiles,
        wasBookmarked: false,
      );
    }
  }

  void _showDeleteSnackBar(
      BuildContext context,
      File file,
      String filePath,
      bool wasBookmarked,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: const Text("File deleted successfully"),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            // Undo functionality would need to be implemented
            // This is a placeholder
          },
        ),
      ),
    );
  }
}