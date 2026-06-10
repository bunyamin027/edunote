import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../bloc/ai/ai_bloc.dart';
import '../../bloc/ai/ai_event.dart';
import '../../bloc/ai/ai_state.dart';
import '../../core/config/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/chat_message_model.dart';
import 'widgets/flashcard_carousel.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiBloc(sl()),
      child: const _AiView(),
    );
  }
}

class _AiView extends StatefulWidget {
  const _AiView();

  @override
  State<_AiView> createState() => _AiViewState();
}

class _AiViewState extends State<_AiView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<AiBloc>().add(SendChatMessage(text));
    _textController.clear();
    _focusNode.requestFocus();
    
    // Give UI a moment to build the new message bubble before scrolling
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Asistan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Sohbeti Temizle',
            onPressed: () {
              context.read<AiBloc>().add(ClearChat());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons (Quick Prompts)
          _QuickActionsBar(),

          // Chat Messages Area
          Expanded(
            child: BlocConsumer<AiBloc, AiState>(
              listener: (context, state) {
                if (state is AiChatIdle || state is AiError) {
                  Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                }
              },
              builder: (context, state) {
                final messages = _getMessagesFromState(state);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length + (state is AiProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && state is AiProcessing) {
                      return const _TypingIndicator();
                    }

                    final message = messages[index];
                    final isUser = message.role == ChatRole.user;

                    return _ChatBubble(message: message, isUser: isUser);
                  },
                );
              },
            ),
          ),

          // Flashcard / Special View Area (if applicable)
          BlocBuilder<AiBloc, AiState>(
            builder: (context, state) {
              if (state is AiFlashcardsGenerated) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FlashcardCarousel(flashcards: state.flashcards),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input Area
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
                      color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(context),
                      decoration: const InputDecoration(
                        hintText: 'AI asistanına sor...',
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
                BlocBuilder<AiBloc, AiState>(
                  builder: (context, state) {
                    final isProcessing = state is AiProcessing;
                    return Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isProcessing 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(
                                  color: Colors.white, 
                                  strokeWidth: 2
                                )
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: isProcessing ? null : () => _sendMessage(context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ChatMessage> _getMessagesFromState(AiState state) {
    if (state is AiProcessing) return state.messages;
    if (state is AiChatIdle) return state.messages;
    if (state is AiFlashcardsGenerated) return state.messages;
    if (state is AiSummaryGenerated) return state.messages;
    if (state is AiError) return state.messages;
    return [];
  }
}

class _QuickActionsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.summarize_rounded,
            label: 'Özetle',
            onTap: () {
              // TODO: Get actual context (e.g. selected notebook text)
              final dummyText = "Mitoz bölünme hücrenin çoğalmasını sağlayan bir olaydır. Prohaz, metafaz, anafaz, telofaz evrelerinden oluşur.";
              context.read<AiBloc>().add(SummarizeText(dummyText));
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionChip(
            icon: Icons.style_rounded,
            label: 'Flashcard Üret',
            onTap: () {
               // TODO: Get actual context
              final dummyText = "Mitoz bölünme hücrenin çoğalmasını sağlayan bir olaydır. Prohaz, metafaz, anafaz, telofaz evrelerinden oluşur.";
              context.read<AiBloc>().add(GenerateFlashcards(dummyText));
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionChip(
            icon: Icons.quiz_rounded,
            label: 'Bana Soru Sor',
            onTap: () {
              context.read<AiBloc>().add(const SendChatMessage("Mevcut notlarımdan bana bir test sorusu sorar mısın?"));
            },
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.primarySurface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ChatBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError ? AppColors.error.withValues(alpha: 0.2) : AppColors.primarySurface,
              child: Icon(
                message.isError ? Icons.error_outline : Icons.auto_awesome_rounded, 
                size: 18, 
                color: message.isError ? AppColors.error : AppColors.primary
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppColors.primary 
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusXl),
                  topRight: const Radius.circular(AppSpacing.radiusXl),
                  bottomLeft: Radius.circular(isUser ? AppSpacing.radiusXl : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusXl),
                ),
                border: isUser ? null : Border.all(
                  color: message.isError ? AppColors.error : theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: isUser ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : (message.isError ? AppColors.error : theme.colorScheme.onSurface),
                ),
              ),
            ).animate().slideY(begin: 0.1, end: 0, duration: 200.ms).fadeIn(duration: 200.ms),
          ),
          
          if (isUser) const SizedBox(width: 32), // Add visual balance
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0.ms),
                const SizedBox(width: 4),
                _Dot(delay: 200.ms),
                const SizedBox(width: 4),
                _Dot(delay: 400.ms),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Duration delay;

  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .scaleXY(begin: 0.5, end: 1.5, duration: 400.ms, curve: Curves.easeInOut, delay: delay)
     .then()
     .scaleXY(begin: 1.5, end: 0.5, duration: 400.ms, curve: Curves.easeInOut);
  }
}
