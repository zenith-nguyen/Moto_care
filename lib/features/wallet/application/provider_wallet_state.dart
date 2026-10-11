import '../domain/wallet_models.dart';

enum ProviderWalletAction { refresh, createWithdrawal }

class ProviderWalletState {
  const ProviderWalletState({
    required this.wallet,
    required this.withdrawals,
    this.action,
    this.lastFailure,
  });

  final ProviderWallet wallet;
  final WithdrawalHistory withdrawals;
  final ProviderWalletAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  ProviderWalletState copyWith({
    ProviderWallet? wallet,
    WithdrawalHistory? withdrawals,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return ProviderWalletState(
      wallet: wallet ?? this.wallet,
      withdrawals: withdrawals ?? this.withdrawals,
      action: identical(action, _unchanged)
          ? this.action
          : action as ProviderWalletAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
