import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class AppMoneyText extends StatelessWidget {
  final double amount;
  final double? originalAmount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const AppMoneyText({
    super.key,
    required this.amount,
    this.originalAmount,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (originalAmount != null && originalAmount! > amount)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(((originalAmount! - amount) / originalAmount!) * 100).round()}%',
                    style: TextStyle(
                      fontSize: fontSize * 0.65,
                      fontWeight: FontWeight.bold,
                      color: context.colors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currencyFormatter.format(originalAmount),
                  style: TextStyle(
                    fontSize: fontSize * 0.75,
                    color: context.colors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        Text(
          currencyFormatter.format(amount),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? context.colors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
