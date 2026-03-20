import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guide_provider.dart';
import '../widgets/step_card.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GuideProvider>(
      builder: (context, provider, _) {
        final guide = provider.currentGuide;
        if (guide == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editor')),
            body: const Center(child: Text('No guide loaded')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Guide'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                provider.reset();
                Navigator.pop(context);
              },
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleExport(context, provider, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Export as PDF'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'markdown',
                    child: ListTile(
                      leading: Icon(Icons.code),
                      title: Text('Export as Markdown'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: guide.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    labelText: 'Guide Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: provider.updateGuideTitle,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: guide.description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: provider.updateGuideDescription,
                ),
                const SizedBox(height: 16),
                Text(
                  'Steps (${guide.steps.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: guide.steps.length,
                    onReorder: provider.reorderSteps,
                    itemBuilder: (context, index) {
                      final step = guide.steps[index];
                      return StepCard(
                        key: ValueKey(step.id),
                        step: step,
                        stepNumber: index + 1,
                        onTitleChanged: (value) =>
                            provider.updateStepTitle(step.id, value),
                        onDescriptionChanged: (value) =>
                            provider.updateStepDescription(step.id, value),
                        onDelete: () => provider.deleteStep(step.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    GuideProvider provider,
    String format,
  ) async {
    try {
      String path;
      if (format == 'pdf') {
        path = await provider.exportToPdf();
      } else {
        path = await provider.exportToMarkdown();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $path'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => Process.run('open', [path]),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}
