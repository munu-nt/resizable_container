import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class GridStateProvider extends ChangeNotifier {
  bool _isEditMode = false;
  String? _draggingTileId;
  String? _resizingTileId;
  int _previewX = 0;
  int _previewY = 0;
  int _previewWidth = 1;
  int _previewHeight = 1;
  Map<String, math.Point<int>> _temporaryPositions = {};
  bool get isEditMode => _isEditMode;
  String? get draggingTileId => _draggingTileId;
  String? get resizingTileId => _resizingTileId;
  int get previewX => _previewX;
  int get previewY => _previewY;
  int get previewWidth => _previewWidth;
  int get previewHeight => _previewHeight;
  Map<String, math.Point<int>> get temporaryPositions => _temporaryPositions;
  void enterEditMode() {
    _isEditMode = true;
    notifyListeners();
  }

  void exitEditMode() {
    _isEditMode = false;
    clearInteractionState();
    notifyListeners();
  }

  void startDrag(String tileId) {
    _draggingTileId = tileId;
    notifyListeners();
  }

  void endDrag() {
    _draggingTileId = null;
    _temporaryPositions.clear();
    notifyListeners();
  }

  void startResize(String tileId) {
    _resizingTileId = tileId;
    notifyListeners();
  }

  void endResize() {
    _resizingTileId = null;
    _temporaryPositions.clear();
    notifyListeners();
  }

  void updatePreview(int x, int y, int width, int height) {
    _previewX = x;
    _previewY = y;
    _previewWidth = width;
    _previewHeight = height;
    notifyListeners();
  }

  void setTemporaryPositions(Map<String, math.Point<int>> positions) {
    _temporaryPositions = positions;
    notifyListeners();
  }

  void clearInteractionState() {
    _draggingTileId = null;
    _resizingTileId = null;
    _temporaryPositions.clear();
  }
}
