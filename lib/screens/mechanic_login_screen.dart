import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ui.dart';
import 'approved_redirect_dialog.dart';
import 'mechanic_forgot_password_screen.dart';
import 'mechanic_pending_approval_screen.dart';
import 'mechanic_register_screen.dart';
import 'mechanic_rejected_screen.dart';
import 'terms_and_commitment_screen.dart';

class MechanicLoginScreen extends StatefulWidget {
  const MechanicLoginScreen({super.key});

  @override
  State<MechanicLoginScreen> createState() => _MechanicLoginScreenState();
}

class _MechanicLoginScreenState extends State<MechanicLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final status = MockData.accountStatusFor(_idController.text);
    final navigator = Navigator.of(context);
    switch (status) {
      case AccountStatus.pending:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MechanicPendingApprovalScreen()),
          (_) => false,
        );
      case AccountStatus.rejected:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MechanicRejectedScreen()),
          (_) => false,
        );
      case AccountStatus.approved:
        final goToMechanic = await showApprovedRedirectDialog(context);
        if (goToMechanic != true || !mounted) return;
        appState.logout(); // reset trạng thái phiên trước
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MechanicShell()),
          (_) => false,
        );
    }
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsAndCommitmentScreen(readOnly: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Brand(),
                        const SizedBox(height: 44),
                        const FieldLabel('Email hoặc số điện thoại'),
                        TextFormField(
                          controller: _idController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                          style: appText(15),
                          decoration: const InputDecoration(hintText: 'vd. minhkhang@motocare.vn'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập email hoặc số điện thoại'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('Mật khẩu'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          style: appText(15),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSub,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MechanicForgotPasswordScreen(
                                  email: _idController.text.contains('@')
                                      ? _idController.text.trim()
                                      : appState.profile.email,
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              'Quên mật khẩu?',
                              style:
                                  appText(14.5, weight: FontWeight.w600, color: AppColors.danger),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        PrimaryButton(label: 'Đăng nhập', onPressed: _login),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MechanicRegisterScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Chưa có tài khoản? ',
                              style: appText(15, color: AppColors.textSub),
                              children: [
                                TextSpan(
                                  text: 'Đăng ký làm thợ',
                                  style: appText(15, weight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 28),
                        GestureDetector(
                          onTap: _openTerms,
                          child: Text.rich(
                            TextSpan(
                              text: 'Bằng việc đăng nhập, bạn đồng ý với ',
                              children: [
                                TextSpan(
                                  text: 'Điều khoản sử dụng',
                                  style: appText(12.5,
                                      weight: FontWeight.w600, color: AppColors.textSub),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Chính sách bảo mật',
                                  style: appText(12.5,
                                      weight: FontWeight.w600, color: AppColors.textSub),
                                ),
                                const TextSpan(text: ' của MotoCare'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: appText(12.5, color: AppColors.textMuted, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.bolt_outlined, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MotoCare', style: appText(26, weight: FontWeight.w600, letterSpacing: -0.5)),
              Text('Đăng nhập dành cho thợ', style: appText(14, color: AppColors.textSub)),
            ],
          ),
        ),
      ],
    );
  }
}
