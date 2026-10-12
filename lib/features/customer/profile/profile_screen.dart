import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../profile/providers/profile_actions_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/theme/profile_dashboard_theme.dart';
import '../../profile/widgets/profile_actions.dart';
import '../../profile/widgets/profile_dashboard_sheets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ProfileActions(context, ref).recoverAvatar());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final busy = ref.watch(profileActionsProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Theme(
        data: ProfileDashboardTheme.light,
        child: Builder(
          builder: (pageContext) {
            final actions = ProfileActions(pageContext, ref);
            return Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    key: const ValueKey('account-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          MediaQuery.paddingOf(context).top + 16,
                          20,
                          20,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ProfileDashboardTheme.primaryContainer,
                              Colors.white,
                            ],
                          ),
                        ),
                        child: _buildHeaderCard(
                          pageContext,
                          state,
                          busy,
                          actions,
                        ),
                      ),
                      _inset(_buildQuickShortcuts(pageContext, state)),
                      const SizedBox(height: 24),
                      _inset(_buildUtilityGrid(pageContext, state)),
                      const SizedBox(height: 24),
                      _inset(_buildPartnerSection(pageContext)),
                      const SizedBox(height: 24),
                      _inset(
                        _buildSecurityGroup(pageContext, state, busy, actions),
                      ),
                      const SizedBox(height: 24),
                      _inset(_buildSupportGroup(pageContext)),
                      const SizedBox(height: 28),
                      _inset(_buildBottomActions(busy, actions)),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: HomeBottomNavigation(
                light: true,
                selectedDestination: HomeDestination.account,
                onSelected: (destination) =>
                    navigateMainTab(pageContext, destination),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ProfileState state,
    bool busy,
    ProfileActions actions,
  ) {
    final profile = state.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tài khoản',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ProfileDashboardTheme.ink,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Trung tâm trợ giúp',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
              ),
              onPressed: () => context.push('/faq'),
              icon: const Icon(Icons.support_agent_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('account-header-card'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(state, busy ? null : actions.pickAvatar),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  profile.fullName.trim().isEmpty
                                      ? 'Tài khoản của bạn'
                                      : profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: ProfileDashboardTheme.ink,
                                  ),
                                ),
                              ),
                              if (profile.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6, top: 3),
                                  child: Tooltip(
                                    message: 'Đã xác thực',
                                    child: Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF39B54A),
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: ProfileDashboardTheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '5.0',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Rating',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ProfileDashboardTheme.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.phoneNumber.isEmpty
                                ? 'Chưa cập nhật SĐT'
                                : 'SĐT: ${profile.phoneNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: ProfileDashboardTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'Chỉnh sửa tài khoản',
                      child: _headerButton(
                        'account-personal-info',
                        'Sửa hồ sơ',
                        Icons.edit_outlined,
                        () => context.push('/thong-tin-ca-nhan'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _headerButton(
                      'account-header-settings',
                      'Cài đặt',
                      Icons.settings_outlined,
                      () => ProfileDashboardSheets.settings(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(ProfileState state, VoidCallback? onEdit) {
    const fallback = ColoredBox(
      color: ProfileDashboardTheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 42,
          color: ProfileDashboardTheme.primary,
        ),
      ),
    );
    final url = state.profile.avatarUrl;
    final avatar = state.avatarBytes != null
        ? Image.memory(
            state.avatarBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : url?.trim().isNotEmpty == true
        ? Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
    return SizedBox(
      width: 76,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 76,
            child: ClipOval(child: avatar),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: IconButton(
              key: const ValueKey('account-avatar'),
              tooltip: 'Sửa ảnh đại diện',
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ProfileDashboardTheme.primary,
                side: const BorderSide(
                  color: ProfileDashboardTheme.primaryContainer,
                ),
                minimumSize: const Size(40, 40),
                padding: const EdgeInsets.all(8),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton(
    String id,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => OutlinedButton.icon(
    key: ValueKey(id),
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: ProfileDashboardTheme.ink,
      side: const BorderSide(color: ProfileDashboardTheme.border),
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    icon: Icon(icon, size: 17),
    label: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildQuickShortcuts(BuildContext context, ProfileState state) =>
      _card(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _shortcut(
              'vehicles',
              Icons.two_wheeler_rounded,
              'Danh sách xe',
              () => context.push('/xe-cua-toi'),
            ),
            _shortcut(
              'payment',
              Icons.account_balance_wallet_outlined,
              'Thanh toán',
              () => ProfileDashboardSheets.payment(context),
            ),
            _shortcut(
              'emergency',
              Icons.sos_rounded,
              'Liên hệ khẩn',
              () => ProfileDashboardSheets.emergency(context, state.profile),
            ),
            _shortcut(
              'expenses',
              Icons.menu_book_outlined,
              'Sổ bảo dưỡng',
              () => ProfileDashboardSheets.expenses(context, ref),
            ),
          ],
        ),
      );

  Widget _shortcut(
    String id,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => Expanded(
    child: InkWell(
      key: ValueKey('account-$id'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ProfileDashboardTheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 25, color: ProfileDashboardTheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildUtilityGrid(BuildContext context, ProfileState state) =>
      _section(
        'Quản lý phương tiện & Địa chỉ',
        _card(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _utilityTile(
                        'vehicle-info',
                        Icons.motorcycle_outlined,
                        'Thông tin xe',
                        'Xe mặc định, Biển số, Loại lốp',
                        () => ProfileDashboardSheets.vehicle(
                          context,
                          state.profile,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _utilityTile(
                        'addresses',
                        Icons.home_outlined,
                        'Địa chỉ đã lưu',
                        'Nhà riêng, Cơ quan',
                        () => ProfileDashboardSheets.addresses(
                          context,
                          state.profile,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _utilityTile(
                        'insurance',
                        Icons.shield_outlined,
                        'Bảo hiểm xe',
                        'Bảo hiểm xe máy TNDS',
                        () => ProfileDashboardSheets.insurance(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _utilityTile(
                        'tips',
                        Icons.lightbulb_outline_rounded,
                        'Cứu hộ khẩn',
                        'Mẹo tự xử lý sự cố',
                        () => context.push('/meo-xu-ly'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _utilityTile(
    String id,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Material(
    color: ProfileDashboardTheme.background,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      key: ValueKey('account-$id'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ProfileDashboardTheme.primary, size: 26),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                height: 1.6,
                color: ProfileDashboardTheme.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPartnerSection(BuildContext context) => _section(
    'Dành cho Đối tác & Tiệm',
    Column(
      children: [
        _partnerTile(
          'mechanic',
          Icons.build_outlined,
          'Đăng ký Trở thành Đối tác Thợ',
          () => context.push('/dang-ky-tho'),
        ),
        const SizedBox(height: 10),
        _partnerTile(
          'shop',
          Icons.storefront_outlined,
          'Đăng ký Tiệm sửa xe / Trạm sạc',
          () => ProfileDashboardSheets.shop(context),
        ),
      ],
    ),
  );

  Widget _partnerTile(
    String id,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(
        color: ProfileDashboardTheme.primaryContainer,
        width: 1.5,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: _buildGroupListTile(
      id: id,
      icon: icon,
      title: title,
      onTap: onTap,
      accent: true,
    ),
  );

  Widget _buildSecurityGroup(
    BuildContext context,
    ProfileState state,
    bool busy,
    ProfileActions actions,
  ) => _section(
    'Tài khoản & Bảo mật',
    _card(
      child: Column(
        children: [
          _buildGroupListTile(
            id: 'password',
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            onTap: busy ? null : actions.changePassword,
          ),
          _divider(),
          _buildGroupListTile(
            id: 'biometric',
            icon: Icons.fingerprint_rounded,
            title: 'Touch ID / FaceID',
            subtitle: 'Xác thực khi chỉnh sửa hồ sơ',
            trailing: Switch.adaptive(
              key: const ValueKey('account-biometric-switch'),
              value: state.biometricEnabled,
              activeTrackColor: ProfileDashboardTheme.primary,
              onChanged: busy ? null : actions.toggleBiometric,
            ),
            onTap: busy
                ? null
                : () => actions.toggleBiometric(!state.biometricEnabled),
          ),
          _divider(),
          _buildGroupListTile(
            id: 'email',
            icon: Icons.alternate_email_rounded,
            title: 'Email liên kết',
            subtitle: state.profile.email.isEmpty
                ? 'Chưa liên kết email'
                : state.profile.email,
            onTap: () => ProfileDashboardSheets.information(
              context,
              'Email liên kết',
              state.profile.email.isEmpty
                  ? 'Chưa có email được liên kết với tài khoản.'
                  : state.profile.email,
              action: 'Xem thông tin cá nhân',
              route: '/thong-tin-ca-nhan',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSupportGroup(BuildContext context) {
    final items = [
      (
        'places',
        Icons.ev_station_outlined,
        'Trạm sạc/tiệm gần nhất',
        () => context.push('/tram-sac-tiem-sua'),
      ),
      (
        'prices',
        Icons.receipt_long_outlined,
        'Bảng giá dịch vụ & Phụ tùng',
        () => context.push('/bang-gia'),
      ),
      (
        'help',
        Icons.support_agent_rounded,
        'Trung tâm trợ giúp & FAQ',
        () => context.push('/faq'),
      ),
      (
        'commitment',
        Icons.verified_user_outlined,
        'Cam kết & Bồi thường',
        () => context.push('/cam-ket-dich-vu'),
      ),
      (
        'messages',
        Icons.chat_bubble_outline_rounded,
        'Tin nhắn',
        () => context.push('/tin-nhan'),
      ),
      (
        'settings',
        Icons.settings_outlined,
        'Cài đặt ứng dụng',
        () => ProfileDashboardSheets.settings(context),
      ),
    ];
    return _section(
      'Tra cứu & Hỗ trợ',
      _card(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _buildGroupListTile(
                id: items[i].$1,
                icon: items[i].$2,
                title: items[i].$3,
                onTap: items[i].$4,
              ),
              if (i < items.length - 1) _divider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupListTile({
    required String id,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    bool accent = false,
  }) => ListTile(
    key: ValueKey('account-$id'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent
            ? ProfileDashboardTheme.primaryContainer
            : ProfileDashboardTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 21,
        color: accent
            ? ProfileDashboardTheme.primary
            : ProfileDashboardTheme.ink,
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
    ),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: ProfileDashboardTheme.muted,
              height: 1.6,
            ),
          ),
    trailing:
        trailing ??
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: ProfileDashboardTheme.muted,
        ),
    onTap: onTap,
  );

  Widget _buildBottomActions(bool busy, ProfileActions actions) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        key: const ValueKey('account-logout'),
        onPressed: busy ? null : actions.logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfileDashboardTheme.primary,
          side: const BorderSide(color: ProfileDashboardTheme.primary),
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: const ValueKey('account-delete'),
        onPressed: busy ? null : actions.deleteAccount,
        style: TextButton.styleFrom(
          foregroundColor: ProfileDashboardTheme.muted,
          minimumSize: const Size(48, 48),
        ),
        child: const Text('Xóa tài khoản', style: TextStyle(fontSize: 12)),
      ),
      const SizedBox(height: 12),
      const Text(
        'Phiên bản MotoCare v1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: ProfileDashboardTheme.muted),
      ),
    ],
  );

  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: ProfileDashboardTheme.ink,
        ),
      ),
      const SizedBox(height: 12),
      child,
    ],
  );

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 70, right: 16),
    child: Divider(height: 1),
  );

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );
}
