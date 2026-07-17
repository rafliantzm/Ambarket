import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambarket_mobile/core/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    test('keeps cursor near edited middle digit', () {
      final formatter = CurrencyInputFormatter();

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1.200.000',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '1.000.000',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      expect(result.text, '1.000.000');
      expect(result.selection.extentOffset, 3);
    });

    test('keeps cursor at the end when appending digits', () {
      final formatter = CurrencyInputFormatter();

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12.000',
          selection: TextSelection.collapsed(offset: 6),
        ),
        const TextEditingValue(
          text: '12.0000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );

      expect(result.text, '120.000');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('keeps cursor stable when deleting a middle digit', () {
      final formatter = CurrencyInputFormatter();

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1.200.000',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '1.00.000',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );

      expect(result.text, '100.000');
      expect(result.selection.extentOffset, 1);
    });

    test(
      'accepts text with rupiah prefix without moving cursor to the end',
      () {
        final formatter = CurrencyInputFormatter();

        final result = formatter.formatEditUpdate(
          const TextEditingValue(
            text: 'Rp 12.000',
            selection: TextSelection.collapsed(offset: 6),
          ),
          const TextEditingValue(
            text: 'Rp 10.000',
            selection: TextSelection.collapsed(offset: 6),
          ),
        );

        expect(result.text, '10.000');
        expect(result.selection.extentOffset, 2);
      },
    );
  });
}
