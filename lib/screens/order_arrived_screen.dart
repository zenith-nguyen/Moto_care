import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/code_input_boxes.dart';
import '../widgets/order_identity.dart';
import '../widgets/ui.dart';
import 'order_in_progress_screen.dart';

class OrderArrivedScreen extends StatefulWidget {
  const OrderArrivedScreen({super.key, required this.order});
  final ActiveOrder order;
  @override
  State<OrderArrivedScreen> createState() => _OrderArrivedScreenState();
}

class _OrderArrivedScreenState extends State<OrderArrivedScreen> {
  Timer? _ticker;
  late final TextEditingController _code;
  int _lastCooldown = 0;
  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.order.otp.draft);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.order.otp.cooldownSeconds;
      if (mounted && remaining != _lastCooldown) {
        _lastCooldown = remaining;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    try {
      final valid = await appState.verifyOtp(
          orderId: widget.order.orderId, code: widget.order.otp.draft);
      if (!mounted || !valid) return;
      FocusScope.of(context).unfocus();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => OrderInProgressScreen(order: widget.order)));
    } on StateError catch (e) {
      if (mounted) showAppSnack(context, e.message);
    }
  }

  Future<void> _paste() async {
    if (widget.order.otp.busy || widget.order.step != OrderStep.arrived) return;
    try {
      final data = await Clipboard.getData('text/plain');
      if (!mounted ||
          widget.order.otp.busy ||
          widget.order.step != OrderStep.arrived) {
        return;
      }
      final code = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
      setState(() {
        if (code.length != 4) {
          widget.order.otp.status = OtpActionState.error;
          widget.order.otp.message = 'Nội dung sao chép cần có đúng 4 chữ số.';
          return;
        }
        _code.text = code;
        widget.order.otp.draft = code;
        widget.order.otp.status = OtpActionState.idle;
        widget.order.otp.message = null;
      });
    } on PlatformException {
      if (mounted) {
        showAppSnack(context, 'Chưa đọc được mã sao chép. Vui lòng nhập mã.');
      }
    }
  }

  Future<void> _resend() async {
    try {
      await appState.resendOtp(
          orderId: widget.order.orderId, channel: widget.order.otp.channel);
    } on StateError catch (e) {
      if (mounted) showAppSnack(context, e.message);
    }
  }

  void _help() => showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
          child: Padding(
              padding: AppSpace.pageInsets,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Xác nhận bắt đầu sửa',
                        style: AppTypography.title),
                    const SizedBox(height: 12),
                    const Text(
                        'Mã thuộc đơn của khách hàng. Chỉ bắt đầu sửa sau khi đã đến nơi và khách cung cấp đúng mã.'),
                    if (appState.demoEnabled) ...[
                      const SizedBox(height: 12),
                      Text(
                          'Mã xác nhận demo: ${appState.demoCodeFor(widget.order.orderId)}',
                          style: AppTypography.label),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                        label: 'Đã hiểu', onPressed: () => Navigator.pop(ctx)),
                  ]))));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final o = widget.order;
        final otp = o.otp;
        final contact = otp.channel == OtpChannel.sms
            ? maskPhone(o.offer.customerPhone)
            : maskEmail(o.offer.customerEmail);
        return Scaffold(
            body: SafeArea(
                child: Column(children: [
          ScreenHeader(
              title: 'Xác nhận bắt đầu sửa',
              centerTitle: false,
              trailing: IconButton(
                  tooltip: 'Trợ giúp mã xác nhận',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: _help)),
          Expanded(
              child: ListView(padding: AppSpace.pageInsets, children: [
            SurfaceCard(
                color: AppColors.surfaceSoft,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Xác nhận mã từ khách hàng',
                                style: AppTypography.label),
                            const SizedBox(height: 6),
                            Text(
                                'Vui lòng yêu cầu khách hàng cung cấp mã xác nhận để bắt đầu sửa chữa.',
                                style: appText(12, color: AppColors.textSub)),
                          ])),
                    ])),
            const SizedBox(height: 12),
            OrderIdentityCard(offer: o.offer),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(
                  child: Text('Nhập mã xác nhận', style: AppTypography.label)),
              TextButton.icon(
                  onPressed: otp.busy ? null : _paste,
                  icon: const Icon(Icons.content_paste_rounded, size: 17),
                  label: const Text('Dán mã')),
            ]),
            const SizedBox(height: 10),
            LayoutBuilder(
                builder: (context, c) => Align(
                    alignment: Alignment.centerLeft,
                    child: CodeInputBoxes(
                        length: 4,
                        controller: _code,
                        autofocus: true,
                        initialValue: otp.draft,
                        enabled: !otp.busy && o.step == OrderStep.arrived,
                        hasError: otp.status == OtpActionState.error,
                        boxSize: ((c.maxWidth - 30) / 4).clamp(40, 62),
                        onSubmitted: (_) {
                          if (otp.draft.length == 4 && !otp.busy) _confirm();
                        },
                        onChanged: (v) => setState(() {
                              otp.draft = v;
                              if (otp.status == OtpActionState.error) {
                                otp.status = OtpActionState.idle;
                                otp.message = null;
                              }
                            })))),
            if (otp.message != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(otp.message!,
                      style: appText(12,
                          color: otp.status == OtpActionState.error
                              ? AppColors.dangerDark
                              : AppColors.successDark))),
            const SizedBox(height: 16),
            SurfaceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Gửi lại mã xác nhận cho khách qua:',
                      style: AppTypography.label),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (final channel in OtpChannel.values) ...[
                      if (channel == OtpChannel.email)
                        const SizedBox(width: 10),
                      Expanded(
                          child: ChoiceChip(
                              showCheckmark: false,
                              selectedColor: AppColors.surfaceSoft,
                              backgroundColor: Colors.white,
                              labelStyle: appText(12,
                                  color: AppColors.primaryDeep,
                                  weight: FontWeight.w600),
                              side: BorderSide(
                                  color: otp.channel == channel
                                      ? AppColors.primary
                                      : AppColors.border),
                              label: Text(
                                  channel == OtpChannel.sms ? 'SMS' : 'Email'),
                              avatar: Icon(
                                  channel == OtpChannel.sms
                                      ? Icons.sms_outlined
                                      : Icons.mail_outline,
                                  size: 18),
                              selected: otp.channel == channel,
                              onSelected: otp.busy
                                  ? null
                                  : (_) =>
                                      setState(() => otp.channel = channel))),
                    ]
                  ]),
                  const SizedBox(height: 6),
                  Text(contact, style: AppTypography.caption),
                  const SizedBox(height: 6),
                  if (otp.status == OtpActionState.sending)
                    const LinearProgressIndicator(),
                  TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      onPressed:
                          otp.busy || otp.cooldownSeconds > 0 ? null : _resend,
                      label: Text(otp.cooldownSeconds > 0
                          ? 'Gửi lại sau ${otp.cooldownSeconds}s'
                          : 'Gửi lại mã')),
                ])),
            if (appState.demoEnabled) ...[
              const SizedBox(height: 12),
              SurfaceCard(
                  color: AppColors.surfaceSoft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chế độ thử nghiệm',
                            style: AppTypography.label
                                .copyWith(color: AppColors.primaryDeep)),
                        const SizedBox(height: 5),
                        Text(
                            'Mã xác nhận demo: ${appState.demoCodeFor(o.orderId)}',
                            style: AppTypography.label),
                        const Text(
                            'SMS/Email chỉ được mô phỏng, không gửi đến người thật.',
                            style: AppTypography.caption),
                        TextButton.icon(
                            onPressed: () async {
                              final code = appState.demoCodeFor(o.orderId);
                              if (code == null) return;
                              await Clipboard.setData(
                                  ClipboardData(text: code));
                              if (context.mounted) {
                                showAppSnack(context, 'Đã sao chép mã demo.');
                              }
                            },
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            label: const Text('Sao chép mã')),
                      ])),
            ] else ...[
              const SizedBox(height: 12),
              Text('Dịch vụ OTP chưa được cấu hình.',
                  style: appText(12, color: AppColors.dangerDark)),
            ],
          ])),
          Padding(
              padding: AppSpace.footerInsets,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (otp.status == OtpActionState.verifying)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator()),
                PrimaryButton(
                    label: otp.status == OtpActionState.verifying
                        ? 'Đang xác minh…'
                        : 'Xác nhận',
                    onPressed: otp.draft.length == 4 &&
                            !otp.busy &&
                            o.step == OrderStep.arrived
                        ? _confirm
                        : null),
              ])),
        ])));
      });
}
