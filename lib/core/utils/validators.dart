class Validators {
  static String? requiredField(String? value, {String name = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) return '$name مطلوب';
    return null;
  }

  static String? positiveNumber(String? value, {String name = 'القيمة'}) {
    final n = double.tryParse(value ?? '');
    if (n == null || n < 0) return '$name يجب أن تكون رقمًا موجبًا';
    return null;
  }
}
