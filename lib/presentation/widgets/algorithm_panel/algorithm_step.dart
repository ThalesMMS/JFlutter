class AlgorithmStep {
  final String title;
  final String description;
  final Map<String, dynamic>? data;

  const AlgorithmStep({
    required this.title,
    required this.description,
    this.data,
  });
}
