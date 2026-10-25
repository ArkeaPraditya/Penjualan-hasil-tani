import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/repositories/order_repository.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screens.dart';
import '../cart/cart_provider.dart';
import '../notifications/notifications_provider.dart';
import '../orders/order_detail_screen.dart';
import '../orders/orders_provider.dart';
import '../products/catalog_provider.dart';
import '../profile/address_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  String _payment = OrderRepository.paymentCod;
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  void _prefill(AuthProvider auth, AddressProvider addresses) {
    if (_prefilled || !auth.isLoggedIn) return;
    final a = addresses.defaultAddress;
    if (a != null) {
      _name.text = a.recipientName;
      _phone.text = a.phone;
      _address.text = a.addressLine;
      _prefilled = true;
    } else if (addresses.ownerId == auth.ownerId) {
      _name.text = auth.user!.name;
      if (Validators.isPhone(auth.user!.emailOrPhone)) _phone.text = auth.user!.emailOrPhone;
      _prefilled = true;
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final orders = context.read<OrdersProvider>();
    final ok = await confirmDialog(
      context,
      title: 'Konfirmasi pesanan',
      message: '${cart.itemCount} barang, total ${formatRupiah(cart.total)}.\n'
          'Pembayaran: $_payment (simulasi, tidak ada uang yang diproses).\n\nBuat pesanan sekarang?',
      confirmLabel: 'Buat Pesanan',
    );
    if (!ok || !mounted) return;
    final catalog = context.read<CatalogProvider>();
    final notifications = context.read<NotificationsProvider>();
    final result = await orders.checkout(
      recipientName: _name.text,
      phone: _phone.text,
      addressLine: _address.text,
      note: _note.text,
      paymentMethod: _payment,
    );
    await cart.reload();
    await catalog.reload(); // stok berubah
    await notifications.reload();
    if (!mounted) return;
    if (result.error != null) {
      showSnack(context, result.error!, error: true);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: result.order!.id, justCreated: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final addresses = context.watch<AddressProvider>();
    final submitting = context.select<OrdersProvider, bool>((o) => o.submitting);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Masuk untuk melanjutkan',
          message: 'Keranjang Anda aman. Masuk atau daftar agar pesanan tersimpan di akun.',
          actionLabel: 'Masuk / Daftar',
          onAction: () => Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen(popOnSuccess: true))),
        ),
      );
    }
    if (cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyState(icon: Icons.shopping_cart_outlined, title: 'Keranjang kosong', message: 'Tambahkan produk dulu sebelum checkout.'),
      );
    }
    _prefill(auth, addresses);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Alamat pengiriman', style: AppText.section),
          if (addresses.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final a in addresses.items)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(a.addressLine, overflow: TextOverflow.ellipsis),
                      onPressed: () => setState(() {
                        _name.text = a.recipientName;
                        _phone.text = a.phone;
                        _address.text = a.addressLine;
                      }),
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama penerima'), validator: Validators.name),
          const SizedBox(height: 10),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP'), validator: Validators.phone),
          const SizedBox(height: 10),
          TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat lengkap'), validator: Validators.address),
          const SizedBox(height: 10),
          TextFormField(controller: _note, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan pesanan (opsional)')),
          const SizedBox(height: 20),
          const Text('Metode pembayaran', style: AppText.section),
          const SizedBox(height: 8),
          for (final m in const [OrderRepository.paymentCod, OrderRepository.paymentTransfer])
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => setState(() => _payment = m),
                leading: Icon(m == _payment ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
                title: Text(m),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFAF1DC), borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Pembayaran pada versi ini hanya simulasi. Tidak ada transaksi uang sungguhan, dan aplikasi tidak pernah meminta PIN, kata sandi bank, atau nomor kartu.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Ringkasan', style: AppText.section),
          const SizedBox(height: 8),
          for (final l in cart.lines) SummaryRow('${l.product.name} x${l.quantity}', formatRupiah(l.subtotal)),
          const Divider(height: 20),
          SummaryRow('Subtotal', formatRupiah(cart.subtotal)),
          SummaryRow('Ongkos kirim', cart.deliveryFee == 0 ? 'Gratis' : formatRupiah(cart.deliveryFee)),
          SummaryRow('Total pembayaran', formatRupiah(cart.total), bold: true),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: submitting ? null : _submit,
            child: submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Buat Pesanan • ${formatRupiah(cart.total)}'),
          ),
        ),
      ),
    );
  }
}
