import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/widgets/secondary_button.dart';

/// "Login & Security" — credential management, 2FA/biometrics, supervisor
/// PIN, and active session review. Frontend-only: every toggle/action here
/// only updates local widget state, nothing is persisted or sent anywhere.
class SecurityLoginScreen extends StatefulWidget {
  const SecurityLoginScreen({super.key});

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _ActiveSession {
  final String device;
  final String location;
  final String status;
  final bool isThisDevice;
  final IconData icon;

  _ActiveSession({
    required this.device,
    required this.location,
    required this.status,
    required this.icon,
    this.isThisDevice = false,
  });
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  bool _twoFactorEnabled = true;
  bool _biometricEnabled = true;

  final List<_ActiveSession> _sessions = [
    _ActiveSession(
      device: 'Current Device',
      location: 'Laguna Branch Network',
      status: 'Active now',
      icon: Icons.smartphone_rounded,
      isThisDevice: true,
    ),
  ];

  void _updatePassword() {
    Navigator.of(context).pushNamed(AppRoutes.resetPassword);
  }

  Future<void> _changePin() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change 4-Digit PIN'),
        content: const Text(
          'This is a frontend-only demo — PIN changes are not persisted. '
          'In the full app, this dialog will collect and confirm a new '
          'supervisor PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _terminateOtherSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate all other sessions?'),
        content: const Text(
          'This app cannot remotely sign out other devices. Changing your '
          'password ends all other sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // The app cannot revoke other devices' sessions itself (that needs the
      // Firebase Admin SDK). Changing the password does end them, so say so
      // instead of claiming an action that did not happen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Other devices cannot be signed out from here. '
            'Change your password to end all other sessions.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Login & Security',
        showBack: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.shield_outlined, color: AppColors.darkBrown),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              '● Security Level: High',
                              style: AppTextStyles.labelLg.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'Laguna Mesh',
                                style: AppTextStyles.labelMd,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protected by Laguna Mesh 256-bit encryption across Calamba, Los Baños, and Santa Cruz nodes.',
                          style: AppTextStyles.bodyMd,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('CREDENTIAL MANAGEMENT', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, color: AppColors.darkBrown),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Change Password', style: AppTextStyles.titleMd),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Good', style: AppTextStyles.labelMd),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last changed 42 days ago. Use at least 8 characters with a mix of numbers and symbols.',
                    style: AppTextStyles.bodyMd,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _updatePassword,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Update Account Password',
                            style: AppTextStyles.labelLg.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('HARDWARE & FACTOR AUTHENTICATION', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.smartphone_rounded,
                    title: 'Two-Factor Authentication (2FA)',
                    subtitle:
                        'Requires 6-digit OTP via SMS / Authenticator App when logging into new POS or mobile devices.',
                    value: _twoFactorEnabled,
                    onChanged: (v) => setState(() => _twoFactorEnabled = v),
                  ),
                  const Divider(height: 1),
                  _ToggleRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Authentication',
                    subtitle:
                        'Quick biometric login (Fingerprint / Face ID) for Santa Cruz & Calamba counter POS.',
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pin_rounded, color: AppColors.darkBrown),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Supervisor PIN Code',
                                style: AppTextStyles.titleMd,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Required for refund approvals, product deletions, and drawer cash reconciliation.',
                          style: AppTextStyles.bodyMd,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Row(
                                children: List.generate(
                                  4,
                                  (i) => Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.darkBrown,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '4-Digit Manager PIN',
                                      style: AppTextStyles.bodySm,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Active',
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: _changePin,
                                child: const Text('Change PIN'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE SESSIONS & DEVICES', style: AppTextStyles.labelSm),
                Text(
                  '${_sessions.length} Terminal${_sessions.length == 1 ? '' : 's'} Online',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final s in _sessions) ...[
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(s.icon, color: AppColors.darkBrown),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        s.device,
                                        style: AppTextStyles.labelLg,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (s.isThisDevice) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'This Device',
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(s.location, style: AppTextStyles.bodySm),
                                Text(
                                  '● ${s.status}',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: s.isThisDevice
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            s.isThisDevice
                                ? Icons.lock_outline_rounded
                                : Icons.logout_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    if (s != _sessions.last) const Divider(height: 1),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SecondaryButton(
                      label: 'Terminate All Other Active Sessions',
                      icon: Icons.block_rounded,
                      onPressed: _sessions.length > 1
                          ? _terminateOtherSessions
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Melai Nuts Laguna Multi-Branch Security Protocol v4.2',
                style: AppTextStyles.bodySm,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.darkBrown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodyMd),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
