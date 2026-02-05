import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

enum ResizeHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class ResizableTile extends StatefulWidget {
  final String id;
  final String title;
  final IconData? icon;
  final String? imageUrl;
  final bool isFavorite;
  final Color color;
  final double cellWidth;
  final double cellHeight;
  final int gridX;
  final int gridY;
  final int gridWidth;
  final int gridHeight;
  final Function(Offset delta) onDrag;
  final Function() onDragEnd;
  final Function(ResizeHandle handle, Offset delta) onResize;
  final Function(ResizeHandle handle) onResizeEnd;
  final bool isDragging;
  final bool isResizing;
  final bool isEditing;
  final Animation<double>? shakeAnimation;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onToggleFavorite;
  const ResizableTile({
    super.key,
    required this.id,
    required this.title,
    this.icon,
    this.imageUrl,
    this.isFavorite = false,
    required this.color,
    required this.cellWidth,
    required this.cellHeight,
    required this.gridX,
    required this.gridY,
    required this.gridWidth,
    required this.gridHeight,
    required this.onDrag,
    required this.onDragEnd,
    required this.onResize,
    required this.onResizeEnd,
    this.width,
    this.height,
    this.isDragging = false,
    this.isResizing = false,
    this.isEditing = false,
    this.shakeAnimation,
    this.onLongPress,
    this.onTap,
    this.onDoubleTap,
    this.onToggleFavorite,
  });
  final double? width;
  final double? height;
  @override
  State<ResizableTile> createState() => _ResizableTileState();
}

class _ResizableTileState extends State<ResizableTile>
    with SingleTickerProviderStateMixin {
  static const double handleSize = 32.0;
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ResizableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isEditing && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? (widget.gridWidth * widget.cellWidth);
    final height = widget.height ?? (widget.gridHeight * widget.cellHeight);
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildAnimatedTileBody(width - 8, height - 8),
            if (widget.isEditing) _buildResizeHandle(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTileBody(double width, double height) {
    if (widget.shakeAnimation != null && widget.isEditing) {
      return AnimatedBuilder(
        animation: widget.shakeAnimation!,
        builder: (context, child) {
          final angle =
              0.03 * math.sin(widget.shakeAnimation!.value * 2 * math.pi);
          return Transform.rotate(angle: angle, child: child);
        },
        child: _buildTileBody(width, height),
      );
    }
    return _buildTileBody(width, height);
  }

  Widget _buildTileBody(double width, double height) {
    final isActive = widget.isDragging || widget.isResizing;
    final scale = _isPressed ? 0.95 : (isActive ? 1.05 : 1.0);

    // Enhanced shadow on drag (enhancement #14)
    final shadowBlur = widget.isDragging ? 28.0 : (isActive ? 20.0 : 12.0);
    final shadowOffset = widget.isDragging ? 8.0 : 4.0;
    final shadowOpacity = widget.isDragging ? 0.3 : (isActive ? 0.2 : 0.08);

    // Generate gradient colors from base color
    final gradientColors = [
      widget.color,
      HSLColor.fromColor(widget.color)
          .withLightness(
              (HSLColor.fromColor(widget.color).lightness * 0.85).clamp(0.0, 1.0))
          .toColor(),
    ];

    Widget body = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.deepPurple.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.3),
            width: isActive ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowOpacity),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffset),
              spreadRadius: widget.isDragging ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
              // Glassmorphism overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Tile content
              _buildTileContent(),
              if (widget.isEditing)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: widget.onToggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: widget.isFavorite ? Colors.red : Colors.black54,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );


    if (widget.isEditing) {
      return GestureDetector(
        onPanUpdate: (details) => widget.onDrag(details.delta),
        onPanEnd: (_) => widget.onDragEnd(),
        onLongPress: widget.onLongPress,
        child: body,
      );
    } else {
      // Ripple effect with scale on press
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onDoubleTap: widget.onDoubleTap,
            child: body,
          ),
        ),
      );
    }
  }

  Widget _buildTileContent() {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth;
            final tileHeight = constraints.maxHeight;
            final showText = tileHeight > 60;
            final isLargeTile = tileWidth > 150 && tileHeight > 150;
            final isMediumTile = tileWidth > 100 && tileHeight > 100;
            double iconSize;
            if (isLargeTile) {
              iconSize = 48.0;
            } else if (isMediumTile) {
              iconSize = 36.0;
            } else if (showText) {
              iconSize = 32.0;
            } else {
              iconSize = 24.0;
            }
            double fontSize;
            if (isLargeTile) {
              fontSize = 14.0;
            } else if (isMediumTile) {
              fontSize = 13.0;
            } else {
              fontSize = 12.0;
            }
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isLargeTile ? 8.0 : 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: widget.imageUrl != null
                          ? Padding(
                              padding: EdgeInsets.all(isLargeTile ? 8.0 : 4.0),
                              child: Image.network(
                                widget.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Icon(
                                      widget.icon ?? Icons.broken_image,
                                      size: iconSize,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Icon(
                                widget.icon ?? Icons.grid_view,
                                size: iconSize,
                                color: Colors.grey.shade800,
                              ),
                            ),
                    ),
                    if (showText) ...[
                      SizedBox(height: isLargeTile ? 6 : 4),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: isLargeTile ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.isFavorite)
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(Icons.star, color: Colors.amber, size: 16),
          ),
      ],
    );
  }

  Widget _buildResizeHandle() {
    // Pulsing resize handle (enhancement #19)
    return Positioned(
      right: 4,
      bottom: 4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) =>
            widget.onResize(ResizeHandle.bottomRight, details.delta),
        onPanEnd: (_) => widget.onResizeEnd(ResizeHandle.bottomRight),
        child: Container(
          width: handleSize + 12,
          height: handleSize + 12,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.open_in_full,
                size: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
