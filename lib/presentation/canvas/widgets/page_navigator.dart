import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../engine/page_model.dart';

/// Vertical page thumbnail strip for multi-page navigation.
class PageNavigator extends StatelessWidget {
  /// All pages in the notebook.
  final List<PageModel> pages;

  /// Currently active page index.
  final int currentPageIndex;

  /// Callback when a page is tapped.
  final ValueChanged<int> onPageSelected;

  /// Callback to add a new page.
  final VoidCallback onAddPage;

  /// Callback to delete a page.
  final ValueChanged<int> onDeletePage;

  const PageNavigator({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onDeletePage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Page thumbnails
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              itemCount: pages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final isSelected = index == currentPageIndex;
                return GestureDetector(
                  onTap: () => onPageSelected(index),
                  onLongPress: pages.length > 1
                      ? () => _showDeleteDialog(context, index)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: AppSpacing.animFast,
                    ),
                    width: 56,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isSelected
                              ? AppColors.primaryDark.withValues(alpha: 0.3)
                              : AppColors.backgroundDark)
                          : (isSelected
                              ? AppColors.primarySurface
                              : Colors.white),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                      duration: 200.ms,
                      delay: (index * 30).ms,
                    );
              },
            ),
          ),

          // Add page button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GestureDetector(
              onTap: onAddPage,
              child: Container(
                width: 56,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayfayı Sil'),
        content: Text('Sayfa ${index + 1} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              onDeletePage(index);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
