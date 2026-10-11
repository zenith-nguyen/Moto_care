import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/wallet/data/wallet_repository.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('parses demo wallet and keeps ledger amounts unsigned', () async {
    final api = RecordingJsonApi()..objectResponse = _walletJson();

    final wallet = await HttpWalletRepository(api).getMine();

    expect(api.lastPath, '/wallets/me');
    expect(wallet.demoOnly, isTrue);
    expect(wallet.summary.availableBalance.value, '75000.00');
    expect(wallet.transactions.single.type, WalletTransactionType.credit);
    expect(wallet.transactions.single.amount.value, '100000.00');
  });

  test('creates only positive decimal sandbox withdrawals', () async {
    final api = RecordingJsonApi()..objectResponse = _creationJson();
    final repository = HttpWalletRepository(api);

    final result = await repository.createWithdrawal(' 50000.00 ');

    expect(api.lastPath, '/withdrawals');
    expect(api.lastData, {'amount': '50000.00'});
    expect(result.withdrawal.status, WithdrawalStatus.pending);
    expect(result.sandboxOnly, isTrue);
    await expectLater(
      repository.createWithdrawal('-1.00'),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _walletJson() => {
  'providerId': 3,
  'balance': '100000.00',
  'lockedBalance': '25000.00',
  'availableBalance': '75000.00',
  'currency': 'VND',
  'demoOnly': true,
  'transactions': [
    {
      'id': 1,
      'type': 'CREDIT',
      'amount': '100000.00',
      'orderId': 42,
      'withdrawalId': null,
      'createdAt': '2026-10-10T08:00:00.000Z',
    },
  ],
};

Map<String, dynamic> _creationJson() => {
  'withdrawal': {
    'id': 5,
    'providerId': 3,
    'amount': '50000.00',
    'status': 'PENDING',
    'decisionReason': null,
    'processedById': null,
    'processedAt': null,
    'createdAt': '2026-10-10T08:00:00.000Z',
    'updatedAt': '2026-10-10T08:00:00.000Z',
  },
  'wallet': {
    'balance': '100000.00',
    'lockedBalance': '50000.00',
    'availableBalance': '50000.00',
    'currency': 'VND',
  },
  'sandboxOnly': true,
};
