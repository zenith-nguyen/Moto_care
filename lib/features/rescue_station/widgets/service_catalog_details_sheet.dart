import 'package:flutter/material.dart';

import '../models/service_catalog_model.dart';
import '../theme/station_detail_theme.dart';
import 'service_catalog_visuals.dart';

Future<void> showServiceCatalogDetails(
  BuildContext context,
  ServiceCatalogModel service,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  constraints: BoxConstraints(
    maxWidth: 600,
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => ServiceCatalogDetailsSheet(service: service),
);

class ServiceCatalogDetailsSheet extends StatelessWidget {
  const ServiceCatalogDetailsSheet({super.key, required this.service});
  final ServiceCatalogModel service;

  @override
  Widget build(BuildContext context) {
    final details = service.details;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chi tiết Quy trình Dịch vụ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: StationDetailColors.text,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng chi tiết dịch vụ',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: StationDetailColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              key: const ValueKey('service-catalog-details-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StationDetailColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ServiceCatalogIconBox(serviceType: service.serviceType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ServiceFulfillmentBadge(
                                fulfillment: service.fulfillment,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                formatCatalogPrice(service.price),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: StationDetailColors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quy trình thực hiện',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  if (details == null || details.procedureSteps.isEmpty)
                    const Text(
                      'Trạm chưa công bố quy trình chi tiết. Liên hệ trạm để được tư vấn phương án xử lý.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: StationDetailColors.muted,
                      ),
                    )
                  else
                    for (
                      var index = 0;
                      index < details.procedureSteps.length;
                      index++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: StationDetailColors.catalogTint,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: StationDetailColors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                details.procedureSteps[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.7,
                                  color: StationDetailColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 10),
                  _InformationPanel(
                    icon: Icons.inventory_2_outlined,
                    title: 'Cam kết linh kiện / Vật tư',
                    content: details?.materialsCommitment ?? 'Liên hệ trạm để xác nhận vật tư, linh kiện và nguồn gốc trước khi thực hiện.',
                  ),
                  const SizedBox(height: 12),
                  _InformationPanel(
                    icon: Icons.verified_user_outlined,
                    title: 'Thời gian bảo hành',
                    content: details?.warranty ?? 'Trạm chưa công bố thời hạn bảo hành cho dịch vụ này. Vui lòng xác nhận trực tiếp với trạm.',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Giá trên là giá dịch vụ. Phí di chuyển (nếu có) được hiển thị trước khi bạn xác nhận yêu cầu.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.7,
                      color: StationDetailColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: StationDetailColors.text,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel({
    required this.icon,
    required this.title,
    required this.content,
  });
  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: StationDetailColors.catalogBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: StationDetailColors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: StationDetailColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
