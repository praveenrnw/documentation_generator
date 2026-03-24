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
  Future<ConnectionResult> checkConnection() async {
    try {
      final response = await _dio.get('$baseUrl/api/tags');
      if (response.statusCode == 200) {
        return const ConnectionResult.success();
      }
      return ConnectionResult.failure(
        'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return ConnectionResult.failure(
          'Cannot connect to Ollama at $baseUrl. Is Ollama running? Try: ollama serve',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        return ConnectionResult.failure(
          'Connection timed out. Check if Ollama is running at $baseUrl',
        );
      }
      return ConnectionResult.failure('Connection failed: ${e.message}');
    } catch (e) {
      return ConnectionResult.failure('Unexpected error: $e');
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

    try {
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
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  @override
  Future<String> generateText(String prompt) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  String _describeError(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'Model "$model" not found. Pull it first: ollama pull $model';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot connect to Ollama at $baseUrl. Is it running? Try: ollama serve';
    }
    if (e.response != null) {
      final body = e.response?.data;
      final msg = body is Map ? body['error'] ?? body : body;
      return 'Ollama error (${e.response?.statusCode}): $msg';
    }
    return 'Ollama request failed: ${e.message}';
  }
}
