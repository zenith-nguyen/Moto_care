import '../../../core/network/json_api.dart';
import '../../orders/domain/geo_point.dart';
import '../domain/provider_models.dart';

abstract interface class ProvidersRepository {
  Future<ProviderPresence> updateWaitingLocation(GeoPoint location);

  Future<ProviderPresence> setOnline(bool isOnline);

  Future<ProviderPresence> updateOrderLocation({
    required int orderId,
    required GeoPoint location,
  });

  Future<List<PendingOffer>> listPendingOffers();
}

class HttpProvidersRepository implements ProvidersRepository {
  const HttpProvidersRepository(this._api);

  final JsonApi _api;

  @override
  Future<ProviderPresence> updateWaitingLocation(GeoPoint location) async {
    final response = await _api.patchObject(
      '/providers/me/location',
      data: location.toRequestJson(),
    );
    return ProviderPresence.fromJson(response);
  }

  @override
  Future<ProviderPresence> setOnline(bool isOnline) async {
    final response = await _api.patchObject(
      '/providers/me/status',
      data: {'isOnline': isOnline},
    );
    return ProviderPresence.fromJson(response);
  }

  @override
  Future<ProviderPresence> updateOrderLocation({
    required int orderId,
    required GeoPoint location,
  }) async {
    _requirePositiveId(orderId, 'orderId');
    final response = await _api.patchObject(
      '/providers/me/orders/$orderId/location',
      data: location.toRequestJson(),
    );
    final responseOrderId = response['orderId'];
    if (responseOrderId is! int || responseOrderId != orderId) {
      throw const FormatException('Invalid order-location response.');
    }
    return ProviderPresence.fromJson(response);
  }

  @override
  Future<List<PendingOffer>> listPendingOffers() async {
    final response = await _api.getList('/providers/me/offers/pending');
    return response.map(PendingOffer.fromJson).toList(growable: false);
  }
}

void _requirePositiveId(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name);
}
