import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../engine/text_element.dart';

/// Overlay widget that renders and manages text elements on the canvas.
class TextLayerOverlay extends StatefulWidget {
  /// Current text elements on this page.
  final List<TextElement> textElements;

  /// Callback when text elements change.
  final ValueChanged<List<TextElement>> onTextElementsChanged;

  /// Whether text mode is active (tapping creates new text boxes).
  final bool isTextMode;

  /// Current canvas transform for positioning.
  final Matrix4 transform;

  const TextLayerOverlay({
    super.key,
    required this.textElements,
    required this.onTextElementsChanged,
    required this.isTextMode,
    required this.transform,
  });

  @override
  State<TextLayerOverlay> createState() => _TextLayerOverlayState();
}

class _TextLayerOverlayState extends State<TextLayerOverlay> {
  final _uuid = const Uuid();
  String? _editingId;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap detector for creating new text boxes
        if (widget.isTextMode)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) => _createTextElement(details.localPosition),
            ),
          ),

        // Render existing text elements
        ...widget.textElements.map((element) {
          return Positioned(
            left: element.x,
            top: element.y,
            child: _TextBox(
              element: element,
              isEditing: _editingId == element.id,
              onTap: () => setState(() => _editingId = element.id),
              onChanged: (updated) => _updateElement(updated),
              onDelete: () => _deleteElement(element.id),
              onDragEnd: (offset) => _moveElement(element.id, offset),
              onEditingDone: () => setState(() => _editingId = null),
            ),
          );
        }),
      ],
    );
  }

  void _createTextElement(Offset position) {
    final element = TextElement(
      id: _uuid.v4(),
      text: '',
      x: position.dx,
      y: position.dy,
    );

    final updated = [...widget.textElements, element];
    widget.onTextElementsChanged(updated);
    setState(() => _editingId = element.id);
  }

  void _updateElement(TextElement element) {
    final updated = widget.textElements.map((e) {
      return e.id == element.id ? element : e;
    }).toList();
    widget.onTextElementsChanged(updated);
  }

  void _deleteElement(String id) {
    final updated = widget.textElements
        .where((e) => e.id != id)
        .toList();
    widget.onTextElementsChanged(updated);
    if (_editingId == id) {
      setState(() => _editingId = null);
    }
  }

  void _moveElement(String id, Offset newOffset) {
    final updated = widget.textElements.map((e) {
      if (e.id == id) {
        return e.copyWith(x: newOffset.dx, y: newOffset.dy);
      }
      return e;
    }).toList();
    widget.onTextElementsChanged(updated);
  }
}

/// Individual draggable, editable text box on the canvas.
class _TextBox extends StatefulWidget {
  final TextElement element;
  final bool isEditing;
  final VoidCallback onTap;
  final ValueChanged<TextElement> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onDragEnd;
  final VoidCallback onEditingDone;

  const _TextBox({
    required this.element,
    required this.isEditing,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
    required this.onDragEnd,
    required this.onEditingDone,
  });

  @override
  State<_TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<_TextBox> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late Offset _dragOffset;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.element.text);
    _focusNode = FocusNode();
    _dragOffset = Offset(widget.element.x, widget.element.y);

    if (widget.isEditing && widget.element.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _TextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _focusNode.requestFocus();
    }
    if (!widget.isEditing && oldWidget.isEditing) {
      _focusNode.unfocus();
    }
    _dragOffset = Offset(widget.element.x, widget.element.y);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final color = Color(element.colorValue);

    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: widget.isEditing
          ? null
          : (details) {
              setState(() {
                _dragOffset += details.delta;
              });
            },
      onPanEnd: widget.isEditing
          ? null
          : (_) => widget.onDragEnd(_dragOffset),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 60,
          maxWidth: element.width > 0 ? element.width : 300,
        ),
        decoration: widget.isEditing
            ? BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Text field or display
            widget.isEditing
                ? IntrinsicWidth(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: element.fontSize,
                        fontWeight: element.fontWeightIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle:
                            element.isItalic ? FontStyle.italic : FontStyle.normal,
                        decoration: element.isUnderline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        color: color,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(AppSpacing.sm),
                        isDense: true,
                      ),
                      onChanged: (text) {
                        widget.onChanged(element.copyWith(text: text));
                      },
                      onEditingComplete: widget.onEditingDone,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      element.text.isEmpty ? 'Metin yazın...' : element.text,
                      style: TextStyle(
                        fontSize: element.fontSize,
                        fontWeight: element.fontWeightIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle:
                            element.isItalic ? FontStyle.italic : FontStyle.normal,
                        decoration: element.isUnderline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        color: element.text.isEmpty
                            ? color.withValues(alpha: 0.4)
                            : color,
                      ),
                    ),
                  ),

            // Editing controls
            if (widget.isEditing)
              Positioned(
                top: -36,
                left: 0,
                child: _TextEditingBar(
                  element: element,
                  onChanged: widget.onChanged,
                  onDelete: widget.onDelete,
                  onDone: widget.onEditingDone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mini toolbar that appears above an editing text box.
class _TextEditingBar extends StatelessWidget {
  final TextElement element;
  final ValueChanged<TextElement> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  const _TextEditingBar({
    required this.element,
    required this.onChanged,
    required this.onDelete,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bold
          _MiniButton(
            icon: Icons.format_bold_rounded,
            isActive: element.fontWeightIndex == 1,
            onTap: () => onChanged(element.copyWith(
              fontWeightIndex: element.fontWeightIndex == 1 ? 0 : 1,
            )),
          ),
          // Italic
          _MiniButton(
            icon: Icons.format_italic_rounded,
            isActive: element.isItalic,
            onTap: () => onChanged(element.copyWith(
              isItalic: !element.isItalic,
            )),
          ),
          // Underline
          _MiniButton(
            icon: Icons.format_underlined_rounded,
            isActive: element.isUnderline,
            onTap: () => onChanged(element.copyWith(
              isUnderline: !element.isUnderline,
            )),
          ),
          // Font size decrease
          _MiniButton(
            icon: Icons.text_decrease_rounded,
            onTap: () {
              if (element.fontSize > 8) {
                onChanged(element.copyWith(fontSize: element.fontSize - 2));
              }
            },
          ),
          // Font size increase
          _MiniButton(
            icon: Icons.text_increase_rounded,
            onTap: () {
              if (element.fontSize < 72) {
                onChanged(element.copyWith(fontSize: element.fontSize + 2));
              }
            },
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: theme.colorScheme.outlineVariant,
          ),
          // Delete
          _MiniButton(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            onTap: onDelete,
          ),
          // Done
          _MiniButton(
            icon: Icons.check_rounded,
            color: AppColors.success,
            onTap: onDone,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    this.isActive = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isActive
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: effectiveColor),
      ),
    );
  }
}
