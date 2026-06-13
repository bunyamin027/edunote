import 'package:flutter/material.dart';

class PdfContextMenu extends StatelessWidget {
  final Offset position;
  final String selectedText;
  final VoidCallback onCopy;
  final VoidCallback onAskAi;
  final VoidCallback onSummarize;
  final VoidCallback onHighlight;

  const PdfContextMenu({
    super.key,
    required this.position,
    required this.selectedText,
    required this.onCopy,
    required this.onAskAi,
    required this.onSummarize,
    required this.onHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy - 60, // Show above the text
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuItem(
                icon: Icons.copy,
                label: 'Kopyala',
                onTap: onCopy,
              ),
              _MenuItem(
                icon: Icons.auto_awesome,
                label: 'Yapay Zekaya Sor',
                onTap: onAskAi,
              ),
              _MenuItem(
                icon: Icons.summarize,
                label: 'Özetle',
                onTap: onSummarize,
              ),
              _MenuItem(
                icon: Icons.format_paint,
                label: 'Vurgula',
                onTap: onHighlight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
