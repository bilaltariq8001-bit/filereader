import 'dart:io';
import 'package:documentreader/bookmark/bookmark.dart';
import 'package:documentreader/setting/settingscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../multiselect/MultiSelectScreen.dart';
import '../search/searchscreen.dart';
import '../services/ai_search.dart';
import '../services/bookmark_service.dart';
import '../services/file.dart';
import '../services/file_services.dart';
import '../services/pdf_dervices.dart';
import '../services/permission_services.dart';
import '../services/scan_import_services.dart';
import '../widget/bottom_sheet_action.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController? _tabController;
  bool _openedWithPdfTron = false;
  bool isBannerAdLoaded = false;
  bool isLoading = true;
  String? _currentOpenedFilePath;

  // PDF State
  bool _isPdfOpen = false;
  final bool _canRedo = false;
  String? _clipboardTextAtOpen;
  bool _scanInProgress = false;

  /// Fires whenever the file or bookmark lists change, so screens opened
  /// from here (search) stay in sync.
  final ValueNotifier<int> _listsChanged = ValueNotifier<int>(0);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _listsChanged.value++;
  }

  // Floating AI Button
  bool _showFloatingAiButton = false;
  String _selectedText = '';

  // Services
  late FileService _fileService;
  late PermissionService _permissionService;
  late BookmarkService _bookmarkService;
  late PdfService _pdfService;
  late AiSearchService _aiSearchService;

  // Lists for files
  List<File> allFiles = [];
  List<File> pdfFiles = [];
  List<File> wordFiles = [];
  List<File> pptFiles = [];
  List<File> excelFiles = [];
  List<File> bookmarkedFiles = [];
  List<File> bookmarkedPdfFiles = [];
  List<File> bookmarkedWordFiles = [];
  List<File> bookmarkedPptFiles = [];
  List<File> bookmarkedExcelFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _initializeTabController();
    _requestPermission();
    _loadBannerAd();
    _setupPdfTronListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The document viewer is a separate Android activity. When the user comes
    // back from it, offer AI search for text they copied inside the viewer.
    if (state == AppLifecycleState.resumed && _isPdfOpen) {
      Clipboard.getData(Clipboard.kTextPlain).then(_handleClipboardData);
    }
  }

  void _initializeServices() {
    _fileService = FileService();
    _permissionService = PermissionService();
    _bookmarkService = BookmarkService();
    _pdfService = PdfService(context: context);
    _aiSearchService = AiSearchService(context: context);
  }

  void _initializeTabController() {
    _tabController = TabController(length: 5, vsync: this);
    // _getCurrentTabFiles() reads _tabController.index when an action is
    // tapped, so the whole screen does not need to rebuild on every tab
    // animation tick.
  }

  void _setupPdfTronListeners() {
    // You can setup event listeners for PDFTron if needed
    // For example, to listen for page change events
  }

  void _handleClipboardData(ClipboardData? data) {
    if (!mounted) return;
    final String? text = data?.text?.trim();
    if (text != null && text.isNotEmpty && _isPdfOpen &&
        text != _clipboardTextAtOpen) {
      _clipboardTextAtOpen = text;
      setState(() {
        _selectedText = text;
        _showFloatingAiButton = true;
      });

      // Auto-hide after 10 seconds
      Future.delayed(Duration(seconds: 10), () {
        if (mounted && _showFloatingAiButton) {
          setState(() {
            _showFloatingAiButton = false;
          });
        }
      });
    }
  }

  void _loadBannerAd() {
    // Your banner ad loading code
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController?.dispose();
    _listsChanged.dispose();
    super.dispose();
  }

  // ============================================
  // PERMISSION HANDLING
  // ============================================
  Future<void> _requestPermission() async {
    final bool hasPermission = await _permissionService.requestStoragePermission(
      onPermissionDenied: _showPermissionDeniedDialog,
    );

    if (hasPermission) {
      await _loadFilesAndBookmarks();
    } else if (mounted) {
      // Without access there is nothing to load: show the empty state (pull
      // to refresh asks again) instead of an endless spinner.
      setState(() => isLoading = false);
      await _loadBookmarks();
    }
  }

  void _showPermissionDeniedDialog() {
    _permissionService.showPermissionDeniedDialog(context);
  }

  Future<void> _loadFilesAndBookmarks() async {
    await loadFiles();
    await _loadBookmarks();
  }

  // ============================================
  // FILE LOADING
  // ============================================
  void _applyFileData(FileLoadResult fileData) {
    setState(() {
      allFiles = fileData.allFiles;
      pdfFiles = fileData.pdfFiles;
      wordFiles = fileData.wordFiles;
      pptFiles = fileData.pptFiles;
      excelFiles = fileData.excelFiles;
    });
  }

  /// Full storage scan (runs in a background isolate). Only one scan runs at
  /// a time; pull-to-refresh and the startup refresh share it.
  Future<void> _scanStorage() async {
    if (_scanInProgress) return;
    _scanInProgress = true;
    try {
      final FileLoadResult fileData = await _fileService.loadAllFiles();
      if (!mounted) return;
      _applyFileData(fileData);
      await _fileService.cacheFiles(fileData.allFiles);
    } catch (e) {
      debugPrint('File scan error: $e');
    } finally {
      _scanInProgress = false;
    }
  }

  /// Shows the cached file list immediately when there is one, then
  /// refreshes it from storage in the background.
  Future<void> loadFiles({bool forceRescan = false}) async {
    if (!mounted) return;

    try {
      if (!forceRescan) {
        final cachedFiles = await _fileService.getCachedFiles();
        if (!mounted) return;
        if (cachedFiles != null && cachedFiles.isNotEmpty) {
          _applyFileData(_fileService.buildResult(cachedFiles));
          setState(() => isLoading = false);
          _scanStorage();
          return;
        }
      }
      if (allFiles.isEmpty) setState(() => isLoading = true);
      await _scanStorage();
    } catch (e) {
      debugPrint('File load error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarkData = await _bookmarkService.loadBookmarks(dropMissing: true);
    if (!mounted) return;

    setState(() {
      bookmarkedFiles = bookmarkData.bookmarkedFiles;
      bookmarkedPdfFiles = bookmarkData.bookmarkedPdfFiles;
      bookmarkedWordFiles = bookmarkData.bookmarkedWordFiles;
      bookmarkedPptFiles = bookmarkData.bookmarkedPptFiles;
      bookmarkedExcelFiles = bookmarkData.bookmarkedExcelFiles;
    });
  }

  Future<void> _toggleBookmark(File file) async {
    final result = await _bookmarkService.toggleBookmark(file);
    if (!mounted) return;
    setState(() {
      bookmarkedFiles = result.bookmarkedFiles;
      bookmarkedPdfFiles = result.bookmarkedPdfFiles;
      bookmarkedWordFiles = result.bookmarkedWordFiles;
      bookmarkedPptFiles = result.bookmarkedPptFiles;
      bookmarkedExcelFiles = result.bookmarkedExcelFiles;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.isBookmarked ? Colors.green : Colors.grey,
        content: Text(
          result.isBookmarked ? "Bookmark added" : "Bookmark removed",
          style: const TextStyle(color: Colors.white, fontFamily: "Inter"),
        ),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () => _toggleBookmark(file),
        ),
      ),
    );
  }

  // ============================================
  // ENHANCED PDF OPERATIONS
  // ============================================
  Future<void> _openWithPdfTron(String path,
      {Future<void> Function()? onLoaded}) async {
    if (_openedWithPdfTron) return;
    _openedWithPdfTron = true;

    try {
      if (!await File(path).exists()) {
        _showMessage('This file no longer exists', Colors.red);
        loadFiles(forceRescan: true);
        return;
      }
      _clipboardTextAtOpen =
          (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
      _currentOpenedFilePath =
          await _pdfService.openDocument(path, onLoaded: onLoaded);
      if (!mounted) return;
      setState(() {
        _isPdfOpen = true;
      });
    } catch (e) {
      debugPrint('Error opening document: $e');
      _showMessage('Could not open this file', Colors.red);
    } finally {
      _openedWithPdfTron = false;
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _enableTextSelectionMode() async {
    await _pdfService.enableTextSelectionMode();
  }

  Future<void> _openSearchInDocument() async {
    await _pdfService.openSearchInDocument();
  }

  Future<void> _openAiSearch(String filePath) async {
    await _aiSearchService.openAiSearch(
      filePath: filePath,
      onSearch: _searchInDocument,
    );
  }

  /// Opens the document and runs the search once the viewer has loaded it.
  Future<void> _searchInDocument(String filePath, String query,
      {bool matchWholeWord = false}) async {
    await _openWithPdfTron(_pathFromUri(filePath), onLoaded: () async {
      await _pdfService.startSearch(query, matchWholeWord: matchWholeWord);
    });
  }

  Future<void> _openAiSearchWithSelectedText() async {
    if (_currentOpenedFilePath != null) {
      setState(() {
        _showFloatingAiButton = false;
      });
      await _aiSearchService.openAiSearch(
        filePath: _currentOpenedFilePath!,
        initialQuery: _selectedText,
        onSearch: _searchInDocument,
      );
    }
  }
  String _pathFromUri(String path) =>
      path.startsWith('file://') ? path.substring(7) : path;

  /// helper
  void _showTextExtractionHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Text Extraction Guide"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.touch_app),
              title: Text("Enable Text Selection"),
              subtitle: Text("Tap the text selection icon first"),
              onTap: () {
                Navigator.pop(context);
                if (_currentOpenedFilePath != null) {
                  _openWithPdfTron(_pathFromUri(_currentOpenedFilePath!),
                      onLoaded: _enableTextSelectionMode);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.content_copy),
              title: Text("Copy Text"),
              subtitle: Text("Long press on text to select"),
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text("Search in Document"),
              subtitle: Text("Find specific text quickly"),
              onTap: () {
                Navigator.pop(context);
                if (_currentOpenedFilePath != null) {
                  _openWithPdfTron(_pathFromUri(_currentOpenedFilePath!),
                      onLoaded: _openSearchInDocument);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PDF ADVANCED FUNCTIONS
  // ============================================



  // ============================================
  // FILE OPERATIONS
  // ============================================
  Future<void> _shareFile(File file) async {
    await _fileService.shareFile(file, context);
  }

  void _renameFile(File file) {
    _fileService.showRenameDialog(
      context: context,
      file: file,
      onRenamed: (oldFile, newFile) {
        _updateFileListsAfterRename(oldFile, newFile);
      },
    );
  }

  void _updateFileListsAfterRename(File oldFile, File newFile) {
    if (!mounted) return;
    setState(() {
      _fileService.updateFileInLists(
        oldFile: oldFile,
        newFile: newFile,
        allFiles: allFiles,
        pdfFiles: pdfFiles,
        wordFiles: wordFiles,
        pptFiles: pptFiles,
        excelFiles: excelFiles,
      );
    });

    // FileService already updated the stored bookmark; refresh our copy.
    _loadBookmarks();
    _fileService.cacheFiles(allFiles);
  }

  void _confirmDelete(File file) {
    _fileService.showDeleteConfirmation(
      context: context,
      file: file,
      onDelete: () => _deleteFile(file),
    );
  }

  void _deleteFile(File file) async {
    final result = await _fileService.deleteFile(
      file: file,
      context: context,
      allFiles: allFiles,
      pdfFiles: pdfFiles,
      wordFiles: wordFiles,
      pptFiles: pptFiles,
      excelFiles: excelFiles,
      bookmarkedFiles: bookmarkedFiles,
      onRestored: () {
        if (!mounted) return;
        loadFiles(forceRescan: true);
        _loadBookmarks();
      },
    );

    if (result.success && mounted) {
      _fileService.cacheFiles(result.allFiles);
      setState(() {
        allFiles = result.allFiles;
        pdfFiles = result.pdfFiles;
        wordFiles = result.wordFiles;
        pptFiles = result.pptFiles;
        excelFiles = result.excelFiles;

        if (result.wasBookmarked) {
          bookmarkedFiles = result.bookmarkedFiles!;
          bookmarkedPdfFiles = result.bookmarkedPdfFiles!;
          bookmarkedWordFiles = result.bookmarkedWordFiles!;
          bookmarkedPptFiles = result.bookmarkedPptFiles!;
          bookmarkedExcelFiles = result.bookmarkedExcelFiles!;
        }
      });
    }
  }

  // ============================================
  // ENHANCED BOTTOM SHEET
  // ============================================
  void showBottomSheet(File file) {
    final bool isBookmarked = bookmarkedFiles.any((f) => f.path == file.path);
    final bool isPdf = file.path.toLowerCase().endsWith('.pdf');

    BottomSheetActions.show(
      context: context,
      file: file,
      isBookmarked: isBookmarked,
      onShare: () => _shareFile(file),
      onBookmark: () => _toggleBookmark(file),
      onRename: () => _renameFile(file),
      onDelete: () => _confirmDelete(file),
      onSelectText: () {
        _openWithPdfTron(file.path, onLoaded: _enableTextSelectionMode);
      },
      onSearch: () {
        _openWithPdfTron(file.path, onLoaded: _openSearchInDocument);
      },
      onAiSearch: () => _openAiSearch(file.path),
      onCopyHelp: () => _pdfService.showTextCopyHelp(),
      onGuide: _showTextExtractionHelp,
      //canRedo: null,
      //canRedo: null,
      // Additional PDF-specific options
      // isPdf: isPdf,
      // onSave: isPdf ? _saveCurrentDocument : null,
      // onRotate: isPdf ? () => _rotateDocument(true) : null,
      // onExport: isPdf ? _exportCurrentPageAsImage : null,
      // onAddBookmark: isPdf ? _addBookmarkToCurrentPage : null,
      // onThumbnails: isPdf ? _openThumbnailsView : null,
      // onGoToPage: isPdf ? _openGoToPage : null,
      // onUndo: isPdf ? _undoLastAction : null,
      // onRedo: isPdf ? _redoLastAction : null,
      // canUndo: isPdf ? _canUndo : false,
      canRedo: isPdf ? _canRedo : false,
    );
  }

  // ============================================
  // UI HELPERS
  // ============================================
  Future<bool> _exitDialog() async {
    if (_showFloatingAiButton) {
      // Back first dismisses the AI search shortcut.
      setState(() => _showFloatingAiButton = false);
      return false;
    }

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Exit", style: TextStyle(fontFamily: "Inter")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to exit?",
                style: TextStyle(fontFamily: "Inter")),
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
                          borderRadius: BorderRadius.circular(6.r)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel",
                        style: TextStyle(
                            color: Colors.redAccent, fontFamily: "Inter")),
                  ),
                ),
                SizedBox(
                  width: 100.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r)),
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Exit",
                        style: TextStyle(
                            color: Colors.white, fontFamily: "Inter")),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<void> _refreshFiles() async {
    if (!mounted) return;
    final bool hasPermission = await _permissionService.requestStoragePermission(
      onPermissionDenied: _showPermissionDeniedDialog,
    );
    if (!hasPermission) return;
    await loadFiles(forceRescan: true);
    await _loadBookmarks();
  }

  /// Search, bookmarks and multi-select can rename, delete or (un)bookmark
  /// files, so re-sync when the user comes back from them.
  Future<void> _afterReturn() async {
    if (!mounted) return;
    await _loadBookmarks();
    final cached = await _fileService.getCachedFiles();
    if (!mounted || cached == null) return;
    _applyFileData(_fileService.buildResult(cached));
  }

  List<File> _getCurrentTabFiles() => _filesForTab(_tabController?.index ?? 0);

  List<File> _filesForTab(int index) {
    switch (index) {
      case 0: return allFiles;
      case 1: return pdfFiles;
      case 2: return wordFiles;
      case 3: return pptFiles;
      case 4: return excelFiles;
      default: return allFiles;
    }
  }

  String _getCurrentFileType() {
    switch (_tabController?.index) {
      case 0: return "All";
      case 1: return "PDF";
      case 2: return "Word";
      case 3: return "PPT";
      case 4: return "Excel";
      default: return "All";
    }
  }

  // ============================================
  // FLOATING ACTION BUTTON WIDGET
  // ============================================
  // Widget _buildFloatingActionButton() {
  //   return Consumer<FloatingButtonProvider>(
  //     builder: (context, provider, child) {
  //       return AnimatedContainer(
  //         duration: Duration(milliseconds: 300),
  //         margin: EdgeInsets.only(bottom: provider.isVisible ? 80.h : 0),
  //         child: FloatingActionButton(
  //           onPressed: () {
  //             if (provider.isVisible) {
  //               _floatingButtonProvider.toggleVisibility();
  //             } else {
  //               Get.to(() => MultiSelectScreen(
  //                 files: _getCurrentTabFiles(),
  //                 fileType: _getCurrentFileType(),
  //                 name: "HomeScreen",
  //               ));
  //             }
  //           },
  //           backgroundColor: Colors.black,
  //           child: provider.isVisible
  //               ? Icon(Icons.close, color: Colors.white)
  //               : Icon(Icons.add, color: Colors.white),
  //         ),
  //       );
  //     },
  //   );
  // }

  // ============================================
  // BUILD METHOD
  // ============================================
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 650;

    return WillPopScope(
      onWillPop: _exitDialog,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(width, isTablet),
        body: Stack(
          children: [
            // Main content
            TabBarView(
              controller: _tabController,
              children: [
                buildFileList(allFiles, "All"),
                buildFileList(pdfFiles, "PDF"),
                buildFileList(wordFiles, "Word"),
                buildFileList(pptFiles, "PPT"),
                buildFileList(excelFiles, "Excel"),
              ],
            ),

            // Floating AI Search Button
            if (_isPdfOpen && _showFloatingAiButton)
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingAiSearchButton(
                  isVisible: _showFloatingAiButton,
                  selectedText: _selectedText,
                  onTap: _openAiSearchWithSelectedText,
                ),
              ),
          ],
        ),
        //floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  AppBar _buildAppBar(double width, bool isTablet) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 4,
      backgroundColor: Colors.red,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Color(0xffDE2429)),
          const SizedBox(width: 5),
          // Flexible: on narrow phones or with large system font sizes the
          // title overflowed into the action icons.
          Flexible(
            child: Text(
              "PDF Reader",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: "Inter",
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(
          iconPath: "assets/search.svg",
          onTap: () async {
            final int tab = _tabController?.index ?? 0;
            await Get.to(() => SearchScreen(
              files: () => _filesForTab(tab),
              changes: _listsChanged,
              fileType: _getCurrentFileType(),
              name: "HomeScreen",
              onShowBottomSheet: showBottomSheet,
              onOpenFile: _openWithPdfTron,
              toggleBookmark: _toggleBookmark,
            ));
            _afterReturn();
          },
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width /20),
        _buildActionButton(
          iconPath: "assets/bookmark.svg",
          onTap: () async {
            await Get.to(() => const BookmarkScreen());
            _afterReturn();
          },
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width / 50),
        _buildActionButton(
          iconPath: "assets/select.svg",
          onTap: () async {
            await Get.to(() => MultiSelectScreen(
              files: List<File>.from(_getCurrentTabFiles()),
              fileType: _getCurrentFileType(),
              name: "HomeScreen",
            ));
            _afterReturn();
          },
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width / 50),
        _buildActionButton(
          iconPath: "assets/settings.svg",
          onTap: () => Get.to(() => const SettingScreen()),
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width / 50),
      ],
      bottom: PreferredSize(
        preferredSize:  Size.fromHeight(60.h),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TabBar(

                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xffDE2429),
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xffFFE5E5),
                ),
                labelStyle: const TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "PDF"),
                  Tab(text: "Word"),
                  Tab(text: "PPT"),
                  Tab(text: "Excel"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required VoidCallback onTap,
    required bool isTablet,
    required double width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: SvgPicture.asset(
        iconPath,
        color: Colors.black,
        height: isTablet ? width / 25 : width / 18,
        width: isTablet ? width / 25 : width / 18,
      ),
    );
  }

  Widget buildFileList(List<File> files, String fileType) {
    return RefreshIndicator(
      onRefresh: _refreshFiles,
      color: Colors.black,
      child: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : files.isEmpty
          ? _buildEmptyState(fileType)
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return FileListItem(
            key: ValueKey(files[index].path),
            file: files[index],
            isBookmarked: bookmarkedFiles.any(
                  (f) => f.path == files[index].path,
            ),
            onTap: () => _openWithPdfTron(files[index].path),
            onMoreTap: () => showBottomSheet(files[index]),
            onBookmarkTap: () => _toggleBookmark(files[index]),
          );
        },
        separatorBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Divider(color: Colors.black.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String fileType) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                const Color(0xff000000),
                BlendMode.srcATop,
              ),
              child: Lottie.asset("assets/nodata.json"),
            ),
            Text(
              fileType == "All"
                  ? "No file found"
                  : "$fileType files not found",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontFamily: "Inter",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating AI Search Button Widget
class FloatingAiSearchButton extends StatelessWidget {
  final bool isVisible;
  final String selectedText;
  final VoidCallback onTap;

  const FloatingAiSearchButton({
    Key? key,
    required this.isVisible,
    required this.selectedText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.8,
        duration: Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "AI Search",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Inter",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}