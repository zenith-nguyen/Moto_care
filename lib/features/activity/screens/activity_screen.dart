import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../models/activity_filter.dart';
import '../models/rescue_order.dart';
import '../providers/activity_provider.dart';
import '../services/activity_actions.dart';
import '../widgets/activity_order_card.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityFilter _filter = ActivityFilter.all;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _details(BuildContext context, RescueOrder order) async {
    final created = await context.push<bool>(
      '/chi-tiet-don-hang?id=${Uri.encodeQueryComponent(order.id)}',
    );
    if (mounted && created == true) _showLatest();
  }

  void _showLatest() {
    setState(() => _filter = ActivityFilter.all);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final orders =
        ref.watch(activityProvider).orders.where(_filter.includes).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Theme(
      data: HomeTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Hoạt động'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: HomeColors.surface,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            for (final filter in ActivityFilter.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  key: ValueKey(
                                    'activity-filter-${filter.name}',
                                  ),
                                  label: Text(filter.label),
                                  selected: _filter == filter,
                                  showCheckmark: false,
                                  backgroundColor: const Color(0xFFF1F1F1),
                                  selectedColor: HomeColors.selected,
                                  labelStyle: TextStyle(
                                    color: HomeColors.text,
                                    fontWeight: _filter == filter
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  side: BorderSide(
                                    color: _filter == filter
                                        ? HomeColors.primary
                                        : Colors.transparent,
                                  ),
                                  shape: const StadiumBorder(),
                                  onSelected: (_) {
                                    setState(() => _filter = filter);
                                    if (_scroll.hasClients) _scroll.jumpTo(0);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        'Dữ liệu mẫu • Lịch sử trong phiên dùng thử',
                        style: TextStyle(
                          color: HomeColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: orders.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      size: 52,
                                      color: HomeColors.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _filter == ActivityFilter.all
                                          ? 'Chưa có hoạt động nào'
                                          : 'Chưa có hoạt động ${_filter.label.toLowerCase()}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: HomeColors.secondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('activity-scroll'),
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                final date = order.createdAt.toLocal();
                                final previous = index == 0
                                    ? null
                                    : orders[index - 1].createdAt.toLocal();
                                final newMonth =
                                    previous == null ||
                                    date.month != previous.month ||
                                    date.year != previous.year;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (newMonth)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        child: Text(
                                          'Tháng ${date.month}/${date.year}',
                                          style: const TextStyle(
                                            color: HomeColors.secondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: ActivityOrderCard(
                                        key: ValueKey(order.id),
                                        order: order,
                                        onDetails: () =>
                                            _details(context, order),
                                        onRebook: () async {
                                          if (await ActivityActions.rebook(
                                                context,
                                                ref,
                                                order,
                                              ) &&
                                              mounted) {
                                            _showLatest();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: HomeBottomNavigation(
            light: true,
            selectedDestination: HomeDestination.activity,
            onSelected: (destination) => navigateMainTab(context, destination),
          ),
        ),
      ),
    );
  }
}
