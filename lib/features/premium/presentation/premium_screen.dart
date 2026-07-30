// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // import '../../../../core/services/subscription_service.dart';

// // // // // class PremiumScreen extends StatefulWidget {
// // // // //   const PremiumScreen({super.key});

// // // // //   @override
// // // // //   State<PremiumScreen> createState() => _PremiumScreenState();
// // // // // }

// // // // // class _PremiumScreenState extends State<PremiumScreen> {
// // // // //   bool _loading = false;
// // // // //   String? _activeSubscriptionId;

// // // // //   static const Color _gold = Color(0xFFF5A623);
// // // // //   static const Color _platinum = Color(0xFF7B68EE);

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _loadStatus();
// // // // //   }

// // // // //   Future<void> _loadStatus() async {
// // // // //     final uid = context.read<AuthProvider>().currentUser?.id;
// // // // //     if (uid == null) return;
// // // // //     final sub = await SubscriptionService.instance.getActiveSubscription(uid);
// // // // //     if (mounted) setState(() => _activeSubscriptionId = sub?['id'] as String?);
// // // // //   }

// // // // //   Future<void> _purchase(_PremiumPlan plan) async {
// // // // //     if (_loading) return;
// // // // //     setState(() => _loading = true);
// // // // //     try {
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         const SnackBar(content: Text('In-app purchase coming soon!')),
// // // // //       );
// // // // //     } finally {
// // // // //       if (mounted) setState(() => _loading = false);
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final user = context.watch<AuthProvider>().currentUser;
// // // // //     final isPremium = user?.isPremiumActive ?? false;
// // // // //     final theme = context.theme;

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: Row(
// // // // //           mainAxisSize: MainAxisSize.min,
// // // // //           children: [
// // // // //             Text(
// // // // //               'Premium',
// // // // //               style: theme.textTheme.titleLarge?.copyWith(
// // // // //                 fontWeight: FontWeight.w800,
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(width: 6),
// // // // //             Container(
// // // // //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // // // //               decoration: BoxDecoration(
// // // // //                 gradient: const LinearGradient(
// // // // //                   colors: [_gold, Color(0xFFFF8C00)],
// // // // //                 ),
// // // // //                 borderRadius: BorderRadius.circular(12),
// // // // //               ),
// // // // //               child: const Text(
// // // // //                 '✦',
// // // // //                 style: TextStyle(color: Colors.white, fontSize: 14),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //         centerTitle: true,
// // // // //       ),
// // // // //       body: SingleChildScrollView(
// // // // //         padding: const EdgeInsets.all(20),
// // // // //         child: Column(
// // // // //           crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //           children: [
// // // // //             if (isPremium) _ActiveBanner(user: user!) else _HeroBanner(),
// // // // //             const SizedBox(height: 24),
// // // // //             ...const [
// // // // //               _PremiumPlan(
// // // // //                 id: 'premium_monthly',
// // // // //                 label: 'Monthly',
// // // // //                 tier: 'premium',
// // // // //                 price: '9.99 MRU',
// // // // //                 period: 'month',
// // // // //                 isPopular: false,
// // // // //               ),
// // // // //               _PremiumPlan(
// // // // //                 id: 'premium_yearly',
// // // // //                 label: 'Yearly',
// // // // //                 tier: 'premium',
// // // // //                 price: '79.99 MRU',
// // // // //                 period: 'year',
// // // // //                 isPopular: true,
// // // // //                 savings: 'Save 33%',
// // // // //               ),
// // // // //               _PremiumPlan(
// // // // //                 id: 'premium_plus_monthly',
// // // // //                 label: 'Premium Plus',
// // // // //                 tier: 'premium_plus',
// // // // //                 price: '19.99 MRU',
// // // // //                 period: 'month',
// // // // //                 isPopular: false,
// // // // //               ),
// // // // //             ].map(
// // // // //               (plan) => _PlanCard(
// // // // //                 plan: plan,
// // // // //                 isActive: isPremium && user?.premiumTier == plan.tier,
// // // // //                 onTap: () => _purchase(plan),
// // // // //                 loading: _loading,
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(height: 24),
// // // // //             _FeatureTable(),
// // // // //             const SizedBox(height: 20),
// // // // //             Text(
// // // // //               'Subscriptions auto-renew unless cancelled 24h before renewal. '
// // // // //               'Manage in your account settings.',
// // // // //               style: theme.textTheme.bodySmall?.copyWith(
// // // // //                 color: theme.colorScheme.onSurfaceVariant,
// // // // //               ),
// // // // //               textAlign: TextAlign.center,
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _HeroBanner extends StatelessWidget {
// // // // //   const _HeroBanner();
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.all(24),
// // // // //       decoration: BoxDecoration(
// // // // //         gradient: const LinearGradient(
// // // // //           colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
// // // // //           begin: Alignment.topLeft,
// // // // //           end: Alignment.bottomRight,
// // // // //         ),
// // // // //         borderRadius: BorderRadius.circular(20),
// // // // //       ),
// // // // //       child: Column(
// // // // //         children: [
// // // // //           const Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
// // // // //           const SizedBox(height: 12),
// // // // //           const Text(
// // // // //             'Unlock Premium',
// // // // //             style: TextStyle(
// // // // //               color: Colors.white,
// // // // //               fontSize: 24,
// // // // //               fontWeight: FontWeight.w900,
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(height: 8),
// // // // //           Text(
// // // // //             'Get hidden spectator mode, anonymous chat, proof replays, premium badge, and more.',
// // // // //             style: TextStyle(
// // // // //               color: Colors.white.withOpacity(0.9),
// // // // //               fontSize: 14,
// // // // //               height: 1.4,
// // // // //             ),
// // // // //             textAlign: TextAlign.center,
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _ActiveBanner extends StatelessWidget {
// // // // //   const _ActiveBanner({required this.user});
// // // // //   final dynamic user;
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final exp = user.premiumExpiresAt;
// // // // //     final label = exp != null
// // // // //         ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
// // // // //         : 'Active — no expiry';
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.all(20),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.green.shade50,
// // // // //         borderRadius: BorderRadius.circular(16),
// // // // //         border: Border.all(color: Colors.green.shade300),
// // // // //       ),
// // // // //       child: Row(
// // // // //         children: [
// // // // //           const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
// // // // //           const SizedBox(width: 12),
// // // // //           Column(
// // // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // // //             children: [
// // // // //               Text(
// // // // //                 'Premium Active ✦',
// // // // //                 style: TextStyle(
// // // // //                   fontWeight: FontWeight.w700,
// // // // //                   color: Colors.green.shade800,
// // // // //                   fontSize: 16,
// // // // //                 ),
// // // // //               ),
// // // // //               Text(
// // // // //                 label,
// // // // //                 style: TextStyle(color: Colors.green.shade600, fontSize: 13),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _PremiumPlan {
// // // // //   const _PremiumPlan({
// // // // //     required this.id,
// // // // //     required this.label,
// // // // //     required this.tier,
// // // // //     required this.price,
// // // // //     required this.period,
// // // // //     required this.isPopular,
// // // // //     this.savings,
// // // // //   });
// // // // //   final String id, label, tier, price, period;
// // // // //   final bool isPopular;
// // // // //   final String? savings;
// // // // // }

// // // // // class _PlanCard extends StatelessWidget {
// // // // //   const _PlanCard({
// // // // //     required this.plan,
// // // // //     required this.isActive,
// // // // //     required this.onTap,
// // // // //     required this.loading,
// // // // //   });
// // // // //   final _PremiumPlan plan;
// // // // //   final bool isActive;
// // // // //   final VoidCallback onTap;
// // // // //   final bool loading;

// // // // //   Color get _accent => plan.tier == 'premium_plus'
// // // // //       ? const Color(0xFF7B68EE)
// // // // //       : const Color(0xFFF5A623);

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.only(bottom: 12),
// // // // //       child: Stack(
// // // // //         children: [
// // // // //           Container(
// // // // //             decoration: BoxDecoration(
// // // // //               color: isActive
// // // // //                   ? _accent.withOpacity(0.08)
// // // // //                   : theme.colorScheme.surface,
// // // // //               borderRadius: BorderRadius.circular(16),
// // // // //               border: Border.all(
// // // // //                 color: isActive ? _accent : theme.colorScheme.outlineVariant,
// // // // //                 width: isActive ? 2 : 1,
// // // // //               ),
// // // // //             ),
// // // // //             child: ListTile(
// // // // //               contentPadding: const EdgeInsets.symmetric(
// // // // //                 horizontal: 16,
// // // // //                 vertical: 8,
// // // // //               ),
// // // // //               title: Text(
// // // // //                 plan.label,
// // // // //                 style: theme.textTheme.titleMedium?.copyWith(
// // // // //                   fontWeight: FontWeight.w700,
// // // // //                 ),
// // // // //               ),
// // // // //               subtitle: Text(
// // // // //                 '${plan.price} / ${plan.period}',
// // // // //                 style: theme.textTheme.bodyMedium,
// // // // //               ),
// // // // //               trailing: isActive
// // // // //                   ? Chip(
// // // // //                       label: const Text('Active'),
// // // // //                       backgroundColor: Colors.green.shade100,
// // // // //                       labelStyle: TextStyle(
// // // // //                         color: Colors.green.shade700,
// // // // //                         fontWeight: FontWeight.w700,
// // // // //                       ),
// // // // //                     )
// // // // //                   : FilledButton(
// // // // //                       style: FilledButton.styleFrom(backgroundColor: _accent),
// // // // //                       onPressed: loading ? null : onTap,
// // // // //                       child: const Text('Get'),
// // // // //                     ),
// // // // //             ),
// // // // //           ),
// // // // //           if (plan.isPopular)
// // // // //             Positioned(
// // // // //               top: 0,
// // // // //               right: 16,
// // // // //               child: Container(
// // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // //                 decoration: BoxDecoration(
// // // // //                   color: _accent,
// // // // //                   borderRadius: const BorderRadius.vertical(
// // // // //                     bottom: Radius.circular(8),
// // // // //                   ),
// // // // //                 ),
// // // // //                 child: Text(
// // // // //                   plan.savings ?? 'Popular',
// // // // //                   style: const TextStyle(
// // // // //                     color: Colors.white,
// // // // //                     fontSize: 11,
// // // // //                     fontWeight: FontWeight.w700,
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _FeatureTable extends StatelessWidget {
// // // // //   const _FeatureTable();

// // // // //   static const _rows = [
// // // // //     ('Hidden spectator mode', true, true),
// // // // //     ('Anonymous chat', true, true),
// // // // //     ('3× proof replays', true, true),
// // // // //     ('Premium badge ✦', true, true),
// // // // //     ('30-day proof history', true, true),
// // // // //     ('Priority support', false, true),
// // // // //     ('Exclusive packs', false, true),
// // // // //   ];

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //       children: [
// // // // //         Text(
// // // // //           'What you get',
// // // // //           style: theme.textTheme.titleMedium?.copyWith(
// // // // //             fontWeight: FontWeight.w700,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 12),
// // // // //         Table(
// // // // //           columnWidths: const {
// // // // //             0: FlexColumnWidth(),
// // // // //             1: FixedColumnWidth(64),
// // // // //             2: FixedColumnWidth(84),
// // // // //           },
// // // // //           children: [
// // // // //             TableRow(
// // // // //               decoration: BoxDecoration(
// // // // //                 color: theme.colorScheme.surfaceContainerHighest,
// // // // //                 borderRadius: BorderRadius.circular(8),
// // // // //               ),
// // // // //               children: [
// // // // //                 const Padding(
// // // // //                   padding: EdgeInsets.all(10),
// // // // //                   child: Text(
// // // // //                     'Feature',
// // // // //                     style: TextStyle(fontWeight: FontWeight.w700),
// // // // //                   ),
// // // // //                 ),
// // // // //                 const Padding(
// // // // //                   padding: EdgeInsets.all(10),
// // // // //                   child: Text(
// // // // //                     'Premium',
// // // // //                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// // // // //                     textAlign: TextAlign.center,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const Padding(
// // // // //                   padding: EdgeInsets.all(10),
// // // // //                   child: Text(
// // // // //                     'Plus',
// // // // //                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// // // // //                     textAlign: TextAlign.center,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //             ..._rows.map(
// // // // //               (r) => TableRow(
// // // // //                 children: [
// // // // //                   Padding(
// // // // //                     padding: const EdgeInsets.symmetric(
// // // // //                       horizontal: 10,
// // // // //                       vertical: 8,
// // // // //                     ),
// // // // //                     child: Text(r.$1, style: theme.textTheme.bodySmall),
// // // // //                   ),
// // // // //                   Center(
// // // // //                     child: Padding(
// // // // //                       padding: const EdgeInsets.symmetric(vertical: 8),
// // // // //                       child: r.$2
// // // // //                           ? const Icon(
// // // // //                               Icons.check_circle_rounded,
// // // // //                               color: Color(0xFFF5A623),
// // // // //                               size: 18,
// // // // //                             )
// // // // //                           : const Icon(
// // // // //                               Icons.remove,
// // // // //                               size: 14,
// // // // //                               color: Colors.grey,
// // // // //                             ),
// // // // //                     ),
// // // // //                   ),
// // // // //                   Center(
// // // // //                     child: Padding(
// // // // //                       padding: const EdgeInsets.symmetric(vertical: 8),
// // // // //                       child: r.$3
// // // // //                           ? const Icon(
// // // // //                               Icons.check_circle_rounded,
// // // // //                               color: Color(0xFF7B68EE),
// // // // //                               size: 18,
// // // // //                             )
// // // // //                           : const Icon(
// // // // //                               Icons.remove,
// // // // //                               size: 14,
// // // // //                               color: Colors.grey,
// // // // //                             ),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/providers/auth_provider.dart';
// // // // import '../../../../core/services/subscription_service.dart';

// // // // class PremiumScreen extends StatefulWidget {
// // // //   const PremiumScreen({super.key});

// // // //   @override
// // // //   State<PremiumScreen> createState() => _PremiumScreenState();
// // // // }

// // // // class _PremiumScreenState extends State<PremiumScreen> {
// // // //   bool _loading = false;
// // // //   String? _activeSubscriptionId;

// // // //   static const Color _gold = Color(0xFFF5A623);
// // // //   static const Color _platinum = Color(0xFF7B68EE);

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _loadStatus();
// // // //   }

// // // //   Future<void> _loadStatus() async {
// // // //     final uid = context.read<AuthProvider>().currentUser?.id;
// // // //     if (uid == null) return;
// // // //     final sub = await SubscriptionService.instance.getActiveSubscription(uid);
// // // //     if (mounted) setState(() => _activeSubscriptionId = sub?['id'] as String?);
// // // //   }

// // // //   Future<void> _purchase(_PremiumPlan plan) async {
// // // //     if (_loading) return;
// // // //     setState(() => _loading = true);
// // // //     try {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('In-app purchase coming soon!')),
// // // //       );
// // // //     } finally {
// // // //       if (mounted) setState(() => _loading = false);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final user = context.watch<AuthProvider>().currentUser;
// // // //     final isPremium = user?.isPremiumActive ?? false;
// // // //     final theme = context.theme;

// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Row(
// // // //           mainAxisSize: MainAxisSize.min,
// // // //           children: [
// // // //             Text(
// // // //               'Premium',
// // // //               style: theme.textTheme.titleLarge?.copyWith(
// // // //                 fontWeight: FontWeight.w800,
// // // //               ),
// // // //             ),
// // // //             const SizedBox(width: 6),
// // // //             Container(
// // // //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // // //               decoration: BoxDecoration(
// // // //                 gradient: const LinearGradient(
// // // //                   colors: [_gold, Color(0xFFFF8C00)],
// // // //                 ),
// // // //                 borderRadius: BorderRadius.circular(12),
// // // //               ),
// // // //               child: const Text(
// // // //                 '✦',
// // // //                 style: TextStyle(color: Colors.white, fontSize: 14),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         centerTitle: true,
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(20),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //           children: [
// // // //             if (isPremium) _ActiveBanner(user: user!) else _HeroBanner(),
// // // //             const SizedBox(height: 24),
// // // //             ...const [
// // // //               _PremiumPlan(
// // // //                 id: 'premium_monthly',
// // // //                 label: 'Monthly',
// // // //                 tier: 'premium',
// // // //                 price: '9.99 MRU',
// // // //                 period: 'month',
// // // //                 isPopular: false,
// // // //               ),
// // // //               _PremiumPlan(
// // // //                 id: 'premium_yearly',
// // // //                 label: 'Yearly',
// // // //                 tier: 'premium',
// // // //                 price: '79.99 MRU',
// // // //                 period: 'year',
// // // //                 isPopular: true,
// // // //                 savings: 'Save 33%',
// // // //               ),
// // // //               _PremiumPlan(
// // // //                 id: 'premium_plus_monthly',
// // // //                 label: 'Premium Plus',
// // // //                 tier: 'premium_plus',
// // // //                 price: '19.99 MRU',
// // // //                 period: 'month',
// // // //                 isPopular: false,
// // // //               ),
// // // //             ].map(
// // // //               (plan) => _PlanCard(
// // // //                 plan: plan,
// // // //                 isActive: isPremium && user?.premiumTier == plan.tier,
// // // //                 onTap: () => _purchase(plan),
// // // //                 loading: _loading,
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 24),
// // // //             _FeatureTable(),
// // // //             const SizedBox(height: 20),
// // // //             Text(
// // // //               'Subscriptions auto-renew unless cancelled 24h before renewal. '
// // // //               'Manage in your account settings.',
// // // //               style: theme.textTheme.bodySmall?.copyWith(
// // // //                 color: theme.colorScheme.onSurfaceVariant,
// // // //               ),
// // // //               textAlign: TextAlign.center,
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _HeroBanner extends StatelessWidget {
// // // //   const _HeroBanner();
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       padding: const EdgeInsets.all(24),
// // // //       decoration: BoxDecoration(
// // // //         gradient: const LinearGradient(
// // // //           colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           const Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
// // // //           const SizedBox(height: 12),
// // // //           const Text(
// // // //             'Unlock Premium',
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontSize: 24,
// // // //               fontWeight: FontWeight.w900,
// // // //             ),
// // // //           ),
// // // //           const SizedBox(height: 8),
// // // //           Text(
// // // //             'Get hidden spectator mode, anonymous chat, proof replays, premium badge, and more.',
// // // //             style: TextStyle(
// // // //               color: Colors.white.withOpacity(0.9),
// // // //               fontSize: 14,
// // // //               height: 1.4,
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _ActiveBanner extends StatelessWidget {
// // // //   const _ActiveBanner({required this.user});
// // // //   final dynamic user;
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final exp = user.premiumExpiresAt;
// // // //     final label = exp != null
// // // //         ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
// // // //         : 'Active — no expiry';
// // // //     return Container(
// // // //       padding: const EdgeInsets.all(20),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.green.shade50,
// // // //         borderRadius: BorderRadius.circular(16),
// // // //         border: Border.all(color: Colors.green.shade300),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
// // // //           const SizedBox(width: 12),
// // // //           Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Text(
// // // //                 'Premium Active ✦',
// // // //                 style: TextStyle(
// // // //                   fontWeight: FontWeight.w700,
// // // //                   color: Colors.green.shade800,
// // // //                   fontSize: 16,
// // // //                 ),
// // // //               ),
// // // //               Text(
// // // //                 label,
// // // //                 style: TextStyle(color: Colors.green.shade600, fontSize: 13),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _PremiumPlan {
// // // //   const _PremiumPlan({
// // // //     required this.id,
// // // //     required this.label,
// // // //     required this.tier,
// // // //     required this.price,
// // // //     required this.period,
// // // //     required this.isPopular,
// // // //     this.savings,
// // // //   });
// // // //   final String id, label, tier, price, period;
// // // //   final bool isPopular;
// // // //   final String? savings;
// // // // }

// // // // class _PlanCard extends StatelessWidget {
// // // //   const _PlanCard({
// // // //     required this.plan,
// // // //     required this.isActive,
// // // //     required this.onTap,
// // // //     required this.loading,
// // // //   });
// // // //   final _PremiumPlan plan;
// // // //   final bool isActive;
// // // //   final VoidCallback onTap;
// // // //   final bool loading;

// // // //   Color get _accent => plan.tier == 'premium_plus'
// // // //       ? const Color(0xFF7B68EE)
// // // //       : const Color(0xFFF5A623);

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 12),
// // // //       child: Stack(
// // // //         children: [
// // // //           Container(
// // // //             decoration: BoxDecoration(
// // // //               color: isActive
// // // //                   ? _accent.withOpacity(0.08)
// // // //                   : theme.colorScheme.surface,
// // // //               borderRadius: BorderRadius.circular(16),
// // // //               border: Border.all(
// // // //                 color: isActive ? _accent : theme.colorScheme.outlineVariant,
// // // //                 width: isActive ? 2 : 1,
// // // //               ),
// // // //             ),
// // // //             child: ListTile(
// // // //               contentPadding: const EdgeInsets.symmetric(
// // // //                 horizontal: 16,
// // // //                 vertical: 8,
// // // //               ),
// // // //               title: Text(
// // // //                 plan.label,
// // // //                 style: theme.textTheme.titleMedium?.copyWith(
// // // //                   fontWeight: FontWeight.w700,
// // // //                 ),
// // // //               ),
// // // //               subtitle: Text(
// // // //                 '${plan.price} / ${plan.period}',
// // // //                 style: theme.textTheme.bodyMedium,
// // // //               ),
// // // //               trailing: SizedBox(
// // // //                 width: 80,
// // // //                 child: isActive
// // // //                     ? Chip(
// // // //                         label: const Text('Active'),
// // // //                         backgroundColor: Colors.green.shade100,
// // // //                         labelStyle: TextStyle(
// // // //                           color: Colors.green.shade700,
// // // //                           fontWeight: FontWeight.w700,
// // // //                         ),
// // // //                       )
// // // //                     : FilledButton(
// // // //                         style: FilledButton.styleFrom(
// // // //                           backgroundColor: _accent,
// // // //                           padding: EdgeInsets.zero,
// // // //                         ),
// // // //                         onPressed: loading ? null : onTap,
// // // //                         child: const Text('Get'),
// // // //                       ),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //           if (plan.isPopular)
// // // //             Positioned(
// // // //               top: 0,
// // // //               right: 16,
// // // //               child: Container(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // //                 decoration: BoxDecoration(
// // // //                   color: _accent,
// // // //                   borderRadius: const BorderRadius.vertical(
// // // //                     bottom: Radius.circular(8),
// // // //                   ),
// // // //                 ),
// // // //                 child: Text(
// // // //                   plan.savings ?? 'Popular',
// // // //                   style: const TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: 11,
// // // //                     fontWeight: FontWeight.w700,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _FeatureTable extends StatelessWidget {
// // // //   const _FeatureTable();

// // // //   static const _rows = [
// // // //     ('Hidden spectator mode', true, true),
// // // //     ('Anonymous chat', true, true),
// // // //     ('3× proof replays', true, true),
// // // //     ('Premium badge ✦', true, true),
// // // //     ('30-day proof history', true, true),
// // // //     ('Priority support', false, true),
// // // //     ('Exclusive packs', false, true),
// // // //   ];

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //       children: [
// // // //         Text(
// // // //           'What you get',
// // // //           style: theme.textTheme.titleMedium?.copyWith(
// // // //             fontWeight: FontWeight.w700,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 12),
// // // //         Table(
// // // //           columnWidths: const {
// // // //             0: FlexColumnWidth(),
// // // //             1: FixedColumnWidth(64),
// // // //             2: FixedColumnWidth(84),
// // // //           },
// // // //           children: [
// // // //             TableRow(
// // // //               decoration: BoxDecoration(
// // // //                 color: theme.colorScheme.surfaceContainerHighest,
// // // //                 borderRadius: BorderRadius.circular(8),
// // // //               ),
// // // //               children: [
// // // //                 const Padding(
// // // //                   padding: EdgeInsets.all(10),
// // // //                   child: Text(
// // // //                     'Feature',
// // // //                     style: TextStyle(fontWeight: FontWeight.w700),
// // // //                   ),
// // // //                 ),
// // // //                 const Padding(
// // // //                   padding: EdgeInsets.all(10),
// // // //                   child: Text(
// // // //                     'Premium',
// // // //                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// // // //                     textAlign: TextAlign.center,
// // // //                   ),
// // // //                 ),
// // // //                 const Padding(
// // // //                   padding: EdgeInsets.all(10),
// // // //                   child: Text(
// // // //                     'Plus',
// // // //                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// // // //                     textAlign: TextAlign.center,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             ..._rows.map(
// // // //               (r) => TableRow(
// // // //                 children: [
// // // //                   Padding(
// // // //                     padding: const EdgeInsets.symmetric(
// // // //                       horizontal: 10,
// // // //                       vertical: 8,
// // // //                     ),
// // // //                     child: Text(r.$1, style: theme.textTheme.bodySmall),
// // // //                   ),
// // // //                   Center(
// // // //                     child: Padding(
// // // //                       padding: const EdgeInsets.symmetric(vertical: 8),
// // // //                       child: r.$2
// // // //                           ? const Icon(
// // // //                               Icons.check_circle_rounded,
// // // //                               color: Color(0xFFF5A623),
// // // //                               size: 18,
// // // //                             )
// // // //                           : const Icon(
// // // //                               Icons.remove,
// // // //                               size: 14,
// // // //                               color: Colors.grey,
// // // //                             ),
// // // //                     ),
// // // //                   ),
// // // //                   Center(
// // // //                     child: Padding(
// // // //                       padding: const EdgeInsets.symmetric(vertical: 8),
// // // //                       child: r.$3
// // // //                           ? const Icon(
// // // //                               Icons.check_circle_rounded,
// // // //                               color: Color(0xFF7B68EE),
// // // //                               size: 18,
// // // //                             )
// // // //                           : const Icon(
// // // //                               Icons.remove,
// // // //                               size: 14,
// // // //                               color: Colors.grey,
// // // //                             ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/network/api_client.dart';
// // // import '../../../../core/providers/auth_provider.dart';
// // // import '../../../../core/services/subscription_service.dart';

// // // const _planPrices = {'monthly': 999, 'yearly': 7999, 'plus_monthly': 1999};

// // // const _planLabels = {
// // //   'monthly': 'Premium Monthly',
// // //   'yearly': 'Premium Yearly',
// // //   'plus_monthly': 'Premium Plus Monthly',
// // // };

// // // class PremiumScreen extends StatefulWidget {
// // //   const PremiumScreen({super.key});

// // //   @override
// // //   State<PremiumScreen> createState() => _PremiumScreenState();
// // // }

// // // class _PremiumScreenState extends State<PremiumScreen> {
// // //   bool _loading = false;
// // //   String? _selectedPlanId;

// // //   static const Color _gold = Color(0xFFF5A623);
// // //   static const Color _platinum = Color(0xFF7B68EE);

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadStatus();
// // //   }

// // //   Future<void> _loadStatus() async {
// // //     final uid = context.read<AuthProvider>().currentUser?.id;
// // //     if (uid == null) return;
// // //     await SubscriptionService.instance.getActiveSubscription(uid);
// // //     if (mounted) setState(() {});
// // //   }

// // //   Future<void> _purchase(_PremiumPlan plan) async {
// // //     if (_loading) return;
// // //     final user = context.read<AuthProvider>().currentUser;
// // //     if (user == null) return;

// // //     final priceMru = _planPrices[plan.id] ?? 0;

// // //     // Confirm with user before deducting
// // //     final confirmed = await showDialog<bool>(
// // //       context: context,
// // //       builder: (dCtx) => AlertDialog(
// // //         title: Text('Purchase ${_planLabels[plan.id] ?? plan.label}'),
// // //         content: Text(
// // //           'This will deduct $priceMru MRU from your wallet balance.\n\n'
// // //           'Plan: ${plan.label} — ${plan.price}/${plan.period}',
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.of(dCtx).pop(false),
// // //             child: const Text('Cancel'),
// // //           ),
// // //           FilledButton(
// // //             onPressed: () => Navigator.of(dCtx).pop(true),
// // //             child: const Text('Confirm Purchase'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //     if (confirmed != true || !mounted) return;

// // //     setState(() {
// // //       _loading = true;
// // //       _selectedPlanId = plan.id;
// // //     });
// // //     try {
// // //       final api = context.read<ApiClient>();
// // //       await api.post('/v1/wallet/subscribe', data: {'planId': plan.id});
// // //       if (!mounted) return;
// // //       // Reload user profile to pick up new premium status
// // //       await context.read<AuthProvider>().refreshCurrentUser();
// // //       await _loadStatus();
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text('🎉 ${_planLabels[plan.id]} activated!'),
// // //             backgroundColor: Colors.green.shade700,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       final raw = e.toString();
// // //       final msg = raw.contains('insufficient_balance')
// // //           ? 'Not enough balance. Please top up your wallet first.'
// // //           : raw.contains('wallet_not_found')
// // //           ? 'Wallet not found. Please contact support.'
// // //           : raw.contains('wallet_frozen')
// // //           ? 'Your wallet is frozen. Please contact support.'
// // //           : raw.contains('invalid_plan')
// // //           ? 'Invalid plan selected.'
// // //           : 'Purchase failed: $raw';
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text(msg),
// // //           backgroundColor: Colors.red.shade700,
// // //           duration: const Duration(seconds: 6),
// // //         ),
// // //       );
// // //     } finally {
// // //       if (mounted)
// // //         setState(() {
// // //           _loading = false;
// // //           _selectedPlanId = null;
// // //         });
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final user = context.watch<AuthProvider>().currentUser;
// // //     final isPremium = user?.isPremiumActive ?? false;
// // //     final tier = user?.premiumTier;
// // //     final theme = context.theme;

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               'Premium',
// // //               style: TextStyle(fontWeight: FontWeight.w800),
// // //             ),
// // //             const SizedBox(width: 6),
// // //             Container(
// // //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // //               decoration: BoxDecoration(
// // //                 gradient: const LinearGradient(
// // //                   colors: [_gold, Color(0xFFFF8C00)],
// // //                 ),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: const Text(
// // //                 '✦',
// // //                 style: TextStyle(color: Colors.white, fontSize: 14),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         centerTitle: true,
// // //       ),
// // //       body: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(20),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.stretch,
// // //           children: [
// // //             if (isPremium)
// // //               _ActiveBanner(user: user!, tier: tier)
// // //             else
// // //               const _HeroBanner(),
// // //             const SizedBox(height: 24),
// // //             ...[
// // //               _PremiumPlan(
// // //                 id: 'monthly',
// // //                 label: 'Monthly',
// // //                 tier: 'premium',
// // //                 price: '9.99 MRU',
// // //                 period: 'month',
// // //                 isPopular: false,
// // //               ),
// // //               _PremiumPlan(
// // //                 id: 'yearly',
// // //                 label: 'Yearly',
// // //                 tier: 'premium',
// // //                 price: '79.99 MRU',
// // //                 period: 'year',
// // //                 isPopular: true,
// // //                 savings: 'Save 33%',
// // //               ),
// // //               _PremiumPlan(
// // //                 id: 'plus_monthly',
// // //                 label: 'Premium Plus',
// // //                 tier: 'premium_plus',
// // //                 price: '19.99 MRU',
// // //                 period: 'month',
// // //                 isPopular: false,
// // //               ),
// // //             ].map(
// // //               (plan) => _PlanCard(
// // //                 plan: plan,
// // //                 isActive: isPremium && tier == plan.tier,
// // //                 isLoading: _loading && _selectedPlanId == plan.id,
// // //                 onTap: () => _purchase(plan),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 24),
// // //             const _FeatureTable(),
// // //             const SizedBox(height: 20),
// // //             Text(
// // //               'Subscriptions auto-renew unless cancelled 24h before renewal.',
// // //               style: theme.textTheme.bodySmall?.copyWith(
// // //                 color: theme.colorScheme.onSurfaceVariant,
// // //               ),
// // //               textAlign: TextAlign.center,
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _HeroBanner extends StatelessWidget {
// // //   const _HeroBanner();
// // //   @override
// // //   Widget build(BuildContext context) => Container(
// // //     padding: const EdgeInsets.all(24),
// // //     decoration: BoxDecoration(
// // //       gradient: const LinearGradient(
// // //         colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
// // //         begin: Alignment.topLeft,
// // //         end: Alignment.bottomRight,
// // //       ),
// // //       borderRadius: BorderRadius.circular(20),
// // //     ),
// // //     child: const Column(
// // //       children: [
// // //         Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
// // //         SizedBox(height: 12),
// // //         Text(
// // //           'Unlock Premium',
// // //           style: TextStyle(
// // //             color: Colors.white,
// // //             fontSize: 24,
// // //             fontWeight: FontWeight.w900,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Text(
// // //           'Custom themes & avatars, 15 rooms/day, 10 offline packs, anonymous chat, and more.',
// // //           style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
// // //           textAlign: TextAlign.center,
// // //         ),
// // //       ],
// // //     ),
// // //   );
// // // }

// // // class _ActiveBanner extends StatelessWidget {
// // //   const _ActiveBanner({required this.user, this.tier});
// // //   final dynamic user;
// // //   final String? tier;
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final exp = user.premiumExpiresAt;
// // //     final label = exp != null
// // //         ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
// // //         : 'Active — no expiry';
// // //     return Container(
// // //       padding: const EdgeInsets.all(20),
// // //       decoration: BoxDecoration(
// // //         color: Colors.green.shade50,
// // //         borderRadius: BorderRadius.circular(16),
// // //         border: Border.all(color: Colors.green.shade300),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
// // //           const SizedBox(width: 12),
// // //           Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Text(
// // //                 tier == 'premium_plus'
// // //                     ? 'Premium Plus Active ✦'
// // //                     : 'Premium Active ✦',
// // //                 style: TextStyle(
// // //                   fontWeight: FontWeight.w700,
// // //                   color: Colors.green.shade800,
// // //                   fontSize: 16,
// // //                 ),
// // //               ),
// // //               Text(
// // //                 label,
// // //                 style: TextStyle(color: Colors.green.shade600, fontSize: 13),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _PremiumPlan {
// // //   const _PremiumPlan({
// // //     required this.id,
// // //     required this.label,
// // //     required this.tier,
// // //     required this.price,
// // //     required this.period,
// // //     required this.isPopular,
// // //     this.savings,
// // //   });
// // //   final String id, label, tier, price, period;
// // //   final bool isPopular;
// // //   final String? savings;
// // // }

// // // class _PlanCard extends StatelessWidget {
// // //   const _PlanCard({
// // //     required this.plan,
// // //     required this.isActive,
// // //     required this.isLoading,
// // //     required this.onTap,
// // //   });
// // //   final _PremiumPlan plan;
// // //   final bool isActive;
// // //   final bool isLoading;
// // //   final VoidCallback onTap;

// // //   Color get _accent => plan.tier == 'premium_plus'
// // //       ? const Color(0xFF7B68EE)
// // //       : const Color(0xFFF5A623);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 12),
// // //       child: Stack(
// // //         children: [
// // //           Container(
// // //             decoration: BoxDecoration(
// // //               color: isActive
// // //                   ? _accent.withOpacity(0.08)
// // //                   : theme.colorScheme.surface,
// // //               borderRadius: BorderRadius.circular(16),
// // //               border: Border.all(
// // //                 color: isActive ? _accent : theme.colorScheme.outlineVariant,
// // //                 width: isActive ? 2 : 1,
// // //               ),
// // //             ),
// // //             child: Padding(
// // //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// // //               child: Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           plan.label,
// // //                           style: theme.textTheme.titleMedium?.copyWith(
// // //                             fontWeight: FontWeight.w700,
// // //                           ),
// // //                         ),
// // //                         const SizedBox(height: 2),
// // //                         Text(
// // //                           '${plan.price} / ${plan.period}',
// // //                           style: theme.textTheme.bodyMedium,
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   if (isActive)
// // //                     Container(
// // //                       padding: const EdgeInsets.symmetric(
// // //                         horizontal: 10,
// // //                         vertical: 4,
// // //                       ),
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.green.shade100,
// // //                         borderRadius: BorderRadius.circular(12),
// // //                       ),
// // //                       child: Text(
// // //                         'Active',
// // //                         style: TextStyle(
// // //                           color: Colors.green.shade700,
// // //                           fontWeight: FontWeight.w700,
// // //                           fontSize: 13,
// // //                         ),
// // //                       ),
// // //                     )
// // //                   else
// // //                     SizedBox(
// // //                       width: 72,
// // //                       height: 36,
// // //                       child: FilledButton(
// // //                         style: FilledButton.styleFrom(
// // //                           backgroundColor: _accent,
// // //                           padding: EdgeInsets.zero,
// // //                           shape: RoundedRectangleBorder(
// // //                             borderRadius: BorderRadius.circular(10),
// // //                           ),
// // //                         ),
// // //                         onPressed: isLoading ? null : onTap,
// // //                         child: isLoading
// // //                             ? const SizedBox(
// // //                                 width: 18,
// // //                                 height: 18,
// // //                                 child: CircularProgressIndicator(
// // //                                   strokeWidth: 2,
// // //                                   color: Colors.white,
// // //                                 ),
// // //                               )
// // //                             : const Text('Get'),
// // //                       ),
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //           if (plan.isPopular)
// // //             Positioned(
// // //               top: 0,
// // //               right: 16,
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // //                 decoration: BoxDecoration(
// // //                   color: _accent,
// // //                   borderRadius: const BorderRadius.vertical(
// // //                     bottom: Radius.circular(8),
// // //                   ),
// // //                 ),
// // //                 child: Text(
// // //                   plan.savings ?? 'Popular',
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 11,
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _FeatureTable extends StatelessWidget {
// // //   const _FeatureTable();

// // //   static const _rows = [
// // //     ('Rooms per day', '5', '15', '15'),
// // //     ('Offline packs', '0', '10', '10'),
// // //     ('Custom themes', '✗', '✓', '✓'),
// // //     ('Premium avatars', '✗', '✓', '✓'),
// // //     ('Anonymous chat', '✗', '✓', '✓'),
// // //     ('3× proof replays', '✗', '✓', '✓'),
// // //     ('Premium badge ✦', '✗', '✓', '✓'),
// // //     ('Hidden spectator', '✗', '✓', '✓'),
// // //     ('Priority support', '✗', '✗', '✓'),
// // //     ('Exclusive packs', '✗', '✗', '✓'),
// // //   ];

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.stretch,
// // //       children: [
// // //         Text(
// // //           'What you get',
// // //           style: theme.textTheme.titleMedium?.copyWith(
// // //             fontWeight: FontWeight.w700,
// // //           ),
// // //         ),
// // //         const SizedBox(height: 12),
// // //         Table(
// // //           columnWidths: const {
// // //             0: FlexColumnWidth(),
// // //             1: FixedColumnWidth(52),
// // //             2: FixedColumnWidth(64),
// // //             3: FixedColumnWidth(52),
// // //           },
// // //           children: [_headerRow(theme), ..._rows.map(_dataRow)],
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   TableRow _headerRow(ThemeData theme) => TableRow(
// // //     decoration: BoxDecoration(
// // //       color: theme.colorScheme.surfaceContainerHighest,
// // //       borderRadius: BorderRadius.circular(8),
// // //     ),
// // //     children: const [
// // //       Padding(
// // //         padding: EdgeInsets.all(10),
// // //         child: Text(
// // //           'Feature',
// // //           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// // //         ),
// // //       ),
// // //       Padding(
// // //         padding: EdgeInsets.all(10),
// // //         child: Text(
// // //           'Free',
// // //           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
// // //           textAlign: TextAlign.center,
// // //         ),
// // //       ),
// // //       Padding(
// // //         padding: EdgeInsets.all(10),
// // //         child: Text(
// // //           'Premium',
// // //           style: TextStyle(
// // //             fontWeight: FontWeight.w700,
// // //             fontSize: 11,
// // //             color: Color(0xFFF5A623),
// // //           ),
// // //           textAlign: TextAlign.center,
// // //         ),
// // //       ),
// // //       Padding(
// // //         padding: EdgeInsets.all(10),
// // //         child: Text(
// // //           'Plus',
// // //           style: TextStyle(
// // //             fontWeight: FontWeight.w700,
// // //             fontSize: 11,
// // //             color: Color(0xFF7B68EE),
// // //           ),
// // //           textAlign: TextAlign.center,
// // //         ),
// // //       ),
// // //     ],
// // //   );

// // //   TableRow _dataRow((String, String, String, String) r) => TableRow(
// // //     children: [
// // //       Padding(
// // //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // //         child: Text(r.$1, style: const TextStyle(fontSize: 12)),
// // //       ),
// // //       _cell(r.$2),
// // //       _cell(r.$3),
// // //       _cell(r.$4),
// // //     ],
// // //   );

// // //   Widget _cell(String val) => Padding(
// // //     padding: const EdgeInsets.symmetric(vertical: 8),
// // //     child: Center(
// // //       child: val == '✓'
// // //           ? const Icon(
// // //               Icons.check_circle_rounded,
// // //               color: Color(0xFFF5A623),
// // //               size: 16,
// // //             )
// // //           : val == '✗'
// // //           ? const Icon(Icons.remove, size: 14, color: Colors.grey)
// // //           : Text(
// // //               val,
// // //               style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
// // //               textAlign: TextAlign.center,
// // //             ),
// // //     ),
// // //   );
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/network/api_client.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/services/subscription_service.dart';

// // const _planPrices = {'monthly': 999, 'yearly': 7999, 'plus_monthly': 1999};

// // const _planLabels = {
// //   'monthly': 'Premium Monthly',
// //   'yearly': 'Premium Yearly',
// //   'plus_monthly': 'Premium Plus Monthly',
// // };

// // class PremiumScreen extends StatefulWidget {
// //   const PremiumScreen({super.key});

// //   @override
// //   State<PremiumScreen> createState() => _PremiumScreenState();
// // }

// // class _PremiumScreenState extends State<PremiumScreen> {
// //   bool _loading = false;
// //   String? _selectedPlanId;

// //   static const Color _gold = Color(0xFFF5A623);
// //   static const Color _platinum = Color(0xFF7B68EE);

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadStatus();
// //   }

// //   Future<void> _loadStatus() async {
// //     final uid = context.read<AuthProvider>().currentUser?.id;
// //     if (uid == null) return;
// //     await SubscriptionService.instance.getActiveSubscription(uid);
// //     if (mounted) setState(() {});
// //   }

// //   Future<void> _purchase(_PremiumPlan plan) async {
// //     if (_loading) return;
// //     final user = context.read<AuthProvider>().currentUser;
// //     if (user == null) return;

// //     final priceMru = _planPrices[plan.id] ?? 0;

// //     // Confirm with user before deducting
// //     final confirmed = await showDialog<bool>(
// //       context: context,
// //       builder: (dCtx) => AlertDialog(
// //         title: Text('Purchase ${_planLabels[plan.id] ?? plan.label}'),
// //         content: Text(
// //           'This will deduct $priceMru MRU from your wallet balance.\n\n'
// //           'Plan: ${plan.label} — ${plan.price}/${plan.period}',
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.of(dCtx).pop(false),
// //             child: const Text('Cancel'),
// //           ),
// //           FilledButton(
// //             onPressed: () => Navigator.of(dCtx).pop(true),
// //             child: const Text('Confirm Purchase'),
// //           ),
// //         ],
// //       ),
// //     );
// //     if (confirmed != true || !mounted) return;

// //     setState(() {
// //       _loading = true;
// //       _selectedPlanId = plan.id;
// //     });
// //     try {
// //       final api = context.read<ApiClient>();
// //       await api.post('/v1/wallet/subscribe', data: {'planId': plan.id});
// //       if (!mounted) return;
// //       print('PUUUUUm , $mounted');
// //       // Reload user profile to pick up new premium status
// //       await context.read<AuthProvider>().refreshCurrentUser();
// //       await _loadStatus();
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('🎉 ${_planLabels[plan.id]} activated!'),
// //             backgroundColor: Colors.green.shade700,
// //             behavior: SnackBarBehavior.fixed,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (!mounted) return;
// //       final raw = e.toString();
// //       final msg = raw.contains('insufficient_balance')
// //           ? 'Not enough balance. Please top up your wallet first.'
// //           : raw.contains('wallet_not_found')
// //           ? 'Wallet not found. Please contact support.'
// //           : raw.contains('wallet_frozen')
// //           ? 'Your wallet is frozen. Please contact support.'
// //           : raw.contains('invalid_plan')
// //           ? 'Invalid plan selected.'
// //           : 'Purchase failed: $raw';
// //       print(msg);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(msg),
// //           backgroundColor: Colors.red.shade700,
// //           behavior: SnackBarBehavior.fixed,
// //           duration: const Duration(seconds: 6),
// //         ),
// //       );
// //     } finally {
// //       if (mounted)
// //         setState(() {
// //           _loading = false;
// //           _selectedPlanId = null;
// //         });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final user = context.watch<AuthProvider>().currentUser;
// //     final isPremium = user?.isPremiumActive ?? false;
// //     final tier = user?.premiumTier;
// //     final theme = context.theme;

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text(
// //               'Premium',
// //               style: TextStyle(fontWeight: FontWeight.w800),
// //             ),
// //             const SizedBox(width: 6),
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //               decoration: BoxDecoration(
// //                 gradient: const LinearGradient(
// //                   colors: [_gold, Color(0xFFFF8C00)],
// //                 ),
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: const Text(
// //                 '✦',
// //                 style: TextStyle(color: Colors.white, fontSize: 14),
// //               ),
// //             ),
// //           ],
// //         ),
// //         centerTitle: true,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             if (isPremium)
// //               _ActiveBanner(user: user!, tier: tier)
// //             else
// //               const _HeroBanner(),
// //             const SizedBox(height: 24),
// //             ...[
// //               _PremiumPlan(
// //                 id: 'monthly',
// //                 label: 'Monthly',
// //                 tier: 'premium',
// //                 price: '9.99 MRU',
// //                 period: 'month',
// //                 isPopular: false,
// //               ),
// //               _PremiumPlan(
// //                 id: 'yearly',
// //                 label: 'Yearly',
// //                 tier: 'premium',
// //                 price: '79.99 MRU',
// //                 period: 'year',
// //                 isPopular: true,
// //                 savings: 'Save 33%',
// //               ),
// //               _PremiumPlan(
// //                 id: 'plus_monthly',
// //                 label: 'Premium Plus',
// //                 tier: 'premium_plus',
// //                 price: '19.99 MRU',
// //                 period: 'month',
// //                 isPopular: false,
// //               ),
// //             ].map(
// //               (plan) => _PlanCard(
// //                 plan: plan,
// //                 isActive: isPremium && tier == plan.tier,
// //                 isLoading: _loading && _selectedPlanId == plan.id,
// //                 onTap: () => _purchase(plan),
// //               ),
// //             ),
// //             const SizedBox(height: 24),
// //             const _FeatureTable(),
// //             const SizedBox(height: 20),
// //             Text(
// //               'Subscriptions auto-renew unless cancelled 24h before renewal.',
// //               style: theme.textTheme.bodySmall?.copyWith(
// //                 color: theme.colorScheme.onSurfaceVariant,
// //               ),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _HeroBanner extends StatelessWidget {
// //   const _HeroBanner();
// //   @override
// //   Widget build(BuildContext context) => Container(
// //     padding: const EdgeInsets.all(24),
// //     decoration: BoxDecoration(
// //       gradient: const LinearGradient(
// //         colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
// //         begin: Alignment.topLeft,
// //         end: Alignment.bottomRight,
// //       ),
// //       borderRadius: BorderRadius.circular(20),
// //     ),
// //     child: const Column(
// //       children: [
// //         Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
// //         SizedBox(height: 12),
// //         Text(
// //           'Unlock Premium',
// //           style: TextStyle(
// //             color: Colors.white,
// //             fontSize: 24,
// //             fontWeight: FontWeight.w900,
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         Text(
// //           'Custom themes & avatars, 15 rooms/day, 10 offline packs (1 free), anonymous chat, and more.',
// //           style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
// //           textAlign: TextAlign.center,
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // class _ActiveBanner extends StatelessWidget {
// //   const _ActiveBanner({required this.user, this.tier});
// //   final dynamic user;
// //   final String? tier;
// //   @override
// //   Widget build(BuildContext context) {
// //     final exp = user.premiumExpiresAt;
// //     final label = exp != null
// //         ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
// //         : 'Active — no expiry';
// //     return Container(
// //       padding: const EdgeInsets.all(20),
// //       decoration: BoxDecoration(
// //         color: Colors.green.shade50,
// //         borderRadius: BorderRadius.circular(16),
// //         border: Border.all(color: Colors.green.shade300),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
// //           const SizedBox(width: 12),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 tier == 'premium_plus'
// //                     ? 'Premium Plus Active ✦'
// //                     : 'Premium Active ✦',
// //                 style: TextStyle(
// //                   fontWeight: FontWeight.w700,
// //                   color: Colors.green.shade800,
// //                   fontSize: 16,
// //                 ),
// //               ),
// //               Text(
// //                 label,
// //                 style: TextStyle(color: Colors.green.shade600, fontSize: 13),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PremiumPlan {
// //   const _PremiumPlan({
// //     required this.id,
// //     required this.label,
// //     required this.tier,
// //     required this.price,
// //     required this.period,
// //     required this.isPopular,
// //     this.savings,
// //   });
// //   final String id, label, tier, price, period;
// //   final bool isPopular;
// //   final String? savings;
// // }

// // class _PlanCard extends StatelessWidget {
// //   const _PlanCard({
// //     required this.plan,
// //     required this.isActive,
// //     required this.isLoading,
// //     required this.onTap,
// //   });
// //   final _PremiumPlan plan;
// //   final bool isActive;
// //   final bool isLoading;
// //   final VoidCallback onTap;

// //   Color get _accent => plan.tier == 'premium_plus'
// //       ? const Color(0xFF7B68EE)
// //       : const Color(0xFFF5A623);

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 12),
// //       child: Stack(
// //         children: [
// //           Container(
// //             decoration: BoxDecoration(
// //               color: isActive
// //                   ? _accent.withOpacity(0.08)
// //                   : theme.colorScheme.surface,
// //               borderRadius: BorderRadius.circular(16),
// //               border: Border.all(
// //                 color: isActive ? _accent : theme.colorScheme.outlineVariant,
// //                 width: isActive ? 2 : 1,
// //               ),
// //             ),
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           plan.label,
// //                           style: theme.textTheme.titleMedium?.copyWith(
// //                             fontWeight: FontWeight.w700,
// //                           ),
// //                         ),
// //                         const SizedBox(height: 2),
// //                         Text(
// //                           '${plan.price} / ${plan.period}',
// //                           style: theme.textTheme.bodyMedium,
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   if (isActive)
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 10,
// //                         vertical: 4,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: Colors.green.shade100,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Text(
// //                         'Active',
// //                         style: TextStyle(
// //                           color: Colors.green.shade700,
// //                           fontWeight: FontWeight.w700,
// //                           fontSize: 13,
// //                         ),
// //                       ),
// //                     )
// //                   else
// //                     SizedBox(
// //                       width: 72,
// //                       height: 36,
// //                       child: FilledButton(
// //                         style: FilledButton.styleFrom(
// //                           backgroundColor: _accent,
// //                           padding: EdgeInsets.zero,
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                         ),
// //                         onPressed: isLoading ? null : onTap,
// //                         child: isLoading
// //                             ? const SizedBox(
// //                                 width: 18,
// //                                 height: 18,
// //                                 child: CircularProgressIndicator(
// //                                   strokeWidth: 2,
// //                                   color: Colors.white,
// //                                 ),
// //                               )
// //                             : const Text('Get'),
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           if (plan.isPopular)
// //             Positioned(
// //               top: 0,
// //               right: 16,
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //                 decoration: BoxDecoration(
// //                   color: _accent,
// //                   borderRadius: const BorderRadius.vertical(
// //                     bottom: Radius.circular(8),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   plan.savings ?? 'Popular',
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 11,
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _FeatureTable extends StatelessWidget {
// //   const _FeatureTable();

// //   static const _rows = [
// //     ('Rooms per day', '5', '15', '15'),
// //     ('Offline packs', '1', '10', '10'),
// //     ('Custom themes', '✗', '✓', '✓'),
// //     ('Premium avatars', '✗', '✓', '✓'),
// //     ('Anonymous chat', '✗', '✓', '✓'),
// //     ('3× proof replays', '✗', '✓', '✓'),
// //     ('Premium badge ✦', '✗', '✓', '✓'),
// //     ('Hidden spectator', '✗', '✓', '✓'),
// //     ('Priority support', '✗', '✗', '✓'),
// //     ('Exclusive packs', '✗', '✗', '✓'),
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.stretch,
// //       children: [
// //         Text(
// //           'What you get',
// //           style: theme.textTheme.titleMedium?.copyWith(
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         const SizedBox(height: 12),
// //         Table(
// //           columnWidths: const {
// //             0: FlexColumnWidth(),
// //             1: FixedColumnWidth(52),
// //             2: FixedColumnWidth(64),
// //             3: FixedColumnWidth(52),
// //           },
// //           children: [_headerRow(theme), ..._rows.map(_dataRow)],
// //         ),
// //       ],
// //     );
// //   }

// //   TableRow _headerRow(ThemeData theme) => TableRow(
// //     decoration: BoxDecoration(
// //       color: theme.colorScheme.surfaceContainerHighest,
// //       borderRadius: BorderRadius.circular(8),
// //     ),
// //     children: const [
// //       Padding(
// //         padding: EdgeInsets.all(10),
// //         child: Text(
// //           'Feature',
// //           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
// //         ),
// //       ),
// //       Padding(
// //         padding: EdgeInsets.all(10),
// //         child: Text(
// //           'Free',
// //           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
// //           textAlign: TextAlign.center,
// //         ),
// //       ),
// //       Padding(
// //         padding: EdgeInsets.all(10),
// //         child: Text(
// //           'Premium',
// //           style: TextStyle(
// //             fontWeight: FontWeight.w700,
// //             fontSize: 11,
// //             color: Color(0xFFF5A623),
// //           ),
// //           textAlign: TextAlign.center,
// //         ),
// //       ),
// //       Padding(
// //         padding: EdgeInsets.all(10),
// //         child: Text(
// //           'Plus',
// //           style: TextStyle(
// //             fontWeight: FontWeight.w700,
// //             fontSize: 11,
// //             color: Color(0xFF7B68EE),
// //           ),
// //           textAlign: TextAlign.center,
// //         ),
// //       ),
// //     ],
// //   );

// //   TableRow _dataRow((String, String, String, String) r) => TableRow(
// //     children: [
// //       Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// //         child: Text(r.$1, style: const TextStyle(fontSize: 12)),
// //       ),
// //       _cell(r.$2),
// //       _cell(r.$3),
// //       _cell(r.$4),
// //     ],
// //   );

// //   Widget _cell(String val) => Padding(
// //     padding: const EdgeInsets.symmetric(vertical: 8),
// //     child: Center(
// //       child: val == '✓'
// //           ? const Icon(
// //               Icons.check_circle_rounded,
// //               color: Color(0xFFF5A623),
// //               size: 16,
// //             )
// //           : val == '✗'
// //           ? const Icon(Icons.remove, size: 14, color: Colors.grey)
// //           : Text(
// //               val,
// //               style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
// //               textAlign: TextAlign.center,
// //             ),
// //     ),
// //   );
// // }

// import 'package:flutter/material.dart';
// import 'package:jma3a/core/services/subscription_service.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/network/api_client.dart';
// import '../../../../core/providers/auth_provider.dart';

// const _planPrices = {'monthly': 999, 'yearly': 7999, 'plus_monthly': 1999};

// const _planLabels = {
//   'monthly': 'Premium Monthly',
//   'yearly': 'Premium Yearly',
//   'plus_monthly': 'Premium Plus Monthly',
// };

// class PremiumScreen extends StatefulWidget {
//   const PremiumScreen({super.key});

//   @override
//   State<PremiumScreen> createState() => _PremiumScreenState();
// }

// class _PremiumScreenState extends State<PremiumScreen> {
//   bool _loading = false;
//   String? _selectedPlanId;

//   static const Color _gold = Color(0xFFF5A623);
//   static const Color _platinum = Color(0xFF7B68EE);

//   @override
//   void initState() {
//     super.initState();
//     _loadStatus();
//   }

//   Future<void> _loadStatus() async {
//     final uid = context.read<AuthProvider>().currentUser?.id;
//     if (uid == null) return;
//     await SubscriptionService.instance.getActiveSubscription(uid);
//     if (mounted) setState(() {});
//   }

//   Future<void> _purchase(_PremiumPlan plan) async {
//     if (_loading) return;
//     final user = context.read<AuthProvider>().currentUser;
//     if (user == null) return;

//     final priceMru = _planPrices[plan.id] ?? 0;

//     // Confirm with user before deducting
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (dCtx) => AlertDialog(
//         title: Text('Purchase ${_planLabels[plan.id] ?? plan.label}'),
//         content: Text(
//           'This will deduct $priceMru MRU from your wallet balance.\n\n'
//           'Plan: ${plan.label} — ${plan.price}/${plan.period}',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(dCtx).pop(false),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.of(dCtx).pop(true),
//             child: const Text('Confirm Purchase'),
//           ),
//         ],
//       ),
//     );
//     if (confirmed != true || !mounted) return;

//     setState(() {
//       _loading = true;
//       _selectedPlanId = plan.id;
//     });
//     try {
//       final api = ApiClient.instance;
//       await api.post('/v1/wallet/subscribe', data: {'planId': plan.id});
//       if (!mounted) return;
//       print(api);
//       // Reload user profile to pick up new premium status
//       await context.read<AuthProvider>().refreshCurrentUser();
//       await _loadStatus();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('🎉 ${_planLabels[plan.id]} activated!'),
//             backgroundColor: Colors.green.shade700,
//             behavior: SnackBarBehavior.fixed,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       final raw = e.toString();
//       final msg = raw.contains('insufficient_balance')
//           ? 'Not enough balance. Please top up your wallet first.'
//           : raw.contains('wallet_not_found')
//           ? 'Wallet not found. Please contact support.'
//           : raw.contains('wallet_frozen')
//           ? 'Your wallet is frozen. Please contact support.'
//           : raw.contains('invalid_plan')
//           ? 'Invalid plan selected.'
//           : 'Purchase failed: $raw';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(msg),
//           backgroundColor: Colors.red.shade700,
//           behavior: SnackBarBehavior.fixed,
//           duration: const Duration(seconds: 6),
//         ),
//       );
//     } finally {
//       if (mounted)
//         setState(() {
//           _loading = false;
//           _selectedPlanId = null;
//         });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<AuthProvider>().currentUser;
//     final isPremium = user?.isPremiumActive ?? false;
//     final tier = user?.premiumTier;
//     final theme = context.theme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Premium',
//               style: TextStyle(fontWeight: FontWeight.w800),
//             ),
//             const SizedBox(width: 6),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [_gold, Color(0xFFFF8C00)],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Text(
//                 '✦',
//                 style: TextStyle(color: Colors.white, fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             if (isPremium)
//               _ActiveBanner(user: user!, tier: tier)
//             else
//               const _HeroBanner(),
//             const SizedBox(height: 24),
//             ...[
//               _PremiumPlan(
//                 id: 'monthly',
//                 label: 'Monthly',
//                 tier: 'premium',
//                 price: '9.99 MRU',
//                 period: 'month',
//                 isPopular: false,
//               ),
//               _PremiumPlan(
//                 id: 'yearly',
//                 label: 'Yearly',
//                 tier: 'premium',
//                 price: '79.99 MRU',
//                 period: 'year',
//                 isPopular: true,
//                 savings: 'Save 33%',
//               ),
//               _PremiumPlan(
//                 id: 'plus_monthly',
//                 label: 'Premium Plus',
//                 tier: 'premium_plus',
//                 price: '19.99 MRU',
//                 period: 'month',
//                 isPopular: false,
//               ),
//             ].map(
//               (plan) => _PlanCard(
//                 plan: plan,
//                 isActive: isPremium && tier == plan.tier,
//                 isLoading: _loading && _selectedPlanId == plan.id,
//                 onTap: () => _purchase(plan),
//               ),
//             ),
//             const SizedBox(height: 24),
//             const _FeatureTable(),
//             const SizedBox(height: 20),
//             Text(
//               'Subscriptions auto-renew unless cancelled 24h before renewal.',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HeroBanner extends StatelessWidget {
//   const _HeroBanner();
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(24),
//     decoration: BoxDecoration(
//       gradient: const LinearGradient(
//         colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: const Column(
//       children: [
//         Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
//         SizedBox(height: 12),
//         Text(
//           'Unlock Premium',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 24,
//             fontWeight: FontWeight.w900,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           'Custom themes & avatars, 15 rooms/day, 10 offline packs (1 free), anonymous chat, and more.',
//           style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     ),
//   );
// }

// class _ActiveBanner extends StatelessWidget {
//   const _ActiveBanner({required this.user, this.tier});
//   final dynamic user;
//   final String? tier;
//   @override
//   Widget build(BuildContext context) {
//     final exp = user.premiumExpiresAt;
//     final label = exp != null
//         ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
//         : 'Active — no expiry';
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.green.shade300),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 tier == 'premium_plus'
//                     ? 'Premium Plus Active ✦'
//                     : 'Premium Active ✦',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.green.shade800,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 label,
//                 style: TextStyle(color: Colors.green.shade600, fontSize: 13),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PremiumPlan {
//   const _PremiumPlan({
//     required this.id,
//     required this.label,
//     required this.tier,
//     required this.price,
//     required this.period,
//     required this.isPopular,
//     this.savings,
//   });
//   final String id, label, tier, price, period;
//   final bool isPopular;
//   final String? savings;
// }

// class _PlanCard extends StatelessWidget {
//   const _PlanCard({
//     required this.plan,
//     required this.isActive,
//     required this.isLoading,
//     required this.onTap,
//   });
//   final _PremiumPlan plan;
//   final bool isActive;
//   final bool isLoading;
//   final VoidCallback onTap;

//   Color get _accent => plan.tier == 'premium_plus'
//       ? const Color(0xFF7B68EE)
//       : const Color(0xFFF5A623);

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: isActive
//                   ? _accent.withOpacity(0.08)
//                   : theme.colorScheme.surface,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: isActive ? _accent : theme.colorScheme.outlineVariant,
//                 width: isActive ? 2 : 1,
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           plan.label,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           '${plan.price} / ${plan.period}',
//                           style: theme.textTheme.bodyMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (isActive)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade100,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         'Active',
//                         style: TextStyle(
//                           color: Colors.green.shade700,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 13,
//                         ),
//                       ),
//                     )
//                   else
//                     SizedBox(
//                       width: 72,
//                       height: 36,
//                       child: FilledButton(
//                         style: FilledButton.styleFrom(
//                           backgroundColor: _accent,
//                           padding: EdgeInsets.zero,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         onPressed: isLoading ? null : onTap,
//                         child: isLoading
//                             ? const SizedBox(
//                                 width: 18,
//                                 height: 18,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Text('Get'),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//           if (plan.isPopular)
//             Positioned(
//               top: 0,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: _accent,
//                   borderRadius: const BorderRadius.vertical(
//                     bottom: Radius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   plan.savings ?? 'Popular',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _FeatureTable extends StatelessWidget {
//   const _FeatureTable();

//   static const _rows = [
//     ('Rooms per day', '5', '15', '15'),
//     ('Offline packs', '1', '10', '10'),
//     ('Custom themes', '✗', '✓', '✓'),
//     ('Premium avatars', '✗', '✓', '✓'),
//     ('Anonymous chat', '✗', '✓', '✓'),
//     ('3× proof replays', '✗', '✓', '✓'),
//     ('Premium badge ✦', '✗', '✓', '✓'),
//     ('Hidden spectator', '✗', '✓', '✓'),
//     ('Priority support', '✗', '✗', '✓'),
//     ('Exclusive packs', '✗', '✗', '✓'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Text(
//           'What you get',
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Table(
//           columnWidths: const {
//             0: FlexColumnWidth(),
//             1: FixedColumnWidth(52),
//             2: FixedColumnWidth(64),
//             3: FixedColumnWidth(52),
//           },
//           children: [_headerRow(theme), ..._rows.map(_dataRow)],
//         ),
//       ],
//     );
//   }

//   TableRow _headerRow(ThemeData theme) => TableRow(
//     decoration: BoxDecoration(
//       color: theme.colorScheme.surfaceContainerHighest,
//       borderRadius: BorderRadius.circular(8),
//     ),
//     children: const [
//       Padding(
//         padding: EdgeInsets.all(10),
//         child: Text(
//           'Feature',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
//         ),
//       ),
//       Padding(
//         padding: EdgeInsets.all(10),
//         child: Text(
//           'Free',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
//           textAlign: TextAlign.center,
//         ),
//       ),
//       Padding(
//         padding: EdgeInsets.all(10),
//         child: Text(
//           'Premium',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 11,
//             color: Color(0xFFF5A623),
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//       Padding(
//         padding: EdgeInsets.all(10),
//         child: Text(
//           'Plus',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 11,
//             color: Color(0xFF7B68EE),
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     ],
//   );

//   TableRow _dataRow((String, String, String, String) r) => TableRow(
//     children: [
//       Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         child: Text(r.$1, style: const TextStyle(fontSize: 12)),
//       ),
//       _cell(r.$2),
//       _cell(r.$3),
//       _cell(r.$4),
//     ],
//   );

//   Widget _cell(String val) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8),
//     child: Center(
//       child: val == '✓'
//           ? const Icon(
//               Icons.check_circle_rounded,
//               color: Color(0xFFF5A623),
//               size: 16,
//             )
//           : val == '✗'
//           ? const Icon(Icons.remove, size: 14, color: Colors.grey)
//           : Text(
//               val,
//               style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
//               textAlign: TextAlign.center,
//             ),
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:jma3a/core/services/subscription_service.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider.dart';

const _planPrices = {'monthly': 999, 'yearly': 7999, 'plus_monthly': 1999};

const _planLabels = {
  'monthly': 'Premium Monthly',
  'yearly': 'Premium Yearly',
  'plus_monthly': 'Premium Plus Monthly',
};

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = false;
  String? _selectedPlanId;

  static const Color _gold = Color(0xFFF5A623);
  static const Color _platinum = Color(0xFF7B68EE);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    await SubscriptionService.instance.getActiveSubscription(uid);
    if (mounted) setState(() {});
  }

  Future<void> _purchase(_PremiumPlan plan) async {
    if (_loading) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final currentTier = user.premiumTier;
    final isCurrentlyPlus =
        user.isPremiumActive && currentTier == 'premium_plus';
    final isDowngrade = isCurrentlyPlus && plan.tier == 'premium';
    if (isDowngrade) {
      final expiresAt = user.premiumExpiresAt;
      final dateStr = expiresAt != null
          ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}'
          : 'your current term ends';
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: const Text('Cannot Downgrade Yet'),
            content: Text(
              'You have an active Premium Plus subscription. You can switch '
              'to a lower plan once it expires on $dateStr.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final priceMru = _planPrices[plan.id] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('Purchase ${_planLabels[plan.id] ?? plan.label}'),
        content: Text(
          'This will deduct $priceMru MRU from your wallet balance.\n\n'
          'Plan: ${plan.label} — ${plan.price}/${plan.period}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _selectedPlanId = plan.id;
    });
    try {
      final api = ApiClient.instance;
      await api.post('/v1/wallet/subscribe', data: {'planId': plan.id});
      if (!mounted) return;
      await context.read<AuthProvider>().refreshCurrentUser();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${_planLabels[plan.id]} activated!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final msg = raw.contains('insufficient_balance')
          ? 'Not enough balance. Please top up your wallet first.'
          : raw.contains('wallet_not_found')
          ? 'Wallet not found. Please contact support.'
          : raw.contains('wallet_frozen')
          ? 'Your wallet is frozen. Please contact support.'
          : raw.contains('invalid_plan')
          ? 'Invalid plan selected.'
          : raw.contains('downgrade_blocked')
          ? 'You can switch plans once your current subscription expires.'
          : 'Purchase failed: $raw';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _selectedPlanId = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isPremium = user?.isPremiumActive ?? false;
    final tier = user?.premiumTier;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Premium',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '✦',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPremium)
              _ActiveBanner(user: user!, tier: tier)
            else
              const _HeroBanner(),
            const SizedBox(height: 24),
            ...[
              _PremiumPlan(
                id: 'monthly',
                label: 'Monthly',
                tier: 'premium',
                price: '9.99 MRU',
                period: 'month',
                isPopular: false,
              ),
              _PremiumPlan(
                id: 'yearly',
                label: 'Yearly',
                tier: 'premium',
                price: '79.99 MRU',
                period: 'year',
                isPopular: true,
                savings: 'Save 33%',
              ),
              _PremiumPlan(
                id: 'plus_monthly',
                label: 'Premium Plus',
                tier: 'premium_plus',
                price: '19.99 MRU',
                period: 'month',
                isPopular: false,
              ),
            ].map((plan) {
              final isDowngradeOption =
                  isPremium && tier == 'premium_plus' && plan.tier == 'premium';
              return _PlanCard(
                plan: plan,
                isActive: isPremium && tier == plan.tier,
                isLoading: _loading && _selectedPlanId == plan.id,
                isLocked: isDowngradeOption,
                onTap: () => _purchase(plan),
              );
            }),
            const SizedBox(height: 24),
            const _FeatureTable(),
            const SizedBox(height: 20),
            Text(
              'Subscriptions auto-renew unless cancelled 24h before renewal.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
        SizedBox(height: 12),
        Text(
          'Unlock Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Custom themes & avatars, 15 rooms/day, up to 12 players per room, 10 offline packs (1 free), anonymous chat, and more.',
          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.user, this.tier});
  final dynamic user;
  final String? tier;
  @override
  Widget build(BuildContext context) {
    final exp = user.premiumExpiresAt;
    final label = exp != null
        ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
        : 'Active — no expiry';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier == 'premium_plus'
                    ? 'Premium Plus Active ✦'
                    : 'Premium Active ✦',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.green.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumPlan {
  const _PremiumPlan({
    required this.id,
    required this.label,
    required this.tier,
    required this.price,
    required this.period,
    required this.isPopular,
    this.savings,
  });
  final String id, label, tier, price, period;
  final bool isPopular;
  final String? savings;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    this.isLocked = false,
  });
  final _PremiumPlan plan;
  final bool isActive;
  final bool isLoading;
  final bool isLocked;
  final VoidCallback onTap;

  Color get _accent => plan.tier == 'premium_plus'
      ? const Color(0xFF7B68EE)
      : const Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isActive
                    ? _accent.withOpacity(0.08)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? _accent : theme.colorScheme.outlineVariant,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${plan.price} / ${plan.period}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (isLocked) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Locked until Premium Plus expires',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else if (isLocked)
                      Icon(
                        Icons.lock_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      )
                    else
                      SizedBox(
                        width: 72,
                        height: 36,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : onTap,
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Get'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (plan.isPopular)
              Positioned(
                top: 0,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    plan.savings ?? 'Popular',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable();

  static const _rows = [
    ('Rooms per day', '5', '15', '15'),
    ('Max players per room', '3', '8', '12'),
    ('Offline packs', '1', '10', '10'),
    ('Custom themes', '✗', '✓', '✓'),
    ('Premium avatars', '✗', '✓', '✓'),
    ('Anonymous chat', '✗', '✓', '✓'),
    ('3× proof replays', '✗', '✓', '✓'),
    ('Premium badge ✦', '✗', '✓', '✓'),
    ('Hidden spectator', '✗', '✓', '✓'),
    ('Priority support', '✗', '✗', '✓'),
    ('Exclusive packs', '✗', '✗', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What you get',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FixedColumnWidth(52),
            2: FixedColumnWidth(64),
            3: FixedColumnWidth(52),
          },
          children: [_headerRow(theme), ..._rows.map(_dataRow)],
        ),
      ],
    );
  }

  TableRow _headerRow(ThemeData theme) => TableRow(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    children: const [
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Feature',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Free',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Premium',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Color(0xFFF5A623),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Plus',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Color(0xFF7B68EE),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  TableRow _dataRow((String, String, String, String) r) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(r.$1, style: const TextStyle(fontSize: 12)),
      ),
      _cell(r.$2),
      _cell(r.$3),
      _cell(r.$4),
    ],
  );

  Widget _cell(String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: val == '✓'
          ? const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFF5A623),
              size: 16,
            )
          : val == '✗'
          ? const Icon(Icons.remove, size: 14, color: Colors.grey)
          : Text(
              val,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
    ),
  );
}
