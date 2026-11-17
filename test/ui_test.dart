import 'dart:io';

import 'package:documentreader/controller/bottom_nav_bar_controllwe.dart';
import 'package:documentreader/controller/fab_controller_pr.dart';
import 'package:documentreader/conversation_tool/controller.dart';
import 'package:documentreader/main.dart';
import 'package:documentreader/services/bookmark_service.dart';
import 'package:documentreader/services/file_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real app shell through its navigation paths.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory docs;

  setUpAll(() async {
    // Use the app's real font so text measures like on a device (the test
    // default font draws every glyph as a wide square).
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.sublistView(
          File('assets/fonts/Inter.ttf').readAsBytesSync())));
    await loader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BookmarkService().resetForTest();
    docs = Directory.systemTemp.createTempSync('docs');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docs.path,
    );
  });

  tearDown(() => docs.deleteSync(recursive: true));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => FloatingButtonProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => DocumentConverterProvider()),
    ], child: const MyApp()));
    // Let the background storage scan (a real isolate) finish.
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  // The empty-state Lottie animation loops forever, so pumpAndSettle()
  // never settles; pump through transitions instead.
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder backArrow() => find.byIcon(Icons.arrow_back_ios_new);

  testWidgets('home loads and tabs keep working', (tester) async {
    await pumpApp(tester);
    expect(find.text('PDF Reader'), findsWidgets);
    expect(find.text('No file found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Tools'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Document Converter'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Privacy Policy'), findsOneWidget);

    // Back on the Settings tab used to pop the only route (black screen).
    await tester.tap(backArrow());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No file found'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('bookmarks, multi-select and search return to the app',
      (tester) async {
    await pumpApp(tester);

    Future<void> openAndBack(String iconAsset, Finder expected) async {
      final button = find.byWidgetPredicate((w) =>
          w is InkWell &&
          w.child.toString().contains(iconAsset));
      await tester.tap(button);
      await settle(tester);
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(expected, findsOneWidget);
      await tester.tap(backArrow().first);
      await settle(tester);
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
      // Back used to rebuild a bare HomeScreen without the bottom bar.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('No file found'), findsOneWidget);
    }

    await openAndBack('bookmark.svg', find.text('No bookmarks found'));
    await openAndBack('select.svg', find.text('0 Selected'));
    await openAndBack('search.svg', find.text('No files found'));
  });

  testWidgets('Text to Word creates a document and reports success',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Tools'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Text to Word'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Hello from the test');
    await tester.tap(find.text('Convert'));
    // File writes are real I/O; let them complete between frames.
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Conversion Successful'), findsOneWidget);
    final created = docs.listSync().whereType<File>().toList();
    expect(created.single.path, endsWith('.docx'));

    // Close the sheet; the history entry is listed.
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(find.text('Recent Conversions'), findsOneWidget);
  });

  testWidgets('Text to Word with empty text shows a message, not a crash',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Tools'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Text to Word'));
    await settle(tester);
    await tester.tap(find.text('Convert'));
    await tester.pump();
    expect(find.text('Please enter some text first'), findsOneWidget);
  });

  group('with documents on storage', () {
    late Directory storage;

    setUp(() {
      storage = Directory.systemTemp.createTempSync('storage');
      Directory('${storage.path}/Download').createSync();
      File('${storage.path}/Download/report.pdf').writeAsStringSync('%PDF-1.4');
      File('${storage.path}/Download/letter.docx').writeAsStringSync('x');
      File('${storage.path}/sheet.xlsx').writeAsStringSync('x');
      FileService.storageRoot = storage.path;
    });

    tearDown(() => storage.deleteSync(recursive: true));

    Future<void> io(WidgetTester tester, [int rounds = 6]) async {
      for (int i = 0; i < rounds; i++) {
        await tester.runAsync(
            () => Future.delayed(const Duration(milliseconds: 80)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('lists files per tab and bookmarks them', (tester) async {
      await pumpApp(tester);
      await io(tester);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('letter.docx'), findsOneWidget);
      expect(find.text('sheet.xlsx'), findsOneWidget);

      await tester.tap(find.text('Word'));
      await io(tester, 6);
      expect(find.text('letter.docx'), findsWidgets);
      await tester.tap(find.text('All'));
      await io(tester, 6);

      final bookmarkIcon = find.descendant(
          of: find.ancestor(
              of: find.text('report.pdf'), matching: find.byType(Row)).last,
          matching: find.byIcon(Icons.bookmark_border));
      await tester.tap(bookmarkIcon.first);
      await io(tester, 3);
      expect(find.text('Bookmark added'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      // Toggling again removes it (it used to add a duplicate).
      await tester.tap(find.byIcon(Icons.bookmark));
      await io(tester, 8);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('bottom sheet opens and rename works', (tester) async {
      await pumpApp(tester);
      await io(tester);

      final more = find.byIcon(Icons.more_vert);
      await tester.tap(more.first);
      await io(tester, 4);
      // The sheet header used to try to draw a PNG as SVG.
      expect(tester.takeException(), isNull);
      expect(find.text('Rename'), findsOneWidget);

      await tester.tap(find.text('Rename'));
      await io(tester, 4);
      final field = find.byType(TextField);
      final String oldName =
          tester.widget<TextField>(field).controller!.text;
      await tester.enterText(field, '${oldName}_renamed');
      await tester.tap(find.text('OK'));
      await io(tester, 6);
      expect(find.text('File renamed successfully'), findsOneWidget);
      expect(
          storage
              .listSync(recursive: true)
              .any((e) => e.path.contains('${oldName}_renamed')),
          isTrue);
    });

    testWidgets('delete removes the file and Undo restores it',
        (tester) async {
      await pumpApp(tester);
      await io(tester);
      final pdf = File('${storage.path}/Download/report.pdf');

      final Finder row = find
          .ancestor(of: find.text('report.pdf'), matching: find.byType(Row))
          .last;
      await tester.tap(
          find.descendant(of: row, matching: find.byIcon(Icons.more_vert)));
      await io(tester, 4);
      await tester.tap(find.text('Delete').last);
      await io(tester, 4);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await io(tester, 4);
      expect(pdf.existsSync(), isFalse);
      expect(find.text('report.pdf'), findsNothing);

      await tester.tap(find.text('Undo'));
      await io(tester, 8);
      expect(pdf.readAsStringSync(), '%PDF-1.4');
      expect(find.text('report.pdf'), findsOneWidget);
    });

    testWidgets('bookmark screen and search work with real files',
        (tester) async {
      await pumpApp(tester);
      await io(tester);

      final Finder row = find
          .ancestor(of: find.text('letter.docx'), matching: find.byType(Row))
          .last;
      await tester.tap(
          find.descendant(of: row, matching: find.byIcon(Icons.bookmark_border)));
      await io(tester, 4);

      Finder appBarButton(String asset) => find.byWidgetPredicate(
          (w) => w is InkWell && w.child.toString().contains(asset));

      await tester.tap(appBarButton('bookmark.svg'));
      await io(tester, 8);
      expect(find.text('letter.docx'), findsWidgets);
      expect(find.text('report.pdf'), findsNothing);

      // Search inside bookmarks, then go back.
      await tester.tap(appBarButton('search.svg').last);
      await io(tester, 6);
      await tester.enterText(find.byType(TextField), 'zzz');
      await io(tester, 2);
      expect(find.text('No files found'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'lett');
      await io(tester, 2);
      expect(find.text('letter.docx'), findsWidgets);
      await tester.tap(backArrow().last);
      await io(tester, 6);

      // Back from bookmarks to the app with its bottom bar.
      await tester.tap(backArrow().last);
      await io(tester, 6);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });
  });
}
