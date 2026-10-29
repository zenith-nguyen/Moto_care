import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/widgets/revo_logo.dart';
import '../application/session_controller.dart';
import '../application/session_state.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../models/auth_validation.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(sessionControllerProvider.notifier)
        .signIn(
          identity: _identityController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isLoading = sessionState is SessionAuthenticating;
    final failure = sessionState is SessionSignedOut
        ? sessionState.failure
        : null;
    final providerApp = isProviderOnlyRuntime(
      ref.watch(runtimeAllowedRolesProvider),
    );

    return AuthScaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        automaticallyImplyLeading: !providerApp,
        leading: providerApp
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/welcome');
                  }
                },
              ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 576
                ? (constraints.maxWidth - 480) / 2
                : (constraints.maxWidth * 0.09).clamp(24.0, 48.0);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    64,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          const _LoginHeader(),
                          const SizedBox(height: 32),
                          _buildForm(isLoading, failure?.message),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          children: [
                            const Text(
                              'Chưa có tài khoản?',
                              style: TextStyle(
                                color: AuthColors.secondary,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/register'),
                              child: const Text('Đăng ký'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading, String? failureMessage) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel('Email hoặc số điện thoại'),
            const SizedBox(height: 8),
            Semantics(
              label: 'Email hoặc số điện thoại',
              child: TextFormField(
                key: const ValueKey('login-identifier'),
                controller: _identityController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Nhập email hoặc số điện thoại của bạn',
                ),
                validator: AuthValidation.loginIdentifier,
              ),
            ),
            const SizedBox(height: 26),
            const _FieldLabel('Mật khẩu'),
            const SizedBox(height: 8),
            Semantics(
              label: 'Mật khẩu',
              child: TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu của bạn',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: FaIcon(
                        _obscurePassword
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.eye,
                        size: 22,
                        color: const Color(0xFF787878),
                      ),
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập mật khẩu'
                    : null,
                onFieldSubmitted: (_) {
                  if (!isLoading) _submit();
                },
              ),
            ),
            if (failureMessage != null) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(
                  failureMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 52),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends ConsumerWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(runtimeAllowedRolesProvider);
    final providerApp = isProviderOnlyRuntime(roles);
    return SizedBox(
      height: 132,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RevoLogo(),
          if (providerApp) ...[
            const SizedBox(height: 12),
            const Text(
              'Dành cho Thợ cứu hộ',
              style: TextStyle(
                color: AuthColors.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 18, height: 1.3));
  }
}
