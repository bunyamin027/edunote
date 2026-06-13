import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../engine/coordinate_mapper.dart';
import '../engine/pdf_tile_renderer.dart';
import '../engine/tile_cache.dart';

/// Renders a single page of the PDF using tiled rendering.
class PdfPageLayer extends StatefulWidget {
  final int pageIndex;
  final Size pageSize;
  final Rect visibleRect;
  final double scale;
  final CoordinateMapper coordinateMapper;
  final PdfTileRenderer renderer;
  final TileCache cache;

  const PdfPageLayer({
    super.key,
    required this.pageIndex,
    required this.pageSize,
    required this.visibleRect,
    required this.scale,
    required this.coordinateMapper,
    required this.renderer,
    required this.cache,
  });

  @override
  State<PdfPageLayer> createState() => _PdfPageLayerState();
}

class _PdfPageLayerState extends State<PdfPageLayer> {
  // Tile dimension in logical pixels (unscaled PDF points)
  static const double _baseTileSize = 256.0;
  final Map<TileKey, bool> _fetchingTiles = {};

  void _requestTile(TileKey key, Rect tileRect, double width, double height) async {
    if (_fetchingTiles[key] == true) return;
    _fetchingTiles[key] = true;
    
    // Convert unscaled PDF width/height to scaled pixels for rendering
    final int pixelWidth = (width * widget.scale).ceil();
    final int pixelHeight = (height * widget.scale).ceil();

    final image = await widget.renderer.renderTile(
      pageIndex: widget.pageIndex,
      tileRect: tileRect,
      scale: widget.scale,
      width: pixelWidth,
      height: pixelHeight,
    );

    if (!mounted) {
      image?.dispose();
      return;
    }
    
    if (image != null) {
      widget.cache.put(key, image);
      setState(() {
        _fetchingTiles.remove(key);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visibleRect.overlaps(Offset.zero & widget.pageSize)) {
      return const SizedBox.shrink();
    }

    // Determine which tiles intersect the visible rect
    final int startCol = max(0, (widget.visibleRect.left / _baseTileSize).floor());
    final int endCol = min(
      ((widget.pageSize.width) / _baseTileSize).ceil() - 1,
      (widget.visibleRect.right / _baseTileSize).floor(),
    );
    
    final int startRow = max(0, (widget.visibleRect.top / _baseTileSize).floor());
    final int endRow = min(
      ((widget.pageSize.height) / _baseTileSize).ceil() - 1,
      (widget.visibleRect.bottom / _baseTileSize).floor(),
    );

    final List<Widget> tileWidgets = [];

    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final double left = col * _baseTileSize;
        final double top = row * _baseTileSize;
        final double width = min(_baseTileSize, widget.pageSize.width - left);
        final double height = min(_baseTileSize, widget.pageSize.height - top);
        
        final Rect tileRect = Rect.fromLTWH(left, top, width, height);
        final TileKey key = TileKey(widget.pageIndex, col, row, widget.scale);
        
        final ui.Image? cachedImage = widget.cache.get(key);
        
        Widget tileContent;
        if (cachedImage != null) {
          tileContent = RawImage(
            image: cachedImage,
            width: width,
            height: height,
            fit: BoxFit.fill,
          );
        } else {
          tileContent = Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12, width: 0.5 / widget.scale),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
          _requestTile(key, tileRect, width, height);
        }
        
        tileWidgets.add(
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: tileContent,
          ),
        );
      }
    }

    return SizedBox(
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // White background for the page
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // Shadow for page separation
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10 / widget.scale,
                    offset: Offset(0, 4 / widget.scale),
                  ),
                ],
              ),
            ),
          ),
          
          // Rendered tiles
          ...tileWidgets,
        ],
      ),
    );
  }
}
