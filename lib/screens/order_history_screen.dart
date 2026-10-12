import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_history_detail_screen.dart';
import 'order_received_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  /// null = tự chọn: có đơn đang làm thì mở "Đang thực hiện", không thì "Hoàn thành".
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final active = appState.activeOrder;
        final filter = _filter ?? (active != null ? OrderStatus.active : OrderStatus.completed);
        final completed = appState.history.where((o) => o.status == OrderStatus.completed).toList();
        final cancelled = appState.history.where((o) => o.status == OrderStatus.cancelled).toList();
        final items = filter == OrderStatus.completed ? completed : cancelled;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Lịch sử đơn', showBack: false),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Đang thực hiện',
                        count: active == null ? 0 : 1,
                        selected: filter == OrderStatus.active,
                        onTap: () => setState(() => _filter = OrderStatus.active),
                      ),
                      _FilterChip(
                        label: 'Hoàn thành',
                        count: completed.length,
                        selected: filter == OrderStatus.completed,
                        onTap: () => setState(() => _filter = OrderStatus.completed),
                      ),
                      _FilterChip(
                        label: 'Đã hủy',
                        count: cancelled.length,
                        selected: filter == OrderStatus.cancelled,
                        onTap: () => setState(() => _filter = OrderStatus.cancelled),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filter == OrderStatus.active
                    ? (active == null
                        ? const _Empty(
                            text:
                                'Không có đơn đang thực hiện.\nBật nhận đơn ở Trang chủ để nhận offer mới.',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            children: [_ActiveTile(order: active)],
                          ))
                    : items.isEmpty
                        ? const _Empty(text: 'Chưa có đơn nào.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, i) => _HistoryTile(
                              item: items[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderHistoryDetailScreen(item: items[i]),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text.rich(
              TextSpan(
                text: '$label ',
                style: appText(14.5, weight: FontWeight.w500, color: fg),
                children: [
                  TextSpan(
                      text: '$count', style: appText(14.5, weight: FontWeight.w700, color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.icon,
    required this.code,
    required this.badge,
    required this.subtitle,
    required this.amount,
    required this.earning,
    required this.onTap,
  });

  final IconData icon;
  final String code;
  final Widget badge;
  final String subtitle;
  final String amount;
  final String earning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          IconCircle(icon: icon, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(code, style: appText(16, weight: FontWeight.w600)),
                    badge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: appText(13.5, color: AppColors.textSub)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: appText(16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(earning,
                  style: appText(12.5, weight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});
  final OrderHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = item.status == OrderStatus.completed;
    return _OrderTile(
      icon: done ? Icons.bolt_outlined : Icons.close,
      code: item.code,
      badge: done ? const StatusBadge.success('Hoàn thành') : const StatusBadge.danger('Đã hủy'),
      subtitle: '${item.issue} · ${formatDayTime(item.time)}',
      amount: done ? formatVnd(item.finalPrice) : '—',
      earning: done ? 'TN +${formatShortVnd(item.earning)}' : 'TN 0đ',
      onTap: onTap,
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.order});
  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    final offer = order.offer;
    return _OrderTile(
      icon: Icons.bolt_outlined,
      code: offer.code,
      badge: const StatusBadge.pending('Đang thực hiện'),
      subtitle: '${offer.issue} · ${formatDayTime(order.acceptedAt).replaceAll(' · ', ' ')}',
      amount: formatVnd(order.finalPrice),
      earning: 'TN +${formatShortVnd(order.finalPrice - order.finalFee)}',
      onTap: () => openActiveOrder(context, order),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: appText(15, color: AppColors.textSub, height: 1.5),
        ),
      ),
    );
  }
}
