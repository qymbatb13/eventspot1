import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';

/// Round button: opens sign-in for a guest, the profile for a user.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;

        return Material(
          elevation: 3,
          shape: const CircleBorder(),
          color: user != null ? scheme.primary : scheme.surface,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => user == null
                ? context.push('/login')
                : _showProfile(context, user),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: user == null
                    ? const Icon(Icons.person_outline)
                    : Text(
                        _initial(user),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _initial(UserEntity user) {
    final name = user.name.trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  void _showProfile(BuildContext context, UserEntity user) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  _initial(user),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(user.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    Navigator.of(sheetContext).pop();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
