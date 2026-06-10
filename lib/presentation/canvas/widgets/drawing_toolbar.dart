import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../engine/drawing_engine.dart';
import '../engine/stroke_style.dart';

/// Main drawing toolbar — tool selection, color, width controls.
class DrawingToolbar extends StatelessWidget {
  final DrawingEngine engine;
  final VoidCallback onUndoTap;
  final VoidCallback onRedoTap;
  final bool canUndo;
  final bool canRedo;

  const DrawingToolbar({
    super.key,
    required this.engine,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = engine.currentStyle;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : AppColors.surfaceLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark
              : AppColors.dividerLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Tool Buttons ─────────────────────────
          _ToolButton(
            icon: Icons.edit_rounded,
            label: 'Kalem',
            isSelected: style.toolType == ToolType.pen,
            onTap: () => engine.setToolType(ToolType.pen),
          ),
          _ToolButton(
            icon: Icons.create_rounded,
            label: 'Tükenmez',
            isSelected: style.toolType == ToolType.ballpoint,
            onTap: () => engine.setToolType(ToolType.ballpoint),
          ),
          _ToolButton(
            icon: Icons.brush_rounded,
            label: 'Fırça',
            isSelected: style.toolType == ToolType.brush,
            onTap: () => engine.setToolType(ToolType.brush),
          ),
          _ToolButton(
            icon: Icons.format_paint_rounded,
            label: 'Fosforlu',
            isSelected: style.toolType == ToolType.highlighter,
            activeColor: AppColors.accentLight,
            onTap: () => engine.setToolType(ToolType.highlighter),
          ),
          _ToolButton(
            icon: Icons.auto_fix_normal_rounded,
            label: 'Silgi',
            isSelected: style.toolType == ToolType.eraser,
            activeColor: AppColors.error.withValues(alpha: 0.8),
            onTap: () => engine.setToolType(ToolType.eraser),
          ),

          // Divider
          _ToolbarDivider(),

          // ─── Color Button ─────────────────────────
          _ColorButton(
            color: style.toolType == ToolType.eraser
                ? Colors.grey
                : style.color,
            enabled: style.toolType != ToolType.eraser,
            onTap: () => _showColorPicker(context),
          ),

          // ─── Width Button ─────────────────────────
          _WidthButton(
            width: style.width,
            color: style.color,
            onTap: () => _showWidthPicker(context),
          ),

          // Divider
          _ToolbarDivider(),

          // ─── Undo / Redo ──────────────────────────
          _ActionButton(
            icon: Icons.undo_rounded,
            enabled: canUndo,
            onTap: onUndoTap,
          ),
          _ActionButton(
            icon: Icons.redo_rounded,
            enabled: canRedo,
            onTap: onRedoTap,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.3,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ColorPickerSheet(
        selectedColor: engine.currentStyle.color,
        onColorSelected: (color) {
          engine.setColor(color);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showWidthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _WidthPickerSheet(
        currentWidth: engine.currentStyle.width,
        color: engine.currentStyle.color,
        onWidthChanged: (width) => engine.setWidth(width),
      ),
    );
  }
}

// ─── Tool Button ────────────────────────────────────────
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = activeColor ?? AppColors.primary;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppSpacing.animFast),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? selectedColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Color Button ───────────────────────────────────────
class _ColorButton extends StatelessWidget {
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey.shade400,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? color : Colors.grey).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Width Button ───────────────────────────────────────
class _WidthButton extends StatelessWidget {
  final double width;
  final Color color;
  final VoidCallback onTap;

  const _WidthButton({
    required this.width,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outline,
          ),
        ),
        child: Center(
          child: Container(
            width: (width * 1.5).clamp(4.0, 18.0),
            height: (width * 1.5).clamp(4.0, 18.0),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action Button (Undo/Redo) ──────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

// ─── Toolbar Divider ────────────────────────────────────
class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 1,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ─── Color Picker Bottom Sheet ──────────────────────────
class _ColorPickerSheet extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerSheet({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Renk Seçin',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: AppColors.penColors.map((color) {
              final isSelected = selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: AppSpacing.animFast),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: _contrastColor(color),
                          size: 22,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

// ─── Width Picker Bottom Sheet ──────────────────────────
class _WidthPickerSheet extends StatefulWidget {
  final double currentWidth;
  final Color color;
  final ValueChanged<double> onWidthChanged;

  const _WidthPickerSheet({
    required this.currentWidth,
    required this.color,
    required this.onWidthChanged,
  });

  @override
  State<_WidthPickerSheet> createState() => _WidthPickerSheetState();
}

class _WidthPickerSheetState extends State<_WidthPickerSheet> {
  late double _width;

  @override
  void initState() {
    super.initState();
    _width = widget.currentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Kalınlık: ${_width.toStringAsFixed(1)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Preview
          Center(
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: CustomPaint(
                painter: _WidthPreviewPainter(
                  width: _width,
                  color: widget.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Preset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WidthPresetButton(
                label: 'İnce',
                width: 1.0,
                color: widget.color,
                isSelected: _width == 1.0,
                onTap: () => _setWidth(1.0),
              ),
              _WidthPresetButton(
                label: 'Orta',
                width: 3.0,
                color: widget.color,
                isSelected: _width == 3.0,
                onTap: () => _setWidth(3.0),
              ),
              _WidthPresetButton(
                label: 'Kalın',
                width: 6.0,
                color: widget.color,
                isSelected: _width == 6.0,
                onTap: () => _setWidth(6.0),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: widget.color,
              thumbColor: widget.color,
              inactiveTrackColor: widget.color.withValues(alpha: 0.2),
              overlayColor: widget.color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _width,
              min: 0.5,
              max: 12.0,
              onChanged: (value) => _setWidth(value),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _setWidth(double width) {
    setState(() => _width = width);
    widget.onWidthChanged(width);
  }
}

// ─── Width Preset Button ────────────────────────────────
class _WidthPresetButton extends StatelessWidget {
  final String label;
  final double width;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _WidthPresetButton({
    required this.label,
    required this.width,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSpacing.animFast),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: width * 3 + 4,
              height: width * 3 + 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Width Preview Painter ──────────────────────────────
class _WidthPreviewPainter extends CustomPainter {
  final double width;
  final Color color;

  _WidthPreviewPainter({required this.width, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;

    path.moveTo(20, midY);

    // Draw a wave pattern
    for (double x = 20; x < size.width - 20; x += 30) {
      final controlY = midY + (x % 60 == 0 ? -15 : 15);
      path.quadraticBezierTo(x + 15, controlY, x + 30, midY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WidthPreviewPainter oldDelegate) {
    return oldDelegate.width != width || oldDelegate.color != color;
  }
}
