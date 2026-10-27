/// Form validators shared across features. Each returns an error message or
/// null when the value is valid, matching [FormField.validator].
abstract final class Validators {
  static String? required(String? value, [String label = 'This field']) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  /// Indian mobile numbers: 10 digits, optionally prefixed with +91.
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > 10000000) return 'Amount looks too large';
    return null;
  }
}
