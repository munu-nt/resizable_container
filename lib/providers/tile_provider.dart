import 'package:flutter/foundation.dart';
import '../models/tile_data.dart';
import '../utils/data_loader.dart';

class TileProvider extends ChangeNotifier {
  List<TileData> _allTiles = [];
  List<TileData> _displayedTiles = [];
  bool _isLoading = false;
  String? _error;
  List<TileData> get allTiles => _allTiles;
  List<TileData> get displayedTiles => _displayedTiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Future<void> loadTiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allTiles = await DataLoader.loadTiles();
      _displayedTiles = _allTiles.where((t) => t.parentId == "0").toList();
      for (int i = 0; i < _displayedTiles.length; i++) {
        _displayedTiles[i] = _displayedTiles[i].copyWith(
          gridX: i % 3,
          gridY: i ~/ 3,
          gridWidth: 1,
          gridHeight: 1,
        );
      }
    } catch (e) {
      _error = 'Failed to load tiles: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateTile(TileData tile) {
    final index = _allTiles.indexWhere((t) => t.id == tile.id);
    if (index != -1) {
      _allTiles[index] = tile;
    }
    final displayIndex = _displayedTiles.indexWhere((t) => t.id == tile.id);
    if (displayIndex != -1) {
      _displayedTiles[displayIndex] = tile;
    }
    notifyListeners();
  }

  void updateTiles(List<TileData> tiles) {
    for (var tile in tiles) {
      final index = _allTiles.indexWhere((t) => t.id == tile.id);
      if (index != -1) {
        _allTiles[index] = tile;
      }
      final displayIndex = _displayedTiles.indexWhere((t) => t.id == tile.id);
      if (displayIndex != -1) {
        _displayedTiles[displayIndex] = tile;
      }
    }
    notifyListeners();
  }

  TileData? getTileById(String id) {
    try {
      return _allTiles.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TileData> getChildTiles(String parentId) {
    final children = _allTiles.where((t) => t.parentId == parentId).toList();
    for (int i = 0; i < children.length; i++) {
      children[i] = children[i].copyWith(
        gridX: i % 3,
        gridY: i ~/ 3,
        gridWidth: 1,
        gridHeight: 1,
      );
    }
    return children;
  }

  Future<void> refreshTiles() async {
    await loadTiles();
  }

  void setDisplayedTiles(String parentId) {
    if (parentId == "0") {
      _displayedTiles = _allTiles.where((t) => t.parentId == "0").toList();
      for (int i = 0; i < _displayedTiles.length; i++) {
        _displayedTiles[i] = _displayedTiles[i].copyWith(
          gridX: i % 3,
          gridY: i ~/ 3,
          gridWidth: 1,
          gridHeight: 1,
        );
      }
    } else {
      _displayedTiles = getChildTiles(parentId);
    }
    notifyListeners();
  }
}
