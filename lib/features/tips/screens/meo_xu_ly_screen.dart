import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/service_actions.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../models/emergency_tip.dart';
import '../widgets/tip_illustration.dart';

class MeoXuLyScreen extends ConsumerWidget {
  const MeoXuLyScreen({super.key});

  void _openArticle(BuildContext context, WidgetRef ref, EmergencyTip tip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ServiceColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Đóng bài viết',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Text(
              tip.title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              '${tip.minutes} phút đọc • ${tip.level}',
              style: const TextStyle(color: ServiceColors.muted),
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < tip.steps.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: TipIllustration(kind: tip.kind, step: index + 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bước ${index + 1}',
                      style: const TextStyle(
                        color: ServiceColors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.steps[index],
                      style: const TextStyle(height: 1.5, fontSize: 16),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () => launchServiceUri(
                sheetContext,
                ref,
                Uri.parse(tip.sourceUrl),
                'Không thể mở tài liệu hướng dẫn lúc này.',
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(tip.sourceLabel),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ServiceScaffold(
    title: 'Mẹo tự xử lý sự cố khẩn cấp',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ServiceColors.orange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.black, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Luôn tấp xe vào sát lề đường an toàn trước khi kiểm tra xe',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const ServiceSectionTitle('Hướng dẫn xử lý nhanh'),
        for (final tip in emergencyTips)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openArticle(context, ref, tip),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 95,
                        height: 96,
                        child: TipIllustration(kind: tip.kind),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${tip.minutes} phút đọc',
                              style: const TextStyle(
                                color: ServiceColors.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tip.level,
                              style: const TextStyle(
                                color: ServiceColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
