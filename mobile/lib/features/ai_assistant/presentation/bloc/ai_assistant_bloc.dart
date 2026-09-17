import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/troubleshooting_advice.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

// Events
abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();
  @override
  List<Object?> get props => [];
}

class RequestTroubleshootingAdvice extends AiAssistantEvent {
  final String query;
  const RequestTroubleshootingAdvice(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearAiAssistantHistory extends AiAssistantEvent {}

// States
abstract class AiAssistantState extends Equatable {
  const AiAssistantState();
  @override
  List<Object?> get props => [];
}

class AiAssistantInitial extends AiAssistantState {}

class AiAssistantLoading extends AiAssistantState {
  final String query;
  const AiAssistantLoading(this.query);
  @override
  List<Object?> get props => [query];
}

class AiAssistantLoaded extends AiAssistantState {
  final List<TroubleshootingAdvice> history;
  const AiAssistantLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

class AiAssistantError extends AiAssistantState {
  final String message;
  const AiAssistantError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final AiAssistantRepository _repository;
  final List<TroubleshootingAdvice> _history = [];

  AiAssistantBloc({required AiAssistantRepository repository})
      : _repository = repository,
        super(AiAssistantInitial()) {
    on<RequestTroubleshootingAdvice>(_onRequestAdvice);
    on<ClearAiAssistantHistory>(_onClearHistory);
  }

  Future<void> _onRequestAdvice(RequestTroubleshootingAdvice event, Emitter<AiAssistantState> emit) async {
    if (event.query.trim().isEmpty) return;

    emit(AiAssistantLoading(event.query));
    try {
      final advice = await _repository.getTroubleshootingAdvice(event.query.trim());
      _history.insert(0, advice);
      emit(AiAssistantLoaded(List.unmodifiable(_history)));
    } catch (e) {
      emit(AiAssistantError(e.toString()));
    }
  }

  void _onClearHistory(ClearAiAssistantHistory event, Emitter<AiAssistantState> emit) {
    _history.clear();
    emit(AiAssistantInitial());
  }
}
