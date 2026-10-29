import '../../activity/models/rescue_order.dart';
import '../../chat/models/chat_conversation.dart';
import '../../home/models/home_discovery.dart';
import '../../partner/models/partner_shop.dart';
import '../models/station_model.dart';
import '../models/service_catalog_model.dart';

class StationDetailsService {
  const StationDetailsService();

  StationModel build({
    required PartnerShop shop,
    required HomeStationDetails details,
    required StationProfile profile,
    required double distanceKm,
  }) {
    final menu = shop.menu('Tất cả dịch vụ');
    final services = [
      for (final type in [
        RescueServiceType.flatTire,
        RescueServiceType.batteryJump,
        RescueServiceType.towing,
      ])
        ...menu
            .where((package) => package.serviceType == type)
            .where(
              (package) =>
                  type != RescueServiceType.flatTire ||
                  package.id == 'tire-tubeless',
            )
            .take(1),
    ];
    return StationModel(
      station: shop.station,
      description: profile.description,
      imageAssets: profile.imageAssets.isEmpty
          ? [details.imageAsset]
          : profile.imageAssets,
      services: services,
      serviceCatalog: [
        for (final package in services)
          ServiceCatalogModel.fromPackage(
            package,
            details: profile.serviceDetails[package.id],
          ),
      ],
      distanceKm: distanceKm,
      reviewCount: details.reviewCount,
      responseMinutes: details.responseMinutes,
      mechanicCount: profile.mechanicCount,
      warrantyLabel: profile.warrantyLabel,
    );
  }

  ChatConversation conversation(StationModel station) => ChatConversation(
    mechanicName: station.name,
    avatarInitials: 'CH',
    licensePlate: 'Chưa có đơn cứu hộ',
    phoneNumber: station.station.phoneNumber,
    status: RescueStatus.accepted,
    statusLabel: station.openingLabel,
    lastMessage: 'Chào bạn! ${station.name} có thể hỗ trợ gì cho bạn?',
    timeLabel: '',
  );
}
