import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.section),
            const SizedBox(height: 6),
            Text(body, style: AppText.body),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & Info')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        block('Tentang GreenCart', 'GreenCart (versi 1.0.0) menghubungkan pembeli dengan petani dan penjual pangan lokal. Dari Petani untuk Dapurmu.'),
        block('Cara berbelanja', '1. Cari atau pilih produk.\n2. Tambahkan ke keranjang.\n3. Checkout, isi alamat, lalu pilih metode pembayaran.\n4. Pantau status pesanan di tab Pesanan.'),
        block('Pembayaran', 'Pembayaran COD dan transfer bank pada versi ini hanyalah simulasi. Tidak ada uang yang diproses dan aplikasi tidak meminta PIN atau nomor kartu.'),
        block('Data & keamanan', 'Seluruh data (akun, keranjang, pesanan) disimpan di perangkat ini saja. Autentikasi lokal hanya untuk demo dan belum layak untuk produksi.'),
        block('Notifikasi', 'Notifikasi hanya tampil di dalam aplikasi. Push notification belum tersedia.'),
        block('Mode penjual', 'Mode penjual berbagi database dengan sisi pembeli di perangkat yang sama. Belum ada sinkronisasi antarperangkat. Akun demo: budi@greencart.demo / demo1234.'),
      ]),
    );
  }
}
