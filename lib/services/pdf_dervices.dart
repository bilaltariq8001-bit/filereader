import 'package:flutter/material.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';

class PdfService {
  final BuildContext context;

  PdfService({required this.context});

  // Helper methods
  void _showSnackbar(String message, {
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: "Inter")),
          backgroundColor: backgroundColor,
          duration: duration,
          action: action,
        ),
      );
    }
  }

  void _showError(String message) {
    _showSnackbar(message, backgroundColor: Colors.red);
    print(message);
  }

  /// ============================================
  /// INITIALIZATION & INFO
  /// ============================================

  /// Initialize PDFTron with optional license key
  Future<void> initialize({String licenseKey = ""}) async {
    try {
      await PdftronFlutter.initialize(licenseKey);
      print("PDFTron initialized successfully");
    } catch (e) {
      print("Error initializing PDFTron: $e");
      rethrow;
    }
  }

  /// Get SDK and platform info
  Future<Map<String, String>> getSystemInfo() async {
    try {
      final platformVersion = await PdftronFlutter.platformVersion;
      final sdkVersion = await PdftronFlutter.version;
      return {
        'platform': platformVersion,
        'sdk': sdkVersion,
      };
    } catch (e) {
      _showError('Error getting system info: $e');
      return {};
    }
  }
  Future<String> openDocument(String path, {
    String? password,
    Config? customConfig,
    bool showTip = true,
  }) async {
    await PdftronFlutter.initialize();

    final String filePath = path.startsWith("file://") ? path : "file://$path";

    var config = customConfig ?? Config();

    // Basic settings
    config.multiTabEnabled = true;
    config.showLeadingNavButton = true;
    config.longPressMenuEnabled = true;
    config.showSavedSignatures = true;
    config.pageChangeOnTap = true;
    config.autoSaveEnabled = true;
    config.continuousAnnotationEditing = true;
    config.signaturePhotoPickerEnabled=true;
    config.showSavedSignatures=true;
    config.annotationAuthor=AutofillHints.name;
    config.autoResizeFreeTextEnabled=true;
    config.fitMode=FitModes.fitPage;




    // CRITICAL: These settings prevent toolbar from hiding
    config.hideTopAppNavBar = false;
    config.hideBottomToolbar = false;
    // config.topToolbarEnabled = true;
    // config.bottomToolbarEnabled = true;

    // This might be the key - keep UI visible
    config.pageIndicatorEnabled = true;
    // config.showToolbarsOnAppear = true;

    // Disable fullscreen which can hide toolbars
    config.fullScreenModeEnabled = false;

    // Explicitly set right bar buttons
    config.topAppNavBarRightBar = [
      Buttons.searchButton,
      Buttons.shareButton,
      Buttons.viewControlsButton,
      Buttons.moreItemsButton,
    ];

    await PdftronFlutter.openDocument(filePath, password: password, config: config);

    if (showTip && context.mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          showTextSelectionTip();
        }
      });
    }

    return filePath;
  }
  /// ============================================
  /// DOCUMENT OPERATIONS
  /// ============================================

  /// Open a PDF document
  Future<String> openDocument1(String path, {
    String? password,
    Config? customConfig,
    bool showTip = true,
  }) async {
    await PdftronFlutter.initialize();

    final String filePath = path.startsWith("file://") ? path : "file://$path";

    // var config = customConfig ?? Config()
    //   ..multiTabEnabled = true
    //   ..showLeadingNavButton = true
    //   ..longPressMenuEnabled = true
    //   ..showSavedSignatures=true
    //   ..fullScreenModeEnabled=true
    //   ..pageChangeOnTap=true
    // // ..showAnnotationReplyReviewState = true
    //   ..autoSaveEnabled = true
    //   ..continuousAnnotationEditing = true
    //
    // ..disabledElements = [
    // Buttons.viewControlsButton,
    // Buttons.thumbnailsButton,
    // Buttons.outlineListButton,
    // Buttons.searchButton,
    // ];
    var config = customConfig ?? Config()
      ..multiTabEnabled = true
      ..showLeadingNavButton = true
      ..longPressMenuEnabled = true
      ..showSavedSignatures = true
      ..fullScreenModeEnabled = false
      ..pageChangeOnTap = true
      ..autoSaveEnabled = true
      ..continuousAnnotationEditing = true

    // Disable buttons you don't want
      ..disabledElements = [
        Buttons.viewControlsButton,
        Buttons.thumbnailsButton,
        Buttons.outlineListButton,
        Buttons.searchButton,
      ]


      ..topAppNavBarRightBar = [
        Buttons.shareButton,
        Buttons.signatureToolButton,

        // CustomToolbarItem(
        //   id: "ai_search",
        //   icon: "ic_ai_search",
        //   title: "AI Search",
        // ),
      ];

    await PdftronFlutter.openDocument(filePath, password: password, config: config);


    if (showTip && context.mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          showTextSelectionTip();
        }
      });
    }

    return filePath;
  }

  /// Save current document
  Future<String?> saveDocument() async {
    try {
      final path = await PdftronFlutter.saveDocument();
      _showSnackbar('Document saved successfully');
      return path;
    } catch (e) {
      _showError('Error saving document: $e');
      return null;
    }
  }

  /// Get document path
  Future<String?> getDocumentPath() async {
    try {
      return await PdftronFlutter.getDocumentPath();
    } catch (e) {
      _showError('Error getting document path: $e');
      return null;
    }
  }

  /// ============================================
  /// ANNOTATION MANAGEMENT
  /// ============================================

  /// Import annotations from XFDF
  Future<void> importAnnotations(String xfdfString) async {
    try {
      await PdftronFlutter.importAnnotations(xfdfString);
      _showSnackbar('Annotations imported successfully');
    } catch (e) {
      _showError('Error importing annotations: $e');
    }
  }

  /// Export annotations
  Future<String?> exportAnnotations({List<Annot>? specificAnnotations}) async {
    try {
      return await PdftronFlutter.exportAnnotations(specificAnnotations);
    } catch (e) {
      _showError('Error exporting annotations: $e');
      return null;
    }
  }

  /// Merge annotations
  Future<void> mergeAnnotations(String xfdfString) async {
    try {
      await PdftronFlutter.mergeAnnotations(xfdfString);
      _showSnackbar('Annotations merged successfully');
    } catch (e) {
      _showError('Error merging annotations: $e');
    }
  }

  /// Delete specific annotations
  Future<void> deleteAnnotations(List<Annot> annotations) async {
    try {
      await PdftronFlutter.deleteAnnotations(annotations);
      _showSnackbar('Annotations deleted successfully');
    } catch (e) {
      _showError('Error deleting annotations: $e');
    }
  }

  /// Delete all annotations
  Future<void> deleteAllAnnotations() async {
    try {
      await PdftronFlutter.deleteAllAnnotations();
      _showSnackbar('All annotations deleted');
    } catch (e) {
      _showError('Error deleting all annotations: $e');
    }
  }

  /// Select annotation
  Future<void> selectAnnotation(Annot annotation) async {
    try {
      await PdftronFlutter.selectAnnotation(annotation);
    } catch (e) {
      _showError('Error selecting annotation: $e');
    }
  }

  /// Set annotation properties
  Future<void> setAnnotationProperties(Annot annotation, AnnotProperty properties) async {
    try {
      await PdftronFlutter.setPropertiesForAnnotation(annotation, properties);
      _showSnackbar('Annotation properties updated');
    } catch (e) {
      _showError('Error setting annotation properties: $e');
    }
  }

  /// Get annotations on specific page
  Future<List<Annot>?> getAnnotationsOnPage(int pageNumber) async {
    try {
      return await PdftronFlutter.getAnnotationsOnPage(pageNumber);
    } catch (e) {
      _showError('Error getting annotations: $e');
      return null;
    }
  }

  /// ============================================
  /// PAGE MANAGEMENT
  /// ============================================

  /// Get page count
  Future<int?> getPageCount() async {
    try {
      return await PdftronFlutter.getPageCount();
    } catch (e) {
      _showError('Error getting page count: $e');
      return null;
    }
  }

  /// Get current page
  Future<int?> getCurrentPage() async {
    try {
      return await PdftronFlutter.getCurrentPage();
    } catch (e) {
      _showError('Error getting current page: $e');
      return null;
    }
  }

  /// Set current page
  Future<bool?> setCurrentPage(int pageNumber) async {
    try {
      return await PdftronFlutter.setCurrentPage(pageNumber);
    } catch (e) {
      _showError('Error setting current page: $e');
      return false;
    }
  }

  /// Navigate pages
  Future<void> gotoFirstPage() async {
    try {
      await PdftronFlutter.gotoFirstPage();
    } catch (e) {
      _showError('Error going to first page: $e');
    }
  }

  Future<void> gotoLastPage() async {
    try {
      await PdftronFlutter.gotoLastPage();
    } catch (e) {
      _showError('Error going to last page: $e');
    }
  }

  Future<void> gotoNextPage() async {
    try {
      await PdftronFlutter.gotoNextPage();
    } catch (e) {
      _showError('Error going to next page: $e');
    }
  }

  Future<void> gotoPreviousPage() async {
    try {
      await PdftronFlutter.gotoPreviousPage();
    } catch (e) {
      _showError('Error going to previous page: $e');
    }
  }

  /// Rotate pages
  Future<void> rotateClockwise() async {
    try {
      await PdftronFlutter.rotateClockwise();
      _showSnackbar('Pages rotated clockwise');
    } catch (e) {
      _showError('Error rotating pages: $e');
    }
  }

  Future<void> rotateCounterClockwise() async {
    try {
      await PdftronFlutter.rotateCounterClockwise();
      _showSnackbar('Pages rotated counter-clockwise');
    } catch (e) {
      _showError('Error rotating pages: $e');
    }
  }

  /// Get page crop box
  Future<Rect> getPageCropBox(int pageNumber) async {
    try {
      return await PdftronFlutter.getPageCropBox(pageNumber);
    } catch (e) {
      _showError('Error getting page crop box: $e');
      rethrow;
    }
  }

  /// Get page rotation
  Future<int> getPageRotation(int pageNumber) async {
    try {
      return await PdftronFlutter.getPageRotation(pageNumber);
    } catch (e) {
      _showError('Error getting page rotation: $e');
      rethrow;
    }
  }

  /// ============================================
  /// TOOL & VIEW MODES
  /// ============================================

  /// Set tool mode
  Future<void> setToolMode(String toolMode) async {
    try {
      await PdftronFlutter.setToolMode(toolMode);
      _showSnackbar('Tool mode set to $toolMode');
    } catch (e) {
      _showError('Error setting tool mode: $e');
    }
  }

  /// Enable text selection mode
  Future<void> enableTextSelectionMode() async {
    try {
      await PdftronFlutter.setToolMode(Tools.textSelect);
      _showSnackbar('Text selection mode enabled. Tap text to select.', backgroundColor: Colors.blue);
    } catch (e) {
      _showError('Error enabling text selection: $e');
    }
  }

  /// Commit current tool
  Future<bool?> commitTool() async {
    try {
      return await PdftronFlutter.commitTool();
    } catch (e) {
      _showError('Error committing tool: $e');
      return null;
    }
  }

  /// Set layout mode
  Future<void> setLayoutMode(String layoutMode) async {
    try {
      await PdftronFlutter.setLayoutMode(layoutMode);
      _showSnackbar('Layout mode changed');
    } catch (e) {
      _showError('Error setting layout mode: $e');
    }
  }

  /// Set fit mode
  Future<void> setFitMode(String fitMode) async {
    try {
      await PdftronFlutter.setFitMode(fitMode);
      _showSnackbar('Fit mode changed');
    } catch (e) {
      _showError('Error setting fit mode: $e');
    }
  }

  /// ============================================
  /// SEARCH FUNCTIONS
  /// ============================================

  /// Open search in document
  Future<void> openSearchInDocument() async {
    try {
      await PdftronFlutter.openSearch();
    } catch (e) {
      _showError('Error opening search: $e');
    }
  }

  /// Start search mode
  Future<void> startSearch(String searchString, {bool matchCase = false, bool matchWholeWord = false}) async {
    try {
      await PdftronFlutter.startSearchMode(searchString, matchCase, matchWholeWord);
    } catch (e) {
      _showError('Error starting search: $e');
    }
  }

  /// Exit search mode
  Future<void> exitSearch() async {
    try {
      await PdftronFlutter.exitSearchMode();
    } catch (e) {
      _showError('Error exiting search: $e');
    }
  }

  /// ============================================
  /// ZOOM & SCROLL OPERATIONS
  /// ============================================

  /// Get zoom level
  Future<double?> getZoom() async {
    try {
      return await PdftronFlutter.getZoom();
    } catch (e) {
      _showError('Error getting zoom level: $e');
      return null;
    }
  }

  /// Zoom with center
  Future<void> zoomWithCenter(double zoom, int x, int y) async {
    try {
      await PdftronFlutter.zoomWithCenter(zoom, x, y);
    } catch (e) {
      _showError('Error zooming: $e');
    }
  }

  /// Set zoom limits
  Future<void> setZoomLimits(String mode, double min, double max) async {
    try {
      await PdftronFlutter.setZoomLimits(mode, min, max);
      _showSnackbar('Zoom limits set');
    } catch (e) {
      _showError('Error setting zoom limits: $e');
    }
  }

  /// Get scroll position
  Future<Map?> getScrollPos() async {
    try {
      return await PdftronFlutter.getScrollPos();
    } catch (e) {
      _showError('Error getting scroll position: $e');
      return null;
    }
  }

  /// ============================================
  /// BOOKMARK MANAGEMENT
  /// ============================================

  /// Import bookmarks
  Future<void> importBookmarks(String bookmarkJson) async {
    try {
      await PdftronFlutter.importBookmarkJson(bookmarkJson);
      _showSnackbar('Bookmarks imported');
    } catch (e) {
      _showError('Error importing bookmarks: $e');
    }
  }

  /// Add bookmark
  Future<void> addBookmark(String title, int pageNumber) async {
    try {
      await PdftronFlutter.addBookmark(title, pageNumber);
      _showSnackbar('Bookmark added');
    } catch (e) {
      _showError('Error adding bookmark: $e');
    }
  }

  /// ============================================
  /// UI NAVIGATION
  /// ============================================

  /// Open annotation list
  Future<void> openAnnotationList() async {
    try {
      await PdftronFlutter.openAnnotationList();
    } catch (e) {
      _showError('Error opening annotation list: $e');
    }
  }

  /// Open bookmark list
  Future<void> openBookmarkList() async {
    try {
      await PdftronFlutter.openBookmarkList();
    } catch (e) {
      _showError('Error opening bookmark list: $e');
    }
  }

  /// Open outline list
  Future<void> openOutlineList() async {
    try {
      await PdftronFlutter.openOutlineList();
    } catch (e) {
      _showError('Error opening outline list: $e');
    }
  }

  /// Open thumbnails view
  Future<void> openThumbnailsView() async {
    try {
      await PdftronFlutter.openThumbnailsView();
    } catch (e) {
      _showError('Error opening thumbnails view: $e');
    }
  }

  /// Open crop dialog
  Future<void> openCrop() async {
    try {
      await PdftronFlutter.openCrop();
    } catch (e) {
      _showError('Error opening crop: $e');
    }
  }

  /// Open go-to page view
  Future<void> openGoToPageView() async {
    try {
      await PdftronFlutter.openGoToPageView();
    } catch (e) {
      _showError('Error opening go to page view: $e');
    }
  }

  /// ============================================
  /// UNDO/REDO OPERATIONS
  /// ============================================

  /// Undo
  Future<void> undo() async {
    try {
      await PdftronFlutter.undo();
    } catch (e) {
      _showError('Error undoing: $e');
    }
  }

  /// Redo
  Future<void> redo() async {
    try {
      await PdftronFlutter.redo();
    } catch (e) {
      _showError('Error redoing: $e');
    }
  }

  /// Check if can undo
  Future<bool?> canUndo() async {
    try {
      return await PdftronFlutter.canUndo();
    } catch (e) {
      _showError('Error checking undo: $e');
      return null;
    }
  }

  /// Check if can redo
  Future<bool?> canRedo() async {
    try {
      return await PdftronFlutter.canRedo();
    } catch (e) {
      _showError('Error checking redo: $e');
      return null;
    }
  }

  /// ============================================
  /// EXPORT OPERATIONS
  /// ============================================

  /// Export page as image
  Future<String?> exportAsImage(int pageNumber, int dpi, String format) async {
    try {
      return await PdftronFlutter.exportAsImage(pageNumber, dpi, format);
    } catch (e) {
      _showError('Error exporting as image: $e');
      return null;
    }
  }

  /// Flatten document
  Future<void> flattenDocument(bool formsOnly) async {
    try {
      await PdftronFlutter.flattenAnnotations(formsOnly);
      _showSnackbar('Document flattened');
    } catch (e) {
      _showError('Error flattening document: $e');
    }
  }

  /// ============================================
  /// VIEWER CUSTOMIZATION
  /// ============================================

  /// Set background color
  Future<void> setBackgroundColor(int red, int green, int blue) async {
    try {
      await PdftronFlutter.setBackgroundColor(red, green, blue);
      _showSnackbar('Background color changed');
    } catch (e) {
      _showError('Error setting background color: $e');
    }
  }

  /// Set page color
  Future<void> setDefaultPageColor(int red, int green, int blue) async {
    try {
      await PdftronFlutter.setDefaultPageColor(red, green, blue);
      _showSnackbar('Page color changed');
    } catch (e) {
      _showError('Error setting page color: $e');
    }
  }

  /// Set navigation button icon
  Future<void> setLeadingNavButtonIcon(String iconPath) async {
    try {
      await PdftronFlutter.setLeadingNavButtonIcon(iconPath);
      _showSnackbar('Navigation button icon changed');
    } catch (e) {
      _showError('Error setting nav button icon: $e');
    }
  }

  /// ============================================
  /// ADDITIONAL FEATURES
  /// ============================================

  /// Get visible pages
  Future<List<int>?> getVisiblePages() async {
    try {
      return await PdftronFlutter.getVisiblePages();
    } catch (e) {
      _showError('Error getting visible pages: $e');
      return null;
    }
  }

  /// Get saved signatures
  Future<List<String>?> getSavedSignatures() async {
    try {
      return await PdftronFlutter.getSavedSignatures();
    } catch (e) {
      _showError('Error getting saved signatures: $e');
      return null;
    }
  }

  /// Handle back button (Android)
  Future<bool?> handleBackButton() async {
    try {
      return await PdftronFlutter.handleBackButton();
    } catch (e) {
      _showError('Error handling back button: $e');
      return null;
    }
  }

  /// ============================================
  /// HELPER METHODS
  /// ============================================

  /// Show text selection tip
  void showTextSelectionTip() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '💡 Long-press on text to select and copy',
            style: TextStyle(fontFamily: "Inter"),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: "Got it",
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Show text copy help
  void showTextCopyHelp() {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("How to Copy Text", style: TextStyle(fontFamily: "Inter")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("1. Enable text selection mode first", style: TextStyle(fontFamily: "Inter")),
              const SizedBox(height: 10),
              const Text("2. Long press on text to select", style: TextStyle(fontFamily: "Inter")),
              const SizedBox(height: 10),
              const Text("3. Use the copy button in the toolbar", style: TextStyle(fontFamily: "Inter")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontFamily: "Inter")),
            ),
          ],
        ),
      );
    }
  }

  /// Show text extraction help
  void showTextExtractionHelp() {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Text Extraction Guide", style: TextStyle(fontFamily: "Inter")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpStep("1. Open a PDF document"),
                _buildHelpStep("2. Tap the text selection icon in toolbar"),
                _buildHelpStep("3. Long press on any text to select"),
                _buildHelpStep("4. Adjust selection handles as needed"),
                _buildHelpStep("5. Copy or share the selected text"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: enableTextSelectionMode,
                  child: const Text("Enable Text Selection Mode"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHelpStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: const TextStyle(fontFamily: "Inter")),
    );
  }
}