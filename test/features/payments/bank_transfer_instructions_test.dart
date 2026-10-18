import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/payments/domain/bank_transfer_instructions.dart';

void main() {
  Map<String, dynamic> validPayload() => {
    'provider': 'SEPAY',
    'mode': 'test',
    'simulationOnly': true,
    'paymentCode': 'MC42',
    'amount': '100000.00',
    'bank': 'MBBank',
    'accountNumber': 'SBSEPAYX9KA2B7MN4QR',
    'accountHolder': 'MOTOCARE DEMO',
    'transferContent': 'MC42',
    'qrImageUrl': 'https://vietqr.app/img?acc=SBSEPAYX9KA2B7MN4QR',
  };

  test('parses SePay Test mode simulation instructions', () {
    final instructions = BankTransferInstructions.fromJson(validPayload());

    expect(instructions.paymentCode, 'MC42');
    expect(instructions.simulationOnly, isTrue);
    expect(instructions.amount.value, '100000.00');
    expect(instructions.qrImageUri.scheme, 'https');
  });

  test('parses a consistent SePay Live instruction', () {
    final live = validPayload()
      ..['mode'] = 'live'
      ..['simulationOnly'] = false;

    final instructions = BankTransferInstructions.fromJson(live);
    expect(instructions.mode, 'live');
    expect(instructions.simulationOnly, isFalse);
  });

  test('refuses an inconsistent payment mode marker', () {
    final invalid = validPayload()..['mode'] = 'live';
    expect(
      () => BankTransferInstructions.fromJson(invalid),
      throwsFormatException,
    );
  });
}
