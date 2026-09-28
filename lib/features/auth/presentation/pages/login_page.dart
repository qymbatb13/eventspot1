import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/validators/auth_validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  /// The BLoC error is shown only after a submit on THIS page, so an
  /// error from a previous attempt doesn't pop up on entry.
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'С возвращением',
      subtitle: 'Войдите, чтобы сохранять любимые события',
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (_, current) => current is Authenticated,
        listener: (context, _) => leaveAuthFlow(context),
        builder: (context, state) {
          final isLoading = state is AuthInProgress;
          final error =
              _submitted && state is Unauthenticated ? state.error : null;

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: authInputDecoration(
                    label: 'Email',
                    icon: Icons.mail_outline,
                  ),
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: authInputDecoration(
                    label: 'Пароль',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Введите пароль' : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBox(message: error),
                ],
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Войти',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      isLoading ? null : () => context.pushReplacement('/register'),
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => leaveAuthFlow(context),
                  child: const Text('Продолжить без входа'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
