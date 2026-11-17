import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

///App Drawer

Future<void> shareURL(BuildContext context) async {
  final Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.softscrown.pdfreader');
  try {
    // canLaunch() returns false on Android 11+ unless the app declares the
    // intent in <queries>, so the link never opened. launchUrl reports
    // failure itself.
    final bool opened =
        await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url'),duration: Duration(milliseconds: 150)),
      );

    }
  } catch (e) {
    debugPrint('Error launching URL: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred while launching the URL'),duration: Duration(milliseconds: 150)),
    );
  }
}

Future<void> privacypolicyURL(BuildContext context) async {
  final Uri url = Uri.parse('https://scrowns.com/Privacy-Policy');
  try {

    await launchUrl(url, mode: LaunchMode.externalApplication);

  } catch (e) {
    debugPrint('Error launching URL: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred while launching the URL'),duration: Duration(milliseconds: 150)),
    );
  }
}

final InAppReview _inAppReview = InAppReview.instance;

Future<void> rateApp() async {
  try {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      return;
    }
  } catch (e) {
    debugPrint('In-app review failed: $e');
  }
  try {
    // Open the app's page on the store
    await _inAppReview.openStoreListing(
      appStoreId: 'your_ios_app_id', // For iOS
      microsoftStoreId: 'your_microsoft_store_id', // For Microsoft Store
    );
  } catch (e) {
    debugPrint('Could not open store listing: $e');
  }
}