import 'dart:math' as math;

/// Represents the state of a turtle for L-system rendering
class TurtleState {
  final double x;
  final double y;
  final double angle;
  final double stepSize;
  final double angleIncrement;
  final double pitch;
  final double roll;

  const TurtleState({
    required this.x,
    required this.y,
    required this.angle,
    required this.stepSize,
    required this.angleIncrement,
    this.pitch = 0.0,
    this.roll = 0.0,
  });

  /// Creates a new turtle state at the origin
  factory TurtleState.origin({
    double stepSize = 10.0,
    double angleIncrement = 90.0,
  }) {
    return TurtleState(
      x: 0.0,
      y: 0.0,
      angle: 0.0,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
    );
  }

  /// Moves the turtle forward by one step
  TurtleState moveForward() {
    final newX = x + stepSize * math.cos(angle * math.pi / 180);
    final newY = y + stepSize * math.sin(angle * math.pi / 180);
    
    return TurtleState(
      x: newX,
      y: newY,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Moves the turtle forward by a custom distance
  TurtleState moveForwardBy(double distance) {
    final newX = x + distance * math.cos(angle * math.pi / 180);
    final newY = y + distance * math.sin(angle * math.pi / 180);
    
    return TurtleState(
      x: newX,
      y: newY,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Turns the turtle left by the angle increment
  TurtleState turnLeft() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle + angleIncrement,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Turns the turtle right by the angle increment
  TurtleState turnRight() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle - angleIncrement,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Turns the turtle by a custom angle
  TurtleState turnBy(double angleDelta) {
    return TurtleState(
      x: x,
      y: y,
      angle: angle + angleDelta,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Turns the turtle 180 degrees
  TurtleState turn180() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle + 180.0,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Pitches the turtle up
  TurtleState pitchUp() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch + angleIncrement,
      roll: roll,
    );
  }

  /// Pitches the turtle down
  TurtleState pitchDown() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch - angleIncrement,
      roll: roll,
    );
  }

  /// Rolls the turtle left
  TurtleState rollLeft() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll + angleIncrement,
    );
  }

  /// Rolls the turtle right
  TurtleState rollRight() {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll - angleIncrement,
    );
  }

  /// Sets the turtle position
  TurtleState setPosition(double newX, double newY) {
    return TurtleState(
      x: newX,
      y: newY,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Sets the turtle angle
  TurtleState setAngle(double newAngle) {
    return TurtleState(
      x: x,
      y: y,
      angle: newAngle,
      stepSize: stepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Sets the step size
  TurtleState setStepSize(double newStepSize) {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: newStepSize,
      angleIncrement: angleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Sets the angle increment
  TurtleState setAngleIncrement(double newAngleIncrement) {
    return TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: stepSize,
      angleIncrement: newAngleIncrement,
      pitch: pitch,
      roll: roll,
    );
  }

  /// Calculates the distance to another turtle state
  double distanceTo(TurtleState other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the angle to another turtle state
  double angleTo(TurtleState other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Normalizes the angle to be between 0 and 360 degrees
  double get normalizedAngle {
    var normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  /// Normalizes the pitch to be between -90 and 90 degrees
  double get normalizedPitch {
    var normalized = pitch % 360;
    if (normalized > 180) normalized -= 360;
    if (normalized < -180) normalized += 360;
    return normalized.clamp(-90.0, 90.0);
  }

  /// Normalizes the roll to be between 0 and 360 degrees
  double get normalizedRoll {
    var normalized = roll % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  /// Creates a copy with updated properties
  TurtleState copyWith({
    double? x,
    double? y,
    double? angle,
    double? stepSize,
    double? angleIncrement,
    double? pitch,
    double? roll,
  }) {
    return TurtleState(
      x: x ?? this.x,
      y: y ?? this.y,
      angle: angle ?? this.angle,
      stepSize: stepSize ?? this.stepSize,
      angleIncrement: angleIncrement ?? this.angleIncrement,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TurtleState &&
        other.x == x &&
        other.y == y &&
        other.angle == angle &&
        other.stepSize == stepSize &&
        other.angleIncrement == angleIncrement &&
        other.pitch == pitch &&
        other.roll == roll;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, angle, stepSize, angleIncrement, pitch, roll);
  }

  @override
  String toString() {
    return 'TurtleState(x: $x, y: $y, angle: $angle, stepSize: $stepSize, angleIncrement: $angleIncrement, pitch: $pitch, roll: $roll)';
  }
}
