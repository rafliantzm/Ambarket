class SellerDashboardStats {
  final int activeProductsCount;
  final int soldProductsCount;
  final int reservedProductsCount;
  final int pendingOrdersCount;
  final int paidOrdersCount;
  final int packedOrdersCount;
  final int shippedOrdersCount;
  final int completedOrdersCount;
  final int pendingOffersCount;
  final double averageRating;
  final int totalReviews;
  final double totalRevenueDummy;

  const SellerDashboardStats({
    this.activeProductsCount = 0,
    this.soldProductsCount = 0,
    this.reservedProductsCount = 0,
    this.pendingOrdersCount = 0,
    this.paidOrdersCount = 0,
    this.packedOrdersCount = 0,
    this.shippedOrdersCount = 0,
    this.completedOrdersCount = 0,
    this.pendingOffersCount = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalRevenueDummy = 0.0,
  });

  factory SellerDashboardStats.empty() {
    return const SellerDashboardStats();
  }
}
