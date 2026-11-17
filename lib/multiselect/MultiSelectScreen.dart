import 'dart:io';
import 'package:documentreader/bookmark/bookmark.dart';
import 'package:documentreader/home/homescreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../constant/common_method.dart';
import '../constant/constant.dart';

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
  bool _selectAll = false;

  void _toggleFileSelection(File file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
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
      print('Error sharing files: $e');
      // Consider showing a snackbar to the user
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
    if (!confirm) return;

    // 🔹 Temporarily store deleted files for undo
    final List<File> filesToDelete = List<File>.from(_selectedFiles);
    final List<String> filePaths = filesToDelete.map((file) => file.path).toList();

    setState(() {
      widget.files.removeWhere((file) => _selectedFiles.contains(file));
      _selectedFiles.clear();
      _selectAll = false; // Reset select all when files are deleted
    });

    // 🔹 Show Snackbar with UNDO option
    final undoSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Files deleted"),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            // 🔥 Restore deleted files
            setState(() {
              widget.files.addAll(filesToDelete);
            });
          },
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.redAccent,
      ),
    );

    // 🔥 Wait 4 seconds before deleting permanently
    await Future.delayed(const Duration(seconds: 4));

    // Check if snackbar is still visible (user didn't undo)
    if (ScaffoldMessenger.of(context).mounted) {
      // 🔹 If the user did NOT press "Undo", delete files permanently
      bool shouldDeletePermanently = true;
      for (final file in filesToDelete) {
        if (widget.files.contains(file)) {
          shouldDeletePermanently = false;
          break;
        }
      }

      if (shouldDeletePermanently) {
        for (final path in filePaths) {
          final file = File(path);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (e) {
              print('Error deleting file $path: $e');
            }
          }
        }
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
          onPressed: () {
            if (widget.name == "HomeScreen") {
              Get.offAll(() =>  HomeScreen()); // Use offAll to prevent going back
            } else {
              Get.offAll(() =>  BookmarkScreen());
            }
          },
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
                    final isSelected = _selectedFiles.contains(file);
                    final isBookmarked = bookmarkedFiles.any((f) => f.path == file.path);

                    return CupertinoListTile(
                      backgroundColor: isSelected
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.transparent,
                      leading: SvgPicture.asset(
                        iconPath,
                        width: 40.w,
                        height: 40.h,
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