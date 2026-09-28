import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/validators/auth_validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Создать аккаунт',
      subtitle: 'Сохраняйте события и находите их быстрее',
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
                  controller: _nameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: authInputDecoration(
                    label: 'Имя',
                    icon: Icons.person_outline,
                  ),
                  validator: AuthValidators.name,
                ),
                const SizedBox(height: 16),
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
                  textInputAction: TextInputAction.next,
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
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: authInputDecoration(
                    label: 'Повторите пароль',
                    icon: Icons.lock_outline,
                  ),
                  validator: (value) => AuthValidators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBox(message: error),
                ],
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Зарегистрироваться',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      isLoading ? null : () => context.pushReplacement('/login'),
                  child: const Text('Уже есть аккаунт? Войти'),
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
