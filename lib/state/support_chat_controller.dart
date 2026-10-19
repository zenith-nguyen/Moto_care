import 'package:flutter/foundation.dart';
import '../services/support_assistant.dart';
import 'app_state.dart';

enum ChatSender { bot, user }

enum SendState { sent, failed }

class SupportMessage {
  SupportMessage(this.sender, this.text, this.time,
      {this.actions = const [], this.state = SendState.sent});
  final ChatSender sender;
  final String text;
  final DateTime time;
  final List<SupportAction> actions;
  SendState state;
}

/// In-memory conversation. Holds only what the user typed and what the
/// assistant answered; it never touches orders, wallet or payouts.
class SupportChatController extends ChangeNotifier {
  SupportChatController(this.assistant, {String Function()? userName})
      : _userName = userName ?? (() => appState.profile.name) {
    reset(notify: false);
  }
  final SupportAssistant assistant;
  final String Function() _userName;
  final List<SupportMessage> messages = [];
  bool waiting = false;

  String get _greeting {
    final parts = _userName().trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty || parts.last.isEmpty ? '' : ' ${parts.last}';
    return 'Chào anh$first, mình là Trợ lý REVO. Anh cần hỏi về đơn hàng, thanh toán, hồ sơ thợ hay chuyện khác?';
  }

  void reset({bool notify = true}) {
    messages
      ..clear()
      ..add(SupportMessage(ChatSender.bot, _greeting, DateTime.now()));
    waiting = false;
    if (notify) notifyListeners();
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || waiting) return;
    final m = SupportMessage(ChatSender.user, text, DateTime.now());
    messages.add(m);
    await _answer(m);
  }

  Future<void> retry(SupportMessage m) async {
    if (waiting || m.state != SendState.failed) return;
    m.state = SendState.sent;
    await _answer(m);
  }

  Future<void> _answer(SupportMessage m) async {
    waiting = true;
    notifyListeners();
    try {
      final replies = await assistant.reply(m.text);
      for (final r in replies) {
        messages.add(SupportMessage(ChatSender.bot, r.text, DateTime.now(),
            actions: r.actions));
      }
    } catch (_) {
      m.state = SendState.failed;
    }
    waiting = false;
    notifyListeners();
  }
}

final supportChat = SupportChatController(MockSupportAssistant());
