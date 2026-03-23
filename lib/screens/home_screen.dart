import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/ui.dart';
import '../providers/guide_provider.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget with NavigationMixin {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DocGen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => pushScreen(context, const SettingsScreen()),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 80,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Documentation Generator',
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Upload a video or screenshots and let AI\ngenerate a user guide for you.',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _pickVideo(context),
                icon: const Icon(Icons.video_file),
                label: const Text('Upload Video'),
                style: FilledButton.styleFrom(minimumSize: const Size(250, 56)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImages(context),
                icon: const Icon(Icons.image),
                label: const Text('Upload Screenshots'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(250, 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      final guide = context.read<GuideProvider>();
      guide.reset();
      guide.processVideo(result.files.single.path!);
      pushScreen(context, const ProcessingScreen());
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final images = <Uint8List>[];
      for (final file in result.files) {
        if (file.path != null) {
          images.add(await File(file.path!).readAsBytes());
        }
      }

      if (images.isNotEmpty) {
        if (!context.mounted) return;
        final guide = context.read<GuideProvider>();
        guide.reset();
        guide.processImages(images);
        pushScreen(context, const ProcessingScreen());
      }
    }
  }
}
