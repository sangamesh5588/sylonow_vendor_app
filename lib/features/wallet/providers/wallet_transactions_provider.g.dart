// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletTransactionsHash() =>
    r'4ed5ade2c5ea47b16f1ceee1fc10eb7cf1278e0a';

/// See also [WalletTransactions].
@ProviderFor(WalletTransactions)
final walletTransactionsProvider = AutoDisposeAsyncNotifierProvider<
    WalletTransactions, List<WalletTransaction>>.internal(
  WalletTransactions.new,
  name: r'walletTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WalletTransactions
    = AutoDisposeAsyncNotifier<List<WalletTransaction>>;
String _$recentWalletTransactionsHash() =>
    r'01fb49e2b7d41e65a3c598e1ebde8e7acfb412ac';

/// See also [RecentWalletTransactions].
@ProviderFor(RecentWalletTransactions)
final recentWalletTransactionsProvider = AutoDisposeAsyncNotifierProvider<
    RecentWalletTransactions, List<WalletTransaction>>.internal(
  RecentWalletTransactions.new,
  name: r'recentWalletTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentWalletTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RecentWalletTransactions
    = AutoDisposeAsyncNotifier<List<WalletTransaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
