import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/theme/home_theme.dart';
import '../models/auth_validation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Connect the recovery API before reporting that a code was sent.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Tính năng gửi mã xác thực qua email sẽ sớm được hỗ trợ.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        foregroundColor: HomeColors.text,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.link,
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
                    child: Center(
                      child: Image.asset(
                        'assets/images/Logo_motocare.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo Moto Care',
                      ),
                    ),
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
                              backgroundColor: AppTheme.link,
                              disabledBackgroundColor: HomeColors.redSelected,
                              disabledForegroundColor: AppTheme.mutedText,
                            ),
                            onPressed: AuthValidation.email(_email) == null
                                ? _submit
                                : null,
                            child: const Text('Nhận mã xác thực'),
                          ),
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
