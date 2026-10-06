/// Aggregated per-branch sales snapshot used across the Owner module.
/// Static/dummy — no backend.
class BranchSales {
  final String branch;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final int ordersToday;
  final int ordersWeek;
  final double yoyGrowthPercent;
  final double stockHealthPercent;
  final String topPerformer;
  final String leadContact;

  const BranchSales({
    required this.branch,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.ordersToday,
    required this.ordersWeek,
    required this.yoyGrowthPercent,
    required this.stockHealthPercent,
    required this.topPerformer,
    required this.leadContact,
  });

  double get avgOrderValue => ordersToday == 0 ? 0 : todayRevenue / ordersToday;
}

/// A single labeled point in a bar/trend chart (e.g. one day or one week).
class RevenuePoint {
  final String label;
  final double value;
  final bool isProjection;

  const RevenuePoint(this.label, this.value, {this.isProjection = false});
}

/// A restocking/demand insight surfaced on the Sales Forecast screen.
class RestockInsight {
  final String branch;
  final String productName;
  final String note;
  final int currentWeeklyRun;
  final int projectedDemand;
  final double growthPercent;
  final String recommendation;

  const RestockInsight({
    required this.branch,
    required this.productName,
    required this.note,
    required this.currentWeeklyRun,
    required this.projectedDemand,
    required this.growthPercent,
    required this.recommendation,
  });
}
