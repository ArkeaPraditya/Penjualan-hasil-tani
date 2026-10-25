import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/models/models.dart';
import '../auth/auth_provider.dart';
import 'address_provider.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  Future<void> _edit(BuildContext context, [Address? a]) async {
    final userId = context.read<AuthProvider>().ownerId;
    final provider = context.read<AddressProvider>();
    final name = TextEditingController(text: a?.recipientName ?? context.read<AuthProvider>().user?.name ?? '');
    final phone = TextEditingController(text: a?.phone ?? '');
    final line = TextEditingController(text: a?.addressLine ?? '');
    final note = TextEditingController(text: a?.areaNote ?? '');
    final form = GlobalKey<FormState>();
    var isDefault = a?.isDefault ?? false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(a == null ? 'Tambah alamat' : 'Ubah alamat', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama penerima'), validator: Validators.name),
                const SizedBox(height: 10),
                TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP'), validator: Validators.phone),
                const SizedBox(height: 10),
                TextFormField(controller: line, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat lengkap'), validator: Validators.address),
                const SizedBox(height: 10),
                TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Patokan (opsional)')),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Jadikan alamat utama'), value: isDefault, onChanged: (v) => setSheet(() => isDefault = v)),
                FilledButton(
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    final err = await provider.save(Address(
                      id: a?.id,
                      userId: userId,
                      recipientName: name.text,
                      phone: phone.text,
                      addressLine: line.text,
                      areaNote: note.text,
                      isDefault: isDefault,
                    ));
                    if (!ctx.mounted) return;
                    if (err != null) {
                      showSnack(ctx, err, error: true);
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    line.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AddressProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Alamat Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah alamat'),
      ),
      body: p.items.isEmpty
          ? const EmptyState(icon: Icons.location_off_outlined, title: 'Belum ada alamat', message: 'Tambahkan alamat agar checkout lebih cepat.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: p.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = p.items[i];
                return Card(
                  child: ListTile(
                    title: Text('${a.recipientName}${a.isDefault ? '  • Utama' : ''}'),
                    subtitle: Text('${a.phone}\n${a.addressLine}${a.areaNote.isEmpty ? '' : '\n${a.areaNote}'}'),
                    isThreeLine: true,
                    onTap: () => _edit(context, a),
                    trailing: IconButton(
                      tooltip: 'Hapus alamat',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        final ok = await confirmDialog(context, title: 'Hapus alamat?', message: a.addressLine, confirmLabel: 'Hapus', destructive: true);
                        if (ok) await p.delete(a);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
