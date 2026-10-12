import 'package:flutter/material.dart';

import '../theme/station_detail_theme.dart';

class StationDetailBottomBar extends StatelessWidget {
  const StationDetailBottomBar({
    super.key,
    required this.isOpen,
    required this.onBook,
    required this.onChat,
  });

  final bool isOpen;
  final VoidCallback? onBook;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 24,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('station-book'),
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  backgroundColor: StationDetailColors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                child: Text(
                  isOpen ? 'YÊU CẦU CỨU HỘ NGAY' : 'TRẠM ĐANG ĐÓNG CỬA',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              key: const ValueKey('station-chat'),
              tooltip: 'Chat với trạm',
              onPressed: onChat,
              style: IconButton.styleFrom(
                fixedSize: const Size(56, 56),
                backgroundColor: StationDetailColors.text,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 23),
            ),
          ],
        ),
      ),
    ),
  );
}
