import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/revo_logo.dart';
import '../../../core/config/support_contact.dart';
import '../../../app/app_dependencies.dart';
import '../application/session_controller.dart';
import '../domain/app_user.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../models/auth_validation.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _failureMessage;

  bool get _validPhone => AuthValidation.registrationPhone(_phone);
  bool get _hasMinLength => AuthValidation.hasMinLength(_password);
  bool get _hasMixedCase => AuthValidation.hasMixedCase(_password);
  bool get _hasNumber => AuthValidation.hasNumber(_password);
  bool get _hasSpecialCharacter =>
      AuthValidation.hasSpecialCharacter(_password);
  bool get _validPassword => AuthValidation.registrationPassword(_password);
  bool get _canSubmit =>
      _name.trim().length >= 2 &&
      AuthValidation.email(_email) == null &&
      _validPhone &&
      _validPassword &&
      _acceptedTerms &&
      !_isSubmitting;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showMessage(
        'Vui lòng đồng ý với Điều khoản và Chính sách quyền riêng tư.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _failureMessage = null;
    });
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .register(
            name: _name,
            email: _email,
            phone: _phone,
            password: _password,
            role: AppRole.customer,
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .activateRegisteredSession(session);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failureMessage = error.toString());
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
          'Đăng ký tài khoản Revo',
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
            const _FieldLabel('Họ và tên'),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('register-name'),
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                hintText: 'Nhập họ và tên của bạn',
              ),
              onChanged: (value) => setState(() => _name = value),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Vui lòng nhập họ và tên'
                  : null,
            ),
            const SizedBox(height: 28),
            const _FieldLabel('Email'),
            const SizedBox(height: 12),
            Semantics(
              label: 'Email',
              child: TextFormField(
                key: const ValueKey('register-email'),
                enabled: !_isSubmitting,
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
                    color: AuthColors.border,
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
                      enabled: !_isSubmitting,
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
                color: AuthColors.secondary,
                fontSize: 15,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 22),
            if (_failureMessage != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _failureMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AuthColors.primary,
                disabledBackgroundColor: AuthColors.disabled,
                disabledForegroundColor: const Color(0xFF909090),
              ),
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng ký'),
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
            activeColor: AuthColors.primary,
            checkColor: Colors.white,
            side: const BorderSide(color: AuthColors.primary, width: 2),
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
                  style: const TextStyle(color: AuthColors.primary),
                  recognizer: _termsRecognizer,
                ),
                const TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách quyền riêng tư',
                  style: const TextStyle(color: AuthColors.primary),
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
    return const Center(child: RevoLogo());
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
            color: satisfied ? AuthColors.primary : AuthColors.secondary,
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
