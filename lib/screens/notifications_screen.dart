import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/notification_feed.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/notification_glyph.dart';
import 'customer_reviews_screen.dart';
import 'incoming_order_popup.dart';
import 'mechanic_account_screen.dart';
import 'order_chat_screen.dart';
import 'order_final_quote_screen.dart';
import 'order_history_detail_screen.dart';
import 'order_received_screen.dart';
import 'wallet_transaction_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;
  late final Timer _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _filters() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('Lọc thông báo',
                        style: appText(17, weight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Đóng bộ lọc',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close,
                        color: AppColors.ink, size: 22)),
              ]),
              for (final filter in NotificationFilter.values)
                Semantics(
                    selected: _filter == filter,
                    child: ListTile(
                      key: ValueKey('notification-filter-${filter.name}'),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                          _filter == filter
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: AppColors.primary,
                          size: 22),
                      title: Text(notificationFilterLabels[filter.index],
                          style: appText(13,
                              weight: _filter == filter
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                      onTap: () {
                        setState(() => _filter = filter);
                        Navigator.pop(ctx);
                      },
                    )),
              const Divider(color: Color(0xFFE6EDF5)),
              ListTile(
                key: const ValueKey('notification-mark-all'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.done_all_rounded,
                    color: AppColors.primary, size: 22),
                title: Text('Đánh dấu tất cả đã đọc',
                    style: appText(13,
                        color: AppColors.primary, weight: FontWeight.w600)),
                onTap: () {
                  appState.markAllRead();
                  Navigator.pop(ctx);
                },
              ),
              if (appState.demoEnabled)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Dữ liệu demo · Thông báo lưu trong phiên hiện tại',
                        style: appText(9, color: AppColors.textSub))),
            ]),
          ),
        ),
      );

  Future<void> _open(RevoNotification notification) async {
    final destination =
        resolveNotification(notification, appState, DateTime.now());
    appState.markNotificationRead(notification);
    final active = destination.active;
    final order = destination.order;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    switch (destination.action) {
      case NotificationAction.request:
        await showIncomingOrder(context, destination.offer!);
      case NotificationAction.activeOrder:
        openActiveOrder(context, active!);
      case NotificationAction.quote:
        push(OrderFinalQuoteScreen(order: active!));
      case NotificationAction.chat:
        push(OrderChatScreen(
          orderId: active?.orderId ?? order!.code,
          customerName: active?.offer.customerName ?? order!.customerName,
          customerPhone: active?.offer.customerPhone ?? order!.customerPhone,
          messages: active?.messages ?? order!.messages,
          readOnly: active == null,
        ));
      case NotificationAction.history:
        push(OrderHistoryDetailScreen(item: order!));
      case NotificationAction.transaction:
        push(WalletTransactionDetailScreen(tx: destination.transaction!));
      case NotificationAction.documents:
        push(const DocumentsScreen());
      case NotificationAction.reviews:
        push(const CustomerReviewsScreen());
      case NotificationAction.detail:
      case NotificationAction.unavailable:
        await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text(
                      destination.action == NotificationAction.unavailable
                          ? 'Thông báo không còn khả dụng'
                          : notification.title,
                      style: appText(17, weight: FontWeight.w700)),
                  content: Text(
                      destination.reason ??
                          [
                            notification.body,
                            if (notification.detail != null)
                              notification.detail!
                          ].join('\n\n'),
                      style: appText(13)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Đóng',
                            style: appText(13,
                                color: AppColors.primary,
                                weight: FontWeight.w600)))
                  ],
                ));
    }
  }

  void _openTab(int index) {
    appState.setTab(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _header() => ColoredBox(
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF14213D), size: 22)),
          Expanded(
              child: Text('Thông báo',
                  textAlign: TextAlign.center,
                  style: appText(22,
                      color: const Color(0xFF14213D),
                      weight: FontWeight.w700,
                      height: 1.25))),
          IconButton(
              tooltip: 'Lọc thông báo',
              onPressed: _filters,
              icon: Badge(
                  isLabelVisible: _filter != NotificationFilter.all,
                  smallSize: 6,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.filter_list_rounded,
                      color: Color(0xFF14213D), size: 25))),
        ]),
      ));

  Widget _chips() => SingleChildScrollView(
        key: const ValueKey('notification-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          for (final filter in NotificationFilter.values.take(5)) ...[
            if (filter != NotificationFilter.all) const SizedBox(width: 8),
            Semantics(
              button: true,
              selected: _filter == filter,
              child: Material(
                key: ValueKey('notification-chip-${filter.name}'),
                color: _filter == filter
                    ? AppColors.primary
                    : const Color(0xFFF0F4F9),
                borderRadius: BorderRadius.circular(40),
                child: InkWell(
                  onTap: () => setState(() => _filter = filter),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 38, minWidth: 64),
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(notificationFilterLabels[filter.index],
                        style: appText(11.5,
                            height: 1.25,
                            weight: _filter == filter
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _filter == filter
                                ? Colors.white
                                : const Color(0xFF667085))),
                  ),
                ),
              ),
            ),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final now = DateTime.now();
          final items = appState.notifications
              .where((n) => matchesNotification(n, _filter))
              .toList();
          final groups = groupNotifications(items, now);
          final newIds = groups
              .expand((g) => g.items)
              .where((n) => !n.read)
              .take(2)
              .map((n) => n.id)
              .toSet();
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: SafeArea(
                bottom: false,
                child: Column(children: [
                  _header(),
                  _chips(),
                  Expanded(
                      child: groups.isEmpty
                          ? _empty()
                          : ListView(
                              key: const ValueKey('notification-list'),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              children: [
                                for (final group in groups) ...[
                                  Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          4, 14, 4, 8),
                                      child: Text(group.label,
                                          style: appText(16.5,
                                              color: const Color(0xFF14213D),
                                              weight: FontWeight.w700,
                                              height: 1.25))),
                                  for (var i = 0; i < group.items.length; i++)
                                    Padding(
                                        padding: EdgeInsets.only(
                                            bottom: i == group.items.length - 1
                                                ? 0
                                                : 10),
                                        child: _NotificationCard(
                                            notification: group.items[i],
                                            showNewBadge: newIds
                                                .contains(group.items[i].id),
                                            now: now,
                                            onTap: () =>
                                                _open(group.items[i]))),
                                ],
                              ],
                            )),
                ])),
            bottomNavigationBar: AppBottomNav(
                currentIndex: appState.tabIndex,
                inactiveLabelWeight: FontWeight.w500,
                onChanged: _openTab),
          );
        },
      );

  Widget _empty() => Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none_rounded,
              color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text('Chưa có thông báo',
              style: appText(16, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
              _filter == NotificationFilter.all
                  ? 'Thông báo mới sẽ xuất hiện tại đây.'
                  : 'Không có thông báo phù hợp bộ lọc này.',
              textAlign: TextAlign.center,
              style: appText(12, color: AppColors.textSub)),
          if (_filter != NotificationFilter.all)
            TextButton(
                onPressed: () =>
                    setState(() => _filter = NotificationFilter.all),
                child: Text('Xem tất cả thông báo',
                    style: appText(12, color: AppColors.primary))),
        ]),
      ));
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(
      {required this.notification,
      required this.showNewBadge,
      required this.now,
      required this.onTap});
  final RevoNotification notification;
  final bool showNewBadge;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: notification.read ? 'Đã đọc' : 'Chưa đọc',
        button: true,
        child: Material(
          key: ValueKey('notification-${notification.id}'),
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: Color(0xFFE5EBF2), width: .7)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: LayoutBuilder(builder: (context, box) {
                final separateTime = showNewBadge ||
                    box.maxWidth < 350 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.25;
                final title = Text(notification.title,
                    style: appText(13,
                        height: 1.25,
                        weight: notification.read
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: const Color(0xFF14213D)));
                final time = Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Text(notificationTime(notification.time, now),
                              textAlign: TextAlign.right,
                              style: appText(9.5,
                                  height: 1.25, color: AppColors.textSub))),
                      if (!notification.read) ...[
                        const SizedBox(width: 7),
                        Container(
                            key: ValueKey(
                                'notification-unread-${notification.id}'),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle)),
                      ],
                    ]);
                return Stack(children: [
                  Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEAF4FC),
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: NotificationGlyph(
                                    key: ValueKey(
                                        'notification-icon-${notification.id}'),
                                    type: notification.type)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  if (separateTime) ...[
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (showNewBadge)
                                            Container(
                                                key: ValueKey(
                                                    'notification-new-${notification.id}'),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5),
                                                decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: Text('MỚI',
                                                    style: appText(8,
                                                        height: 1.1,
                                                        color: Colors.white,
                                                        weight:
                                                            FontWeight.w600))),
                                          const SizedBox(width: 6),
                                          Expanded(
                                              child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: time)),
                                        ]),
                                    const SizedBox(height: 3),
                                    title,
                                  ] else
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: title),
                                          const SizedBox(width: 8),
                                          ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 105),
                                              child: time)
                                        ]),
                                  const SizedBox(height: 5),
                                  Padding(
                                      padding: const EdgeInsets.only(right: 18),
                                      child: Text(notification.body,
                                          style: appText(11.5,
                                              height: 1.3,
                                              color: AppColors.textSub))),
                                  if (notification.detail?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 3),
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(right: 14),
                                        child: Text(notification.detail!,
                                            style: appText(11,
                                                height: 1.3,
                                                color: AppColors.textSub))),
                                  ],
                                ])),
                          ])),
                  Positioned(
                      right: 10,
                      bottom: 16,
                      child: Icon(Icons.chevron_right_rounded,
                          key: ValueKey(
                              'notification-chevron-${notification.id}'),
                          color: AppColors.textSub,
                          size: 19)),
                ]);
              })),
        ),
      );
}
