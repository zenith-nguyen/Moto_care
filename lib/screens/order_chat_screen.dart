import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

/// Chat thợ – khách trong đơn. [messages] là danh sách dùng chung với đơn (được ghi thêm khi gửi).
class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.messages,
    this.readOnly = false,
  });

  final String customerName;
  final String customerPhone;
  final List<ChatMessage> messages;

  /// true: xem lại chat của đơn đã kết thúc (ẩn thanh nhập liệu).
  final bool readOnly;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _textController = TextEditingController();
  final List<Timer> _timers = [];
  bool _customerReplied = false;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _textController.dispose();
    super.dispose();
  }

  void _after(Duration d, VoidCallback fn) {
    _timers.add(Timer(d, () {
      if (mounted) setState(fn);
    }));
  }

  /// Mock gửi tin: "đang gửi" -> "đã gửi" sau 0,8 giây.
  void _deliver(ChatMessage m) {
    m.status = MessageStatus.sending;
    _after(const Duration(milliseconds: 800), () => m.status = MessageStatus.sent);
  }

  void _add(ChatMessage m) {
    setState(() => widget.messages.add(m));
    _deliver(m);
    if (!_customerReplied) {
      _customerReplied = true;
      _after(const Duration(milliseconds: 2500), () {
        widget.messages.add(ChatMessage(
          fromMechanic: false,
          time: DateTime.now(),
          text: 'Dạ em cảm ơn anh nhiều nha.',
        ));
      });
    }
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _add(ChatMessage(fromMechanic: true, time: DateTime.now(), text: text));
  }

  void _retry(ChatMessage m) => setState(() => _deliver(m));

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Chụp ảnh', style: appText(15, weight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Chọn từ thư viện', style: appText(15, weight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    _add(ChatMessage(fromMechanic: true, time: DateTime.now(), isImage: true));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.messages.reversed.toList();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: widget.customerName,
              trailing: RoundIconButton(
                icon: Icons.call_outlined,
                tooltip: 'Gọi khách',
                size: 48,
                onTap: () => showAppSnack(
                  context,
                  'Đang gọi ${widget.customerName} (${maskPhone(widget.customerPhone)})...',
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: items.length,
                itemBuilder: (context, i) => _Bubble(message: items[i], onRetry: _retry),
              ),
            ),
            if (!widget.readOnly)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEFEFF1))),
                ),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: 'Chụp ảnh',
                      size: 48,
                      onTap: () => _add(
                        ChatMessage(fromMechanic: true, time: DateTime.now(), isImage: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.image_outlined,
                      tooltip: 'Gửi ảnh từ thư viện',
                      size: 48,
                      onTap: _pickImage,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: appText(15),
                        onSubmitted: (_) => _sendText(),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Gửi',
                      iconSize: 28,
                      icon: const Icon(Icons.send_outlined),
                      onPressed: _sendText,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onRetry});
  final ChatMessage message;
  final ValueChanged<ChatMessage> onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMechanic;
    final failed = message.status == MessageStatus.failed;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.md),
      topRight: const Radius.circular(AppRadius.md),
      bottomLeft: Radius.circular(mine ? AppRadius.md : 6),
      bottomRight: Radius.circular(mine ? 6 : AppRadius.md),
    );

    final Widget content = message.isImage
        ? const Padding(
            padding: EdgeInsets.all(5),
            child: PhotoPlaceholder(width: 200, height: 140, radius: 16),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              message.text ?? '',
              style: appText(15, color: mine ? Colors.white : AppColors.ink, height: 1.4),
            ),
          );

    final (IconData statusIcon, String statusLabel) = switch (message.status) {
      MessageStatus.sending => (Icons.schedule, 'Đang gửi'),
      MessageStatus.sent => (Icons.check, 'Đã gửi'),
      MessageStatus.seen => (Icons.done_all, 'Đã xem'),
      MessageStatus.failed => (Icons.error_outline, 'Lỗi · Chạm để gửi lại'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
            child: GestureDetector(
              onTap: failed ? () => onRetry(message) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: mine ? AppColors.ink : Colors.white,
                  borderRadius: radius,
                  border: failed ? Border.all(color: AppColors.danger, width: 1.4) : null,
                ),
                child: content,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatHm(message.time), style: appText(11.5, color: AppColors.textMuted)),
                if (mine) ...[
                  const SizedBox(width: 6),
                  Icon(
                    statusIcon,
                    size: 13,
                    color: failed ? AppColors.danger : AppColors.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      statusLabel,
                      overflow: TextOverflow.ellipsis,
                      style: appText(
                        11.5,
                        weight: failed ? FontWeight.w600 : FontWeight.w500,
                        color: failed ? AppColors.danger : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
