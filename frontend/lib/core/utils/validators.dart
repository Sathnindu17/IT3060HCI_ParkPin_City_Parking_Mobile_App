/// Form validators shared by every screen. Each returns null when valid.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v.trim())) return 'Enter a valid email, e.g. name@parkpin.lk';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Number between [min] and [max] (inclusive).
  static String? numberInRange(String? v, num min, num max, [String field = 'Value']) {
    final n = num.tryParse((v ?? '').trim());
    if (n == null) return '$field must be a number';
    if (n < min || n > max) return '$field must be between $min and $max';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 12) return 'Enter a valid phone number';
    return null;
  }
}
