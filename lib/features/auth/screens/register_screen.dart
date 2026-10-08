import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/support_contact.dart';
import '../../home/theme/home_theme.dart';
import '../models/auth_validation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  String _email = '';
  String _phone = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  bool get _validPhone => AuthValidation.registrationPhone(_phone);
  bool get _hasMinLength => AuthValidation.hasMinLength(_password);
  bool get _hasMixedCase => AuthValidation.hasMixedCase(_password);
  bool get _hasNumber => AuthValidation.hasNumber(_password);
  bool get _hasSpecialCharacter =>
      AuthValidation.hasSpecialCharacter(_password);
  bool get _validPassword => AuthValidation.registrationPassword(_password);
  bool get _canSubmit =>
      AuthValidation.email(_email) == null &&
      _validPhone &&
      _validPassword &&
      _acceptedTerms;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showMessage('Điều khoản sử dụng đang được cập nhật.');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          _showMessage('Chính sách quyền riêng tư đang được cập nhật.');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showMessage(
        'Vui lòng đồng ý với Điều khoản và Chính sách quyền riêng tư.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _showMessage('Đăng ký tài khoản sẽ sớm được hỗ trợ.');
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
          'Đăng ký tài khoản MotoCare',
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 576
                ? (constraints.maxWidth - 480) / 2
                : (constraints.maxWidth * 0.11).clamp(24.0, 48.0);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RegisterLogo(),
                  const SizedBox(height: 28),
                  _buildForm(),
                ],
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
            const _FieldLabel('Email'),
            const SizedBox(height: 12),
            Semantics(
              label: 'Email',
              child: TextFormField(
                key: const ValueKey('register-email'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Nhập email của bạn',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFF707070)),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _email = value.trim()),
                validator: AuthValidation.email,
              ),
            ),
            const SizedBox(height: 28),
            const _FieldLabel('Số điện thoại'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: HomeColors.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('+84', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label: 'Số điện thoại',
                    child: TextFormField(
                      key: const ValueKey('register-phone'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      style: const TextStyle(fontSize: 16),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại của bạn',
                        hintMaxLines: 1,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF707070),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => setState(() => _phone = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return _validPhone
                            ? null
                            : 'Số điện thoại không hợp lệ';
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _FieldLabel('Mật khẩu'),
            const SizedBox(height: 12),
            Semantics(
              label: 'Mật khẩu',
              child: TextFormField(
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu của bạn',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF707070),
                  ),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: FaIcon(
                      _obscurePassword
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 22,
                      color: const Color(0xFF787878),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() => _password = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return _validPassword
                      ? null
                      : 'Mật khẩu chưa đáp ứng đủ các yêu cầu';
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Tạo một mật khẩu thoả mãn:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _PasswordRequirement(
              text: 'Chứa ít nhất 8 ký tự',
              satisfied: _hasMinLength,
            ),
            const SizedBox(height: 12),
            _PasswordRequirement(
              text: 'Chứa cả chữ thường (a-z) và chữ hoa (A-Z)',
              satisfied: _hasMixedCase,
            ),
            const SizedBox(height: 12),
            _PasswordRequirement(
              text: 'Chứa ít nhất một số (0-9)',
              satisfied: _hasNumber,
            ),
            const SizedBox(height: 12),
            _PasswordRequirement(
              text: 'Chứa ít nhất một ký tự đặc biệt (@, #, …)',
              satisfied: _hasSpecialCharacter,
            ),
            const SizedBox(height: 28),
            _buildConsent(),
            const SizedBox(height: 16),
            const Text.rich(
              TextSpan(
                text:
                    'Trường hợp không đồng ý hoặc có ý kiến với mục đích '
                    'xử lý dữ liệu cá nhân hoặc các nội dung khác tại '
                    'Chính sách quyền riêng tư, vui lòng liên hệ lại với '
                    'chúng tôi qua hotline ',
                children: [
                  TextSpan(
                    text: SupportContact.hotline,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 15,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.link,
                disabledBackgroundColor: HomeColors.redSelected,
                disabledForegroundColor: const Color(0xFF909090),
              ),
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          height: 40,
          child: Checkbox(
            value: _acceptedTerms,
            activeColor: AppTheme.link,
            checkColor: Colors.white,
            side: const BorderSide(color: AppTheme.link, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            semanticLabel: 'Đồng ý với Điều khoản và Chính sách quyền riêng tư',
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Bạn đồng ý với ',
              children: [
                TextSpan(
                  text: 'Điều khoản',
                  style: const TextStyle(color: AppTheme.link),
                  recognizer: _termsRecognizer,
                ),
                const TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách quyền riêng tư',
                  style: const TextStyle(color: AppTheme.link),
                  recognizer: _privacyRecognizer,
                ),
              ],
            ),
            style: const TextStyle(fontSize: 16, height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _RegisterLogo extends StatelessWidget {
  const _RegisterLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Logo_motocare.png',
        width: 112,
        height: 112,
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
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.text, required this.satisfied});

  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${satisfied ? 'Đã đạt' : 'Chưa đạt'}: $text',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_rounded : Icons.close_rounded,
            size: 18,
            color: satisfied ? const Color(0xFF66BB6A) : AppTheme.link,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
