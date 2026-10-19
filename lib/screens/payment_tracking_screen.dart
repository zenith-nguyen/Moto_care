import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/payout_request.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/progress_stepper.dart';
import '../widgets/ui.dart';
import 'order_history_detail_screen.dart';

/// Read-only tracking of a payout request sent to Admin. Nothing here can
/// change the request, the order or the wallet; the steps are not tappable.
class PaymentTrackingScreen extends StatelessWidget {
  const PaymentTrackingScreen({super.key, required this.request});
  final PayoutRequest request;

  static const _softBlue = Color(0xFFF1F7FC);

  (String, Color, Color, IconData) get _chip => switch (request.status) {
        PayoutStatus.received => (
            'Đã nhận đơn',
            AppColors.surfaceSoft,
            AppColors.primary,
            Icons.inbox_outlined
          ),
        PayoutStatus.processing => (
            'Đang xử lý',
            AppColors.surfaceSoft,
            AppColors.primary,
            Icons.schedule_rounded
          ),
        PayoutStatus.paid => (
            'Đã xử lý',
            AppColors.successSoft,
            AppColors.successDark,
            Icons.check_circle_outline_rounded
          ),
        PayoutStatus.rejected => (
            'Bị từ chối',
            AppColors.dangerSoft,
            AppColors.dangerDark,
            Icons.cancel_outlined
          ),
      };

  String get _progressNote => switch (request.status) {
        PayoutStatus.received ||
        PayoutStatus.processing =>
          'Admin đã tiếp nhận đề nghị của bạn.',
        PayoutStatus.paid => 'Admin đã xử lý đề nghị của bạn.',
        PayoutStatus.rejected =>
          request.rejectReason ?? 'Admin đã từ chối đề nghị này.',
      };

  String get _banner => switch (request.status) {
        PayoutStatus.paid => 'Admin đã xử lý đề nghị chi trả này.',
        PayoutStatus.rejected =>
          'Đề nghị không được chấp nhận nên chưa có khoản nào được chi trả.',
        _ =>
          'Khoản tiền chưa được ghi nhận là đã chi trả. Trạng thái sẽ cập nhật sau khi Admin xử lý.',
      };

  List<StepperStep> get _steps {
    final s = request.status;
    String? t(DateTime? d) => d == null ? null : formatHm(d);
    return [
      StepperStep('Đã nhận đơn', t(request.receivedAt), StepKind.done),
      StepperStep(
          'Đang xử lý',
          t(request.processingAt),
          s == PayoutStatus.received
              ? StepKind.pending
              : s == PayoutStatus.processing
                  ? StepKind.current
                  : StepKind.done),
      switch (s) {
        PayoutStatus.paid =>
          StepperStep('Đã xử lý', t(request.resolvedAt), StepKind.done),
        PayoutStatus.rejected =>
          StepperStep('Bị từ chối', t(request.resolvedAt), StepKind.failed),
        _ => const StepperStep('Đã xử lý', null, StepKind.pending),
      },
    ];
  }

  OrderHistoryItem? get _order {
    for (final o in appState.history) {
      if (o.orderId == request.orderCode) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipBg, chipFg, chipIcon) = _chip;
    final order = _order;
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      ScreenHeader(
          title: 'Theo dõi thanh toán',
          onBack: () => Navigator.of(context).maybePop()),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text('ĐỀ NGHỊ CHI TRẢ',
                        style: appText(11.5,
                            weight: FontWeight.w600,
                            color: AppColors.primary)))),
            const SizedBox(height: 12),
            Text('Theo dõi yêu cầu của bạn',
                key: const ValueKey('pay-title'),
                style: appText(25, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Yêu cầu đã gửi tới Admin để kiểm tra và xử lý.',
                style: appText(13.5, color: AppColors.textSub)),
            const SizedBox(height: 18),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Số tiền đề nghị',
                          style: appText(12.5, color: AppColors.textSub)),
                      const SizedBox(height: 4),
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatVnd(request.amount),
                              key: const ValueKey('pay-amount'),
                              style: appText(28, weight: FontWeight.w700))),
                    ])),
                const SizedBox(width: 8),
                Container(
                    key: const ValueKey('pay-status-chip'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(chipIcon, size: 15, color: chipFg),
                      const SizedBox(width: 5),
                      Text(chipLabel,
                          style: appText(12,
                              weight: FontWeight.w600, color: chipFg)),
                    ])),
              ]),
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: .7, color: AppColors.border),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Mã đơn hàng',
                          style: appText(12, color: AppColors.textSub)),
                      const SizedBox(height: 2),
                      Text(request.orderCode,
                          key: const ValueKey('pay-order-code'),
                          style: appText(17, weight: FontWeight.w700)),
                    ])),
                TextButton.icon(
                    key: const ValueKey('pay-copy'),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: request.orderCode));
                      if (context.mounted) {
                        showAppSnack(context, 'Đã sao chép mã đơn hàng.');
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text('Sao chép',
                        style: appText(13,
                            weight: FontWeight.w600,
                            color: AppColors.primary))),
              ]),
            ])),
            const SizedBox(height: 14),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tiến độ xử lý',
                  style: appText(17, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(_progressNote,
                  key: const ValueKey('pay-progress-note'),
                  style: appText(12.5, color: AppColors.textSub)),
              const SizedBox(height: 18),
              KeyedSubtree(
                  key: const ValueKey('pay-stepper'),
                  child: ProgressStepper(steps: _steps)),
            ])),
            const SizedBox(height: 14),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Thông tin đề nghị',
                  style: appText(17, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              _infoRow(Icons.build_outlined, 'Dịch vụ',
                  order?.issue ?? request.serviceName),
              const Divider(height: 1, thickness: .7, color: AppColors.border),
              _infoRow(Icons.description_outlined, 'Hình thức',
                  'Gửi Admin xét duyệt'),
            ])),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _softBlue, borderRadius: BorderRadius.circular(14)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_banner,
                              key: const ValueKey('pay-banner'),
                              style: appText(12, color: AppColors.textSub))),
                    ])),
            const SizedBox(height: 6),
            const Text('Dữ liệu demo · Chưa đồng bộ với Admin',
                textAlign: TextAlign.center, style: AppTypography.caption),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                  key: const ValueKey('pay-open-order'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: order == null
                      ? () => showAppSnack(
                          context, 'Không tìm thấy đơn hàng liên quan.')
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  OrderHistoryDetailScreen(item: order))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            child: Text('Xem đơn hàng liên quan',
                                style: AppTypography.button
                                    .copyWith(color: Colors.white))),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ])))),
    ])));
  }

  Widget _card(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.border, width: .7),
          boxShadow: AppShadows.soft),
      child: child);

  Widget _infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        IconCircle(
            icon: icon,
            size: 34,
            color: AppColors.ink,
            background: const Color(0xFFEEF3F8)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: appText(12, color: AppColors.textSub)),
          Text(value, style: appText(14.5, weight: FontWeight.w500)),
        ])),
      ]));
}
