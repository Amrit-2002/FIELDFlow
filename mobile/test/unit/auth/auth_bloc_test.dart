import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_flow/core/errors/exceptions.dart';
import 'package:field_flow/features/auth/domain/entities/user.dart';
import 'package:field_flow/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:field_flow/features/auth/domain/usecases/login_usecase.dart';
import 'package:field_flow/features/auth/domain/usecases/logout_usecase.dart';
import 'package:field_flow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_flow/features/auth/presentation/bloc/auth_event.dart';
import 'package:field_flow/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  const testUser = User(
    id: 'tech-uuid-1',
    name: 'Amrit Sharma',
    email: 'worker@example.com',
    role: 'FIELD_WORKER',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
  });

  group('AuthBloc Unit Tests', () {
    blocTest<AuthBloc, AuthState>(
      'CheckAuthStatus emits Authenticated when session is cached',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => testUser);
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'CheckAuthStatus emits Unauthenticated when no session exists',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginSubmitted emits [AuthLoading, Authenticated] upon successful login',
      build: () {
        when(() => mockLoginUseCase(email: 'worker@example.com', password: 'password123'))
            .thenAnswer((_) async => testUser);
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoginSubmitted(email: 'worker@example.com', password: 'password123')),
      expect: () => [
        AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginSubmitted emits [AuthLoading, AuthFailureState] upon invalid credentials',
      build: () {
        when(() => mockLoginUseCase(email: 'worker@example.com', password: 'wrong'))
            .thenThrow(const ServerException(message: 'Invalid email or password'));
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoginSubmitted(email: 'worker@example.com', password: 'wrong')),
      expect: () => [
        AuthLoading(),
        const AuthFailureState('Invalid email or password'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'LogoutRequested emits [AuthLoading, Unauthenticated]',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async {});
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
