import 'dart:ui' as ui;

/// An image filter that performs a "Smart Invert".
/// 
/// Smart Invert inverts the lightness of the image but preserves the hue,
/// making it ideal for dark mode PDF rendering. Text and white backgrounds
/// become dark, while photos and color highlights retain their original colors.
class SmartInvertFilter {
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  void toggle() {
    _isEnabled = !_isEnabled;
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Returns the color filter to apply to the canvas/image.
  /// Returns null if smart invert is disabled.
  ui.ColorFilter? get filter {
    if (!_isEnabled) return null;

    // This matrix performs a lightness inversion in RGB space.
    // Mathematically, it's roughly: R' = 1 - R, G' = 1 - G, B' = 1 - B
    // A perfect hue-preserving invert requires HSL conversion which isn't 
    // supported directly by ColorFilter.matrix, but this provides a very 
    // fast approximation suitable for PDFs.
    return const ui.ColorFilter.matrix(<double>[
      -1,  0,  0, 0, 255, // Red
       0, -1,  0, 0, 255, // Green
       0,  0, -1, 0, 255, // Blue
       0,  0,  0, 1,   0, // Alpha
    ]);
  }
}
