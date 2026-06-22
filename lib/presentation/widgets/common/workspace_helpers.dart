String formatCount(String singular, String plural, int count) {
  final label = count == 1 ? singular : plural;
  return '$count $label';
}
