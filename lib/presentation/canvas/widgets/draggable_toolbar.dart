import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class DraggableToolbar extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final Axis initialAxis;
  final void Function(Axis)? onAxisChanged;

  const DraggableToolbar({
    super.key,
    required this.child,
    required this.initialPosition,
    this.initialAxis = Axis.horizontal,
    this.onAxisChanged,
  });

  @override
  State<DraggableToolbar> createState() => _DraggableToolbarState();
}

class _DraggableToolbarState extends State<DraggableToolbar> {
  late Offset _position;
  late Axis _axis;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _axis = widget.initialAxis;
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    setState(() {
      _position += details.delta;
      _clampPosition(screenSize);
    });
  }

  void _clampPosition(Size screenSize) {
    final RenderBox? box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final Size size = box.size;
    final padding = AppSpacing.sm;

    double minDx = padding;
    double maxDx = screenSize.width - size.width - padding;
    if (maxDx < minDx) {
      // Toolbar is wider than the screen, allow dragging to negative x
      final temp = minDx;
      minDx = maxDx;
      maxDx = temp;
    }

    double minDy = padding;
    double maxDy = screenSize.height - size.height - padding;
    if (maxDy < minDy) {
      // Toolbar is taller than the screen, allow dragging to negative y
      final temp = minDy;
      minDy = maxDy;
      maxDy = temp;
    }

    double dx = _position.dx.clamp(minDx, maxDx);
    double dy = _position.dy.clamp(minDy, maxDy);

    _position = Offset(dx, dy);
  }

  void _toggleOrientation() {
    setState(() {
      _axis = _axis == Axis.horizontal ? Axis.vertical : Axis.horizontal;
    });
    widget.onAxisChanged?.call(_axis);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build drag handle
    final Widget dragHandle = GestureDetector(
      onPanUpdate: (details) => _onPanUpdate(details, screenSize),
      onPanEnd: (_) => _clampPosition(screenSize),
      onDoubleTap: _toggleOrientation,
      child: Tooltip(
        message: 'Sürükleyin | Çift tıkla döndür',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(
            Icons.drag_indicator_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Container(
        key: _key,
        child: Flex(
          direction: _axis,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dragHandle,
            widget.child,
          ],
        ),
      ),
    );
  }
}
