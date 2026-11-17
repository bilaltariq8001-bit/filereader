// providers/floating_button_provider.dart
import 'package:flutter/material.dart';

class FloatingButtonProvider extends ChangeNotifier {
  bool _isPdfOpen = false;
  bool _showFloatingButton = false;
  String _selectedText = '';
  String? _currentFilePath;

  bool get isPdfOpen => _isPdfOpen;
  bool get showFloatingButton => _showFloatingButton;
  String get selectedText => _selectedText;
  String? get currentFilePath => _currentFilePath;

  void setPdfOpen(bool value) {
    _isPdfOpen = value;
    if (!value) {
      _showFloatingButton = false;
      _selectedText = '';
    }
    notifyListeners();
  }

  void showWithText(String text, String filePath) {
    _selectedText = text;
    _currentFilePath = filePath;
    _showFloatingButton = true;
    _isPdfOpen = true;
    notifyListeners();

    // Auto-hide after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (_showFloatingButton) {
        _showFloatingButton = false;
        notifyListeners();
      }
    });
  }

  void hide() {
    _showFloatingButton = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedText = '';
    notifyListeners();
  }
}