import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../constant/common_method.dart';
import '../services/bookmark_service.dart';
import '../services/file_services.dart';

class MultiSelectScreen extends StatefulWidget {
  final List<File> files;
  final String fileType;
  final String name;

  const MultiSelectScreen({
    Key? key, // Added Key parameter
    required this.files,
    required this.fileType,
    required this.name,
  }) : super(key: key);

  @override
  _MultiSelectScreenState createState() => _MultiSelectScreenState();
}

class _MultiSelectScreenState extends State<MultiSelectScreen> {
  List<File> _selectedFiles = [];
  final FileService _fileService = FileService();

  bool _isSelected(File file) => _selectedFiles.any((f) => f.path == file.path);
  bool _selectAll = false;

  void _toggleFileSelection(File file) {
    setState(() {
      if (_isSelected(file)) {
        _selectedFiles.removeWhere((f) => f.path == file.path);
      } else {
        _selectedFiles.add(file);
      }
      _selectAll = widget.files.isNotEmpty &&
          _selectedFiles.length == widget.files.length;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedFiles.clear();
      } else {
        _selectedFiles = List<File>.from(widget.files); // Added explicit type
      }
      _selectAll = !_selectAll;
    });
  }

  void _shareFiles() async {
    if (_selectedFiles.isEmpty) return;
    
    try {
      final filePaths = _selectedFiles.map((file) => file.path).toList();
      await Share.shareXFiles(
        filePaths.map((path) => XFile(path)).toList(), // Convert to XFile
        text: "Check out these documents",
      );
    } catch (e) {
      // Handle error appropriately (show snackbar, dialog, etc.)
      debugPrint('Error sharing files: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share files'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteFiles() async {
    if (_selectedFiles.isEmpty) return; // Added safety check

    final bool confirm = await _showDeleteConfirmation();
    if (!confirm || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<File> filesToDelete = List<File>.from(_selectedFiles);

    // Move the files aside first so Undo can really bring them back.
    final Map<String, File> staged = {};
    final List<String> unbookmarked = [];
    for (final File file in filesToDelete) {
      try {
        staged[file.path] = await _fileService.stageDelete(file);
        if (BookmarkService().isBookmarked(file)) {
          await BookmarkService().removeBookmark(file.path);
          unbookmarked.add(file.path);
        }
      } catch (e) {
        debugPrint('Error deleting file ${file.path}: $e');
      }
    }
    if (!mounted) return;

    setState(() {
      widget.files.removeWhere((file) => staged.containsKey(file.path));
      _selectedFiles.clear();
      _selectAll = false; // Reset select all when files are deleted
    });

    if (staged.length < filesToDelete.length) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            '${filesToDelete.length - staged.length} file(s) could not be deleted'),
      ));
    }
    if (staged.isEmpty) return;

    messenger.hideCurrentSnackBar();
    final SnackBarClosedReason reason = await messenger
        .showSnackBar(
          SnackBar(
            content: const Text("Files deleted"),
            action: SnackBarAction(
              label: "Undo",
              textColor: Colors.white,
              onPressed: () {},
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.redAccent,
          ),
        )
        .closed;

    if (reason == SnackBarClosedReason.action) {
      final List<File> restored = [];
      for (final MapEntry<String, File> e in staged.entries) {
        try {
          restored.add(await _fileService.restoreStaged(e.value, e.key));
          if (unbookmarked.contains(e.key)) {
            await BookmarkService().addBookmark(e.key);
          }
        } catch (err) {
          debugPrint('Error restoring ${e.key}: $err');
        }
      }
      if (mounted) setState(() => widget.files.addAll(restored));
    } else {
      for (final File file in staged.values) {
        await _fileService.commitDelete(file);
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow tapping outside to dismiss
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Files",
          style: TextStyle(fontFamily: "Inter"),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to permanently delete the selected files?",
              style: TextStyle(fontFamily: "Inter"),
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
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.redAccent, fontFamily: "Inter"),
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
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white, fontFamily: "Inter"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          // Return to the screen that opened multi-select. offAll() rebuilt
          // the app without its bottom bar and rescanned storage.
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          "${_selectedFiles.length} Selected",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              _selectAll ? "Deselect All" : "Select All",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          widget.files.isEmpty
              ? const Center(
                  child: Text(
                    "No files available",
                    style: TextStyle(fontFamily: "Inter"),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: 80.h), // Add padding for bottom bar
                  itemCount: widget.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.files[index];
                    final fileName = file.path.split('/').last;
                    final iconPath = getIconForFile(file.path);
                    final isSelected = _isSelected(file);
                    final isBookmarked = BookmarkService().isBookmarked(file);

                    return CupertinoListTile(
                      key: ValueKey(file.path),
                      backgroundColor: isSelected
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.transparent,
                      leading: Image.asset(
                        iconPath,
                        width: 40.w,
                        height: 40.h,
                        cacheWidth: 144,
                        cacheHeight: 144,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBookmarked)
                            SvgPicture.asset(
                              "assets/bookmark_filled.svg",
                              height: 18.h,
                              width: 18.w,
                              color: Colors.green,
                            ),
                          SizedBox(width: 8.w),
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleFileSelection(file);
                            },
                            activeColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            side: BorderSide(
                              width: 2.w,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _toggleFileSelection(file);
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => Divider(
                    color: Colors.grey.withOpacity(0.2),
                    height: 1.h,
                  ),
                ),
          Container(
            color: const Color(0xffD4D4D4).withOpacity(0.7),
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 10.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomButton(
                  iconPath: "assets/share.svg",
                  label: "Share",
                  isEnabled: _selectedFiles.isNotEmpty,
                  onTap: _shareFiles,
                ),
                _buildBottomButton(
                  iconPath: "assets/delete.svg",
                  label: "Delete",
                  isEnabled: _selectedFiles.isNotEmpty,
                  onTap: _deleteFiles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String iconPath,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Column(
            children: [
              SvgPicture.asset(
                iconPath,
                height: 27.h,
                width: 27.w,
                color: isEnabled ? Colors.black : Colors.grey,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}