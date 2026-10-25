import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greencart/core/errors.dart';
import 'package:greencart/core/utils/order_status.dart';
import 'package:greencart/data/database/app_database.dart';
import 'package:greencart/data/models/models.dart';
import 'package:greencart/data/repositories/auth_repository.dart';
import 'package:greencart/data/repositories/cart_repository.dart';
import 'package:greencart/data/repositories/catalog_repository.dart';
import 'package:greencart/data/repositories/notification_repository.dart';
import 'package:greencart/data/repositories/order_repository.dart';
import 'package:greencart/features/orders/orders_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  initFfi();
  late AppDatabase app;
  late CartRepository cart;
  late CatalogRepository catalog;
  late OrderRepository orders;
  late NotificationRepository notifs;

  setUp(() async {
    app = await openTestDb();
    cart = CartRepository(app.db);
    catalog = CatalogRepository(app.db);
    orders = OrderRepository(app.db);
    notifs = NotificationRepository(app.db);
  });
  tearDown(() => app.close());

  Future<Product> prod(int id) async => (await catalog.getProduct(id))!;

  Future<Order> placeOrder({int userId = 1}) => orders.createOrder(
        userId: userId,
        recipientName: 'Arkea',
        phone: '081234567890',
        addressLine: 'Jl. Melati No. 12',
        note: '',
        paymentMethod: OrderRepository.paymentCod,
      );

  group('Autentikasi lokal', () {
    test('registrasi, login, dan penolakan kata sandi salah', () async {
      final auth = AuthRepository(app.db);
      final u = await auth.register(name: 'Dewi Lestari', emailOrPhone: 'dewi@mail.com', password: 'kebun2026');
      expect(u.passwordHashDemo.contains('kebun2026'), isFalse);
      expect((await auth.login('DEWI@mail.com', 'kebun2026')).id, u.id);
      expect(() => auth.login('dewi@mail.com', 'salah1234'), throwsA(isA<AppException>()));
      expect(() => auth.register(name: 'Dewi', emailOrPhone: 'dewi@mail.com', password: 'kebun2026'), throwsA(isA<AppException>()));
    });
  });

  group('Keranjang dan stok', () {
    test('menambah, mengubah kuantitas, menghapus', () async {
      await cart.add(1, await prod(1), quantity: 2);
      await cart.add(1, await prod(1));
      expect((await cart.lines(1)).single.quantity, 3);
      await cart.setQuantity(1, await prod(1), 5);
      expect((await cart.lines(1)).single.subtotal, 20000);
      await cart.setQuantity(1, await prod(1), 0);
      expect(await cart.lines(1), isEmpty);
    });
    test('tidak boleh melebihi stok atau menambah produk habis', () async {
      await expectLater(cart.add(1, await prod(1), quantity: 41), throwsA(isA<AppException>()));
      await expectLater(cart.add(1, await prod(12)), throwsA(isA<AppException>()));
    });
    test('keranjang tamu digabung saat masuk', () async {
      await cart.add(0, await prod(1), quantity: 2);
      await cart.mergeGuestCart(1);
      expect((await cart.lines(0)), isEmpty);
      expect((await cart.lines(1)).single.quantity, 2);
    });
  });

  group('Checkout', () {
    test('menghitung total, mengurangi stok, mengosongkan keranjang, membuat notifikasi', () async {
      await cart.add(1, await prod(1), quantity: 2); // 8.000
      await cart.add(1, await prod(7)); // 14.000
      final o = await placeOrder();
      expect(o.subtotal, 22000);
      expect(o.deliveryFee, 8000);
      expect(o.total, 30000);
      expect(o.orderNumber, matches(RegExp(r'^GC\d{8}-0001$')));
      expect(o.status, OrderStatus.pending);
      expect((await prod(1)).stock, 38);
      expect(await cart.lines(1), isEmpty);
      final n = await notifs.list(1);
      expect(n.single.title, 'Pesanan berhasil dibuat');
      expect(n.single.orderId, o.id);
    });
    test('gratis ongkir untuk belanja besar dan nomor pesanan berurutan', () async {
      await cart.add(1, await prod(11), quantity: 3); // 114.000
      final a = await placeOrder();
      expect(a.deliveryFee, 0);
      await cart.add(1, await prod(1));
      final b = await placeOrder();
      expect(b.orderNumber, endsWith('-0002'));
    });
    test('keranjang kosong ditolak', () => expectLater(placeOrder(), throwsA(isA<AppException>())));
    test('stok berubah sebelum checkout ditolak dan tidak ada pesanan tersimpan', () async {
      await cart.add(1, await prod(10), quantity: 20);
      await catalog.saveProduct((await prod(10)).copyWith(stock: 5));
      await expectLater(placeOrder(), throwsA(isA<AppException>()));
      expect(await orders.ordersForUser(1), isEmpty);
      expect((await prod(10)).stock, 5);
    });
    test('harga pada riwayat tidak berubah saat katalog berubah', () async {
      await cart.add(1, await prod(1), quantity: 2);
      final o = await placeOrder();
      await catalog.saveProduct((await prod(1)).copyWith(price: 9000));
      final again = (await orders.getOrder(o.id))!;
      expect(again.items.single.price, 4000);
      expect(again.total, o.total);
    });
    test('tombol ditekan berulang hanya membuat satu pesanan', () async {
      await cart.add(1, await prod(1));
      final provider = OrdersProvider(orders)..setOwner(1);
      Future<({Order? order, String? error})> go() => provider.checkout(
          recipientName: 'Arkea', phone: '081234567890', addressLine: 'Jl. Melati No. 12', note: '', paymentMethod: OrderRepository.paymentCod);
      final results = await Future.wait([go(), go(), go()]);
      expect(results.where((r) => r.order != null).length, 1);
      expect((await orders.ordersForUser(1)).length, 1);
    });
  });

  group('Status, pembatalan, dan notifikasi', () {
    test('penjual menjalankan alur penuh dan notifikasi pembeli sinkron', () async {
      await cart.add(1, await prod(1));
      final o = await placeOrder();
      for (final s in [OrderStatus.processing, OrderStatus.packed, OrderStatus.shipped, OrderStatus.completed]) {
        await orders.updateStatus(o.id, s, bySeller: true);
        expect((await orders.getOrder(o.id))!.status, s);
        expect((await notifs.list(1)).first.title, isNotEmpty);
      }
      final done = (await orders.getOrder(o.id))!;
      expect(done.events.map((e) => e.status), OrderStatus.flow);
      expect((await notifs.list(1)).length, 5);
      expect(() => orders.updateStatus(o.id, OrderStatus.cancelled, bySeller: true), throwsA(isA<AppException>()));
    });
    test('tidak boleh melompat status', () async {
      await cart.add(1, await prod(1));
      final o = await placeOrder();
      expect(() => orders.updateStatus(o.id, OrderStatus.shipped, bySeller: true), throwsA(isA<AppException>()));
    });
    test('pembatalan mengembalikan stok dan membuat notifikasi', () async {
      await cart.add(1, await prod(1), quantity: 4);
      final o = await placeOrder();
      expect((await prod(1)).stock, 36);
      await orders.updateStatus(o.id, OrderStatus.cancelled, bySeller: false);
      expect((await prod(1)).stock, 40);
      expect((await orders.getOrder(o.id))!.status, OrderStatus.cancelled);
      expect((await notifs.list(1)).first.title, 'Pesanan dibatalkan');
      expect(() => orders.updateStatus(o.id, OrderStatus.cancelled, bySeller: false), throwsA(isA<AppException>()));
    });
    test('pembeli tidak dapat membatalkan setelah diproses', () async {
      await cart.add(1, await prod(1));
      final o = await placeOrder();
      await orders.updateStatus(o.id, OrderStatus.processing, bySeller: true);
      expect(() => orders.updateStatus(o.id, OrderStatus.cancelled, bySeller: false), throwsA(isA<AppException>()));
    });
    test('penjual hanya melihat pesanan produknya', () async {
      await cart.add(1, await prod(1)); // Budi
      await placeOrder();
      expect((await orders.ordersForSeller(2)).length, 1);
      expect((await orders.ordersForSeller(3)), isEmpty);
    });
  });

  group('Penjual mengubah data yang dilihat pembeli', () {
    test('ubah harga, stok, dan nonaktifkan produk', () async {
      final p = await prod(1);
      await catalog.saveProduct(p.copyWith(price: 4500, stock: 12));
      expect((await prod(1)).price, 4500);
      await catalog.setActive(1, false);
      expect((await catalog.activeProducts()).any((e) => e.id == 1), isFalse);
    });
    test('validasi harga dan stok', () async {
      final p = await prod(1);
      expect(() => catalog.saveProduct(p.copyWith(price: 0)), throwsA(isA<AppException>()));
      expect(() => catalog.saveProduct(p.copyWith(stock: -1)), throwsA(isA<AppException>()));
    });
  });

  group('Persistensi', () {
    test('keranjang dan pesanan tetap ada setelah database dibuka ulang', () async {
      final dir = await Directory.systemTemp.createTemp('greencart_test');
      final path = '${dir.path}/gc.db';
      var a = await AppDatabase.open(path: path);
      var c = CartRepository(a.db);
      final cat = CatalogRepository(a.db);
      await c.add(1, (await cat.getProduct(1))!, quantity: 2);
      await c.add(1, (await cat.getProduct(7))!);
      await OrderRepository(a.db).createOrder(
          userId: 1, recipientName: 'Arkea', phone: '081234567890', addressLine: 'Jl. Melati No. 12', note: '', paymentMethod: OrderRepository.paymentCod);
      await c.add(1, (await cat.getProduct(5))!, quantity: 3);
      await a.close();

      a = await AppDatabase.open(path: path);
      c = CartRepository(a.db);
      expect((await c.lines(1)).single.quantity, 3);
      expect((await OrderRepository(a.db).ordersForUser(1)).single.total, 30000);
      await a.close();
      await dir.delete(recursive: true);
    });
    test('reset data demo mengembalikan kondisi awal', () async {
      await cart.add(1, await prod(1));
      await placeOrder();
      await app.resetDemoData();
      expect(await OrderRepository(app.db).ordersForUser(1), isEmpty);
      expect((await prod(1)).stock, 40);
    });
  });
}
