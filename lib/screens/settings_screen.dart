import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/ollama_service.dart';
import '../services/openai_service.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;
  bool _isConnected = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.ollamaUrl);
    _modelController = TextEditingController(text: settings.model);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _checkConnection();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  AiService _createService(SettingsProvider settings) {
    return switch (settings.aiProvider) {
      AiProvider.ollama => OllamaService(baseUrl: settings.ollamaUrl),
      AiProvider.openAi => OpenAiService(apiKey: settings.apiKey),
      AiProvider.gemini => GeminiService(apiKey: settings.apiKey),
    };
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final settings = context.read<SettingsProvider>();
    final service = _createService(settings);

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
              // --- AI Provider Selection ---
              Text('AI Provider', style: context.textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<AiProvider>(
                segments: AiProvider.values
                    .map(
                      (p) =>
                          ButtonSegment(value: p, label: Text(p.displayName)),
                    )
                    .toList(),
                selected: {settings.aiProvider},
                onSelectionChanged: (selected) {
                  settings.setAiProvider(selected.first);
                  _modelController.text = selected.first.defaultModel;
                  _isConnected = false;
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // --- API Key (for cloud providers) ---
              if (settings.aiProvider.requiresApiKey) ...[
                Text('API Key', style: context.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '${settings.aiProvider.displayName} API Key',
                    hintText: 'Enter your API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        settings.setApiKey(_apiKeyController.text);
                        _checkConnection();
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    settings.setApiKey(value);
                    _checkConnection();
                  },
                ),
                const SizedBox(height: 24),
              ],

              // --- Ollama URL (only for Ollama) ---
              if (settings.aiProvider == AiProvider.ollama) ...[
                Text('Ollama Connection', style: context.textTheme.titleMedium),
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
              ],

              // --- Test Connection Button ---
              FilledButton.tonal(
                onPressed: () {
                  if (settings.aiProvider == AiProvider.ollama) {
                    settings.setOllamaUrl(_urlController.text);
                  } else {
                    settings.setApiKey(_apiKeyController.text);
                  }
                  _checkConnection();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isChecking)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Text(_isChecking ? 'Checking...' : 'Test Connection'),
                  ],
                ),
              ),
              if (!_isChecking)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _isConnected ? 'Connected' : 'Not connected',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // --- AI Model ---
              Text('AI Model', style: context.textTheme.titleMedium),
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
                  decoration: InputDecoration(
                    labelText: 'Model Name',
                    hintText: settings.aiProvider.defaultModel,
                    border: const OutlineInputBorder(),
                    helperText: 'Connect to see available models',
                  ),
                  onSubmitted: (value) => settings.setModel(value),
                ),
              const SizedBox(height: 24),

              // --- Frame Extraction ---
              Text('Frame Extraction', style: context.textTheme.titleMedium),
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

              // --- Setup Guide ---
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
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Setup Guide',
                            style: context.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (settings.aiProvider == AiProvider.ollama)
                        const Text(
                          '1. Install Ollama: https://ollama.com\n'
                          '2. Pull a vision model: ollama pull llava\n'
                          '3. Start Ollama: ollama serve\n'
                          '4. Install ffmpeg for video processing:\n'
                          '   macOS: brew install ffmpeg\n'
                          '   Linux: sudo apt install ffmpeg',
                        )
                      else if (settings.aiProvider == AiProvider.openAi)
                        const Text(
                          '1. Get an API key from https://platform.openai.com\n'
                          '2. Paste your API key above\n'
                          '3. Select a vision model (gpt-4o recommended)\n'
                          '4. Install ffmpeg for video processing:\n'
                          '   macOS: brew install ffmpeg\n'
                          '   Linux: sudo apt install ffmpeg',
                        )
                      else
                        const Text(
                          '1. Get an API key from https://aistudio.google.com\n'
                          '2. Paste your API key above\n'
                          '3. Select a Gemini model\n'
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
