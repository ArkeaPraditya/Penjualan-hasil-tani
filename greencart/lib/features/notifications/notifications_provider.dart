import '../../core/state/owner_scoped_notifier.dart';
import '../../data/models/models.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsProvider extends OwnerScopedNotifier {
  NotificationsProvider(this._repo);
  final NotificationRepository _repo;

  List<AppNotification> items = const [];
  int get unreadCount => items.where((n) => !n.isRead).length;

  @override
  Future<void> reload() async {
    items = ownerId == 0 ? const [] : await _repo.list(ownerId);
    safeNotify();
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    await _repo.markRead(n.id);
    await reload();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead(ownerId);
    await reload();
  }
}
