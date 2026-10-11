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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MotoCare',
                          style: appText(36, weight: FontWeight.w900, letterSpacing: -1)),
                      const SizedBox(height: 2),
                      Text('Đăng nhập dành cho Thợ', style: appText(16, color: AppColors.textSub)),
                      const SizedBox(height: 28),
                      const _WelcomeCard(),
                      const SizedBox(height: 28),
                      const FieldLabel('Email hoặc số điện thoại'),
                      TextFormField(
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                        style: appText(15),
                        decoration: const InputDecoration(hintText: 'you@email.com'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập email hoặc số điện thoại'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      FieldLabel(
                        'Mật khẩu',
                        trailing: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MechanicForgotPasswordScreen(
                                email: _idController.text.contains('@')
                                    ? _idController.text.trim()
                                    : MockData.profile().email,
                              ),
                            ),
                          ),
                          child:
                              Text('Quên mật khẩu?', style: appText(15, weight: FontWeight.w800)),
                        ),
                      ),
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
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSub,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(label: 'Đăng nhập', onPressed: _login),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('hoặc', style: appText(14, color: AppColors.textMuted)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MechanicRegisterScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Chưa có tài khoản Thợ? ',
                              style: appText(15, color: AppColors.textSub),
                              children: [
                                TextSpan(
                                  text: 'Đăng ký ngay',
                                  style: appText(15, weight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: GestureDetector(
                    onTap: _openTerms,
                    child: Text.rich(
                      TextSpan(
                        text: 'Bằng việc đăng nhập, bạn đồng ý với ',
                        children: [
                          TextSpan(
                            text: 'Điều khoản & Cam kết',
                            style: appText(13, weight: FontWeight.w700, color: AppColors.textSub),
                          ),
                          const TextSpan(text: ' của MotoCare.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: appText(13, color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 20, 26),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng trở lại',
                  style: appText(24, weight: FontWeight.w800, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục nhận đơn cứu hộ.',
                  style: appText(14.5, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Logo: ghim vị trí có xe máy.
          SizedBox(
            width: 64,
            height: 76,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 72),
                Positioned(
                  top: 15,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                    child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
