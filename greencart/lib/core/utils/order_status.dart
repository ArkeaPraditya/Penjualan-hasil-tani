enum OrderStatus {
  pending('pending', 'Menunggu Konfirmasi'),
  processing('processing', 'Diproses'),
  packed('packed', 'Dikemas'),
  shipped('shipped', 'Dikirim'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan');

  const OrderStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static OrderStatus fromDb(String v) =>
      OrderStatus.values.firstWhere((s) => s.dbValue == v, orElse: () => OrderStatus.pending);

  bool get isActive => this != completed && this != cancelled;

  /// Tahapan normal untuk timeline (tanpa status dibatalkan).
  static const flow = [pending, processing, packed, shipped, completed];
}

class OrderStatusRules {
  /// Status berikutnya pada alur normal, atau null jika sudah final.
  static OrderStatus? next(OrderStatus s) {
    final i = OrderStatus.flow.indexOf(s);
    if (i < 0 || i == OrderStatus.flow.length - 1) return null;
    return OrderStatus.flow[i + 1];
  }

  /// Pembeli hanya dapat membatalkan saat menunggu konfirmasi.
  /// Penjual dapat membatalkan sebelum pesanan dikirim.
  static bool canCancel(OrderStatus s, {required bool bySeller}) {
    if (bySeller) return s == OrderStatus.pending || s == OrderStatus.processing || s == OrderStatus.packed;
    return s == OrderStatus.pending;
  }

  static bool isValidTransition(OrderStatus from, OrderStatus to, {required bool bySeller}) {
    if (to == OrderStatus.cancelled) return canCancel(from, bySeller: bySeller);
    return bySeller && next(from) == to;
  }
}
