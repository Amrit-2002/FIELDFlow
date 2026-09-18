import 'package:equatable/equatable.dart';

class TroubleshootingAdvice extends Equatable {
  final String query;
  final List<String> possibleCauses;
  final List<String> recommendedChecks;
  final String safetyNotes;
  final DateTime timestamp;
  final String source; // e.g. 'Ollama Local LLM' or 'Field Diagnostic Expert'

  const TroubleshootingAdvice({
    required this.query,
    required this.possibleCauses,
    required this.recommendedChecks,
    required this.safetyNotes,
    required this.timestamp,
    this.source = 'Ollama Local LLM',
  });

  @override
  List<Object?> get props => [query, possibleCauses, recommendedChecks, safetyNotes, timestamp, source];
}

