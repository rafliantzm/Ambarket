import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final selectionOffset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCursor = _countDigitsBefore(
      newValue.text,
      selectionOffset,
    );

    final digits = _onlyDigits(newValue.text);
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final newText = _formatRupiahDigits(digits);
    final newOffset = _offsetAfterDigitCount(newText, digitsBeforeCursor);

    if (newText == newValue.text &&
        newOffset == newValue.selection.extentOffset) {
      return newValue;
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  static String _onlyDigits(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (_isDigit(codeUnit)) {
        buffer.writeCharCode(codeUnit);
      }
    }

    final rawDigits = buffer.toString();
    var firstNonZero = 0;
    while (firstNonZero < rawDigits.length - 1 &&
        rawDigits.codeUnitAt(firstNonZero) == 48) {
      firstNonZero++;
    }
    return rawDigits.substring(firstNonZero);
  }

  static String _formatRupiahDigits(String digits) {
    final buffer = StringBuffer();
    final firstGroupLength = digits.length % 3 == 0 ? 3 : digits.length % 3;

    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (i - firstGroupLength) % 3 == 0) {
        buffer.write('.');
      }
      buffer.writeCharCode(digits.codeUnitAt(i));
    }

    return buffer.toString();
  }

  int _countDigitsBefore(String text, int offset) {
    var count = 0;
    final end = offset.clamp(0, text.length);
    for (var i = 0; i < end; i++) {
      if (_isDigit(text.codeUnitAt(i))) {
        count++;
      }
    }
    return count;
  }

  int _offsetAfterDigitCount(String text, int digitCount) {
    if (digitCount <= 0) return 0;

    var seenDigits = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text.codeUnitAt(i))) {
        seenDigits++;
        if (seenDigits == digitCount) {
          return i + 1;
        }
      }
    }

    return text.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
