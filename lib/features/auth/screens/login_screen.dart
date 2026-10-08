import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/theme/home_theme.dart';
import '../models/auth_validation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _submit() {
    FocusScope.of(context).unfocus();
    // Temporary DEV bypass: restore validation and authentication here later.
    context.go('/trang-chu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
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
                          const SizedBox(height: 40),
                          const _LoginHeader(),
                          const SizedBox(height: 32),
                          _buildForm(),
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
                                color: AppTheme.mutedText,
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

  Widget _buildForm() {
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
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 52),
            FilledButton(onPressed: _submit, child: const Text('Đăng nhập')),
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Logo_motocare.png',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        semanticLabel: 'Logo Moto Care',
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
