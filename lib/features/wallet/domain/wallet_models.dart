import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';

enum WalletTransactionType {
  credit('CREDIT'),
  debit('DEBIT');

  const WalletTransactionType(this.wireValue);
  final String wireValue;

  static WalletTransactionType fromWire(Object? raw) {
    return values.firstWhere(
      (value) => value.wireValue == raw,
      orElse: () => throw FormatException('Unsupported transaction type: $raw'),
    );
  }
}

enum WithdrawalStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const WithdrawalStatus(this.wireValue);
  final String wireValue;

  static WithdrawalStatus fromWire(Object? raw) {
    return values.firstWhere(
      (value) => value.wireValue == raw,
      orElse: () =>
          throw FormatException('Unsupported withdrawal status: $raw'),
    );
  }
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.lockedBalance,
    required this.availableBalance,
    required this.currency,
  });

  final MoneyAmount balance;
  final MoneyAmount lockedBalance;
  final MoneyAmount availableBalance;
  final String currency;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WalletSummary(
      balance: MoneyAmount.parse(reader.value('balance')),
      lockedBalance: MoneyAmount.parse(reader.value('lockedBalance')),
      availableBalance: MoneyAmount.parse(reader.value('availableBalance')),
      currency: reader.string('currency'),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.orderId,
    required this.withdrawalId,
    required this.createdAt,
  });

  final int id;
  final WalletTransactionType type;
  final MoneyAmount amount;
  final int? orderId;
  final int? withdrawalId;
  final DateTime createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WalletTransaction(
      id: reader.positiveInt('id'),
      type: WalletTransactionType.fromWire(reader.value('type')),
      amount: MoneyAmount.parse(reader.value('amount')),
      orderId: reader.nullablePositiveInt('orderId'),
      withdrawalId: reader.nullablePositiveInt('withdrawalId'),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}

class ProviderWallet {
  const ProviderWallet({
    required this.providerId,
    required this.summary,
    required this.demoOnly,
    required this.transactions,
  });

  final int providerId;
  final WalletSummary summary;
  final bool demoOnly;
  final List<WalletTransaction> transactions;

  factory ProviderWallet.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ProviderWallet(
      providerId: reader.positiveInt('providerId'),
      summary: WalletSummary.fromJson(json),
      demoOnly: reader.boolean('demoOnly'),
      transactions: reader
          .list('transactions')
          .map(_object)
          .map(WalletTransaction.fromJson)
          .toList(growable: false),
    );
  }
}

class WithdrawalRequest {
  const WithdrawalRequest({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.status,
    required this.decisionReason,
    required this.processedById,
    required this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int providerId;
  final MoneyAmount amount;
  final WithdrawalStatus status;
  final String? decisionReason;
  final int? processedById;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WithdrawalRequest(
      id: reader.positiveInt('id'),
      providerId: reader.positiveInt('providerId'),
      amount: MoneyAmount.parse(reader.value('amount')),
      status: WithdrawalStatus.fromWire(reader.value('status')),
      decisionReason: reader.nullableString('decisionReason'),
      processedById: reader.nullablePositiveInt('processedById'),
      processedAt: reader.nullableDateTime('processedAt'),
      createdAt: reader.dateTime('createdAt'),
      updatedAt: reader.dateTime('updatedAt'),
    );
  }
}

class WithdrawalHistory {
  const WithdrawalHistory({
    required this.providerId,
    required this.wallet,
    required this.sandboxOnly,
    required this.items,
  });

  final int providerId;
  final WalletSummary wallet;
  final bool sandboxOnly;
  final List<WithdrawalRequest> items;

  factory WithdrawalHistory.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WithdrawalHistory(
      providerId: reader.positiveInt('providerId'),
      wallet: WalletSummary.fromJson(reader.object('wallet')),
      sandboxOnly: reader.boolean('sandboxOnly'),
      items: reader
          .list('items')
          .map(_object)
          .map(WithdrawalRequest.fromJson)
          .toList(growable: false),
    );
  }
}

class WithdrawalCreationResult {
  const WithdrawalCreationResult({
    required this.withdrawal,
    required this.wallet,
    required this.sandboxOnly,
  });

  final WithdrawalRequest withdrawal;
  final WalletSummary wallet;
  final bool sandboxOnly;

  factory WithdrawalCreationResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WithdrawalCreationResult(
      withdrawal: WithdrawalRequest.fromJson(reader.object('withdrawal')),
      wallet: WalletSummary.fromJson(reader.object('wallet')),
      sandboxOnly: reader.boolean('sandboxOnly'),
    );
  }
}

Map<String, dynamic> _object(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected an object item.');
  return Map<String, dynamic>.from(raw);
}
