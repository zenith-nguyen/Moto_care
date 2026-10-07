import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/brand_backdrop.dart';
import '../../home/widgets/home_bottom_navigation.dart';

import '../../home/models/home_user.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/profile_account_service.dart';
import '../services/profile_device_service.dart';
import '../theme/profile_theme.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_edit_sheet.dart';

class ThongTinCaNhanScreen extends ConsumerStatefulWidget {
  const ThongTinCaNhanScreen({super.key, this.user});
  final HomeUser? user;

  @override
  ConsumerState<ThongTinCaNhanScreen> createState() =>
      _ThongTinCaNhanScreenState();
}

class _ThongTinCaNhanScreenState extends ConsumerState<ThongTinCaNhanScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = widget.user;
      if (user != null || !ref.read(profileProvider).initialized) {
        ref
            .read(profileProvider.notifier)
            .initialize(
              UserProfile(
                id: user?.memberId ?? '',
                fullName: user?.displayName.trim() ?? '',
                memberTier: user?.membershipLabel ?? 'Chưa có hạng',
                rewardPoints: user?.rewardPoints ?? 0,
              ),
            );
      }
      unawaited(_recoverAvatar());
    });
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _recoverAvatar() async {
    try {
      final bytes = await ref
          .read(profileDeviceServiceProvider)
          .recoverAvatar();
      if (mounted &&
          bytes != null &&
          ref.read(profileProvider).avatarBytes == null) {
        ref.read(profileProvider.notifier).setAvatar(bytes);
      }
    } catch (error) {
      if (error is ProfileDeviceException) _notice(error.message);
    }
  }

  Future<bool> _authenticate({bool force = false}) async {
    if (_busy) return false;
    if (!force && !ref.read(profileProvider).biometricEnabled) return true;
    setState(() => _busy = true);
    try {
      final success = await ref
          .read(profileDeviceServiceProvider)
          .authenticate();
      if (!success) {
        _notice('Chưa xác thực. Thông tin của bạn được giữ nguyên.');
      }
      return mounted && success;
    } catch (error) {
      _notice(
        error is ProfileDeviceException
            ? error.message
            : 'Không thể xác thực lúc này. Vui lòng thử lại.',
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(BuildContext pageContext) async {
    if (!await _authenticate() || !pageContext.mounted) return;
    final edited = await showModalBottomSheet<UserProfile>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) =>
          ProfileEditSheet(profile: ref.read(profileProvider).profile),
    );
    if (!mounted || edited == null) return;
    final saved = ref
        .read(profileProvider.notifier)
        .saveDetails(
          fullName: edited.fullName,
          phoneNumber: edited.phoneNumber,
          emergencyContactName: edited.emergencyContactName,
          emergencyContactPhone: edited.emergencyContactPhone,
          medicalNote: edited.medicalNote,
        );
    _notice(
      saved
          ? 'Đã lưu thông tin trong phiên dùng thử.'
          : 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
    );
  }

  Future<void> _pickAvatar() async {
    if (!await _authenticate() || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(profileDeviceServiceProvider).pickAvatar();
      if (mounted && bytes != null) {
        ref.read(profileProvider.notifier).setAvatar(bytes);
        _notice('Đã cập nhật ảnh đại diện trong phiên dùng thử.');
      }
    } catch (error) {
      _notice(
        error is ProfileDeviceException
            ? error.message
            : 'Không thể đọc ảnh này. Vui lòng chọn ảnh khác.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!await _authenticate(force: true)) return;
    ref.read(profileProvider.notifier).setBiometricEnabled(enabled);
    _notice(
      enabled
          ? 'Đã bật xác thực khi chỉnh sửa hồ sơ.'
          : 'Đã tắt xác thực khi chỉnh sửa hồ sơ.',
    );
  }

  Future<void> _changePassword(BuildContext pageContext) async {
    if (!await _authenticate() || !pageContext.mounted) return;
    final changed = await showDialog<bool>(
      context: pageContext,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(
        service: ref.read(profileAccountServiceProvider),
      ),
    );
    if (changed == true) _notice('Đã đổi mật khẩu.');
  }

  void _endSession() {
    ref.read(profileProvider.notifier).clearSession();
    context.go('/login');
  }

  Future<bool> _confirm(
    BuildContext pageContext, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: pageContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive
                    ? const Color(0xFFD92D20)
                    : ProfileTheme.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _logout(BuildContext pageContext) async {
    if (await _confirm(
          pageContext,
          title: 'Đăng xuất khỏi MotoCare?',
          message: 'Thông tin chỉnh sửa trong phiên dùng thử sẽ được xóa khỏi bộ nhớ.',
          action: 'Đăng xuất',
        ) &&
        mounted) {
      _endSession();
    }
  }

  Future<void> _deleteAccount(BuildContext pageContext) async {
    if (!await _authenticate() || !pageContext.mounted) return;
    final confirmed = await _confirm(
      pageContext,
      title: 'Xóa tài khoản?',
      message: 'Tài khoản và dữ liệu liên quan sẽ bị xóa khi dịch vụ xác nhận. Bạn không thể khôi phục tài khoản sau khi xóa.',
      action: 'Xóa tài khoản',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileAccountServiceProvider)
          .deleteAccount(ref.read(profileProvider).profile.id);
      if (mounted) _endSession();
    } catch (error) {
      _notice(
        error is ProfileAccountException
            ? error.message
            : 'Không thể xóa tài khoản. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    final vehicle = profile.defaultVehicle;
    return Theme(
      data: ProfileTheme.light,
      child: Builder(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(
            flexibleSpace: const BrandBackdrop(child: SizedBox.expand()),
            toolbarHeight: MediaQuery.textScalerOf(context).scale(60),
            leading: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => pageContext.canPop()
                  ? pageContext.pop()
                  : pageContext.go('/trang-chu'),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ProfileTheme.orange,
                size: 22,
              ),
            ),
            title: const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileHeader(
                        profile: profile,
                        avatarBytes: state.avatarBytes,
                        onEdit: _busy ? null : () => _edit(pageContext),
                        onEditAvatar: _busy ? null : _pickAvatar,
                      ),
                      ProfileSection(
                        title: 'Cứu hộ khẩn cấp',
                        icon: Icons.health_and_safety_outlined,
                        onEdit: _busy ? null : () => _edit(pageContext),
                        children: [
                          ProfileInfoRow(
                            icon: Icons.emergency_outlined,
                            label: profile.emergencyContactName.isEmpty
                                ? 'Người thân nhận thông báo SOS'
                                : '${profile.emergencyContactName} • Liên hệ SOS',
                            value: profile.emergencyContactPhone,
                          ),
                          ProfileInfoRow(
                            icon: Icons.medical_information_outlined,
                            label: 'Ghi chú y tế',
                            value: profile.medicalNote,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ProfileSection(
                        title: 'Phương tiện & Địa chỉ',
                        icon: Icons.two_wheeler_rounded,
                        children: [
                          ProfileInfoRow(
                            icon: Icons.motorcycle_outlined,
                            label: 'Xe mặc định',
                            value: vehicle?.type ?? 'Chưa chọn xe mặc định',
                          ),
                          ProfileInfoRow(
                            icon: Icons.pin_outlined,
                            label: 'Biển số xe',
                            value: vehicle?.plate ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.tire_repair_rounded,
                            label: 'Loại lốp',
                            value: vehicle?.tireType ?? '',
                          ),
                          const Divider(color: HomeColors.border),
                          ProfileInfoRow(
                            icon: Icons.home_outlined,
                            label: 'Nhà',
                            value: profile.defaultAddress,
                          ),
                          ProfileInfoRow(
                            icon: Icons.business_outlined,
                            label: 'Cơ quan',
                            value: profile.workAddress,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ProfileSection(
                        title: 'Tài khoản & Bảo mật',
                        icon: Icons.shield_outlined,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.lock_outline_rounded,
                              color: ProfileTheme.muted,
                            ),
                            title: const Text('Đổi mật khẩu'),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: ProfileTheme.muted,
                            ),
                            onTap: _busy
                                ? null
                                : () => _changePassword(pageContext),
                          ),
                          const Divider(color: HomeColors.border),
                          SwitchListTile.adaptive(
                            key: const ValueKey('profile-biometric-switch'),
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.face_rounded,
                              color: ProfileTheme.muted,
                            ),
                            title: const Text('FaceID / Vân tay'),
                            subtitle: const Text(
                              'Xác thực khi chỉnh sửa hồ sơ',
                              style: TextStyle(
                                color: ProfileTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            activeTrackColor: ProfileTheme.red,
                            value: state.biometricEnabled,
                            onChanged: _busy ? null : _toggleBiometric,
                          ),
                          const Divider(color: HomeColors.border),
                          ProfileInfoRow(
                            icon: Icons.alternate_email_rounded,
                            label: 'Email liên kết',
                            value: profile.email.isEmpty
                                ? 'Chưa liên kết email'
                                : profile.email,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _logout(pageContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ProfileTheme.orange,
                          side: const BorderSide(color: ProfileTheme.orange),
                          minimumSize: const Size(48, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                        onPressed: _busy
                            ? null
                            : () => _deleteAccount(pageContext),
                        style: TextButton.styleFrom(
                          foregroundColor: ProfileTheme.red,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Xóa tài khoản'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hồ sơ dùng thử • Các thay đổi và tùy chọn bảo mật chỉ lưu trong phiên sử dụng.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ProfileTheme.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: HomeBottomNavigation(
            selectedDestination: HomeDestination.account,
            onSelected: (destination) =>
                navigateMainTab(pageContext, destination),
          ),
        ),
      ),
    );
  }
}
