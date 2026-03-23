import 'dart:typed_data';

enum AiProvider { ollama, openAi, gemini }

extension AiProviderX on AiProvider {
  String get displayName => switch (this) {
    AiProvider.ollama => 'Ollama (Local)',
    AiProvider.openAi => 'OpenAI',
    AiProvider.gemini => 'Google Gemini',
  };

  String get defaultModel => switch (this) {
    AiProvider.ollama => 'llava',
    AiProvider.openAi => 'gpt-4o',
    AiProvider.gemini => 'gemini-2.0-flash',
  };

  bool get requiresApiKey => this != AiProvider.ollama;
}

abstract class AiService {
  Future<bool> checkConnection();
  Future<List<String>> listModels();
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  });
  Future<String> generateText(String prompt);
  void updateConfig({String? baseUrl, String? model, String? apiKey});
}
