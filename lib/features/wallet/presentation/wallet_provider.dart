// import 'dart:async';

// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../core/providers/base_provider.dart';
// import '../../../core/utils/app_logger.dart';
// import '../data/wallet_repository.dart';
// import '../domain/wallet_entity.dart';

// export '../domain/wallet_entity.dart';

// /// Wallet state — alive for the duration of the user session.
// ///
// /// Real-time balance sync: subscribes to Supabase Postgres CDC on wallets
// /// table filtered to the current user's wallet. Instant UI update on any
// /// server-side balance change (deposit approval, pack purchase, etc.)
// ///
// /// Offline safety: last-known balance is shown; operations fail gracefully
// /// with clear error messages when offline.
// class WalletProvider extends BaseProvider {
//   WalletProvider({required WalletRepository walletRepository})
//       : _repo = walletRepository;

//   final WalletRepository _repo;

//   // ── State ──────────────────────────────────────────────────────────────────
//   WalletEntity?              _wallet;
//   List<WalletTransaction>    _transactions    = [];
//   List<PaymentMethodEntity>  _depositMethods  = [];
//   List<PaymentMethodEntity>  _withdrawMethods = [];
//   List<DepositEntity>        _myDeposits      = [];
//   List<WithdrawalEntity>     _myWithdrawals   = [];
//   EarningsSummary?           _earnings;
//   bool                       _hasMoreTx       = true;
//   int                        _txPage          = 0;
//   bool                       _isLoadingMore   = false;

//   RealtimeChannel?           _balanceChannel;

//   // ── Getters ────────────────────────────────────────────────────────────────
//   WalletEntity?             get wallet          => _wallet;
//   int                       get balanceMru      => _wallet?.balanceMru ?? 0;
//   String                    get formattedBalance => _wallet?.formattedBalance ?? '0 MRU';
//   bool                      get isWalletFrozen  => _wallet?.isFrozen ?? false;
//   List<WalletTransaction>   get transactions    => _transactions;
//   List<PaymentMethodEntity> get depositMethods  => _depositMethods;
//   List<PaymentMethodEntity> get withdrawMethods => _withdrawMethods;
//   List<DepositEntity>       get myDeposits      => _myDeposits;
//   List<WithdrawalEntity>    get myWithdrawals   => _myWithdrawals;
//   EarningsSummary?          get earnings        => _earnings;
//   bool                      get hasMoreTx       => _hasMoreTx;
//   bool                      get isLoadingMore   => _isLoadingMore;

//   bool canAfford(int amountMru) => _wallet?.canDebit(amountMru) ?? false;

//   // ── Lifecycle ──────────────────────────────────────────────────────────────

//   @override
//   void onUserLoggedIn(String userId) {
//     _loadWallet(userId);
//     _loadPaymentMethods();
//   }

//   @override
//   void onUserLoggedOut() {
//     _balanceChannel?.unsubscribe();
//     _balanceChannel = null;
//     _wallet       = null;
//     _transactions = [];
//     _myDeposits   = [];
//     _myWithdrawals = [];
//     _earnings     = null;
//     _hasMoreTx    = true;
//     _txPage       = 0;
//     super.onUserLoggedOut();
//   }

//   @override
//   void dispose() {
//     _balanceChannel?.unsubscribe();
//     super.dispose();
//   }

//   // ── Load wallet ────────────────────────────────────────────────────────────

//   Future<void> _loadWallet(String userId) async {
//     await runAsync(() async {
//       _wallet = await _repo.getWallet(userId);
//     });
//     if (_wallet != null) {
//       _subscribeToBalance(_wallet!.id, userId);
//     }
//   }

//   Future<void> refreshWallet() async {
//     if (currentUserId == null) return;
//     final w = await _repo.getWalletSafe(currentUserId!);
//     if (w != null) {
//       _wallet = w;
//       notifyListeners();
//     }
//   }

//   // ── Realtime balance subscription ──────────────────────────────────────────
//   /// Subscribes to Postgres CDC on the wallets table.
//   /// When the server updates balance (after deposit approval, pack purchase, etc.)
//   /// the UI reflects it immediately — no polling needed.
//   void _subscribeToBalance(String walletId, String userId) {
//     _balanceChannel?.unsubscribe();

//     _balanceChannel = Supabase.instance.client
//         .channel('wallet-balance:$walletId')
//         .onPostgresChanges(
//           event:  PostgresChangeEvent.update,
//           schema: 'public',
//           table:  'wallets',
//           filter: PostgresChangeFilter(
//             type:   PostgresChangeFilterType.eq,
//             column: 'user_id',
//             value:  userId,
//           ),
//           callback: (payload) {
//             final newBalance = payload.newRecord['balance_mru'] as int?;
//             final isFrozen   = payload.newRecord['is_frozen']   as bool?;
//             if (newBalance != null && _wallet != null) {
//               _wallet = _wallet!.copyWith(
//                 balanceMru: newBalance,
//                 isFrozen:   isFrozen,
//               );
//               notifyListeners();
//               AppLogger.info(
//                   'WalletProvider: balance updated to $newBalance MRU');
//             }
//           },
//         )
//         .subscribe();
//   }

//   // ── Payment methods ────────────────────────────────────────────────────────

//   Future<void> _loadPaymentMethods() => runAsync(() async {
//     final results = await Future.wait([
//       _repo.getPaymentMethods(forDeposit: true),
//       _repo.getPaymentMethods(forDeposit: false),
//     ]);
//     _depositMethods  = results[0] as List<PaymentMethodEntity>;
//     _withdrawMethods = results[1] as List<PaymentMethodEntity>;
//   }, setLoading: false);

//   Future<void> refreshPaymentMethods() => _loadPaymentMethods();

//   // ── Transactions ───────────────────────────────────────────────────────────

//   Future<void> loadTransactions({bool reset = false}) async {
//     if (_wallet == null) return;
//     if (reset) { _txPage = 0; _hasMoreTx = true; _transactions = []; }
//     if (!_hasMoreTx) return;

//     await runAsync(() async {
//       const perPage = 30;
//       final tx = await _repo.getTransactions(
//         _wallet!.id,
//         limit:  perPage,
//         offset: _txPage * perPage,
//       );
//       _transactions = reset ? tx : [..._transactions, ...tx];
//       _hasMoreTx    = tx.length == perPage;
//       _txPage++;
//     }, setLoading: _transactions.isEmpty);
//   }

//   Future<void> loadMoreTransactions() async {
//     if (_isLoadingMore || !_hasMoreTx) return;
//     _isLoadingMore = true;
//     notifyListeners();
//     try { await loadTransactions(); }
//     finally { _isLoadingMore = false; notifyListeners(); }
//   }

//   // ── Deposit ────────────────────────────────────────────────────────────────

//   Future<({bool success, String? error, DepositEntity? deposit})>
//       requestDeposit({
//     required int    amountMru,
//     required String paymentMethodId,
//     required String phoneNumber,
//     required String paymentReference,
//     String? notes,
//   }) async {
//     final deposit = await runAsync(
//       () => _repo.requestDeposit(
//         amountMru:         amountMru,
//         paymentMethodId:   paymentMethodId,
//         phoneNumber:       phoneNumber,
//         paymentReference:  paymentReference,
//         notes:             notes,
//       ),
//     );

//     if (deposit != null) {
//       _myDeposits = [deposit, ..._myDeposits];
//       notifyListeners();
//       return (success: true, error: null, deposit: deposit);
//     }
//     return (success: false, error: failure?.message, deposit: null);
//   }

//   Future<void> loadMyDeposits() => runAsync(() async {
//     _myDeposits = await _repo.getMyDeposits();
//   }, setLoading: false);

//   // ── Withdrawal ─────────────────────────────────────────────────────────────

//   Future<({bool success, String? error, WithdrawalEntity? withdrawal})>
//       requestWithdrawal({
//     required int    amountMru,
//     required String paymentMethodId,
//     required String phoneNumber,
//     String? notes,
//   }) async {
//     final withdrawal = await runAsync(
//       () => _repo.requestWithdrawal(
//         amountMru:        amountMru,
//         paymentMethodId:  paymentMethodId,
//         phoneNumber:      phoneNumber,
//         notes:            notes,
//       ),
//     );

//     if (withdrawal != null) {
//       _myWithdrawals = [withdrawal, ..._myWithdrawals];
//       notifyListeners();
//       return (success: true, error: null, withdrawal: withdrawal);
//     }
//     return (success: false, error: failure?.message, withdrawal: null);
//   }

//   Future<void> loadMyWithdrawals() => runAsync(() async {
//     _myWithdrawals = await _repo.getMyWithdrawals();
//   }, setLoading: false);

//   // ── Creator earnings ───────────────────────────────────────────────────────

//   Future<void> loadEarnings() => runAsync(() async {
//     if (currentUserId == null) return;
//     _earnings = await _repo.getEarningsSummary(currentUserId!);
//   }, setLoading: false);
// }

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/base_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_entity.dart';

export '../domain/wallet_entity.dart';

/// Wallet state — alive for the duration of the user session.
///
/// Real-time balance sync: subscribes to Supabase Postgres CDC on wallets
/// table filtered to the current user's wallet. Instant UI update on any
/// server-side balance change (deposit approval, pack purchase, etc.)
///
/// Offline safety: last-known balance is shown; operations fail gracefully
/// with clear error messages when offline.
class WalletProvider extends BaseProvider {
  WalletProvider({required WalletRepository walletRepository})
    : _repo = walletRepository;

  final WalletRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  WalletEntity? _wallet;
  List<WalletTransaction> _transactions = [];
  List<PaymentMethodEntity> _depositMethods = [];
  List<PaymentMethodEntity> _withdrawMethods = [];
  List<DepositEntity> _myDeposits = [];
  List<WithdrawalEntity> _myWithdrawals = [];
  EarningsSummary? _earnings;
  bool _hasMoreTx = true;
  int _txPage = 0;
  bool _isLoadingMore = false;

  RealtimeChannel? _balanceChannel;

  // ── Getters ────────────────────────────────────────────────────────────────
  WalletEntity? get wallet => _wallet;
  int get balanceMru => _wallet?.balanceMru ?? 0;
  String get formattedBalance => _wallet?.formattedBalance ?? '0 MRU';
  bool get isWalletFrozen => _wallet?.isFrozen ?? false;
  List<WalletTransaction> get transactions => _transactions;
  List<PaymentMethodEntity> get depositMethods => _depositMethods;
  List<PaymentMethodEntity> get withdrawMethods => _withdrawMethods;
  List<DepositEntity> get myDeposits => _myDeposits;
  List<WithdrawalEntity> get myWithdrawals => _myWithdrawals;
  EarningsSummary? get earnings => _earnings;
  bool get hasMoreTx => _hasMoreTx;
  bool get isLoadingMore => _isLoadingMore;

  bool canAfford(int amountMru) => _wallet?.canDebit(amountMru) ?? false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onUserLoggedIn(String userId) {
    _loadWallet(userId);
    _loadPaymentMethods();
  }

  @override
  void onUserLoggedOut() {
    _balanceChannel?.unsubscribe();
    _balanceChannel = null;
    _wallet = null;
    _transactions = [];
    _myDeposits = [];
    _myWithdrawals = [];
    _earnings = null;
    _hasMoreTx = true;
    _txPage = 0;
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _balanceChannel?.unsubscribe();
    super.dispose();
  }

  // ── Load wallet ────────────────────────────────────────────────────────────

  Future<void> _loadWallet(String userId) async {
    await runAsync(() async {
      _wallet = await _repo.getWallet(userId);
    });
    if (_wallet != null) {
      _subscribeToBalance(_wallet!.id, userId);
    }
  }

  Future<void> refreshWallet() async {
    if (currentUserId == null) return;
    final w = await _repo.getWalletSafe(currentUserId!);
    if (w != null) {
      _wallet = w;
      notifyListeners();
    }
  }

  // ── Realtime balance subscription ──────────────────────────────────────────
  /// Subscribes to Postgres CDC on the wallets table.
  /// When the server updates balance (after deposit approval, pack purchase, etc.)
  /// the UI reflects it immediately — no polling needed.
  void _subscribeToBalance(String walletId, String userId) {
    _balanceChannel?.unsubscribe();

    _balanceChannel = Supabase.instance.client
        .channel('wallet-balance:$walletId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newBalance = payload.newRecord['balance_mru'] as int?;
            final isFrozen = payload.newRecord['is_frozen'] as bool?;
            if (newBalance != null && _wallet != null) {
              _wallet = _wallet!.copyWith(
                balanceMru: newBalance,
                isFrozen: isFrozen,
              );
              notifyListeners();
              AppLogger.info(
                'WalletProvider: balance updated to $newBalance MRU',
              );
            }
          },
        )
        .subscribe();
  }

  // ── Payment methods ────────────────────────────────────────────────────────

  Future<void> _loadPaymentMethods() => runAsync(() async {
    final results = await Future.wait([
      _repo.getPaymentMethods(forDeposit: true),
      _repo.getPaymentMethods(forDeposit: false),
    ]);
    _depositMethods = results[0] as List<PaymentMethodEntity>;
    _withdrawMethods = results[1] as List<PaymentMethodEntity>;
  }, setLoading: false);

  Future<void> refreshPaymentMethods() => _loadPaymentMethods();

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<void> loadTransactions({bool reset = false}) async {
    if (_wallet == null || _wallet!.id.isEmpty) return;
    if (reset) {
      _txPage = 0;
      _hasMoreTx = true;
      _transactions = [];
    }
    if (!_hasMoreTx) return;

    await runAsync(() async {
      const perPage = 30;
      final tx = await _repo.getTransactions(
        _wallet!.id,
        limit: perPage,
        offset: _txPage * perPage,
      );
      _transactions = reset ? tx : [..._transactions, ...tx];
      _hasMoreTx = tx.length == perPage;
      _txPage++;
    }, setLoading: _transactions.isEmpty);
  }

  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreTx) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await loadTransactions();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Deposit ────────────────────────────────────────────────────────────────

  Future<({bool success, String? error, DepositEntity? deposit})>
  requestDeposit({
    required int amountMru,
    required String paymentMethodId,
    required String phoneNumber,
    required String paymentReference,
    String? notes,
  }) async {
    final deposit = await runAsync(
      () => _repo.requestDeposit(
        amountMru: amountMru,
        paymentMethodId: paymentMethodId,
        phoneNumber: phoneNumber,
        paymentReference: paymentReference,
        notes: notes,
      ),
    );

    if (deposit != null) {
      _myDeposits = [deposit, ..._myDeposits];
      notifyListeners();
      return (success: true, error: null, deposit: deposit);
    }
    return (success: false, error: failure?.message, deposit: null);
  }

  Future<void> loadMyDeposits() => runAsync(() async {
    _myDeposits = await _repo.getMyDeposits();
  }, setLoading: false);

  // ── Withdrawal ─────────────────────────────────────────────────────────────

  Future<({bool success, String? error, WithdrawalEntity? withdrawal})>
  requestWithdrawal({
    required int amountMru,
    required String paymentMethodId,
    required String phoneNumber,
    String? notes,
  }) async {
    final withdrawal = await runAsync(
      () => _repo.requestWithdrawal(
        amountMru: amountMru,
        paymentMethodId: paymentMethodId,
        phoneNumber: phoneNumber,
        notes: notes,
      ),
    );

    if (withdrawal != null) {
      _myWithdrawals = [withdrawal, ..._myWithdrawals];
      notifyListeners();
      return (success: true, error: null, withdrawal: withdrawal);
    }
    return (success: false, error: failure?.message, withdrawal: null);
  }

  Future<void> loadMyWithdrawals() => runAsync(() async {
    _myWithdrawals = await _repo.getMyWithdrawals();
  }, setLoading: false);

  // ── Creator earnings ───────────────────────────────────────────────────────

  Future<void> loadEarnings() => runAsync(() async {
    if (currentUserId == null) return;
    _earnings = await _repo.getEarningsSummary(currentUserId!);
  }, setLoading: false);
}
