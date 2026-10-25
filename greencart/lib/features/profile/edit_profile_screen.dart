import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ui_helpers.dart';
import '../auth/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().user!.name);
  late final _id = TextEditingController(text: context.read<AuthProvider>().user!.emailOrPhone);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().updateProfile(_name.text, _id.text);
      if (!mounted) return;
      showSnack(context, 'Profil diperbarui');
      Navigator.pop(context);
    } on AppException catch (e) {
      showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Center(child: AvatarInitials(_name.text.isEmpty ? '?' : _name.text, size: 80)),
            const SizedBox(height: 20),
            TextFormField(controller: _name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Nama'), validator: Validators.name),
            const SizedBox(height: 14),
            TextFormField(controller: _id, decoration: const InputDecoration(labelText: 'Email atau nomor HP'), validator: Validators.emailOrPhone),
            const SizedBox(height: 20),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
          ]),
        ),
      );
}
