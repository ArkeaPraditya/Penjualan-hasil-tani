import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../cart/cart_provider.dart';
import 'catalog_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = context.watch<CatalogProvider>().byId(widget.productId);
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(widget.productId));
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.inventory_2_outlined, title: 'Produk tidak tersedia', message: 'Produk ini sudah tidak dijual.'),
      );
    }
    final remaining = product.stock - inCart; // sisa yang masih boleh ditambah
    final maxQty = remaining < 1 ? 1 : remaining;
    final qty = _qty.clamp(1, maxQty).toInt();
    final canAdd = product.isAvailable && remaining > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ListView(children: [
        AspectRatio(aspectRatio: 1.4, child: ProductImage(product.imageAssetPath)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: AppText.title),
            const SizedBox(height: 4),
            Text('${formatRupiah(product.price)} / ${product.unit}', style: AppText.price.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              product.isAvailable ? 'Stok tersedia: ${product.stock} ${product.unit}' : 'Stok habis',
              style: TextStyle(color: product.isAvailable ? AppColors.primary : AppColors.error, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(product.description, style: AppText.body),
            const SizedBox(height: 16),
            Card(
              child: Column(children: [
                ListTile(leading: const Icon(Icons.agriculture_outlined, color: AppColors.primary), title: const Text('Petani / penjual'), subtitle: Text(product.sellerName)),
                if (product.origin.isNotEmpty)
                  ListTile(leading: const Icon(Icons.place_outlined, color: AppColors.primary), title: const Text('Asal produk'), subtitle: Text(product.origin)),
              ]),
            ),
            if (inCart > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Sudah ada $inCart ${product.unit} di keranjang.', style: AppText.caption),
              ),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                IconButton(
                  tooltip: 'Kurangi jumlah',
                  onPressed: canAdd && qty > 1 ? () => setState(() => _qty = qty - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center, style: AppText.section)),
                IconButton(
                  tooltip: 'Tambah jumlah',
                  onPressed: canAdd && qty < maxQty ? () => setState(() => _qty = qty + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: canAdd
                    ? () async {
                        await addToCart(context, product, quantity: qty);
                        if (mounted) setState(() => _qty = 1);
                      }
                    : null,
                child: Text(!product.isAvailable ? 'Stok habis' : remaining <= 0 ? 'Stok maksimal di keranjang' : 'Tambah ke Keranjang'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
