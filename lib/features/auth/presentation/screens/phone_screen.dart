// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';

// class PhoneScreen extends StatefulWidget {
//   const PhoneScreen({super.key});

//   @override
//   State<PhoneScreen> createState() => _PhoneScreenState();
// }

// class _PhoneScreenState extends State<PhoneScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneCtrl = TextEditingController();
//   final _phoneFocus = FocusNode();

//   @override
//   void dispose() {
//     _phoneCtrl.dispose();
//     _phoneFocus.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//     _phoneFocus.unfocus();

//     final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
//     final phone = '+222$digits';

//     final auth = context.read<AuthProvider>();
//     final result = await auth.sendPhoneOtp(phone);

//     if (!mounted) return;
//     if (result.success) {
//       context.push(RouteNames.authOtp, extra: result.syntheticEmail);
//     } else {
//       context.showErrorSnackBar(
//         result.errorMessage ?? context.l10n.errorUnexpected,
//       );
//     }
//   }

//   void _enterGuestMode() {
//     context.read<AuthProvider>().enterGuestMode();
//     context.go(RouteNames.offline);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final theme = context.theme;

//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 64),

//                 _BrandHeader()
//                     .animate()
//                     .fadeIn(duration: 500.ms)
//                     .slideY(begin: -0.15, end: 0),

//                 const SizedBox(height: 56),

//                 Text(
//                   l10n.authWelcome,
//                   style: theme.textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

//                 const SizedBox(height: 8),

//                 Text(
//                   l10n.authTagline,
//                   style: theme.textTheme.bodyLarge?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ).animate(delay: 150.ms).fadeIn(),

//                 const SizedBox(height: 40),

//                 TextFormField(
//                   controller: _phoneCtrl,
//                   focusNode: _phoneFocus,
//                   keyboardType: TextInputType.phone,
//                   textInputAction: TextInputAction.done,
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                   maxLength: 8,
//                   onFieldSubmitted: (_) => _submit(),
//                   decoration: InputDecoration(
//                     labelText: 'Phone number',
//                     hintText: '12345678',
//                     prefixIcon: const Icon(Icons.phone_outlined),
//                     prefix: Text(
//                       '+222 ',
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: theme.colorScheme.onSurface,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     counterText: '',
//                   ),
//                   validator: (v) {
//                     final digits =
//                         v?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
//                     if (digits.isEmpty || digits.length < 8) {
//                       return 'Enter your 8-digit Mauritanian number';
//                     }
//                     return null;
//                   },
//                 ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.08, end: 0),

//                 const SizedBox(height: 24),

//                 Consumer<AuthProvider>(
//                   builder: (_, auth, __) => JButton(
//                     label: l10n.authSendOtp,
//                     onPressed: _submit,
//                     isLoading: auth.isSendingOtp,
//                   ),
//                 ).animate(delay: 280.ms).fadeIn(),

//                 const SizedBox(height: 16),

//                 Center(
//                   child: TextButton(
//                     onPressed: () => context.push(RouteNames.authEmail),
//                     child: Text(
//                       'Use email instead',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.primary,
//                       ),
//                     ),
//                   ),
//                 ).animate(delay: 310.ms).fadeIn(),

//                 const SizedBox(height: 4),

//                 Row(
//                   children: [
//                     const Expanded(child: Divider()),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       child: Text(
//                         l10n.or,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ),
//                     const Expanded(child: Divider()),
//                   ],
//                 ).animate(delay: 340.ms).fadeIn(),

//                 const SizedBox(height: 16),

//                 OutlinedButton.icon(
//                   onPressed: _enterGuestMode,
//                   icon: const Icon(Icons.person_outline_rounded, size: 20),
//                   label: const Text('Continue as Guest'),
//                   style: OutlinedButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 48),
//                   ),
//                 ).animate(delay: 380.ms).fadeIn(),

//                 const SizedBox(height: 40),

//                 Center(
//                   child: Text(
//                     'By continuing you agree to our Terms & Privacy Policy',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ).animate(delay: 420.ms).fadeIn(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BrandHeader extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             color: AppColors.navyBlue,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: const Icon(
//             Icons.groups_rounded,
//             color: Colors.white,
//             size: 26,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           'Jma3a',
//           style: context.textTheme.titleLarge?.copyWith(
//             color: AppColors.navyBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _phoneFocus.unfocus();

    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = '+222$digits';

    final auth = context.read<AuthProvider>();
    final result = await auth.sendPhoneOtp(phone);

    if (!mounted) return;
    if (result.success) {
      context.push(
        RouteNames.authOtp,
        extra: (identifier: result.syntheticEmail ?? '', phoneNumber: phone),
      );
    } else {
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.errorUnexpected,
      );
    }
  }

  void _enterGuestMode() {
    context.read<AuthProvider>().enterGuestMode();
    context.go(RouteNames.offline);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                _BrandHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.15, end: 0),

                const SizedBox(height: 56),

                Text(
                  l10n.authWelcome,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  l10n.authTagline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '12345678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefix: Text(
                      '+222 ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    final digits =
                        v?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.isEmpty || digits.length < 8) {
                      return 'Enter your 8-digit Mauritanian number';
                    }
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: l10n.authSendOtp,
                    onPressed: _submit,
                    isLoading: auth.isSendingOtp,
                  ),
                ).animate(delay: 280.ms).fadeIn(),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.push(RouteNames.authEmail),
                    child: Text(
                      'Use email instead',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ).animate(delay: 310.ms).fadeIn(),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.or,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate(delay: 340.ms).fadeIn(),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _enterGuestMode,
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ).animate(delay: 380.ms).fadeIn(),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate(delay: 420.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.navyBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Jma3a',
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.navyBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
