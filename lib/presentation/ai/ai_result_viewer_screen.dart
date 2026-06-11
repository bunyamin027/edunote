import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/ai_result_model.dart';
import 'widgets/flashcard_carousel.dart';
import '../../data/models/flashcard_model.dart';

class AiResultViewerScreen extends StatelessWidget {
  final AiResultModel aiResult;

  const AiResultViewerScreen({super.key, required this.aiResult});

  void _shareContent(BuildContext context) {
    String textToShare = '${aiResult.title}\n\n';

    if (aiResult.type == AiResultType.flashcards) {
      try {
        final List<dynamic> jsonList = jsonDecode(aiResult.content);
        for (int i = 0; i < jsonList.length; i++) {
          final item = jsonList[i] as Map<String, dynamic>;
          textToShare += 'Soru ${i + 1}: ${item['question'] ?? item['front']}\n';
          textToShare += 'Cevap: ${item['answer'] ?? item['back']}\n\n';
        }
      } catch (_) {
        textToShare += aiResult.content;
      }
    } else {
      textToShare += aiResult.content;
    }

    Share.share(textToShare, subject: aiResult.title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget body;
    if (aiResult.type == AiResultType.flashcards) {
      try {
        final List<dynamic> jsonList = jsonDecode(aiResult.content);
        final flashcards = jsonList.map((j) => FlashcardModel.fromJson(j as Map<String, dynamic>)).toList();
        body = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: FlashcardCarousel(flashcards: flashcards),
          ),
        );
      } catch (e) {
        body = Center(child: Text('Flashcard verisi okunamadı.'));
      }
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        child: SelectableText(
          aiResult.content,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          aiResult.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Paylaş',
            onPressed: () => _shareContent(context),
          ),
        ],
      ),
      body: body,
    );
  }
}
