import 'package:flutter/material.dart';

import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../theme/profile_theme.dart';

class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phoneNumber);
  late final _contactName = TextEditingController(
    text: widget.profile.emergencyContactName,
  );
  late final _contactPhone = TextEditingController(
    text: widget.profile.emergencyContactPhone,
  );
  late final _medical = TextEditingController(text: widget.profile.medicalNote);

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _contactName,
      _contactPhone,
      _medical,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      widget.profile.copyWith(
        fullName: _name.text,
        phoneNumber: _phone.text,
        emergencyContactName: _contactName.text,
        emergencyContactPhone: _contactPhone.text,
        medicalNote: _medical.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chỉnh sửa thông tin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng chỉnh sửa',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Text(
              'Số liên hệ chính xác giúp thợ hỗ trợ bạn nhanh hơn.',
              style: TextStyle(color: ProfileTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('profile-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              autofillHints: const [AutofillHints.name],
              validator: ProfileValidation.fullName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('profile-phone'),
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: '09… hoặc +84…',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: ProfileValidation.phone,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('profile-contact-name'),
              controller: _contactName,
              decoration: const InputDecoration(
                labelText: 'Tên người thân (không bắt buộc)',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 80,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('profile-contact-phone'),
              controller: _contactPhone,
              decoration: const InputDecoration(
                labelText: 'SĐT người thân khẩn cấp',
                helperText: 'Có thể để trống nếu chưa có liên hệ SOS.',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  ProfileValidation.phone(value, optional: true),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('profile-medical-note'),
              controller: _medical,
              decoration: const InputDecoration(
                labelText: 'Ghi chú y tế (không bắt buộc)',
                hintText: 'Ví dụ: dị ứng thuốc, lưu ý khi hỗ trợ…',
              ),
              maxLines: 3,
              maxLength: 240,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    ),
  );
}
