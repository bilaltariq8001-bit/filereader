import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../controller.dart';

import '../utilities/constants.dart';


class SpeedDialWidget extends StatelessWidget {
  const SpeedDialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentConverterProvider>();

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: AppConstants.wordColor,
      foregroundColor: Colors.white,
      activeForegroundColor: Colors.white,
      activeBackgroundColor: Colors.red,
      visible: !provider.isConverting,
      overlayOpacity: 0.5,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(AppConstants.pdfIcon, color: Colors.white),
          backgroundColor: AppConstants.pdfColor,
          label: AppConstants.pdfToWord,
          labelStyle: const TextStyle(fontSize: 16),
          onTap: () => provider.pickAndConvertPdfToWord(),
        ),
        SpeedDialChild(
          child: const Icon(AppConstants.wordIcon, color: Colors.white),
          backgroundColor: AppConstants.wordColor,
          label: AppConstants.wordToPdf,
          labelStyle: const TextStyle(fontSize: 16),
          onTap: () => provider.pickAndConvertWordToPdf(),
        ),
        SpeedDialChild(
          child: const Icon(AppConstants.imageIcon, color: Colors.white),
          backgroundColor: AppConstants.imageColor,
          label: AppConstants.imageToPdf,
          labelStyle: const TextStyle(fontSize: 16),
          onTap: () => provider.pickAndConvertImageToPdf(),
        ),
        SpeedDialChild(
          child: const Icon(AppConstants.multipleIcon, color: Colors.white),
          backgroundColor: AppConstants.multipleColor,
          label: AppConstants.multipleImagesToPdf,
          labelStyle: const TextStyle(fontSize: 16),
          onTap: () => provider.pickAndConvertMultipleImagesToPdf(),
        ),
      ],
    );
  }
}