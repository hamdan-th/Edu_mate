class UserUtils {
  /// Extracts a "First Last" name from a full name string.
  static String deriveDisplayName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    return '${parts.first} ${parts.last}';
  }

  /// Resolves a user-facing name from a user data map.
  /// Handles legacy numeric usernames by falling back to First+Last from fullName.
  static String getDisplayName(Map<String, dynamic> data) {
    final username = (data['username'] ?? '').toString().trim();
    final fullName = (data['fullName'] ?? '').toString().trim();

    // Check if username is a raw numeric identifier (legacy)
    final isNumeric = RegExp(r'^\d+$').hasMatch(username);

    if (isNumeric) {
      if (fullName.isNotEmpty) {
        return deriveDisplayName(fullName);
      }
      return username; // last resort fall back to ID if no name
    }

    return username.isNotEmpty ? username : deriveDisplayName(fullName);
  }
}
