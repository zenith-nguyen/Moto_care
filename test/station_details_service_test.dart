import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/activity/models/rescue_order.dart';
import 'package:revo/features/home/models/home_discovery.dart';
import 'package:revo/features/partner/providers/partner_provider.dart';
import 'package:revo/features/rescue_station/data/mock_rescue_stations.dart';
import 'package:revo/features/rescue_station/models/station_model.dart';
import 'package:revo/features/rescue_station/models/service_catalog_model.dart';
import 'package:revo/features/rescue_station/providers/station_details_provider.dart';
import 'package:revo/features/rescue_station/services/station_details_service.dart';

void main() {
  test(
    'Featured packages match the selected partner menu and capabilities',
    () {
      final shop = PartnerShop(
        station: mockRescueStations.first,
        vehicleTypes: const [],
        services: const [RescueServiceType.flatTire],
      );
      final model = const StationDetailsService().build(
        shop: shop,
        details: const HomeStationDetails(
          imageAsset: 'shop.png',
          reviewCount: 7,
        ),
        profile: StationProfile(description: 'Tiệm sửa xe'),
        distanceKm: 2.3,
      );
      expect(model.services, hasLength(1));
      final package = model.services.single;
      expect(shop.menu('Tất cả dịch vụ'), contains(package));
      expect(package.price, 50000);
      final entry = model.serviceCatalog.single;
      expect(
        (entry.id, entry.name, entry.price),
        (package.id, package.name, package.price),
      );
      expect(entry.fulfillment, ServiceFulfillment.onSite);
      expect(entry.details, isNull);
      expect(model.distanceKm, 2.3);
      expect(model.reviewCount, 7);
      expect(model.mechanicCount, isNull);
      expect(model.warrantyLabel, isNull);
    },
  );

  test(
    'Profiles and models copy gallery lists instead of sharing mutable input',
    () {
      final images = ['first.png'];
      final profile = StationProfile(description: 'Trạm', imageAssets: images);
      images.add('another-station.png');
      final model = const StationDetailsService().build(
        shop: PartnerShop(
          station: mockRescueStations.first,
          vehicleTypes: const [],
          services: const [],
        ),
        details: const HomeStationDetails(imageAsset: 'fallback.png'),
        profile: profile,
        distanceKm: 1,
      );
      expect(model.imageAssets, ['first.png']);
      expect(
        () => model.imageAssets.add('mutation.png'),
        throwsUnsupportedError,
      );
      expect(() => model.services.clear(), throwsUnsupportedError);
      expect(() => model.serviceCatalog.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Catalog joins station details by package ID without changing prices',
    () {
      final steps = ['Kiểm tra lốp', 'Vá và kiểm tra độ kín'];
      final detail = ServiceCatalogDetails(
        description: 'Vá nấm chuyên dụng • 10 phút',
        procedureSteps: steps,
        materialsCommitment: 'Vật tư đã xác nhận',
        warranty: '30 ngày',
      );
      final details = {'tire-tubeless': detail, 'unsupported-package': detail};
      final profile = StationProfile(
        description: 'Trạm',
        serviceDetails: details,
      );
      steps.clear();
      details.clear();
      final model = const StationDetailsService().build(
        shop: PartnerShop(
          station: mockRescueStations.first,
          vehicleTypes: const [],
          services: const [
            RescueServiceType.flatTire,
            RescueServiceType.batteryJump,
            RescueServiceType.towing,
          ],
        ),
        details: const HomeStationDetails(imageAsset: 'shop.png'),
        profile: profile,
        distanceKm: 1,
      );
      expect(
        model.serviceCatalog.map(
          (entry) => (entry.id, entry.name, entry.price),
        ),
        model.services.map(
          (package) => (package.id, package.name, package.price),
        ),
      );
      expect(model.serviceCatalog.first.details, same(detail));
      expect(detail.procedureSteps, ['Kiểm tra lốp', 'Vá và kiểm tra độ kín']);
      expect(
        () => detail.procedureSteps.add('mutation'),
        throwsUnsupportedError,
      );
      expect(() => profile.serviceDetails.clear(), throwsUnsupportedError);
      expect(model.serviceCatalog[1].details, isNull);
      expect(
        model.serviceCatalog.last.fulfillment,
        ServiceFulfillment.toWorkshop,
      );
      expect(
        model.serviceCatalog.map((entry) => entry.id),
        isNot(contains('unsupported-package')),
      );
    },
  );

  test('Missing station IDs never borrow a fallback identity', () {
    final state = ProviderContainer(
      overrides: [partnerShopsProvider.overrideWithValue([])],
    );
    addTearDown(state.dispose);
    expect(state.read(stationModelProvider('missing')), isNull);
  });
}
