import 'package:documentreader/search/searchscreen.dart';
import 'package:documentreader/setting/settingscreen.dart';
import 'package:documentreader/tool/tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/bottom_nav_bar_controllwe.dart';
import 'documents/scanner_ui.dart';
import 'home/homescreen.dart';


class bottom_nav extends StatelessWidget {
  const bottom_nav({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    final List<Widget> screens = [
      HomeScreen(),
       ToolScreen(),
      //DocumentScannerPage()
      const SettingScreen(),
    ];

    return Scaffold(
      body: screens[navProvider.currentIndex],
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
