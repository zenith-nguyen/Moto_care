import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../rescue_station/models/rescue_station.dart';
import '../../rescue_station/providers/rescue_station_provider.dart';
import '../models/marketplace_catalog.dart';

enum PartnerVehicleType {
  scooter('Xe tay ga'),
  underbone('Xe số'),
  largeBike('PKL'),
  tubeless('Lốp không ruột');

  const PartnerVehicleType(this.label);
  final String label;
}

class PartnerShop {
  const PartnerShop({
    required this.station,
    required this.vehicleTypes,
    required this.services,
  });
  final RescueStation station;
  final List<PartnerVehicleType> vehicleTypes;
  final List<RescueServiceType> services;
  String get id => station.id;
  List<ServicePackage> menu(String serviceType) {
    final requested = MarketplaceCatalog.typeFor(serviceType);
    return MarketplaceCatalog.packages
        .where(
          (package) =>
              services.contains(package.serviceType) &&
              (requested == null || package.serviceType == requested),
        )
        .toList();
  }

  String get supportedVehicles =>
      vehicleTypes.contains(PartnerVehicleType.largeBike)
      ? 'Honda, Yamaha, Vespa, PKL'
      : 'Honda, Yamaha, Vespa';
}

// Capabilities and menu prices are sample data until a partner API is connected.
final partnerShopsProvider = Provider<List<PartnerShop>>(
  (ref) => [
    for (final station in ref.watch(rescueStationsProvider))
      PartnerShop(
        station: station,
        vehicleTypes: station.stationType == StationType.officialDealer
            ? PartnerVehicleType.values
            : [
                PartnerVehicleType.scooter,
                PartnerVehicleType.underbone,
                PartnerVehicleType.tubeless,
              ],
        services: station.stationType == StationType.mobileTeam
            ? RescueServiceType.values
                  .where(
                    (type) =>
                        type != RescueServiceType.charging &&
                        type != RescueServiceType.maintenance,
                  )
                  .toList()
            : RescueServiceType.values,
      ),
  ],
);
