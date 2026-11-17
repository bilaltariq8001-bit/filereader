// // import 'package:google_mobile_ads/google_mobile_ads.dart';

// class AdHelper {
//   static void loadOpenAd(Function(AppOpenAd) onAdLoaded) {
//     AppOpenAd.load(
//       adUnitId: 'ca-app-pub-3940256099942544/9257395921', // Test Open App Ad
//       request: AdRequest(),
//       adLoadCallback: AppOpenAdLoadCallback(
//         onAdLoaded: (ad) {
//           onAdLoaded(ad);
//         },
//         onAdFailedToLoad: (error) {
//           print('Open Ad Failed to Load: $error');
//         },
//       ),

//     );
//   }

//   static void loadInterstitialAd(Function(InterstitialAd) onAdLoaded) {
//     InterstitialAd.load(
//       adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test Interstitial Ad
//       request: AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           onAdLoaded(ad);
//         },
//         onAdFailedToLoad: (error) {
//           print('Interstitial Ad Failed to Load: $error');
//         },
//       ),
//     );
//   }

//   static void loadBannerAd(Function(BannerAd) onAdLoaded) {
//     BannerAd bannerAd = BannerAd(
//       size: AdSize.banner,
//       adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner Ad
//       listener: BannerAdListener(),
//       request: AdRequest(),
//     )..load();

//     onAdLoaded(bannerAd);
//   }
// }
