import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  final List<String> _navigationHistory = ['0'];
  String _currentParentId = '0';
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  String get currentParentId => _currentParentId;
  void navigateToTile(String parentId) {
    if (_currentParentId != parentId) {
      _navigationHistory.add(parentId);
      _currentParentId = parentId;
      notifyListeners();
    }
  }

  bool navigateBack() {
    if (canGoBack()) {
      _navigationHistory.removeLast();
      _currentParentId = _navigationHistory.last;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool canGoBack() {
    return _navigationHistory.length > 1;
  }

  void clearHistory() {
    _navigationHistory.clear();
    _navigationHistory.add('0');
    _currentParentId = '0';
    notifyListeners();
  }
}
