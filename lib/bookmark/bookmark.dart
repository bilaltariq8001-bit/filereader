import 'dart:io';
import 'package:documentreader/constant/common_method.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../multiselect/MultiSelectScreen.dart';
import '../search/searchscreen.dart';
import '../services/bookmark_service.dart';
import '../services/file_services.dart';
import '../services/pdf_dervices.dart';
import '../setting/settingscreen.dart';
import '../widget/file_meta.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _openedWithPdfTron = false;
  bool isLoading = true;

  final BookmarkService _bookmarkService = BookmarkService();
  final FileService _fileService = FileService();
  late final PdfService _pdfService = PdfService(context: context);

  List<File> bookmarkedFiles = [];
  List<File> bookmarkedPdfFiles = [];
  List<File> bookmarkedWordFiles = [];
  List<File> bookmarkedPptFiles = [];
  List<File> bookmarkedExcelFiles = [];

  /// Lets the search screen opened from here follow changes.
  final ValueNotifier<int> _listsChanged = ValueNotifier<int>(0);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _listsChanged.value++;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Bookmarks are a stored list of paths; no storage scan is needed here.
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _listsChanged.dispose();
    super.dispose();
  }

  void _apply(BookmarkData data) {
    if (!mounted) return;
    setState(() {
      bookmarkedFiles = data.bookmarkedFiles;
      bookmarkedPdfFiles = data.bookmarkedPdfFiles;
      bookmarkedWordFiles = data.bookmarkedWordFiles;
      bookmarkedPptFiles = data.bookmarkedPptFiles;
      bookmarkedExcelFiles = data.bookmarkedExcelFiles;
    });
  }

  Future<void> _loadBookmarks({bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) setState(() => isLoading = true);
    try {
      // Drops bookmarks whose file was deleted or moved outside the app.
      _apply(await _bookmarkService.loadBookmarks(dropMissing: true));
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load bookmarks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openWithPdfTron(String path) async {
    if (_openedWithPdfTron) return;
    _openedWithPdfTron = true;
    try {
      if (!await File(path).exists()) {
        _showError('This file no longer exists');
        _loadBookmarks(showSpinner: false);
        return;
      }
      await _pdfService.openDocument(path, showTip: false);
    } catch (e) {
      debugPrint('Error opening file with PDFTron: $e');
      _showError('Failed to open file');
    } finally {
      _openedWithPdfTron = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _removeBookmark(File file) async {
    _apply(await _bookmarkService.removeBookmark(file.path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Bookmark removed"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () => _restoreBookmark(file),
        ),
      ),
    );
  }

  Future<void> _restoreBookmark(File file) async {
    _apply(await _bookmarkService.addBookmark(file.path));
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 650;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          // Go back to where Bookmarks was opened from. offAll() replaced
          // the whole app with a bare HomeScreen and lost the bottom bar.
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: Text("Bookmark",
            style: TextStyle(color: Colors.black, fontFamily: "Inter")),
        backgroundColor: Colors.white,
        actions: [
          _buildActionButton(
            iconPath: "assets/search.svg",
            onTap: () {
              final int tab = _tabController?.index ?? 0;
              Get.to(() => SearchScreen(
                    files: () => _bookmarksForTab(tab),
                    changes: _listsChanged,
                    fileType: _getCurrentFileType(),
                    name: "BookmarkScreen",
                    onShowBottomSheet: showBottomSheet,
                    onOpenFile: _openWithPdfTron,
                    toggleBookmark: _removeBookmark,
                  ));
            },
            isTablet: isTablet,
            width: width,
          ),
          SizedBox(width: width / 40),
          _buildActionButton(
            iconPath: "assets/select.svg",
            onTap: () async {
              final List<File> filesToSelect =
                  List<File>.from(_getCurrentTabBookmarkedFiles());
              await Get.to(() => MultiSelectScreen(
                    files: filesToSelect,
                    fileType: _getCurrentFileType(),
                    name: "BookmarkScreen",
                  ));
              _loadBookmarks(showSpinner: false);
            },
            isTablet: isTablet,
            width: width,
          ),
          SizedBox(width: width / 40),
          _buildActionButton(
            iconPath: "assets/settings.svg",
            onTap: () => Get.to(() => const SettingScreen()),
            isTablet: isTablet,
            width: width,
          ),
          SizedBox(width: width / 40),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xffDE2429),
          labelStyle: const TextStyle(fontFamily: "Inter", fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontFamily: "Inter", fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "PDF"),
            Tab(text: "Word"),
            Tab(text: "PPT"),
            Tab(text: "Excel"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileList(bookmarkedFiles, "All"),
          _buildFileList(bookmarkedPdfFiles, "PDF"),
          _buildFileList(bookmarkedWordFiles, "Word"),
          _buildFileList(bookmarkedPptFiles, "PPT"),
          _buildFileList(bookmarkedExcelFiles, "Excel"),
        ],
      ),
      // bottomNavigationBar: bannerAd != null && isBannerAdLoaded
      //     ? Container(
      //         height: 50,
      //         alignment: Alignment.center,
      //         child: AdWidget(ad: bannerAd!),
      //       )
      //     : SizedBox(height: 50),
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

  List<File> _getCurrentTabBookmarkedFiles() =>
      _bookmarksForTab(_tabController?.index ?? 0);

  List<File> _bookmarksForTab(int index) {
    switch (index) {
      case 0:
        return bookmarkedFiles;
      case 1:
        return bookmarkedPdfFiles;
      case 2:
        return bookmarkedWordFiles;
      case 3:
        return bookmarkedPptFiles;
      case 4:
        return bookmarkedExcelFiles;
      default:
        return bookmarkedFiles;
    }
  }

  String _getCurrentFileType() {
    switch (_tabController?.index) {
      case 0:
        return "All";
      case 1:
        return "PDF";
      case 2:
        return "Word";
      case 3:
        return "PPT";
      case 4:
        return "Excel";
      default:
        return "All";
    }
  }

  void showBottomSheet(File file) {
    final bool isBookmarked = bookmarkedFiles.any((f) => f.path == file.path);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      builder: (context) {
        final String fileName = file.path.split('/').last;
        final String iconPath = getIconForFile(file.path);

        return Container(
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
          child: Column(
            children: [
              AppBar(
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
                    Image.asset(
                      iconPath,
                      height: 40.h,
                      width: 40.w,
                      cacheWidth: 144,
                      cacheHeight: 144,
                    ),
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
                          FileMetaBuilder(
                            file: file,
                            builder: (context, stat) => Text(
                            stat == null ? '' : formatFileSize(stat.size),
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontFamily: "Inter",
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomSheetAction(
                      iconPath: "assets/share.svg",
                      label: "Share",
                      onTap: () {
                        Navigator.pop(context);
                        _shareFile(file);
                      },
                    ),
                    _buildBottomSheetAction(
                      iconPath: isBookmarked
                          ? "assets/bookmark_filled.svg"
                          : "assets/bookmark_outlined.svg",
                      label: "Bookmark",
                      iconColor: isBookmarked ? Colors.green : Colors.black,
                      onTap: () {
                        Navigator.pop(context);
                        if (isBookmarked) {
                          _removeBookmark(file);
                        } else {
                          _restoreBookmark(file);
                        }
                      },
                    ),
                    _buildBottomSheetAction(
                      iconPath: "assets/rename.svg",
                      label: "Rename",
                      onTap: () {
                        Navigator.pop(context);
                        _renameFile(file);
                      },
                    ),
                    _buildBottomSheetAction(
                      iconPath: "assets/delete.svg",
                      label: "Delete",
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDelete(file);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetAction({
    required String iconPath,
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
          SvgPicture.asset(
            iconPath,
            height: 30.h,
            width: 30.w,
            color: iconColor,
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Check out this document",
      );
    } catch (e) {
      print('Error sharing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _renameFile(File file) {
    _fileService.showRenameDialog(
      context: context,
      file: file,
      // FileService renames the file and updates the stored bookmark.
      onRenamed: (oldFile, newFile) => _loadBookmarks(showSpinner: false),
    );
  }

  void _confirmDelete(File file) {
    _fileService.showDeleteConfirmation(
      context: context,
      file: file,
      onDelete: () => _deleteFile(file),
    );
  }

  Future<void> _deleteFile(File file) async {
    final result = await _fileService.deleteFile(
      file: file,
      context: context,
      allFiles: [],
      pdfFiles: [],
      wordFiles: [],
      pptFiles: [],
      excelFiles: [],
      bookmarkedFiles: bookmarkedFiles,
      onRestored: () => _loadBookmarks(showSpinner: false),
    );
    if (result.success) {
      _apply(await _bookmarkService.loadBookmarks());
    }
  }

  Future<void> _refreshFiles() async {
    await _loadBookmarks(showSpinner: false);
  }

  Widget _buildFileList(List<File> files, String fileType) {
    return RefreshIndicator(
      onRefresh: _refreshFiles,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                )
              : files.isEmpty
                  ? Center(
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
                              child: Lottie.asset("assets/nodata.json", height: 250.h),
                            ),
                            Text(
                              fileType == "All"
                                  ? "No bookmarks found"
                                  : "No $fileType bookmarks",
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  fontFamily: "Inter"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final File file = files[index];
                        final String fileName = file.path.split('/').last;
                        final String iconPath = getIconForFile(file.path);
                        final bool isBookmarked =
                            bookmarkedFiles.any((f) => f.path == file.path);

                        return CupertinoListTile(
                          key: ValueKey(file.path),
                          leading: Image.asset(iconPath,
                              width: 40.w,
                              height: 40.h,
                              cacheWidth: 144,
                              cacheHeight: 144),
                          title: Text(fileName,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Inter")),
                          subtitle: FileMetaBuilder(
                            file: file,
                            builder: (context, stat) => Text(
                                stat == null
                                    ? ''
                                    : "${formatFileDate(stat.modified)} - ${formatFileSize(stat.size)}",
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                    fontFamily: "Inter")),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBookmarked)
                                InkWell(
                                  onTap: () => _removeBookmark(file),
                                  child: SvgPicture.asset(
                                    "assets/bookmark_filled.svg",
                                    height: 18.h,
                                    width: 18.w,
                                    color: Colors.green,
                                  ),
                                ),
                              SizedBox(width: 7.w),
                              InkWell(
                                child: Icon(Icons.more_vert, size: 22.sp),
                                onTap: () => showBottomSheet(file),
                              ),
                            ],
                          ),
                          onTap: () {
                            _openWithPdfTron(file.path);
                          },
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(color: Colors.grey.withOpacity(0.2)),
                    ),
        ],
      ),
    );
  }
}