import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tab_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../checkout/checkout_screen.dart';
import 'cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.loading) return const Center(child: CircularProgressIndicator());
    if (cart.lines.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Keranjang masih kosong',
        message: 'Pilih sayur, buah, dan bumbu segar dari petani lokal.',
        actionLabel: 'Mulai belanja',
        onAction: () => context.read<ShellTabProvider>().go(ShellTab.categories),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Align(alignment: Alignment.centerLeft, child: Text('Keranjang (${cart.itemCount})', style: AppText.title)),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cart.lines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final l = cart.lines[i];
            final p = l.product;
            Future<void> change(int q) async {
              final err = await cart.setQuantity(p, q);
              if (err != null && context.mounted) showSnack(context, err, error: true);
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 72, height: 72, child: ProductImage(p.imageAssetPath))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      Text('${formatRupiah(p.price)}/${p.unit}', style: AppText.caption),
                      const SizedBox(height: 4),
                      Row(children: [
                        _Step(icon: Icons.remove, tooltip: 'Kurangi', onTap: () => change(l.quantity - 1)),
                        SizedBox(width: 36, child: Text('${l.quantity}', textAlign: TextAlign.center, style: AppText.section)),
                        _Step(icon: Icons.add, tooltip: 'Tambah', onTap: l.quantity < p.stock ? () => change(l.quantity + 1) : null),
                      ]),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    IconButton(
                      tooltip: 'Hapus ${p.name}',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        await cart.remove(p);
                        if (context.mounted) showSnack(context, '${p.name} dihapus dari keranjang');
                      },
                    ),
                    Text(formatRupiah(l.subtotal), style: AppText.price),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SummaryRow('Subtotal', formatRupiah(cart.subtotal)),
          SummaryRow('Ongkos kirim', cart.deliveryFee == 0 ? 'Gratis' : formatRupiah(cart.deliveryFee)),
          SummaryRow('Total', formatRupiah(cart.total), bold: true),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            child: const Text('Lanjut ke Checkout'),
          ),
        ]),
      ),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 40,
        height: 40,
        child: IconButton.outlined(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, size: 18)),
      );
}
