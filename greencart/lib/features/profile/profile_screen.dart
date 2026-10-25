import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tab_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/database/app_database.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screens.dart';
import '../cart/cart_provider.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_screen.dart';
import '../products/catalog_provider.dart';
import '../seller/seller_dashboard_screen.dart';
import 'addresses_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _resetDemo(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Reset data demo?',
      message: 'Semua akun, keranjang, alamat, pesanan, dan notifikasi di perangkat ini akan dihapus lalu diisi ulang dengan data awal.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final db = context.read<AppDatabase>();
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final catalog = context.read<CatalogProvider>();
    final cart = context.read<CartProvider>();
    final notifications = context.read<NotificationsProvider>();
    final nav = Navigator.of(context);
    final tab = context.read<ShellTabProvider>();
    try {
      await db.resetDemoData();
      await auth.handleDataReset();
      await settings.clear();
      await catalog.reload();
      await cart.reload();
      await notifications.reload();
      tab.go(ShellTab.home);
      nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Reset gagal. Coba lagi.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final unread = context.select<NotificationsProvider, int>((n) => n.unreadCount);

    Widget item(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) => ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: onTap,
        );
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            AvatarInitials(user?.name ?? 'Tamu'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? 'Tamu', style: AppText.title),
                Text(user?.emailOrPhone ?? 'Masuk untuk menyimpan pesanan', style: AppText.caption),
                if (user?.isSeller == true) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Petani / Penjual', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (!auth.isLoggedIn)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton(onPressed: () => open(const LoginScreen(popOnSuccess: true)), child: const Text('Masuk / Daftar')),
        ),
      Card(
        child: Column(children: [
          if (auth.isLoggedIn) ...[
            item(Icons.person_outline, 'Edit Profil', () => open(const EditProfileScreen())),
            item(Icons.receipt_long_outlined, 'Pesanan Saya', () => context.read<ShellTabProvider>().go(ShellTab.orders)),
            item(Icons.location_on_outlined, 'Alamat Saya', () => open(const AddressesScreen())),
            item(Icons.notifications_none, 'Notifikasi', () => open(const NotificationsScreen()),
                trailing: unread > 0 ? Badge(label: Text('$unread')) : null),
            if (user!.isSeller) item(Icons.storefront_outlined, 'Dashboard Penjual', () => open(const SellerDashboardScreen())),
          ],
          item(Icons.help_outline, 'Bantuan & Info Aplikasi', () => open(const HelpScreen())),
          item(Icons.restart_alt, 'Reset Data Demo', () => _resetDemo(context)),
        ]),
      ),
      if (auth.isLoggedIn) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
          onPressed: () async {
            final ok = await confirmDialog(context, title: 'Keluar dari akun?', message: 'Data Anda tetap tersimpan di perangkat ini.', confirmLabel: 'Keluar');
            if (!ok || !context.mounted) return;
            final tab = context.read<ShellTabProvider>();
            final nav = Navigator.of(context);
            await auth.logout();
            tab.go(ShellTab.home);
            nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
        ),
      ],
    ]);
  }
}
