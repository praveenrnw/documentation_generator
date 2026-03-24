import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui.dart';
import '../providers/guide_provider.dart';
import 'editor_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with NavigationMixin {
  final ScrollController _logScrollController = ScrollController();
  bool _showLogs = true;

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<GuideProvider>().reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<GuideProvider>(
        builder: (context, guide, _) {
          if (guide.state == ProcessingState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushReplacementScreen(context, const EditorScreen());
            });
          }

          if (guide.state == ProcessingState.error) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.errorMessage ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      guide.reset();
                      Navigator.pop(context);
                    },
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _buildLogSection(context, guide)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 32),
                Text(
                  _getStateTitle(guide.state),
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  guide.statusMessage,
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(value: guide.progress),
                const SizedBox(height: 8),
                Text('${(guide.progress * 100).toInt()}%'),
                const SizedBox(height: 32),
                // Log section
                Expanded(child: _buildLogSection(context, guide)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStateTitle(ProcessingState state) {
    return switch (state) {
      ProcessingState.extractingFrames => 'Extracting Frames',
      ProcessingState.analyzingFrames => 'Analyzing with AI',
      ProcessingState.generatingGuide => 'Generating Guide',
      _ => 'Processing...',
    };
  }

  Widget _buildLogSection(BuildContext context, GuideProvider guide) {
    final logs = guide.logs;
    if (logs.isNotEmpty) _scrollToBottom();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showLogs = !_showLogs),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _showLogs
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Logs',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} entries',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showLogs) ...[
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Waiting for logs...',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final isError = logs[index].startsWith('Error');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isError
                                    ? Icons.error_outline
                                    : Icons.chevron_right,
                                size: 14,
                                color: isError
                                    ? context.colorScheme.error
                                    : context.colorScheme.primary.withOpacity(
                                        0.6,
                                      ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  logs[index],
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    height: 1.5,
                                    color: isError
                                        ? context.colorScheme.error
                                        : context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
