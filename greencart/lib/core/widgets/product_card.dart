import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../features/products/product_detail_screen.dart';
import '../utils/format.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id!))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: Stack(fit: StackFit.expand, children: [
              ProductImage(p.imageAssetPath),
              if (!p.isAvailable)
                Container(
                  color: const Color(0xAAFFFFFF),
                  alignment: Alignment.center,
                  child: const Text('Stok habis', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text('${formatRupiah(p.price)}/${p.unit}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.price),
                ),
                _AddButton(product: p),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final enabled = product.isAvailable;
    return Semantics(
      button: true,
      label: 'Tambah ${product.name} ke keranjang',
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          onPressed: enabled ? () => addToCart(context, product) : null,
          icon: Icon(Icons.add_circle, size: 30, color: enabled ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.shrinkWrap = false});
  final List<Product> products;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: shrinkWrap ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 8, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 245,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      );
}

/// Ikon kategori (Material Icons) berdasarkan kunci di database.
IconData categoryIcon(String key) => switch (key) {
      'veg' => Icons.eco_outlined,
      'fruit' => Icons.apple_outlined,
      'spice' => Icons.local_fire_department_outlined,
      _ => Icons.grain_outlined,
    };
