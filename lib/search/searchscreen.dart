import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constant/constant.dart';
import '../services/bookmark_service.dart';
import '../widget/file_meta.dart';

class SearchScreen extends StatefulWidget {
  /// Returns the current list to search. It is read again whenever
  /// [changes] fires, so renames, deletes and rescans show up here.
  final List<File> Function() files;
  final Listenable? changes;
  final String fileType;
  final String name;
  final Function(File) onShowBottomSheet;
  final Function(String) onOpenFile;
  final Future<void> Function(File) toggleBookmark;

  SearchScreen({required this.files, this.changes, required this.fileType,required this.name,    required this.onShowBottomSheet,
    required this.onOpenFile,required this.toggleBookmark, });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

// ignore_for_file: library_private_types_in_public_api

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<File> _filteredFiles = [];

  // InterstitialAd? interstitialAd;
  // BannerAd? bannerAd;

  bool isBannerAdLoaded = false;

  void _loadBannerAd() {
    // Dispose the previous banner ad if exists
    // bannerAd?.dispose();
    // bannerAd = null;
    isBannerAdLoaded = false; // Reset loading state

    // Load new banner ad
    // bannerAd = BannerAd(
    //   size: AdSize.banner,
    //   adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       setState(() {
    //         isBannerAdLoaded = true; // Ad is now loaded
    //       });
    //     },
    //     onAdFailedToLoad: (ad, error) {
    //       print("Banner Ad failed to load: $error");
    //       isBannerAdLoaded = false;
    //     },
    //   ),
    //   request: AdRequest(),
    // );

    // bannerAd!.load(); // Call load explicitly
  }

  @override
  void initState() {
    super.initState();
    // AdHelper.loadInterstitialAd((ad) {
    //   setState(() {
    //     interstitialAd = ad;
    //   });
    // });
    _loadBannerAd();
    _filteredFiles = widget.files(); // Initially show all files
    widget.changes?.addListener(_onFilesChanged);
  }

  void _onFilesChanged() {
    if (mounted) _filterFiles(_searchController.text);
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_onFilesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFiles(String query) {
    setState(() {
      final List<File> files = widget.files();
      if (query.isEmpty) {
        _filteredFiles = files;
      } else {
        _filteredFiles = files
            .where((file) => file.path.split('/').last.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String getIconForFile(String filePath) {
    if (filePath.toLowerCase().endsWith(Constants.pdf)) {
      return 'assets/pdf.svg';
    } else if (filePath.toLowerCase().endsWith(Constants.doc) || filePath.toLowerCase().endsWith(Constants.docx)) {
      return 'assets/word.svg';
    } else if (filePath.toLowerCase().endsWith(Constants.xlsx) || filePath.toLowerCase().endsWith(Constants.xls)) {
      return 'assets/excel.svg';
    } else if (filePath.toLowerCase().endsWith(Constants.ppt) || filePath.toLowerCase().endsWith(Constants.pptx)) {
      return 'assets/ppt.svg';
    } else {
      return 'assets/default.svg'; // Default icon if the file type isn't recognized
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        // Return to the screen that opened search instead of pushing a new
        // copy of it (which re-scanned storage and lost the bottom bar).
        leading: IconButton(onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios_new,color: Colors.black,)),
        automaticallyImplyLeading: false,
        title: Padding(
          padding:  EdgeInsets.only(right: 8.w),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Color(0xffD4D4D4).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFiles,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Search ${widget.fileType} files",
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isEmpty ? SizedBox() : IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterFiles(""); // Reset the search results
                  },
                ),
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),

      body: _filteredFiles.isEmpty
          ? Center(
        child: Text("No files found", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey)),
      )
          : ListView.separated(
        itemCount: _filteredFiles.length,
        itemBuilder: (context, index) {
          File file = _filteredFiles[index];
          String fileName = file.path.split('/').last;
          String iconPath = getIconForFile(file.path);

          bool isBookmarked = BookmarkService().isBookmarked(file);

          return CupertinoListTile(
            key: ValueKey(file.path),
            leading: SvgPicture.asset(iconPath, width: 40, height: 40),
            title: Text(fileName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: FileMetaBuilder(
              file: file,
              builder: (context, stat) => Text(
                  stat == null
                      ? ''
                      : "${formatFileDate(stat.modified, pad: false)} - ${formatFileSize(stat.size)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isBookmarked ?   InkWell(
                  onTap: () async {
                    await widget.toggleBookmark(file);
                    if (mounted) setState(() {});
                  },
                  child: SvgPicture.asset(
                    "assets/bookmark_filled.svg",
                    height: 18.h,
                    width: 18.w,
                    color: Colors.green,
                  ),
                ) : SizedBox(),
                SizedBox(width: 7.w,),
                InkWell(
                  child:  Icon(Icons.more_vert,size: 22.sp,),
                  onTap:  () {
                    widget.onShowBottomSheet(file);
                  }
                ),
              ],
            ),
            onTap: () {
              widget.onOpenFile(file.path);
              // if (interstitialAd != null) {
              //   interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              //     onAdDismissedFullScreenContent: (ad) {
              //       widget.onOpenFile(file.path);
              //       ad.dispose();
              //       interstitialAd = null;
              //       AdHelper.loadInterstitialAd((ad) {
              //         setState(() {
              //           interstitialAd = ad;
              //         });
              //       });
              //     },
              //     onAdFailedToShowFullScreenContent: (ad, error) {
              //       widget.onOpenFile(file.path);
              //       ad.dispose();
              //       interstitialAd = null;
              //       AdHelper.loadInterstitialAd((ad) {
              //         setState(() {
              //           interstitialAd = ad;
              //         });
              //       });
              //     },
              //   );
              //   interstitialAd!.show();
              // } else {
              //   widget.onOpenFile(file.path);
              // }
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey.withOpacity(0.2)),
      ),
      // bottomNavigationBar:        bannerAd != null && isBannerAdLoaded
      //     ? Container(
      //   height: 50,
      //   alignment: Alignment.center,
      //   child: AdWidget(ad: bannerAd!),
      // )
      //     : SizedBox(height: 50),
    );
  }


}
