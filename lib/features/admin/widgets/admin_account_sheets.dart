import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/admin_tokens.dart';
import '../data/admin_account_data.dart';
import '../models/admin_account_models.dart';
import '../providers/admin_account_provider.dart';
import '../providers/admin_providers.dart';
import 'admin_account_cards.dart';
import 'admin_common.dart';

enum AdminAccountSheet { staff, audit, logins, guide }

Future<void> showAdminAccountSheet(
  BuildContext context,
  AdminAccountSheet sheet,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _AccountSheet(sheet: sheet),
);

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet({required this.sheet});
  final AdminAccountSheet sheet;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminAccountProvider);
    final session = ref.watch(adminSessionProvider);
    final title = switch (sheet) {
      AdminAccountSheet.staff => 'Phân quyền Quản trị',
      AdminAccountSheet.audit => 'Nhật ký thao tác (Audit Trail)',
      AdminAccountSheet.logins => 'Lịch sử đăng nhập & Thiết bị',
      AdminAccountSheet.guide => 'Hướng dẫn Vận hành Admin',
    };
    final audit = ref.watch(adminAuditTrailProvider);
    final children = session?.isAdmin != true
        ? <Widget>[const AdminStateView.forbidden()]
        : switch (sheet) {
            AdminAccountSheet.staff => <Widget>[
              AdminAccountCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.profile.name,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(data.profile.email),
                    const SizedBox(height: 12),
                    AdminStatusChip(
                      session!.isSuperAdmin
                          ? 'SUPER ADMIN · Bạn'
                          : 'ADMIN · Bạn',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!session.isSuperAdmin)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Chỉ SUPER ADMIN được thay đổi phân quyền và ca trực.',
                  ),
                ),
              for (final member in data.staff)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminAccountCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          member.email,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AdminStatusChip(member.role.label),
                            AdminStatusChip(
                              member.onDuty ? 'Đang trực' : 'Ngoài ca',
                              color: member.onDuty
                                  ? AdminTokens.primaryBlue
                                  : AdminTokens.muted,
                            ),
                          ],
                        ),
                        if (session.isSuperAdmin)
                          TextButton.icon(
                            onPressed: data.busy
                                ? null
                                : () => showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) =>
                                        _StaffEditor(member: member),
                                  ),
                            icon: const Icon(
                              Icons.manage_accounts_outlined,
                              size: 18,
                            ),
                            label: const Text('Chỉnh quyền / ca trực'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
            AdminAccountSheet.audit => <Widget>[
              if (audit.isEmpty)
                const AdminStateView(
                  title: 'Chưa có thao tác được ghi nhận',
                  icon: Icons.history_rounded,
                  description: 'Các lần duyệt thợ, duyệt tiền và thay đổi cấu hình sẽ xuất hiện ở đây.',
                ),
              for (final entry in audit)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AdminTokens.primaryBlue,
                  ),
                  title: Text(
                    entry.action,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.target}\n${entry.actorName} · ${adminDate(entry.at)}',
                  ),
                ),
            ],
            AdminAccountSheet.logins => <Widget>[
              for (final login in data.logins)
                AdminAccountCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.devices_rounded,
                        color: AdminTokens.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        login.device,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(login.description),
                      const SizedBox(height: 8),
                      Text(
                        'Ghi nhận: ${adminDate(login.at)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AdminTokens.muted,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (login.current)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: AdminStatusChip('Đang hoạt động'),
                        ),
                    ],
                  ),
                ),
            ],
            AdminAccountSheet.guide => <Widget>[
              for (final section in AdminAccountData.guide)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: section == AdminAccountData.guide.first,
                  title: Text(
                    section.$1,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 20),
                  children: [
                    Text(
                      section.$2,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
            ],
          };
    return FractionallySizedBox(
      heightFactor: .85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffEditor extends ConsumerStatefulWidget {
  const _StaffEditor({required this.member});
  final AdminStaffMember member;
  @override
  ConsumerState<_StaffEditor> createState() => _StaffEditorState();
}

class _StaffEditorState extends ConsumerState<_StaffEditor> {
  late AdminStaffRole _role = widget.member.role;
  late bool _onDuty = widget.member.onDuty;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(adminAccountProvider).busy;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.member.name, textAlign: TextAlign.center),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AdminStaffRole>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: [
                  for (final role in AdminStaffRole.values)
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _role = value);
                      },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đang trực'),
                value: _onDuty,
                onChanged: busy
                    ? null
                    : (value) => setState(() => _onDuty = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: GoogleFonts.montserrat(
                    color: AdminTokens.primaryRed,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    final result = await ref
                        .read(adminAccountProvider.notifier)
                        .updateStaff(
                          widget.member.copyWith(role: _role, onDuty: _onDuty),
                        );
                    if (!context.mounted) return;
                    if (result.success) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _error = result.message);
                    }
                  },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
