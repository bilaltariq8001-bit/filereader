import 'package:documentreader/setting/settingscreen.dart';
import 'package:documentreader/tool/tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/bottom_nav_bar_controllwe.dart';
import 'home/homescreen.dart';


// ignore: camel_case_types
class bottom_nav extends StatelessWidget {
  const bottom_nav({super.key});

  // Created once. Rebuilding this list on every tab change used to dispose
  // HomeScreen, so coming back to Home re-requested permissions and
  // re-scanned the whole storage each time.
  static final List<Widget> _screens = [
    HomeScreen(),
    const ToolScreen(),
    //DocumentScannerPage()
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      // IndexedStack keeps each tab's state (scroll position, loaded files).
      body: IndexedStack(
        index: navProvider.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onTap: navProvider.changeIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_rounded),
            label: "Tools",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
