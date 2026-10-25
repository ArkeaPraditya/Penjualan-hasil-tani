/// Aturan biaya pengiriman lokal yang dapat dikonfigurasi.
class DeliveryPolicy {
  const DeliveryPolicy({required this.baseFee, required this.freeThreshold});
  final int baseFee;
  final int freeThreshold;

  int feeFor(int subtotal) {
    if (subtotal <= 0) return 0;
    return subtotal >= freeThreshold ? 0 : baseFee;
  }
}

const defaultDeliveryPolicy = DeliveryPolicy(baseFee: 8000, freeThreshold: 100000);

String buildOrderNumber(DateTime date, int sequence) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'GC${date.year}${two(date.month)}${two(date.day)}-${sequence.toString().padLeft(4, '0')}';
}
