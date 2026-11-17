import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/common_method.dart';

class FileListItem extends StatefulWidget {
  final File file;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback onBookmarkTap;

  const FileListItem({
    Key? key,
    required this.file,
    required this.isBookmarked,
    required this.onTap,
    required this.onMoreTap,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails d) => setState(() => _scale = 0.97);
  void _onTapUp(TapUpDetails d) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final fileName = file.path.split('/').last;
    final iconPath = getIconForFile(file.path);
    final lastModified = file.lastModifiedSync();
    final formattedDate =
        "${lastModified.day.toString().padLeft(2, '0')}/"
        "${lastModified.month.toString().padLeft(2, '0')}/"
        "${lastModified.year}";
    final formattedSize = _getFormattedFileSize();
    final isRecent = DateTime.now().difference(lastModified).inDays <= 2;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _getBgColor(file.path),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📄 File Icon
              Image.asset(iconPath, width: 48.w, height: 48.h),

              SizedBox(width: 12.w),

              /// 📄 File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title + NEW badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter",
                            ),
                          ),
                        ),
                        if (isRecent)
                          Container(
                            margin: EdgeInsets.only(left: 6.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text("NEW",
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.white)),
                          )
                      ],
                    ),

                    SizedBox(height: 4.h),

                    /// Subtitle
                    Text(
                      "$formattedDate • $formattedSize",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                        fontFamily: "Inter",
                      ),
                    ),

                    SizedBox(height: 6.h),

                    /// File size progress indicator
                    _buildSizeIndicator(file.lengthSync()),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              /// ⭐ Actions
              Column(
                children: [
                  GestureDetector(
                    onTap: widget.onBookmarkTap,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: widget.isBookmarked
                          ? Icon(Icons.bookmark,
                          key: const ValueKey(true),
                          color: Colors.amber,
                          size: 22.sp)
                          : Icon(Icons.bookmark_border,
                          key: const ValueKey(false), size: 22.sp),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: widget.onMoreTap,
                    child: Icon(Icons.more_vert, size: 22.sp),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Background color by file type
  Color _getBgColor(String path) {
    if (path.endsWith('.pdf')) return Colors.red.withOpacity(0.08);
    if (path.endsWith('.doc') || path.endsWith('.docx')) {
      return Colors.blue.withOpacity(0.08);
    }
    if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
      return Colors.green.withOpacity(0.08);
    }
    if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
      return Colors.orange.withOpacity(0.08);
    }
    return Colors.grey.withOpacity(0.06);
  }

  /// 📊 File size indicator bar
  Widget _buildSizeIndicator(int bytes) {
    double sizeMB = bytes / (1024 * 1024);
    double percent = (sizeMB / 20).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 4.h,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(Colors.indigoAccent),
      ),
    );
  }

  /// 📦 Format file size
  String _getFormattedFileSize() {
    final int bytes = widget.file.lengthSync();
    final kb = bytes / 1024;
    final mb = kb / 1024;

    return mb >= 1
        ? '${mb.toStringAsFixed(2)} MB'
        : '${kb.toStringAsFixed(2)} KB';
  }
}
