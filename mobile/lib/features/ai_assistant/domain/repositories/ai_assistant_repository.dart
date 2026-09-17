import '../entities/troubleshooting_advice.dart';

abstract class AiAssistantRepository {
  Future<TroubleshootingAdvice> getTroubleshootingAdvice(String issueQuery);
}
