import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Màn hình Khách (rút gọn) — chỉ để demo luồng:
/// "Trở thành đối tác" -> chờ Admin duyệt (CMS) -> hỏi chuyển sang giao diện Thợ.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  Future<void> _openRegister(BuildContext context, AppState state) async {
    final result = await showModalBottomSheet<_PartnerApplication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PartnerFormSheet(initialName: state.profile.displayName),
    );
    if (result == null || !context.mounted) return;
    state.submitPartnerApplication(result.name, result.area);
    showAppSnack(context, 'Đã gửi hồ sơ. Hệ thống sẽ duyệt trên CMS/Admin Backend.');
  }

  /// Hỏi người dùng có muốn sang Màn hình Thợ ngay không.
  Future<void> _askSwitch(BuildContext context, AppState state) async {
    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Hồ sơ đối tác đã được duyệt',
            style: appText(17, weight: FontWeight.w800)),
        content: Text(
          'Bạn muốn sang Màn hình Thợ để nhận đơn ngay?',
          style: appText(14.5, color: AppColors.textSub, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Để sau',
                style: appText(14, weight: FontWeight.w700, color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('Sang giao diện Thợ',
                style: appText(14, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (go == true) state.switchMode(AppMode.mechanic);
  }

  /// Mock Admin bấm "Duyệt" trên CMS rồi app nhận thông báo "Đã duyệt".
  Future<void> _simulateApproval(BuildContext context, AppState state) async {
    state.approvePartnerDemo();
    await _askSwitch(context, state);
  }

  /// Mock "lần đăng nhập tiếp theo": tự chuyển nếu đã bật, nếu không thì hỏi.
  Future<void> _simulateNextLogin(BuildContext context, AppState state) async {
    if (state.autoOpenMechanic) {
      state.switchMode(AppMode.mechanic);
    } else {
      await _askSwitch(context, state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final status = state.partnerStatus;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Text('MotoCare', style: appText(26, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Cứu hộ xe máy tức thời', style: appText(14, color: AppColors.textSub)),
              const SizedBox(height: 20),

              // Khối gọi cứu hộ (giao diện Khách: ngoài phạm vi bài này)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xe bạn gặp sự cố?',
                        style: appText(19, weight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Kết nối thợ sửa xe gần nhất trong vài phút.',
                        style: appText(13.5, color: Colors.white.op(0.75))),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => showAppSnack(
                            context, 'Giao diện Khách nằm ngoài phạm vi phần Thợ (demo).'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        child: Text('Gọi cứu hộ ngay',
                            style: appText(14.5, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Khối "Trở thành đối tác" theo trạng thái
              _PartnerCard(
                status: status,
                onRegister: () => _openRegister(context, state),
                onApproveDemo: () => _simulateApproval(context, state),
                onGoMechanic: () => state.switchMode(AppMode.mechanic),
              ),

              if (status == PartnerStatus.approved) ...[
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lần đăng nhập sau tự vào giao diện Thợ',
                          style: appText(14, weight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: state.autoOpenMechanic,
                        onChanged: state.setAutoOpenMechanic,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.online,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.disabled,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _simulateNextLogin(context, state),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: Text('Demo: giả lập đăng nhập lần sau',
                        style: appText(13, weight: FontWeight.w600, color: AppColors.textSub)),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: state.skipToMechanic,
                  icon: const Icon(Icons.fast_forward_outlined, size: 18),
                  label: Text('Vào nhanh giao diện Thợ (bỏ qua đăng ký)',
                      style: appText(13, weight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSub,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.status,
    required this.onRegister,
    required this.onApproveDemo,
    required this.onGoMechanic,
  });

  final PartnerStatus status;
  final VoidCallback onRegister;
  final VoidCallback onApproveDemo;
  final VoidCallback onGoMechanic;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String title;
    late final String body;
    late final String cta;
    late final VoidCallback onCta;
    Color tone = AppColors.ink;

    switch (status) {
      case PartnerStatus.none:
        icon = Icons.handyman_outlined;
        title = 'Trở thành đối tác';
        body = 'Bạn là thợ sửa xe? Đăng ký để nhận đơn cứu hộ quanh khu vực của bạn.';
        cta = 'Đăng ký làm đối tác';
        onCta = onRegister;
        break;
      case PartnerStatus.pending:
        icon = Icons.hourglass_empty;
        title = 'Hồ sơ đang chờ duyệt';
        body = 'Hệ thống đang duyệt tài khoản của bạn trên CMS/Admin Backend.';
        cta = 'Demo: giả lập Admin duyệt';
        onCta = onApproveDemo;
        tone = const Color(0xFF9A5B00);
        break;
      case PartnerStatus.approved:
        icon = Icons.check_circle_outline;
        title = 'Đã duyệt — bạn là đối tác';
        body = 'Chuyển sang Màn hình Thợ để bật nhận đơn.';
        cta = 'Sang giao diện Thợ';
        onCta = onGoMechanic;
        tone = AppColors.successDark;
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tone.op(0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: appText(16, weight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: appText(13.5, color: AppColors.textSub, height: 1.4)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: status == PartnerStatus.pending
                ? OutlinedButton(
                    onPressed: onCta,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink, width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text(cta, style: appText(14.5, weight: FontWeight.w700)),
                  )
                : ElevatedButton(
                    onPressed: onCta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text(cta,
                        style: appText(14.5, weight: FontWeight.w800, color: Colors.white)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartnerApplication {
  const _PartnerApplication(this.name, this.area);
  final String name;
  final String area;
}

/// Form đăng ký đối tác rút gọn (tên tiệm/thợ + quận/huyện).
class _PartnerFormSheet extends StatefulWidget {
  const _PartnerFormSheet({required this.initialName});
  final String initialName;

  @override
  State<_PartnerFormSheet> createState() => _PartnerFormSheetState();
}

class _PartnerFormSheetState extends State<_PartnerFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  String _area = MockData.districts[2]; // Quận 5
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên tiệm / thợ.');
      return;
    }
    Navigator.of(context).pop(_PartnerApplication(_name.text.trim(), _area));
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Đăng ký làm đối tác', style: appText(18, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Giấy tờ (CCCD/ĐKKD, chứng chỉ thợ) sẽ được tải lên và xác minh ở bước sau.',
              style: appText(13, color: AppColors.textSub, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
              style: appText(15),
              decoration: InputDecoration(
                labelText: 'Tên tiệm / thợ',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: const InputDecoration(labelText: 'Quận/huyện hoạt động'),
              style: appText(15, weight: FontWeight.w600),
              items: [
                for (final d in MockData.districts)
                  DropdownMenuItem<String>(value: d, child: Text(d)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _area = v);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text('Gửi hồ sơ',
                    style: appText(15.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
