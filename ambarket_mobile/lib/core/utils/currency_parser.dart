class CurrencyParser {
  /// Parses a string formatted as Rupiah (e.g., "15.000", "Rp 15.000", "1.500.000")
  /// into a pure integer (e.g., 15000, 1500000).
  /// If the input is empty or invalid, returns 0.
  static int parse(String? input) {
    if (input == null || input.trim().isEmpty) return 0;

    // Ambil semua digit angka saja
    final String digits = input.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return 0;

    return int.tryParse(digits) ?? 0;
  }
}
