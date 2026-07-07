class DummyWithdrawalInput {
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? note;

  DummyWithdrawalInput({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
