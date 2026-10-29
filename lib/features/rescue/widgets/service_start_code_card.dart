import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/theme/home_theme.dart';
import '../../orders/domain/order_action_results.dart';
import '../providers/service_start_token_provider.dart';
import '../theme/order_tracking_theme.dart';

/// Shows the customer the start code their mechanic must enter to begin the
/// repair. Only meaningful once the provider has marked themselves as arrived;
/// until then [serviceStartTokenProvider] yields `null` and we show a short
/// hint instead.
class ServiceStartCodeCard extends ConsumerWidget {
  const ServiceStartCodeCard({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(serviceStartTokenProvider(orderId));
    return token.when(
      loading: () => const _CodeShell(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Đang chuẩn bị mã bắt đầu dịch vụ…')),
          ],
        ),
      ),
      error: (_, _) => _CodeShell(
        child: Row(
          children: [
            const Expanded(child: Text('Không tải được mã bắt đầu dịch vụ.')),
            TextButton(
              onPressed: () =>
                  ref.invalidate(serviceStartTokenProvider(orderId)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (value) => value == null
          ? const _CodeShell(
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 20,
                    color: OrderTrackingColors.muted,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Khi thợ xác nhận đã đến nơi, mã bắt đầu dịch vụ sẽ '
                      'hiện ở đây để bạn đưa cho thợ.',
                      style: TextStyle(
                        color: OrderTrackingColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _StartCode(token: value),
    );
  }
}

class _StartCode extends StatefulWidget {
  const _StartCode({required this.token});

  final ServiceStartToken token;

  @override
  State<_StartCode> createState() => _StartCodeState();
}

class _StartCodeState extends State<_StartCode> {
  Timer? _ticker;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final left = widget.token.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.token.token));
    if (!mounted) return;
    setState(() => _copied = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final expired = remaining == Duration.zero;
    return _CodeShell(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.vpn_key_rounded,
                size: 20,
                color: HomeColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mã bắt đầu dịch vụ',
                  style: TextStyle(
                    color: HomeColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                expired ? 'Đang làm mới…' : 'Hết hạn sau $minutes:$seconds',
                style: const TextStyle(
                  color: OrderTrackingColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Đọc hoặc đưa mã này cho thợ để bắt đầu sửa. Không chia sẻ mã '
            'cho người khác.',
            style: TextStyle(
              color: OrderTrackingColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HomeColors.accentBorder),
            ),
            child: SelectableText(
              widget.token.token,
              style: const TextStyle(
                color: HomeColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _copy,
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 18,
            ),
            label: Text(_copied ? 'Đã sao chép' : 'Sao chép mã'),
          ),
        ],
      ),
    );
  }
}

class _CodeShell extends StatelessWidget {
  const _CodeShell({required this.child, this.tinted = false});

  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? HomeColors.tint : HomeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tinted ? HomeColors.accentBorder : OrderTrackingColors.border,
        ),
      ),
      child: child,
    );
  }
}
