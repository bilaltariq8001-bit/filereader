import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../constant/color.dart';
import '../../constant/constant.dart';
import 'bookmark_service.dart';

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

/// Top-level so it can run inside a background isolate.
List<String> scanDocumentPaths(String rootPath) {
  const Set<String> extensions = {
    Constants.pdf,
    Constants.doc,
    Constants.docx,
    Constants.ppt,
    Constants.pptx,
    Constants.xls,
    Constants.xlsx,
  };
  final String root =
      rootPath.endsWith('/') ? rootPath.substring(0, rootPath.length - 1) : rootPath;
  // App-private and OBB folders are not readable on Android 11+ and hold
  // huge numbers of unrelated files, so walking them only costs time.
  final Set<String> skipped = {'$root/Android/data', '$root/Android/obb'};
  final List<String> result = [];
  final List<Directory> pending = [Directory(root)];

  while (pending.isNotEmpty) {
    final Directory dir = pending.removeLast();
    List<FileSystemEntity> children;
    try {
      children = dir.listSync(recursive: false, followLinks: false);
    } catch (_) {
      continue; // permission denied or vanished
    }
    for (final FileSystemEntity entity in children) {
      final String path = entity.path;
      final String name = path.substring(path.lastIndexOf('/') + 1);
      if (name.startsWith('.')) {
        if (entity is File) _sweepAbandonedDelete(entity, name);
        continue; // hidden files, trash, thumbnails
      }
      if (entity is Directory) {
        if (!skipped.contains(path)) pending.add(entity);
      } else if (entity is File) {
        final int dot = name.lastIndexOf('.');
        if (dot > 0 && extensions.contains(name.substring(dot).toLowerCase())) {
          result.add(path);
        }
      }
    }
  }
  return result;
}

/// A file deleted from the app is first renamed to
/// `.pending_delete_<micros>_<name>` so Undo can bring it back. If the app was
/// killed before the deletion was committed, finish it here.
void _sweepAbandonedDelete(File file, String name) {
  const String prefix = '.pending_delete_';
  if (!name.startsWith(prefix)) return;
  final String rest = name.substring(prefix.length);
  final int sep = rest.indexOf('_');
  final int? micros = sep > 0 ? int.tryParse(rest.substring(0, sep)) : null;
  if (micros == null) return;
  final DateTime stagedAt = DateTime.fromMicrosecondsSinceEpoch(micros);
  if (DateTime.now().difference(stagedAt) > const Duration(minutes: 10)) {
    try {
      file.deleteSync();
    } catch (_) {}
  }
}

class FileService {
  /// Android shared storage. Overridable so tests can scan a temp folder.
  @visibleForTesting
  static String storageRoot = '/storage/emulated/0';

  /// Suffix used while a deleted file can still be restored with Undo.
  static const String _pendingDeletePrefix = '.pending_delete_';

  /// Load all files from storage. The directory walk runs in a background
  /// isolate so the UI thread never blocks on file system I/O.
  Future<FileLoadResult> loadAllFiles() async {
    final String root = storageRoot;
    final List<String> paths = await Isolate.run(() => scanDocumentPaths(root));
    return buildResult(paths.map((p) => File(p)).toList());
  }

  FileLoadResult buildResult(List<File> allFiles) {
    return FileLoadResult(
      allFiles: allFiles,
      pdfFiles: _filterFilesByExtension(allFiles, [Constants.pdf]),
      wordFiles: _filterFilesByExtension(allFiles, [Constants.doc, Constants.docx]),
      pptFiles: _filterFilesByExtension(allFiles, [Constants.ppt, Constants.pptx]),
      excelFiles: _filterFilesByExtension(allFiles, [Constants.xlsx, Constants.xls]),
    );
  }

  /// Moves the file aside (same folder, so the move is instant) so the
  /// deletion can be undone. Returns the staged file.
  Future<File> stageDelete(File file) async {
    final String name = file.path.substring(file.path.lastIndexOf('/') + 1);
    final String stagedPath =
        '${file.parent.path}/$_pendingDeletePrefix${DateTime.now().microsecondsSinceEpoch}_$name';
    return file.rename(stagedPath);
  }

  /// Puts a staged file back where it was.
  Future<File> restoreStaged(File staged, String originalPath) {
    return staged.rename(originalPath);
  }

  /// Permanently removes a staged file.
  Future<void> commitDelete(File staged) async {
    try {
      if (await staged.exists()) await staged.delete();
    } catch (e) {
      debugPrint('Error deleting file ${staged.path}: $e');
    }
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
      debugPrint('Error sharing file: $e');
      if (!context.mounted) return;
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
    final TextEditingController renameController = TextEditingController(
        text: fileExtension.isEmpty
            ? fileName
            : fileName.substring(0, fileName.length - fileExtension.length));
    final BuildContext outerContext = context;

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
                            context: outerContext,
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
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String newPath = '${file.parent.path}/$newName';
      if (newPath == file.path) return;
      if (await File(newPath).exists()) {
        messenger.showSnackBar(
          const SnackBar(content: Text("A file with that name already exists")),
        );
        return;
      }
      final File newFile = await file.rename(newPath);
      await BookmarkService().updateBookmarkedFile(file, newFile);

      onRenamed(file, newFile);

      messenger.showSnackBar(
        const SnackBar(content: Text("File renamed successfully")),
      );
    } catch (e) {
      debugPrint('Error renaming file: $e');
      messenger.showSnackBar(
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

  /// Delete a file with a working Undo.
  ///
  /// The file is first moved aside (instant, same folder). Undo moves it
  /// back; once the snackbar closes any other way it is deleted for good.
  /// The bookmark, if any, is removed and restored together with the file.
  Future<FileDeleteResult> deleteFile({
    required File file,
    required BuildContext context,
    required List<File> allFiles,
    required List<File> pdfFiles,
    required List<File> wordFiles,
    required List<File> pptFiles,
    required List<File> excelFiles,
    required List<File> bookmarkedFiles,
    VoidCallback? onRestored,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String filePath = file.path;
    final FileDeleteResult unchanged = FileDeleteResult(
      success: false,
      allFiles: allFiles,
      pdfFiles: pdfFiles,
      wordFiles: wordFiles,
      pptFiles: pptFiles,
      excelFiles: excelFiles,
      wasBookmarked: false,
    );

    try {
      if (!await file.exists()) {
        messenger.showSnackBar(const SnackBar(content: Text("File no longer exists")));
        return unchanged;
      }

      final bool wasBookmarked = bookmarkedFiles.any((f) => f.path == filePath);
      final File staged = await stageDelete(file);

      void removeFileFromList(List<File> list) =>
          list.removeWhere((f) => f.path == filePath);
      removeFileFromList(allFiles);
      removeFileFromList(pdfFiles);
      removeFileFromList(wordFiles);
      removeFileFromList(pptFiles);
      removeFileFromList(excelFiles);

      BookmarkData? bookmarks;
      if (wasBookmarked) {
        bookmarks = await BookmarkService().removeBookmark(filePath);
      }

      messenger.hideCurrentSnackBar();
      messenger
          .showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: const Text("File deleted successfully"),
              action: SnackBarAction(
                label: "Undo",
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          )
          .closed
          .then((reason) async {
        if (reason == SnackBarClosedReason.action) {
          try {
            await restoreStaged(staged, filePath);
            if (wasBookmarked) await BookmarkService().addBookmark(filePath);
            onRestored?.call();
          } catch (e) {
            debugPrint('Error restoring file: $e');
            messenger.showSnackBar(
              const SnackBar(content: Text("Failed to restore file")),
            );
          }
        } else {
          await commitDelete(staged);
        }
      });

      return FileDeleteResult(
        success: true,
        allFiles: allFiles,
        pdfFiles: pdfFiles,
        wordFiles: wordFiles,
        pptFiles: pptFiles,
        excelFiles: excelFiles,
        wasBookmarked: wasBookmarked,
        bookmarkedFiles: bookmarks?.bookmarkedFiles,
        bookmarkedPdfFiles: bookmarks?.bookmarkedPdfFiles,
        bookmarkedWordFiles: bookmarks?.bookmarkedWordFiles,
        bookmarkedPptFiles: bookmarks?.bookmarkedPptFiles,
        bookmarkedExcelFiles: bookmarks?.bookmarkedExcelFiles,
      );
    } catch (e) {
      debugPrint('Error deleting file: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text("Error deleting file")),
      );
      return unchanged;
    }
  }
}
