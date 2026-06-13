import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../bloc/document_note/document_note_cubit.dart';
import '../../../bloc/document_note/document_note_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/document_note_model.dart';

/// A panel for taking and viewing notes associated with a document.
class DocumentNotesPanel extends StatefulWidget {
  const DocumentNotesPanel({super.key});

  @override
  State<DocumentNotesPanel> createState() => _DocumentNotesPanelState();
}

class _DocumentNotesPanelState extends State<DocumentNotesPanel> {
  final TextEditingController _noteController = TextEditingController();
  DocumentNoteModel? _editingNote;

  @override
  void initState() {
    super.initState();
    // Load notes when the panel opens
    context.read<DocumentNoteCubit>().loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;

    if (_editingNote != null) {
      context.read<DocumentNoteCubit>().updateNote(_editingNote!, content);
    } else {
      context.read<DocumentNoteCubit>().addNote(content);
    }

    _noteController.clear();
    setState(() => _editingNote = null);
  }

  void _editNote(DocumentNoteModel note) {
    setState(() {
      _editingNote = note;
      _noteController.text = note.content;
    });
  }

  void _shareAllNotes(List<DocumentNoteModel> notes) {
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak not bulunamadı.')),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Belge Notları');
    buffer.writeln('-------------------');
    
    for (var note in notes) {
      final date = '${note.updatedAt.day}.${note.updatedAt.month}.${note.updatedAt.year}';
      buffer.writeln('[$date]');
      buffer.writeln(note.content);
      buffer.writeln();
    }

    Share.share(buffer.toString(), subject: 'Belge Notları');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Belge Notları',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  BlocBuilder<DocumentNoteCubit, DocumentNoteState>(
                    builder: (context, state) {
                      final hasNotes = state is DocumentNoteLoaded && state.notes.isNotEmpty;
                      return IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: 'Tüm Notları Paylaş',
                        onPressed: hasNotes ? () => _shareAllNotes((state).notes) : null,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Notes List
            Expanded(
              child: BlocBuilder<DocumentNoteCubit, DocumentNoteState>(
                builder: (context, state) {
                  if (state is DocumentNoteLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DocumentNoteError) {
                    return Center(child: Text(state.message));
                  } else if (state is DocumentNoteLoaded) {
                    final notes = state.notes;
                    
                    if (notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Henüz not eklenmemiş.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: notes.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _NoteItem(
                          note: note,
                          onEdit: () => _editNote(note),
                          onDelete: () => context.read<DocumentNoteCubit>().deleteNote(note.id),
                        ).animate().fadeIn(delay: (index * 50).ms);
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Note Input Area
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_editingNote != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Not düzenleniyor',
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _editingNote = null;
                                _noteController.clear();
                              });
                            },
                            child: Text(
                              'İptal',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Belgeyle ilgili notlarınızı yazın...',
                            filled: true,
                            fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: _saveNote,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final DocumentNoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteItem({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${note.updatedAt.day}.${note.updatedAt.month}.${note.updatedAt.year} ${note.updatedAt.hour}:${note.updatedAt.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            note.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
