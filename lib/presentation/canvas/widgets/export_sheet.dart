import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Export options bottom sheet.
///
/// Lets the user choose between PNG and PDF export,
/// with resolution and scope options.
class ExportSheet extends StatefulWidget {
  final int totalPages;
  final int currentPage;
  final VoidCallback onExportCurrentPng;
  final VoidCallback onExportAllPng;
  final VoidCallback onExportPdf;

  const ExportSheet({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onExportCurrentPng,
    required this.onExportAllPng,
    required this.onExportPdf,
  });

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
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
          // Drag handle
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

          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Dışa Aktar',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Export current page as PNG
          _ExportOption(
            icon: Icons.image_rounded,
            title: 'Bu Sayfayı PNG Olarak',
            subtitle: 'Sayfa ${widget.currentPage + 1} — 2480×3508 px',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              widget.onExportCurrentPng();
            },
          ).animate().fadeIn(duration: 200.ms).slideX(
                begin: -0.05,
                end: 0,
                duration: 200.ms,
              ),

          const SizedBox(height: AppSpacing.md),

          // Export all pages as PNG
          if (widget.totalPages > 1)
            _ExportOption(
              icon: Icons.collections_rounded,
              title: 'Tüm Sayfaları PNG Olarak',
              subtitle: '${widget.totalPages} sayfa — ayrı dosyalar',
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                widget.onExportAllPng();
              },
            ).animate().fadeIn(duration: 200.ms, delay: 50.ms).slideX(
                  begin: -0.05,
                  end: 0,
                  duration: 200.ms,
                ),

          if (widget.totalPages > 1) const SizedBox(height: AppSpacing.md),

          // Export as PDF
          _ExportOption(
            icon: Icons.picture_as_pdf_rounded,
            title: 'PDF Olarak Dışa Aktar',
            subtitle: widget.totalPages > 1
                ? '${widget.totalPages} sayfa — tek dosya'
                : '1 sayfa — PDF belgesi',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              widget.onExportPdf();
            },
          ).animate().fadeIn(duration: 200.ms, delay: 100.ms).slideX(
                begin: -0.05,
                end: 0,
                duration: 200.ms,
              ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
