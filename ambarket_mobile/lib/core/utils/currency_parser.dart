class CurrencyParser {
  /// Parses a string formatted as Rupiah (e.g., "15.000", "Rp 15.000", "1.500.000")
  /// into a pure integer (e.g., 15000, 1500000).
  /// If the input is empty or invalid, returns 0.
  static int parse(String? input) {
    if (input == null || input.trim().isEmpty) return 0;

    final digits = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final codeUnit = input.codeUnitAt(i);
      if (codeUnit >= 48 && codeUnit <= 57) {
        digits.writeCharCode(codeUnit);
      }
    }

    final value = digits.toString();
    if (value.isEmpty) return 0;

    return int.tryParse(value) ?? 0;
  }
}
