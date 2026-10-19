import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_account_models.dart';
import '../models/admin_models.dart';

class AdminAccountCard extends StatelessWidget {
  const AdminAccountCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AdminTokens.surface,
      borderRadius: BorderRadius.all(Radius.circular(18)),
      boxShadow: [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: AdminTokens.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

class AdminAccountProfileCard extends StatelessWidget {
  const AdminAccountProfileCard({
    super.key,
    required this.session,
    required this.state,
    required this.onEdit,
    required this.onPassword,
    required this.onAvatar,
  });
  final AdminSession session;
  final AdminAccountState state;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) => AdminAccountCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final avatar = SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AdminTokens.activePill,
                    backgroundImage: state.avatarBytes == null
                        ? null
                        : MemoryImage(state.avatarBytes!),
                    child: state.avatarBytes == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: 42,
                            color: AdminTokens.primaryBlue,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filledTonal(
                      tooltip: 'Đổi ảnh đại diện',
                      onPressed: state.busy ? null : onAvatar,
                      style: IconButton.styleFrom(
                        backgroundColor: AdminTokens.surface,
                        foregroundColor: AdminTokens.primaryBlue,
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.profile.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTokens.activePill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AdminTokens.primaryBlue,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  state.profile.email,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AdminTokens.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${session.id}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AdminTokens.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                if (state.profile.phone.isNotEmpty)
                  Text(
                    state.profile.phone,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AdminTokens.muted,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
              ],
            );
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [avatar, const SizedBox(height: 14), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ProfileAction(
                  label: 'Chỉnh sửa hồ sơ',
                  icon: Icons.edit_outlined,
                  onTap: state.busy ? null : onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileAction(
                  label: 'Đổi mật khẩu',
                  icon: Icons.lock_outline_rounded,
                  onTap: state.busy ? null : onPassword,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: AdminTokens.text,
      side: const BorderSide(color: AdminTokens.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class AdminAccountSectionTitle extends StatelessWidget {
  const AdminAccountSectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AdminTokens.text,
          height: 1.5,
          letterSpacing: -0.3,
        ),
      ),
    ),
  );
}

class AdminAccountListTile extends StatelessWidget {
  const AdminAccountListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AdminAccountCard(
      padding: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AdminTokens.primaryBlue, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminTokens.text,
                        height: 1.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AdminTokens.muted,
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AdminTokens.muted,
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}
