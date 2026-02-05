import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tile_data.dart';

class DataLoader {
  static const int _columns = 3;
  static Future<List<TileData>> loadTiles() async {
    try {
      final jsonString = await rootBundle.loadString('data/home-data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> menus = jsonData['Menus'];
      menus.sort(
        (a, b) => (a['SequenceNo'] as int).compareTo(b['SequenceNo'] as int),
      );
      List<TileData> tiles = [];
      int currentX = 0;
      int currentY = 0;
      for (var item in menus) {
        tiles.add(
          TileData(
            id: item['Id'],
            title: item['Name'],
            imageUrl: item['ImageUrl'],
            pageUrl: item['PageUrl'],
            parentId: item['ParentID']?.toString() ?? "0",
            isFavorite: _parseBool(item['IsFavorite']),
            icon: null,
            color: _getColor(tiles.length),
            gridX: currentX,
            gridY: currentY,
            gridWidth: 1,
            gridHeight: 1,
          ),
        );
        currentX++;
        if (currentX >= _columns) {
          currentX = 0;
          currentY++;
        }
      }
      return tiles;
    } catch (e) {
      debugPrint('Error loading tiles: $e');
      return [];
    }
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  static Color _getColor(int index) {
    return Colors.grey.shade200;
  }
}
