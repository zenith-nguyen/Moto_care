import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

class OrderTrackingChatSheet extends StatefulWidget {
  const OrderTrackingChatSheet({
    super.key,
    required this.mechanicName,
    required this.orderCode,
    required this.messages,
  });
  final String mechanicName, orderCode;
  final List<String> messages;
  @override
  State<OrderTrackingChatSheet> createState() => _OrderTrackingChatSheetState();
}

class _OrderTrackingChatSheetState extends State<OrderTrackingChatSheet> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  void _send() {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    setState(() {
      widget.messages.add(message);
      _text.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.mechanicName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng trò chuyện',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.orderCode,
                    style: const TextStyle(
                      color: HomeColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Trò chuyện mô phỏng • Tin nhắn được lưu trong màn hình này, chưa gửi tới thợ.',
                      style: TextStyle(
                        color: HomeColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.messages.isEmpty)
                    const Text(
                      'Bạn có thể ghi chú vị trí hoặc tình trạng xe tại đây.',
                      style: TextStyle(color: HomeColors.secondary),
                    ),
                  for (final message in widget.messages)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HomeColors.redSelected,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('tracking-chat-input'),
                      controller: _text,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('tracking-chat-send'),
                    tooltip: 'Lưu tin nhắn mô phỏng',
                    onPressed: _text.text.trim().isEmpty ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
