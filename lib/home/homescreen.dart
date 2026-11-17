import 'dart:io';
import 'package:documentreader/bookmark/bookmark.dart';
import 'package:documentreader/constant/color.dart';
import 'package:documentreader/setting/settingscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';

import '../constant/constant.dart';
import '../controller/fab_controller_pr.dart';
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
import '../widget/floating_action_button.dart';
import '../widget/text_helping_dialoags.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _openedWithPdfTron = false;
  bool isBannerAdLoaded = false;
  bool isLoading = true;
  String? _currentOpenedFilePath;
  late FloatingButtonProvider _floatingButtonProvider;

  // PDF State
  bool _isPdfOpen = false;
  int? _currentPageNumber;
  int? _totalPages;
  double? _currentZoom;
  bool _canUndo = false;
  bool _canRedo = false;

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
    _initializeServices();
    _initializeTabController();
    _requestPermission();
    _loadBannerAd();
    _setupPdfTronListeners();
    _floatingButtonProvider = context.read<FloatingButtonProvider>();

    // Listen to clipboard changes
    Clipboard.getData(Clipboard.kTextPlain).then(_handleClipboardData);
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
    _tabController!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _setupPdfTronListeners() {
    // You can setup event listeners for PDFTron if needed
    // For example, to listen for page change events
  }

  void _handleClipboardData(ClipboardData? data) {
    if (data != null && data.text != null && data.text!.isNotEmpty && _isPdfOpen) {
      setState(() {
        _selectedText = data.text!;
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
    _tabController?.dispose();
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
  void _setFilesToState(List<File> files) {
    setState(() {
      allFiles = files;
      pdfFiles = files.where((f) => f.path.toLowerCase().endsWith('.pdf')).toList();
      wordFiles = files.where((f) => f.path.endsWith('.doc') || f.path.endsWith('.docx')).toList();
      pptFiles = files.where((f) => f.path.endsWith('.ppt') || f.path.endsWith('.pptx')).toList();
      excelFiles = files.where((f) => f.path.endsWith('.xls') || f.path.endsWith('.xlsx')).toList();
    });
  }

  void _updateStateWithFileData(dynamic fileData) {
    setState(() {
      allFiles = fileData.allFiles;
      pdfFiles = fileData.pdfFiles;
      wordFiles = fileData.wordFiles;
      pptFiles = fileData.pptFiles;
      excelFiles = fileData.excelFiles;
    });
  }

  Future<void> _refreshFilesInBackground() async {
    try {
      final fileData = await _fileService.loadAllFiles();
      if (!mounted) return;
      _updateStateWithFileData(fileData);
      await _fileService.cacheFiles(fileData.allFiles);
    } catch (_) {}
  }

  Future<void> loadFiles() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final cachedFiles = await _fileService.getCachedFiles();
      if (cachedFiles != null && cachedFiles.isNotEmpty) {
        _setFilesToState(cachedFiles);
        _refreshFilesInBackground();
        setState(() => isLoading = false);
        return;
      }

      final fileData = await _fileService.loadAllFiles();
      if (!mounted) return;
      _updateStateWithFileData(fileData);
      await _fileService.cacheFiles(fileData.allFiles);
    } catch (e) {
      debugPrint('File load error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarkData = await _bookmarkService.loadBookmarks();
    if (!mounted) return;

    setState(() {
      bookmarkedFiles = bookmarkData.bookmarkedFiles;
      bookmarkedPdfFiles = bookmarkData.bookmarkedPdfFiles;
      bookmarkedWordFiles = bookmarkData.bookmarkedWordFiles;
      bookmarkedPptFiles = bookmarkData.bookmarkedPptFiles;
      bookmarkedExcelFiles = bookmarkData.bookmarkedExcelFiles;
    });
  }

  void _toggleBookmark(File file) async {
    final result = await _bookmarkService.toggleBookmark(file);
    setState(() {
      bookmarkedFiles = result.bookmarkedFiles;
      bookmarkedPdfFiles = result.bookmarkedPdfFiles;
      bookmarkedWordFiles = result.bookmarkedWordFiles;
      bookmarkedPptFiles = result.bookmarkedPptFiles;
      bookmarkedExcelFiles = result.bookmarkedExcelFiles;
    });

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
  Future<void> _openWithPdfTron(String path) async {
    if (_openedWithPdfTron) return;
    _openedWithPdfTron = true;

    try {
      _currentOpenedFilePath = await _pdfService.openDocument(path);

      setState(() {
        _isPdfOpen = true;
      });

      // Load PDF info in background
      _loadPdfInfo();

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _pdfService.showTextSelectionTip();
        });
      }
    } finally {
      _openedWithPdfTron = false;
    }
  }

  Future<void> _loadPdfInfo() async {
    // Get page count
    _totalPages = await _pdfService.getPageCount();

    // Get current page
    _currentPageNumber = await _pdfService.getCurrentPage();

    // Get zoom level
    _currentZoom = await _pdfService.getZoom();


    _canUndo = await _pdfService.canUndo() ?? false;
    _canRedo = await _pdfService.canRedo() ?? false;

    if (mounted) setState(() {});
  }

  Future<void> _enableTextSelectionMode() async {
    await _pdfService.enableTextSelectionMode();
  }

  Future<void> _openSearchInDocument() async {
    await _pdfService.openSearchInDocument();
  }

  Future<void> _openAiSearch(String filePath) async {
    await _aiSearchService.openAiSearch(filePath: filePath);
  }

  Future<void> _openAiSearchWithSelectedText() async {
    if (_currentOpenedFilePath != null) {
      await _aiSearchService.openAiSearch(
        filePath: _currentOpenedFilePath!,
        initialQuery: _selectedText,
      );
      setState(() {
        _showFloatingAiButton = false;
      });
    }
  }
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
              onTap: _enableTextSelectionMode,
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
              onTap: _openSearchInDocument,
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


  Future<void> _shareExportedImage(String imagePath) async {
    // Implement sharing logic
  }



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

    if (bookmarkedFiles.any((f) => f.path == oldFile.path)) {
      setState(() {
        _bookmarkService.updateBookmarkedFile(oldFile, newFile);
      });
    }
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
    );

    if (result.success) {
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
        _openWithPdfTron(file.path);
        Future.delayed(const Duration(milliseconds: 800), () {
          _enableTextSelectionMode();
        });
      },
      onSearch: () {
        _openWithPdfTron(file.path);
        Future.delayed(const Duration(milliseconds: 800), () {
          _openSearchInDocument();
        });
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
    setState(() {
      _isPdfOpen = false;
      _showFloatingAiButton = false;
    });

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
    setState(() => isLoading = true);
    await _requestPermission();
    if (mounted) setState(() => isLoading = false);
  }

  List<File> _getCurrentTabFiles() {
    switch (_tabController?.index) {
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
          Text(
            "PDF Reader",
            style: TextStyle(
              color: Colors.black,
              fontFamily: "Inter",
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(
          iconPath: "assets/search.svg",
          onTap: () {
            Get.to(() => SearchScreen(
              files: _getCurrentTabFiles(),
              fileType: _getCurrentFileType(),
              name: "HomeScreen",
              onShowBottomSheet: showBottomSheet,
              onOpenFile: _openWithPdfTron,
              toggleBookmark: _toggleBookmark,
            ));
          },
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width /20),
        _buildActionButton(
          iconPath: "assets/bookmark.svg",
          onTap: () => Get.to(() => BookmarkScreen()),
          isTablet: isTablet,
          width: width,
        ),
        SizedBox(width: width / 50),
        _buildActionButton(
          iconPath: "assets/select.svg",
          onTap: () {
            Get.to(() => MultiSelectScreen(
              files: _getCurrentTabFiles(),
              fileType: _getCurrentFileType(),
              name: "HomeScreen",
            ));
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
        itemCount: files.length,
        itemBuilder: (context, index) {
          return FileListItem(
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