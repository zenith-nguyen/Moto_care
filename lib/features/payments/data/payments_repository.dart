import '../../../core/network/json_api.dart';
import '../domain/bank_transfer_instructions.dart';

abstract interface class PaymentsRepository {
  Future<BankTransferInstructions> getTestModeInstructions(int orderId);
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
}
