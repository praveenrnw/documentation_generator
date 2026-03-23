import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_service.dart';

class OllamaService implements AiService {
  late Dio _dio;
  String baseUrl;
  String model;

  OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llava',
  }) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  @override
  void updateConfig({String? baseUrl, String? model, String? apiKey}) {
    if (baseUrl != null) this.baseUrl = baseUrl;
    if (model != null) this.model = model;
  }

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('$baseUrl/api/tags');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get('$baseUrl/api/tags');
      final models = (response.data['models'] as List)
          .map((m) => m['name'] as String)
          .toList();
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await _dio.post(
      '$baseUrl/api/chat',
      data: {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
            'images': [base64Image],
          },
        ],
        'stream': false,
      },
    );

    return response.data['message']['content'] as String;
  }

  @override
  Future<String> generateText(String prompt) async {
    final response = await _dio.post(
      '$baseUrl/api/chat',
      data: {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'stream': false,
      },
    );

    return response.data['message']['content'] as String;
  }
}
