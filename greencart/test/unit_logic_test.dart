import 'package:flutter_test/flutter_test.dart';
import 'package:greencart/core/utils/format.dart';
import 'package:greencart/core/utils/order_status.dart';
import 'package:greencart/core/utils/password_hasher.dart';
import 'package:greencart/core/utils/pricing.dart';
import 'package:greencart/core/utils/product_filter.dart';
import 'package:greencart/core/utils/validators.dart';
import 'package:greencart/data/models/models.dart';

Product _p(String name, int cat, int price, int stock, {bool active = true}) => Product(
      id: name.hashCode,
      name: name,
      categoryId: cat,
      description: '',
      price: price,
      unit: 'kg',
      stock: stock,
      imageAssetPath: 'x',
      sellerId: 2,
      isActive: active,
    );

void main() {
  group('Validasi input akun', () {
    test('email dan nomor HP', () {
      expect(Validators.emailOrPhone('a@b.co'), isNull);
      expect(Validators.emailOrPhone('081234567890'), isNull);
      expect(Validators.emailOrPhone('abc'), isNotNull);
      expect(Validators.emailOrPhone(''), isNotNull);
    });
    test('kata sandi minimal 8 karakter, huruf dan angka', () {
      expect(Validators.password('abc123'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('abcd1234'), isNull);
    });
  });

  group('Pencarian dan filter', () {
    final all = [_p('Bayam', 1, 3000, 5), _p('Tomat', 1, 6000, 0), _p('Jeruk', 2, 18000, 9), _p('Jahe', 3, 22000, 2)];
    test('pencarian nama tidak peka huruf besar', () {
      expect(filterProducts(all, query: 'ba').map((e) => e.name), ['Bayam']);
    });
    test('filter kategori + hanya tersedia', () {
      expect(filterProducts(all, categoryId: 1, onlyAvailable: true).map((e) => e.name), ['Bayam']);
    });
    test('pengurutan harga', () {
      expect(filterProducts(all, sort: SortOrder.priceAsc).first.name, 'Bayam');
      expect(filterProducts(all, sort: SortOrder.priceDesc).first.name, 'Jahe');
    });
    test('tanpa hasil', () => expect(filterProducts(all, query: 'durian'), isEmpty));
  });

  group('Harga dan ongkos kirim', () {
    test('ongkir mengikuti kebijakan', () {
      expect(defaultDeliveryPolicy.feeFor(0), 0);
      expect(defaultDeliveryPolicy.feeFor(22000), 8000);
      expect(defaultDeliveryPolicy.feeFor(100000), 0);
    });
    test('kebijakan dapat dikonfigurasi', () {
      const p = DeliveryPolicy(baseFee: 5000, freeThreshold: 50000);
      expect(p.feeFor(49999), 5000);
      expect(p.feeFor(50000), 0);
    });
    test('format Rupiah', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(4000), 'Rp 4.000');
      expect(formatRupiah(1234567), 'Rp 1.234.567');
    });
    test('nomor pesanan', () => expect(buildOrderNumber(DateTime(2026, 10, 9), 12), 'GC20261009-0012'));
  });

  group('Transisi status pesanan', () {
    test('alur normal oleh penjual', () {
      expect(OrderStatusRules.next(OrderStatus.pending), OrderStatus.processing);
      expect(OrderStatusRules.next(OrderStatus.shipped), OrderStatus.completed);
      expect(OrderStatusRules.next(OrderStatus.completed), isNull);
      expect(OrderStatusRules.next(OrderStatus.cancelled), isNull);
    });
    test('pembeli hanya bisa membatalkan saat menunggu', () {
      expect(OrderStatusRules.canCancel(OrderStatus.pending, bySeller: false), isTrue);
      expect(OrderStatusRules.canCancel(OrderStatus.processing, bySeller: false), isFalse);
      expect(OrderStatusRules.canCancel(OrderStatus.packed, bySeller: true), isTrue);
      expect(OrderStatusRules.canCancel(OrderStatus.shipped, bySeller: true), isFalse);
    });
    test('tidak boleh melompat status', () {
      expect(OrderStatusRules.isValidTransition(OrderStatus.pending, OrderStatus.shipped, bySeller: true), isFalse);
      expect(OrderStatusRules.isValidTransition(OrderStatus.pending, OrderStatus.processing, bySeller: false), isFalse);
    });
  });

  test('hash kata sandi memakai salt dan dapat diverifikasi', () {
    final a = PasswordHasher.hash('rahasia123');
    final b = PasswordHasher.hash('rahasia123');
    expect(a, isNot(b));
    expect(a.contains('rahasia123'), isFalse);
    expect(PasswordHasher.verify('rahasia123', a), isTrue);
    expect(PasswordHasher.verify('salah1234', a), isFalse);
  });
}
