import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

class ChatInputBar extends StatelessWidget {
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

  static const _quickReplies = [
    'Tôi đang ở đúng vị trí ghim',
    'Anh đến đâu rồi?',
    'Xe tôi bị thủng lốp / không nổ máy',
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: ChatTheme.border)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            key: const ValueKey('chat-quick-replies'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                for (final text in _quickReplies)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(text),
                      backgroundColor: ChatTheme.inputBackground,
                      shape: const StadiumBorder(),
                      onPressed: () => onQuickReply(text),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const ValueKey('chat-camera'),
                  tooltip: isPickingPhoto
                      ? 'Đang chọn ảnh…'
                      : 'Gửi ảnh sự cố xe',
                  color: ChatTheme.mutedText,
                  onPressed: isPickingPhoto ? null : onPickPhoto,
                  icon: isPickingPhoto
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintMaxLines: 1,
                      filled: true,
                      fillColor: ChatTheme.inputBackground,
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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) => IconButton(
                    key: const ValueKey('chat-send'),
                    tooltip: 'Gửi tin nhắn',
                    color: ChatTheme.messageRed,
                    disabledColor: ChatTheme.messageRed.withValues(alpha: .3),
                    onPressed: value.text.trim().isEmpty ? null : onSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
