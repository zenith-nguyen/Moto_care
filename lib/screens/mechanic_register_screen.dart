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
      showAppSnack(context, 'Vui lòng đồng ý Điều khoản sử dụng để gửi hồ sơ');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MechanicPendingApprovalScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Đăng ký làm thợ'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ScrollColumn(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  children: [
                    const FieldLabel('Họ tên / Tên thợ'),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: 'Nguyễn Minh Khang'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Email'),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: 'email@vidu.com'),
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
                      decoration: const InputDecoration(hintText: '09xx xxx xxx'),
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
                      decoration: const InputDecoration(hintText: 'Tối thiểu 8 ký tự'),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Mật khẩu tối thiểu 8 ký tự' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Xác nhận mật khẩu'),
                    TextFormField(
                      obscureText: true,
                      style: appText(15),
                      decoration: const InputDecoration(hintText: 'Nhập lại mật khẩu'),
                      validator: (v) =>
                          v != _passwordController.text ? 'Mật khẩu xác nhận không khớp' : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Divider(height: 1),
                    ),
                    Text.rich(
                      TextSpan(
                        text: 'Giấy tờ xác minh ',
                        style: appText(17, weight: FontWeight.w600),
                        children: [
                          TextSpan(
                            text: '(tuỳ chọn, bổ sung sau)',
                            style: appText(13.5, color: AppColors.textSub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _UploadTile(
                              title: 'CCCD (2 mặt)',
                              uploaded: _idUploaded,
                              onTap: () => setState(() => _idUploaded = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _UploadTile(
                              title: 'Chứng chỉ nghề',
                              uploaded: _certUploaded,
                              onTap: () => setState(() => _certUploaded = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCheckbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openTerms,
                            child: Text.rich(
                              TextSpan(
                                text: 'Tôi đồng ý với ',
                                children: [
                                  TextSpan(
                                    text: 'Điều khoản sử dụng',
                                    style: appText(14, weight: FontWeight.w700),
                                  ),
                                  const TextSpan(
                                    text: ' và cam kết cung cấp dịch vụ đúng quy định MotoCare',
                                  ),
                                ],
                              ),
                              style: appText(14, color: AppColors.textSub, height: 1.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: PrimaryButton(label: 'Gửi hồ sơ đăng ký', onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.title, required this.uploaded, required this.onTap});

  final String title;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DashedBorderBox(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconCircle(
              icon: uploaded ? Icons.check : Icons.file_upload_outlined,
              size: 50,
              background: uploaded ? AppColors.successSoft : AppColors.surface,
              color: uploaded ? AppColors.success : AppColors.ink,
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: title,
                style: appText(13.5, weight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: uploaded ? '  Đã tải' : '  Tải lên',
                    style: appText(
                      12,
                      weight: FontWeight.w500,
                      color: uploaded ? AppColors.success : AppColors.textSub,
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
