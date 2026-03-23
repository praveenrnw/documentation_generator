import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_service.dart';

class OpenAiService implements AiService {
  late Dio _dio;
  String apiKey;
  String model;

  OpenAiService({required this.apiKey, this.model = 'gpt-4o'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  @override
  void updateConfig({String? baseUrl, String? model, String? apiKey}) {
    if (model != null) this.model = model;
    if (apiKey != null) {
      this.apiKey = apiKey;
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    }
  }

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get('/models');
      final models =
          (response.data['data'] as List)
              .map((m) => m['id'] as String)
              .where(
                (id) => id.startsWith('gpt-4o') || id.startsWith('gpt-4.1'),
              )
              .toList()
            ..sort();
      return models;
    } catch (_) {
      return ['gpt-4o', 'gpt-4o-mini', 'gpt-4.1'];
    }
  }

  @override
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/png;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 1024,
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  @override
  Future<String> generateText(String prompt) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 2048,
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }
}
