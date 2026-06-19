// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:uuid/uuid.dart';

// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/network/api_client.dart';
// // import '../domain/wallet_entity.dart';

// // export '../domain/wallet_entity.dart';

// // const _uuid = Uuid();

// // /// All wallet read/write operations.
// // ///
// // /// Reads  → Supabase direct (RLS-protected — users see only their own data)
// // /// Writes → Node.js API (service_role — owns business rules, idempotency, audit)
// // ///
// // /// Security model:
// // /// - Client never calls apply_wallet_transaction() directly
// // /// - All balance mutations go through Node.js which validates, logs, and
// // ///   uses FOR UPDATE row locks to prevent race conditions
// // class WalletRepository extends BaseRepository {
// //   WalletRepository._();
// //   static final WalletRepository _instance = WalletRepository._();
// //   static WalletRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;
// //   final _api = ApiClient.instance;

// //   // ── Wallet ─────────────────────────────────────────────────────────────────

// //   Future<WalletEntity> getWallet(String userId) => guardedCall(
// //     operationName: 'getWallet',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('wallets')
// //           .select()
// //           .eq('user_id', userId)
// //           .single();
// //       return _rowToWallet(row);
// //     },
// //   );

// //   Future<WalletEntity?> getWalletSafe(String userId) => softCall(
// //     operationName: 'getWalletSafe',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('wallets')
// //           .select()
// //           .eq('user_id', userId)
// //           .maybeSingle();
// //       // if (row == null) return null;
// //       if (row == null)
// //         throw const NotFoundFailure(message: 'Wallet not found.');
// //       return _rowToWallet(row);
// //     },
// //   );

// //   // ── Transactions ───────────────────────────────────────────────────────────

// //   Future<List<WalletTransaction>> getTransactions(
// //     String walletId, {
// //     int limit = 30,
// //     int offset = 0,
// //     TransactionType? typeFilter,
// //   }) => guardedCall(
// //     operationName: 'getTransactions',
// //     operation: () async {
// //       var q = _supabase
// //           .from('wallet_transactions')
// //           .select()
// //           .eq('wallet_id', walletId);

// //       if (typeFilter != null) {
// //         q = q.eq('type', typeFilter.name);
// //       }

// //       final rows = await q
// //           .order('created_at', ascending: false)
// //           .range(offset, offset + limit - 1);

// //       return rows.map(_rowToTransaction).toList();
// //     },
// //   );

// //   // ── Payment methods (admin-managed, fetched dynamically) ──────────────────

// //   Future<List<PaymentMethodEntity>> getPaymentMethods({
// //     bool forDeposit = true,
// //   }) => guardedCall(
// //     operationName: 'getPaymentMethods',
// //     operation: () async {
// //       var q = _supabase
// //           .from('payment_methods_config')
// //           .select()
// //           .eq('is_active', true);

// //       if (forDeposit) {
// //         q = q.eq('supports_deposit', true);
// //       } else {
// //         q = q.eq('supports_withdrawal', true);
// //       }

// //       final rows = await q.order('sort_order');
// //       return rows.map(_rowToPaymentMethod).toList();
// //     },
// //   );

// //   // ── Deposits ───────────────────────────────────────────────────────────────

// //   /// Submit a deposit request.
// //   /// Node.js validates and creates the pending deposit row.
// //   /// Admin approves/rejects via the admin dashboard.
// //   Future<DepositEntity> requestDeposit({
// //     required int amountMru,
// //     required String paymentMethodId,
// //     required String phoneNumber,
// //     required String paymentReference,
// //     String? notes,
// //   }) => guardedCall(
// //     operationName: 'requestDeposit',
// //     operation: () async {
// //       // Client-side validation before touching network
// //       if (amountMru < 100) {
// //         throw const ValidationFailure(
// //           message: 'Minimum deposit amount is 100 MRU.',
// //         );
// //       }
// //       if (amountMru > 1_000_000) {
// //         throw const ValidationFailure(
// //           message: 'Maximum deposit amount is 1,000,000 MRU.',
// //         );
// //       }
// //       if (phoneNumber.trim().isEmpty) {
// //         throw const ValidationFailure(message: 'Phone number is required.');
// //       }
// //       if (paymentReference.trim().isEmpty) {
// //         throw const ValidationFailure(
// //           message: 'Payment reference is required.',
// //         );
// //       }

// //       final resp = await _api.post<Map<String, dynamic>>(
// //         '/v1/wallet/deposit-request',
// //         data: {
// //           'amount_mru': amountMru,
// //           'payment_method_id': paymentMethodId,
// //           'phone_number': phoneNumber.trim(),
// //           'payment_reference': paymentReference.trim(),
// //           'notes': notes,
// //           'idempotency_key': _uuid.v4(),
// //         },
// //       );

// //       final data = resp.data!['data'] as Map<String, dynamic>;
// //       return _rowToDeposit(data['deposit'] as Map<String, dynamic>);
// //     },
// //   );

// //   Future<List<DepositEntity>> getMyDeposits({int limit = 20}) => guardedCall(
// //     operationName: 'getMyDeposits',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('deposits')
// //           .select()
// //           .order('created_at', ascending: false)
// //           .limit(limit);
// //       return rows.map(_rowToDeposit).toList();
// //     },
// //   );

// //   // ── Withdrawals ────────────────────────────────────────────────────────────

// //   Future<WithdrawalEntity> requestWithdrawal({
// //     required int amountMru,
// //     required String paymentMethodId,
// //     required String phoneNumber,
// //     String? notes,
// //   }) => guardedCall(
// //     operationName: 'requestWithdrawal',
// //     operation: () async {
// //       if (amountMru < 500) {
// //         throw const ValidationFailure(
// //           message: 'Minimum withdrawal amount is 500 MRU.',
// //         );
// //       }
// //       if (phoneNumber.trim().isEmpty) {
// //         throw const ValidationFailure(message: 'Phone number is required.');
// //       }

// //       final resp = await _api.post<Map<String, dynamic>>(
// //         '/v1/wallet/withdrawal-request',
// //         data: {
// //           'amount_mru': amountMru,
// //           'payment_method_id': paymentMethodId,
// //           'phone_number': phoneNumber.trim(),
// //           'notes': notes,
// //           'idempotency_key': _uuid.v4(),
// //         },
// //       );

// //       final data = resp.data!['data'] as Map<String, dynamic>;
// //       return _rowToWithdrawal(data['withdrawal'] as Map<String, dynamic>);
// //     },
// //   );

// //   Future<List<WithdrawalEntity>> getMyWithdrawals({int limit = 20}) =>
// //       guardedCall(
// //         operationName: 'getMyWithdrawals',
// //         operation: () async {
// //           final rows = await _supabase
// //               .from('withdrawals')
// //               .select()
// //               .order('created_at', ascending: false)
// //               .limit(limit);
// //           return rows.map(_rowToWithdrawal).toList();
// //         },
// //       );

// //   // ── Creator earnings ───────────────────────────────────────────────────────

// //   Future<EarningsSummary> getEarningsSummary(String creatorId) => guardedCall(
// //     operationName: 'getEarningsSummary',
// //     operation: () async {
// //       final resp = await _api.get<Map<String, dynamic>>(
// //         '/v1/wallet/earnings-summary',
// //       );
// //       final data = resp.data!['data'] as Map<String, dynamic>;
// //       return EarningsSummary(
// //         totalEarnedMru: data['total_earned_mru'] as int? ?? 0,
// //         pendingEarningsMru: data['pending_earnings_mru'] as int? ?? 0,
// //         availableForWithdrawalMru:
// //             data['available_for_withdrawal_mru'] as int? ?? 0,
// //         totalSales: data['total_sales'] as int? ?? 0,
// //         thisMonthMru: data['this_month_mru'] as int? ?? 0,
// //         commissionRate: (data['commission_rate'] as num?)?.toDouble() ?? 0.15,
// //       );
// //     },
// //   );

// //   // ── Mappers ────────────────────────────────────────────────────────────────

// //   WalletEntity _rowToWallet(Map<String, dynamic> r) => WalletEntity(
// //     id: r['id'] as String,
// //     userId: r['user_id'] as String,
// //     balanceMru: r['balance_mru'] as int? ?? 0,
// //     isFrozen: r['is_frozen'] as bool? ?? false,
// //     updatedAt: r['updated_at'] != null
// //         ? DateTime.tryParse(r['updated_at'] as String)
// //         : null,
// //   );

// //   WalletTransaction _rowToTransaction(Map<String, dynamic> r) =>
// //       WalletTransaction(
// //         id: r['id'] as String,
// //         walletId: r['wallet_id'] as String,
// //         type: TransactionType.fromString(r['type'] as String? ?? 'deposit'),
// //         status: TransactionStatus.fromString(
// //           r['status'] as String? ?? 'completed',
// //         ),
// //         amountMru: r['amount_mru'] as int,
// //         balanceBefore: r['balance_before'] as int? ?? 0,
// //         balanceAfter: r['balance_after'] as int? ?? 0,
// //         description: r['description'] as String?,
// //         referenceId: r['reference_id'] as String?,
// //         idempotencyKey: r['idempotency_key'] as String?,
// //         createdAt: DateTime.parse(r['created_at'] as String),
// //       );

// //   DepositEntity _rowToDeposit(Map<String, dynamic> r) => DepositEntity(
// //     id: r['id'] as String,
// //     walletId: r['wallet_id'] as String? ?? '',
// //     userId: r['user_id'] as String? ?? '',
// //     amountMru: r['amount_mru'] as int,
// //     paymentMethod: r['payment_method'] as String? ?? '',
// //     paymentReference: r['payment_reference'] as String?,
// //     status: DepositStatus.fromString(r['status'] as String? ?? 'pending'),
// //     rejectedReason: r['rejected_reason'] as String?,
// //     submittedAt: DateTime.parse(r['created_at'] as String),
// //     approvedAt: r['approved_at'] != null
// //         ? DateTime.tryParse(r['approved_at'] as String)
// //         : null,
// //     rejectedAt: r['rejected_at'] != null
// //         ? DateTime.tryParse(r['rejected_at'] as String)
// //         : null,
// //   );

// //   WithdrawalEntity _rowToWithdrawal(Map<String, dynamic> r) => WithdrawalEntity(
// //     id: r['id'] as String,
// //     walletId: r['wallet_id'] as String? ?? '',
// //     userId: r['user_id'] as String? ?? '',
// //     amountMru: r['amount_mru'] as int,
// //     payoutMethod: r['payout_method'] as String? ?? '',
// //     payoutDetails: (r['payout_details'] as Map?)?.cast<String, dynamic>() ?? {},
// //     status: TransactionStatus.fromString(r['status'] as String? ?? 'pending'),
// //     rejectedReason: r['rejected_reason'] as String?,
// //     submittedAt: DateTime.parse(r['created_at'] as String),
// //     processedAt: r['processed_at'] != null
// //         ? DateTime.tryParse(r['processed_at'] as String)
// //         : null,
// //   );

// //   PaymentMethodEntity _rowToPaymentMethod(Map<String, dynamic> r) =>
// //       PaymentMethodEntity(
// //         id: r['id'] as String,
// //         type: r['type'] as String? ?? 'other',
// //         name: r['name'] as String,
// //         logoUrl: r['logo_url'] as String?,
// //         accountNumber: r['account_number'] as String?,
// //         accountName: r['account_name'] as String?,
// //         instructions: r['instructions'] as String?,
// //         isActive: r['is_active'] as bool? ?? true,
// //         supportsDeposit: r['supports_deposit'] as bool? ?? true,
// //         supportsWithdrawal: r['supports_withdrawal'] as bool? ?? true,
// //         minAmountMru: r['min_amount_mru'] as int?,
// //         maxAmountMru: r['max_amount_mru'] as int?,
// //         sortOrder: r['sort_order'] as int? ?? 0,
// //       );
// // }

// import 'package:jma3a/core/utils/app_logger.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';

// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/network/api_client.dart';
// import '../domain/wallet_entity.dart';

// export '../domain/wallet_entity.dart';

// const _uuid = Uuid();

// /// All wallet read/write operations.
// ///
// /// Reads  → Supabase direct (RLS-protected — users see only their own data)
// /// Writes → Node.js API (service_role — owns business rules, idempotency, audit)
// ///
// /// Security model:
// /// - Client never calls apply_wallet_transaction() directly
// /// - All balance mutations go through Node.js which validates, logs, and
// ///   uses FOR UPDATE row locks to prevent race conditions
// class WalletRepository extends BaseRepository {
//   WalletRepository._();
//   static final WalletRepository _instance = WalletRepository._();
//   static WalletRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _api = ApiClient.instance;

//   // ── Wallet ─────────────────────────────────────────────────────────────────

//   Future<WalletEntity> getWallet(String userId) => guardedCall(
//     operationName: 'getWallet',
//     operation: () async {
//       final row = await _supabase
//           .from('wallets')
//           .select()
//           .eq('user_id', userId)
//           .single();
//       return _rowToWallet(row);
//     },
//   );

//   // Future<WalletEntity?> getWalletSafe(String userId) => softCall(
//   //   operationName: 'getWalletSafe',
//   //   operation: () async {
//   //     // Try to fetch first
//   //     var row = await _supabase
//   //         .from('wallets')
//   //         .select()
//   //         .eq('user_id', userId)
//   //         .maybeSingle();

//   //     // Wallet missing — the DB trigger should have created it on profile insert.
//   //     // Upsert as fallback (works if RLS allows own-user insert).
//   //     if (row == null) {
//   //       await _supabase
//   //           .from('wallets')
//   //           .upsert({
//   //             'user_id': userId,
//   //             'balance_mru': 0,
//   //           }, onConflict: 'user_id')
//   //           .select()
//   //           .maybeSingle()
//   //           .then((r) => row = r)
//   //           .catchError((_) {});
//   //     }

//   //     if (row == null) return null; // softCall returns null, no crash
//   //     return _rowToWallet(row);
//   //   },
//   // );

//   Future<WalletEntity?> getWalletSafe(String userId) => softCall(
//     operationName: 'getWalletSafe',
//     operation: () async {
//       // First try to fetch existing wallet
//       var row = await _supabase
//           .from('wallets')
//           .select()
//           .eq('user_id', userId)
//           .maybeSingle();

//       // If not found, try to create it via the backend API
//       if (row == null) {
//         try {
//           final resp = await _api.post<Map<String, dynamic>>(
//             '/v1/wallet/ensure', // You need to create this endpoint in Node.js
//             data: {'user_id': userId},
//           );
//           row = resp.data?['data'] as Map<String, dynamic>?;
//         } catch (e) {
//           // If API fails, return a zero-balance placeholder
//           AppLogger.warning('Could not create wallet via API: $e');
//           return WalletEntity(
//             id: '',
//             userId: userId,
//             balanceMru: 0,
//             isFrozen: false,
//             updatedAt: null,
//           );
//         }
//       }

//       if (row == null)
//         throw const NotFoundFailure(message: 'Wallet not found.');
//       ;
//       return _rowToWallet(row);
//     },
//   );
//   // ── Transactions ───────────────────────────────────────────────────────────

//   Future<List<WalletTransaction>> getTransactions(
//     String walletId, {
//     int limit = 30,
//     int offset = 0,
//     TransactionType? typeFilter,
//   }) => guardedCall(
//     operationName: 'getTransactions',
//     operation: () async {
//       var q = _supabase
//           .from('wallet_transactions')
//           .select()
//           .eq('wallet_id', walletId);

//       if (typeFilter != null) {
//         q = q.eq('type', typeFilter.name);
//       }

//       final rows = await q
//           .order('created_at', ascending: false)
//           .range(offset, offset + limit - 1);

//       return rows.map(_rowToTransaction).toList();
//     },
//   );

//   // ── Payment methods (admin-managed, fetched dynamically) ──────────────────

//   Future<List<PaymentMethodEntity>> getPaymentMethods({
//     bool forDeposit = true,
//   }) => guardedCall(
//     operationName: 'getPaymentMethods',
//     operation: () async {
//       var q = _supabase
//           .from('payment_methods_config')
//           .select()
//           .eq('is_active', true);

//       if (forDeposit) {
//         q = q.eq('supports_deposit', true);
//       } else {
//         q = q.eq('supports_withdrawal', true);
//       }

//       final rows = await q.order('sort_order');
//       return rows.map(_rowToPaymentMethod).toList();
//     },
//   );

//   // ── Deposits ───────────────────────────────────────────────────────────────

//   /// Submit a deposit request.
//   /// Node.js validates and creates the pending deposit row.
//   /// Admin approves/rejects via the admin dashboard.
//   Future<DepositEntity> requestDeposit({
//     required int amountMru,
//     required String paymentMethodId,
//     required String phoneNumber,
//     required String paymentReference,
//     String? notes,
//   }) => guardedCall(
//     operationName: 'requestDeposit',
//     operation: () async {
//       // Client-side validation before touching network
//       if (amountMru < 100) {
//         throw const ValidationFailure(
//           message: 'Minimum deposit amount is 100 MRU.',
//         );
//       }
//       if (amountMru > 1_000_000) {
//         throw const ValidationFailure(
//           message: 'Maximum deposit amount is 1,000,000 MRU.',
//         );
//       }
//       if (phoneNumber.trim().isEmpty) {
//         throw const ValidationFailure(message: 'Phone number is required.');
//       }
//       if (paymentReference.trim().isEmpty) {
//         throw const ValidationFailure(
//           message: 'Payment reference is required.',
//         );
//       }

//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/wallet/deposit-request',
//         data: {
//           'amount_mru': amountMru,
//           'payment_method_id': paymentMethodId,
//           'phone_number': phoneNumber.trim(),
//           'payment_reference': paymentReference.trim(),
//           'notes': notes,
//           'idempotency_key': _uuid.v4(),
//         },
//       );

//       final data = resp.data!['data'] as Map<String, dynamic>;
//       return _rowToDeposit(data['deposit'] as Map<String, dynamic>);
//     },
//   );

//   Future<List<DepositEntity>> getMyDeposits({int limit = 20}) => guardedCall(
//     operationName: 'getMyDeposits',
//     operation: () async {
//       final rows = await _supabase
//           .from('deposits')
//           .select()
//           .order('created_at', ascending: false)
//           .limit(limit);
//       return rows.map(_rowToDeposit).toList();
//     },
//   );

//   // ── Withdrawals ────────────────────────────────────────────────────────────

//   Future<WithdrawalEntity> requestWithdrawal({
//     required int amountMru,
//     required String paymentMethodId,
//     required String phoneNumber,
//     String? notes,
//   }) => guardedCall(
//     operationName: 'requestWithdrawal',
//     operation: () async {
//       if (amountMru < 500) {
//         throw const ValidationFailure(
//           message: 'Minimum withdrawal amount is 500 MRU.',
//         );
//       }
//       if (phoneNumber.trim().isEmpty) {
//         throw const ValidationFailure(message: 'Phone number is required.');
//       }

//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/wallet/withdrawal-request',
//         data: {
//           'amount_mru': amountMru,
//           'payment_method_id': paymentMethodId,
//           'phone_number': phoneNumber.trim(),
//           'notes': notes,
//           'idempotency_key': _uuid.v4(),
//         },
//       );

//       final data = resp.data!['data'] as Map<String, dynamic>;
//       return _rowToWithdrawal(data['withdrawal'] as Map<String, dynamic>);
//     },
//   );

//   Future<List<WithdrawalEntity>> getMyWithdrawals({int limit = 20}) =>
//       guardedCall(
//         operationName: 'getMyWithdrawals',
//         operation: () async {
//           final rows = await _supabase
//               .from('withdrawals')
//               .select()
//               .order('created_at', ascending: false)
//               .limit(limit);
//           return rows.map(_rowToWithdrawal).toList();
//         },
//       );

//   // ── Creator earnings ───────────────────────────────────────────────────────

//   Future<EarningsSummary> getEarningsSummary(String creatorId) => guardedCall(
//     operationName: 'getEarningsSummary',
//     operation: () async {
//       final resp = await _api.get<Map<String, dynamic>>(
//         '/v1/wallet/earnings-summary',
//       );
//       final data = resp.data!['data'] as Map<String, dynamic>;
//       return EarningsSummary(
//         totalEarnedMru: data['total_earned_mru'] as int? ?? 0,
//         pendingEarningsMru: data['pending_earnings_mru'] as int? ?? 0,
//         availableForWithdrawalMru:
//             data['available_for_withdrawal_mru'] as int? ?? 0,
//         totalSales: data['total_sales'] as int? ?? 0,
//         thisMonthMru: data['this_month_mru'] as int? ?? 0,
//         commissionRate: (data['commission_rate'] as num?)?.toDouble() ?? 0.15,
//       );
//     },
//   );

//   // ── Mappers ────────────────────────────────────────────────────────────────

//   WalletEntity _rowToWallet(Map<String, dynamic> r) => WalletEntity(
//     id: r['id'] as String,
//     userId: r['user_id'] as String,
//     balanceMru: r['balance_mru'] as int? ?? 0,
//     isFrozen: r['is_frozen'] as bool? ?? false,
//     updatedAt: r['updated_at'] != null
//         ? DateTime.tryParse(r['updated_at'] as String)
//         : null,
//   );

//   WalletTransaction _rowToTransaction(Map<String, dynamic> r) =>
//       WalletTransaction(
//         id: r['id'] as String,
//         walletId: r['wallet_id'] as String,
//         type: TransactionType.fromString(r['type'] as String? ?? 'deposit'),
//         status: TransactionStatus.fromString(
//           r['status'] as String? ?? 'completed',
//         ),
//         amountMru: r['amount_mru'] as int,
//         balanceBefore: r['balance_before'] as int? ?? 0,
//         balanceAfter: r['balance_after'] as int? ?? 0,
//         description: r['description'] as String?,
//         referenceId: r['reference_id'] as String?,
//         idempotencyKey: r['idempotency_key'] as String?,
//         createdAt: DateTime.parse(r['created_at'] as String),
//       );

//   DepositEntity _rowToDeposit(Map<String, dynamic> r) => DepositEntity(
//     id: r['id'] as String,
//     walletId: r['wallet_id'] as String? ?? '',
//     userId: r['user_id'] as String? ?? '',
//     amountMru: r['amount_mru'] as int,
//     paymentMethod: r['payment_method'] as String? ?? '',
//     paymentReference: r['payment_reference'] as String?,
//     status: DepositStatus.fromString(r['status'] as String? ?? 'pending'),
//     rejectedReason: r['rejected_reason'] as String?,
//     submittedAt: DateTime.parse(r['created_at'] as String),
//     approvedAt: r['approved_at'] != null
//         ? DateTime.tryParse(r['approved_at'] as String)
//         : null,
//     rejectedAt: r['rejected_at'] != null
//         ? DateTime.tryParse(r['rejected_at'] as String)
//         : null,
//   );

//   WithdrawalEntity _rowToWithdrawal(Map<String, dynamic> r) => WithdrawalEntity(
//     id: r['id'] as String,
//     walletId: r['wallet_id'] as String? ?? '',
//     userId: r['user_id'] as String? ?? '',
//     amountMru: r['amount_mru'] as int,
//     payoutMethod: r['payout_method'] as String? ?? '',
//     payoutDetails: (r['payout_details'] as Map?)?.cast<String, dynamic>() ?? {},
//     status: TransactionStatus.fromString(r['status'] as String? ?? 'pending'),
//     rejectedReason: r['rejected_reason'] as String?,
//     submittedAt: DateTime.parse(r['created_at'] as String),
//     processedAt: r['processed_at'] != null
//         ? DateTime.tryParse(r['processed_at'] as String)
//         : null,
//   );

//   PaymentMethodEntity _rowToPaymentMethod(Map<String, dynamic> r) =>
//       PaymentMethodEntity(
//         id: r['id'] as String,
//         type: r['type'] as String? ?? 'other',
//         name: r['name'] as String,
//         logoUrl: r['logo_url'] as String?,
//         accountNumber: r['account_number'] as String?,
//         accountName: r['account_name'] as String?,
//         instructions: r['instructions'] as String?,
//         isActive: r['is_active'] as bool? ?? true,
//         supportsDeposit: r['supports_deposit'] as bool? ?? true,
//         supportsWithdrawal: r['supports_withdrawal'] as bool? ?? true,
//         minAmountMru: r['min_amount_mru'] as int?,
//         maxAmountMru: r['max_amount_mru'] as int?,
//         sortOrder: r['sort_order'] as int? ?? 0,
//       );
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../domain/wallet_entity.dart';

export '../domain/wallet_entity.dart';

const _uuid = Uuid();

/// All wallet read/write operations.
///
/// Reads  → Supabase direct (RLS-protected — users see only their own data)
/// Writes → Node.js API (service_role — owns business rules, idempotency, audit)
///
/// Security model:
/// - Client never calls apply_wallet_transaction() directly
/// - All balance mutations go through Node.js which validates, logs, and
///   uses FOR UPDATE row locks to prevent race conditions
class WalletRepository extends BaseRepository {
  WalletRepository._();
  static final WalletRepository _instance = WalletRepository._();
  static WalletRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  // ── Wallet ─────────────────────────────────────────────────────────────────

  Future<WalletEntity> getWallet(String userId) => guardedCall(
    operationName: 'getWallet',
    operation: () async {
      var raw = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (raw == null) {
        // Auto-create — DB trigger may have missed this user
        raw = await _supabase
            .from('wallets')
            .upsert({
              'user_id': userId,
              'balance_mru': 0,
            }, onConflict: 'user_id')
            .select()
            .single();
      }

      final row = Map<String, dynamic>.from(raw);
      if ((row['id'] as String? ?? '').isEmpty) {
        throw const NotFoundFailure(message: 'Wallet id missing.');
      }
      return _rowToWallet(row);
    },
  );

  Future<WalletEntity?> getWalletSafe(String userId) => softCall(
    operationName: 'getWalletSafe',
    operation: () async {
      Map<String, dynamic>? row = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .then((r) => r != null ? Map<String, dynamic>.from(r) : null);

      if (row == null) {
        try {
          final upserted = await _supabase
              .from('wallets')
              .upsert({
                'user_id': userId,
                'balance_mru': 0,
              }, onConflict: 'user_id')
              .select()
              .maybeSingle();
          if (upserted != null) {
            row = Map<String, dynamic>.from(upserted);
          }
        } catch (_) {}
      }

      if (row == null) throw Exception('nooooooooo');
      return _rowToWallet(row);
    },
  );

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<List<WalletTransaction>> getTransactions(
    String walletId, {
    int limit = 30,
    int offset = 0,
    TransactionType? typeFilter,
  }) => guardedCall(
    operationName: 'getTransactions',
    operation: () async {
      var q = _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId);

      if (typeFilter != null) {
        q = q.eq('type', typeFilter.name);
      }

      final rows = await q
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows.map(_rowToTransaction).toList();
    },
  );

  // ── Payment methods (admin-managed, fetched dynamically) ──────────────────

  Future<List<PaymentMethodEntity>> getPaymentMethods({
    bool forDeposit = true,
  }) => guardedCall(
    operationName: 'getPaymentMethods',
    operation: () async {
      var q = _supabase
          .from('payment_methods_config')
          .select()
          .eq('is_active', true);

      if (forDeposit) {
        q = q.eq('supports_deposit', true);
      } else {
        q = q.eq('supports_withdrawal', true);
      }

      final rows = await q.order('sort_order');
      return rows.map(_rowToPaymentMethod).toList();
    },
  );

  // ── Deposits ───────────────────────────────────────────────────────────────

  /// Submit a deposit request.
  /// Node.js validates and creates the pending deposit row.
  /// Admin approves/rejects via the admin dashboard.
  Future<DepositEntity> requestDeposit({
    required int amountMru,
    required String paymentMethodId,
    required String phoneNumber,
    required String paymentReference,
    String? notes,
  }) => guardedCall(
    operationName: 'requestDeposit',
    operation: () async {
      // Client-side validation before touching network
      if (amountMru < 100) {
        throw const ValidationFailure(
          message: 'Minimum deposit amount is 100 MRU.',
        );
      }
      if (amountMru > 1_000_000) {
        throw const ValidationFailure(
          message: 'Maximum deposit amount is 1,000,000 MRU.',
        );
      }
      if (phoneNumber.trim().isEmpty) {
        throw const ValidationFailure(message: 'Phone number is required.');
      }
      if (paymentReference.trim().isEmpty) {
        throw const ValidationFailure(
          message: 'Payment reference is required.',
        );
      }

      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/wallet/deposit-request',
        data: {
          'amount_mru': amountMru,
          'payment_method_id': paymentMethodId,
          'phone_number': phoneNumber.trim(),
          'payment_reference': paymentReference.trim(),
          'notes': notes,
          'idempotency_key': _uuid.v4(),
        },
      );

      final data = resp.data!['data'] as Map<String, dynamic>;
      return _rowToDeposit(data['deposit'] as Map<String, dynamic>);
    },
  );

  Future<List<DepositEntity>> getMyDeposits({int limit = 20}) => guardedCall(
    operationName: 'getMyDeposits',
    operation: () async {
      final rows = await _supabase
          .from('deposits')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(_rowToDeposit).toList();
    },
  );

  // ── Withdrawals ────────────────────────────────────────────────────────────

  Future<WithdrawalEntity> requestWithdrawal({
    required int amountMru,
    required String paymentMethodId,
    required String phoneNumber,
    String? notes,
  }) => guardedCall(
    operationName: 'requestWithdrawal',
    operation: () async {
      if (amountMru < 500) {
        throw const ValidationFailure(
          message: 'Minimum withdrawal amount is 500 MRU.',
        );
      }
      if (phoneNumber.trim().isEmpty) {
        throw const ValidationFailure(message: 'Phone number is required.');
      }

      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/wallet/withdrawal-request',
        data: {
          'amount_mru': amountMru,
          'payment_method_id': paymentMethodId,
          'phone_number': phoneNumber.trim(),
          'notes': notes,
          'idempotency_key': _uuid.v4(),
        },
      );

      final data = resp.data!['data'] as Map<String, dynamic>;
      return _rowToWithdrawal(data['withdrawal'] as Map<String, dynamic>);
    },
  );

  Future<List<WithdrawalEntity>> getMyWithdrawals({int limit = 20}) =>
      guardedCall(
        operationName: 'getMyWithdrawals',
        operation: () async {
          final rows = await _supabase
              .from('withdrawals')
              .select()
              .order('created_at', ascending: false)
              .limit(limit);
          return rows.map(_rowToWithdrawal).toList();
        },
      );

  // ── Creator earnings ───────────────────────────────────────────────────────

  Future<EarningsSummary> getEarningsSummary(String creatorId) => guardedCall(
    operationName: 'getEarningsSummary',
    operation: () async {
      final resp = await _api.get<Map<String, dynamic>>(
        '/v1/wallet/earnings-summary',
      );
      final data = resp.data!['data'] as Map<String, dynamic>;
      return EarningsSummary(
        totalEarnedMru: data['total_earned_mru'] as int? ?? 0,
        pendingEarningsMru: data['pending_earnings_mru'] as int? ?? 0,
        availableForWithdrawalMru:
            data['available_for_withdrawal_mru'] as int? ?? 0,
        totalSales: data['total_sales'] as int? ?? 0,
        thisMonthMru: data['this_month_mru'] as int? ?? 0,
        commissionRate: (data['commission_rate'] as num?)?.toDouble() ?? 0.15,
      );
    },
  );

  // ── Mappers ────────────────────────────────────────────────────────────────

  WalletEntity _rowToWallet(Map<String, dynamic> r) => WalletEntity(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    balanceMru: r['balance_mru'] as int? ?? 0,
    isFrozen: r['is_frozen'] as bool? ?? false,
    updatedAt: r['updated_at'] != null
        ? DateTime.tryParse(r['updated_at'] as String)
        : null,
  );

  WalletTransaction _rowToTransaction(Map<String, dynamic> r) =>
      WalletTransaction(
        id: r['id'] as String,
        walletId: r['wallet_id'] as String,
        type: TransactionType.fromString(r['type'] as String? ?? 'deposit'),
        status: TransactionStatus.fromString(
          r['status'] as String? ?? 'completed',
        ),
        amountMru: r['amount_mru'] as int,
        balanceBefore: r['balance_before'] as int? ?? 0,
        balanceAfter: r['balance_after'] as int? ?? 0,
        description: r['description'] as String?,
        referenceId: r['reference_id'] as String?,
        idempotencyKey: r['idempotency_key'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );

  DepositEntity _rowToDeposit(Map<String, dynamic> r) => DepositEntity(
    id: r['id'] as String,
    walletId: r['wallet_id'] as String? ?? '',
    userId: r['user_id'] as String? ?? '',
    amountMru: r['amount_mru'] as int,
    paymentMethod: r['payment_method'] as String? ?? '',
    paymentReference: r['payment_reference'] as String?,
    status: DepositStatus.fromString(r['status'] as String? ?? 'pending'),
    rejectedReason: r['rejected_reason'] as String?,
    submittedAt: DateTime.parse(r['created_at'] as String),
    approvedAt: r['approved_at'] != null
        ? DateTime.tryParse(r['approved_at'] as String)
        : null,
    rejectedAt: r['rejected_at'] != null
        ? DateTime.tryParse(r['rejected_at'] as String)
        : null,
  );

  WithdrawalEntity _rowToWithdrawal(Map<String, dynamic> r) => WithdrawalEntity(
    id: r['id'] as String,
    walletId: r['wallet_id'] as String? ?? '',
    userId: r['user_id'] as String? ?? '',
    amountMru: r['amount_mru'] as int,
    payoutMethod: r['payout_method'] as String? ?? '',
    payoutDetails: (r['payout_details'] as Map?)?.cast<String, dynamic>() ?? {},
    status: TransactionStatus.fromString(r['status'] as String? ?? 'pending'),
    rejectedReason: r['rejected_reason'] as String?,
    submittedAt: DateTime.parse(r['created_at'] as String),
    processedAt: r['processed_at'] != null
        ? DateTime.tryParse(r['processed_at'] as String)
        : null,
  );

  PaymentMethodEntity _rowToPaymentMethod(Map<String, dynamic> r) =>
      PaymentMethodEntity(
        id: r['id'] as String,
        type: r['type'] as String? ?? 'other',
        name: r['name'] as String,
        logoUrl: r['logo_url'] as String?,
        accountNumber: r['account_number'] as String?,
        accountName: r['account_name'] as String?,
        instructions: r['instructions'] as String?,
        isActive: r['is_active'] as bool? ?? true,
        supportsDeposit: r['supports_deposit'] as bool? ?? true,
        supportsWithdrawal: r['supports_withdrawal'] as bool? ?? true,
        minAmountMru: r['min_amount_mru'] as int?,
        maxAmountMru: r['max_amount_mru'] as int?,
        sortOrder: r['sort_order'] as int? ?? 0,
      );
}
