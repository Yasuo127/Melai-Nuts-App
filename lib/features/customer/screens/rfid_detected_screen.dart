import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/customer_data_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

/// "RFID Loyalty Card Detected" — confirmation shown right after a
/// (simulated) NFC tap. Every value below is the real signed-in customer's
/// own data (name, linked card number, real points balance) — there's no
/// physical NFC reader in this environment to simulate a genuine tap, but
/// nothing here is a stand-in stranger's fabricated profile.
class RfidDetectedScreen extends StatelessWidget {
  const RfidDetectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CustomerDataStore.instance,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final profile = CustomerDataStore.instance.profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : (AuthService.instance.currentProfile?.name ?? 'Customer');
    final cardNumber = profile?.rfidCardNumber;
    final points = CustomerDataStore.instance.pointsBalance;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Golden Kernel Club',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$points pts', style: AppTextStyles.labelMd.copyWith(color: AppColors.primaryDark)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.contactless_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'NFC Tap Confirmed',
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Loyalty Card Detected',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Matched to your Melai Nuts account.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Golden Kernel Member', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: Text('Verified Active', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(initials, style: AppTextStyles.titleMd.copyWith(color: AppColors.primaryDark)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTextStyles.titleMd),
                            Text(cardNumber ?? 'No physical card linked yet', style: AppTextStyles.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT LOYALTY BALANCE', style: AppTextStyles.labelSm),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.headlineLg.copyWith(color: AppColors.darkBrown),
                            children: [
                              TextSpan(text: '$points '),
                              TextSpan(text: 'Kernel Points', style: AppTextStyles.titleMd),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Redeem Rewards Now ($points pts available)',
              icon: Icons.card_giftcard_rounded,
              onPressed: () => Navigator.pushNamed(context, '/customer/loyalty/redeem'),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Back to Loyalty',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/customer/loyalty')),
            ),
          ],
        ),
      ),
    );
  }
}
