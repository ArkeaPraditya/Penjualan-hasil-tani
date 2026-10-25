import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/product_filter.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../products/catalog_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CatalogProvider>();
    if (_controller.text != c.query) {
      _controller.value = TextEditingValue(text: c.query, selection: TextSelection.collapsed(offset: c.query.length));
    }
    final items = c.filtered;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: c.setQuery,
              decoration: InputDecoration(
                hintText: 'Cari nama produk',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: c.query.isEmpty
                    ? null
                    : IconButton(tooltip: 'Hapus pencarian', icon: const Icon(Icons.close), onPressed: () => c.setQuery('')),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SortOrder>(
            tooltip: 'Urutkan harga',
            icon: Icon(Icons.sort, color: c.sort == SortOrder.none ? AppColors.textSecondary : AppColors.primary),
            onSelected: c.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: SortOrder.none, child: Text('Urutan awal')),
              PopupMenuItem(value: SortOrder.priceAsc, child: Text('Harga: rendah ke tinggi')),
              PopupMenuItem(value: SortOrder.priceDesc, child: Text('Harga: tinggi ke rendah')),
            ],
          ),
        ]),
      ),
      SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            ChoiceChip(label: const Text('Semua'), selected: c.categoryId == null, onSelected: (_) => c.setCategory(null)),
            for (final cat in c.categories) ...[
              const SizedBox(width: 8),
              ChoiceChip(label: Text(cat.name), selected: c.categoryId == cat.id, onSelected: (_) => c.setCategory(cat.id)),
            ],
            const SizedBox(width: 8),
            FilterChip(label: const Text('Tersedia saja'), selected: c.onlyAvailable, onSelected: c.setOnlyAvailable),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Text('${items.length} produk', style: AppText.caption)),
          if (c.hasActiveFilter) TextButton(onPressed: c.clearFilters, child: const Text('Hapus filter')),
        ]),
      ),
      Expanded(
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
                ? ErrorRetry(message: c.error!, onRetry: c.reload)
                : items.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'Produk tidak ditemukan',
                        message: 'Coba kata kunci lain atau hapus filter yang aktif.',
                        actionLabel: c.hasActiveFilter ? 'Hapus filter' : null,
                        onAction: c.clearFilters,
                      )
                    : ProductGrid(products: items),
      ),
    ]);
  }
}
