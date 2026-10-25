class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phone = RegExp(r'^(\+62|62|0)8[0-9]{8,12}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());
  static bool isPhone(String v) => _phone.hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''));

  static String? required(String? v, [String label = 'Kolom ini']) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? name(String? v) {
    final r = required(v, 'Nama');
    if (r != null) return r;
    return v!.trim().length < 3 ? 'Nama minimal 3 karakter' : null;
  }

  static String? emailOrPhone(String? v) {
    final r = required(v, 'Email atau nomor HP');
    if (r != null) return r;
    return (isEmail(v!) || isPhone(v)) ? null : 'Gunakan email yang valid atau nomor HP (contoh 08123456789)';
  }

  static String? phone(String? v) {
    final r = required(v, 'Nomor HP');
    if (r != null) return r;
    return isPhone(v!) ? null : 'Nomor HP tidak valid (contoh 08123456789)';
  }

  static String? password(String? v) {
    final r = required(v, 'Kata sandi');
    if (r != null) return r;
    if (v!.length < 8) return 'Kata sandi minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Kata sandi harus memuat huruf dan angka';
    }
    return null;
  }

  static String? address(String? v) {
    final r = required(v, 'Alamat');
    if (r != null) return r;
    return v!.trim().length < 10 ? 'Tulis alamat selengkapnya (minimal 10 karakter)' : null;
  }

  static String? positiveInt(String? v, String label, {bool allowZero = false}) {
    final r = required(v, label);
    if (r != null) return r;
    final n = int.tryParse(v!.trim());
    if (n == null) return '$label harus berupa angka bulat';
    if (n < 0 || (n == 0 && !allowZero)) return '$label tidak valid';
    return null;
  }
}
