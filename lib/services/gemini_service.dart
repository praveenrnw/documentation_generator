import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_service.dart';

class GeminiService implements AiService {
  late Dio _dio;
  String apiKey;
  String model;

  GeminiService({required this.apiKey, this.model = 'gemini-2.0-flash'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  @override
  void updateConfig({String? baseUrl, String? model, String? apiKey}) {
    if (model != null) this.model = model;
    if (apiKey != null) this.apiKey = apiKey;
  }

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        '/models',
        queryParameters: {'key': apiKey},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get(
        '/models',
        queryParameters: {'key': apiKey},
      );
      final models =
          (response.data['models'] as List)
              .map((m) => (m['name'] as String).replaceFirst('models/', ''))
              .where((name) => name.startsWith('gemini'))
              .toList()
            ..sort();
      return models;
    } catch (_) {
      return ['gemini-2.0-flash', 'gemini-2.5-flash', 'gemini-2.5-pro'];
    }
  }

  @override
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/png', 'data': base64Image},
              },
            ],
          },
        ],
      },
    );

    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  @override
  Future<String> generateText(String prompt) async {
    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      },
    );

    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }
}
