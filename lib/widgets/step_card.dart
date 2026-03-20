import 'package:flutter/material.dart';
import '../models/guide_step.dart';

class StepCard extends StatelessWidget {
  final GuideStep step;
  final int stepNumber;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onDelete;

  const StepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text('$stepNumber')),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: step.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Step title...',
                    ),
                    onChanged: onTitleChanged,
                  ),
                ),
                const Icon(Icons.drag_handle),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            if (step.screenshot != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  step.screenshot!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              initialValue: step.description,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Step description...',
                isDense: true,
              ),
              onChanged: onDescriptionChanged,
            ),
            if (step.timestamp != Duration.zero)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Timestamp: ${_formatDuration(step.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
