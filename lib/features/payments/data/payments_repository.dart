import '../../../core/network/json_api.dart';
import '../domain/bank_transfer_instructions.dart';
import '../domain/demo_payment_result.dart';

abstract interface class PaymentsRepository {
  Future<BankTransferInstructions> getTestModeInstructions(int orderId);

  Future<DemoPrepaymentResult> confirmDemoPrepayment(int orderId);

  Future<DemoAdjustmentResult> confirmDemoAdjustment(int orderId);
}

class HttpPaymentsRepository implements PaymentsRepository {
  const HttpPaymentsRepository(this._api);

  final JsonApi _api;

  @override
  Future<BankTransferInstructions> getTestModeInstructions(int orderId) async {
    if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
    final response = await _api.getObject(
      '/payments/orders/$orderId/instructions',
    );
    return BankTransferInstructions.fromJson(response);
  }

  @override
  Future<DemoPrepaymentResult> confirmDemoPrepayment(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.postObject(
      '/payments/demo/orders/$orderId/confirm',
    );
    return DemoPrepaymentResult.fromJson(response);
  }

  @override
  Future<DemoAdjustmentResult> confirmDemoAdjustment(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.postObject(
      '/payments/demo/orders/$orderId/adjustment/confirm',
    );
    return DemoAdjustmentResult.fromJson(response);
  }
}

void _requireOrderId(int orderId) {
  if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
}
