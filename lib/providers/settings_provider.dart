import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class SettingsProvider extends ChangeNotifier {
  AiProvider _aiProvider = AiProvider.ollama;
  String _ollamaUrl = 'http://localhost:11434';
  String _model = 'llava';
  String _apiKey = '';
  int _frameInterval = 3;
  int _maxFrames = 20;
  List<String> _availableModels = [];

  AiProvider get aiProvider => _aiProvider;
  String get ollamaUrl => _ollamaUrl;
  String get model => _model;
  String get apiKey => _apiKey;
  int get frameInterval => _frameInterval;
  int get maxFrames => _maxFrames;
  List<String> get availableModels => _availableModels;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aiProvider = AiProvider.values[prefs.getInt('ai_provider') ?? 0];
    _ollamaUrl = prefs.getString('ollama_url') ?? 'http://localhost:11434';
    _model = prefs.getString('model') ?? _aiProvider.defaultModel;
    _apiKey = prefs.getString('api_key') ?? '';
    _frameInterval = prefs.getInt('frame_interval') ?? 3;
    _maxFrames = prefs.getInt('max_frames') ?? 20;
    notifyListeners();
  }

  Future<void> setAiProvider(AiProvider provider) async {
    _aiProvider = provider;
    _model = provider.defaultModel;
    _availableModels = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_provider', provider.index);
    await prefs.setString('model', _model);
    notifyListeners();
  }

  Future<void> setOllamaUrl(String url) async {
    _ollamaUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_url', url);
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    _model = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('model', model);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    notifyListeners();
  }

  Future<void> setFrameInterval(int interval) async {
    _frameInterval = interval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('frame_interval', interval);
    notifyListeners();
  }

  Future<void> setMaxFrames(int max) async {
    _maxFrames = max;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_frames', max);
    notifyListeners();
  }

  void setAvailableModels(List<String> models) {
    _availableModels = models;
    notifyListeners();
  }
}
