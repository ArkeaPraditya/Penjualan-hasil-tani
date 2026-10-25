import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/main_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/errors.dart';
import '../../core/utils/validators.dart';
import 'auth_provider.dart';

void _finish(BuildContext context, bool popOnSuccess) {
  if (popOnSuccess) {
    Navigator.pop(context, true);
  } else {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.popOnSuccess = false});

  /// true bila dibuka dari layar lain (mis. checkout) dan harus kembali setelah masuk.
  final bool popOnSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_id.text, _pw.text);
      if (mounted) _finish(context, widget.popOnSuccess);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.popOnSuccess ? AppBar() : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!widget.popOnSuccess) const SizedBox(height: 32),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/images/logo.png', width: 64, height: 64),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Selamat datang!', style: AppText.title, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Masuk untuk melanjutkan belanja', style: AppText.caption.copyWith(fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _id,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Email atau nomor HP', prefixIcon: Icon(Icons.person_outline)),
                  validator: Validators.emailOrPhone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pw,
                  obscureText: _hide,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hide ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) => Validators.required(v, 'Kata sandi'),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Masuk'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen(popOnSuccess: widget.popOnSuccess)),
                  ),
                  child: const Text('Buat akun baru'),
                ),
                if (!widget.popOnSuccess)
                  TextButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().continueAsGuest();
                      if (context.mounted) _finish(context, false);
                    },
                    child: const Text('Lanjutkan sebagai tamu'),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Mode demo: akun disimpan di perangkat ini saja.\n'
                    'Pembeli: arkea@greencart.demo\nPenjual: budi@greencart.demo\nKata sandi: demo1234',
                    style: TextStyle(fontSize: 12, color: AppColors.dark, height: 1.5),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.popOnSuccess = false});
  final bool popOnSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true;
  bool _seller = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(_name.text, _id.text, _pw.text, asSeller: _seller);
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      } else {
        _finish(context, false);
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Pendaftaran gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buat akun')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: Validators.name,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _id,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email atau nomor HP', prefixIcon: Icon(Icons.alternate_email)),
                  validator: Validators.emailOrPhone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pw,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    helperText: 'Minimal 8 karakter, kombinasi huruf dan angka',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hide ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _seller,
                  onChanged: (v) => setState(() => _seller = v),
                  title: const Text('Daftar sebagai petani / penjual'),
                  subtitle: const Text('Membuka Dashboard Penjual di profil'),
                ),
                if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Daftar'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Autentikasi ini hanya untuk demo lokal dan belum layak untuk produksi.',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ),
      );
}
