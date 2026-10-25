import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../orders/order_detail_screen.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [if (n.unreadCount > 0) TextButton(onPressed: n.markAllRead, child: const Text('Tandai dibaca'))],
      ),
      body: n.items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'Belum ada notifikasi',
              message: 'Info pesanan Anda akan muncul di sini. Notifikasi hanya tampil di dalam aplikasi.',
            )
          : ListView.separated(
              itemCount: n.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = n.items[i];
                return ListTile(
                  tileColor: item.isRead ? null : AppColors.soft,
                  leading: Icon(item.isRead ? Icons.notifications_none : Icons.notifications_active, color: AppColors.primary),
                  title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700)),
                  subtitle: Text('${item.message}\n${formatDateTime(item.createdAt)}'),
                  isThreeLine: true,
                  onTap: () async {
                    await n.markRead(item);
                    if (item.orderId != null && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: item.orderId!)));
                    }
                  },
                );
              },
            ),
    );
  }
}
