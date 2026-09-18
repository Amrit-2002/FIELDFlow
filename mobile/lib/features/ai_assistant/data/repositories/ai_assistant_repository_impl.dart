import '../../domain/entities/troubleshooting_advice.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ollama_datasource.dart';
import '../datasources/rule_based_field_expert.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final OllamaDataSource _ollamaDataSource;

  AiAssistantRepositoryImpl({OllamaDataSource? ollamaDataSource})
      : _ollamaDataSource = ollamaDataSource ?? OllamaDataSource();

  @override
  Future<TroubleshootingAdvice> getTroubleshootingAdvice(String issueQuery) async {
    try {
      // Try local Ollama instance first
      return await _ollamaDataSource.getAdvice(issueQuery);
    } catch (_) {
      // Graceful fallback to offline rule-based field expert
      await Future.delayed(const Duration(milliseconds: 600)); // Smooth UX transition
      return RuleBasedFieldExpert.diagnose(issueQuery);
    }
  }
}

