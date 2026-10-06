import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../../products/screens/product_management_screen.dart';
import '../widgets/branch_performance_card.dart';
import 'owner_dashboard_screen.dart';
import 'owner_profile_screen.dart';
import 'user_management_screen.dart';

/// Owner Executive Dashboard — Sales analytics, multi-branch comparisons,
/// product & pricing, user management, and profile (incl. Log Out) behind a
/// single bottom-navigation shell.
class OwnerPortalScreen extends StatefulWidget {
  const OwnerPortalScreen({super.key});

  @override
  State<OwnerPortalScreen> createState() => _OwnerPortalScreenState();
}

class _OwnerPortalScreenState extends State<OwnerPortalScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.roleOwner,
              child: Icon(Icons.insights_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner Dashboard', style: AppTextStyles.labelLg),
                Text('Laguna Enterprise Overview', style: AppTextStyles.bodySm),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          OwnerDashboardScreen(),
          _BranchComparisonTab(),
          _SystemLogsTab(),
          ProductManagementBody(),
          UserManagementBody(showAddButton: true),
          OwnerProfileBody(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.roleOwner.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          // Six tabs share the bar, so use a slightly smaller label to keep
          // "Dashboard" / "Branches" from clipping on narrow phones.
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final base = AppTextStyles.labelMd.copyWith(fontSize: 10.5, letterSpacing: 0);
            if (states.contains(WidgetState.selected)) {
              return base.copyWith(color: AppColors.roleOwner);
            }
            return base;
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.roleOwner),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.compare_arrows_rounded),
              selectedIcon: Icon(Icons.compare_arrows_rounded, color: AppColors.roleOwner),
              label: 'Branches',
            ),
            NavigationDestination(
              icon: Icon(Icons.security_rounded),
              selectedIcon: Icon(Icons.security_rounded, color: AppColors.roleOwner),
              label: 'Security',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.roleOwner),
              label: 'Products',
              tooltip: 'Product & Pricing Hub',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts_rounded, color: AppColors.roleOwner),
              label: 'Users',
              tooltip: 'Manage Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.roleOwner),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchComparisonTab extends StatelessWidget {
  const _BranchComparisonTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Branch Operations', style: AppTextStyles.headlineSm),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchComparison),
              child: const Text('Full Comparison'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final sales in kBranchSalesList)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BranchPerformanceCard(
              sales: sales,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchPerformance, arguments: sales.branch),
            ),
          ),
      ],
    );
  }
}

class _SystemLogsTab extends StatelessWidget {
  const _SystemLogsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Enterprise Audit Logs', style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        _buildLogTile('POS Login', 'Manager Elena (Calamba)', '10:24 AM'),
        _buildLogTile('Inventory Adjustment', 'Staff Juan (Santa Cruz)', '09:15 AM'),
        _buildLogTile('Price Update', 'System Automate (HQ)', '08:00 AM'),
      ],
    );
  }

  Widget _buildLogTile(String action, String user, String time) {
    return ListTile(
      leading: const Icon(Icons.history_toggle_off_rounded, size: 20),
      title: Text(action, style: AppTextStyles.labelLg),
      subtitle: Text(user, style: AppTextStyles.bodySm),
      trailing: Text(time, style: AppTextStyles.bodySm),
    );
  }
}