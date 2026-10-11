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
  OrderStatus _filter = OrderStatus.completed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final active = appState.activeOrder;
        final cancelled = appState.history.where((o) => o.status == OrderStatus.cancelled).length;
        final items = appState.history.where((o) => o.status == _filter).toList();

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Text('Lịch sử đơn', style: appText(30, weight: FontWeight.w900)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Đang thực hiện · ${active == null ? 0 : 1}',
                      selected: _filter == OrderStatus.active,
                      onTap: () => setState(() => _filter = OrderStatus.active),
                    ),
                    _FilterChip(
                      label: 'Hoàn thành',
                      selected: _filter == OrderStatus.completed,
                      onTap: () => setState(() => _filter = OrderStatus.completed),
                    ),
                    _FilterChip(
                      label: 'Đã hủy · $cancelled',
                      selected: _filter == OrderStatus.cancelled,
                      onTap: () => setState(() => _filter = OrderStatus.cancelled),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filter == OrderStatus.active
                    ? _ActiveList(order: active)
                    : items.isEmpty
                        ? const _Empty(text: 'Chưa có đơn nào.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
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
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Text(
              label,
              style: appText(14.5,
                  weight: FontWeight.w700, color: selected ? Colors.white : AppColors.ink),
            ),
          ),
        ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            IconCircle(
              icon: item.service.icon,
              size: 52,
              background: done ? AppColors.successSoft : AppColors.surface,
              color: done ? AppColors.success : AppColors.textSub,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.code, style: appText(16.5, weight: FontWeight.w800)),
                      done
                          ? const StatusBadge.success('Hoàn thành')
                          : const StatusBadge(
                              label: 'Đã hủy',
                              foreground: AppColors.dangerDark,
                              background: AppColors.dangerSoft,
                            ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.issue} · ${formatDayTime(item.time)}',
                    style: appText(13.5, color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatVnd(item.finalPrice),
                  style: appText(16.5,
                      weight: FontWeight.w900, color: done ? AppColors.ink : AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                if (done)
                  Text(
                    'TN +${formatVnd(item.earning)}',
                    style: appText(12.5, weight: FontWeight.w600, color: AppColors.success),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({required this.order});
  final ActiveOrder? order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    if (o == null) {
      return const _Empty(
          text: 'Không có đơn đang thực hiện.\nBật nhận đơn ở Trang chủ để nhận offer mới.');
    }
    final step = o.step.index + 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        InkWell(
          onTap: () => openActiveOrder(context, o),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                IconCircle(icon: o.offer.service.icon, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(o.offer.code, style: appText(16.5, weight: FontWeight.w800)),
                          StatusBadge.pending('Bước $step/5'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.offer.issue} · ${orderStepLabels[o.step.index]}',
                        style: appText(13.5, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatVnd(o.finalPrice), style: appText(16.5, weight: FontWeight.w900)),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
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
