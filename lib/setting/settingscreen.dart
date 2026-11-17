import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constant/drawer.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  // BannerAd? bannerAd;

  bool isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }


  void _loadBannerAd() {
    // Dispose the previous banner ad if exists
    // bannerAd?.dispose();
    // bannerAd = null;
    isBannerAdLoaded = false; 

    // Load new banner ad
  //   bannerAd = BannerAd(
  //     size: AdSize.banner,
  //     adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit
  //     listener: BannerAdListener(
  //       onAdLoaded: (ad) {
  //         setState(() {
  //           isBannerAdLoaded = true; // Ad is now loaded
  //         });
  //       },
  //       onAdFailedToLoad: (ad, error) {
  //         print("Banner Ad failed to load: $error");
  //         isBannerAdLoaded = false;
  //       },
  //     ),
  //     request: AdRequest(),
  //   );

  //   bannerAd!.load(); // Call load explicitly
  }

  @override
  Widget build(BuildContext context) {

    List<Map<String, dynamic>> drawerItems = [
      {'icon': Icons.privacy_tip_rounded, 'title': 'Privacy Policy', 'onTap': () => privacypolicyURL(context),},
      {'icon': Icons.share, 'title': 'Share', 'onTap': () => shareURL(context),},
      {'icon': Icons.star, 'title': 'Rate App', 'onTap': () => rateApp(),},
    ];
    double width=MediaQuery.of(context).size.width;
    bool isTablet = width >= 650;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        leading: IconButton(onPressed: (){Get.back();}, icon: Icon(Icons.arrow_back_ios_new,color: Colors.black,)),
        title: Text("Settings",style: TextStyle(color: Colors.black,fontFamily: "Inter"),),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.white),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/logo.png",
                    height: isTablet ? 200.h : 100.h,
                    width: isTablet ? 200.w : 100.w,
                  ),
                  Text("PDF Reader",style: TextStyle(fontFamily: "Inter",fontWeight: FontWeight.w700),)
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: drawerItems.length,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return isTablet
                    ? ListTile(
                  leading: Icon(
                    drawerItems[index]['icon'],
                    color: Colors.black,
                    size: isTablet ? 34.sp : 22.sp,
                  ),
                  title: Text(
                    drawerItems[index]['title'],
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: isTablet ? 22.sp : 14.sp,
                    ),
                  ),
                  onTap: drawerItems[index]['onTap'],
                )
                    : CupertinoListTile(
                  leading: Icon(
                    drawerItems[index]['icon'],
                    color: Colors.black,
                    size: 22.sp,
                  ),
                  title: Text(
                    drawerItems[index]['title'],
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 14.sp,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,color: Colors.black,size: 18.sp,),
                  onTap: drawerItems[index]['onTap'],
                );
              },
              separatorBuilder: (BuildContext context, int index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 20),
                child: Divider(),
              ),
            ),
          ),
        ],
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
