import '../../../core/network/json_api.dart';
import '../domain/geo_point.dart';
import '../domain/order_action_results.dart';
import '../domain/order_models.dart';
import '../domain/price_decision_result.dart';

abstract interface class OrdersRepository {
  Future<List<OrderSummary>> listMine();

  Future<OrderCreationResult> create({
    required int incidentTypeId,
    required GeoPoint customerLocation,
  });

  Future<OrderDetails> getById(int orderId);

  Future<OrderCreationResult> retryMatching(int orderId);

  Future<OrderCancellationResult> cancel(int orderId, String reason);

  Future<ServiceStartToken> getStartToken(int orderId);

  Future<PriceDecisionResult> approveFinalPrice({
    required int orderId,
    required int proposalId,
  });

  Future<PriceDecisionResult> rejectFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  });
}

class HttpOrdersRepository implements OrdersRepository {
  const HttpOrdersRepository(this._api);

  final JsonApi _api;

  @override
  Future<List<OrderSummary>> listMine() async {
    final response = await _api.getList('/orders');
    return response.map(OrderSummary.fromJson).toList(growable: false);
  }

  @override
  Future<OrderCreationResult> create({
    required int incidentTypeId,
    required GeoPoint customerLocation,
  }) async {
    if (incidentTypeId <= 0) {
      throw ArgumentError.value(incidentTypeId, 'incidentTypeId');
    }
    final response = await _api.postObject(
      '/orders',
      data: {
        'incident_type_id': incidentTypeId,
        'customer_location': customerLocation.toRequestJson(),
      },
    );
    return OrderCreationResult.fromJson(response);
  }

  @override
  Future<OrderDetails> getById(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.getObject('/orders/$orderId');
    return OrderDetails.fromJson(response);
  }

  @override
  Future<OrderCreationResult> retryMatching(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.postObject('/orders/$orderId/retry-match');
    return OrderCreationResult.fromJson(response);
  }

  @override
  Future<OrderCancellationResult> cancel(int orderId, String reason) async {
    _requireOrderId(orderId);
    final normalizedReason = reason.trim();
    if (normalizedReason.length < 3 || normalizedReason.length > 500) {
      throw const FormatException(
        'Cancellation reason must contain 3 to 500 characters.',
      );
    }
    final response = await _api.postObject(
      '/orders/$orderId/cancel',
      data: {'reason': normalizedReason},
    );
    return OrderCancellationResult.fromJson(response);
  }

  @override
  Future<ServiceStartToken> getStartToken(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.getObject('/orders/$orderId/start-token');
    return ServiceStartToken.fromJson(response);
  }

  @override
  Future<PriceDecisionResult> approveFinalPrice({
    required int orderId,
    required int proposalId,
  }) async {
    _requireOrderId(orderId);
    _requireProposalId(proposalId);
    final response = await _api.postObject(
      '/orders/$orderId/price-proposals/$proposalId/approve',
    );
    return PriceDecisionResult.fromJson(response);
  }

  @override
  Future<PriceDecisionResult> rejectFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  }) async {
    _requireOrderId(orderId);
    _requireProposalId(proposalId);
    final normalized = reason.trim();
    if (normalized.length < 3 || normalized.length > 500) {
      throw const FormatException(
        'Price rejection reason must contain 3 to 500 characters.',
      );
    }
    final response = await _api.postObject(
      '/orders/$orderId/price-proposals/$proposalId/reject',
      data: {'reason': normalized},
    );
    return PriceDecisionResult.fromJson(response);
  }
}

void _requireOrderId(int orderId) {
  if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
}

void _requireProposalId(int proposalId) {
  if (proposalId <= 0) throw ArgumentError.value(proposalId, 'proposalId');
}
