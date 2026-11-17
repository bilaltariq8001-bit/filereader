import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'controller/bottom_nav_bar_controllwe.dart';
import 'controller/fab_controller_pr.dart';
import 'conversation_tool/controller.dart';
import 'nav_bar.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';





void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  // MobileAds.instance.initialize();
  runApp(MultiProvider(providers:[
    ChangeNotifierProvider(create: (_) => FloatingButtonProvider()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ChangeNotifierProvider(create: (_) => DocumentConverterProvider()),
  ],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // sizeOf() only depends on the screen size. MediaQuery.of() also
      // depended on the keyboard insets, so the entire app (including
      // GetMaterialApp) rebuilt on every frame of the keyboard animation.
      designSize: MediaQuery.sizeOf(context),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_ , child) {
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          },
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PDF Reader',
            home: const bottom_nav(),
          ),
        );
      },
    );
  }
}




class DocumentScannerView extends StatefulWidget {
  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Scanner'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  size: 50,
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.black),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: () => startScan(DocumentFormat.pdf),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Scan PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.black),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: () => startScan(DocumentFormat.jpeg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Scan JPEG',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            if (_result?.pdf != null) ...[
              Padding(
                padding: const EdgeInsets.only(
                    top: 16, bottom: 8, right: 8, left: 8),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('PDF Document:')),
              ),
              SizedBox(
                height: 300,
                child: PDFView(
                  filePath: _result!.pdf!.uri,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: false,
                ),
              ),
            ],
            if (_result?.images?.isNotEmpty == true) ...[
              Padding(
                padding: const EdgeInsets.only(
                    top: 16, bottom: 8, right: 8, left: 8),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Images [0]:')),
              ),
              SizedBox(
                  height: 400, child: Image.file(File(_result!.images!.first))),
            ],
          ],
        ),
      ),
    );
  }

  void startScan(DocumentFormat format) async {
    try {
      _result = null;
      setState(() {});
      _documentScanner?.close();
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          //documentFormats:,
          mode: ScannerMode.full,
          isGalleryImport: false,
          pageLimit: 1,
        ),
      );
      _result = await _documentScanner?.scanDocument();
      print('result: $_result');
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }
}