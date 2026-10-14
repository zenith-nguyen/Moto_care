import 'package:flutter/material.dart';

import '../models/service_catalog_model.dart';
import '../theme/station_detail_theme.dart';
import 'service_catalog_details_sheet.dart';
import 'service_catalog_visuals.dart';

export '../models/service_catalog_model.dart';

class StationServicesCatalog extends StatelessWidget {
  const StationServicesCatalog({super.key, required this.services});
  final List<ServiceCatalogModel> services;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Dịch vụ cứu hộ chính',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: StationDetailColors.text,
        ),
      ),
      const SizedBox(height: 8),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_user_outlined,
              size: 15,
              color: StationDetailColors.red,
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Giá niêm yết công khai • Không phát sinh phụ phí',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: StationDetailColors.muted,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (services.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StationDetailColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Liên hệ trạm để được tư vấn dịch vụ.',
            style: TextStyle(color: StationDetailColors.muted, height: 1.6),
          ),
        ),
      for (var index = 0; index < services.length; index++) ...[
        ServiceCatalogItemCard(
          key: ValueKey('station-service-${services[index].id}'),
          service: services[index],
        ),
        if (index < services.length - 1) const SizedBox(height: 12),
      ],
    ],
  );
}

class ServiceCatalogItemCard extends StatelessWidget {
  const ServiceCatalogItemCard({super.key, required this.service});
  final ServiceCatalogModel service;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: StationDetailColors.catalogBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showServiceCatalogDetails(context, service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceCatalogIconBox(serviceType: service.serviceType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 8),
                    Text(
                      service.details?.description ?? 'Vật tư và thời gian xử lý được trạm xác nhận trước khi thực hiện.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: StationDetailColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatCatalogPrice(service.price),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: StationDetailColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: StationDetailColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildTitle(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final title = Text(
        service.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: StationDetailColors.text,
        ),
      );
      final badge = ServiceFulfillmentBadge(fulfillment: service.fulfillment);
      if (constraints.maxWidth >= 215 &&
          MediaQuery.textScalerOf(context).scale(15) <= 18) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 8),
            badge,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 8), badge],
      );
    },
  );
}
