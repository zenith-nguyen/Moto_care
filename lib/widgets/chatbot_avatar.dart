import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Official REVO assistant picture (`assets/images/revo_chatbot_avatar.png`).
/// The fallback icon only shows if the asset fails to load.
class ChatbotAvatar extends StatelessWidget {
  const ChatbotAvatar({super.key, this.size = 36});
  static const assetPath = 'assets/images/revo_chatbot_avatar.png';
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
      child: SizedBox(
          width: size,
          height: size,
          // The robot sits small in the 1024px frame; a gentle centred zoom
          // keeps the face readable at 30-40dp. No filter, nothing redrawn.
          child: Transform.scale(
              scale: 1.28,
              child: Image.asset(assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceSoft,
                      alignment: Alignment.center,
                      child: Icon(Icons.smart_toy_outlined,
                          size: size * .55, color: AppColors.primary))))));
}
