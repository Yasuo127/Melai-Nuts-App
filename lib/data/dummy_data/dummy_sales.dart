import '../models/sales_data.dart';

/// One category's share of revenue, used by the Owner analytics screens.
class CategoryRevenue {
  final String categoryId;
  final double revenue;
  final double marginPercent;

  const CategoryRevenue({
    required this.categoryId,
    required this.revenue,
    required this.marginPercent,
  });
}

/// One week's performance snapshot, used by the Sales Trends breakdown.
class WeeklyBreakdown {
  final String label; // e.g. "W1"
  final String dateRange; // e.g. "Sep 1 - Sep 7"
  final int orders;
  final double revenue;
  final double growthPercent;

  const WeeklyBreakdown({
    required this.label,
    required this.dateRange,
    required this.orders,
    required this.revenue,
    required this.growthPercent,
  });
}

/// Real per-branch sales figures — starts empty until connected to a
/// backend.
const List<BranchSales> kBranchSalesList = <BranchSales>[];

double get todaysGrossSales =>
    kBranchSalesList.fold<double>(0, (sum, b) => sum + b.todayRevenue);

int get todaysOrderCount =>
    kBranchSalesList.fold<int>(0, (sum, b) => sum + b.ordersToday);

double get weekGrossSales =>
    kBranchSalesList.fold<double>(0, (sum, b) => sum + b.weekRevenue);

int get weekOrderCount =>
    kBranchSalesList.fold<int>(0, (sum, b) => sum + b.ordersWeek);

double get monthGrossSales =>
    kBranchSalesList.fold<double>(0, (sum, b) => sum + b.monthRevenue);

/// Returns sales figures for [branch], or a zeroed-out placeholder if no
/// sales data exists yet for that branch (never crashes on an empty list).
BranchSales findBranchSales(String branch) {
  return kBranchSalesList.firstWhere(
    (b) => b.branch == branch,
    orElse: () => BranchSales(
      branch: branch,
      todayRevenue: 0,
      weekRevenue: 0,
      monthRevenue: 0,
      ordersToday: 0,
      ordersWeek: 0,
      yoyGrowthPercent: 0,
      stockHealthPercent: 0,
      topPerformer: '—',
      leadContact: '—',
    ),
  );
}

final List<CategoryRevenue> categoryRevenueBreakdown = <CategoryRevenue>[];

const List<RevenuePoint> kWeeklyRevenueSeries = <RevenuePoint>[];

const List<RevenuePoint> kMonthlyRevenueSeries = <RevenuePoint>[];

const List<WeeklyBreakdown> kWeeklyBreakdown = <WeeklyBreakdown>[];

// --- Sales Forecast (simulated simple linear regression) -----------------
// All zeroed out until there is enough real sales history to project from.

const double kForecastNextMonthTotal = 0;
const double kForecastRangeLow = 0;
const double kForecastRangeHigh = 0;
const double kForecastConfidenceR2 = 0;
const double kForecastGrowthPercent = 0;

const List<RevenuePoint> kForecastTrajectory = <RevenuePoint>[];

const List<RestockInsight> kRestockInsights = <RestockInsight>[];
