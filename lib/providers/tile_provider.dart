import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tile_data.dart';
import '../utils/data_loader.dart';

class TileProvider extends ChangeNotifier {
  static const String _positionsKey = 'tile_positions';

  List<TileData> _allTiles = [];
  List<TileData> _displayedTiles = [];
  bool _isLoading = false;
  String? _error;
  List<TileData> get allTiles => _allTiles;
  List<TileData> get displayedTiles => _displayedTiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void toggleFavorite(String tileId) {
    final displayIndex = _displayedTiles.indexWhere((t) => t.id == tileId);
    if (displayIndex != -1) {
      final tile = _displayedTiles[displayIndex];
      _displayedTiles[displayIndex] = tile.copyWith(isFavorite: !tile.isFavorite);
    }
    final allIndex = _allTiles.indexWhere((t) => t.id == tileId);
    if (allIndex != -1) {
      final tile = _allTiles[allIndex];
      _allTiles[allIndex] = tile.copyWith(isFavorite: !tile.isFavorite);
    }
    notifyListeners();
  }

  Future<void> loadTiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allTiles = await DataLoader.loadTiles();
      _displayedTiles = _allTiles.where((t) => t.parentId == "0").toList();

      // Try to load saved positions
      final savedPositions = await _loadSavedPositions();
      if (savedPositions != null) {
        _applySavedPositions(savedPositions);
      } else {
        // Default grid layout
        for (int i = 0; i < _displayedTiles.length; i++) {
          _displayedTiles[i] = _displayedTiles[i].copyWith(
            gridX: i % 3,
            gridY: i ~/ 3,
            gridWidth: 1,
            gridHeight: 1,
          );
        }
      }
    } catch (e) {
      _error = 'Failed to load tiles: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _loadSavedPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_positionsKey);
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to load saved positions: $e');
    }
    return null;
  }

  void _applySavedPositions(Map<String, dynamic> positions) {
    for (int i = 0; i < _displayedTiles.length; i++) {
      final tile = _displayedTiles[i];
      final savedPos = positions[tile.id];
      if (savedPos != null && savedPos is Map<String, dynamic>) {
        _displayedTiles[i] = tile.copyWith(
          gridX: savedPos['gridX'] ?? i % 3,
          gridY: savedPos['gridY'] ?? i ~/ 3,
          gridWidth: savedPos['gridWidth'] ?? 1,
          gridHeight: savedPos['gridHeight'] ?? 1,
        );
      } else {
        // Default position if not saved
        _displayedTiles[i] = tile.copyWith(
          gridX: i % 3,
          gridY: i ~/ 3,
          gridWidth: 1,
          gridHeight: 1,
        );
      }
    }
  }

  Future<void> _saveTilePositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positions = <String, dynamic>{};
      for (final tile in _displayedTiles) {
        positions[tile.id] = {
          'gridX': tile.gridX,
          'gridY': tile.gridY,
          'gridWidth': tile.gridWidth,
          'gridHeight': tile.gridHeight,
        };
      }
      await prefs.setString(_positionsKey, jsonEncode(positions));
    } catch (e) {
      debugPrint('Failed to save tile positions: $e');
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
    _saveTilePositions();
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
    _saveTilePositions();
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
