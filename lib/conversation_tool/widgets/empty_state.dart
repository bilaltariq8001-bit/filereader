import 'package:flutter/material.dart';
import '../utilities/constants.dart';


class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.offline_bolt,
            size: 100,
            color: AppConstants.wordColor,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.appTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.wordColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.noInternet,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.noConversions,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.tapToStart,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}