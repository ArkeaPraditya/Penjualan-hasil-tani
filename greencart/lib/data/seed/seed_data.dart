import 'package:sqflite/sqflite.dart';

import '../../core/utils/password_hasher.dart';

/// Data awal lokal. Akun demo (kata sandi: demo1234):
///  - arkea@greencart.demo  (pembeli)
///  - budi@greencart.demo   (penjual)
///  - siti@greencart.demo   (penjual)
class SeedData {
  static const demoPassword = 'demo1234';
  static const _img = 'assets/images/products/';

  static Future<void> insert(DatabaseExecutor d) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = PasswordHasher.hash(demoPassword);

    Future<int> user(String name, String login, String role) => d.insert('users', {
          'name': name,
          'email_or_phone': login,
          'password_hash': hash,
          'role': role,
          'created_at': now,
        });
    await user('Arkea Praditya', 'arkea@greencart.demo', 'buyer');
    final budi = await user('Budi Santoso', 'budi@greencart.demo', 'seller');
    final siti = await user('Siti Aminah', 'siti@greencart.demo', 'seller');

    const categories = [
      ('Sayuran', 'veg'),
      ('Buah-buahan', 'fruit'),
      ('Bumbu Dapur', 'spice'),
      ('Hasil Panen Lainnya', 'other'),
    ];
    for (var i = 0; i < categories.length; i++) {
      await d.insert('categories', {
        'id': i + 1,
        'name': categories[i].$1,
        'icon_key': categories[i].$2,
        'sort_order': i,
      });
    }

    // (nama, kategori, harga, satuan, stok, gambar, penjual, asal, deskripsi)
    final products = <List<Object>>[
      ['Selada Hijau', 1, 4000, 'ikat', 40, 'selada-hijau', budi, 'Lembang, Jawa Barat', 'Selada renyah untuk lalapan dan salad, dipanen pagi hari.'],
      ['Bayam', 1, 3000, 'ikat', 60, 'bayam', budi, 'Ungaran, Jawa Tengah', 'Bayam hijau segar untuk sayur bening dan tumisan.'],
      ['Kangkung', 1, 2500, 'ikat', 55, 'kangkung', siti, 'Ungaran, Jawa Tengah', 'Kangkung batang muda, cocok untuk tumis dan plecing.'],
      ['Sawi Hijau', 1, 3500, 'ikat', 45, 'sawi-hijau', siti, 'Bandungan, Jawa Tengah', 'Sawi hijau segar untuk sup, mi, dan tumisan.'],
      ['Wortel Lokal', 1, 5000, 'kg', 80, 'wortel', budi, 'Dieng, Jawa Tengah', 'Wortel manis dan renyah dari dataran tinggi.'],
      ['Tomat', 1, 6000, 'kg', 70, 'tomat', siti, 'Bandungan, Jawa Tengah', 'Tomat merah matang untuk sambal dan masakan harian.'],
      ['Kentang', 1, 14000, 'kg', 90, 'kentang', budi, 'Dieng, Jawa Tengah', 'Kentang granola untuk sup, goreng, dan perkedel.'],
      ['Pisang Raja', 2, 15000, 'sisir', 30, 'pisang', siti, 'Boyolali, Jawa Tengah', 'Pisang raja manis, matang pohon.'],
      ['Jeruk Pontianak', 2, 18000, 'kg', 50, 'jeruk', budi, 'Pontianak, Kalimantan Barat', 'Jeruk manis berair, kulit tipis.'],
      ['Pepaya California', 2, 9000, 'buah', 25, 'pepaya', siti, 'Magelang, Jawa Tengah', 'Pepaya matang dengan daging buah tebal dan manis.'],
      ['Cabai Merah', 3, 38000, 'kg', 35, 'cabai-merah', siti, 'Temanggung, Jawa Tengah', 'Cabai merah keriting segar, harga mengikuti pasar.'],
      ['Cabai Rawit', 3, 45000, 'kg', 0, 'cabai-rawit', budi, 'Temanggung, Jawa Tengah', 'Cabai rawit pedas. Stok sedang kosong.'],
      ['Bawang Merah', 3, 32000, 'kg', 60, 'bawang-merah', budi, 'Brebes, Jawa Tengah', 'Bawang merah kering, umbi padat.'],
      ['Jahe', 3, 22000, 'kg', 40, 'jahe', siti, 'Wonosobo, Jawa Tengah', 'Jahe segar untuk bumbu dan minuman hangat.'],
      ['Serai', 3, 3000, 'ikat', 50, 'serai', siti, 'Ungaran, Jawa Tengah', 'Serai segar beraroma kuat untuk soto dan tumisan.'],
      ['Jagung Manis', 4, 7000, 'kg', 45, 'jagung-manis', budi, 'Grobogan, Jawa Tengah', 'Jagung manis siap rebus atau bakar.'],
      ['Singkong', 4, 5000, 'kg', 65, 'singkong', siti, 'Wonogiri, Jawa Tengah', 'Singkong segar, empuk saat direbus.'],
      ['Telur Ayam Kampung', 4, 28000, 'kg', 20, 'telur-ayam', budi, 'Boyolali, Jawa Tengah', 'Telur ayam kampung dari peternak lokal.'],
    ];
    for (final r in products) {
      await d.insert('products', {
        'name': r[0],
        'category_id': r[1],
        'price': r[2],
        'unit': r[3],
        'stock': r[4],
        'image_asset_path': '$_img${r[5]}.png',
        'seller_id': r[6],
        'origin': r[7],
        'description': r[8],
        'is_active': 1,
      });
    }

    await d.insert('addresses', {
      'user_id': 1,
      'recipient_name': 'Arkea Praditya',
      'phone': '081234567890',
      'address_line': 'Jl. Melati No. 12, RT 03 RW 02',
      'area_note': 'Dekat pos ronda',
      'is_default': 1,
    });
  }
}
