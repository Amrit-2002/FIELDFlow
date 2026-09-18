import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Profile'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Avatar & Name Card
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'T',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'Field Technician',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.role ?? 'FIELD_WORKER',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section: Field Capabilities
              const Text(
                'SYSTEM & STORAGE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sync, color: AppColors.accent),
                      title: const Text('Sync Center'),
                      subtitle: const Text('Inspect offline queue, retry failed & resolve conflicts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/sync-center'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.smart_toy_outlined, color: AppColors.amber),
                      title: const Text('AI Service Assistant'),
                      subtitle: const Text('Diagnose field equipment faults with local Ollama'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/ai-assistant'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.success),
                      title: const Text('Notifications'),
                      subtitle: const Text('Job dispatch alerts and schedule reminders'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign Out Button
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

