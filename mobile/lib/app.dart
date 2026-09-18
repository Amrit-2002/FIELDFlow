import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/network/network_info.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/network_status_bar.dart';
import 'features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_details_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';
import 'injection/dependency_injection.dart';

class FieldFlowApp extends StatefulWidget {
  const FieldFlowApp({super.key});

  @override
  State<FieldFlowApp> createState() => _FieldFlowAppState();
}

class _FieldFlowAppState extends State<FieldFlowApp> {
  late final AuthBloc _authBloc;
  late final TaskBloc _taskBloc;
  late final TaskDetailsBloc _taskDetailsBloc;
  late final SyncBloc _syncBloc;
  late final AiAssistantBloc _aiAssistantBloc;
  late final GoRouter _router;

  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(CheckAuthStatus());
    _taskBloc = sl<TaskBloc>()..add(LoadTasks());
    _taskDetailsBloc = sl<TaskDetailsBloc>();
    _syncBloc = sl<SyncBloc>()..add(WatchSyncQueue());
    _aiAssistantBloc = sl<AiAssistantBloc>();

    _router = createRouter(_authBloc);

    // Monitor connectivity
    sl<NetworkInfo>().onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<TaskBloc>.value(value: _taskBloc),
        BlocProvider<TaskDetailsBloc>.value(value: _taskDetailsBloc),
        BlocProvider<SyncBloc>.value(value: _syncBloc),
        BlocProvider<AiAssistantBloc>.value(value: _aiAssistantBloc),
      ],
      child: MaterialApp.router(
        title: 'FIELDFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          return Column(
            children: [
              if (!_isOnline)
                const NetworkStatusBar(status: NetworkStatus.offline),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _taskBloc.close();
    _taskDetailsBloc.close();
    _syncBloc.close();
    _aiAssistantBloc.close();
    super.dispose();
  }
}

