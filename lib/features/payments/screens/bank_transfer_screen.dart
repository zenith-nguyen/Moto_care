import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/network/api_failure.dart';
import '../../activity/data/activity_api_orders.dart';
import '../../activity/widgets/order_summary.dart';
import '../../orders/domain/order_status.dart';
import '../domain/bank_transfer_instructions.dart';

class BankTransferScreen extends ConsumerStatefulWidget {
  const BankTransferScreen({super.key, required this.orderId});

  final int? orderId;

  @override
  ConsumerState<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends ConsumerState<BankTransferScreen> {
  BankTransferInstructions? _instructions;
  Object? _failure;
  bool _loading = true;
  bool _checking = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) {
      setState(() {
        _failure = const FormatException('Mã đơn thanh toán không hợp lệ.');
        _loading = false;
      });
      return;
    }
    try {
      final instructions = await ref
          .read(paymentsRepositoryProvider)
          .getTransferInstructions(orderId);
      if (!mounted) return;
      setState(() {
        _instructions = instructions;
        _failure = null;
        _loading = false;
      });
      _poller = Timer.periodic(
        const Duration(seconds: 4),
        (_) => unawaited(_checkPayment(silent: true)),
      );
    } catch (error) {
      if (!mounted) return;
      // 409 (conflict) nghĩa là đơn không còn chờ chuyển khoản, gần như chắc
      // chắn đã thanh toán xong (webhook SePay đã xác nhận). Thay vì hiện màn
      // lỗi (nút "Thử lại" sẽ chỉ lặp lại 409), kiểm tra trạng thái đơn và tự
      // điều hướng sang màn theo dõi đơn.
      if (error is ApiFailure && error.kind == ApiFailureKind.conflict) {
        final moved = await _checkPayment(silent: true);
        if (moved || !mounted) return;
      }
      if (!mounted) return;
      setState(() {
        _failure = error;
        _loading = false;
      });
    }
  }

  Future<bool> _checkPayment({bool silent = false}) async {
    final orderId = widget.orderId;
    if (_checking || orderId == null) return false;
    setState(() => _checking = true);
    try {
      final order = await ref.read(ordersRepositoryProvider).getById(orderId);
      if (!mounted) return false;
      if (order.status != OrderStatus.awaitingPrepayment) {
        _poller?.cancel();
        ref.invalidate(activityApiOrdersProvider);
        context.go('/order-tracking?id=$orderId');
        return true;
      }
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa nhận được xác nhận chuyển khoản.'),
          ),
        );
      }
      return false;
    } catch (error) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa kiểm tra được thanh toán: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _confirmDemo() async {
    final orderId = widget.orderId;
    if (_checking || orderId == null) return;
    setState(() => _checking = true);
    try {
      await ref.read(paymentsRepositoryProvider).confirmDemoPrepayment(orderId);
      if (!mounted) return;
      ref.invalidate(activityApiOrdersProvider);
      context.go('/order-tracking?id=$orderId');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xác nhận thanh toán thử: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _instructions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán chuyển khoản'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/hoat-dong'),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : data == null
            ? _PaymentError(
                error: _failure,
                onRetry: () {
                  setState(() => _loading = true);
                  unawaited(_load());
                },
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Quét QR để thanh toán',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giữ nguyên số tiền và nội dung. Sau khi SePay xác nhận, hệ thống sẽ tự chuyển sang màn hình tìm thợ.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE1E3E8)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          data.qrImageUri.toString(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'Không tải được QR. Hãy chuyển khoản bằng thông tin bên dưới.',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TransferRow(label: 'Ngân hàng', value: data.bank),
                  _TransferRow(
                    label: 'Số tài khoản',
                    value: data.accountNumber,
                    onCopy: () => _copy(data.accountNumber, 'số tài khoản'),
                  ),
                  _TransferRow(
                    label: 'Chủ tài khoản',
                    value: data.accountHolder,
                  ),
                  _TransferRow(
                    label: 'Số tiền',
                    value: formatOrderPrice(
                      int.parse(data.amount.value.split('.').first),
                    ),
                  ),
                  _TransferRow(
                    label: 'Nội dung',
                    value: data.transferContent,
                    onCopy: () =>
                        _copy(data.transferContent, 'nội dung chuyển khoản'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('check-bank-transfer'),
                    onPressed: _checking ? null : _checkPayment,
                    icon: _checking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('TÔI ĐÃ CHUYỂN KHOẢN'),
                  ),
                  if (data.simulationOnly) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _checking ? null : _confirmDemo,
                      child: const Text('Xác nhận thanh toán thử'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Đang chờ xác nhận thanh toán… Bạn có thể để màn hình này mở.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.label, required this.value, this.onCopy});
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    trailing: onCopy == null
        ? null
        : IconButton(
            tooltip: 'Sao chép $label',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
  );
}

class _PaymentError extends StatelessWidget {
  const _PaymentError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 12),
          const Text('Chưa tải được thông tin chuyển khoản.'),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
