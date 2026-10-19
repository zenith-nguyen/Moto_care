import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_in_progress_screen.dart';

class OrderFinalQuoteScreen extends StatefulWidget {
  const OrderFinalQuoteScreen({
    super.key,
    required this.order,
    this.fromRepair = false,
  });
  final ActiveOrder order;
  final bool fromRepair;
  @override
  State<OrderFinalQuoteScreen> createState() => _OrderFinalQuoteScreenState();
}

class _OrderFinalQuoteScreenState extends State<OrderFinalQuoteScreen> {
  List<int> get _quantities =>
      widget.order.quoteDraft.map((line) => line.quantity).toList();
  int get _extra => widget.order.draftExtra;
  void _change(int index, int value) => appState.setQuoteQuantity(
        orderId: widget.order.orderId,
        index: index,
        quantity: value,
      );
  Future<void> _send() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận gửi báo giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.order.orderId} · ${widget.order.offer.customerName}',
            ),
            const SizedBox(height: 12),
            KeyValueRow('Phát sinh', formatVnd(_extra)),
            KeyValueRow(
              'Tổng đơn dự kiến',
              formatVnd(widget.order.offer.price + _extra),
            ),
            const SizedBox(height: 8),
            const Text('Chỉ thực hiện hạng mục bổ sung sau khi khách đồng ý.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xem lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận gửi'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;
    try {
      appState.sendQuote(orderId: widget.order.orderId);
    } on StateError catch (error) {
      showAppSnack(context, error.message);
    }
  }

  void _returnToRepair() {
    if (widget.fromRepair && Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderInProgressScreen(order: widget.order),
        ),
      );
    }
  }

  void _respond(bool accepted) {
    try {
      appState.resolveQuote(accepted, orderId: widget.order.orderId);
      if (accepted) _returnToRepair();
    } on StateError catch (error) {
      showAppSnack(context, error.message);
    }
  }

  Future<void> _omitRejectedWork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tiếp tục theo giá đã xác nhận?'),
        content: Text(
          'Không thực hiện và không thu tiền các hạng mục vừa bị từ chối. '
          'Chi phí giữ ở mức ${formatVnd(widget.order.finalPrice)}. '
          'Chỉ bàn giao khi xe đủ điều kiện an toàn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xem lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tiếp tục theo giá đã xác nhận'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      appState.continueWithoutRejectedQuote(orderId: widget.order.orderId);
      _returnToRepair();
    } on StateError catch (error) {
      showAppSnack(context, error.message);
    }
  }

  Future<void> _quantity(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MockData.quoteServices[index].$1,
                  style: appText(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Giảm ${MockData.quoteServices[index].$1}',
                      onPressed: _quantities[index] == 0
                          ? null
                          : () {
                              _change(index, _quantities[index] - 1);
                              update(() {});
                            },
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${_quantities[index]}',
                        textAlign: TextAlign.center,
                        style: appText(18, weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Thêm ${MockData.quoteServices[index].$1}',
                      onPressed: _quantities[index] == 9
                          ? null
                          : () {
                              _change(index, _quantities[index] + 1);
                              update(() {});
                            },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Xong',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _details() => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết báo giá',
                  style: appText(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                KeyValueRow('Giá ban đầu', formatVnd(widget.order.offer.price)),
                KeyValueRow(
                  'Phí phát sinh',
                  formatVnd(
                    widget.order.proposedPrice == null
                        ? _extra
                        : widget.order.proposedPrice! -
                            widget.order.offer.price,
                  ),
                ),
                if (widget.order.quoteReason != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      widget.order.quoteReason!,
                      style: appText(13, color: AppColors.textSub),
                    ),
                  ),
                const SizedBox(height: 12),
                PrimaryButton(
                    label: 'Đóng', onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final o = widget.order;
          final status = o.quoteStatus;
          final editing = status == QuoteStatus.none;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  ScreenHeader(
                    title: editing ? 'Báo giá phát sinh' : 'Phản hồi báo giá',
                    centerTitle: !editing,
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Tùy chọn báo giá',
                      icon: const Icon(Icons.more_horiz_rounded, size: 20),
                      onSelected: (action) {
                        if (action == 'details') _details();
                        if (action == 'retry') {
                          appState.cancelQuote(orderId: o.orderId);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Text('Chi tiết báo giá'),
                        ),
                        if (status == QuoteStatus.accepted ||
                            status == QuoteStatus.rejected)
                          const PopupMenuItem(
                            value: 'retry',
                            child: Text('Lập lại báo giá'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: editing
                        ? ListView(
                            key: const ValueKey('quote-editor'),
                            padding: AppSpace.pageInsets,
                            children: [
                              Text(
                                'Có thêm hạng mục phát sinh.\nVui lòng báo giá cho khách.',
                                style: appText(
                                  13,
                                  color: AppColors.textSub,
                                  height: 1.6,
                                ),
                              ),
                              if (o.rejectedQuoteNeedsAction) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Khách đã từ chối. Chỉnh sửa và gửi lại để khách duyệt.',
                                  style: appText(12, color: AppColors.danger),
                                ),
                              ],
                              const SizedBox(height: 16),
                              for (var i = 0;
                                  i < MockData.quoteServices.length;
                                  i++)
                                Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () => _quantity(i),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 50,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '0${i + 1}.',
                                            style: appText(
                                              10,
                                              color: AppColors.textSub,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${MockData.quoteServices[i].$1}${_quantities[i] > 0 ? ' × ${_quantities[i]}' : ''}',
                                              style: appText(
                                                13,
                                                weight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            formatVnd(
                                              MockData.quoteServices[i].$2 *
                                                  (_quantities[i] == 0
                                                      ? 1
                                                      : _quantities[i]),
                                            ),
                                            style: appText(
                                              13,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip:
                                                'Thêm ${MockData.quoteServices[i].$1}',
                                            onPressed: _quantities[i] < 9
                                                ? () => _change(
                                                    i, _quantities[i] + 1)
                                                : null,
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                              color: AppColors.textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              KeyValueRow(
                                'Tổng cộng',
                                formatVnd(_extra),
                                labelStyle:
                                    appText(13, weight: FontWeight.w700),
                                valueStyle:
                                    appText(20, weight: FontWeight.w700),
                              ),
                              Text(
                                'Giá gốc ${formatVnd(o.offer.price)} · Tổng đơn ${formatVnd(o.offer.price + _extra)}',
                                style: appText(11, color: AppColors.textSub),
                              ),
                              const SizedBox(height: 20),
                              PrimaryButton(
                                label: 'Gửi báo giá',
                                color: AppColors.primary,
                                onPressed: _extra > 0 ? _send : null,
                              ),
                              if (o.rejectedQuoteNeedsAction)
                                TextButton(
                                  onPressed: _omitRejectedWork,
                                  child: const Text('Bỏ phát sinh bị từ chối'),
                                ),
                            ],
                          )
                        : _result(status),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _result(QuoteStatus status) {
    final o = widget.order;
    final pending = status == QuoteStatus.pending;
    final accepted = status == QuoteStatus.accepted;
    final extra = o.submittedQuote.fold(0, (sum, line) => sum + line.amount);
    final color = pending
        ? AppColors.primary
        : accepted
            ? AppColors.success
            : AppColors.danger;
    return ListView(
      key: ValueKey('quote-result-${status.name}'),
      padding: AppSpace.pageInsets,
      children: [
        Center(
          child: IconCircle(
            icon: pending
                ? Icons.hourglass_empty_rounded
                : accepted
                    ? Icons.check_rounded
                    : Icons.close_rounded,
            size: 52,
            background: color.withValues(alpha: .1),
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pending
              ? 'Đang chờ khách duyệt'
              : accepted
                  ? 'Khách đã đồng ý báo giá'
                  : 'Khách từ chối báo giá',
          textAlign: TextAlign.center,
          style: appText(17, weight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          pending
              ? 'Chỉ tiếp tục hạng mục phát sinh sau khi khách đồng ý.'
              : accepted
                  ? 'Tiếp tục sửa chữa, kiểm tra và bàn giao trước khi hoàn thành.'
                  : o.rejectedQuoteNeedsAction
                      ? 'Chỉnh sửa và gửi lại, hoặc bỏ hạng mục bị từ chối để tiếp tục theo chi phí đã xác nhận.'
                      : 'Đã bỏ hạng mục bị từ chối. Tiếp tục theo chi phí đã xác nhận.',
          textAlign: TextAlign.center,
          style: appText(12, color: AppColors.textSub, height: 1.5),
        ),
        if (pending && appState.demoEnabled) ...[
          const SizedBox(height: 16),
          SurfaceCard(
            color: AppColors.light,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô phỏng phản hồi khách hàng',
                  style: appText(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Demo Mode · Dữ liệu mô phỏng, không gửi cho khách thật.',
                  style: appText(11, color: AppColors.textSub, height: 1.5),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Khách đồng ý báo giá',
                  onPressed: () => _respond(true),
                ),
                const SizedBox(height: 8),
                OutlineActionButton(
                  label: 'Khách từ chối báo giá',
                  color: AppColors.danger,
                  borderColor: AppColors.danger,
                  onPressed: () => _respond(false),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.offer.customerName,
                style: appText(15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã đơn ${o.orderId}',
                style: appText(12, color: AppColors.textSub),
              ),
              const Divider(height: 24),
              KeyValueRow('Chi phí ban đầu', formatVnd(o.offer.price)),
              KeyValueRow('Chi phí phát sinh', formatVnd(extra)),
              KeyValueRow(
                'Tổng tiền đề xuất',
                formatVnd(o.offer.price + extra),
                valueStyle: appText(
                  16,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (!pending)
                KeyValueRow('Chi phí đã xác nhận', formatVnd(o.finalPrice)),
              const Divider(height: 24),
              Text(
                'Hạng mục phát sinh',
                style: appText(13, weight: FontWeight.w600),
              ),
              for (final line in o.submittedQuote)
                KeyValueRow(
                  '${line.name} × ${line.quantity}',
                  formatVnd(line.amount),
                ),
              if (o.quoteSentAt != null) ...[
                const Divider(height: 24),
                KeyValueRow('Thời điểm gửi', formatDayTime(o.quoteSentAt!)),
              ],
              if (o.quoteResolvedAt != null)
                KeyValueRow(
                  'Khách phản hồi',
                  formatDayTime(o.quoteResolvedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (status == QuoteStatus.rejected && o.rejectedQuoteNeedsAction) ...[
          PrimaryButton(
            label: 'Chỉnh sửa và gửi lại báo giá',
            onPressed: () => appState.cancelQuote(orderId: o.orderId),
          ),
          const SizedBox(height: 8),
          OutlineActionButton(
            label: 'Bỏ phát sinh bị từ chối',
            onPressed: _omitRejectedWork,
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(label: 'Quay lại đơn hàng', onPressed: _returnToRepair),
        const SizedBox(height: 12),
      ],
    );
  }
}
