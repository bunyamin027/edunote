import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:collection';

/// Uniquely identifies a tile in the cache.
class TileKey {
  final int pageIndex;
  final int col;
  final int row;
  final double scale;

  const TileKey(this.pageIndex, this.col, this.row, this.scale);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileKey &&
          runtimeType == other.runtimeType &&
          pageIndex == other.pageIndex &&
          col == other.col &&
          row == other.row &&
          scale == other.scale;

  @override
  int get hashCode => Object.hash(pageIndex, col, row, scale);
}

/// Cache for rendered PDF tiles using LRU eviction policy.
class TileCache {
  final int maxMemoryBytes;
  int _currentMemoryBytes = 0;
  
  final LinkedHashMap<TileKey, ui.Image> _cache = LinkedHashMap<TileKey, ui.Image>();

  /// Default 128 MB cache size
  TileCache({this.maxMemoryBytes = 128 * 1024 * 1024});

  /// Get a tile from the cache. Moves it to the front of LRU.
  ui.Image? get(TileKey key) {
    final image = _cache.remove(key);
    if (image != null) {
      _cache[key] = image; // Move to end (most recently used)
    }
    return image;
  }

  /// Put a rendered tile into the cache. Evicts old tiles if necessary.
  void put(TileKey key, ui.Image image) {
    if (_cache.containsKey(key)) {
      final oldImage = _cache.remove(key)!;
      _currentMemoryBytes -= _estimateImageSize(oldImage);
      oldImage.dispose();
    }

    _cache[key] = image;
    _currentMemoryBytes += _estimateImageSize(image);

    _evictIfNeeded();
  }

  /// Estimates memory footprint of a ui.Image.
  int _estimateImageSize(ui.Image image) {
    // 4 bytes per pixel for RGBA8888
    return image.width * image.height * 4;
  }

  /// Evict least recently used tiles until we're under budget.
  void _evictIfNeeded() {
    while (_currentMemoryBytes > maxMemoryBytes && _cache.isNotEmpty) {
      final keyToEvict = _cache.keys.first; // First item is LRU
      final evictedImage = _cache.remove(keyToEvict)!;
      _currentMemoryBytes -= _estimateImageSize(evictedImage);
      evictedImage.dispose();
    }
  }

  /// Invalidate tiles for a specific page, or all tiles if [pageIndex] is null.
  void invalidate({int? pageIndex}) {
    if (pageIndex == null) {
      for (final image in _cache.values) {
        image.dispose();
      }
      _cache.clear();
      _currentMemoryBytes = 0;
    } else {
      final keysToRemove = _cache.keys.where((k) => k.pageIndex == pageIndex).toList();
      for (final key in keysToRemove) {
        final image = _cache.remove(key)!;
        _currentMemoryBytes -= _estimateImageSize(image);
        image.dispose();
      }
    }
  }

  void dispose() {
    invalidate();
  }
}
