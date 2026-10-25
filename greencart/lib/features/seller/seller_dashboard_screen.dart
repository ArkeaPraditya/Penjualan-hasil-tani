import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../orders/orders_screen.dart';
import 'product_form_screen.dart';
import 'seller_provider.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SellerProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Penjual'),
          bottom: const TabBar(tabs: [Tab(text: 'Produk'), Tab(text: 'Pesanan Masuk')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Tambah produk'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _Stat('Produk', '${s.products.length}'),
              const SizedBox(width: 8),
              _Stat('Pesanan aktif', '${s.activeOrderCount}'),
              const SizedBox(width: 8),
              _Stat('Stok menipis', '${s.lowStockCount}'),
            ]),
          ),
          Expanded(
            child: TabBarView(children: [
              s.products.isEmpty
                  ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'Belum ada produk', message: 'Tambahkan produk pertama Anda.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: s.products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = s.products[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 60, height: 60, child: ProductImage(p.imageAssetPath))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${formatRupiah(p.price)}/${p.unit} • stok ${p.stock}', style: AppText.caption),
                                  Text(p.isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 12, color: p.isActive ? AppColors.primary : AppColors.textSecondary)),
                                ]),
                              ),
                              Switch(
                                value: p.isActive,
                                onChanged: (v) async {
                                  final err = await s.setActive(p, v);
                                  if (context.mounted && err != null) showSnack(context, err, error: true);
                                },
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
                                  } else {
                                    final ok = await confirmDialog(context, title: 'Hapus produk?', message: '${p.name} akan dihapus permanen. Riwayat pesanan lama tidak berubah.', confirmLabel: 'Hapus', destructive: true);
                                    if (!ok || !context.mounted) return;
                                    final err = await s.deleteProduct(p);
                                    if (context.mounted) showSnack(context, err ?? 'Produk dihapus', error: err != null);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Ubah harga / stok')),
                                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                ],
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
              s.incoming.isEmpty
                  ? const EmptyState(icon: Icons.inbox_outlined, title: 'Belum ada pesanan masuk', message: 'Pesanan untuk produk Anda akan muncul di sini.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: s.incoming.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => OrderCard(order: s.incoming[i], sellerMode: true),
                    ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
            Text(label, style: AppText.caption),
          ]),
        ),
      );
}
