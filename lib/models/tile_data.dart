import 'package:flutter/material.dart';

class TileData {
  final String id;
  String title;
  IconData? icon;
  final String? imageUrl;
  final String? pageUrl;
  final String parentId;
  final bool? _isFavorite;
  Color color;
  int gridX;
  int gridY;
  int gridWidth;
  int gridHeight;
  bool get isFavorite => _isFavorite ?? false;
  TileData({
    required this.id,
    required this.title,
    this.icon,
    this.imageUrl,
    this.pageUrl,
    this.parentId = "0",
    bool? isFavorite,
    required this.color,
    required this.gridX,
    required this.gridY,
    this.gridWidth = 1,
    this.gridHeight = 1,
  }) : _isFavorite = isFavorite;
  Rect get gridRect => Rect.fromLTWH(
    gridX.toDouble(),
    gridY.toDouble(),
    gridWidth.toDouble(),
    gridHeight.toDouble(),
  );
  bool overlaps(TileData other) {
    if (id == other.id) return false;
    return gridRect.overlaps(other.gridRect);
  }

  TileData copyWith({
    String? id,
    String? title,
    IconData? icon,
    String? imageUrl,
    String? pageUrl,
    String? parentId,
    bool? isFavorite,
    Color? color,
    int? gridX,
    int? gridY,
    int? gridWidth,
    int? gridHeight,
  }) {
    return TileData(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      pageUrl: pageUrl ?? this.pageUrl,
      parentId: parentId ?? this.parentId,
      isFavorite: isFavorite ?? _isFavorite,
      color: color ?? this.color,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
    );
  }
}
