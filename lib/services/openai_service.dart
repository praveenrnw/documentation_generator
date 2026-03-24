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
  Future<ConnectionResult> checkConnection() async {
    if (apiKey.isEmpty) {
      return const ConnectionResult.failure(
        'API key is empty. Enter your OpenAI API key.',
      );
    }
    try {
      final response = await _dio.get('/models');
      if (response.statusCode == 200) {
        return const ConnectionResult.success();
      }
      return ConnectionResult.failure(
        'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const ConnectionResult.failure(
          'Invalid API key. Check your OpenAI key at https://platform.openai.com',
        );
      }
      if (e.response?.statusCode == 429) {
        return const ConnectionResult.failure(
          'Rate limited or quota exceeded. Check your OpenAI billing.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const ConnectionResult.failure(
          'Cannot reach OpenAI API. Check your internet connection.',
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

    try {
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
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  @override
  Future<String> generateText(String prompt) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Invalid API key. Check your OpenAI key.';
    if (status == 404)
      return 'Model "$model" not found. Check the model name in Settings.';
    if (status == 429)
      return 'Rate limit or quota exceeded. Check your OpenAI billing.';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach OpenAI API. Check your internet connection.';
    }
    if (e.response != null) {
      final body = e.response?.data;
      String? apiMsg;
      if (body is Map) apiMsg = (body['error'] as Map?)?['message'] as String?;
      return 'OpenAI error ($status): ${apiMsg ?? body}';
    }
    return 'OpenAI request failed: ${e.message}';
  }
}
