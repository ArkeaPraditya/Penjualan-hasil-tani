/// Kesalahan yang pesannya aman dan layak ditampilkan langsung ke pengguna.
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
