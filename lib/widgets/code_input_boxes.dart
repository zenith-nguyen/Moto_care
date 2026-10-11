import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Ô nhập mã nhiều chữ số (OTP 6 số, mã bắt đầu sửa 4 số).
/// Một TextField ẩn nhận bàn phím, các ô hiển thị từng chữ số; ô đang nhập có viền đậm.
class CodeInputBoxes extends StatefulWidget {
  const CodeInputBoxes({
    super.key,
    required this.length,
    required this.onChanged,
    this.boxSize = 52,
    this.spacing = 10,
    this.autofocus = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final double boxSize;
  final double spacing;
  final bool autofocus;

  @override
  State<CodeInputBoxes> createState() => _CodeInputBoxesState();
}

class _CodeInputBoxesState extends State<CodeInputBoxes> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Semantics(
      label: 'Nhập mã ${widget.length} số',
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                _Box(
                  size: widget.boxSize,
                  digit: i < code.length ? code[i] : '',
                  active: _focus.hasFocus &&
                      (i == code.length ||
                          (code.length == widget.length && i == widget.length - 1)),
                  filled: i < code.length,
                ),
              ],
            ],
          ),
          // TextField trong suốt phủ lên các ô: chạm vào là mở bàn phím số.
          Positioned.fill(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {});
                widget.onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.size, required this.digit, required this.active, required this.filled});
  final double size;
  final String digit;
  final bool active;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size * 1.22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: active || filled ? AppColors.ink : AppColors.border,
          width: active ? 2 : (filled ? 1.2 : 1.4),
        ),
      ),
      child: Text(digit, style: appText(size * 0.46, weight: FontWeight.w800)),
    );
  }
}
