class SellerProductStats {
  final int totalProducts;
  final int activeProducts;
  final int reservedProducts;
  final int soldProducts;
  final int archivedProducts;
  final int hiddenProducts;
  final int rejectedProducts;

  SellerProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.reservedProducts,
    required this.soldProducts,
    required this.archivedProducts,
    required this.hiddenProducts,
    required this.rejectedProducts,
  });

  factory SellerProductStats.empty() {
    return SellerProductStats(
      totalProducts: 0,
      activeProducts: 0,
      reservedProducts: 0,
      soldProducts: 0,
      archivedProducts: 0,
      hiddenProducts: 0,
      rejectedProducts: 0,
    );
  }

  factory SellerProductStats.fromJson(Map<String, dynamic> json) {
    return SellerProductStats(
      totalProducts: json['totalProducts'] as int? ?? 0,
      activeProducts: json['activeProducts'] as int? ?? 0,
      reservedProducts: json['reservedProducts'] as int? ?? 0,
      soldProducts: json['soldProducts'] as int? ?? 0,
      archivedProducts: json['archivedProducts'] as int? ?? 0,
      hiddenProducts: json['hiddenProducts'] as int? ?? 0,
      rejectedProducts: json['rejectedProducts'] as int? ?? 0,
    );
  }
}
