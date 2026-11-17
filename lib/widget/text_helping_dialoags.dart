import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextHelpDialogs {
  /// Show text extraction help dialog
  static void showTextExtractionHelp({
    required BuildContext context,
    required VoidCallback onEnableTextSelection,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8.w),
            const Text(
              'Extract Text',
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To copy text from this PDF:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Inter",
                ),
              ),
              SizedBox(height: 12.h),
              _buildExtractionStep('1', 'Long-press on any text in the document'),
              SizedBox(height: 8.h),
              _buildExtractionStep('2', 'Drag the handles to select the text you want'),
              SizedBox(height: 8.h),
              _buildExtractionStep('3', 'Tap "Copy" from the popup menu'),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You can also use the text selection tool from the toolbar',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: "Inter",
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontFamily: "Inter"),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onEnableTextSelection();
            },
            child: const Text(
              'Enable Text Selection',
              style: TextStyle(color: Colors.white, fontFamily: "Inter"),
            ),
          ),
        ],
      ),
    );
  }

  /// Show comprehensive text copy help dialog
  static void showTextCopyHelp({required BuildContext context}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'How to Copy Text',
          style: TextStyle(fontFamily: "Inter", fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '📝 Method 1: Long Press',
                'Long-press on text → Drag to select → Tap "Copy" in popup menu',
              ),
              SizedBox(height: 12.h),
              _buildHelpSection(
                '🔍 Method 2: Text Selection Tool',
                'Tap "Text Selection" button → Tap and drag on text → Copy',
              ),
              SizedBox(height: 12.h),
              _buildHelpSection(
                '🔎 Method 3: Search & Copy',
                'Use search to find text → Copy from search results',
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            fontFamily: "Inter",
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'PDFTron viewer has built-in text selection. Just long-press any text to start selecting!',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: "Inter",
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: Colors.white, fontFamily: "Inter"),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildExtractionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                fontFamily: "Inter",
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, fontFamily: "Inter"),
          ),
        ),
      ],
    );
  }

  static Widget _buildHelpSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            fontFamily: "Inter",
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 13.sp,
            fontFamily: "Inter",
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}