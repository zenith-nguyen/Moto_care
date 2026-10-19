import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_received_screen.dart';

/// Chat thợ – khách trong đơn. [messages] là danh sách dùng chung với đơn (được ghi thêm khi gửi).
class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.messages,
    this.readOnly = false,
  });

  final String orderId;
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
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    appState.sendChat(widget.orderId, text: text);
    _textController.clear();
  }

  void _retry(ChatMessage message) =>
      appState.retryChat(widget.orderId, message);

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                'Gửi ảnh mẫu phương tiện',
                style: appText(15, weight: FontWeight.w600),
              ),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                'Gửi ảnh mẫu sự cố',
                style: appText(15, weight: FontWeight.w600),
              ),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    appState.sendChat(widget.orderId, isImage: true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final items = widget.messages.reversed.toList();
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          icon:
                              const Icon(Icons.chevron_left_rounded, size: 22),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        AvatarCircle(
                          initials: initialsOf(widget.customerName),
                          size: 32,
                          dark: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customerName,
                                style: appText(13, weight: FontWeight.w600),
                              ),
                              Text(
                                widget.readOnly
                                    ? 'Lịch sử trò chuyện'
                                    : 'Đang hoạt động',
                                style: appText(10, color: AppColors.textSub),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gọi khách',
                          icon: const Icon(Icons.call_outlined, size: 20),
                          onPressed: () => callCustomer(
                            context,
                            widget.customerName,
                            widget.customerPhone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _Bubble(
                          message: items[i],
                          onRetry: _retry,
                          readOnly: widget.readOnly,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.readOnly)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border:
                            Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Gửi ảnh mẫu',
                            onPressed: _pickImage,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.textSub,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              style: appText(12),
                              onSubmitted: (_) => _sendText(),
                              decoration: const InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Gửi',
                            iconSize: 20,
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
        },
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.onRetry,
    this.readOnly = false,
  });
  final ChatMessage message;
  final ValueChanged<ChatMessage> onRetry;
  final bool readOnly;

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
        ? Padding(
            padding: const EdgeInsets.all(5),
            child: PhotoPlaceholder(
                width: 160,
                height: 100,
                radius: 12,
                vehicle: message.imageVehicle),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              message.text ?? '',
              style: appText(12, color: AppColors.ink, height: 1.5),
            ),
          );

    final (IconData statusIcon, String statusLabel) = switch (message.status) {
      MessageStatus.sending => (Icons.schedule, 'Đang gửi'),
      MessageStatus.sent => (Icons.check, 'Đã gửi'),
      MessageStatus.seen => (Icons.done_all, 'Đã xem'),
      MessageStatus.failed => (
          Icons.error_outline,
          readOnly ? 'Gửi thất bại' : 'Lỗi · Chạm để gửi lại',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            child: GestureDetector(
              onTap: failed && !readOnly ? () => onRetry(message) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: mine ? AppColors.surfaceSoft : AppColors.light,
                  borderRadius: radius,
                  border: failed
                      ? Border.all(color: AppColors.danger, width: 1.4)
                      : null,
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
                Text(
                  formatHm(message.time),
                  style: appText(10, color: AppColors.textMuted),
                ),
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
                        10,
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
