import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ollama_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;
  bool _isConnected = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.ollamaUrl);
    _modelController = TextEditingController(text: settings.model);
    _checkConnection();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final settings = context.read<SettingsProvider>();
    final service = OllamaService(baseUrl: settings.ollamaUrl);

    final connected = await service.checkConnection();
    if (connected) {
      final models = await service.listModels();
      if (mounted) {
        settings.setAvailableModels(models);
      }
    }

    if (mounted) {
      setState(() {
        _isConnected = connected;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ollama Connection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Ollama URL',
                  hintText: 'http://localhost:11434',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                ),
                onSubmitted: (value) {
                  settings.setOllamaUrl(value);
                  _checkConnection();
                },
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () {
                  settings.setOllamaUrl(_urlController.text);
                  _checkConnection();
                },
                child: const Text('Test Connection'),
              ),
              const SizedBox(height: 24),

              Text('AI Model', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (settings.availableModels.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      settings.availableModels.contains(settings.model)
                      ? settings.model
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Vision Model',
                    border: OutlineInputBorder(),
                  ),
                  items: settings.availableModels
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) settings.setModel(value);
                  },
                )
              else
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model Name',
                    hintText: 'llava',
                    border: OutlineInputBorder(),
                    helperText: 'Connect to Ollama to see available models',
                  ),
                  onSubmitted: (value) => settings.setModel(value),
                ),
              const SizedBox(height: 24),

              Text(
                'Frame Extraction',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Frame Interval'),
                subtitle: Text(
                  'Extract a frame every ${settings.frameInterval} seconds',
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.frameInterval.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${settings.frameInterval}s',
                    onChanged: (value) =>
                        settings.setFrameInterval(value.round()),
                  ),
                ),
              ),
              ListTile(
                title: const Text('Max Frames'),
                subtitle: Text('Analyze up to ${settings.maxFrames} frames'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.maxFrames.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${settings.maxFrames}',
                    onChanged: (value) => settings.setMaxFrames(value.round()),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Setup Guide',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Install Ollama: https://ollama.com\n'
                        '2. Pull a vision model: ollama pull llava\n'
                        '3. Start Ollama: ollama serve\n'
                        '4. Install ffmpeg for video processing:\n'
                        '   macOS: brew install ffmpeg\n'
                        '   Linux: sudo apt install ffmpeg',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
