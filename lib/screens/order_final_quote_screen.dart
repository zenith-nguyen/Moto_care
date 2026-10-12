import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/ui.dart';
import 'order_received_screen.dart';

/// Bước 4/5: Báo giá cuối khác giá ban đầu. Khách có 10 phút để đồng ý / từ chối.
class OrderFinalQuoteScreen extends StatefulWidget {
  const OrderFinalQuoteScreen({super.key, required this.order});

  final ActiveOrder order;

  static const Duration responseWindow = Duration(minutes: 10);

  @override
  State<OrderFinalQuoteScreen> createState() => _OrderFinalQuoteScreenState();
}

class _OrderFinalQuoteScreenState extends State<OrderFinalQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _reasonController = TextEditingController();

  ActiveOrder get _order => widget.order;

  int get _proposed => int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    if (_order.quoteStatus != QuoteStatus.none) {
      _priceController.text = '${_order.proposedPrice}';
      _reasonController.text = _order.quoteReason ?? '';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    appState.sendQuote(_proposed, _reasonController.text.trim());
  }

  Future<void> _cancelQuote() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hủy đề xuất giá?', style: appText(19, weight: FontWeight.w600)),
        content: Text(
          'Đơn sẽ giữ nguyên giá ban đầu ${formatVnd(_order.offer.price)}.',
          style: appText(15, color: AppColors.textSub, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Không',
              style: appText(15, weight: FontWeight.w600, color: AppColors.textSub),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Hủy đề xuất',
              style: appText(15, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    appState.cancelQuote();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final status = _order.quoteStatus;
        final editing = status == QuoteStatus.none;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const ScreenHeader(title: 'Đề xuất giá cuối'),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ScrollColumn(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      children: [
                        const StepProgressBar(current: 4, steps: orderStepLabels),
                        const SizedBox(height: 20),
                        _PriceCard(
                          initial: _order.offer.price,
                          proposed: editing ? _proposed : _order.proposedPrice!,
                          editing: editing,
                          controller: _priceController,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 22),
                        const FieldLabel('Lý do phát sinh', required: true),
                        TextFormField(
                          controller: _reasonController,
                          readOnly: !editing,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          style: appText(15, height: 1.45),
                          decoration: InputDecoration(
                            hintText: 'vd. Lốp rách nặng cần thay ruột mới, phát sinh phụ tùng...',
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? 'Vui lòng ghi rõ lý do (tối thiểu 10 ký tự)'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (status == QuoteStatus.pending) ...[
                          _WaitingBlock(sentAt: _order.quoteSentAt!),
                          const SizedBox(height: 14),
                          const Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              StatusBadge.success('Khách đồng ý', icon: Icons.check),
                              StatusBadge.danger('Từ chối / Admin xem xét', icon: Icons.close),
                            ],
                          ),
                        ],
                        if (status == QuoteStatus.accepted)
                          SurfaceCard(
                            color: AppColors.successSoft,
                            radius: AppRadius.md,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                  size: 30,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Khách đã đồng ý giá mới ${formatVnd(_order.proposedPrice!)}. '
                                    'Bạn có thể hoàn thành công việc.',
                                    style: appText(14.5, weight: FontWeight.w500, height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: switch (status) {
                    QuoteStatus.none => PrimaryButton(
                        label: 'Gửi đề xuất cho khách',
                        onPressed: _send,
                      ),
                    QuoteStatus.pending => Column(
                        children: [
                          OutlineActionButton(
                            label: 'Nhắn khách',
                            onPressed: () => openOrderChat(context, _order),
                          ),
                          const SizedBox(height: 4),
                          MutedTextButton(
                            label: 'Hủy đề xuất',
                            color: AppColors.danger,
                            onPressed: _cancelQuote,
                          ),
                        ],
                      ),
                    QuoteStatus.accepted => PrimaryButton(
                        label: 'Quay lại hoàn thành đơn',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.initial,
    required this.proposed,
    required this.editing,
    required this.controller,
    required this.onChanged,
  });

  final int initial;
  final int proposed;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diff = proposed - initial;
    final diffText = proposed == 0 ? '—' : formatSignedVnd(diff.abs(), plus: diff >= 0);
    return SurfaceCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: [
          KeyValueRow('Giá ban đầu', formatVnd(initial)),
          editing
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Text('Giá đề xuất mới', style: appText(15, color: AppColors.textSub)),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.right,
                          style: appText(15, weight: FontWeight.w700),
                          decoration: const InputDecoration(
                            hintText: '140000',
                            suffixText: 'đ',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onChanged: (_) => onChanged(),
                          validator: (v) {
                            final n = int.tryParse(v ?? '') ?? 0;
                            if (n <= 0) return 'Nhập giá mới';
                            if (n == initial) return 'Giá mới phải khác';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : KeyValueRow('Giá đề xuất mới', formatVnd(proposed)),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chênh lệch',
                  style: appText(16, weight: FontWeight.w600, color: AppColors.danger),
                ),
              ),
              Text(
                diffText,
                style: appText(20, weight: FontWeight.w700, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chờ khách duyệt: vòng đếm ngược 10 phút màu vàng cam.
class _WaitingBlock extends StatelessWidget {
  const _WaitingBlock({required this.sentAt});
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CountdownRing(
            total: OrderFinalQuoteScreen.responseWindow,
            startedAt: sentAt,
            color: AppColors.warning,
            size: 72,
            strokeWidth: 6,
            fontSize: 15,
            labelBuilder: formatMSs,
            onFinished: () => showAppSnack(
              context,
              'Khách chưa phản hồi trong 10 phút. Đơn chuyển sang tranh chấp để Admin xử lý.',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang chờ khách duyệt',
                  style: appText(16.5, weight: FontWeight.w600, color: AppColors.warningDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tự hết hạn nếu không phản hồi kịp',
                  style: appText(13.5, color: AppColors.warningDark, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
