import 'package:flutter/material.dart';

import '../services/profile_account_service.dart';
import '../models/profile_validation.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.service});
  final ProfileAccountService service;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.changePassword(
        currentPassword: _current.text,
        newPassword: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ProfileAccountException
              ? error.message
              : 'Không thể đổi mật khẩu. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const ValueKey('current-password'),
                controller: _current,
                enabled: !_saving,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  suffixIcon: IconButton(
                    tooltip: _visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: ProfileValidation.currentPassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('new-password'),
                controller: _password,
                enabled: !_saving,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  helperText: 'Từ 8 đến 128 ký tự',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    ProfileValidation.newPassword(value, _current.text),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('confirm-password'),
                controller: _confirm,
                enabled: !_saving,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                ),
                validator: (value) =>
                    ProfileValidation.confirmPassword(value, _password.text),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang xử lý…' : 'Cập nhật mật khẩu'),
        ),
      ],
    ),
  );
}
