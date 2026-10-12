import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';
import '../data/demo_chat_data.dart' show chatQuickReplies;

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isPickingPhoto,
    required this.onPickPhoto,
    required this.onSend,
    required this.onQuickReply,
  });

  final TextEditingController controller;
  final bool isPickingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickReply;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _showQuickReplies = false;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: ChatTheme.inputBackground,
      border: Border(top: BorderSide(color: ChatTheme.border)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showQuickReplies)
            SingleChildScrollView(
              key: const ValueKey('chat-quick-replies'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  for (final text in chatQuickReplies)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(text, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        side: const BorderSide(color: ChatTheme.border),
                        shape: const StadiumBorder(),
                        onPressed: () => widget.onQuickReply(text),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 6, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const ValueKey('chat-quick-toggle'),
                  tooltip: _showQuickReplies
                      ? 'Ẩn trả lời nhanh'
                      : 'Trả lời nhanh',
                  color: ChatTheme.messageText,
                  onPressed: () => setState(() {
                    _showQuickReplies = !_showQuickReplies;
                  }),
                  icon: Icon(
                    _showQuickReplies ? Icons.close_rounded : Icons.add_rounded,
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: widget.controller,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ChatTheme.messageText,
                    ),
                    cursorColor: ChatTheme.messageRed,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: const TextStyle(
                        color: ChatTheme.timestamp,
                        fontSize: 14,
                      ),
                      hintMaxLines: 1,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, child) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: IconButton(
                            key: const ValueKey('chat-send'),
                            tooltip: 'Gửi tin nhắn',
                            color: Colors.white,
                            disabledColor: ChatTheme.timestamp,
                            style: IconButton.styleFrom(
                              backgroundColor: ChatTheme.messageRed,
                              disabledBackgroundColor: Colors.transparent,
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(8),
                              shape: const CircleBorder(),
                            ),
                            onPressed: value.text.trim().isEmpty
                                ? null
                                : widget.onSend,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('chat-camera'),
                  tooltip: widget.isPickingPhoto
                      ? 'Đang chọn ảnh…'
                      : 'Gửi ảnh sự cố xe',
                  color: ChatTheme.messageText,
                  onPressed: widget.isPickingPhoto ? null : widget.onPickPhoto,
                  icon: widget.isPickingPhoto
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined, size: 23),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
