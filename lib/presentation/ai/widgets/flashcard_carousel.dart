import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/flashcard_model.dart';

class FlashcardCarousel extends StatefulWidget {
  final List<FlashcardModel> flashcards;

  const FlashcardCarousel({
    super.key,
    required this.flashcards,
  });

  @override
  State<FlashcardCarousel> createState() => _FlashcardCarouselState();
}

class _FlashcardCarouselState extends State<FlashcardCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.flashcards.length,
            itemBuilder: (context, index) {
              return _FlashcardItem(
                flashcard: widget.flashcards[index],
                isActive: index == _currentIndex,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.flashcards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: AppSpacing.animFast),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashcardItem extends StatefulWidget {
  final FlashcardModel flashcard;
  final bool isActive;

  const _FlashcardItem({
    required this.flashcard,
    required this.isActive,
  });

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem> {
  bool _showAnswer = false;

  @override
  void didUpdateWidget(covariant _FlashcardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      // Reset flip when swiped away
      setState(() => _showAnswer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scale = widget.isActive ? 1.0 : 0.9;
    final opacity = widget.isActive ? 1.0 : 0.6;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: AppSpacing.animFast),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: AppSpacing.animFast),
        child: GestureDetector(
          onTap: () => setState(() => _showAnswer = !_showAnswer),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: _showAnswer 
                  ? AppColors.primarySurface 
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: _showAnswer ? AppColors.primary : theme.colorScheme.outlineVariant,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.flashcard.topic != null && !_showAnswer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.flashcard.topic!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    _showAnswer ? widget.flashcard.answer : widget.flashcard.question,
                    key: ValueKey<bool>(_showAnswer),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: _showAnswer ? FontWeight.normal : FontWeight.w600,
                      color: _showAnswer ? theme.colorScheme.onSurface : AppColors.primary,
                    ),
                  ),
                ),
                
                if (widget.flashcard.topic != null && !_showAnswer) const Spacer(),
                
                const SizedBox(height: AppSpacing.md),
                Text(
                  _showAnswer ? 'Soruya dönmek için dokunun' : 'Cevabı görmek için dokunun',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
