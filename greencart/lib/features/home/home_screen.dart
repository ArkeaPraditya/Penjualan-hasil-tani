import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tab_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../auth/auth_provider.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_screen.dart';
import '../products/catalog_provider.dart';
import '../profile/settings_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickArea(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Pilih area layanan', style: AppText.section)),
          for (final a in SettingsProvider.areas)
            ListTile(
              title: Text(a),
              trailing: a == settings.serviceArea ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(ctx, a),
            ),
        ]),
      ),
    );
    if (picked != null) settings.setArea(picked);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final name = context.select<AuthProvider, String?>((a) => a.user?.name);
    final area = context.select<SettingsProvider, String>((s) => s.serviceArea);
    final unread = context.select<NotificationsProvider, int>((n) => n.unreadCount);

    if (catalog.loading) return const Center(child: CircularProgressIndicator());
    if (catalog.error != null) return ErrorRetry(message: catalog.error!, onRetry: catalog.reload);

    final available = catalog.products.where((p) => p.isAvailable).toList();
    final featured = available.take(6).toList();
    final local = available.skip(6).take(8).toList();

    return RefreshIndicator(
      onRefresh: catalog.reload,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name == null ? 'Halo, Selamat Datang' : 'Halo, ${name.split(' ').first}', style: AppText.title),
              InkWell(
                onTap: () => _pickArea(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Kec. $area', style: AppText.caption.copyWith(fontSize: 13)),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                  ]),
                ),
              ),
            ]),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none)),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Cari sayur, buah, atau bumbu', prefixIcon: Icon(Icons.search)),
          onSubmitted: (q) {
            catalog.clearFilters();
            catalog.setQuery(q);
            context.read<ShellTabProvider>().go(ShellTab.categories);
          },
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Image.asset('assets/images/banner.png', height: 130, width: double.infinity, fit: BoxFit.cover),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Segar langsung\ndari petani', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Gratis ongkir untuk belanja di atas Rp 100.000', style: AppText.caption.copyWith(color: Colors.white70)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 84,
          child: Row(children: [
            for (final c in catalog.categories)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    catalog.clearFilters();
                    catalog.setCategory(c.id);
                    context.read<ShellTabProvider>().go(ShellTab.categories);
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
                      child: Icon(categoryIcon(c.iconKey), color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.2)),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        SectionHeader('Produk Pilihan', actionLabel: 'Lihat semua', onAction: () {
          catalog.clearFilters();
          context.read<ShellTabProvider>().go(ShellTab.categories);
        }),
        if (featured.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada produk tersedia.', textAlign: TextAlign.center))
        else
          ProductGrid(products: featured, shrinkWrap: true),
        if (local.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Segar dari Petani Lokal'),
          const SizedBox(height: 8),
          SizedBox(
            height: 245,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: local.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 170, child: ProductCard(product: local[i])),
            ),
          ),
        ],
      ]),
    );
  }
}
