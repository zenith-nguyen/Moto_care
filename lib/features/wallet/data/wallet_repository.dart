import '../../../core/network/json_api.dart';
import '../domain/wallet_models.dart';

abstract interface class WalletRepository {
  Future<ProviderWallet> getMine();

  Future<WithdrawalHistory> getWithdrawals();

  Future<WithdrawalCreationResult> createWithdrawal(String amount);
}

class HttpWalletRepository implements WalletRepository {
  const HttpWalletRepository(this._api);

  final JsonApi _api;

  @override
  Future<ProviderWallet> getMine() async {
    return ProviderWallet.fromJson(await _api.getObject('/wallets/me'));
  }

  @override
  Future<WithdrawalHistory> getWithdrawals() async {
    return WithdrawalHistory.fromJson(await _api.getObject('/withdrawals/me'));
  }

  @override
  Future<WithdrawalCreationResult> createWithdrawal(String amount) async {
    final normalized = amount.trim();
    if (!RegExp(r'^(?!(?:0+\.00)$)(?:0|[1-9]\d{0,11})\.\d{2}$')
        .hasMatch(normalized)) {
      throw const FormatException(
        'Withdrawal must be a positive decimal with two digits.',
      );
    }
    final response = await _api.postObject(
      '/withdrawals',
      data: {'amount': normalized},
    );
    return WithdrawalCreationResult.fromJson(response);
  }
}
