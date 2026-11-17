import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../model/conversion_history.dart';
import '../utilities/constants.dart';


class ConversionHistoryCard extends StatelessWidget {
  final ConversionHistory history;

  const ConversionHistoryCard({
    super.key,
    required this.history,
  });

  Color _getColorForType(String type) {
    if (type.contains('PDF to')) return AppConstants.pdfColor;
    if (type.contains('Word')) return AppConstants.wordColor;
    if (type.contains('Multiple')) return AppConstants.multipleColor;
    if (type.contains('Image')) return AppConstants.imageColor;
    return AppConstants.wordColor;
  }

  IconData _getIconForType(String type) {
    if (type.contains('PDF to')) return AppConstants.pdfIcon;
    if (type.contains('Word')) return AppConstants.wordIcon;
    if (type.contains('Multiple')) return AppConstants.multipleIcon;
    if (type.contains('Image')) return AppConstants.imageIcon;
    return Icons.transform;
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForType(history.type),
          child: Icon(
            _getIconForType(history.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          history.type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Time: ${_formatTime(history.timestamp)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Output: ${_getFileName(history.outputPath)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.open_in_new, color: AppConstants.wordColor),
              tooltip: 'Open',
              onPressed: () async {
                await OpenFile.open(history.outputPath);
              },
            ),
            IconButton(
              icon: Icon(Icons.share, color: AppConstants.imageColor),
              tooltip: 'Share',
              onPressed: () async {
                await Share.shareXFiles([XFile(history.outputPath)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}