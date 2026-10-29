import '../../../core/money/money_amount.dart';

class BankTransferInstructions {
  const BankTransferInstructions({
    required this.paymentCode,
    required this.mode,
    required this.simulationOnly,
    required this.amount,
    required this.bank,
    required this.accountNumber,
    required this.accountHolder,
    required this.transferContent,
    required this.qrImageUri,
  });

  final String paymentCode;
  final String mode;
  final bool simulationOnly;
  final MoneyAmount amount;
  final String bank;
  final String accountNumber;
  final String accountHolder;
  final String transferContent;
  final Uri qrImageUri;

  factory BankTransferInstructions.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'];
    final simulationOnly = json['simulationOnly'];
    final validModePair =
        (mode == 'test' && simulationOnly == true) ||
        (mode == 'live' && simulationOnly == false);
    if (json['provider'] != 'SEPAY' || !validModePair) {
      throw const FormatException('Invalid SePay payment mode.');
    }

    final paymentCode = _requiredString(json, 'paymentCode');
    final bank = _requiredString(json, 'bank');
    final accountNumber = _requiredString(json, 'accountNumber');
    final accountHolder = _requiredString(json, 'accountHolder');
    final transferContent = _requiredString(json, 'transferContent');
    final qrImageUri = Uri.tryParse(_requiredString(json, 'qrImageUrl'));
    if (qrImageUri == null || qrImageUri.scheme != 'https') {
      throw const FormatException('Invalid SePay QR URL.');
    }

    return BankTransferInstructions(
      paymentCode: paymentCode,
      mode: mode as String,
      simulationOnly: simulationOnly as bool,
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
