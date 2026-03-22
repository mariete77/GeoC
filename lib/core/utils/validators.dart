/// Validation utilities
class Validators {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  /// Returns true if password meets minimum requirements
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate display name
  static bool isValidDisplayName(String name) {
    return name.trim().isNotEmpty && name.length >= 2 && name.length <= 30;
  }

  /// Validate that string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
