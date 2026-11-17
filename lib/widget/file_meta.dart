import 'dart:io';
import 'package:flutter/widgets.dart';

/// Reads a file's size and date asynchronously and hands them to [builder].
///
/// List items used to call `lengthSync()`/`lastModifiedSync()` inside
/// `build`, which blocks the UI thread on every frame that builds a row and
/// throws (red screen) when a listed file was moved or deleted outside the
/// app. This widget does the I/O once per file, off the build path.
class FileMetaBuilder extends StatefulWidget {
  final File file;
  final Widget Function(BuildContext context, FileStat? stat) builder;

  const FileMetaBuilder({super.key, required this.file, required this.builder});

  @override
  State<FileMetaBuilder> createState() => _FileMetaBuilderState();
}

class _FileMetaBuilderState extends State<FileMetaBuilder> {
  FileStat? _stat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FileMetaBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _stat = null;
      _load();
    }
  }

  Future<void> _load() async {
    final String path = widget.file.path;
    final FileStat stat = await FileStat.stat(path);
    if (!mounted || widget.file.path != path) return;
    setState(() => _stat = stat.type == FileSystemEntityType.notFound ? null : stat);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _stat);
}

String formatFileSize(int bytes) {
  final double kb = bytes / 1024;
  final double mb = kb / 1024;
  return mb >= 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
}

String formatFileDate(DateTime date, {bool pad = true}) {
  String two(int v) => pad ? v.toString().padLeft(2, '0') : v.toString();
  return "${two(date.day)}/${two(date.month)}/${date.year}";
}
