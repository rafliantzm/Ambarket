class SellerWithdrawalModel {
  final String id;
  final String sellerId;
  final double amount;
  final String status;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerWithdrawalModel({
    required this.id,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return SellerWithdrawalModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolder: json['account_holder'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
