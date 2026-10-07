import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/photo_attachment_field.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../providers/partner_registration_provider.dart';

class DangKyThoScreen extends ConsumerStatefulWidget {
  const DangKyThoScreen({super.key});

  @override
  ConsumerState<DangKyThoScreen> createState() => _DangKyThoScreenState();
}

class _DangKyThoScreenState extends ConsumerState<DangKyThoScreen> {
  final _forms = List.generate(3, (_) => GlobalKey<FormState>());
  final _name = TextEditingController();
  final _citizenId = TextEditingController();
  final _scroll = ScrollController();
  final _tools = <String>{};
  Uint8List? _frontPhoto;
  Uint8List? _backPhoto;
  String? _experience;
  String? _district;
  int _step = 0;
  bool _showToolError = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _citizenId.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _validate(int step) {
    final valid = _forms[step].currentState!.validate();
    if (step == 1) setState(() => _showToolError = _tools.isEmpty);
    return valid && (step != 1 || _tools.isNotEmpty);
  }

  void _changeStep(int target) {
    if (target == _step || target > _step + 1) return;
    if (target > _step && !_validate(_step)) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = target);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _submit() async {
    if (_submitted) return;
    for (var step = 0; step < 3; step++) {
      if (!_validate(step)) {
        setState(() => _step = step);
        return;
      }
    }
    FocusScope.of(context).unfocus();
    ref
        .read(partnerApplicationsProvider.notifier)
        .submit(
          PartnerApplication(
            fullName: _name.text.trim(),
            citizenId: _citizenId.text.trim(),
            frontPhoto: _frontPhoto!,
            backPhoto: _backPhoto!,
            experience: _experience!,
            tools: _tools,
            district: _district!,
          ),
        );
    setState(() => _submitted = true);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: ServiceColors.orange,
          size: 48,
        ),
        title: const Text('Đăng ký thành công'),
        content: const Text(
          'Hồ sơ của bạn đã được ghi nhận. Admin sẽ liên hệ xác minh trong 24h.\n\nHồ sơ đang được lưu trong phiên dùng thử; chưa gửi đến Admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ServiceScaffold(
    title: 'Đăng ký Đối tác Thợ sửa xe',
    bottomBar: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _step == 2 && !_submitted ? _submit : null,
        child: Text(_submitted ? 'Đã ghi nhận hồ sơ' : 'Gửi hồ sơ đăng ký'),
      ),
    ),
    body: SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RegistrationSteps(current: _step, onSelected: _changeStep),
          const SizedBox(height: 24),
          const Text(
            'Cùng MotoCare giúp mọi hành trình an toàn hơn.',
            style: TextStyle(color: ServiceColors.muted),
          ),
          const SizedBox(height: 20),
          _StepPanels(
            index: _step,
            children: [
              Form(
                key: _forms[0],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Họ tên'),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 80,
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Vui lòng nhập họ tên đầy đủ.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _citizenId,
                      decoration: const InputDecoration(labelText: 'Số CCCD'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 12,
                      validator: (value) =>
                          RegExp(r'^\d{12}$').hasMatch(value ?? '')
                          ? null
                          : 'Số CCCD phải gồm 12 chữ số.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ảnh CCCD 2 mặt',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    PhotoAttachmentField(
                      label: 'Ảnh CCCD mặt trước',
                      requiredPhoto: true,
                      onChanged: (photo) => _frontPhoto = photo,
                    ),
                    const SizedBox(height: 14),
                    PhotoAttachmentField(
                      label: 'Ảnh CCCD mặt sau',
                      requiredPhoto: true,
                      onChanged: (photo) => _backPhoto = photo,
                    ),
                  ],
                ),
              ),
              Form(
                key: _forms[1],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Tay nghề & Dụng cụ',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _experience,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Số năm kinh nghiệm',
                      ),
                      items: [
                        for (final value in [
                          'Dưới 1 năm',
                          '1 - 3 năm',
                          '3 - 5 năm',
                          'Trên 5 năm',
                        ])
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (value) => setState(() => _experience = value),
                      validator: (value) => value == null
                          ? 'Vui lòng chọn số năm kinh nghiệm.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dụng cụ có sẵn',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final tool in [
                      'Bơm điện',
                      'Bộ vá lốp',
                      'Bình ắc quy phụ',
                      'Bộ chìa khóa',
                    ])
                      CheckboxListTile(
                        value: _tools.contains(tool),
                        title: Text(tool),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            _tools.add(tool);
                          } else {
                            _tools.remove(tool);
                          }
                          _showToolError = false;
                        }),
                      ),
                    if (_showToolError)
                      Text(
                        'Vui lòng chọn ít nhất một dụng cụ.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              Form(
                key: _forms[2],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Khu vực hoạt động',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _district,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Quận/Huyện hoạt động chính',
                      ),
                      items: [
                        for (final value in [
                          'Quận 1',
                          'Quận 3',
                          'Quận 7',
                          'Bình Thạnh',
                          'Tân Bình',
                          'Thủ Đức',
                          'Bình Chánh',
                          'Hóc Môn',
                        ])
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (value) => setState(() => _district = value),
                      validator: (value) => value == null
                          ? 'Vui lòng chọn khu vực hoạt động.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Hồ sơ được lưu trong phiên dùng thử. Chức năng gửi đến Admin chưa được kết nối.',
                          style: TextStyle(color: ServiceColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => _changeStep(_step - 1),
                  child: const Text('Quay lại bước trước'),
                ),
              if (_step < 2)
                FilledButton(
                  onPressed: () => _changeStep(_step + 1),
                  child: const Text('Tiếp tục'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StepPanels extends StatelessWidget {
  const _StepPanels({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++)
        Offstage(offstage: i != index, child: children[i]),
    ],
  );
}

class _RegistrationSteps extends StatelessWidget {
  const _RegistrationSteps({required this.current, required this.onSelected});
  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: Semantics(
            selected: current == i,
            label: 'Bước ${i + 1} trên 3',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: i <= current + 1 ? () => onSelected(i) : null,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: i <= current
                          ? ServiceColors.orange
                          : ServiceColors.surface,
                      foregroundColor: Colors.white,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['Cá nhân', 'Tay nghề & Dụng cụ', 'Khu vực'][i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: i == current
                            ? ServiceColors.orange
                            : ServiceColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
