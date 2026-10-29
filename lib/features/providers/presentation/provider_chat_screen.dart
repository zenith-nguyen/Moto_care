import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/theme/revo_brand.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../messages/application/customer_chat_controller.dart';
import '../../messages/data/chat_image_picker.dart';
import '../../messages/domain/chat_message.dart';
import 'provider_formatters.dart';

class ProviderChatScreen extends ConsumerStatefulWidget {
  const ProviderChatScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends ConsumerState<ProviderChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<int, Future<ProtectedChatImage>> _imageLoads = {};

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(customerChatControllerProvider(widget.orderId));
    final session = ref.watch(sessionControllerProvider);
    final currentUserId = session is SessionSignedIn
        ? session.session.user.id
        : -1;

    ref.listen(customerChatControllerProvider(widget.orderId), (
      previous,
      next,
    ) {
      final previousLength = previous?.value?.messages.length ?? 0;
      final nextLength = next.value?.messages.length ?? 0;
      if (nextLength > previousLength) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Chat đơn #${widget.orderId}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ChatFailure(
                  message: 'Không tải được tin nhắn: $error',
                  onRetry: () => ref.invalidate(
                    customerChatControllerProvider(widget.orderId),
                  ),
                ),
                data: (state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text('Chưa có tin nhắn trong đơn này.'),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return _MessageBubble(
                        message: message,
                        isMine: message.senderId == currentUserId,
                        image: message.image == null
                            ? null
                            : _imageLoads.putIfAbsent(
                                message.id,
                                () => ref
                                    .read(
                                      customerChatControllerProvider(
                                        widget.orderId,
                                      ).notifier,
                                    )
                                    .loadImage(message.id),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            if (chat.value?.lastFailure != null)
              _ChatFailure(
                message: 'Không gửi được tin nhắn: ${chat.value!.lastFailure}',
              ),
            _Composer(
              controller: _messageController,
              busy: chat.value?.isBusy ?? true,
              onAttach: _pickImage,
              onSend: _sendText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await ref
        .read(customerChatControllerProvider(widget.orderId).notifier)
        .sendText(content);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ChatImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ChatImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ChatImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await ref.read(chatImagePickerProvider).pick(source);
      if (image == null) return;
      final caption = _messageController.text.trim();
      _messageController.clear();
      await ref
          .read(customerChatControllerProvider(widget.orderId).notifier)
          .sendImage(image, content: caption.isEmpty ? null : caption);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $error')));
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.image,
  });

  final ChatMessage message;
  final bool isMine;
  final Future<ProtectedChatImage>? image;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine
              ? RevoBrandColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FutureBuilder<ProtectedChatImage>(
                  future: image,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        Uint8List.fromList(snapshot.data!.bytes),
                        fit: BoxFit.cover,
                      );
                    }
                    if (snapshot.hasError) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      );
                    }
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (image != null && message.content != null)
              const SizedBox(height: 8),
            if (message.content != null)
              Text(
                message.content!,
                style: TextStyle(color: isMine ? Colors.white : null),
              ),
            const SizedBox(height: 5),
            Text(
              formatProviderDateTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : RevoBrandColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Gửi ảnh',
              onPressed: busy ? null : onAttach,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  isDense: true,
                ),
              ),
            ),
            IconButton.filled(
              tooltip: 'Gửi',
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFailure extends StatelessWidget {
  const _ChatFailure({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(message, textAlign: TextAlign.center)),
          if (onRetry != null)
            IconButton(
              tooltip: 'Thử lại',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}
