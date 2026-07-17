class SimulationCancelledException implements Exception {
  const SimulationCancelledException();

  @override
  String toString() => 'Simulation cancelled';
}
