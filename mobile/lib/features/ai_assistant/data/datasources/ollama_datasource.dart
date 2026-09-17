import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/troubleshooting_advice.dart';

class OllamaDataSource {
  final Dio _dio;

  OllamaDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.ollamaBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  Future<TroubleshootingAdvice> getAdvice(String issueQuery) async {
    final prompt = '''
You are a senior field service engineering AI assistant.
A field technician reports this issue: "$issueQuery"

Return ONLY a valid JSON object with EXACTLY this structure:
{
  "possibleCauses": ["cause 1", "cause 2", "cause 3"],
  "recommendedChecks": ["check 1", "check 2", "check 3"],
  "safetyNotes": "safety warning for technician"
}
Do not return Markdown tags or other text. Only JSON.
''';

    final response = await _dio.post(
      '/api/generate',
      data: {
        'model': 'llama3',
        'prompt': prompt,
        'stream': false,
        'format': 'json',
      },
    );

    final rawJson = response.data['response'] as String;
    final parsed = jsonDecode(rawJson) as Map<String, dynamic>;

    return TroubleshootingAdvice(
      query: issueQuery,
      possibleCauses: List<String>.from(parsed['possibleCauses'] ?? []),
      recommendedChecks: List<String>.from(parsed['recommendedChecks'] ?? []),
      safetyNotes: parsed['safetyNotes'] as String? ??
          'Do not perform electrical or mechanical work without appropriate safety procedures.',
      timestamp: DateTime.now(),
      source: 'Ollama Local LLM',
    );
  }
}
