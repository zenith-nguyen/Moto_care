import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/code_input_boxes.dart';
import '../widgets/ui.dart';

/// Quên mật khẩu: Bước 1 nhập OTP 6 số, Bước 2 đặt mật khẩu mới — trong cùng một màn.
class MechanicForgotPasswordScreen extends StatefulWidget {
  const MechanicForgotPasswordScreen({
    super.key,
    required this.email,
    this.title = 'Quên mật khẩu',
  });

  final String email;
  final String title;

  @override
  State<MechanicForgotPasswordScreen> createState() => _MechanicForgotPasswordScreenState();
}

class _MechanicForgotPasswordScreenState extends State<MechanicForgotPasswordScreen> {
  static const _resendSeconds = 48;

  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String _otp = '';
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  bool get _otpDone => _otp.length == 6;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_otpDone) {
      showAppSnack(context, 'Vui lòng nhập đủ 6 số mã xác nhận');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    showAppSnack(context, 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: widget.title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StepHeading(number: 1, title: 'Nhập mã xác nhận', active: true),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        text: 'Mã 6 số đã được gửi tới email ',
                        children: [
                          TextSpan(
                            text: maskEmail(widget.email),
                            style: appText(14.5, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: appText(14.5, color: AppColors.textSub, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c) {
                        const gap = 10.0;
                        final box = ((c.maxWidth - 5 * gap) / 6).clamp(36.0, 56.0);
                        return CodeInputBoxes(
                          length: 6,
                          boxSize: box,
                          spacing: gap,
                          autofocus: true,
                          onChanged: (v) => setState(() => _otp = v),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Gửi lại mã sau ',
                              children: [
                                TextSpan(
                                  text: formatMmSs(Duration(seconds: _secondsLeft)),
                                  style: appText(14.5, weight: FontWeight.w700),
                                ),
                              ],
                            ),
                            style: appText(14.5, color: AppColors.textSub),
                          ),
                        ),
                        TextButton(
                          onPressed: _secondsLeft > 0
                              ? null
                              : () {
                                  _startTimer();
                                  showAppSnack(context, 'Đã gửi lại mã xác nhận');
                                },
                          child: Text(
                            'Gửi lại',
                            style: appText(
                              14.5,
                              weight: FontWeight.w600,
                              color: _secondsLeft > 0 ? AppColors.textMuted : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    Opacity(
                      opacity: _otpDone ? 1 : 0.45,
                      child: IgnorePointer(
                        ignoring: !_otpDone,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StepHeading(number: 2, title: 'Đặt mật khẩu mới', active: _otpDone),
                              const SizedBox(height: 18),
                              const FieldLabel('Mật khẩu mới'),
                              TextFormField(
                                controller: _newController,
                                obscureText: true,
                                style: appText(15),
                                decoration: const InputDecoration(hintText: 'Tối thiểu 8 ký tự'),
                                validator: (v) => (v == null || v.length < 8)
                                    ? 'Mật khẩu tối thiểu 8 ký tự'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              const FieldLabel('Xác nhận mật khẩu'),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: true,
                                style: appText(15),
                                decoration: const InputDecoration(hintText: 'Nhập lại mật khẩu'),
                                validator: (v) => v != _newController.text
                                    ? 'Mật khẩu xác nhận không khớp'
                                    : null,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: PrimaryButton(label: 'Đặt lại mật khẩu', onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.number, required this.title, required this.active});
  final int number;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.ink : AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: appText(
              14,
              weight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSub,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: appText(
              18,
              weight: FontWeight.w600,
              color: active ? AppColors.ink : AppColors.textSub,
            ),
          ),
        ),
      ],
    );
  }
}
