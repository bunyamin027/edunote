import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/notebook/notebook_bloc.dart';
import '../../bloc/notebook/notebook_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bottom sheet for creating a new notebook.
class CreateNotebookSheet extends StatefulWidget {
  const CreateNotebookSheet({super.key});

  @override
  State<CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<CreateNotebookSheet> {
  final _nameController = TextEditingController();
  int _selectedCover = 0;
  int _selectedTemplate = 0;

  final List<String> _templateNames = [
    'Boş',
    'Çizgili',
    'Kareli',
    'Noktalı',
    'İzometrik',
  ];

  final List<IconData> _templateIcons = [
    Icons.crop_square_rounded,
    Icons.format_line_spacing_rounded,
    Icons.grid_4x4_rounded,
    Icons.grain_rounded,
    Icons.change_history_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXxl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePaddingHorizontal,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Yeni Not Defteri',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePaddingHorizontal,
                    ),
                    children: [
                      // Name input
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Not Defteri Adı',
                          hintText: 'ör. Biyoloji 101 Notları',
                          prefixIcon: const Icon(Icons.edit_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _nameController.clear(),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Cover selection
                      Text(
                        'Kapak Tasarımı',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AppColors.coverGradients.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedCover == index;
                            final colors = AppColors.coverGradients[index];

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCover = index),
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: AppSpacing.animFast,
                                ),
                                width: 64,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: colors,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: colors.first
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Template selection
                      Text(
                        'Kağıt Şablonu',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: List.generate(
                          _templateNames.length,
                          (index) {
                            final isSelected = _selectedTemplate == index;
                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedTemplate = index,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: AppSpacing.animFast,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primarySurface
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : theme.colorScheme.outline,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _templateIcons[index],
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.primary
                                          : theme
                                              .colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      _templateNames[index],
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),

                // Create button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePaddingHorizontal,
                    AppSpacing.md,
                    AppSpacing.pagePaddingHorizontal,
                    AppSpacing.xxl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _onCreate,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Not Defteri Oluştur'),
                      style: FilledButton.styleFrom(
                        textStyle: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onCreate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir isim girin')),
      );
      return;
    }

    context.read<NotebookBloc>().add(
          CreateNotebook(
            name: name,
            coverIndex: _selectedCover,
            templateIndex: _selectedTemplate,
          ),
        );

    Navigator.of(context).pop();
  }
}
