import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/photo_attachment_field.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../../providers/data/provider_application_repository.dart';
import '../models/partner_registration_draft.dart';
import '../providers/partner_registration_draft_provider.dart';
import '../services/partner_registration_service.dart';

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
  final _draftKey = Object();
  PartnerRegistrationDraftController get _controller =>
      ref.read(partnerRegistrationDraftProvider(_draftKey).notifier);
  int get _step => ref.read(partnerRegistrationDraftProvider(_draftKey)).step;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _citizenId.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _validate(int step) {
    final valid = _forms[step].currentState!.validate();
    final toolsValid = _controller.validateTools(step);
    return valid && toolsValid;
  }

  void _changeStep(int target) {
    if (target == _step || target > _step + 1) return;
    if (target > _step && !_validate(_step)) return;
    FocusScope.of(context).unfocus();
    _controller.changeStep(target);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (ref.read(partnerRegistrationDraftProvider(_draftKey)).submitted) return;
    for (var step = 0; step < 3; step++) {
      if (!_validate(step)) {
        _controller.changeStep(step);
        return;
      }
    }
    FocusScope.of(context).unfocus();

    // In live API mode, submit to the backend first so the application really
    // reaches Admin. Only mark the draft submitted once the server accepts it,
    // so a transient failure leaves the form usable.
    final draft = ref.read(partnerRegistrationDraftProvider(_draftKey));
    final liveMode = ref.read(runtimeApiIntegrationProvider);
    if (liveMode) {
      setState(() => _submitting = true);
      final sent = await _sendToBackend(draft);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!sent) return;
    }

    if (!_controller.submit(_name.text, _citizenId.text)) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: ServiceColors.orange,
          size: 48,
        ),
        title: const Text('Đăng ký thành công'),
        content: Text(
          liveMode
              ? 'Hồ sơ của bạn đã được gửi đến Admin. Bạn sẽ nhận được thông '
                    'báo khi hồ sơ được duyệt.'
              : 'Hồ sơ của bạn đã được ghi nhận. Admin sẽ liên hệ xác minh '
                    'trong 24h.\n\nHồ sơ đang được lưu trong phiên dùng thử; '
                    'chưa gửi đến Admin.',
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

  // Returns true when the application was accepted (or already exists), false
  // when the caller should let the applicant retry.
  Future<bool> _sendToBackend(PartnerRegistrationDraft draft) async {
    try {
      await ref
          .read(providerApplicationRepositoryProvider)
          .submit(
            ProviderApplicationInput(
              bio: _composeBio(draft),
              yearsOfExperience: _yearsFrom(draft.experience),
            ),
          );
      return true;
    } on ApiFailure catch (failure) {
      if (failure.kind == ApiFailureKind.conflict) {
        // Already applied: treat as submitted so the form settles.
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Bạn đã nộp hồ sơ trước đó, vui lòng chờ duyệt.'),
              ),
            );
        }
        return true;
      }
      _showSubmitError('Không gửi được hồ sơ: ${failure.message}');
      return false;
    } catch (error) {
      _showSubmitError('Không gửi được hồ sơ: $error');
      return false;
    }
  }

  void _showSubmitError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // The backend application stores a free-text bio; compose it from the public
  // details collected here. The CCCD number and ID photos are intentionally
  // left out of this text (admin verification of documents is a later step).
  String? _composeBio(PartnerRegistrationDraft draft) {
    final parts = <String>[
      if (draft.experience != null) 'Kinh nghiệm: ${draft.experience}',
      if (draft.district != null) 'Khu vực: ${draft.district}',
      if (draft.tools.isNotEmpty) 'Dụng cụ: ${draft.tools.join(', ')}',
    ];
    return parts.isEmpty ? null : parts.join('. ');
  }

  int? _yearsFrom(String? experience) => switch (experience) {
    'Dưới 1 năm' => 0,
    '1 - 3 năm' => 1,
    '3 - 5 năm' => 3,
    'Trên 5 năm' => 5,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(partnerRegistrationDraftProvider(_draftKey));
    final service = ref.watch(partnerRegistrationServiceProvider);
    final options = ref.watch(partnerRegistrationOptionsProvider);
    return ServiceScaffold(
      title: 'Đăng ký Đối tác Thợ sửa xe',
      bottomBar: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _step == 2 && !draft.submitted && !_submitting
              ? _submit
              : null,
          child: Text(
            draft.submitted
                ? 'Đã ghi nhận hồ sơ'
                : _submitting
                ? 'Đang gửi...'
                : 'Gửi hồ sơ đăng ký',
          ),
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
                        validator: service.validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _citizenId,
                        decoration: const InputDecoration(labelText: 'Số CCCD'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 12,
                        validator: service.validateCitizenId,
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
                        onChanged: _controller.attachFront,
                      ),
                      const SizedBox(height: 14),
                      PhotoAttachmentField(
                        label: 'Ảnh CCCD mặt sau',
                        requiredPhoto: true,
                        onChanged: _controller.attachBack,
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
                        initialValue: draft.experience,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Số năm kinh nghiệm',
                        ),
                        items: [
                          for (final value in options.experience)
                            DropdownMenuItem(value: value, child: Text(value)),
                        ],
                        onChanged: _controller.selectExperience,
                        validator: service.validateExperience,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Dụng cụ có sẵn',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final tool in options.tools)
                        CheckboxListTile(
                          value: draft.tools.contains(tool),
                          title: Text(tool),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) =>
                              _controller.selectTool(tool, value == true),
                        ),
                      if (draft.showToolError)
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
                        initialValue: draft.district,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Quận/Huyện hoạt động chính',
                        ),
                        items: [
                          for (final value in options.districts)
                            DropdownMenuItem(value: value, child: Text(value)),
                        ],
                        onChanged: _controller.selectDistrict,
                        validator: service.validateDistrict,
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            ref.watch(runtimeApiIntegrationProvider)
                                ? 'Khi gửi, hồ sơ sẽ được chuyển đến Admin để '
                                      'duyệt. Bạn vẫn dùng ứng dụng như khách '
                                      'hàng cho tới khi được duyệt.'
                                : 'Hồ sơ được lưu trong phiên dùng thử. Chức '
                                      'năng gửi đến Admin chưa được kết nối.',
                            style: const TextStyle(color: ServiceColors.muted),
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
