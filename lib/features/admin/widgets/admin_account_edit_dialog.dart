import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_validation.dart';
import '../../profile/models/profile_validation.dart';
import '../models/admin_account_models.dart';
import '../providers/admin_account_provider.dart';
import '../providers/admin_providers.dart';

enum AdminAccountEditor { profile, password, fees, alerts, support }

Future<void> showAdminAccountEditor(
  BuildContext context,
  AdminAccountEditor editor,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AdminAccountEditDialog(editor: editor),
);

class AdminAccountEditDialog extends ConsumerStatefulWidget {
  const AdminAccountEditDialog({super.key, required this.editor});
  final AdminAccountEditor editor;
  @override
  ConsumerState<AdminAccountEditDialog> createState() =>
      _AdminAccountEditDialogState();
}

class _AdminAccountEditDialogState
    extends ConsumerState<AdminAccountEditDialog> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String? _error;
  bool _visible = false;
  late bool _sound;

  String get _title => switch (widget.editor) {
    AdminAccountEditor.profile => 'Chỉnh sửa hồ sơ',
    AdminAccountEditor.password => 'Đổi mật khẩu',
    AdminAccountEditor.fees => 'Cấu hình Phí & Hệ số',
    AdminAccountEditor.alerts => 'Cài đặt Cảnh báo SOS',
    AdminAccountEditor.support => 'Liên hệ Kỹ thuật',
  };

  @override
  void initState() {
    super.initState();
    final data = ref.read(adminAccountProvider);
    _sound = data.settings.sosSound;
    final initial = switch (widget.editor) {
      AdminAccountEditor.profile => {
        'name': data.profile.name,
        'email': data.profile.email,
        'phone': data.profile.phone,
      },
      AdminAccountEditor.fees => {
        'fee': '${data.settings.feePercent}',
        'weather': '${data.settings.weatherFactor}',
        'sos': '${data.settings.sosFactor}',
      },
      AdminAccountEditor.password => {'current': '', 'new': '', 'confirm': ''},
      AdminAccountEditor.support => {'subject': '', 'message': ''},
      AdminAccountEditor.alerts => <String, String>{},
    };
    for (final entry in initial.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _fields[key]!.text;
  double _number(String key) =>
      double.parse(_text(key).trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final controller = ref.read(adminAccountProvider.notifier);
    final settings = ref.read(adminAccountProvider).settings;
    final result = await switch (widget.editor) {
      AdminAccountEditor.profile => controller.updateProfile(
        AdminAccountProfile(
          name: _text('name'),
          email: _text('email'),
          phone: _text('phone'),
        ),
      ),
      AdminAccountEditor.password => controller.changePassword(
        _text('current'),
        _text('new'),
      ),
      AdminAccountEditor.fees => controller.updateSettings(
        settings.copyWith(
          feePercent: _number('fee'),
          weatherFactor: _number('weather'),
          sosFactor: _number('sos'),
        ),
      ),
      AdminAccountEditor.alerts => controller.updateSettings(
        settings.copyWith(sosSound: _sound),
      ),
      AdminAccountEditor.support => controller.requestSupport(
        _text('subject'),
        _text('message'),
      ),
    };
    if (!mounted) return;
    if (result.success) {
      final messenger = ScaffoldMessenger.of(context);
      final message = widget.editor == AdminAccountEditor.support
          ? 'Đã lưu yêu cầu hỗ trợ ${ref.read(adminAccountProvider).requests.first.id} trong phiên hiện tại.'
          : 'Đã cập nhật thành công.';
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      setState(() => _error = result.message);
    }
  }

  Widget _field(
    String key,
    String label, {
    String? Function(String?)? validator,
    bool password = false,
    bool decimal = false,
    int lines = 1,
    String? helper,
    int? maxLength,
  }) {
    final busy = ref.watch(adminAccountProvider).busy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: ValueKey('admin-${widget.editor.name}-$key'),
        controller: _fields[key],
        enabled: !busy,
        obscureText: password && !_visible,
        autocorrect: !password,
        enableSuggestions: !password,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : key == 'email'
            ? TextInputType.emailAddress
            : key == 'phone'
            ? TextInputType.phone
            : lines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        minLines: lines,
        maxLines: lines,
        maxLength: maxLength,
        textInputAction: lines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          suffixIcon: password && key == 'current'
              ? IconButton(
                  tooltip: _visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: busy
                      ? null
                      : () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  String? _range(String? value, double min, double max) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || !number.isFinite || number < min || number > max
        ? 'Nhập giá trị từ $min đến $max'
        : null;
  }

  List<Widget> _formFields() => switch (widget.editor) {
    AdminAccountEditor.profile => [
      _field(
        'name',
        'Họ tên',
        validator: ProfileValidation.fullName,
        maxLength: 80,
      ),
      _field('email', 'Email', validator: AuthValidation.email),
      _field(
        'phone',
        'Số điện thoại',
        validator: (v) => ProfileValidation.phone(v, optional: true),
      ),
    ],
    AdminAccountEditor.password => [
      _field(
        'current',
        'Mật khẩu hiện tại',
        password: true,
        validator: ProfileValidation.currentPassword,
      ),
      _field(
        'new',
        'Mật khẩu mới',
        password: true,
        helper: 'Từ 8 đến 128 ký tự',
        validator: (v) => ProfileValidation.newPassword(v, _text('current')),
      ),
      _field(
        'confirm',
        'Nhập lại mật khẩu mới',
        password: true,
        validator: (v) => ProfileValidation.confirmPassword(v, _text('new')),
      ),
    ],
    AdminAccountEditor.fees => [
      _field(
        'fee',
        'Phí dịch vụ (%)',
        decimal: true,
        validator: (v) => _range(v, 0, 100),
      ),
      _field(
        'weather',
        'Hệ số thời tiết',
        decimal: true,
        validator: (v) => _range(v, 1, 3),
      ),
      _field(
        'sos',
        'Hệ số SOS',
        decimal: true,
        validator: (v) => _range(v, 1, 5),
      ),
    ],
    AdminAccountEditor.alerts => [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Âm thanh đơn SOS mới'),
        subtitle: const Text('Chuông cảnh báo khi có yêu cầu cứu hộ mới.'),
        value: _sound,
        onChanged: ref.watch(adminAccountProvider).busy
            ? null
            : (value) => setState(() => _sound = value),
      ),
    ],
    AdminAccountEditor.support => [
      Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Text(
          'Yêu cầu hỗ trợ được lưu trong phiên hiện tại.',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ),
      _field(
        'subject',
        'Tiêu đề yêu cầu',
        maxLength: 100,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
      ),
      _field(
        'message',
        'Mô tả vấn đề',
        lines: 4,
        maxLength: 2000,
        validator: (v) =>
            (v?.trim().length ?? 0) < 10 ? 'Nhập tối thiểu 10 ký tự' : null,
      ),
      if (ref.watch(adminAccountProvider).requests.isNotEmpty)
        ExpansionTile(
          title: const Text('Yêu cầu đã lưu'),
          children: [
            for (final request in ref.watch(adminAccountProvider).requests)
              ListTile(
                title: Text('${request.id} · ${request.subject}'),
                subtitle: Text(request.message),
              ),
          ],
        ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(adminAccountProvider).busy;
    final allowed = ref.watch(adminSessionProvider)?.isAdmin == true;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(_title, textAlign: TextAlign.center),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (allowed)
                  ..._formFields()
                else
                  const Text('Phiên quản trị đã kết thúc.'),
                if (_error != null)
                  Text(
                    _error!,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          if (allowed)
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(
                busy
                    ? 'Đang lưu…'
                    : widget.editor == AdminAccountEditor.password
                    ? 'Cập nhật mật khẩu'
                    : 'Lưu thay đổi',
              ),
            ),
        ],
      ),
    );
  }
}
