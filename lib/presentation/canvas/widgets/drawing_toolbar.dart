import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../engine/drawing_engine.dart';
import '../engine/stroke_style.dart';
import 'pen_settings_sheet.dart';

/// Main drawing toolbar — tool selection, color, width controls.
class DrawingToolbar extends StatelessWidget {
  final DrawingEngine engine;
  final VoidCallback onUndoTap;
  final VoidCallback onRedoTap;
  final bool canUndo;
  final bool canRedo;
  final Axis axis;

  const DrawingToolbar({
    super.key,
    required this.engine,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.canUndo,
    required this.canRedo,
    this.axis = Axis.horizontal,
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
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Tool Buttons ─────────────────────────
          _ToolButton(
            icon: Icons.pan_tool_rounded,
            label: 'Kaydır',
            isSelected: style.toolType == ToolType.pan,
            onTap: () => engine.setToolType(ToolType.pan),
          ),
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
            icon: Icons.polyline_rounded,
            label: 'Akıllı Şekil',
            isSelected: style.toolType == ToolType.smartShape,
            onTap: () => engine.setToolType(ToolType.smartShape),
          ),
          _ToolButton(
            icon: Icons.all_out_rounded,
            label: 'Kement (Lasso)',
            isSelected: style.toolType == ToolType.lasso,
            onTap: () => engine.setToolType(ToolType.lasso),
          ),
          _ToolButton(
            icon: Icons.auto_fix_normal_rounded,
            label: 'Silgi',
            isSelected: style.toolType == ToolType.eraser,
            activeColor: AppColors.error.withValues(alpha: 0.8),
            onTap: () => engine.setToolType(ToolType.eraser),
          ),

          // Divider
          _ToolbarDivider(axis: axis),

          // ─── Color Button ─────────────────────────
          _ColorButton(
            color: style.toolType == ToolType.eraser
                ? Colors.grey
                : style.color,
            enabled: style.toolType != ToolType.eraser,
            onTap: () => _showSettingsSheet(context),
          ),

          // ─── Width Button ─────────────────────────
          _WidthButton(
            width: style.width,
            color: style.color,
            onTap: () => _showSettingsSheet(context),
          ),

          // Divider
          _ToolbarDivider(axis: axis),

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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PenSettingsSheet(engine: engine),
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
  final Axis axis;
  const _ToolbarDivider({this.axis = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: axis == Axis.horizontal ? 6 : 0,
        vertical: axis == Axis.vertical ? 6 : 0,
      ),
      width: axis == Axis.horizontal ? 1 : 24,
      height: axis == Axis.horizontal ? 24 : 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// Old picker sheets removed as we now use PenSettingsSheet
