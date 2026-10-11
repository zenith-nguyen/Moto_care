import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'mechanic_pending_approval_screen.dart';
import 'terms_and_commitment_screen.dart';

class MechanicRegisterScreen extends StatefulWidget {
  const MechanicRegisterScreen({super.key});

  @override
  State<MechanicRegisterScreen> createState() => _MechanicRegisterScreenState();
}

class _MechanicRegisterScreenState extends State<MechanicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _agreed = false;
  bool _idUploaded = false;
  bool _certUploaded = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TermsAndCommitmentScreen(initiallyAgreed: _agreed)),
    );
    if (agreed == true) setState(() => _agreed = true);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showAppSnack(context, 'Vui lòng đồng ý Điều khoản & Cam kết để gửi hồ sơ');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MechanicPendingApprovalScreen()),
      (_) => false,
    );
  }

  String? _required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Đăng ký tài khoản Thợ'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ScrollColumn(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text(
                      'Tạo tài khoản để bắt đầu nhận đơn cứu hộ xe máy trên MotoCare. Hồ sơ sẽ '
                      'được Admin xét duyệt trước khi bạn hoạt động.',
                      style: appText(14.5, color: AppColors.textSub, height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    const FieldLabel('Họ tên hoặc tên thợ'),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: 'VD: Nguyễn Minh Phát'),
                      validator: (v) => _required(v, 'Vui lòng nhập họ tên'),
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Email'),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: 'you@email.com'),
                      validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                          ? 'Email không hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Số điện thoại'),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: '090 xxx xx xx'),
                      validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 10)
                          ? 'Số điện thoại gồm 10 số'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Mật khẩu'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: '••••••••'),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Xác nhận mật khẩu'),
                    TextFormField(
                      obscureText: true,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: '••••••••'),
                      validator: (v) =>
                          v != _passwordController.text ? 'Mật khẩu xác nhận không khớp' : null,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text('Giấy tờ xác minh', style: appText(18, weight: FontWeight.w800)),
                        ),
                        const StatusBadge.neutral('Tuỳ chọn'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Có thể bổ sung sau trong mục Hồ sơ. Admin sẽ xác minh khi xét duyệt.',
                      style: appText(13.5, color: AppColors.textSub, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _UploadRow(
                            icon: Icons.badge_outlined,
                            title: 'CCCD / Giấy phép hành nghề',
                            uploaded: _idUploaded,
                            onTap: () => setState(() => _idUploaded = true),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _UploadRow(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Chứng chỉ nghề (nếu có)',
                            uploaded: _certUploaded,
                            onTap: () => setState(() => _certUploaded = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreed,
                          activeColor: AppColors.ink,
                          onChanged: (v) => setState(() => _agreed = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: GestureDetector(
                              onTap: _openTerms,
                              child: Text.rich(
                                TextSpan(
                                  text: 'Tôi đồng ý với ',
                                  children: [
                                    TextSpan(
                                      text: 'Điều khoản & Cam kết cung cấp dịch vụ',
                                      style: appText(14, weight: FontWeight.w800),
                                    ),
                                    const TextSpan(text: ' của MotoCare.'),
                                  ],
                                ),
                                style: appText(14, color: AppColors.textSub, height: 1.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                children: [
                  PrimaryButton(label: 'Gửi hồ sơ đăng ký', onPressed: _submit),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text.rich(
                      TextSpan(
                        text: 'Đã có tài khoản? ',
                        style: appText(14.5, color: AppColors.textSub),
                        children: [
                          TextSpan(
                              text: 'Đăng nhập', style: appText(14.5, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.icon,
    required this.title,
    required this.uploaded,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconCircle(icon: icon, size: 44),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: appText(15, weight: FontWeight.w700))),
          const SizedBox(width: 8),
          uploaded
              ? const StatusBadge.success('Đã tải', icon: Icons.check)
              : OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text('Tải lên', style: appText(13.5, weight: FontWeight.w800)),
                ),
        ],
      ),
    );
  }
}
