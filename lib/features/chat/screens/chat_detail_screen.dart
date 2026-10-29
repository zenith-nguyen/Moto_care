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
import '../services/chat_service.dart';
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

  Future<void> _sendText([String? quickReply]) async {
    final chat = widget.conversation;
    if (chat == null) return;
    final sent = await ref
        .read(chatMessagesProvider(chat).notifier)
        .sendText(quickReply ?? _textController.text);
    if (sent && quickReply == null) _textController.clear();
  }

  Future<void> _callMechanic() async {
    final chat = widget.conversation;
    if (chat == null || chat.phoneNumber.trim().isEmpty) return;
    final opened = await ref.read(chatServiceProvider).call(chat.phoneNumber);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Không thể mở ứng dụng gọi điện. '
            'Bạn có thể gọi số ${chat.phoneNumber}.',
          ),
        ),
      );
  }

  void _showConversationDetails() {
    final chat = widget.conversation;
    if (chat == null) return;
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChatTheme.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Theme(
        data: ChatTheme.light,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('chat-details-sheet'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Thông tin cuộc trò chuyện',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  chat.mechanicName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  chat.statusLabel ?? chat.status.label,
                  style: const TextStyle(color: ChatTheme.mutedText),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.two_wheeler_outlined),
                  title: const Text('Biển số xe'),
                  subtitle: Text(chat.licensePlate),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Số điện thoại'),
                  subtitle: Text(
                    chat.phoneNumber.isEmpty
                        ? 'Chưa có số điện thoại'
                        : chat.phoneNumber,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final chat = widget.conversation;
    if (_selectingPhoto || chat == null) return;
    _selectingPhoto = true;
    ImageSource? source;
    try {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: ChatTheme.surface,
        showDragHandle: true,
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
      try {
        await ref.read(chatMessagesProvider(chat).notifier).sendImage(photo);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không gửi được ảnh. Vui lòng thử lại.'),
            ),
          );
        }
      }
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
        backgroundColor: ChatTheme.surface,
        appBar: AppBar(
          backgroundColor: ChatTheme.inputBackground,
          foregroundColor: ChatTheme.messageText,
          scrolledUnderElevation: 0,
          toolbarHeight: chat == null ? 56 : 72,
          leadingWidth: 44,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/tin-nhan');
              }
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          title: chat == null
              ? const Text('Tin nhắn')
              : _ConversationHeader(conversation: chat),
          actions: [
            if (chat != null) ...[
              IconButton(
                key: const ValueKey('chat-call'),
                tooltip: 'Gọi cho thợ',
                onPressed: chat.phoneNumber.trim().isEmpty
                    ? null
                    : _callMechanic,
                icon: const Icon(Icons.phone_outlined, size: 22),
              ),
              PopupMenuButton<_ConversationAction>(
                key: const ValueKey('chat-more'),
                tooltip: 'Tùy chọn cuộc trò chuyện',
                color: ChatTheme.surface,
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                onSelected: (action) {
                  if (action == _ConversationAction.details) {
                    _showConversationDetails();
                  } else {
                    _callMechanic();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _ConversationAction.details,
                    child: Text('Thông tin cuộc trò chuyện'),
                  ),
                  PopupMenuItem(
                    value: _ConversationAction.call,
                    enabled: chat.phoneNumber.trim().isNotEmpty,
                    child: const Text('Gọi cho thợ'),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: ChatTheme.border),
          ),
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
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              itemCount: messages!.length + 1,
                              itemBuilder: (context, index) => index == 0
                                  ? _ConversationContext(conversation: chat)
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

enum _ConversationAction { details, call }

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE5E5E8),
        foregroundColor: ChatTheme.messageText,
        child: Text(
          conversation.avatarInitials,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.mechanicName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ChatTheme.messageText,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              conversation.statusLabel ?? conversation.status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ChatTheme.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConversationContext extends StatelessWidget {
  const _ConversationContext({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ChatTheme.incomingBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            conversation.licensePlate,
            style: const TextStyle(color: ChatTheme.mutedText, fontSize: 10),
          ),
        ),
      ),
    ),
  );
}
