import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import 'provider_wallet_state.dart';

final providerWalletControllerProvider =
    AsyncNotifierProvider<ProviderWalletController, ProviderWalletState>(
      ProviderWalletController.new,
    );

class ProviderWalletController extends AsyncNotifier<ProviderWalletState> {
  @override
  Future<ProviderWalletState> build() async {
    final walletFuture = ref.read(walletRepositoryProvider).getMine();
    final withdrawalsFuture = ref
        .read(walletRepositoryProvider)
        .getWithdrawals();
    return ProviderWalletState(
      wallet: await walletFuture,
      withdrawals: await withdrawalsFuture,
    );
  }

  Future<void> refresh() async {
    await _run(ProviderWalletAction.refresh, _reload);
  }

  Future<void> createWithdrawal(String amount) async {
    await _run(ProviderWalletAction.createWithdrawal, () async {
      await ref.read(walletRepositoryProvider).createWithdrawal(amount);
      await _reload();
    });
  }

  Future<void> _reload() async {
    final walletFuture = ref.read(walletRepositoryProvider).getMine();
    final withdrawalsFuture = ref
        .read(walletRepositoryProvider)
        .getWithdrawals();
    state = AsyncData(
      _requireState().copyWith(
        wallet: await walletFuture,
        withdrawals: await withdrawalsFuture,
      ),
    );
  }

  Future<void> _run(
    ProviderWalletAction action,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(action: action, lastFailure: null));
    try {
      await operation();
      state = AsyncData(_requireState().copyWith(action: null));
    } catch (error) {
      state = AsyncData(
        _requireState().copyWith(action: null, lastFailure: error),
      );
    }
  }

  ProviderWalletState _requireState() {
    return state.value ?? (throw StateError('Provider wallet is not loaded.'));
  }
}
