class SellerWalletSummary {
  final double availableBalance;
  final double pendingBalance;
  final double totalEarning;
  final double completedOrderRevenue;
  final int withdrawalCount;
  final int pendingWithdrawalCount;

  SellerWalletSummary({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarning,
    required this.completedOrderRevenue,
    required this.withdrawalCount,
    required this.pendingWithdrawalCount,
  });

  factory SellerWalletSummary.empty() {
    return SellerWalletSummary(
      availableBalance: 0,
      pendingBalance: 0,
      totalEarning: 0,
      completedOrderRevenue: 0,
      withdrawalCount: 0,
      pendingWithdrawalCount: 0,
    );
  }

  factory SellerWalletSummary.fromJson(Map<String, dynamic> json) {
    return SellerWalletSummary(
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarning: (json['total_earning'] as num?)?.toDouble() ?? 0.0,
      completedOrderRevenue: (json['completed_order_revenue'] as num?)?.toDouble() ?? 0.0,
      withdrawalCount: (json['withdrawal_count'] as num?)?.toInt() ?? 0,
      pendingWithdrawalCount: (json['pending_withdrawal_count'] as num?)?.toInt() ?? 0,
    );
  }
}
