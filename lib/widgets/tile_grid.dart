import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/tile_data.dart';
import '../providers/tile_provider.dart';
import '../providers/grid_state_provider.dart';
import '../utils/responsive_utils.dart';
import 'resizable_tile.dart';

class TileGrid extends StatefulWidget {
  final int? columns;
  final int? rows;
  final Function(TileData)? onTileTap;
  const TileGrid({super.key, this.columns, this.rows, this.onTileTap});
  @override
  State<TileGrid> createState() => _TileGridState();
}

class _TileGridState extends State<TileGrid> with TickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  Offset _resizeOffset = Offset.zero;
  double? _currentPixelWidth;
  double? _currentPixelHeight;
  late AnimationController _shakeController;
  late AnimationController _settleController;
  Animation<Offset>? _settleAnim;
  Offset _settleFrom = Offset.zero;
  Offset _settleTo = Offset.zero;
  int _currentColumns = 3;
  double _currentPadding = 16.0;
  static const double _edgeResistance = 0.35;
  static const double _snapThreshold = 0.35;
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  double _applyResistance(double value, double min, double max) {
    if (value < min) return min + (value - min) * _edgeResistance;
    if (value > max) return max + (value - max) * _edgeResistance;
    return value;
  }

  int _snap(double v, double cellSize) {
    final raw = v / cellSize;
    final floorVal = raw.floor();
    final frac = raw - floorVal;
    if (frac > _snapThreshold) return floorVal + 1;
    return floorVal;
  }

  void _enterEditMode() {
    HapticFeedback.heavyImpact();
    context.read<GridStateProvider>().enterEditMode();
    _shakeController.repeat(reverse: true);
  }

  void _exitEditMode() {
    context.read<GridStateProvider>().exitEditMode();
    _shakeController.stop();
    _shakeController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final gridState = context.watch<GridStateProvider>();
    final tileProvider = context.watch<TileProvider>();
    final tiles = tileProvider.displayedTiles;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final newColumns =
            widget.columns ?? ResponsiveUtils.getGridColumns(availableWidth);
        if (newColumns != _currentColumns) {
          _currentColumns = newColumns;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final provider = context.read<TileProvider>();
            final compactedTiles = _compactLayout(provider.displayedTiles);
            provider.updateTiles(compactedTiles);
          });
        }
        _currentPadding = ResponsiveUtils.getGridPadding(availableWidth);
        final cellWidth =
            (availableWidth - (_currentPadding * 2)) / _currentColumns;
        final cellHeight = cellWidth;
        int maxRow = widget.rows ?? 7;
        for (var tile in tiles) {
          maxRow = math.max(maxRow, tile.gridY + tile.gridHeight);
        }
        if (gridState.previewWidth > 0) {
          maxRow = math.max(
            maxRow,
            gridState.previewY + gridState.previewHeight,
          );
        }
        final totalRows = maxRow + 2;
        final totalHeight = totalRows * cellHeight + (_currentPadding * 2);
        final gridWidth = (_currentColumns * cellWidth) + (_currentPadding * 2);
        return Center(
          child: GestureDetector(
            onTap: _exitEditMode,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: gridWidth,
              height: totalHeight,
              child: Padding(
                padding: EdgeInsets.all(_currentPadding),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildGridBackground(cellWidth, cellHeight, totalRows),
                    _buildDropPreview(cellWidth, cellHeight, gridState),
                    ..._buildTiles(cellWidth, cellHeight, tiles, gridState),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDrag(
    TileData tile,
    Offset delta,
    double cellWidth,
    double cellHeight,
  ) {
    final gridState = context.read<GridStateProvider>();
    if (!gridState.isEditMode) return;
    setState(() {
      if (gridState.draggingTileId != tile.id) {
        HapticFeedback.selectionClick();
        gridState.startDrag(tile.id);
      }
      _dragOffset += delta;
      final maxX = (_currentColumns - tile.gridWidth) * cellWidth;
      final maxY = 10000.0;
      final rawX = tile.gridX * cellWidth + _dragOffset.dx;
      final rawY = tile.gridY * cellHeight + _dragOffset.dy;
      final resistX = _applyResistance(rawX, 0, maxX);
      final resistY = _applyResistance(rawY, 0, maxY);
      final centerX = resistX + (tile.gridWidth * cellWidth) / 2;
      final centerY = resistY + (tile.gridHeight * cellHeight) / 2;
      int targetGridX = _snap(centerX, cellWidth);
      int targetGridY = _snap(centerY, cellHeight);
      targetGridX = targetGridX.clamp(0, _currentColumns - tile.gridWidth);
      targetGridY = math.max(0, targetGridY);
      var resolvedPositions = _reflowAround(
        tile.id,
        targetGridX,
        targetGridY,
        tile.gridWidth,
        tile.gridHeight,
      );
      if (resolvedPositions != null) {
        gridState.updatePreview(
          targetGridX,
          targetGridY,
          tile.gridWidth,
          tile.gridHeight,
        );
        gridState.setTemporaryPositions(resolvedPositions);
      }
    });
  }

  Widget _buildGridBackground(
    double cellWidth,
    double cellHeight,
    int totalRows,
  ) {
    final gridState = context.watch<GridStateProvider>();
    return Positioned.fill(
      child: CustomPaint(
        painter: _TileBackgroundPainter(
          columns: _currentColumns,
          rows: totalRows,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          isEditMode: gridState.isEditMode,
        ),
      ),
    );
  }

  Widget _buildDropPreview(
    double cellWidth,
    double cellHeight,
    GridStateProvider gridState,
  ) {
    if (gridState.draggingTileId == null && gridState.resizingTileId == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: gridState.previewX * cellWidth,
      top: gridState.previewY * cellHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: gridState.previewWidth * cellWidth,
        height: gridState.previewHeight * cellHeight,
        decoration: BoxDecoration(
          color:
              _canPlace(
                gridState.previewX,
                gridState.previewY,
                gridState.previewWidth,
                gridState.previewHeight,
                gridState.draggingTileId ?? gridState.resizingTileId,
              )
              ? Colors.white.withOpacity(0.15)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _canPlace(
                  gridState.previewX,
                  gridState.previewY,
                  gridState.previewWidth,
                  gridState.previewHeight,
                  gridState.draggingTileId ?? gridState.resizingTileId,
                )
                ? Colors.white.withOpacity(0.4)
                : Colors.red.withOpacity(0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    double cellWidth,
    double cellHeight,
    List<TileData> tiles,
    GridStateProvider gridState,
  ) {
    return tiles.map((tile) {
      final isDragging = tile.id == gridState.draggingTileId;
      final isResizing = tile.id == gridState.resizingTileId;
      int currentGridX = tile.gridX;
      int currentGridY = tile.gridY;
      if (gridState.temporaryPositions.containsKey(tile.id)) {
        final point = gridState.temporaryPositions[tile.id]!;
        currentGridX = point.x;
        currentGridY = point.y;
      } else if (isResizing) {
        currentGridX = gridState.previewX;
        currentGridY = gridState.previewY;
      }
      double left = currentGridX * cellWidth;
      double top = currentGridY * cellHeight;
      if (isDragging) {
        if (_settleAnim != null && _settleController.isAnimating) {
          final settle = _settleAnim!.value;
          left = tile.gridX * cellWidth + settle.dx;
          top = tile.gridY * cellHeight + settle.dy;
        } else {
          final maxX = (_currentColumns - tile.gridWidth) * cellWidth;
          final maxY = 10000.0;
          final rawX = tile.gridX * cellWidth + _dragOffset.dx;
          final rawY = tile.gridY * cellHeight + _dragOffset.dy;
          final resistX = _applyResistance(rawX, 0, maxX);
          final resistY = _applyResistance(rawY, 0, maxY);
          left = resistX;
          top = resistY;
        }
      }
      return AnimatedPositioned(
        duration:
            isDragging ||
                isResizing ||
                (_settleController.isAnimating && isDragging)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        left: left,
        top: top,
        child: ResizableTile(
          id: tile.id,
          title: tile.title,
          icon: tile.icon,
          imageUrl: tile.imageUrl,
          isFavorite: tile.isFavorite,
          color: tile.color,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          gridX: currentGridX,
          gridY: currentGridY,
          gridWidth: isResizing ? gridState.previewWidth : tile.gridWidth,
          gridHeight: isResizing ? gridState.previewHeight : tile.gridHeight,
          width: isResizing ? _currentPixelWidth : null,
          height: isResizing ? _currentPixelHeight : null,
          isDragging: isDragging,
          isResizing: isResizing,
          onDrag: (delta) => _handleDrag(tile, delta, cellWidth, cellHeight),
          onDragEnd: () => _handleDragEnd(tile, cellWidth, cellHeight),
          onResize: (handle, delta) =>
              _handleResize(tile, handle, delta, cellWidth, cellHeight),
          onResizeEnd: (handle) => _handleResizeEnd(tile),
          isEditing: gridState.isEditMode,
          shakeAnimation: _shakeController,
          onLongPress: _enterEditMode,
          onTap: () {
            if (!gridState.isEditMode && widget.onTileTap != null) {
              widget.onTileTap!(tile);
            }
          },
          onDoubleTap: () => _handleDoubleTap(tile),
        ),
      );
    }).toList();
  }

  void _handleDoubleTap(TileData tile) {
    if (!context.read<GridStateProvider>().isEditMode) return;
    
    HapticFeedback.mediumImpact();
    
    int newWidth = tile.gridWidth;
    int newHeight = tile.gridHeight;

    // Cycle: 1x1 -> 2x1 -> 2x2 -> 1x1
    if (tile.gridWidth == 1 && tile.gridHeight == 1) {
      newWidth = 2;
      newHeight = 1;
    } else if (tile.gridWidth == 2 && tile.gridHeight == 1) {
      newWidth = 2;
      newHeight = 2;
    } else {
      newWidth = 1;
      newHeight = 1;
    }

    // Clamp to grid columns
    if (tile.gridX + newWidth > _currentColumns) {
       // If it doesn't fit horizontally due to edge, try to find a valid size or reset
       if (newWidth > 1) {
          // If 2x1 or 2x2 doesn't fit, go back to 1x1
          newWidth = 1;
          newHeight = 1;
       }
    }
    
    // Attempt to reflow/place
    _commitResize(tile, newWidth, newHeight);
  }

  void _commitResize(TileData tile, int newWidth, int newHeight) {
    final tileProvider = context.read<TileProvider>();
    final tiles = tileProvider.displayedTiles;
    
    // Simple check if we can place it directly or if we need to reflow
    // reusing the logic from _handleResize but simplified for immediate commit
    
    // We try to find a spot or push others
    var resolvedPositions = _reflowAround(
       tile.id,
       tile.gridX,
       tile.gridY,
       newWidth,
       newHeight,
    );
     
    if (resolvedPositions != null) {
      List<TileData> updatedTiles = tiles.map((t) {
        if (t.id == tile.id) {
          return t.copyWith(
            gridWidth: newWidth,
            gridHeight: newHeight,
          );
        }
        if (resolvedPositions.containsKey(t.id)) {
          var p = resolvedPositions[t.id]!;
          return t.copyWith(gridX: p.x, gridY: p.y);
        }
        return t;
      }).toList();
      
      updatedTiles = _compactLayout(updatedTiles);
      tileProvider.updateTiles(updatedTiles);
    } else {
        // If it fails to resize (e.g. no space), maybe shake or error feedback?
        HapticFeedback.vibrate();
    }
  }

  void _handleDragEnd(TileData tile, double cellWidth, double cellHeight) {
    final gridState = context.read<GridStateProvider>();
    if (!gridState.isEditMode) return;
    final maxX = (_currentColumns - tile.gridWidth) * cellWidth;
    final maxY = 10000.0;
    final rawX = tile.gridX * cellWidth + _dragOffset.dx;
    final rawY = tile.gridY * cellHeight + _dragOffset.dy;
    final fromX = _applyResistance(rawX, 0, maxX);
    final fromY = _applyResistance(rawY, 0, maxY);
    final settleFrom = Offset(
      fromX - (tile.gridX * cellWidth),
      fromY - (tile.gridY * cellHeight),
    );
    final settleTo = Offset(
      (gridState.previewX - tile.gridX) * cellWidth,
      (gridState.previewY - tile.gridY) * cellHeight,
    );
    _settleFrom = settleFrom;
    _settleTo = settleTo;
    _settleAnim = Tween<Offset>(begin: _settleFrom, end: _settleTo).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutBack),
    );
    _settleController.forward(from: 0).whenComplete(() {
      _commitDrag(tile);
    });
    setState(() {});
  }

  void _commitDrag(TileData tile) {
    HapticFeedback.mediumImpact();
    final tileProvider = context.read<TileProvider>();
    final gridState = context.read<GridStateProvider>();
    final tiles = tileProvider.displayedTiles;
    List<TileData> updatedTiles = [];
    bool changed = false;
    if (gridState.temporaryPositions.isNotEmpty) {
      updatedTiles = tiles.map((t) {
        if (t.id == tile.id) {
          return t.copyWith(
            gridX: gridState.previewX,
            gridY: gridState.previewY,
          );
        }
        if (gridState.temporaryPositions.containsKey(t.id)) {
          var p = gridState.temporaryPositions[t.id]!;
          return t.copyWith(gridX: p.x, gridY: p.y);
        }
        return t;
      }).toList();
      changed = true;
    } else if (_canPlace(
      gridState.previewX,
      gridState.previewY,
      gridState.previewWidth,
      gridState.previewHeight,
      tile.id,
    )) {
      updatedTiles = tiles.map((t) {
        if (t.id == tile.id) {
          return t.copyWith(
            gridX: gridState.previewX,
            gridY: gridState.previewY,
          );
        }
        return t;
      }).toList();
      changed = true;
    }
    if (changed) {
      updatedTiles = _compactLayout(updatedTiles);
      tileProvider.updateTiles(updatedTiles);
    }
    setState(() {
      gridState.endDrag();
      _dragOffset = Offset.zero;
      _settleAnim = null;
    });
  }

  Map<String, math.Point<int>>? _reflowAround(
    String activeTileId,
    int activeX,
    int activeY,
    int activeW,
    int activeH,
  ) {
    final tiles = context.read<TileProvider>().displayedTiles;
    if (activeX < 0 || activeY < 0) return null;
    if (activeX + activeW > _currentColumns) return null;
    var otherTiles = tiles.where((t) => t.id != activeTileId).toList();
    otherTiles.sort((a, b) {
      if (a.gridY != b.gridY) return a.gridY.compareTo(b.gridY);
      return a.gridX.compareTo(b.gridX);
    });
    Map<String, math.Point<int>> newPositions = {};
    List<Rect> occupiedRects = [];
    occupiedRects.add(
      Rect.fromLTWH(
        activeX.toDouble(),
        activeY.toDouble(),
        activeW.toDouble(),
        activeH.toDouble(),
      ),
    );
    for (var tile in otherTiles) {
      int y = 0;
      bool placed = false;
      while (!placed) {
        for (int x = 0; x < _currentColumns; x++) {
          if (x + tile.gridWidth > _currentColumns) continue;
          final candidateRect = Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            tile.gridWidth.toDouble(),
            tile.gridHeight.toDouble(),
          );
          bool overlaps = false;
          for (var rect in occupiedRects) {
            if (candidateRect.overlaps(rect)) {
              overlaps = true;
              break;
            }
          }
          if (!overlaps) {
            newPositions[tile.id] = math.Point(x, y);
            occupiedRects.add(candidateRect);
            placed = true;
            break;
          }
        }
        if (placed) break;
        y++;
      }
    }
    return newPositions;
  }

  void _handleResize(
    TileData tile,
    ResizeHandle handle,
    Offset delta,
    double cellWidth,
    double cellHeight,
  ) {
    final gridState = context.read<GridStateProvider>();
    if (!gridState.isEditMode) return;
    setState(() {
      if (gridState.resizingTileId != tile.id) {
        HapticFeedback.selectionClick();
        gridState.startResize(tile.id);
      }
      _resizeOffset += delta;
      double rawWidth = (tile.gridWidth * cellWidth) + _resizeOffset.dx;
      double rawHeight = (tile.gridHeight * cellHeight) + _resizeOffset.dy;
      double maxWidth = (_currentColumns - tile.gridX) * cellWidth;
      double maxAllowedWidth = math.min(maxWidth, 3 * cellWidth);
      double maxAllowedHeight = 3 * cellHeight;
      _currentPixelWidth = rawWidth.clamp(cellWidth * 0.5, maxAllowedWidth);
      _currentPixelHeight = rawHeight.clamp(cellHeight * 0.5, maxAllowedHeight);
      int newWidth = (_currentPixelWidth! / cellWidth).round();
      if (newWidth < 1) newWidth = 1;
      int newHeight = (_currentPixelHeight! / cellHeight).round();
      if (newHeight < 1) newHeight = 1;
      newWidth = newWidth.clamp(1, math.min(3, _currentColumns - tile.gridX));
      newHeight = newHeight.clamp(1, 3);
      if (newWidth != gridState.previewWidth ||
          newHeight != gridState.previewHeight ||
          gridState.temporaryPositions.isEmpty) {
        var resolvedPositions = _reflowAround(
          tile.id,
          tile.gridX,
          tile.gridY,
          newWidth,
          newHeight,
        );
        if (resolvedPositions != null) {
          gridState.updatePreview(tile.gridX, tile.gridY, newWidth, newHeight);
          gridState.setTemporaryPositions(resolvedPositions);
        }
      }
    });
  }

  void _handleResizeEnd(TileData tile) {
    HapticFeedback.mediumImpact();
    final tileProvider = context.read<TileProvider>();
    final gridState = context.read<GridStateProvider>();
    final tiles = tileProvider.displayedTiles;
    if (!gridState.isEditMode) return;
    List<TileData> updatedTiles = [];
    bool changed = false;
    if (gridState.temporaryPositions.isNotEmpty) {
      updatedTiles = tiles.map((t) {
        if (t.id == tile.id) {
          return t.copyWith(
            gridX: gridState.previewX,
            gridY: gridState.previewY,
            gridWidth: gridState.previewWidth,
            gridHeight: gridState.previewHeight,
          );
        }
        if (gridState.temporaryPositions.containsKey(t.id)) {
          var p = gridState.temporaryPositions[t.id]!;
          return t.copyWith(gridX: p.x, gridY: p.y);
        }
        return t;
      }).toList();
      changed = true;
    } else if (_canPlace(
      gridState.previewX,
      gridState.previewY,
      gridState.previewWidth,
      gridState.previewHeight,
      tile.id,
    )) {
      updatedTiles = tiles.map((t) {
        if (t.id == tile.id) {
          return t.copyWith(
            gridX: gridState.previewX,
            gridY: gridState.previewY,
            gridWidth: gridState.previewWidth,
            gridHeight: gridState.previewHeight,
          );
        }
        return t;
      }).toList();
      changed = true;
    }
    if (changed) {
      updatedTiles = _compactLayout(updatedTiles);
      tileProvider.updateTiles(updatedTiles);
    }
    setState(() {
      gridState.endResize();
      _resizeOffset = Offset.zero;
      _currentPixelWidth = null;
      _currentPixelHeight = null;
    });
  }

  List<TileData> _compactLayout(List<TileData> inputTiles) {
    var sortedTiles = List<TileData>.from(inputTiles);
    sortedTiles.sort((a, b) {
      if (a.gridY != b.gridY) return a.gridY.compareTo(b.gridY);
      return a.gridX.compareTo(b.gridX);
    });
    List<TileData> placedTiles = [];
    for (var tile in sortedTiles) {
      int y = 0;
      bool placed = false;
      while (!placed) {
        for (int x = 0; x < _currentColumns; x++) {
          if (x + tile.gridWidth > _currentColumns) continue;
          bool overlaps = false;
          final candidateRect = Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            tile.gridWidth.toDouble(),
            tile.gridHeight.toDouble(),
          );
          for (var placedTile in placedTiles) {
            if (candidateRect.overlaps(placedTile.gridRect)) {
              overlaps = true;
              break;
            }
          }
          if (!overlaps) {
            placedTiles.add(tile.copyWith(gridX: x, gridY: y));
            placed = true;
            break;
          }
        }
        if (placed) break;
        y++;
      }
    }
    return placedTiles;
  }

  bool _canPlace(int x, int y, int width, int height, String? excludeTileId) {
    final tiles = context.read<TileProvider>().displayedTiles;
    if (x < 0 || y < 0) return false;
    if (x + width > _currentColumns) return false;
    final testRect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    for (final tile in tiles) {
      if (tile.id == excludeTileId) continue;
      if (testRect.overlaps(tile.gridRect)) return false;
    }
    return true;
  }
}

class _TileBackgroundPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;
  final bool isEditMode;

  _TileBackgroundPainter({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.isEditMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEditMode) return;

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const double dotSize = 4.0;

    for (int i = 0; i <= columns; i++) {
        for (int j = 0; j <= rows; j++) {
            final double x = i * cellWidth;
            final double y = j * cellHeight;
            canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _TileBackgroundPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight ||
        oldDelegate.isEditMode != isEditMode;
  }
}
