import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui.dart';
import '../providers/guide_provider.dart';
import 'editor_screen.dart';

class ProcessingScreen extends StatelessWidget with NavigationMixin {
  const ProcessingScreen({super.key});

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                ],
              ),
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
}
