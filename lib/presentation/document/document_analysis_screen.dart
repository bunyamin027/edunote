import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../bloc/document/document_bloc.dart';
import '../../bloc/document/document_event.dart';
import '../../bloc/document/document_state.dart';
import '../../core/config/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/ai_service.dart';
import '../ai/widgets/flashcard_carousel.dart';

import '../../data/models/imported_file_model.dart';
import '../../data/services/ai_result_service.dart';

/// Full-screen document analysis page.
/// User picks a file → text is extracted → AI operations available.
class DocumentAnalysisScreen extends StatelessWidget {
  final ImportedFile? file;

  const DocumentAnalysisScreen({super.key, this.file});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = DocumentBloc(sl<AiService>(), sl<AiResultService>());
        if (file != null) {
          bloc.add(LoadDocument(
            filePath: file!.localPath,
            fileName: file!.fileName,
            fileExtension: file!.extension,
            fileSizeBytes: file!.fileSize,
            folderId: file!.folderId,
            sourceFileId: file!.id,
          ));
        } else {
          bloc.add(PickDocument());
        }
        return bloc;
      },
      child: _DocumentAnalysisView(file: file),
    );
  }
}

class _DocumentAnalysisView extends StatefulWidget {
  final ImportedFile? file;

  const _DocumentAnalysisView({this.file});

  @override
  State<_DocumentAnalysisView> createState() => _DocumentAnalysisViewState();
}

class _DocumentAnalysisViewState extends State<_DocumentAnalysisView> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Belge Analizi'),
        centerTitle: true,
        actions: [
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state is DocumentLoaded ||
                  state is DocumentResultReady ||
                  state is DocumentFlashcardsReady ||
                  state is DocumentChatActive ||
                  (state is DocumentError && state.hasDocument)) {
                return IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Yeni Dosya Seç',
                  onPressed: () {
                    context.read<DocumentBloc>().add(ResetDocument());
                    context.read<DocumentBloc>().add(PickDocument());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentInitial) {
            // User cancelled file picker — go back
            Navigator.of(context).pop();
          }
          if (state is DocumentChatActive) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is DocumentPicking) {
            return _buildPickingState(theme);
          }
          if (state is DocumentLoaded) {
            return _buildLoadedState(context, theme, state);
          }
          if (state is DocumentProcessing) {
            return _buildProcessingState(theme, state);
          }
          if (state is DocumentResultReady) {
            return _buildResultState(context, theme, state);
          }
          if (state is DocumentFlashcardsReady) {
            return _buildFlashcardsState(context, theme, state);
          }
          if (state is DocumentChatActive) {
            return _buildChatState(context, theme, state);
          }
          if (state is DocumentError) {
            return _buildErrorState(context, theme, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ─── Picking State ──────────────────────────────────────

  Widget _buildPickingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Dosya seçici açılıyor...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Loaded State — Show AI Action Cards ────────────────

  Widget _buildLoadedState(
      BuildContext context, ThemeData theme, DocumentLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info card
          _FileInfoCard(
            fileName: state.fileName,
            fileExtension: state.fileExtension,
            formattedSize: state.formattedSize,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: AppSpacing.xxl),

          // Section title
          Text(
            'AI ile Çalış',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belgeni analiz etmek için bir işlem seçin',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // AI Action Cards — 2x2 grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.15,
            children: [
              _AiActionCard(
                icon: Icons.summarize_rounded,
                title: 'Özet Çıkar',
                description: 'Belgenin akademik özetini oluştur',
                gradient: [AppColors.primary, AppColors.primaryLight],
                onTap: () =>
                    context.read<DocumentBloc>().add(SummarizeDocument()),
              ),
              _AiActionCard(
                icon: Icons.quiz_rounded,
                title: 'Soru Üret',
                description: 'Sınav soruları oluştur',
                gradient: [AppColors.accent, AppColors.accentLight],
                onTap: () => context
                    .read<DocumentBloc>()
                    .add(GenerateDocumentQuestions()),
              ),
              _AiActionCard(
                icon: Icons.style_rounded,
                title: 'Flashcard',
                description: 'Bilgi kartları oluştur',
                gradient: [AppColors.secondary, AppColors.secondaryLight],
                onTap: () => context
                    .read<DocumentBloc>()
                    .add(GenerateDocumentFlashcards()),
              ),
              _AiActionCard(
                icon: Icons.chat_rounded,
                title: 'Soru Sor',
                description: 'Belge hakkında sohbet et',
                gradient: [AppColors.info, const Color(0xFF60A5FA)],
                onTap: () => context
                    .read<DocumentBloc>()
                    .add(const ChatAboutDocument(
                        'Bu belgenin içeriği hakkında kısaca bilgi ver.')),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.15, end: 0, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxl),

          // Extracted text preview
          ExpansionTile(
            leading: Icon(Icons.text_snippet_outlined,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
            title: Text(
              'Çıkarılan Metin Önizleme',
              style: theme.textTheme.labelLarge,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  state.extractedText.length > 500
                      ? '${state.extractedText.substring(0, 500)}...'
                      : state.extractedText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Processing State ──────────────────────────────────

  Widget _buildProcessingState(ThemeData theme, DocumentProcessing state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms)
                .shimmer(duration: 1200.ms, color: Colors.white30),

            const SizedBox(height: AppSpacing.xxl),

            Text(
              state.operationLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.fileName} analiz ediliyor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Result State (Summary / Questions) ────────────────

  Widget _buildResultState(
      BuildContext context, ThemeData theme, DocumentResultReady state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result header
                _FileInfoCard(
                  fileName: state.fileName,
                  fileExtension: '',
                  formattedSize: '',
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Result title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        state.resultTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Result content
                SelectableText(
                  state.resultContent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action bar
        _BottomActionBar(
          onBack: () =>
              context.read<DocumentBloc>().add(ClearDocumentResults()),
          onNewFile: () {
            context.read<DocumentBloc>().add(ResetDocument());
            context.read<DocumentBloc>().add(PickDocument());
          },
          onSave: widget.file?.folderId != null ? () {
            context.read<DocumentBloc>().add(SaveAiResult(
              title: state.resultTitle,
              content: state.resultContent,
              typeIndex: state.resultTitle.contains('Özet') ? 0 : 1,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sonuç klasöre kaydedildi!')),
            );
          } : null,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Flashcards State ─────────────────────────────────

  Widget _buildFlashcardsState(
      BuildContext context, ThemeData theme, DocumentFlashcardsReady state) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FileInfoCard(
                fileName: state.fileName,
                fileExtension: '',
                formattedSize: '',
                compact: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      '🎴 ${state.flashcards.length} Flashcard',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Flashcard carousel
        Expanded(
          child: FlashcardCarousel(flashcards: state.flashcards),
        ),

        // Bottom action bar
        _BottomActionBar(
          onBack: () =>
              context.read<DocumentBloc>().add(ClearDocumentResults()),
          onNewFile: () {
            context.read<DocumentBloc>().add(ResetDocument());
            context.read<DocumentBloc>().add(PickDocument());
          },
          onSave: widget.file?.folderId != null ? () {
            final jsonContent = jsonEncode(state.flashcards.map((f) => {'question': f.question, 'answer': f.answer}).toList());
            context.read<DocumentBloc>().add(SaveAiResult(
              title: 'Flashcardlar',
              content: jsonContent,
              typeIndex: 2,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Flashcardlar klasöre kaydedildi!')),
            );
          } : null,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Chat State ────────────────────────────────────────

  Widget _buildChatState(
      BuildContext context, ThemeData theme, DocumentChatActive state) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // File header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.description_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.fileName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.read<DocumentBloc>().add(ClearDocumentResults()),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Geri'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount:
                state.messages.length + (state.isProcessing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.messages.length && state.isProcessing) {
                return _buildTypingIndicator();
              }

              final message = state.messages[index];
              final isUser = message.role == ChatRole.user;

              return _ChatBubble(message: message, isUser: isUser);
            },
          ),
        ),

        // Chat input
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _chatController,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendChatMessage(context),
                    decoration: const InputDecoration(
                      hintText: 'Belge hakkında soru sor...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: state.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed:
                      state.isProcessing ? null : () => _sendChatMessage(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendChatMessage(BuildContext context) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    context.read<DocumentBloc>().add(ChatAboutDocument(text));
    _chatController.clear();
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (controller) => controller.repeat())
                      .scaleXY(
                        begin: 0.5,
                        end: 1.5,
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        delay: (i * 200).ms,
                      )
                      .then()
                      .scaleXY(
                        begin: 1.5,
                        end: 0.5,
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────

  Widget _buildErrorState(
      BuildContext context, ThemeData theme, DocumentError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Hata Oluştu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.hasDocument)
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<DocumentBloc>().add(ClearDocumentResults()),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Geri Dön'),
                  ),
                if (state.hasDocument) const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    context.read<DocumentBloc>().add(ResetDocument());
                    context.read<DocumentBloc>().add(PickDocument());
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Reusable Widgets ─────────────────────────────────────

class _FileInfoCard extends StatelessWidget {
  final String fileName;
  final String fileExtension;
  final String formattedSize;
  final bool compact;

  const _FileInfoCard({
    required this.fileName,
    required this.fileExtension,
    required this.formattedSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 52,
            height: compact ? 40 : 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              _getFileIcon(fileExtension),
              color: Colors.white,
              size: compact ? 20 : 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: (compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.titleSmall)
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact && formattedSize.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Text(
                        formattedSize,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (fileExtension.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            fileExtension.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: compact ? 20 : 24,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'txt':
        return Icons.description_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _AiActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _AiActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: gradient.first.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: gradient.first, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: gradient.first,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.primarySurface,
              child: Icon(
                message.isError
                    ? Icons.error_outline
                    : Icons.auto_awesome_rounded,
                size: 18,
                color: message.isError ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusXl),
                  topRight: const Radius.circular(AppSpacing.radiusXl),
                  bottomLeft:
                      Radius.circular(isUser ? AppSpacing.radiusXl : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : AppSpacing.radiusXl),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: message.isError
                            ? AppColors.error
                            : theme.colorScheme.outlineVariant,
                      ),
              ),
              child: SelectableText(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? Colors.white
                      : (message.isError
                          ? AppColors.error
                          : theme.colorScheme.onSurface),
                  height: 1.5,
                ),
              ),
            )
                .animate()
                .slideY(begin: 0.1, end: 0, duration: 200.ms)
                .fadeIn(duration: 200.ms),
          ),
          if (isUser) const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNewFile;
  final VoidCallback? onSave;

  const _BottomActionBar({
    required this.onBack,
    required this.onNewFile,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePaddingHorizontal,
        right: AppSpacing.pagePaddingHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Geri'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNewFile,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Yeni'),
            ),
          ),
          if (onSave != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
