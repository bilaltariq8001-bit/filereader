import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

///App Drawer

Future<void> shareURL(BuildContext context) async {
  const url = 'https://play.google.com/store/apps/details?id=com.softscrown.pdfreader';
  try {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url'),duration: Duration(milliseconds: 150)),
      );

    }
  } catch (e) {
    // Handle unexpected errors
    print('Error launching URL: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred while launching the URL'),duration: Duration(milliseconds: 150)),
    );
  }
}

Future<void> privacypolicyURL(BuildContext context) async {
  final Uri url = Uri.parse('https://scrowns.com/Privacy-Policy');
  try {

    await launchUrl(url);

  } catch (e) {
    print('Error launching URL: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred while launching the URL'),duration: Duration(milliseconds: 150)),
    );
  }
}

final InAppReview _inAppReview = InAppReview.instance;

rateApp() async {
  if (await _inAppReview.isAvailable()) {
    await _inAppReview.requestReview();
  } else {
    // Open the app's page on the store
    await _inAppReview.openStoreListing(
      appStoreId: 'your_ios_app_id', // For iOS
      microsoftStoreId: 'your_microsoft_store_id', // For Microsoft Store
    );
  }
}