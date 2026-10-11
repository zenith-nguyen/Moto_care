import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/code_input_boxes.dart';
import '../widgets/ui.dart';

/// Quên mật khẩu: Bước 1 nhập OTP 6 số, Bước 2 đặt mật khẩu mới — trong cùng một màn.
class MechanicForgotPasswordScreen extends StatefulWidget {
  const MechanicForgotPasswordScreen(
      {super.key, required this.email, this.title = 'Quên mật khẩu'});

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StepHeading(number: 1, title: 'Nhập mã xác nhận', active: true),
                    Padding(
                      padding: const EdgeInsets.only(left: 46, top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'Mã gồm 6 số đã được gửi tới email ',
                              children: [
                                TextSpan(
                                  text: maskEmail(widget.email),
                                  style: appText(15, weight: FontWeight.w800),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            style: appText(15, color: AppColors.textSub, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, c) {
                              final box = ((c.maxWidth - 5 * 8) / 6).clamp(36.0, 52.0);
                              return CodeInputBoxes(
                                length: 6,
                                boxSize: box,
                                spacing: 8,
                                autofocus: true,
                                onChanged: (v) => setState(() => _otp = v),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _secondsLeft > 0
                                ? null
                                : () {
                                    _startTimer();
                                    showAppSnack(context, 'Đã gửi lại mã xác nhận');
                                  },
                            child: Text.rich(
                              TextSpan(
                                text: 'Chưa nhận được mã? ',
                                children: [
                                  TextSpan(
                                    text: _secondsLeft > 0
                                        ? 'Gửi lại (${formatMmSs(Duration(seconds: _secondsLeft))})'
                                        : 'Gửi lại',
                                    style: appText(15, weight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              style: appText(15, color: AppColors.textSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(height: 1),
                    ),
                    _StepHeading(number: 2, title: 'Đặt mật khẩu mới', active: _otpDone),
                    Padding(
                      padding: const EdgeInsets.only(left: 46, top: 14),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MutedLabel('Mật khẩu mới', enabled: _otpDone),
                            _PasswordField(
                              controller: _newController,
                              enabled: _otpDone,
                              validator: (v) =>
                                  (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                            ),
                            const SizedBox(height: 18),
                            _MutedLabel('Xác nhận mật khẩu mới', enabled: _otpDone),
                            _PasswordField(
                              controller: _confirmController,
                              enabled: _otpDone,
                              validator: (v) =>
                                  v != _newController.text ? 'Mật khẩu xác nhận không khớp' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.ink : AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: appText(14,
                weight: FontWeight.w800, color: active ? Colors.white : AppColors.textSub),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: appText(18, weight: FontWeight.w800))),
      ],
    );
  }
}

class _MutedLabel extends StatelessWidget {
  const _MutedLabel(this.text, {required this.enabled});
  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: appText(15,
            weight: FontWeight.w700, color: enabled ? AppColors.ink : AppColors.textSub),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.enabled, required this.validator});
  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      style: appText(15),
      validator: validator,
      decoration: InputDecoration(
        hintText: '••••••••',
        fillColor: enabled ? Colors.white : AppColors.surface,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
