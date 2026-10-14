import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/order_cancellation_reason.dart';

class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({super.key});

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  static const _blue = Color(0xFF1976D2);
  static const _blueTint = Color(0xFFEAF3FD);

  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  final FocusNode _customReasonFocus = FocusNode();

  OrderCancellationReason? get _reason => OrderCancellationReason.tryCreate(
    selectedReason: selectedReason,
    details: customReasonController.text,
  );

  @override
  void dispose() {
    customReasonController.dispose();
    _customReasonFocus.dispose();
    super.dispose();
  }

  void _select(String code) {
    setState(() => selectedReason = code);
    if (code == 'other') {
      _customReasonFocus.requestFocus();
    } else {
      _customReasonFocus.unfocus();
    }
  }

  void _confirm() {
    final reason = _reason;
    if (reason == null) return;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    // The invoking order screen may have a red theme. Scope every interactive
    // control here to blue, including focused inputs and text selection.
    final theme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: _blue,
        secondary: _blue,
        error: _blue,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _blue,
        selectionColor: Color(0x401976D2),
        selectionHandleColor: _blue,
      ),
    );
    return Theme(
      data: theme,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lý do bạn muốn hủy đơn?',
                  style: AppTextStyles.pageTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng chọn lý do để giúp Revo hỗ trợ bạn tốt hơn.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 20),
                for (final entry in OrderCancellationReason.options.entries)
                  _choice(entry.key, entry.value),
                const SizedBox(height: 8),
                Text(
                  selectedReason == 'other'
                      ? 'Chi tiết lý do'
                      : 'Ghi chú thêm (không bắt buộc)',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('cancel-custom-reason'),
                  controller: customReasonController,
                  focusNode: _customReasonFocus,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  cursorColor: _blue,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body.copyWith(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nhập chi tiết lý do của bạn...',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: Colors.black45,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.all(14),
                    border: _inputBorder(),
                    enabledBorder: _inputBorder(),
                    focusedBorder: _inputBorder(_blue),
                    helperText: selectedReason == 'other' && _reason == null
                        ? 'Vui lòng nhập lý do để xác nhận hủy.'
                        : null,
                    helperMaxLines: 2,
                    helperStyle: AppTextStyles.caption,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('cancel-confirm'),
                  onPressed: _reason == null ? null : _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE3EBF4),
                    disabledForegroundColor: const Color(0xFF8899AC),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  child: const Text(
                    'XÁC NHẬN HỦY',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('cancel-keep-order'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF547699),
                    minimumSize: const Size.fromHeight(44),
                    textStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục cứu hộ',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder([Color color = const Color(0xFFE5E7EB)]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Widget _choice(String code, String label) {
    final selected = selectedReason == code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? _blueTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('cancel-reason-$code'),
            onTap: () => _select(code),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _blue : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? _blue : const Color(0xFFA1A8B2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.4,
                      ),
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
