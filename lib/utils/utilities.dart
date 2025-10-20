extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

String extractFirstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return "";
  // Normalize whitespace and split by spaces
  final parts = fullName.trim().split(RegExp(r'\s+'));
  // List of prefixes to ignore (case-insensitive, dots optional)
  const prefixes = {
    "mr", "mr.", "mrs", "mrs.", "ms", "ms.", "miss", "dr", "dr.", "shri", "smt", "smt."
  };
  // Skip prefixes, return the first valid name part
  for (final part in parts) {
    final cleaned = part.toLowerCase().replaceAll('.', '');
    if (!prefixes.contains(cleaned)) {
      return part; // first real name
    }
  }
  // Fallback to first part if nothing found
  return parts.first;
}