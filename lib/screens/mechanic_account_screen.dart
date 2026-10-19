import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'service_management_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'weekly_summary_screen.dart';
import 'withdraw_screen.dart';
import 'rank_screen.dart';
import 'terms_and_commitment_screen.dart';
import 'customer_reviews_screen.dart';
import 'payment_tracking_screen.dart';
import '../widgets/progress_stepper.dart';

class MechanicAccountScreen extends StatelessWidget {
  const MechanicAccountScreen({super.key});
  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  Future<void> _logout(BuildContext context) async {
    if (appState.activeOrder != null) {
      showAppSnack(
          context, 'Hãy hoàn thành đơn đang xử lý trước khi đăng xuất.');
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Đăng xuất tài khoản?'),
              content: const Text(
                  'Bạn sẽ ngừng nhận đơn và quay về màn hình chào. Lịch sử đơn và số dư ví của phiên demo được giữ lại.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Ở lại')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.dangerDark),
                    child: const Text('Đăng xuất'))
              ],
            ));
    if (!context.mounted || confirmed != true) return;
    if (!appState.signOut()) {
      showAppSnack(context, 'Đang có đơn xử lý. Chưa thể đăng xuất.');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TermsEntryScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        final verified = p.verificationStatus == VerificationStatus.verified;
        return SafeArea(
            bottom: false,
            child: ListView(padding: AppSpace.pageInsets, children: [
              Row(children: [
                const Expanded(
                    child: Text('Tài khoản',
                        style: TextStyle(
                            fontFamily: AppTypography.family,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink))),
                Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                        side: BorderSide(color: AppColors.border, width: .7)),
                    child: IconButton(
                        tooltip: 'Cài đặt tài khoản',
                        onPressed: () => _open(context, const SettingsScreen()),
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.primary)))
              ]),
              const SizedBox(height: 12),
              _profileCard(context, p, verified),
              const SizedBox(height: 12),
              SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
                  child: Column(children: [
                    IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Expanded(
                              child: _stat('${appState.totalCompletedOrders}',
                                  'Đơn hoàn thành')),
                          const VerticalDivider(
                              width: 1, thickness: .7, color: AppColors.border),
                          Expanded(
                              child: _stat('${p.rating}', 'Điểm đánh giá')),
                          const VerticalDivider(
                              width: 1, thickness: .7, color: AppColors.border),
                          Expanded(
                              child: _stat(formatVnd(appState.monthIncome),
                                  'Thu nhập tháng')),
                        ])),
                    const SizedBox(height: 10),
                    Text('Số liệu demo · Thu nhập tháng từ số giao dịch',
                        textAlign: TextAlign.center,
                        style: appText(11, color: AppColors.textSub))
                  ])),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _quick(Icons.receipt_long_outlined, 'Đơn hàng',
                    () => appState.setTab(1)),
                _quick(Icons.account_balance_wallet_outlined, 'Ví Thợ',
                    () => appState.setTab(2)),
                _quick(Icons.build_outlined, 'Dịch vụ',
                    () => _open(context, const ServiceManagementScreen())),
                _quick(Icons.bar_chart_rounded, 'Thống kê',
                    () => _open(context, const WeeklySummaryScreen())),
              ]),
              _group('Hồ sơ & năng lực', [
                _row(Icons.person_outline, 'Thông tin cá nhân',
                    () => _open(context, const ProfileEditScreen()),
                    subtitle: 'Liên hệ, chuyên môn & khu vực hoạt động',
                    iconColor: AppColors.primary),
                _row(Icons.badge_outlined, 'Giấy tờ & chứng chỉ',
                    () => _open(context, const DocumentsScreen()),
                    subtitle: 'Kỹ năng đã đăng ký · Đăng ký kỹ năng mới',
                    iconColor: AppColors.primary),
                _row(Icons.build_outlined, 'Quản lý dịch vụ',
                    () => _open(context, const ServiceManagementScreen()),
                    iconColor: AppColors.primary),
                _row(Icons.workspace_premium_outlined, 'Hạng thợ & Quyền lợi',
                    () => _open(context, const RankBenefitsScreen()),
                    subtitle: 'Tiến độ lên hạng và điều kiện',
                    iconColor: AppColors.primary),
              ]),
              Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Row(children: [
                    const Expanded(
                        child:
                            Text('Hoạt động công việc', style: _sectionStyle)),
                    TextButton(
                        key: const ValueKey('activity-see-all'),
                        onPressed: () => appState.setTab(1),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Xem tất cả',
                              style: appText(13,
                                  weight: FontWeight.w600,
                                  color: AppColors.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.primary),
                        ])),
                  ])),
              const _OrderActivityCard(),
              _group('Tài chính', [
                _row(Icons.account_balance_wallet_outlined,
                    'Ví & lịch sử giao dịch', () => appState.setTab(2)),
                _row(Icons.payments_outlined, 'Rút tiền',
                    () => _open(context, const WithdrawScreen())),
                if (appState.payoutRequests.isNotEmpty)
                  _row(
                      Icons.fact_check_outlined,
                      'Theo dõi thanh toán',
                      () => _open(
                          context,
                          PaymentTrackingScreen(
                              request: appState.payoutRequests.first)),
                      subtitle: 'Đề nghị chi trả gửi Admin'),
                _row(Icons.account_balance_outlined, 'Tài khoản nhận tiền',
                    () => showReceivingAccount(context)),
              ]),
              _group('Hệ thống', [
                _row(Icons.star_outline_rounded, 'Đánh giá từ khách hàng',
                    () => _open(context, const CustomerReviewsScreen())),
                _row(Icons.notifications_none_rounded, 'Thông báo',
                    () => _open(context, const NotificationsScreen())),
                _row(Icons.settings_outlined, 'Cài đặt',
                    () => _open(context, const SettingsScreen())),
                _row(Icons.support_agent_rounded, 'Trợ giúp & hỗ trợ',
                    () => _open(context, const SupportScreen())),
                _row(Icons.info_outline_rounded, 'Giới thiệu REVO',
                    () => showRevoAbout(context)),
                _row(
                    Icons.description_outlined,
                    'Điều khoản & Cam kết',
                    () => _open(context,
                        const TermsAndCommitmentScreen(readOnly: true))),
              ]),
              SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: _row(
                      Icons.logout_rounded, 'Đăng xuất', () => _logout(context),
                      danger: true)),
              const SizedBox(height: 10),
              const Text('Phiên tài khoản mô phỏng · Dữ liệu giữ trong bộ nhớ',
                  textAlign: TextAlign.center, style: AppTypography.caption),
              const SizedBox(height: 12),
            ]));
      });
  static const _sectionStyle = TextStyle(
      fontFamily: AppTypography.family,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.ink);

  Widget _profileCard(BuildContext context, MechanicProfile p, bool verified) =>
      ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [
            Positioned.fill(
                child: CustomPaint(painter: _ProfileCurvePainter())),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F7FC)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD9E8F5)),
                    boxShadow: AppShadows.soft),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Container(
                              key: const ValueKey('profile-avatar'),
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: AvatarCircle(
                                  initials: p.initials,
                                  size: 76,
                                  imageAsset: p.avatarAsset)),
                          if (verified)
                            Positioned(
                                right: -1,
                                bottom: 0,
                                child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.verified_rounded,
                                        color: AppColors.primary, size: 22))),
                        ]),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(p.name,
                                  style: appText(20, weight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text('Thợ cứu hộ REVO',
                                  style: appText(13, color: AppColors.textSub)),
                              const SizedBox(height: 8),
                              Wrap(
                                  spacing: 6,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (verified)
                                      const Icon(Icons.verified_rounded,
                                          color: AppColors.primary, size: 16),
                                    Text(
                                        verified
                                            ? 'Đã xác minh'
                                            : 'Chờ xác minh',
                                        style: appText(12,
                                            weight: FontWeight.w500,
                                            color: AppColors.primary)),
                                    const Icon(Icons.star_rounded,
                                        color: AppColors.warning, size: 16),
                                    Text('${p.rating} (${p.ratingCount})',
                                        style: appText(12,
                                            color: AppColors.textSub)),
                                  ]),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 17, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(p.area,
                                style:
                                    appText(12.5, color: AppColors.textSub))),
                        const SizedBox(width: 8),
                        InkWell(
                            key: const ValueKey('edit-profile'),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () =>
                                _open(context, const ProfileEditScreen()),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(
                                        color: const Color(0xFFCFE2F3))),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Sửa hồ sơ',
                                          style: appText(12.5,
                                              weight: FontWeight.w600,
                                              color: AppColors.primary)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 16, color: AppColors.primary),
                                    ]))),
                      ]),
                    ])),
          ]));

  Widget _stat(String value, String label) => Column(children: [
        FittedBox(
            child: Text(value, style: appText(19, weight: FontWeight.w700))),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: appText(11, color: AppColors.textSub)),
      ]);
  Widget _quick(IconData icon, String label, VoidCallback tap) => Expanded(
      child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                IconCircle(
                    icon: icon,
                    size: 50,
                    background: AppColors.surfaceSoft,
                    color: AppColors.primary),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: appText(12, weight: FontWeight.w500))
              ]))));
  Widget _group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _sectionStyle),
        const SizedBox(height: 10),
        SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: .7, indent: 48),
                rows[i],
              ]
            ])),
      ]));
  Widget _row(IconData icon, String label, VoidCallback tap,
          {String? subtitle, bool danger = false, Color? iconColor}) =>
      ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          minLeadingWidth: 36,
          leading: IconCircle(
              icon: icon,
              size: 36,
              color: danger
                  ? AppColors.dangerDark
                  : iconColor ?? AppColors.primary,
              background: danger
                  ? AppColors.dangerSoft
                  : iconColor != null
                      ? const Color(0xFFEAF3FA)
                      : AppColors.surfaceSoft),
          title: Text(label,
              style: appText(14,
                  weight: FontWeight.w600,
                  color: danger ? AppColors.dangerDark : AppColors.ink)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: appText(11.5, color: AppColors.textSub)),
          trailing: Icon(Icons.chevron_right_rounded,
              size: 18,
              color: danger ? AppColors.dangerDark : AppColors.textSub),
          onTap: tap);
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: appState.profile.name);
  final _phone = TextEditingController(text: appState.profile.phone);
  final _email = TextEditingController(text: appState.profile.email);
  final _bio = TextEditingController(text: appState.profile.bio);
  final _years =
      TextEditingController(text: '${appState.profile.experienceYears}');
  final _specialty = TextEditingController(text: appState.profile.specialty);
  late String _area = appState.profile.area;
  late final Set<String> _vehicles = appState.profile.supportedVehicles.toSet();
  String? _error;
  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _bio, _years, _specialty]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    try {
      appState.saveProfessionalProfile(
          name: _name.text,
          bio: _bio.text,
          phone: _phone.text,
          email: _email.text,
          experienceYears: int.tryParse(_years.text) ?? -1,
          specialty: _specialty.text,
          area: _area,
          vehicles: _vehicles.toList());
      Navigator.pop(context);
      showAppSnack(context, 'Đã cập nhật hồ sơ.');
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      showAppSnack(context, e.message);
    }
  }

  Widget _heading(String label) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(label, style: AppTypography.label));
  Widget _field(String label, TextEditingController controller,
          {TextInputType? type,
          int lines = 1,
          int? limit,
          String? Function(String?)? validator}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FieldLabel(label),
            TextFormField(
                key: ValueKey('profile-$label'),
                controller: controller,
                keyboardType: type,
                maxLines: lines,
                maxLength: limit,
                style: appText(13),
                validator: validator,
                textInputAction:
                    lines > 1 ? TextInputAction.newline : TextInputAction.next,
                inputFormatters: type == TextInputType.number
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null),
          ]));
  @override
  Widget build(BuildContext context) {
    final p = appState.profile;
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      const ScreenHeader(title: 'Thông tin cá nhân'),
      Expanded(
          child: Form(
              key: _form,
              child: ListView(padding: AppSpace.pageInsets, children: [
                Row(children: [
                  AvatarCircle(
                      initials: p.initials,
                      size: 54,
                      imageAsset: p.avatarAsset),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Hồ sơ nghề nghiệp', style: AppTypography.label),
                        Text('Ảnh hồ sơ mẫu · Chưa hỗ trợ tải ảnh',
                            style: AppTypography.caption),
                      ]))
                ]),
                _heading('Thông tin cơ bản'),
                _field('Họ tên', _name,
                    limit: 80,
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Vui lòng nhập họ tên.'
                        : null),
                _field('Số điện thoại', _phone,
                    type: TextInputType.phone,
                    validator: (v) => (v ?? '').isNotEmpty &&
                            !RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(v!.trim())
                        ? 'Nhập số Việt Nam hợp lệ hoặc để trống.'
                        : null),
                _field('Email', _email,
                    type: TextInputType.emailAddress,
                    validator: (v) => (v ?? '').isNotEmpty &&
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(v!.trim())
                        ? 'Email chưa hợp lệ.'
                        : null),
                _field('Giới thiệu', _bio, lines: 3, limit: 500),
                _heading('Thông tin nghề nghiệp'),
                _field('Số năm kinh nghiệm', _years,
                    type: TextInputType.number,
                    limit: 2,
                    validator: (v) =>
                        int.tryParse(v ?? '') == null || int.parse(v!) > 60
                            ? 'Nhập từ 0 đến 60 năm.'
                            : null),
                _field('Chuyên môn chính', _specialty,
                    limit: 80,
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Vui lòng nhập chuyên môn.'
                        : null),
                const FieldLabel('Loại phương tiện hỗ trợ'),
                Wrap(spacing: 8, children: [
                  for (final vehicle in AppConfig.vehicleTypes)
                    FilterChip(
                        label: Text(vehicle),
                        selected: _vehicles.contains(vehicle),
                        onSelected: (v) => setState(() {
                              v
                                  ? _vehicles.add(vehicle)
                                  : _vehicles.remove(vehicle);
                            }))
                ]),
                _heading('Khu vực hoạt động'),
                DropdownButtonFormField<String>(
                    initialValue: _area,
                    isExpanded: true,
                    items: {...MockData.districts, _area}
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s, style: appText(13))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _area = v;
                    }),
                _heading('Năng lực & chứng chỉ · chỉ đọc'),
                SurfaceCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      StatusBadge.verification(p.verificationStatus),
                      const SizedBox(height: 10),
                      for (final s in p.skills)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Expanded(child: Text(s.name, style: appText(12))),
                              StatusBadge.verification(s.status),
                            ])),
                      const Divider(),
                      const Text(
                          'Trạng thái xác minh do REVO xét duyệt. Thợ không thể tự chỉnh sửa.',
                          style: AppTypography.caption),
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DocumentsScreen())),
                          child: const Text('Xem giấy tờ & đăng ký kỹ năng')),
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ServiceManagementScreen())),
                          child: const Text('Chọn dịch vụ nhận đơn')),
                    ])),
                _heading('Thông tin hoạt động · demo'),
                KeyValueRow(
                    'Đơn hoàn thành', '${appState.totalCompletedOrders}'),
                KeyValueRow('Điểm đánh giá', '${p.rating} (${p.ratingCount})'),
                if (p.joinedAt != null)
                  KeyValueRow('Ngày tham gia', formatDM(p.joinedAt!)),
                KeyValueRow('Sẵn sàng nhận đơn',
                    appState.isOnline ? 'Trực tuyến' : 'Ngoại tuyến'),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!,
                          style: appText(12, color: AppColors.dangerDark))),
                const SizedBox(height: 12),
              ]))),
      Padding(
          padding: AppSpace.footerInsets,
          child: PrimaryButton(label: 'Lưu thay đổi', onPressed: _save)),
    ])));
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  Future<void> _registerSkill(BuildContext context) async {
    final registered = appState.profile.skills.map((s) => s.name).toSet();
    final options =
        MockData.extraSkills.where((s) => !registered.contains(s)).toList();
    if (options.isEmpty) {
      showAppSnack(context, 'Bạn đã đăng ký tất cả kỹ năng hiện có');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Đăng ký kỹ năng mới',
                style: appText(20, weight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Kỹ năng sẽ ở trạng thái Chờ xác minh cho đến khi Admin duyệt.',
                style: appText(13.5, color: AppColors.textSub),
              ),
            ),
            for (final s in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.shield_outlined),
                title: Text(s, style: appText(15.5, weight: FontWeight.w500)),
                trailing: const Icon(Icons.add),
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    appState.registerSkill(picked);
    if (context.mounted) {
      showAppSnack(context, 'Đã gửi đăng ký kỹ năng "$picked"');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: appState,
            builder: (context, _) => Column(
              children: [
                const ScreenHeader(title: 'Giấy tờ & chứng chỉ'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Hồ sơ xác minh',
                        style: appText(14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trạng thái được cập nhật sau khi REVO xét duyệt.',
                        style: appText(13, color: AppColors.textSub),
                      ),
                      const SizedBox(height: 16),
                      for (final d in appState.profile.documents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SurfaceCard(
                            color: Colors.white,
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    d.name,
                                    style: appText(13, weight: FontWeight.w600),
                                  ),
                                ),
                                StatusBadge.verification(d.status),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Kỹ năng đã đăng ký',
                        style: appText(14, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      for (final skill in appState.profile.skills)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(skill.name, style: appText(13)),
                          trailing: StatusBadge.verification(skill.status),
                        ),
                      const SizedBox(height: 12),
                      OutlineActionButton(
                        label: '+ Đăng ký kỹ năng mới',
                        borderColor: AppColors.border,
                        onPressed: () => _registerSkill(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ProfileCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCEBF8).withValues(alpha: .55)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * .62, 0)
      ..quadraticBezierTo(
          size.width * .78, size.height * .5, size.width * .6, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Four-step order progress, taken from the active order or the latest
/// non-cancelled order in history. Missing times stay blank, never invented.
class _OrderActivityCard extends StatelessWidget {
  const _OrderActivityCard();

  @override
  Widget build(BuildContext context) {
    final a = appState.activeOrder;
    String code;
    List<StepperStep> steps;
    bool done;
    if (a != null) {
      final reached = switch (a.step) {
        OrderStep.received || OrderStep.navigating => 1,
        OrderStep.arrived => 2,
        OrderStep.repairing || OrderStep.quoting => 3,
        OrderStep.completed => 4,
      };
      final times = [a.acceptedAt, a.arrivedAt, a.repairStartedAt, null];
      steps = _steps(reached, times);
      code = a.orderId;
      done = reached == 4;
    } else {
      OrderHistoryItem? last;
      for (final o in appState.history) {
        if (o.status == OrderStatus.completed) {
          last = o;
          break;
        }
      }
      if (last == null) {
        return const SurfaceCard(
            child: Text('Chưa có hoạt động đơn hàng.',
                style: AppTypography.caption));
      }
      final tl = last.timeline;
      steps = _steps(
          4, [for (var i = 0; i < 4; i++) i < tl.length ? tl[i].time : null]);
      code = last.orderId;
      done = true;
    }
    return SurfaceCard(
        key: const ValueKey('order-activity'),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          LayoutBuilder(builder: (context, box) {
            final big = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final chip = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: done ? AppColors.successSoft : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 15,
                      color: done ? AppColors.success : AppColors.warningDark),
                  const SizedBox(width: 5),
                  Text(done ? 'Hoàn thành' : 'Đang thực hiện',
                      style: appText(12,
                          weight: FontWeight.w600,
                          color: done
                              ? AppColors.successDark
                              : AppColors.warningDark)),
                ]));
            final left = Row(children: [
              const IconCircle(
                  icon: Icons.inventory_2_outlined,
                  size: 40,
                  color: AppColors.ink,
                  background: Color(0xFFEEF3F8)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Mã đơn hàng:',
                        style: appText(12, color: AppColors.textSub)),
                    Row(children: [
                      Flexible(
                          child: Text(code,
                              key: const ValueKey('activity-code'),
                              style: appText(16, weight: FontWeight.w700))),
                      InkWell(
                          key: const ValueKey('activity-copy'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            if (context.mounted) {
                              showAppSnack(context, 'Đã sao chép mã đơn hàng.');
                            }
                          },
                          child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.copy_rounded,
                                  size: 17, color: AppColors.textSub))),
                    ]),
                  ]))
            ]);
            return big
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [left, const SizedBox(height: 10), chip])
                : Row(children: [Expanded(child: left), chip]);
          }),
          const SizedBox(height: 18),
          KeyedSubtree(
              key: const ValueKey('order-stepper'),
              child: ProgressStepper(steps: steps, emptyTime: '—')),
        ]));
  }

  static List<StepperStep> _steps(int reached, List<DateTime?> times) {
    const labels = ['Nhận đơn', 'Đến nơi', 'Bắt đầu', 'Hoàn thành'];
    return [
      for (var i = 0; i < 4; i++)
        StepperStep(
            labels[i],
            i < reached && times[i] != null ? formatHm(times[i]!) : null,
            i < reached ? StepKind.done : StepKind.pending),
    ];
  }
}
