import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';

class FileController extends GetxController {
  RxList<File> allFiles = <File>[].obs;
  RxList<File> pdfFiles = <File>[].obs;
  RxList<File> wordFiles = <File>[].obs;
  RxList<File> pptFiles = <File>[].obs;
  RxList<File> excelFiles = <File>[].obs;

  RxList<File> bookmarkedFiles = <File>[].obs;
  RxList<File> bookmarkedPdfFiles = <File>[].obs;
  RxList<File> bookmarkedWordFiles = <File>[].obs;
  RxList<File> bookmarkedPptFiles = <File>[].obs;
  RxList<File> bookmarkedExcelFiles = <File>[].obs;

  RxBool isLoading = false.obs;
  RxInt totalFilesScanned = 0.obs;
  RxInt totalFilesFound = 0.obs;

  // Exclude directories that don't contain documents
  static const List<String> _excludedDirectories = [
    '.', // Hidden directories
    'Android',
    'DCIM',
    'Pictures',
    'Music',
    'Movies',
    'Videos',
    'Download',
    'Documents', // We'll still scan Documents but might want to prioritize it
    'system',
    'proc',
    'sys',
    'dev',
    'acct',
    'cache',
    'config',
    'mnt',
    'sdcard',
    'storage'
  ];

  @override
  void onInit() {
    super.onInit();
    loadFiles();
    loadBookmarks();
  }
Future<void> loadFiles() async {
  isLoading.value = true;
  totalFilesScanned.value = 0;
  totalFilesFound.value = 0;

  try {
    allFiles.clear();
    pdfFiles.clear();
    wordFiles.clear();
    pptFiles.clear();
    excelFiles.clear();

    // Priority directories to scan first
    final priorityDirs = [
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ];

    // Scan priority directories with full recursion
    for (final path in priorityDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await _scanDirectoryOptimized(dir, 0, true);
      }
    }

    _categorizeFiles();
    
  } catch (e) {
    print("Error loading files: $e");
  } finally {
    isLoading.value = false;
  }
}

Future<void> _scanDirectoryOptimized(Directory directory, int depth, bool recursive) async {
  if (depth > 3) return; // Reduce max depth
  
  try {
    final entities = await directory
        .list(recursive: false, followLinks: false)
        .where((entity) {
          final name = entity.path.split('/').last;
          // Filter out hidden and system directories early
          return !name.startsWith('.') && 
                 !_excludedDirectories.contains(name.toLowerCase());
        })
        .toList();

    final List<File> foundFiles = [];
    
    for (final entity in entities) {
      if (entity is File && _isDocumentFile(entity)) {
        foundFiles.add(entity);
      } else if (recursive && entity is Directory) {
        await _scanDirectoryOptimized(entity, depth + 1, true);
      }
    }

    // Batch add files
    if (foundFiles.isNotEmpty) {
      allFiles.addAll(foundFiles);
      totalFilesFound.value += foundFiles.length;
      update();
    }
    
  } catch (e) {
    // Silently skip permission errors
  }
}
  Future<void> loadFiles1() async {
    isLoading.value = true;
    totalFilesScanned.value = 0;
    totalFilesFound.value = 0;

    try {
      // Clear existing files first
      allFiles.clear();
      pdfFiles.clear();
      wordFiles.clear();
      pptFiles.clear();
      excelFiles.clear();

      // Start scanning from root
      await _scanDirectory(Directory('/storage/emulated/0/'), 0);

      // After scanning, categorize the files
      _categorizeFiles();
      
    } catch (e) {
      print("Error loading files: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _scanDirectory(Directory directory, int depth) async {
    // Limit recursion depth to avoid scanning too deep
    if (depth > 5) return;
    
    // Skip excluded directories
    final String dirName = directory.path.split('/').last.toLowerCase();
    if (_excludedDirectories.contains(dirName) || dirName.startsWith('.')) {
      return;
    }

    try {
      await for (final entity in directory.list(recursive: false, followLinks: false)) {
        totalFilesScanned.value++;
        
        if (entity is File) {
          // Check if it's a document file
          if (_isDocumentFile(entity)) {
            allFiles.add(entity);
            totalFilesFound.value++;
            
            // Update UI periodically (every 50 files)
            if (totalFilesFound.value % 50 == 0) {
              update();
            }
          }
        } else if (entity is Directory) {
          // Continue scanning directory
          await _scanDirectory(entity, depth + 1);
        }
      }
    } catch (e) {
      // Skip directories with permission issues
      print("Error scanning directory ${directory.path}: $e");
    }
  }

  bool _isDocumentFile(File file) {
    final String path = file.path.toLowerCase();
    return path.endsWith(Constants.pdf) ||
        path.endsWith(Constants.doc) ||
        path.endsWith(Constants.docx) ||
        path.endsWith(Constants.ppt) ||
        path.endsWith(Constants.pptx) ||
        path.endsWith(Constants.xlsx) ||
        path.endsWith(Constants.xls);
  }

  void _categorizeFiles() {
    final List<File> pdfs = [];
    final List<File> words = [];
    final List<File> ppts = [];
    final List<File> excels = [];

    for (final file in allFiles) {
      final String path = file.path.toLowerCase();
      if (path.endsWith(Constants.pdf)) {
        pdfs.add(file);
      } else if (path.endsWith(Constants.doc) || path.endsWith(Constants.docx)) {
        words.add(file);
      } else if (path.endsWith(Constants.ppt) || path.endsWith(Constants.pptx)) {
        ppts.add(file);
      } else if (path.endsWith(Constants.xlsx) || path.endsWith(Constants.xls)) {
        excels.add(file);
      }
    }

    pdfFiles.assignAll(pdfs);
    wordFiles.assignAll(words);
    pptFiles.assignAll(ppts);
    excelFiles.assignAll(excels);
    
    update();
  }

  // ALTERNATIVE: Fast scanning with specific document directories only
  Future<void> loadFilesFast() async {
    isLoading.value = true;
    totalFilesScanned.value = 0;
    totalFilesFound.value = 0;

    try {
      // Clear existing files
      allFiles.clear();
      pdfFiles.clear();
      wordFiles.clear();
      pptFiles.clear();
      excelFiles.clear();

      // Only scan common document directories
      final List<Directory> docDirectories = [
        Directory('/storage/emulated/0/Documents'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Downloads'),
        Directory('/storage/emulated/0/My Documents'),
        Directory('/storage/emulated/0/DCIM'), // Sometimes documents are here
      ];

      for (final dir in docDirectories) {
        if (await dir.exists()) {
          await _scanDirectoryFast(dir);
        }
      }

      _categorizeFiles();
      
    } catch (e) {
      print("Error loading files fast: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _scanDirectoryFast(Directory directory) async {
    try {
      final List<FileSystemEntity> entities = await directory.list().toList();
      
      for (final entity in entities) {
        totalFilesScanned.value++;
        
        if (entity is File && _isDocumentFile(entity)) {
          allFiles.add(entity);
          totalFilesFound.value++;
        }
      }
      
      // Update UI
      if (totalFilesFound.value % 20 == 0) {
        update();
      }
      
    } catch (e) {
      print("Error scanning directory fast ${directory.path}: $e");
    }
  }

  Future<void> loadBookmarks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? paths = prefs.getStringList("bookmarks");
      
      if (paths != null) {
        // Filter out non-existent files
        final List<File> validBookmarks = [];
        
        for (final path in paths) {
          final file = File(path);
          if (await file.exists()) {
            validBookmarks.add(file);
          }
        }

        bookmarkedFiles.assignAll(validBookmarks);
        
        // Update categorized bookmark lists
        bookmarkedPdfFiles.assignAll(
            bookmarkedFiles.where((file) => file.path.toLowerCase().endsWith(Constants.pdf)).toList());
        bookmarkedWordFiles.assignAll(
            bookmarkedFiles.where((file) => file.path.toLowerCase().endsWith(Constants.doc) || 
                file.path.toLowerCase().endsWith(Constants.docx)).toList());
        bookmarkedPptFiles.assignAll(
            bookmarkedFiles.where((file) => file.path.toLowerCase().endsWith(Constants.ppt) || 
                file.path.toLowerCase().endsWith(Constants.pptx)).toList());
        bookmarkedExcelFiles.assignAll(
            bookmarkedFiles.where((file) => file.path.toLowerCase().endsWith(Constants.xlsx) || 
                file.path.toLowerCase().endsWith(Constants.xls)).toList());

        // Save filtered list back to shared preferences
        await saveBookmarks();
      }
    } catch (e) {
      print("Error loading bookmarks: $e");
    }
  }

  Future<void> saveBookmarks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> paths = bookmarkedFiles.map((file) => file.path).toList();
      await prefs.setStringList("bookmarks", paths);
    } catch (e) {
      print("Error saving bookmarks: $e");
    }
  }

  Future<void> renameFile(File oldFile, File newFile) async {
    try {
      // Update in allFiles list
      final int allIndex = allFiles.indexOf(oldFile);
      if (allIndex != -1) allFiles[allIndex] = newFile;

      // Update in categorized lists
      _updateFileInList(pdfFiles, oldFile, newFile);
      _updateFileInList(wordFiles, oldFile, newFile);
      _updateFileInList(pptFiles, oldFile, newFile);
      _updateFileInList(excelFiles, oldFile, newFile);

      // Update in bookmarks
      final int bookmarkIndex = bookmarkedFiles.indexOf(oldFile);
      if (bookmarkIndex != -1) {
        bookmarkedFiles[bookmarkIndex] = newFile;
        await saveBookmarks();
      }

      update();
    } catch (e) {
      print("Error renaming file: $e");
      rethrow;
    }
  }

  void _updateFileInList(List<File> list, File oldFile, File newFile) {
    final int index = list.indexOf(oldFile);
    if (index != -1) {
      list[index] = newFile;
    }
  }

  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        
        // Remove from lists
        allFiles.remove(file);
        pdfFiles.remove(file);
        wordFiles.remove(file);
        pptFiles.remove(file);
        excelFiles.remove(file);
        
        // Remove from bookmarks if present
        if (bookmarkedFiles.contains(file)) {
          bookmarkedFiles.remove(file);
          await saveBookmarks();
        }
        
        update();
      }
    } catch (e) {
      print("Error deleting file: $e");
      rethrow;
    }
  }

  // Clear all cached files
  void clearCache() {
    allFiles.clear();
    pdfFiles.clear();
    wordFiles.clear();
    pptFiles.clear();
    excelFiles.clear();
    update();
  }

  // Refresh files (reload)
  Future<void> refreshFiles() async {
    await loadFiles();
  }
}