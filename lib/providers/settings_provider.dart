import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _ollamaUrl = 'http://localhost:11434';
  String _model = 'llava';
  int _frameInterval = 3;
  int _maxFrames = 20;
  List<String> _availableModels = [];

  String get ollamaUrl => _ollamaUrl;
  String get model => _model;
  int get frameInterval => _frameInterval;
  int get maxFrames => _maxFrames;
  List<String> get availableModels => _availableModels;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ollamaUrl = prefs.getString('ollama_url') ?? 'http://localhost:11434';
    _model = prefs.getString('model') ?? 'llava';
    _frameInterval = prefs.getInt('frame_interval') ?? 3;
    _maxFrames = prefs.getInt('max_frames') ?? 20;
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
