import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/revo_theme.dart';
import '../application/provider_work_controller.dart';
import '../domain/provider_models.dart';
import 'provider_formatters.dart';

/// Outcome of the incoming-offer dialog, consumed by the shell to decide
/// whether to open the accepted order.
enum IncomingOfferOutcome { accepted, rejected, dismissed }

class IncomingOfferResult {
  const IncomingOfferResult(this.outcome, {this.orderId});
  final IncomingOfferOutcome outcome;
  final int? orderId;
}

/// Shows a prominent, ride-hailing style incoming rescue request.
///
/// All actions go through the real [ProviderWorkController] (accept/reject hit
/// the backend). The dialog never mutates money or state on its own.
Future<IncomingOfferResult?> showIncomingOfferDialog(
  BuildContext context,
  PendingOffer offer,
) {
  return showGeneralDialog<IncomingOfferResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'incoming-offer',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _IncomingOfferDialog(offer: offer),
    transitionBuilder: (context, anim, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _IncomingOfferDialog extends ConsumerStatefulWidget {
  const _IncomingOfferDialog({required this.offer});

  final PendingOffer offer;

  @override
  ConsumerState<_IncomingOfferDialog> createState() =>
      _IncomingOfferDialogState();
}

class _IncomingOfferDialogState extends ConsumerState<_IncomingOfferDialog> {
  Timer? _ticker;
  late Duration _total;
  late Duration _remaining;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _remaining = _timeLeft();
    // Capture the total window at open time so the ring starts full.
    _total = _remaining.inMilliseconds <= 0
        ? const Duration(seconds: 15)
        : _remaining;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _timeLeft();
      setState(() => _remaining = left);
      if (left <= Duration.zero) {
        _close(const IncomingOfferResult(IncomingOfferOutcome.dismissed));
      }
    });
  }

  Duration _timeLeft() {
    final diff = widget.offer.expiresAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _close(IncomingOfferResult result) {
    _ticker?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref
        .read(providerWorkControllerProvider.notifier)
        .acceptOffer(widget.offer);
    if (!mounted) return;
    final state = ref.read(providerWorkControllerProvider).value;
    if (state?.selectedOrder?.id == widget.offer.orderId) {
      _close(
        IncomingOfferResult(
          IncomingOfferOutcome.accepted,
          orderId: widget.offer.orderId,
        ),
      );
    } else {
      // Accept failed (expired / taken by someone else): surface and close.
      setState(() => _busy = false);
      final failure = state?.lastFailure;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không nhận được đơn: $failure')),
        );
      }
      _close(const IncomingOfferResult(IncomingOfferOutcome.dismissed));
    }
  }

  Future<void> _reject() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref
        .read(providerWorkControllerProvider.notifier)
        .rejectOffer(widget.offer);
    if (!mounted) return;
    _close(const IncomingOfferResult(IncomingOfferOutcome.rejected));
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final seconds = _remaining.inSeconds;
    final fraction = _total.inMilliseconds == 0
        ? 0.0
        : (_remaining.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final urgent = seconds <= 5;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: RevoBrandColors.surface,
                borderRadius: BorderRadius.circular(RevoRadius.hero),
                boxShadow: RevoShadows.modal,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header banner with the countdown.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: RevoGradients.balance,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yêu cầu cứu hộ mới',
                              style: RevoTypography.title.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CountdownRing(
                          fraction: fraction,
                          seconds: seconds,
                          urgent: urgent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phản hồi trước khi hết giờ',
                          style: RevoTypography.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.order.incidentType.name,
                          style: RevoTypography.heading,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mã đơn ${offer.order.code}',
                          style: RevoTypography.caption,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.payments_rounded,
                          label: 'Giá dự kiến',
                          value: formatProviderMoney(
                            offer.order.estimatedPrice,
                          ),
                          emphasize: true,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.place_rounded,
                          label: 'Vị trí khách',
                          value:
                              '${offer.order.customerLocation.latitude.toStringAsFixed(5)}, '
                              '${offer.order.customerLocation.longitude.toStringAsFixed(5)}',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _reject,
                                child: const Text('Từ chối'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _busy || seconds <= 0
                                    ? null
                                    : _accept,
                                child: _busy
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Nhận đơn'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.fraction,
    required this.seconds,
    required this.urgent,
  });

  final double fraction;
  final int seconds;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 7,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              urgent ? RevoBrandColors.warning : Colors.white,
            ),
          ),
          Center(
            child: Text(
              '${seconds}s',
              style: RevoTypography.heading.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RevoBrandColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: RevoBrandColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: RevoTypography.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: emphasize
                    ? RevoTypography.title.copyWith(
                        color: RevoBrandColors.primaryDeep,
                      )
                    : RevoTypography.label,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
