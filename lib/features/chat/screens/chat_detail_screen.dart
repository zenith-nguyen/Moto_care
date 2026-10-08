import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/main_navigation.dart';
import '../../../core/providers/attachment_provider.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../models/chat_conversation.dart';
import '../providers/chat_messages_provider.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, this.conversation});

  final ChatConversation? conversation;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _selectingPhoto = false;
  final _pickerKey = Object();
  int _scrollRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _scrollToBottom();

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation != widget.conversation) {
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    final request = ++_scrollRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted &&
          request == _scrollRequest &&
          _scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        if (!mounted || !_scrollController.hasClients) return;
        // Lazy layout refines the end offset for bubbles of different heights.
        if (_scrollController.position.extentAfter < 1) return;
      }
    });
  }

  void _sendText([String? quickReply]) {
    final chat = widget.conversation;
    if (chat == null) return;
    final sent = ref
        .read(chatMessagesProvider(chat).notifier)
        .sendText(quickReply ?? _textController.text);
    if (sent && quickReply == null) _textController.clear();
  }

  Future<void> _pickPhoto() async {
    final chat = widget.conversation;
    if (_selectingPhoto || chat == null) return;
    _selectingPhoto = true;
    ImageSource? source;
    try {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Gửi ảnh sự cố xe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (!mounted || source == null || widget.conversation != chat) return;
      final photo = await ref
          .read(attachmentProvider((_pickerKey, chat)).notifier)
          .pick(useCamera: source == ImageSource.camera);
      if (!mounted || photo == null || widget.conversation != chat) return;
      ref.read(chatMessagesProvider(chat).notifier).sendImage(photo);
    } finally {
      _selectingPhoto = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.conversation;
    final picker = ref.watch(attachmentProvider((_pickerKey, chat)));
    ref.listen(attachmentProvider((_pickerKey, chat)), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });
    final messages = chat == null
        ? null
        : ref.watch(chatMessagesProvider(chat));
    if (chat != null) {
      ref.listen(chatMessagesProvider(chat), (previous, next) {
        if (previous?.length != next.length) _scrollToBottom();
      });
    }
    return Theme(
      data: ChatTheme.light,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/tin-nhan');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Chi tiết Chat'),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: chat == null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chọn một cuộc trò chuyện trong Tin nhắn để xem chi tiết.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollStartNotification>(
                            onNotification: (notification) {
                              if (notification.dragDetails != null) {
                                _scrollRequest++;
                              }
                              return false;
                            },
                            child: ListView.builder(
                              key: const ValueKey('chat-message-list'),
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages!.length + 1,
                              itemBuilder: (context, index) => index == 0
                                  ? _ConversationHeader(conversation: chat)
                                  : ChatMessageBubble(
                                      key: ValueKey(
                                        'chat-message-${index - 1}',
                                      ),
                                      message: messages[index - 1],
                                    ),
                            ),
                          ),
                        ),
                        ChatInputBar(
                          controller: _textController,
                          isPickingPhoto: picker.picking,
                          onPickPhoto: _pickPhoto,
                          onSend: _sendText,
                          onQuickReply: _sendText,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: chat == null
            ? HomeBottomNavigation(
                selectedDestination: HomeDestination.account,
                onSelected: (destination) =>
                    navigateMainTab(context, destination),
              )
            : null,
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: ChatTheme.surface,
              foregroundColor: ChatTheme.orange,
              child: Text(conversation.avatarInitials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.mechanicName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.licensePlate,
                    style: const TextStyle(color: ChatTheme.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          conversation.statusLabel ?? conversation.status.label,
          style: TextStyle(
            color: conversation.status == RescueStatus.completed
                ? ChatTheme.green
                : ChatTheme.orange,
          ),
        ),
      ],
    ),
  );
}
