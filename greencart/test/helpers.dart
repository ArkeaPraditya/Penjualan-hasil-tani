import 'package:greencart/data/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// ID seed: pembeli demo = 1, penjual Budi = 2, Siti = 3.
/// Produk: 1 Selada (4000/ikat, stok 40), 7 Kentang (14000/kg), 10 Pepaya (stok 25),
/// 11 Cabai Merah (38000/kg), 12 Cabai Rawit (stok 0).
void initFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<AppDatabase> openTestDb() => AppDatabase.open(path: inMemoryDatabasePath);
