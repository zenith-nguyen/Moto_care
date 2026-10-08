import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../rescue_station/models/rescue_station.dart';
import '../../rescue_station/providers/rescue_station_provider.dart';
import '../models/partner_shop.dart';
export '../models/partner_shop.dart';

// Capabilities and menu prices are sample data until a partner API is connected.
final partnerShopsProvider = Provider<List<PartnerShop>>(
  (ref) => List.unmodifiable([
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
  ]),
);
