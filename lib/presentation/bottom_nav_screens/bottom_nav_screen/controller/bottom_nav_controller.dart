// providers/bottom_nav_provider.dart
import 'package:flutter/material.dart';

class BottomNavProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void navigateToBottomscreen(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
