import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/guide_step.dart';
import '../models/user_guide.dart';
import '../services/ollama_service.dart';
import '../services/video_processing_service.dart';
import '../services/export_service.dart';
import 'settings_provider.dart';

enum ProcessingState {
  idle,
  extractingFrames,
  analyzingFrames,
  generatingGuide,
  done,
  error,
}

class GuideProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  late OllamaService _ollamaService;
  final VideoProcessingService _videoService = VideoProcessingService();
  final ExportService _exportService = ExportService();
  final _uuid = const Uuid();

  ProcessingState _state = ProcessingState.idle;
  String _statusMessage = '';
  double _progress = 0;
  UserGuide? _currentGuide;
  String? _errorMessage;

  ProcessingState get state => _state;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  UserGuide? get currentGuide => _currentGuide;
  String? get errorMessage => _errorMessage;

  GuideProvider(this._settings) {
    _ollamaService = OllamaService(
      baseUrl: _settings.ollamaUrl,
      model: _settings.model,
    );
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _ollamaService.updateConfig(
      baseUrl: _settings.ollamaUrl,
      model: _settings.model,
    );
  }

  Future<void> processVideo(String videoPath) async {
    try {
      _state = ProcessingState.extractingFrames;
      _statusMessage = 'Extracting frames from video...';
      _progress = 0;
      notifyListeners();

      final frames = await _videoService.extractFrames(
        videoPath: videoPath,
        intervalSeconds: _settings.frameInterval,
        maxFrames: _settings.maxFrames,
      );

      if (frames.isEmpty) {
        throw Exception('No frames could be extracted from the video');
      }

      await _analyzeAndBuildGuide(frames);
    } catch (e) {
      _state = ProcessingState.error;
      _errorMessage = e.toString();
      _statusMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> processImages(List<Uint8List> images) async {
    try {
      _state = ProcessingState.analyzingFrames;
      _statusMessage = 'Preparing images...';
      _progress = 0;
      notifyListeners();

      final frames = images
          .asMap()
          .entries
          .map(
            (e) => ExtractedFrame(
              bytes: e.value,
              timestamp: Duration(seconds: e.key * 3),
              index: e.key,
            ),
          )
          .toList();

      await _analyzeAndBuildGuide(frames);
    } catch (e) {
      _state = ProcessingState.error;
      _errorMessage = e.toString();
      _statusMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> _analyzeAndBuildGuide(List<ExtractedFrame> frames) async {
    _state = ProcessingState.analyzingFrames;
    notifyListeners();

    final analyses = <Map<String, dynamic>>[];

    for (int i = 0; i < frames.length; i++) {
      _statusMessage = 'Analyzing frame ${i + 1} of ${frames.length}...';
      _progress = i / frames.length;
      notifyListeners();

      final analysis = await _ollamaService.analyzeImage(
        imageBytes: frames[i].bytes,
        prompt: _buildFrameAnalysisPrompt(i, frames.length),
      );

      analyses.add({
        'index': i,
        'timestamp': frames[i].timestamp.inSeconds,
        'analysis': analysis,
      });
    }

    _state = ProcessingState.generatingGuide;
    _statusMessage = 'Generating user guide...';
    _progress = 0.9;
    notifyListeners();

    final guideJson = await _ollamaService.generateText(
      _buildGuideCompilationPrompt(analyses),
    );

    final guide = _parseGuideResponse(guideJson, frames);
    _currentGuide = guide;
    _state = ProcessingState.done;
    _statusMessage = 'Guide generated successfully!';
    _progress = 1.0;
    notifyListeners();
  }

  String _buildFrameAnalysisPrompt(int frameIndex, int totalFrames) {
    return 'Analyze this screenshot (frame ${frameIndex + 1} of $totalFrames) '
        'from a software application or workflow.\n\n'
        'Describe:\n'
        '1. What screen, page, or interface is shown\n'
        '2. What UI elements are visible (buttons, forms, menus, dialogs)\n'
        '3. What action the user appears to be performing\n'
        '4. Any important text visible on screen\n\n'
        'Be concise and focus on what matters for a user guide.';
  }

  String _buildGuideCompilationPrompt(List<Map<String, dynamic>> analyses) {
    final analysisText = analyses
        .map(
          (a) =>
              'Frame ${a['index'] + 1} (at ${a['timestamp']}s):\n${a['analysis']}',
        )
        .join('\n\n---\n\n');

    return 'Based on the following sequence of screenshot analyses from a '
        'software application, create a structured step-by-step user guide.\n\n'
        '$analysisText\n\n'
        'Create a user guide in this exact JSON format '
        '(respond with ONLY the JSON, no other text):\n'
        '{\n'
        '  "title": "Guide title based on the workflow shown",\n'
        '  "description": "Brief overview of what this guide covers",\n'
        '  "steps": [\n'
        '    {\n'
        '      "step_number": 1,\n'
        '      "title": "Short action title",\n'
        '      "description": "Detailed instruction telling the user what to do",\n'
        '      "frame_index": 0\n'
        '    }\n'
        '  ]\n'
        '}\n\n'
        'Rules:\n'
        '- Merge similar/duplicate frames into single steps\n'
        '- Focus on clear, actionable instructions\n'
        '- Each step should map to a frame_index (0-based) for the screenshot\n'
        '- Write as if instructing a new user';
  }

  UserGuide _parseGuideResponse(String response, List<ExtractedFrame> frames) {
    try {
      String jsonStr = response;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final steps = (data['steps'] as List).asMap().entries.map((entry) {
        final step = entry.value as Map<String, dynamic>;
        final frameIndex = (step['frame_index'] as int?) ?? entry.key;

        return GuideStep(
          id: _uuid.v4(),
          title: step['title'] as String? ?? 'Step ${entry.key + 1}',
          description: step['description'] as String? ?? '',
          screenshot: frameIndex < frames.length
              ? frames[frameIndex].bytes
              : null,
          timestamp: frameIndex < frames.length
              ? frames[frameIndex].timestamp
              : Duration.zero,
          order: entry.key,
        );
      }).toList();

      return UserGuide(
        id: _uuid.v4(),
        title: data['title'] as String? ?? 'Untitled Guide',
        description: data['description'] as String? ?? '',
        steps: steps,
      );
    } catch (_) {
      final steps = frames
          .asMap()
          .entries
          .map(
            (entry) => GuideStep(
              id: _uuid.v4(),
              title: 'Step ${entry.key + 1}',
              description: response,
              screenshot: entry.value.bytes,
              timestamp: entry.value.timestamp,
              order: entry.key,
            ),
          )
          .toList();

      return UserGuide(
        id: _uuid.v4(),
        title: 'Generated Guide',
        description: 'Guide generated from video analysis',
        steps: steps,
      );
    }
  }

  void updateStepTitle(String stepId, String title) {
    if (_currentGuide == null) return;
    final index = _currentGuide!.steps.indexWhere((s) => s.id == stepId);
    if (index != -1) {
      _currentGuide!.steps[index].title = title;
      _currentGuide!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  void updateStepDescription(String stepId, String description) {
    if (_currentGuide == null) return;
    final index = _currentGuide!.steps.indexWhere((s) => s.id == stepId);
    if (index != -1) {
      _currentGuide!.steps[index].description = description;
      _currentGuide!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  void updateGuideTitle(String title) {
    if (_currentGuide != null) {
      _currentGuide!.title = title;
      _currentGuide!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  void updateGuideDescription(String description) {
    if (_currentGuide != null) {
      _currentGuide!.description = description;
      _currentGuide!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  void deleteStep(String stepId) {
    if (_currentGuide == null) return;
    _currentGuide!.steps.removeWhere((s) => s.id == stepId);
    for (int i = 0; i < _currentGuide!.steps.length; i++) {
      _currentGuide!.steps[i].order = i;
    }
    _currentGuide!.updatedAt = DateTime.now();
    notifyListeners();
  }

  void reorderSteps(int oldIndex, int newIndex) {
    if (_currentGuide == null) return;
    if (newIndex > oldIndex) newIndex--;
    final step = _currentGuide!.steps.removeAt(oldIndex);
    _currentGuide!.steps.insert(newIndex, step);
    for (int i = 0; i < _currentGuide!.steps.length; i++) {
      _currentGuide!.steps[i].order = i;
    }
    _currentGuide!.updatedAt = DateTime.now();
    notifyListeners();
  }

  Future<String> exportToPdf() async {
    if (_currentGuide == null) throw Exception('No guide to export');
    return _exportService.exportToPdf(_currentGuide!);
  }

  Future<String> exportToMarkdown() async {
    if (_currentGuide == null) throw Exception('No guide to export');
    return _exportService.exportToMarkdown(_currentGuide!);
  }

  void reset() {
    _state = ProcessingState.idle;
    _statusMessage = '';
    _progress = 0;
    _currentGuide = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
