import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_dependencies.dart';
import '../../activity/data/activity_api_orders.dart';
import '../domain/order_models.dart';
import '../domain/order_status.dart';

/// Customer action card for the final price proposed by the provider.
///
/// The legacy customer activity UI still renders [RescueOrder], while the
/// final-price workflow belongs to the newer orders API model. This widget
/// deliberately loads the authoritative order detail so the approval action
/// cannot be hidden by the legacy mapping.
class FinalPriceApprovalCard extends ConsumerStatefulWidget {
  const FinalPriceApprovalCard({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<FinalPriceApprovalCard> createState() =>
      _FinalPriceApprovalCardState();
}

class _FinalPriceApprovalCardState
    extends ConsumerState<FinalPriceApprovalCard> {
  OrderDetails? _details;
  Object? _failure;
  bool _loading = true;
  bool _busy = false;

  int? get _parsedOrderId => int.tryParse(widget.orderId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orderId = _parsedOrderId;
    if (orderId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final details = await ref.read(ordersRepositoryProvider).getById(orderId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _failure = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error;
        _loading = false;
      });
    }
  }

  Future<void> _approve() async {
    final details = _details;
    final proposal = details?.priceProposal;
    if (_busy || details == null || proposal == null) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(ordersRepositoryProvider)
          .approveFinalPrice(orderId: details.id, proposalId: proposal.id);
      ref.invalidate(activityApiOrdersProvider);
      if (!mounted) return;

      if (result.orderStatus == OrderStatus.awaitingPayment) {
        context.go('/bank-transfer?id=${details.id}');
        return;
      }

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã duyệt giá cuối.')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  Future<void> _reject() async {
    final reason = await _askRejectReason();
    final details = _details;
    final proposal = details?.priceProposal;
    if (!mounted || reason == null || details == null || proposal == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .rejectFinalPrice(
            orderId: details.id,
            proposalId: proposal.id,
            reason: reason,
          );
      ref.invalidate(activityApiOrdersProvider);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối giá. Thợ có thể tiếp tục xử lý.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  Future<String?> _askRejectReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối giá cuối'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            hintText: 'Ví dụ: Giá phát sinh chưa rõ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length < 3) return;
              Navigator.pop(context, value);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Không thể cập nhật giá: $error')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failure != null) return const SizedBox.shrink();
    final details = _details;
    final proposal = details?.priceProposal;
    if (details == null ||
        proposal == null ||
        details.status != OrderStatus.awaitingPriceApproval ||
        proposal.status != PriceProposalStatus.pending) {
      return const SizedBox.shrink();
    }

    final price = int.tryParse(
      proposal.proposedFinalPrice.value.split('.').first,
    );
    final formattedPrice = price == null
        ? proposal.proposedFinalPrice.value
        : '${NumberFormat('#,###', 'vi_VN').format(price)} đ';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0C98A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Color(0xFFE68A00)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thợ đề xuất giá cuối',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedPrice,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Lý do: ${proposal.reason}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _approve,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Duyệt giá'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
