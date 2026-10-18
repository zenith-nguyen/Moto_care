import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../theme/admin_order_theme.dart';
import 'admin_common.dart';
import 'admin_order_common.dart';

/// Shared tracking layout for request queues and mechanic applications.
class AdminReviewCard extends StatelessWidget {
  const AdminReviewCard({
    super.key,
    required this.title,
    required this.status,
    required this.fields,
    this.titleLabel = 'Mã đơn hàng:',
    this.receivedLabel = 'Đã nhận đơn',
    this.processingLabel = 'Đang xử lý',
    this.actions = const [],
  });

  final String title;
  final String titleLabel;
  final AdminReviewStatus status;
  final List<AdminField> fields;
  final String receivedLabel;
  final String processingLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    color: AdminTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final identity = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleLabel, style: AdminOrderTheme.label),
                const SizedBox(height: 4),
                Text(title, style: AdminOrderTheme.title),
              ],
            );
            final badge = _ReviewStatusBadge(status: status);
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: badge),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                badge,
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < fields.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ReviewField(field: fields[i])),
              const SizedBox(width: 16),
              Expanded(
                child: i + 1 < fields.length
                    ? _ReviewField(field: fields[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        AdminReviewProgress(
          status: status,
          receivedLabel: receivedLabel,
          processingLabel: processingLabel,
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ],
    ),
  );
}

class AdminReviewCardList extends StatelessWidget {
  const AdminReviewCardList({super.key, required this.cards});
  final List<AdminReviewCard> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 900 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.2
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    },
  );
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.field});
  final AdminField field;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(field.label, style: AdminOrderTheme.label),
      const SizedBox(height: 4),
      DefaultTextStyle(style: AdminOrderTheme.value, child: field.value),
    ],
  );
}

class _ReviewStatusBadge extends StatelessWidget {
  const _ReviewStatusBadge({required this.status});
  final AdminReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      AdminReviewStatus.pending => (
        const Color(0xFFFFF4DE),
        AdminTokens.warning,
      ),
      AdminReviewStatus.approved => (
        AdminTokens.activePill,
        AdminTokens.primaryBlue,
      ),
      AdminReviewStatus.rejected => (
        const Color(0xFFFFEBEE),
        AdminTokens.primaryRed,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          status.label,
          style: AdminOrderTheme.value.copyWith(
            fontSize: 11,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Pending records confirm receipt only; a final decision completes processing.
/// No processing timestamps or intermediate server state are invented.
class AdminReviewProgress extends StatelessWidget {
  const AdminReviewProgress({
    super.key,
    required this.status,
    this.receivedLabel = 'Đã nhận đơn',
    this.processingLabel = 'Đang xử lý',
  });
  final AdminReviewStatus status;
  final String receivedLabel;
  final String processingLabel;

  @override
  Widget build(BuildContext context) {
    final completed = status == AdminReviewStatus.pending ? 1 : 3;
    final labels = [receivedLabel, processingLabel, 'Đã xong'];
    const pending = Color(0xFFD1D1D6);
    return Semantics(
      label: 'Tiến trình: $completed/3 mốc hoàn thành. ${status.label}',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 24,
              child: Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth / 6,
                    right: constraints.maxWidth / 6,
                    top: 11,
                    child: Row(
                      children: [
                        for (var i = 1; i < 3; i++)
                          Expanded(
                            child: ColoredBox(
                              color: i < completed ? AdminTokens.text : pending,
                              child: const SizedBox(height: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        Expanded(
                          child: Center(
                            child: i < completed
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('admin-review-step-$i-true'),
                                    size: 24,
                                    color: AdminTokens.text,
                                  )
                                : DecoratedBox(
                                    key: ValueKey('admin-review-step-$i-false'),
                                    decoration: const BoxDecoration(
                                      color: pending,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final label in labels)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AdminOrderTheme.label.copyWith(
                        fontSize: 10,
                        color: AdminTokens.text,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminReviewAction extends StatelessWidget {
  const AdminReviewAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: destructive
          ? const Color(0xFFFFEBEE)
          : AdminTokens.activePill,
      foregroundColor: destructive
          ? AdminTokens.primaryRed
          : AdminTokens.primaryBlue,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: AdminOrderTheme.value.copyWith(fontSize: 12),
    ),
    child: Text(label),
  );
}
