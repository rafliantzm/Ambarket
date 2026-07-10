import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/checkout_models.dart';

final shippingMethodsProvider = Provider<List<ShippingMethodModel>>((ref) {
  return [
    ShippingMethodModel(
      id: 'cod',
      name: 'Ambil Sendiri (COD)',
      description: 'Ketemuan langsung dengan penjual',
      cost: 0,
    ),
    ShippingMethodModel(
      id: 'regular',
      name: 'Reguler Dummy',
      description: 'Estimasi 2-4 hari',
      cost: 12000,
    ),
    ShippingMethodModel(
      id: 'instant',
      name: 'Instan Dummy',
      description: 'Estimasi 3 jam sampai',
      cost: 25000,
    ),
  ];
});

final paymentMethodsProvider = Provider<List<PaymentMethodModel>>((ref) {
  return [
    PaymentMethodModel(
      id: 'cod',
      name: 'Bayar di Tempat (COD)',
      description: 'Bayar saat bertemu penjual',
      type: 'cod',
    ),
    PaymentMethodModel(
      id: 'va_bca',
      name: 'BCA Virtual Account (Dummy)',
      description: 'Transfer otomatis via BCA',
      type: 'virtual_account',
    ),
    PaymentMethodModel(
      id: 'va_mandiri',
      name: 'Mandiri Virtual Account (Dummy)',
      description: 'Transfer otomatis via Mandiri',
      type: 'virtual_account',
    ),
    PaymentMethodModel(
      id: 'qris',
      name: 'QRIS (Dummy)',
      description: 'Bayar dengan aplikasi e-wallet apa saja',
      type: 'qris',
    ),
    PaymentMethodModel(
      id: 'gopay',
      name: 'GoPay (Dummy)',
      description: 'Bayar langsung pakai GoPay',
      type: 'e_wallet',
    ),
  ];
});
