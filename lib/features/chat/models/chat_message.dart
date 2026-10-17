import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  const ChatMessage({
    required this.isCustomer,
    required this.timeLabel,
    this.text,
    this.imageBytes,
  }) : assert(text != null || imageBytes != null);

  const ChatMessage.text(
    String this.text, {
    required this.isCustomer,
    required this.timeLabel,
  }) : imageBytes = null;

  const ChatMessage.image(
    Uint8List this.imageBytes, {
    required this.isCustomer,
    required this.timeLabel,
  }) : text = null;

  final String? text;
  final Uint8List? imageBytes;
  final bool isCustomer;
  final String timeLabel;
}
