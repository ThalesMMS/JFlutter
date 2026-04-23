class AutomatonIdUtils {
  static int calculateNextAutomatonId(List<Map<String, dynamic>> states) {
    if (states.isEmpty) {
      return 0;
    }

    var highestId = -1;
    for (final state in states) {
      final id = state['id']?.toString() ?? '';
      final numericId = _extractNumericAutomatonId(id);
      if (numericId != null && numericId > highestId) {
        highestId = numericId;
      }
    }

    return highestId >= 0 ? highestId + 1 : states.length;
  }

  static int? _extractNumericAutomatonId(String id) {
    final numericId = int.tryParse(id);
    if (numericId != null) {
      return numericId;
    }

    final match = RegExp(r'(\d+)$').firstMatch(id);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
