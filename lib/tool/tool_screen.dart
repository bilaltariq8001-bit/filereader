import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../conversation_tool/controller.dart';
import '../conversation_tool/model/conversion_status.dart';
import '../conversation_tool/model/conversion_history.dart';

class ToolScreen extends StatefulWidget {
  const ToolScreen({super.key});

  @override
  State<ToolScreen> createState() => _ToolScreenState();
}

class _ToolScreenState extends State<ToolScreen> {
  @override
  Widget build(BuildContext context) {
    final converterProvider = Provider.of<DocumentConverterProvider>(context);
    final status = converterProvider.status;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Document Converter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: "Inter",
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolGrid(context, converterProvider),
                if (converterProvider.history.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            "Recent Conversions",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Inter",
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => converterProvider.clearHistory(),
                          child: const Text("Clear All"),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: converterProvider.history.length,
                    itemBuilder: (context, index) {
                      final item = converterProvider.history[index];
                      return _buildHistoryItem(context, item);
                    },
                  ),
                  SizedBox(height: 100.h), // Extra space
                ],
              ],
            ),
          ),
          if (status.isLoading) _buildLoadingOverlay(status),
        ],
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context, DocumentConverterProvider provider) {
    final tools = [
      _ToolItem(
        title: "Word to PDF",
        icon: Icons.description,
        color: Colors.blue,
        onTap: () => _handleConversion(context, provider.pickAndConvertWordToPdf),
      ),
      _ToolItem(
        title: "Excel to PDF",
        icon: Icons.table_chart,
        color: Colors.green,
        onTap: () => _handleConversion(context, provider.pickAndConvertExcelToPdf),
      ),
      _ToolItem(
        title: "PPT to PDF",
        icon: Icons.slideshow,
        color: Colors.orange,
        onTap: () => _handleConversion(context, provider.pickAndConvertPptToPdf),
      ),
      _ToolItem(
        title: "PDF to Word",
        icon: Icons.picture_as_pdf,
        color: Colors.red,
        onTap: () => _handleConversion(context, provider.pickAndConvertPdfToWord),
      ),
      _ToolItem(
        title: "Images to PDF",
        icon: Icons.image,
        color: Colors.purple,
        onTap: () => _handleConversion(context, provider.pickAndConvertMultipleImagesToPdf),
      ),
      _ToolItem(
        title: "Text to Word",
        icon: Icons.text_fields,
        color: Colors.teal,
        onTap: () => _showTextToWordDialog(context, provider),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return InkWell(
          onTap: tool.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: tool.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tool.icon,
                    color: tool.color,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  tool.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Inter",
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, ConversionHistory item) {
    final fileName = item.outputPath.split('/').last;
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            fileName.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.description,
            color: Colors.blue,
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: "Inter"),
        ),
        subtitle: Text(
          "${item.timestamp.toString().substring(0, 16)} • ${item.type}",
          style: TextStyle(fontSize: 12.sp, color: Colors.black54),
        ),
        trailing: PopupMenuButton<String>(

          onSelected: (value) async {
            if (value == 'open') {
              _openOutput(context, item.outputPath);
            } else if (value == 'share') {
              if (!await File(item.outputPath).exists()) {
                if (context.mounted) _showMissing(context);
                return;
              }
              await Share.shareXFiles([XFile(item.outputPath)]);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text("Open")),
            const PopupMenuItem(value: 'share', child: Text("Share")),
          ],
        ),
        onTap: () => _openOutput(context, item.outputPath),
      ),
    );
  }

  Widget _buildLoadingOverlay(ConversionStatus status) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 20.h),
              Text(
                status.message.isEmpty ? "Converting..." : status.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Inter",
                ),
              ),
              SizedBox(height: 12.h),
              LinearProgressIndicator(value: status.progress),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConversion(BuildContext context, Future<dynamic> Function() conversion) async {
    final provider = context.read<DocumentConverterProvider>();
    // Ignore taps while a conversion is already running.
    if (provider.isConverting) return;
    try {
      final result = await conversion();
      if (!mounted) return;
      // Use this screen's context: the one passed in may belong to a dialog
      // that has already closed.
      final BuildContext screenContext = this.context;
      if (result == null) {
        // The provider reports failures through its status; show them
        // instead of silently doing nothing.
        final status = provider.status;
        if (status.isError) {
          final String detail = (status.errorMessage ?? '')
              .replaceAll('Exception: ', '')
              .trim();
          ScaffoldMessenger.of(screenContext).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(detail.isEmpty
                  ? status.message
                  : '${status.message}: $detail'),
            ),
          );
          provider.resetStatus();
        }
        return;
      }
      if (result != null) {
        File? file;
        if (result is File) {
          file = result;
        } else if (result is String) {
          file = File(result);
        }
        
        if (file != null) {
          _showSuccessSheet(screenContext, file);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showSuccessSheet(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                SizedBox(width: 12.w),
                const Text(
                  "Conversion Successful",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Inter",
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              "File saved as: ${file.path.split('/').last}",
              style: TextStyle(color: Colors.black54, fontSize: 14.sp),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openOutput(this.context, file.path);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text("Open File"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0078D4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextToWordDialog(BuildContext context, DocumentConverterProvider provider) {
    final textController = TextEditingController();
    final BuildContext screenContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Text to Word"),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Enter text to convert...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final String text = textController.text;
              if (text.trim().isEmpty) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  const SnackBar(content: Text("Please enter some text first")),
                );
                return;
              }
              Navigator.pop(context);
              _handleConversion(screenContext, () => provider.convertTextToWord(text));
            },
            child: const Text("Convert"),
          ),
        ],
      ),
    );
  }
}

Future<void> _openOutput(BuildContext context, String path) async {
  if (!await File(path).exists()) {
    if (context.mounted) _showMissing(context);
    return;
  }
  final OpenResult result = await OpenFile.open(path);
  if (result.type != ResultType.done && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.type == ResultType.noAppToOpen
          ? 'No app installed that can open this file'
          : 'Could not open file: ${result.message}'),
    ));
  }
}

void _showMissing(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('This file no longer exists')),
  );
}

class _ToolItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ToolItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
