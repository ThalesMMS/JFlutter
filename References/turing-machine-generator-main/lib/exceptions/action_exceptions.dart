class ActionParserException implements Exception {
  final String message;
  const ActionParserException(
      [this.message = "Failed to parse valid actions!"]);
}

class TapeOperationException implements Exception {
  final String message;
  const TapeOperationException(
      [this.message = "Tape is unable to comply with an invalid Action!"]);
}

class InvalidLookupException implements Exception {
  final String message;
  const InvalidLookupException(
      [this.message = "No Configuration-Action pair found to match input!"]);
}
