import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/product_images.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/models/models.dart';
import '../auth/auth_provider.dart';
import '../products/catalog_provider.dart';
import 'seller_provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(text: widget.product?.price.toString());
  late final _unit = TextEditingController(text: widget.product?.unit ?? 'kg');
  late final _stock = TextEditingController(text: widget.product?.stock.toString());
  late final _origin = TextEditingController(text: widget.product?.origin);
  late final _desc = TextEditingController(text: widget.product?.description);
  late int _category = widget.product?.categoryId ?? 1;
  late String _image = widget.product?.imageAssetPath ?? productImagePath(productImageAssets.first);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _price, _unit, _stock, _origin, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final seller = context.read<SellerProvider>();
    final base = widget.product;
    final p = Product(
      id: base?.id,
      name: _name.text.trim(),
      categoryId: _category,
      description: _desc.text.trim(),
      price: int.parse(_price.text.trim()),
      unit: _unit.text.trim(),
      stock: int.parse(_stock.text.trim()),
      imageAssetPath: _image,
      sellerId: context.read<AuthProvider>().ownerId,
      origin: _origin.text.trim(),
      isActive: base?.isActive ?? true,
    );
    final err = await seller.saveProduct(p);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, error: true);
    } else {
      showSnack(context, 'Produk disimpan');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Tambah Produk' : 'Ubah Produk')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama produk'), validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final c in categories) ChoiceChip(label: Text(c.name), selected: _category == c.id, onSelected: (_) => setState(() => _category = c.id)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)'), validator: (v) => Validators.positiveInt(v, 'Harga'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Satuan'), validator: (v) => Validators.required(v, 'Satuan'))),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok'), validator: (v) => Validators.positiveInt(v, 'Stok', allowZero: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _origin, decoration: const InputDecoration(labelText: 'Asal produk (opsional)')),
          const SizedBox(height: 12),
          TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi singkat'), validator: (v) => Validators.required(v, 'Deskripsi')),
          const SizedBox(height: 16),
          const Text('Gambar produk', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: productImageAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final path = productImagePath(productImageAssets[i]);
                final selected = path == _image;
                return InkWell(
                  onTap: () => setState(() => _image = path),
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2.5 : 1),
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: ProductImage(path)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan Produk')),
        ]),
      ),
    );
  }
}
