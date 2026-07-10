class ReviewSummaryModel {
  final double averageRating;
  final int totalReviews;

  ReviewSummaryModel({required this.averageRating, required this.totalReviews});

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReviewSummaryModel(
      averageRating: double.parse(json['average_rating']?.toString() ?? '0'),
      totalReviews: int.parse(json['total_reviews']?.toString() ?? '0'),
    );
  }
}
