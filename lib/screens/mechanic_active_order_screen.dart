import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/add_extra_sheet.dart';
import '../widgets/common_widgets.dart';
import '../widgets/route_map.dart';
import '../widgets/step_progress.dart';

/// Màn 3 — Thực hiện đơn hàng & dẫn đường.
class MechanicActiveOrderScreen extends StatefulWidget {
  const MechanicActiveOrderScreen({super.key, required this.order});
  final OrderRequest order;

  @override
  State<MechanicActiveOrderScreen> createState() => _MechanicActiveOrderScreenState();
}

class _MechanicActiveOrderScreenState extends State<MechanicActiveOrderScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _stepLabels = [
    'Đã nhận đơn',
    'Đang đến chỗ khách',
    'Đã đến nơi',
    'Đang sửa chữa',
    'Hoàn thành',
  ];

  /// Nhãn nút chuyển bước, theo bước hiện tại.
  static const List<String> _actionLabels = [
    'Bắt đầu di chuyển',
    'Tôi đã đến nơi',
    'Bắt đầu sửa chữa',
    'Hoàn thành đơn hàng',
    'Về trang chủ',
  ];

  static const int _lastStep = 4;

  // Nhận đơn xong -> thợ đang trên đường tới khách (bước 1).
  int _step = 1;
  final List<ExtraItem> _extras = [];
  late final AnimationController _move;

  final List<Timer> _timers = [];

  /// Chỉ tính các khoản khách ĐÃ xác nhận.
  int get _extraTotal => _extras
      .where((e) => e.status == ExtraStatus.confirmed)
      .fold<int>(0, (sum, e) => sum + e.amount);
  bool get _hasPendingExtra => _extras.any((e) => e.status == ExtraStatus.pending);
  int get _totalIncome => widget.order.earning + _extraTotal;
  bool get _finished => _step == _lastStep;

  @override
  void initState() {
    super.initState();
    // Marker thợ chạy dọc tuyến trong lúc "Đang đến chỗ khách".
    _move = AnimationController(vsync: this, duration: const Duration(seconds: 26));
    _move.animateTo(0.88, curve: Curves.linear);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _move.dispose();
    super.dispose();
  }

  void _advance() {
    if (_finished) {
      Navigator.of(context).pop();
      return;
    }
    if (_step == 3 && _hasPendingExtra) {
      showAppSnack(context, 'Đang chờ khách xác nhận báo giá phát sinh. Vui lòng đợi hoặc hủy khoản đó.');
      return;
    }
    setState(() => _step += 1);
    if (_step == 2) {
      _move.animateTo(1.0, duration: const Duration(milliseconds: 700), curve: Curves.easeOut);
    }
    if (_step == _lastStep) {
      // Ghi nhận thu nhập, trừ chiết khấu, tăng số đơn (có thể lên hạng).
      AppScope.read(context).completeOrder(widget.order, _extraTotal);
    }
  }

  Future<void> _addExtra() async {
    final item = await showAddExtraSheet(context);
    if (item == null || !mounted) return;
    setState(() => _extras.add(item));
    showAppSnack(context, 'Đã gửi báo giá ${formatVnd(item.amount)} cho khách xác nhận.');
    // Mock: sau 4 giây khách bấm "Đồng ý" trên app của họ.
    _timers.add(Timer(const Duration(seconds: 4), () {
      if (!mounted || !_extras.contains(item)) return;
      setState(() => item.status = ExtraStatus.confirmed);
      showAppSnack(context, 'Khách đã xác nhận: ${item.description}.');
    }));
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Rời khỏi đơn đang làm?', style: appText(17, weight: FontWeight.w800)),
        content: Text(
          'Đơn ${widget.order.id} chưa hoàn thành. Thoát bây giờ sẽ hủy đơn này.',
          style: appText(14, color: AppColors.textSub, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Ở lại', style: appText(14, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Hủy đơn',
                style: appText(14, weight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  String get _statusText {
    switch (_step) {
      case 0:
        return 'Đã nhận đơn';
      case 1:
        return 'Còn ${formatKm(widget.order.distanceKm)} · ~${widget.order.etaMinutes} phút';
      case 2:
        return 'Đã đến nơi';
      case 3:
        return 'Đang sửa chữa';
      default:
        return 'Hoàn thành';
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFEDEFF1),
          body: Stack(
            children: [
              Positioned.fill(child: RouteMap(progress: _move)),
              // Lớp nổi phía trên bản đồ: nút back + chip trạng thái + card khách
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleIconButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Quay lại',
                            background: Colors.white,
                            foreground: AppColors.ink,
                            onTap: () {
                              if (_finished) {
                                Navigator.of(context).pop();
                              } else {
                                _confirmLeave();
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: AppShadows.soft,
                              ),
                              child: Row(
                                children: [
                                  Text(order.id, style: appText(13.5, weight: FontWeight.w800)),
                                  Container(
                                    width: 1,
                                    height: 16,
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    color: AppColors.border,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _statusText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: appText(13, weight: FontWeight.w600, color: AppColors.textSub),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CustomerCard(order: order),
                    ],
                  ),
                ),
              ),
              // Panel điều khiển phía dưới
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomPanel(
                  step: _step,
                  stepLabels: _stepLabels,
                  actionLabel: _actionLabels[_step],
                  baseIncome: order.earning,
                  extras: _extras,
                  totalIncome: _totalIncome,
                  finished: _finished,
                  onAdvance: _advance,
                  onAddExtra: _addExtra,
                  onRemoveExtra: (i) => setState(() => _extras.removeAt(i)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card thông tin khách nổi trên bản đồ + nút gọi / nhắn tin.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final OrderRequest order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${order.vehicle} · ${order.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(12.5, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.phone_outlined,
            tooltip: 'Gọi điện',
            onTap: () => showAppSnack(context, 'Đang gọi ${order.customerPhone} (demo)'),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Nhắn tin',
            onTap: () => showAppSnack(context, 'Mở tin nhắn với ${order.customerName} (demo)'),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.step,
    required this.stepLabels,
    required this.actionLabel,
    required this.baseIncome,
    required this.extras,
    required this.totalIncome,
    required this.finished,
    required this.onAdvance,
    required this.onAddExtra,
    required this.onRemoveExtra,
  });

  final int step;
  final List<String> stepLabels;
  final String actionLabel;
  final int baseIncome;
  final List<ExtraItem> extras;
  final int totalIncome;
  final bool finished;
  final VoidCallback onAdvance;
  final VoidCallback onAddExtra;
  final ValueChanged<int> onRemoveExtra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.op(0.12), blurRadius: 24, offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgress(current: step, labels: stepLabels),
              const SizedBox(height: 14),
              _IncomeSummary(
                baseIncome: baseIncome,
                extras: extras,
                totalIncome: totalIncome,
                canEdit: !finished,
                onRemove: onRemoveExtra,
              ),
              if (finished)
                _SuccessNote(total: totalIncome)
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onAddExtra,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      '+ Thêm phụ tùng phát sinh',
                      style: appText(13.5,
                          weight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onAdvance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: finished ? AppColors.ink : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      actionLabel,
                      key: ValueKey<String>(actionLabel),
                      style: appText(16, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeSummary extends StatelessWidget {
  const _IncomeSummary({
    required this.baseIncome,
    required this.extras,
    required this.totalIncome,
    required this.canEdit,
    required this.onRemove,
  });

  final int baseIncome;
  final List<ExtraItem> extras;
  final int totalIncome;
  final bool canEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          _line('Thu nhập đơn', formatVnd(baseIncome)),
          for (var i = 0; i < extras.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '+ ${extras[i].description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(13, color: AppColors.textSub),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: extras[i].status == ExtraStatus.confirmed
                          ? AppColors.successSoft
                          : AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      extras[i].status == ExtraStatus.confirmed ? 'Khách đã xác nhận' : 'Chờ khách xác nhận',
                      style: appText(10.5,
                          weight: FontWeight.w700,
                          color: extras[i].status == ExtraStatus.confirmed
                              ? AppColors.successDark
                              : const Color(0xFF9A5B00)),
                    ),
                  ),
                  Text(formatVnd(extras[i].amount),
                      style: appText(13, weight: FontWeight.w600)),
                  if (canEdit && extras[i].status == ExtraStatus.pending)
                    InkResponse(
                      radius: 18,
                      onTap: () => onRemove(i),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, size: 16, color: AppColors.textSub),
                      ),
                    ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Tổng thu nhập tạm tính',
                    style: appText(13.5, weight: FontWeight.w600)),
              ),
              Text(formatVnd(totalIncome),
                  style: appText(18, weight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: appText(13, color: AppColors.textSub))),
        Text(value, style: appText(13, weight: FontWeight.w600)),
      ],
    );
  }
}

class _SuccessNote extends StatelessWidget {
  const _SuccessNote({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: AppColors.successDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn hoàn tất — ${formatVnd(total)} đã được cộng vào ví.',
              style: appText(13.5, weight: FontWeight.w600, color: AppColors.successDark),
            ),
          ),
        ],
      ),
    );
  }
}
