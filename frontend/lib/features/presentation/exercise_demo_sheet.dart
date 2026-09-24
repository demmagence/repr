import 'package:flutter/material.dart';
import '../../data/exercise_api_client.dart';
import '../../ui/material/app_ui.dart';

Future<void> showExerciseDemoSheet(
  BuildContext context, {
  required ExerciseApiModel exercise,
  VoidCallback? onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ExerciseDemoView(exercise: exercise, onSelect: onSelect),
  );
}

class _ExerciseDemoView extends StatelessWidget {
  const _ExerciseDemoView({required this.exercise, this.onSelect});

  final ExerciseApiModel exercise;
  final VoidCallback? onSelect;

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppPageShell(
      topBar: AppTopBar(title: _capitalize(exercise.name), showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Animated GIF Demo
            if (exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(
                    exercise.gifUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Animasi gerakan tidak tersedia secara offline',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  context,
                  icon: Icons.accessibility_new,
                  label: 'Bagian: ${_capitalize(exercise.bodyPart)}',
                  color: colorScheme.primaryContainer,
                  textColor: colorScheme.onPrimaryContainer,
                ),
                _buildChip(
                  context,
                  icon: Icons.adjust,
                  label: 'Target: ${_capitalize(exercise.target)}',
                  color: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
                _buildChip(
                  context,
                  icon: Icons.fitness_center,
                  label: 'Alat: ${_capitalize(exercise.equipment)}',
                  color: colorScheme.tertiaryContainer,
                  textColor: colorScheme.onTertiaryContainer,
                ),
              ],
            ),

            if (exercise.secondaryMuscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Otot Sekunder:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final m in exercise.secondaryMuscles)
                    Chip(
                      label: Text(_capitalize(m)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Instructions section
            Row(
              children: [
                Icon(Icons.menu_book, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Petunjuk Gerakan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (exercise.instructions.isEmpty)
              Text(
                'Belum ada instruksi langkah demi langkah untuk gerakan ini.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (var i = 0; i < exercise.instructions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.instructions[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 24),

            if (onSelect != null)
              AppButton(
                label: 'Gunakan Exercise Ini',
                onPressed: () {
                  Navigator.pop(context);
                  onSelect!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
