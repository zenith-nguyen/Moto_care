import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_controller.dart';
import '../application/session_state.dart';

class SignInIntegrationPage extends ConsumerStatefulWidget {
  const SignInIntegrationPage({super.key});

  @override
  ConsumerState<SignInIntegrationPage> createState() =>
      _SignInIntegrationPageState();
}

class _SignInIntegrationPageState extends ConsumerState<SignInIntegrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isLoading = sessionState is SessionAuthenticating;
    final failure = sessionState is SessionSignedOut
        ? sessionState.failure
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Moto Care')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nền tích hợp MotoCare',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Màn hình kỹ thuật tạm thời để kiểm tra API. '
                      'UI chính thức của nhóm sẽ thay thế màn hình này.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _identityController,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                        AutofillHints.telephoneNumber,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Email hoặc số điện thoại',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Vui lòng nhập email hoặc số điện thoại.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Mật khẩu phải có ít nhất 8 ký tự.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(isLoading),
                    ),
                    if (failure != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          failure.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : () => _submit(false),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập để kiểm tra'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(bool isLoading) {
    if (isLoading || !_formKey.currentState!.validate()) return;
    ref
        .read(sessionControllerProvider.notifier)
        .signIn(
          identity: _identityController.text,
          password: _passwordController.text,
        );
  }
}
