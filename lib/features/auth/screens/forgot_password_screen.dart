import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/widgets/revo_logo.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../models/auth_validation.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _email = '';
  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _failureMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _failureMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Nếu email tồn tại, mã xác thực đã được gửi.'),
          ),
        );
    } catch (error) {
      if (mounted) setState(() => _failureMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.trim().isEmpty ||
        _newPasswordController.text.length < 8) {
      setState(() {
        _failureMessage = 'Nhập mã xác thực và mật khẩu mới ít nhất 8 ký tự.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _failureMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _email,
            code: _codeController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
      context.go('/login');
    } catch (error) {
      if (mounted) setState(() => _failureMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        foregroundColor: AuthColors.text,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AuthColors.primary,
            size: 24,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'Quên mật khẩu',
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 576
                ? (constraints.maxWidth - 480) / 2
                : (constraints.maxWidth * 0.11).clamp(24.0, 48.0);
            final logoHeight = (MediaQuery.sizeOf(context).height * 0.26).clamp(
              176.0,
              232.0,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: logoHeight,
                    child: Center(child: const RevoLogo()),
                  ),
                  const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vui lòng nhập email mà bạn đã đăng ký tài khoản.',
                    style: TextStyle(fontSize: 16, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Email', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Email',
                            child: TextFormField(
                              enabled: !_isSubmitting && !_codeSent,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Nhập email của bạn',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF707070),
                                ),
                              ),
                              validator: AuthValidation.email,
                              onChanged: (value) =>
                                  setState(() => _email = value),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Mã xác thực sẽ được gửi qua email.',
                            style: TextStyle(fontSize: 16, height: 1.45),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AuthColors.primary,
                              disabledBackgroundColor: AuthColors.disabled,
                              disabledForegroundColor: AuthColors.secondary,
                            ),
                            onPressed:
                                AuthValidation.email(_email) == null &&
                                    !_isSubmitting &&
                                    !_codeSent
                                ? _submit
                                : null,
                            child: _isSubmitting && !_codeSent
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Nhận mã xác thực'),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _codeController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mã xác thực',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPasswordController,
                              enabled: !_isSubmitting,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Mật khẩu mới',
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _resetPassword,
                              child: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Đặt mật khẩu mới'),
                            ),
                          ],
                          if (_failureMessage != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _failureMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
