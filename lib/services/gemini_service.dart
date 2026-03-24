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
  Future<ConnectionResult> checkConnection() async {
    if (apiKey.isEmpty) {
      return const ConnectionResult.failure(
        'API key is empty. Enter your Gemini API key.',
      );
    }
    try {
      final response = await _dio.get(
        '/models',
        queryParameters: {'key': apiKey},
      );
      if (response.statusCode == 200) {
        return const ConnectionResult.success();
      }
      return ConnectionResult.failure(
        'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseBody = e.response?.data;

      // Extract API error message if available
      String? apiMessage;
      if (responseBody is Map) {
        apiMessage = responseBody['error']?['message'] as String?;
      }

      if (statusCode == 400) {
        return ConnectionResult.failure(
          'Bad request (400): ${apiMessage ?? 'Invalid API key. Check your Gemini key at https://aistudio.google.com'}',
        );
      }
      if (statusCode == 403) {
        return ConnectionResult.failure(
          'Forbidden (403): ${apiMessage ?? 'API key does not have permission. Enable the Generative Language API.'}',
        );
      }
      if (statusCode == 404) {
        return ConnectionResult.failure(
          'Not found (404): ${apiMessage ?? 'API endpoint not found. The API version may have changed.'}',
        );
      }
      if (statusCode != null) {
        return ConnectionResult.failure(
          'HTTP $statusCode: ${apiMessage ?? responseBody ?? e.message}',
        );
      }

      // No HTTP response — network-level error
      final rawError = e.error?.toString() ?? e.message ?? 'Unknown error';
      return ConnectionResult.failure(
        'Network error (${e.type.name}): $rawError',
      );
    } catch (e) {
      return ConnectionResult.failure('Unexpected error: $e');
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

    try {
      final response = await _dio.post(
        '/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
        },
      );

      return response.data['candidates'][0]['content']['parts'][0]['text']
          as String;
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  @override
  Future<String> generateText(String prompt) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String? apiMsg;
    if (body is Map) apiMsg = body['error']?['message'] as String?;

    if (status == 400) return 'Bad request: ${apiMsg ?? 'Check your API key.'}';
    if (status == 403)
      return 'Forbidden: ${apiMsg ?? 'API key lacks permission.'}';
    if (status == 404)
      return 'Model "$model" not found. Check the model name in Settings.';
    if (status == 429) return 'Quota exceeded. Check your Google AI billing.';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach Gemini API. Check your internet connection.';
    }
    if (status != null) return 'Gemini error ($status): ${apiMsg ?? body}';
    return 'Gemini request failed: ${e.message}';
  }
}
