import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/common_method.dart';

class BottomSheetActions {
  static void show({
    required BuildContext context,
    required File file,
    required bool isBookmarked,
    required VoidCallback onShare,
    required VoidCallback onBookmark,
    required VoidCallback onRename,
    required VoidCallback onDelete,
    required VoidCallback onSelectText,
    required VoidCallback onSearch,
    required VoidCallback onAiSearch,
    required VoidCallback onCopyHelp,
    required VoidCallback onGuide, required bool canRedo,
  }) {
    final String fileName = file.path.split('/').last;
    final String iconPath = getIconForFile(file.path);
    final bool isPdf = file.path.toLowerCase().endsWith('.pdf');
    final String formattedSize = _getFormattedFileSize(file);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
          height: isPdf
              ? MediaQuery.of(context).size.height * 0.35
              : MediaQuery.of(context).size.height * 0.25,
          child: Column(
            children: [
              _buildHeader(context, fileName, iconPath, formattedSize),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                child: Column(
                  children: [
                    _buildFirstRowActions(
                      context: context,
                      isBookmarked: isBookmarked,
                      onShare: onShare,
                      onBookmark: onBookmark,
                      onRename: onRename,
                      onDelete: onDelete,
                    ),
                    if (isPdf) ...[
                      SizedBox(height: 20.h),
                      _buildSecondRowActions(
                        context: context,
                        onSelectText: onSelectText,
                        onSearch: onSearch,
                        onCopyHelp: onCopyHelp,
                        onGuide: onGuide,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildHeader(
      BuildContext context,
      String fileName,
      String iconPath,
      String formattedSize,
      ) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        )
      ],
      title: Row(
        children: [
          SvgPicture.asset(iconPath, height: 40.h, width: 40.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: "Inter",
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2.h),
                Text(
                  formattedSize,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontFamily: "Inter",
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFirstRowActions({
    required BuildContext context,
    required bool isBookmarked,
    required VoidCallback onShare,
    required VoidCallback onBookmark,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAction(
          iconPath: "assets/share.svg",
          label: "Share",
          onTap: () {
            Navigator.pop(context);
            onShare();
          },
        ),
        _buildAction(
          iconPath: isBookmarked
              ? "assets/bookmark_filled.svg"
              : "assets/bookmark_outlined.svg",
          label: "Bookmark",
          iconColor: isBookmarked ? Colors.green : Colors.black,
          onTap: () {
            onBookmark();
            Navigator.pop(context);
          },
        ),
        _buildAction(
          iconPath: "assets/rename.svg",
          label: "Rename",
          onTap: () {
            Navigator.pop(context);
            onRename();
          },
        ),
        _buildAction(
          iconPath: "assets/delete.svg",
          label: "Delete",
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    );
  }

  static Widget _buildSecondRowActions({
    required BuildContext context,
    required VoidCallback onSelectText,
    required VoidCallback onSearch,
    required VoidCallback onCopyHelp,
    required VoidCallback onGuide,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAction(
          icon: Icons.select_all_sharp,
          label: "Select Text",
          onTap: () {
            Navigator.pop(context);
            onSelectText();
          },
        ),
        _buildAction(
          icon: Icons.search,
          label: "Search",
          onTap: () {
            Navigator.pop(context);
            onSearch();
          },
        ),
        _buildAction(
          icon: Icons.help_outline,
          label: "Copy Help",
          onTap: () {
            Navigator.pop(context);
            onCopyHelp();
          },
        ),
        _buildAction(
          icon: Icons.info_outline,
          label: "Guide",
          onTap: () {
            Navigator.pop(context);
            onGuide();
          },
        ),
      ],
    );
  }

  static Widget _buildAction({
    String? iconPath,
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            SvgPicture.asset(
              iconPath,
              height: 30.h,
              width: 30.w,
              color: iconColor,
            )
          else if (icon != null)
            Icon(icon, size: 30.sp, color: iconColor),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontFamily: "Inter"),
          ),
        ],
      ),
    );
  }

  static String _getFormattedFileSize(File file) {
    final int fileSizeInBytes = file.lengthSync();
    final double fileSizeInKB = fileSizeInBytes / 1024;
    final double fileSizeInMB = fileSizeInKB / 1024;

    return fileSizeInMB >= 1
        ? '${fileSizeInMB.toStringAsFixed(2)} MB'
        : '${fileSizeInKB.toStringAsFixed(2)} KB';
  }
}