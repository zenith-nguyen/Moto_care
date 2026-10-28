import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/theme/revo_brand.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';
import '../../orders/presentation/incident_photos_card.dart';
import '../../wallet/application/provider_wallet_controller.dart';
import '../application/provider_location_tracking_controller.dart';
import '../application/provider_work_controller.dart';
import '../application/provider_work_state.dart';
import 'provider_formatters.dart';

class ProviderOrderDetailsScreen extends ConsumerStatefulWidget {
  const ProviderOrderDetailsScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProviderOrderDetailsScreen> createState() =>
      _ProviderOrderDetailsScreenState();
}

class _ProviderOrderDetailsScreenState
    extends ConsumerState<ProviderOrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrder);
  }

  Future<void> _loadOrder() async {
    await ref
        .read(providerWorkControllerProvider.notifier)
        .selectOrder(widget.orderId);
    final order = ref.read(providerWorkControllerProvider).value?.selectedOrder;
    if (order != null && providerOrderIsActive(order.status)) {
      await ref
          .read(providerLocationTrackingControllerProvider.notifier)
          .trackOrder(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final work = ref.watch(providerWorkControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn cứu hộ'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadOrder,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: work.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailsFailure(
          message: 'Không tải được đơn: $error',
          onRetry: _loadOrder,
        ),
        data: (state) {
          final order = state.selectedOrder;
          if (order == null || order.id != widget.orderId) {
            return const Center(child: CircularProgressIndicator());
          }
          return _OrderDetailsBody(order: order, state: state);
        },
      ),
    );
  }
}

class _OrderDetailsBody extends ConsumerWidget {
  const _OrderDetailsBody({required this.order, required this.state});

  final OrderDetails order;
  final ProviderWorkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RevoBrandColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.incidentType.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: RevoBrandColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text('Mã đơn: ${order.code}'),
              const SizedBox(height: 10),
              _StatusLabel(status: order.status),
            ],
          ),
        ),
        if (_isJourneyStatus(order.status)) ...[
          const SizedBox(height: 16),
          _OrderProgressCard(status: order.status),
        ],
        if (state.lastFailure != null) ...[
          const SizedBox(height: 14),
          _DetailsFailure(message: 'Thao tác thất bại: ${state.lastFailure}'),
        ],
        const SizedBox(height: 18),
        _DetailsCard(
          title: 'Vị trí khách hàng',
          icon: Icons.location_on_outlined,
          children: [
            Text(
              '${order.customerLocation.latitude.toStringAsFixed(6)}, '
              '${order.customerLocation.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openNavigation(order),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Mở chỉ đường'),
            ),
          ],
        ),
        IncidentPhotosCard(orderId: order.id),
        const SizedBox(height: 14),
        _DetailsCard(
          title: 'Thông tin dịch vụ',
          icon: Icons.handyman_outlined,
          children: [
            _DetailsRow(
              label: 'Giá tạm tính',
              value: formatProviderMoney(order.estimatedPrice),
            ),
            if (order.finalPrice != null)
              _DetailsRow(
                label: 'Giá cuối',
                value: formatProviderMoney(order.finalPrice!),
              ),
            if (order.vehicle != null) ...[
              const Divider(height: 28),
              _DetailsRow(
                label: 'Phương tiện',
                value: order.vehicle!.displayName,
              ),
              if (order.vehicle!.color != null)
                _DetailsRow(label: 'Màu xe', value: order.vehicle!.color!),
            ],
            if (order.message?.isNotEmpty == true) ...[
              const Divider(height: 28),
              Text(order.message!),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/provider/orders/${order.id}/chat'),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Nhắn khách'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callCustomer(context, ref, order.id),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Gọi khách'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _OrderAction(order: order, busy: state.isBusy),
      ],
    );
  }

  Future<void> _openNavigation(OrderDetails order) async {
    final point = order.customerLocation;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${point.latitude},${point.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callCustomer(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    try {
      final contact = await ref
          .read(ordersRepositoryProvider)
          .participantContact(orderId);
      final phone = contact.phone;
      if (phone == null || phone.isEmpty) {
        throw StateError('Khách hàng chưa cung cấp số điện thoại.');
      }
      await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể gọi khách: $error')));
    }
  }
}

class _OrderAction extends ConsumerWidget {
  const _OrderAction({required this.order, required this.busy});

  final OrderDetails order;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(providerWorkControllerProvider.notifier);
    return switch (order.status) {
      OrderStatus.accepted => FilledButton.icon(
        onPressed: busy ? null : controller.markArrived,
        icon: const Icon(Icons.location_on_rounded),
        label: const Text('Tôi đã đến nơi'),
      ),
      OrderStatus.arrived => FilledButton.icon(
        onPressed: busy ? null : () => _startService(context, controller),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Nhập mã và bắt đầu sửa'),
      ),
      OrderStatus.inProgress => FilledButton.icon(
        onPressed: busy ? null : () => _proposePrice(context, controller),
        icon: const Icon(Icons.request_quote_outlined),
        label: const Text('Đề xuất giá cuối'),
      ),
      OrderStatus.paid => FilledButton.icon(
        onPressed: busy ? null : () => _complete(context, ref, controller),
        icon: const Icon(Icons.task_alt_rounded),
        label: const Text('Hoàn tất dịch vụ'),
      ),
      OrderStatus.awaitingPriceApproval => const _WaitingMessage(
        text: 'Đang chờ khách hàng duyệt giá cuối.',
      ),
      OrderStatus.priceDisputed => const _WaitingMessage(
        text: 'Tranh chấp giá đang chờ quản trị viên xử lý.',
      ),
      OrderStatus.awaitingPayment => const _WaitingMessage(
        text: 'Đang chờ quyết toán phần chênh lệch sandbox.',
      ),
      OrderStatus.completed => _CompletedState(order: order),
      _ => _WaitingMessage(
        text:
            'Không có thao tác dành cho trạng thái '
            '${providerOrderStatusLabel(order.status)}.',
      ),
    };
  }

  Future<void> _startService(
    BuildContext context,
    ProviderWorkController controller,
  ) async {
    final token = await _showTextDialog(
      context,
      title: 'Mã bắt đầu dịch vụ',
      label: 'Nhập mã do khách hàng cung cấp',
      minLines: 1,
    );
    if (token != null) await controller.startService(token);
  }

  Future<void> _proposePrice(
    BuildContext context,
    ProviderWorkController controller,
  ) async {
    final result = await showDialog<({String price, String reason})>(
      context: context,
      builder: (context) => const _PriceProposalDialog(),
    );
    if (result == null) return;
    await controller.proposeFinalPrice(
      finalPrice: result.price,
      reason: result.reason,
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    ProviderWorkController controller,
  ) async {
    await controller.completeService();
    if (!context.mounted) return;
    final latest = ref
        .read(providerWorkControllerProvider)
        .value
        ?.selectedOrder;
    if (latest?.status != OrderStatus.completed) return;
    ref.invalidate(providerWalletControllerProvider);
    await ref
        .read(providerLocationTrackingControllerProvider.notifier)
        .resumeWaiting();
  }
}

class _PriceProposalDialog extends StatefulWidget {
  const _PriceProposalDialog();

  @override
  State<_PriceProposalDialog> createState() => _PriceProposalDialogState();
}

class _PriceProposalDialogState extends State<_PriceProposalDialog> {
  final _price = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đề xuất giá cuối'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Giá cuối (VND)',
              hintText: 'Ví dụ: 150000',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nội dung công việc / lý do',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final rawPrice = _price.text.trim();
            final reason = _reason.text.trim();
            if (rawPrice.isEmpty || reason.length < 5) return;
            Navigator.pop(context, (
              price: rawPrice.contains('.') ? rawPrice : '$rawPrice.00',
              reason: reason,
            ));
          },
          child: const Text('Gửi đề xuất'),
        ),
      ],
    );
  }
}

Future<String?> _showTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  required int minLines,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 5,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result?.isEmpty == true ? null : result;
}

bool _isJourneyStatus(OrderStatus status) => switch (status) {
  OrderStatus.accepted ||
  OrderStatus.arrived ||
  OrderStatus.inProgress ||
  OrderStatus.awaitingPriceApproval ||
  OrderStatus.priceDisputed ||
  OrderStatus.awaitingPayment ||
  OrderStatus.paid ||
  OrderStatus.completed => true,
  _ => false,
};

/// Horizontal progress stepper for the provider's job journey, mirroring the
/// REVO reference. Driven by the real [OrderStatus].
class _OrderProgressCard extends StatelessWidget {
  const _OrderProgressCard({required this.status});

  final OrderStatus status;

  static const _labels = [
    'Đã nhận',
    'Đến nơi',
    'Đang sửa',
    'Chốt giá',
    'Hoàn tất',
  ];

  int get _currentStep => switch (status) {
    OrderStatus.accepted => 0,
    OrderStatus.arrived => 1,
    OrderStatus.inProgress => 2,
    OrderStatus.awaitingPriceApproval ||
    OrderStatus.priceDisputed ||
    OrderStatus.awaitingPayment ||
    OrderStatus.paid => 3,
    OrderStatus.completed => 4,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final current = _currentStep;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: _StepNode(
                  label: _labels[i],
                  done: i < current,
                  active: i == current,
                  showLeftLine: i != 0,
                  showRightLine: i != _labels.length - 1,
                  leftLineDone: i <= current,
                  rightLineDone: i < current,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.done,
    required this.active,
    required this.showLeftLine,
    required this.showRightLine,
    required this.leftLineDone,
    required this.rightLineDone,
  });

  final String label;
  final bool done;
  final bool active;
  final bool showLeftLine;
  final bool showRightLine;
  final bool leftLineDone;
  final bool rightLineDone;

  Color _line(bool lineDone) =>
      lineDone ? RevoBrandColors.primary : RevoBrandColors.border;

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                color: showLeftLine ? _line(leftLineDone) : Colors.transparent,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: reached
                    ? RevoBrandColors.primary
                    : RevoBrandColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached
                      ? RevoBrandColors.primary
                      : RevoBrandColors.border,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : active
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                height: 3,
                color: showRightLine
                    ? _line(rightLineDone)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: reached ? RevoBrandColors.ink : RevoBrandColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: RevoBrandColors.primaryDeep),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Text(
      providerOrderStatusLabel(status),
      style: const TextStyle(
        color: RevoBrandColors.primaryDeep,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _WaitingMessage extends StatelessWidget {
  const _WaitingMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoBrandColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: RevoBrandColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _CompletedState extends StatefulWidget {
  const _CompletedState({required this.order});

  final OrderDetails order;

  @override
  State<_CompletedState> createState() => _CompletedStateState();
}

class _CompletedStateState extends State<_CompletedState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finalPrice = widget.order.finalPrice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: RevoBrandColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RevoBrandColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: RevoBrandColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Đơn đã hoàn tất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RevoBrandColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cảm ơn bạn đã hoàn thành đơn cứu hộ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RevoBrandColors.textSubtle),
          ),
          if (finalPrice != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatProviderMoney(finalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: RevoBrandColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Thu nhập đã được cộng vào ví của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RevoBrandColors.textSubtle, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DetailsFailure extends StatelessWidget {
  const _DetailsFailure({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: RevoBrandColors.dangerDark),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
