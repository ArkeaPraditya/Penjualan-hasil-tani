import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tab_provider.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screens.dart';
import 'order_detail_screen.dart';
import 'orders_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Masuk untuk melihat pesanan',
        message: 'Riwayat dan status pesanan tersimpan di akun Anda.',
        actionLabel: 'Masuk / Daftar',
        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(popOnSuccess: true))),
      );
    }
    final orders = context.watch<OrdersProvider>();
    if (orders.loading) return const Center(child: CircularProgressIndicator());
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(alignment: Alignment.centerLeft, child: Text('Pesanan Saya', style: AppText.title)),
        ),
        const TabBar(tabs: [Tab(text: 'Aktif'), Tab(text: 'Riwayat')]),
        Expanded(
          child: TabBarView(children: [
            _OrderList(
              orders: orders.active,
              empty: EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Belum ada pesanan aktif',
                message: 'Pesanan yang sedang diproses akan muncul di sini.',
                actionLabel: 'Mulai belanja',
                onAction: () => context.read<ShellTabProvider>().go(ShellTab.categories),
              ),
            ),
            const _OrderList(
              orders: null,
              empty: EmptyState(icon: Icons.history, title: 'Belum ada riwayat', message: 'Pesanan selesai atau dibatalkan akan tersimpan di sini.'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.empty});
  final List<Order>? orders; // null = ambil riwayat dari provider
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final list = orders ?? context.watch<OrdersProvider>().history;
    if (list.isEmpty) return empty;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => OrderCard(order: list[i]),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.sellerMode = false});
  final Order order;
  final bool sellerMode;

  @override
  Widget build(BuildContext context) {
    final summary = order.items.map((i) => '${i.name} x${i.quantity}').join(', ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id, sellerMode: sellerMode))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('#${order.orderNumber}', style: AppText.body.copyWith(fontWeight: FontWeight.w700))),
              StatusChip(order.status),
            ]),
            const SizedBox(height: 4),
            Text(formatDateTime(order.createdAt), style: AppText.caption),
            const SizedBox(height: 8),
            Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body),
            const SizedBox(height: 8),
            Text(formatRupiah(order.total), style: AppText.price),
          ]),
        ),
      ),
    );
  }
}
