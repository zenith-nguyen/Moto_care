import '../../activity/models/rescue_order.dart';
import '../../rescue_station/models/rescue_station.dart';
import 'marketplace_catalog.dart';

enum PartnerVehicleType {
  scooter('Xe tay ga'),
  underbone('Xe số'),
  largeBike('PKL'),
  tubeless('Lốp không ruột');

  const PartnerVehicleType(this.label);
  final String label;
}

class PartnerShop {
  PartnerShop({
    required this.station,
    required List<PartnerVehicleType> vehicleTypes,
    required List<RescueServiceType> services,
  }) : vehicleTypes = List.unmodifiable(vehicleTypes),
       services = List.unmodifiable(services);
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
        .toList(growable: false);
  }

  String get supportedVehicles =>
      vehicleTypes.contains(PartnerVehicleType.largeBike)
      ? 'Honda, Yamaha, Vespa, PKL'
      : 'Honda, Yamaha, Vespa';
}
