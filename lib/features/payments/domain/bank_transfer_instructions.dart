import '../../../core/money/money_amount.dart';

class BankTransferInstructions {
  const BankTransferInstructions({
    required this.paymentCode,
    required this.amount,
    required this.bank,
    required this.accountNumber,
    required this.accountHolder,
    required this.transferContent,
    required this.qrImageUri,
  });

  final String paymentCode;
  final MoneyAmount amount;
  final String bank;
  final String accountNumber;
  final String accountHolder;
  final String transferContent;
  final Uri qrImageUri;

  factory BankTransferInstructions.fromJson(Map<String, dynamic> json) {
    if (json['provider'] != 'SEPAY' ||
        json['mode'] != 'test' ||
        json['simulationOnly'] != true) {
      throw const FormatException(
        'Only SePay Test mode simulation instructions are supported.',
      );
    }

    final paymentCode = _requiredString(json, 'paymentCode');
    final bank = _requiredString(json, 'bank');
    final accountNumber = _requiredString(json, 'accountNumber');
    final accountHolder = _requiredString(json, 'accountHolder');
    final transferContent = _requiredString(json, 'transferContent');
    final qrImageUri = Uri.tryParse(_requiredString(json, 'qrImageUrl'));
    if (qrImageUri == null || qrImageUri.scheme != 'https') {
      throw const FormatException('Invalid SePay Test mode QR URL.');
    }

    return BankTransferInstructions(
      paymentCode: paymentCode,
      amount: MoneyAmount.parse(json['amount']),
      bank: bank,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      transferContent: transferContent,
      qrImageUri: qrImageUri,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing payment instruction field: $key');
    }
    return value;
  }
}
