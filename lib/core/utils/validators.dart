import 'package:logisender/core/constants/app_constants.dart';

/// Validation utilities for form inputs throughout the application.
abstract final class Validators {
  /// Normalizes a phone number to E.164 format (e.g. `+14155550123`).
  ///
  /// Removes spaces, dashes, parentheses and dots. If the number does not
  /// start with `+`, it is added so Telegram receives a valid international
  /// number regardless of local formatting.
  static String normalizePhone(String value) {
    var cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final normalized = normalizePhone(value);
    if (!AppConstants.phoneRegex.hasMatch(normalized)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  static String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Code is required';
    }
    if (!AppConstants.codeRegex.hasMatch(value.trim())) {
      return 'Code must be 5-6 digits';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 4) {
      return 'Password is too short';
    }
    return null;
  }

  static String? validateApiId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API ID is required';
    }
    if (!AppConstants.apiIdRegex.hasMatch(value.trim())) {
      return 'API ID must be a number';
    }
    return null;
  }

  static String? validateApiHash(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API Hash is required';
    }
    if (!AppConstants.apiHashRegex.hasMatch(value.trim())) {
      return 'API Hash must be 32 hex characters';
    }
    return null;
  }

  static String? validateTemplateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Template name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
