class StringUtils {
  StringUtils._();

  static bool isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static String orEmpty(String? value) => value ?? '';

  static String truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }
}
