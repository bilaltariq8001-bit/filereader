import 'dart:io';
import 'package:documentreader/constant/common_method.dart';
import 'package:documentreader/home/homescreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adhelper/adhelper.dart';
import '../constant/color.dart';
import '../constant/constant.dart';
import '../multiselect/MultiSelectScreen.dart';
import '../search/searchscreen.dart';
import '../setting/settingscreen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _openedWithPdfTron = false;

  // InterstitialAd? interstitialAd;
  // BannerAd? bannerAd;

  bool isBannerAdLoaded = false;
  bool isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // AdHelper.loadInterstitialAd((ad) {
    //   setState(() {
    //     interstitialAd = ad;
    //   });
    // });

    _tabController = TabController(length: 5, vsync: this);
    _requestPermission();
    _tabController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadFiles();
    _loadBannerAd();
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final Directory rootDirectory = Directory('/storage/emulated/0/');
      if (await rootDirectory.exists()) {
        final List<FileSystemEntity> allFilesList =
            await _getAllFiles(rootDirectory);
        
        if (!mounted) return;
        
        setState(() {
          allFiles = allFilesList.whereType<File>().where((file) {
            final String path = file.path.toLowerCase();
            return path.endsWith(Constants.pdf) ||
                path.endsWith(Constants.doc) ||
                path.endsWith(Constants.docx) ||
                path.endsWith(Constants.ppt) ||
                path.endsWith(Constants.pptx) ||
                path.endsWith(Constants.xlsx) ||
                path.endsWith(Constants.xls);
          }).toList();

          pdfFiles = allFiles
              .where((file) => file.path.toLowerCase().endsWith(Constants.pdf))
              .toList();

          wordFiles = allFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.doc) ||
                  file.path.toLowerCase().endsWith(Constants.docx))
              .toList();

          pptFiles = allFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.ppt) ||
                  file.path.toLowerCase().endsWith(Constants.pptx))
              .toList();

          excelFiles = allFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.xlsx) ||
                  file.path.toLowerCase().endsWith(Constants.xls))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load files'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _loadBannerAd() {
    // Dispose the previous banner ad if exists
    // bannerAd?.dispose();
    // bannerAd = null;
    isBannerAdLoaded = false;

    // Load new banner ad
    // bannerAd = BannerAd(
    //   size: AdSize.banner,
    //   adUnitId: 'ca-app-pub-3940256099942544/6300978111',
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       setState(() {
    //         isBannerAdLoaded = true;
    //       });
    //     },
    //     onAdFailedToLoad: (ad, error) {
    //       print("Banner Ad failed to load: $error");
    //       isBannerAdLoaded = false;
    //     },
    //   ),
    //   request: AdRequest(),
    // );

    // bannerAd!.load();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final PermissionStatus storageStatus = await Permission.storage.status;
      final PermissionStatus manageStorageStatus =
          await Permission.manageExternalStorage.status;

      if (storageStatus.isGranted || manageStorageStatus.isGranted) {
        await _loadBookmarks();
      } else {
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();

        if (statuses[Permission.storage]?.isGranted == true ||
            statuses[Permission.manageExternalStorage]?.isGranted == true) {
          await _loadBookmarks();
        } else {
          _showPermissionDeniedDialog();
        }
      }
    } else {
      await _loadBookmarks();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Storage permission is required to access your documents. '
            'Please grant permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<List<FileSystemEntity>> _getAllFiles(Directory directory) async {
    final List<FileSystemEntity> files = [];
    try {
      await for (final FileSystemEntity entity
          in directory.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        } else if (entity is Directory) {
          try {
            files.addAll(await _getAllFiles(entity));
          } catch (e) {
            // Ignore directories with permission issues
          }
        }
      }
    } catch (e) {
      // Handle directory access errors
    }
    return files;
  }

  Future<void> _openWithPdfTron(String path) async {
    if (_openedWithPdfTron) return;

    _openedWithPdfTron = true;
    try {
      await PdftronFlutter.initialize();
      final String filePath =
          path.startsWith("file://") ? path : "file://$path";
      await PdftronFlutter.openDocument(filePath);
    } catch (e) {
      print('Error opening file with PDFTron: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _openedWithPdfTron = false;
    }
  }

  Future<void> _loadBookmarks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? paths = prefs.getStringList("bookmarks");

      if (paths != null) {
        final List<File> tempBookmarkedFiles = paths.map((path) => File(path)).toList();

        // Remove files that no longer exist
        final List<File> existingFiles = [];
        for (final file in tempBookmarkedFiles) {
          if (await file.exists()) {
            existingFiles.add(file);
          }
        }

        if (!mounted) return;

        setState(() {
          bookmarkedFiles = existingFiles;
          bookmarkedPdfFiles = bookmarkedFiles
              .where((file) => file.path.toLowerCase().endsWith(Constants.pdf))
              .toList();
          bookmarkedWordFiles = bookmarkedFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.doc) ||
                  file.path.toLowerCase().endsWith(Constants.docx))
              .toList();
          bookmarkedPptFiles = bookmarkedFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.ppt) ||
                  file.path.toLowerCase().endsWith(Constants.pptx))
              .toList();
          bookmarkedExcelFiles = bookmarkedFiles
              .where((file) =>
                  file.path.toLowerCase().endsWith(Constants.xlsx) ||
                  file.path.toLowerCase().endsWith(Constants.xls))
              .toList();
        });

        // Save filtered bookmarks
        final List<String> updatedPaths =
            bookmarkedFiles.map((file) => file.path).toList();
        await prefs.setStringList("bookmarks", updatedPaths);
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load bookmarks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _removeBookmark(File file) {
    setState(() {
      bookmarkedFiles.remove(file);
      bookmarkedPdfFiles.remove(file);
      bookmarkedWordFiles.remove(file);
      bookmarkedPptFiles.remove(file);
      bookmarkedExcelFiles.remove(file);
      saveBookmarks();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Bookmark removed"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            _restoreBookmark(file);
          },
        ),
      ),
    );
  }

  void _restoreBookmark(File file) {
    setState(() {
      bookmarkedFiles.add(file);
      final String path = file.path.toLowerCase();
      if (path.endsWith(Constants.pdf)) {
        bookmarkedPdfFiles.add(file);
      } else if (path.endsWith(Constants.doc) || path.endsWith(Constants.docx)) {
        bookmarkedWordFiles.add(file);
      } else if (path.endsWith(Constants.ppt) || path.endsWith(Constants.pptx)) {
        bookmarkedPptFiles.add(file);
      } else if (path.endsWith(Constants.xlsx) || path.endsWith(Constants.xls)) {
        bookmarkedExcelFiles.add(file);
      }
      saveBookmarks();
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(() {});
    _tabController?.dispose();
    // bannerAd?.dispose();
    // interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 650;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.offAll(() =>  HomeScreen()),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: Text("Bookmark",
            style: TextStyle(color: Colors.black, fontFamily: "Inter")),
        backgroundColor: Colors.white,
        actions: [
          _buildActionButton(
            iconPath: "assets/search.svg",
            onTap: () {
              final List<File> filesToSearch = _getCurrentTabBookmarkedFiles();
              Get.to(() => SearchScreen(
                    files: filesToSearch,
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
            onTap: () {
              final List<File> filesToSelect = _getCurrentTabBookmarkedFiles();
              Get.to(() => MultiSelectScreen(
                    files: filesToSelect,
                    fileType: _getCurrentFileType(),
                    name: "BookmarkScreen",
                  ));
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

  List<File> _getCurrentTabBookmarkedFiles() {
    switch (_tabController?.index) {
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
    final bool isBookmarked = bookmarkedFiles.contains(file);
    final int fileSizeInBytes = file.lengthSync();
    final double fileSizeInKB = fileSizeInBytes / 1024;
    final double fileSizeInMB = fileSizeInKB / 1024;
    final String formattedSize = fileSizeInMB >= 1
        ? '${fileSizeInMB.toStringAsFixed(2)} MB'
        : '${fileSizeInKB.toStringAsFixed(2)} KB';

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
                    SvgPicture.asset(
                      iconPath,
                      height: 40.h,
                      width: 40.w,
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
                        if (isBookmarked) {
                          _removeBookmark(file);
                        } else {
                          _restoreBookmark(file);
                        }
                        Navigator.pop(context);
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
    final String fileName = file.path.split('/').last;
    final String fileExtension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';

    final TextEditingController renameController = TextEditingController(
        text: fileName.replaceAll(fileExtension, ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
            child: Text("Rename",
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Inter"))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: renameController,
                cursorColor: Colors.black,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: "Inter",
                    color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter new file name",
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_hint),
                      borderRadius: BorderRadius.circular(6.r)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                      borderRadius: BorderRadius.circular(6.r)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                ),
              ),
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.redAccent, fontFamily: "Inter")),
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
                      onPressed: () {
                        final String newName = renameController.text.trim();
                        if (newName.isNotEmpty) {
                          final String newFullName = newName + fileExtension;
                          Navigator.pop(context);
                          _performRename(file, newFullName);
                        }
                      },
                      child: const Text("OK",
                          style: TextStyle(color: Colors.white, fontFamily: "Inter")),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performRename(File file, String newName) async {
    try {
      final String newPath = '${file.parent.path}/$newName';
      final File newFile = await file.rename(newPath);

      // Update all file lists
      void updateFileInList(List<File> list) {
        final int index = list.indexWhere((f) => f.path == file.path);
        if (index != -1) {
          list[index] = newFile;
        }
      }

      setState(() {
        updateFileInList(allFiles);
        updateFileInList(pdfFiles);
        updateFileInList(wordFiles);
        updateFileInList(pptFiles);
        updateFileInList(excelFiles);
      });

      // Update bookmarks
      if (bookmarkedFiles.any((f) => f.path == file.path)) {
        setState(() {
          updateFileInList(bookmarkedFiles);
          updateFileInList(bookmarkedPdfFiles);
          updateFileInList(bookmarkedWordFiles);
          updateFileInList(bookmarkedPptFiles);
          updateFileInList(bookmarkedExcelFiles);
        });
        saveBookmarks();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File renamed successfully")),
      );
    } catch (e) {
      print('Error renaming file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error renaming file")),
      );
    }
  }

  void _confirmDelete(File file) {
    final String fileName = file.path.split('/').last;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete $fileName?",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to permanently delete this file?"),
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.redAccent, fontFamily: "Inter")),
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
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteFile(file);
                    },
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.white, fontFamily: "Inter")),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFile(File file) async {
    try {
      if (await file.exists()) {
        final String filePath = file.path;
        final bool wasBookmarked = bookmarkedFiles.contains(file);

        // Store file for potential undo
        final File tempFile = File(filePath);

        // Delete file
        await file.delete();

        setState(() {
          // Remove from all lists
          void removeFileFromList(List<File> list) {
            list.removeWhere((f) => f.path == filePath);
          }

          removeFileFromList(allFiles);
          removeFileFromList(pdfFiles);
          removeFileFromList(wordFiles);
          removeFileFromList(pptFiles);
          removeFileFromList(excelFiles);

          // Remove from bookmarks if bookmarked
          if (wasBookmarked) {
            removeFileFromList(bookmarkedFiles);
            removeFileFromList(bookmarkedPdfFiles);
            removeFileFromList(bookmarkedWordFiles);
            removeFileFromList(bookmarkedPptFiles);
            removeFileFromList(bookmarkedExcelFiles);
            saveBookmarks();
          }
        });

        // Show undo snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: const Text("File deleted successfully"),
            action: SnackBarAction(
              label: "Undo",
              textColor: Colors.white,
              onPressed: () async {
                try {
                  // Try to restore the file
                  await tempFile.create();

                  setState(() {
                    allFiles.add(tempFile);
                    final String path = tempFile.path.toLowerCase();
                    if (path.endsWith(Constants.pdf)) {
                      pdfFiles.add(tempFile);
                    } else if (path.endsWith(Constants.doc) ||
                        path.endsWith(Constants.docx)) {
                      wordFiles.add(tempFile);
                    } else if (path.endsWith(Constants.ppt) ||
                        path.endsWith(Constants.pptx)) {
                      pptFiles.add(tempFile);
                    } else if (path.endsWith(Constants.xlsx) ||
                        path.endsWith(Constants.xls)) {
                      excelFiles.add(tempFile);
                    }

                    if (wasBookmarked) {
                      bookmarkedFiles.add(tempFile);
                      if (path.endsWith(Constants.pdf)) {
                        bookmarkedPdfFiles.add(tempFile);
                      } else if (path.endsWith(Constants.doc) ||
                          path.endsWith(Constants.docx)) {
                        bookmarkedWordFiles.add(tempFile);
                      } else if (path.endsWith(Constants.ppt) ||
                          path.endsWith(Constants.pptx)) {
                        bookmarkedPptFiles.add(tempFile);
                      } else if (path.endsWith(Constants.xlsx) ||
                          path.endsWith(Constants.xls)) {
                        bookmarkedExcelFiles.add(tempFile);
                      }
                      saveBookmarks();
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("File restored successfully",
                            style: TextStyle(
                                color: Colors.white, fontFamily: "Inter"))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to restore file")),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting file")),
      );
    }
  }

  Future<void> _refreshFiles() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    await _loadFiles();
    await _loadBookmarks();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildFileList(List<File> files, String fileType) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
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
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final File file = files[index];

                        // Skip files that no longer exist
                        if (!file.existsSync()) {
                          return const SizedBox.shrink();
                        }

                        final String fileName = file.path.split('/').last;
                        final String iconPath = getIconForFile(file.path);
                        final DateTime lastModified = file.lastModifiedSync();
                        final String formattedDate =
                            "${lastModified.day.toString().padLeft(2, '0')}/${lastModified.month.toString().padLeft(2, '0')}/${lastModified.year}";

                        final int fileSizeInBytes = file.lengthSync();
                        final double fileSizeInKB = fileSizeInBytes / 1024;
                        final double fileSizeInMB = fileSizeInKB / 1024;
                        final String formattedSize = fileSizeInMB >= 1
                            ? '${fileSizeInMB.toStringAsFixed(2)} MB'
                            : '${fileSizeInKB.toStringAsFixed(2)} KB';

                        final bool isBookmarked =
                            bookmarkedFiles.any((f) => f.path == file.path);

                        return CupertinoListTile(
                          leading:
                              SvgPicture.asset(iconPath, width: 40.w, height: 40.h),
                          title: Text(fileName,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Inter")),
                          subtitle: Text("$formattedDate - $formattedSize",
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey,
                                  fontFamily: "Inter")),
                          trailing: Row(
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