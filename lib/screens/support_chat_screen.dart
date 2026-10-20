import 'package:flutter/material.dart';
import '../services/support_assistant.dart';
import '../state/app_state.dart';
import '../state/support_chat_controller.dart';
import '../theme/app_theme.dart';
import '../theme/support_palette.dart';
import '../utils/format.dart';
import '../widgets/chatbot_avatar.dart';
import '../widgets/ui.dart';
import 'support_screen.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.controller});

  /// Defaults to the app-wide conversation; tests inject their own.
  final SupportChatController? controller;
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  late final SupportChatController _c = widget.controller ?? supportChat;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;

  static const _chips = [
    ('Đơn hàng', 'Tôi cần hỗ trợ về đơn hàng'),
    ('Thanh toán', 'Cách gửi đề nghị chi trả?'),
    ('Mã OTP', 'Khách chưa cung cấp mã xác nhận thì làm sao?'),
    ('Gặp Admin', null),
  ];

  @override
  void initState() {
    super.initState();
    _lastCount = _c.messages.length;
    _c.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(jump: true));
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (_c.messages.length != _lastCount || _c.waiting) {
      _lastCount = _c.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
    }
  }

  void _toEnd({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (jump || MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(end);
    } else {
      _scroll.animateTo(end,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    if (text == null) _input.clear();
    _c.send(value);
  }

  void _run(SupportAction a) {
    switch (a.kind) {
      case SupportActionKind.openPaymentGuide:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SupportScreen(initialTab: 1)));
      case SupportActionKind.openFaq:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SupportScreen()));
      case SupportActionKind.openWallet:
        Navigator.of(context).popUntil((r) => r.isFirst);
        appState.setTab(2);
      case SupportActionKind.contactAdmin:
        showAppSnack(context,
            'Kênh liên hệ Admin chưa được kết nối trong bản trình diễn.');
    }
  }

  Future<void> _about() => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: const Text('Trợ lý REVO'),
              content: Text(_c.assistant.isLive
                  ? 'Trợ lý trả lời tự động. Trợ lý không thể thay đổi đơn hàng, ví hay duyệt đề nghị chi trả.'
                  : 'Trợ lý đang chạy ở chế độ mô phỏng: trả lời theo mẫu có sẵn, chưa kết nối dịch vụ AI. Trợ lý không thể thay đổi đơn hàng, ví hay duyệt đề nghị chi trả.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng'))
              ]));

  Future<void> _plus() async {
    final pick = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  key: const ValueKey('plus-faq'),
                  leading: const Icon(Icons.help_outline_rounded,
                      color: AppColors.primary),
                  title: Text('Câu hỏi thường gặp',
                      style: appText(14, color: SupportPalette.text)),
                  onTap: () => Navigator.pop(ctx, 'faq')),
              ListTile(
                  key: const ValueKey('plus-new'),
                  leading: const Icon(Icons.add_comment_outlined,
                      color: AppColors.primary),
                  title: Text('Cuộc trò chuyện mới',
                      style: appText(14, color: SupportPalette.text)),
                  onTap: () => Navigator.pop(ctx, 'new')),
            ])));
    if (!mounted) return;
    if (pick == 'new') _c.reset();
    if (pick == 'faq') {
      _run(const SupportAction('', SupportActionKind.openFaq));
    }
  }

  Widget _header(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: SupportPalette.border))),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(children: [
        IconButton(
            tooltip: 'Quay lại',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded,
                size: 30, color: SupportPalette.text)),
        const ChatbotAvatar(size: 38),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trợ lý REVO',
              style: appText(16,
                  weight: FontWeight.w600, color: SupportPalette.text)),
          Row(children: [
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _c.assistant.isLive
                        ? SupportPalette.live
                        : SupportPalette.border)),
            const SizedBox(width: 5),
            Flexible(
                child: Text(
                    _c.assistant.isLive
                        ? 'Trả lời tự động · 24/7'
                        : 'Chế độ mô phỏng',
                    key: const ValueKey('chat-status'),
                    style: appText(12, color: SupportPalette.textSub))),
          ]),
        ])),
        PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            icon: const Icon(Icons.more_horiz_rounded,
                color: SupportPalette.text),
            onSelected: (v) {
              if (v == 'new') _c.reset();
              if (v == 'about') _about();
            },
            itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'new',
                      child: Text('Cuộc trò chuyện mới', style: appText(14))),
                  PopupMenuItem(
                      value: 'about',
                      child:
                          Text('Thông tin về Trợ lý REVO', style: appText(14))),
                ]),
      ]));

  Widget _chipsRow() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: SizedBox(
          width: double.infinity,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < _chips.length; i++)
              Material(
                  color: Colors.white,
                  shape: const StadiumBorder(
                      side: BorderSide(color: SupportPalette.border)),
                  child: InkWell(
                      key: ValueKey('chat-chip-$i'),
                      customBorder: const StadiumBorder(),
                      onTap: () => _chips[i].$2 == null
                          ? _run(const SupportAction(
                              'Gặp Admin', SupportActionKind.contactAdmin))
                          : _send(_chips[i].$2),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          child: Text(_chips[i].$1,
                              style:
                                  appText(12.5, color: SupportPalette.text))))),
          ])));

  Widget _inputBar() => Container(
      color: SupportPalette.bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListenableBuilder(
          listenable: _input,
          builder: (context, _) {
            final can = _input.text.trim().isNotEmpty && !_c.waiting;
            return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Semantics(
                  button: true,
                  label: 'Thêm',
                  child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                          side: BorderSide(color: SupportPalette.border)),
                      child: InkWell(
                          key: const ValueKey('chat-plus'),
                          customBorder: const CircleBorder(),
                          onTap: _plus,
                          child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.add_rounded,
                                  color: SupportPalette.text, size: 22))))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      key: const ValueKey('chat-input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      style: appText(14, color: SupportPalette.text),
                      decoration: InputDecoration(
                          hintText: 'Nhập câu hỏi...',
                          hintStyle: appText(14, color: SupportPalette.textSub),
                          filled: true,
                          fillColor: SupportPalette.inactive,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          border: _pill(),
                          enabledBorder: _pill(),
                          focusedBorder: _pill(AppColors.primary)))),
              const SizedBox(width: 8),
              Semantics(
                  button: true,
                  label: 'Gửi',
                  child: Material(
                      color: can
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: .4),
                      shape: const CircleBorder(),
                      child: InkWell(
                          key: const ValueKey('chat-send'),
                          customBorder: const CircleBorder(),
                          onTap: can ? _send : null,
                          child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.arrow_upward_rounded,
                                  color: Colors.white, size: 22))))),
            ]);
          }));

  OutlineInputBorder _pill([Color c = SupportPalette.border]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: c));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: SupportPalette.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
          child: Column(children: [
        _header(context),
        Expanded(
            child: ListenableBuilder(
                listenable: _c,
                builder: (context, _) {
                  final msgs = _c.messages;
                  return ListView.builder(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: msgs.length + (_c.waiting ? 1 : 0),
                      itemBuilder: (_, i) => i == msgs.length
                          ? const _Typing()
                          : _Bubble(
                              message: msgs[i],
                              onAction: _run,
                              onRetry: () => _c.retry(msgs[i])));
                })),
        _chipsRow(),
        _inputBar(),
      ])));
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => Padding(
      key: const ValueKey('chat-typing'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const ChatbotAvatar(size: 32),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: _botDecoration,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
              const SizedBox(width: 10),
              Text('Đang soạn trả lời…',
                  style: appText(12.5, color: SupportPalette.textSub)),
            ])),
      ]));
}

final _botDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: SupportPalette.border));

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.message, required this.onAction, required this.onRetry});
  final SupportMessage message;
  final void Function(SupportAction) onAction;
  final VoidCallback onRetry;

  bool get _user => message.sender == ChatSender.user;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * .8;
    final color = _user ? Colors.white : SupportPalette.text;
    final body = _RichLines(message.text, color: color);
    final bubble = Container(
        key: ValueKey(_user ? 'bubble-user' : 'bubble-bot'),
        constraints: BoxConstraints(maxWidth: maxW),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
        decoration: _user
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16))
            : _botDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          body,
          for (final a in message.actions) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: SupportPalette.border),
            InkWell(
                key: ValueKey('action-${a.kind.name}'),
                onTap: () => onAction(a),
                child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(children: [
                      Flexible(
                          child: Text(a.label,
                              style: appText(13.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.primary))),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: AppColors.primary),
                    ]))),
          ],
        ]));
    final meta = Padding(
        padding: const EdgeInsets.only(top: 3),
        child: message.state == SendState.failed
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Chưa gửi được · ',
                    style: appText(11.5, color: SupportPalette.textSub)),
                InkWell(
                    key: const ValueKey('chat-retry'),
                    onTap: onRetry,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('Thử lại',
                            style: appText(11.5,
                                weight: FontWeight.w600,
                                color: AppColors.primary)))),
              ])
            : Text(formatHm(message.time),
                style: appText(10.5, color: SupportPalette.textSub)));
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _user
            ? Align(
                alignment: Alignment.centerRight,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [bubble, meta]))
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const ChatbotAvatar(size: 32),
                const SizedBox(width: 8),
                Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [bubble, meta])),
              ]));
  }
}

/// Plain text with `**bold**` and "1. step" lines; nothing else is parsed.
class _RichLines extends StatelessWidget {
  const _RichLines(this.text, {required this.color});
  final String text;
  final Color color;

  static final _step = RegExp(r'^(\d+)\.\s+(.*)$');

  TextSpan _spans(String s) {
    final parts = s.split('**');
    return TextSpan(children: [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
            text: parts[i],
            style:
                i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final base = appText(13.5, color: color, height: 1.45);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final line in text.split('\n'))
        Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: () {
              final m = _step.firstMatch(line);
              if (m == null) {
                return Text.rich(_spans(line), style: base);
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEAF2FA), shape: BoxShape.circle),
                        child: Text(m.group(1)!,
                            style: appText(12,
                                weight: FontWeight.w600,
                                color: AppColors.primary))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text.rich(_spans(m.group(2)!), style: base)),
                  ]);
            }()),
    ]);
  }
}
