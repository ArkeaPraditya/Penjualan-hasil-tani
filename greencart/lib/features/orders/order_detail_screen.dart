import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/utils/order_status.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/models/models.dart';
import '../products/catalog_provider.dart';
import '../seller/seller_provider.dart';
import 'orders_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.sellerMode = false, this.justCreated = false});
  final int orderId;
  final bool sellerMode;
  final bool justCreated;

  @override
  Widget build(BuildContext context) {
    final Order? order = sellerMode
        ? context.watch<SellerProvider>().incoming.where((o) => o.id == orderId).firstOrNull
        : context.watch<OrdersProvider>().byId(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: const EmptyState(icon: Icons.receipt_long_outlined, title: 'Pesanan tidak ditemukan', message: 'Pesanan ini belum tersedia atau sudah dihapus.'),
      );
    }

    final next = OrderStatusRules.next(order.status);
    final canCancel = OrderStatusRules.canCancel(order.status, bySeller: sellerMode);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (justCreated)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.check_circle, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Pesanan berhasil dibuat dan tersimpan. Pembayaran hanya simulasi.')),
            ]),
          ),
        Row(children: [
          Expanded(child: Text('#${order.orderNumber}', style: AppText.title)),
          StatusChip(order.status),
        ]),
        Text(formatDateTime(order.createdAt), style: AppText.caption),
        const SizedBox(height: 16),
        _Timeline(order: order),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Barang', style: AppText.section),
              const SizedBox(height: 8),
              for (final i in order.items) SummaryRow('${i.name} (${formatRupiah(i.price)}/${i.unit}) x${i.quantity}', formatRupiah(i.subtotal)),
              const Divider(height: 20),
              SummaryRow('Subtotal', formatRupiah(order.subtotal)),
              SummaryRow('Ongkos kirim', order.deliveryFee == 0 ? 'Gratis' : formatRupiah(order.deliveryFee)),
              SummaryRow('Total', formatRupiah(order.total), bold: true),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pengiriman & pembayaran', style: AppText.section),
              const SizedBox(height: 8),
              Text('${order.recipientName} • ${order.phone}', style: AppText.body),
              Text(order.addressLine, style: AppText.body),
              if (order.note.isNotEmpty) Text('Catatan: ${order.note}', style: AppText.caption),
              const SizedBox(height: 8),
              Text(order.paymentMethod, style: AppText.body),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        if (sellerMode && next != null)
          FilledButton(
            onPressed: () async {
              final err = await context.read<SellerProvider>().advance(order, next);
              if (context.mounted) showSnack(context, err ?? 'Status diubah menjadi ${next.label}', error: err != null);
            },
            child: Text('Ubah ke "${next.label}"'),
          ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Batalkan pesanan?', message: 'Pesanan #${order.orderNumber} akan dibatalkan dan stok dikembalikan.', confirmLabel: 'Batalkan Pesanan', cancelLabel: 'Tidak', destructive: true);
              if (!ok || !context.mounted) return;
              final catalog = context.read<CatalogProvider>();
              final String? err = sellerMode
                  ? await context.read<SellerProvider>().advance(order, OrderStatus.cancelled)
                  : await context.read<OrdersProvider>().cancel(order);
              await catalog.reload();
              if (context.mounted) showSnack(context, err ?? 'Pesanan dibatalkan', error: err != null);
            },
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ]),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;
    final reachedIndex = cancelled ? -1 : OrderStatus.flow.indexOf(order.status);
    DateTime? timeOf(OrderStatus s) {
      for (final e in order.events) {
        if (e.status == s) return e.timestamp;
      }
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Status pesanan', style: AppText.section),
          const SizedBox(height: 8),
          if (cancelled)
            Row(children: [
              const Icon(Icons.cancel, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(child: Text('Dibatalkan • ${formatDateTime(timeOf(OrderStatus.cancelled) ?? order.createdAt)}', style: const TextStyle(color: AppColors.error))),
            ])
          else
            for (var i = 0; i < OrderStatus.flow.length; i++)
              _Step(
                label: OrderStatus.flow[i].label,
                time: timeOf(OrderStatus.flow[i]),
                done: i <= reachedIndex,
                current: i == reachedIndex,
                last: i == OrderStatus.flow.length - 1,
              ),
          const SizedBox(height: 4),
          const Text('Status diperbarui oleh penjual. Lokasi kurir tidak dilacak.', style: AppText.caption),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.time, required this.done, required this.current, required this.last});
  final String label;
  final DateTime? time;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 28,
            child: Column(children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: done ? AppColors.primary : AppColors.border),
              if (!last) Expanded(child: Container(width: 2, color: done ? AppColors.primary : AppColors.border)),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14, left: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: AppText.body.copyWith(fontWeight: current ? FontWeight.w700 : FontWeight.w400, color: done ? AppColors.text : AppColors.textSecondary)),
                if (time != null) Text(formatDateTime(time!), style: AppText.caption),
              ]),
            ),
          ),
        ]),
      );
}
