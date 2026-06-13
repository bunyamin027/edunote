import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../engine/drawing_engine.dart';
import '../engine/stroke_style.dart';

class PenSettingsSheet extends StatefulWidget {
  final DrawingEngine engine;

  const PenSettingsSheet({
    super.key,
    required this.engine,
  });

  @override
  State<PenSettingsSheet> createState() => _PenSettingsSheetState();
}

class _PenSettingsSheetState extends State<PenSettingsSheet> {
  // We keep local state for the sliders to allow smooth dragging before committing to engine
  late double _currentWidth;
  late double _currentOpacity;
  int _selectedTabIndex = 0;

  // Advanced settings local state (currently visual only)
  bool _pressureSensitivity = true;
  bool _smoothing = true;
  double _sharpness = 0.5;

  @override
  void initState() {
    super.initState();
    _currentWidth = widget.engine.currentStyle.width;
    _currentOpacity = widget.engine.currentStyle.opacity;
    widget.engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _onEngineChanged() {
    if (mounted) {
      setState(() {
        _currentWidth = widget.engine.currentStyle.width;
        _currentOpacity = widget.engine.currentStyle.opacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.75)
        : AppColors.surfaceLight.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _buildTabs(theme),
                      const SizedBox(height: AppSpacing.xl),
                      if (_selectedTabIndex == 0) ...[
                        _buildPenGrid(theme),
                        const SizedBox(height: AppSpacing.xl),
                        _buildColorPalette(theme),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSliders(theme),
                      ] else ...[
                        _buildAdvancedSettings(theme),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _buildFavoritesButton(theme),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // spacer for balance
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Bitti',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedTabIndex = 0),
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTabIndex == 0 ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _selectedTabIndex == 0 ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Temel',
              style: TextStyle(
                color: _selectedTabIndex == 0 ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => setState(() => _selectedTabIndex = 1),
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTabIndex == 1 ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _selectedTabIndex == 1 ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Gelişmiş Ayarlar',
              style: TextStyle(
                color: _selectedTabIndex == 1 ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalem Davranışı',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Basınç Hassasiyeti'),
            subtitle: const Text('Apple Pencil veya desteklenen ekran kalemleri için çizgi kalınlığını basınca göre ayarlar.'),
            value: _pressureSensitivity,
            onChanged: (val) {
              setState(() => _pressureSensitivity = val);
            },
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Çizgi Yumuşatma'),
            subtitle: const Text('Titremeleri azaltarak daha pürüzsüz çizgiler oluşturur.'),
            value: _smoothing,
            onChanged: (val) {
              setState(() => _smoothing = val);
            },
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Uç Hassasiyeti',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            theme: theme,
            label: 'Keskinlik',
            value: _sharpness,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              setState(() => _sharpness = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPenGrid(ThemeData theme) {
    // Current available tools mapped to presentation items
    final List<Map<String, dynamic>> tools = [
      {'name': 'Tükenmez Kalem', 'type': ToolType.ballpoint},
      {'name': 'Dolma Kalem', 'type': ToolType.pen},
      {'name': 'Modern Kaligrafi', 'type': ToolType.brush},
      {'name': 'Keçeli Kalem', 'type': ToolType.highlighter}, // closest
      {'name': 'Silgi', 'type': ToolType.eraser},
      {'name': 'Akıllı Şekil', 'type': ToolType.smartShape},
      {'name': 'Kement', 'type': ToolType.lasso},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: tools.map((t) {
        final toolType = t['type'] as ToolType;
        final name = t['name'] as String;
        final isSelected = widget.engine.currentStyle.toolType == toolType;

        return GestureDetector(
          onTap: () => widget.engine.setToolType(toolType),
          child: Container(
            width: 72,
            height: 90,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CustomPaint(
                        painter: _SquigglePainter(
                          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                          toolType: toolType,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPalette(ThemeData theme) {
    // Generate a rich set of colors
    final colors = [
      Colors.black, Colors.grey.shade800, Colors.grey.shade600, Colors.grey.shade400,
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.blueGrey, const Color(0xFFE91E63), const Color(0xFF9C27B0),
      const Color(0xFF673AB7), const Color(0xFF3F51B5), const Color(0xFF2196F3), const Color(0xFF03A9F4),
      const Color(0xFF00BCD4), const Color(0xFF009688), const Color(0xFF4CAF50), const Color(0xFF8BC34A),
      const Color(0xFFCDDC39), const Color(0xFFFFEB3B), const Color(0xFFFFC107), const Color(0xFFFF9800),
    ];

    final isEraser = widget.engine.currentStyle.toolType == ToolType.eraser;
    final selectedColor = widget.engine.currentStyle.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          // Color picker icon button
          GestureDetector(
            onTap: () {
               // Optional: Show native color picker
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          ...colors.map((c) {
            final isSelected = !isEraser && c.toARGB32() == selectedColor.toARGB32();
            return GestureDetector(
              onTap: () {
                if (isEraser) {
                  widget.engine.setToolType(ToolType.pen); // switch back to pen if selecting color
                }
                widget.engine.setColor(c);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.5),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliders(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSliderRow(
            theme: theme,
            label: 'Kalınlık',
            value: _currentWidth,
            min: 0.5,
            max: 20.0,
            onChanged: (val) {
              setState(() => _currentWidth = val);
              widget.engine.setWidth(val);
            },
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            theme: theme,
            label: 'Opaklık',
            value: _currentOpacity,
            min: 0.1,
            max: 1.0,
            onChanged: (val) {
              setState(() => _currentOpacity = val);
              widget.engine.setOpacity(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required ThemeData theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesButton(ThemeData theme) {
    return Center(
      child: InkWell(
        onTap: () {
          // TODO: Implement favorites logic
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.orange.shade400),
              const SizedBox(width: 8),
              Text(
                'Favorilere ekle',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  final ToolType toolType;

  _SquigglePainter({required this.color, required this.toolType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;

    switch (toolType) {
      case ToolType.pen:
      case ToolType.ballpoint:
        paint.strokeWidth = 3;
        path.moveTo(0, midY);
        path.quadraticBezierTo(size.width * 0.25, midY - 15, size.width * 0.5, midY);
        path.quadraticBezierTo(size.width * 0.75, midY + 15, size.width, midY);
        break;
      case ToolType.brush:
        paint.strokeWidth = 5;
        path.moveTo(0, midY + 10);
        path.quadraticBezierTo(size.width * 0.5, midY - 20, size.width, midY + 10);
        break;
      case ToolType.highlighter:
        paint.strokeWidth = 8;
        paint.color = color.withValues(alpha: 0.5);
        paint.strokeCap = StrokeCap.square;
        path.moveTo(0, midY);
        path.quadraticBezierTo(size.width * 0.5, midY - 10, size.width, midY);
        break;
      case ToolType.eraser:
        paint.strokeWidth = 10;
        paint.color = Colors.grey.shade400;
        path.moveTo(5, midY);
        path.lineTo(size.width - 5, midY);
        break;
      case ToolType.smartShape:
        paint.strokeWidth = 3;
        path.addRect(Rect.fromCenter(center: Offset(size.width/2, midY), width: 20, height: 20));
        break;
      case ToolType.lasso:
        paint.strokeWidth = 2;
        paint.color = color;
        path.moveTo(0, midY);
        for(double i=0; i<size.width; i+=4) {
          path.lineTo(i, midY + (i%8==0 ? 5 : -5));
        }
        break;
      case ToolType.pan:
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquigglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.toolType != toolType;
  }
}
