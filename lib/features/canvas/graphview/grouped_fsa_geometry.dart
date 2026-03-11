import 'package:flutter/material.dart';

const double kGroupedFsaLaneSpacing = 34.0;
const double kGroupedFsaLoopSpacing = 10.0;

double resolveGroupedFsaLaneOffset({
  required String fromId,
  required String toId,
  required bool hasOpposingTraffic,
  double spacing = kGroupedFsaLaneSpacing,
}) {
  if (!hasOpposingTraffic) {
    return 0.0;
  }
  return fromId.compareTo(toId) <= 0 ? -spacing : spacing;
}

Offset resolveGroupedFsaMidpoint(Offset fromCenter, Offset toCenter) {
  return Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );
}

Offset resolveGroupedFsaPerpendicular(Offset fromCenter, Offset toCenter) {
  final delta = toCenter - fromCenter;
  if (delta.distanceSquared == 0) {
    return const Offset(0, -1);
  }
  final perpendicular = Offset(-delta.dy, delta.dx);
  return perpendicular / perpendicular.distance;
}

Offset resolveGroupedFsaPairPerpendicular({
  required String fromId,
  required String toId,
  required Offset fromCenter,
  required Offset toCenter,
}) {
  if (fromId.compareTo(toId) <= 0) {
    return resolveGroupedFsaPerpendicular(fromCenter, toCenter);
  }
  return resolveGroupedFsaPerpendicular(toCenter, fromCenter);
}

Offset resolveGroupedFsaControlPoint({
  required String fromId,
  required String toId,
  required Offset fromCenter,
  required Offset toCenter,
  required bool hasOpposingTraffic,
  double spacing = kGroupedFsaLaneSpacing,
}) {
  final midpoint = resolveGroupedFsaMidpoint(fromCenter, toCenter);
  final perpendicular = resolveGroupedFsaPairPerpendicular(
    fromId: fromId,
    toId: toId,
    fromCenter: fromCenter,
    toCenter: toCenter,
  );
  final laneOffset = resolveGroupedFsaLaneOffset(
    fromId: fromId,
    toId: toId,
    hasOpposingTraffic: hasOpposingTraffic,
    spacing: spacing,
  );
  return midpoint + (perpendicular * laneOffset);
}

Offset resolveGroupedFsaLabelNormal({
  required String fromId,
  required String toId,
  required Offset fromCenter,
  required Offset toCenter,
  required double laneOffset,
}) {
  var normal = resolveGroupedFsaPairPerpendicular(
    fromId: fromId,
    toId: toId,
    fromCenter: fromCenter,
    toCenter: toCenter,
  );
  if (laneOffset == 0.0) {
    if (normal.dy > 0) {
      normal = -normal;
    }
    return normal;
  }
  return laneOffset < 0 ? -normal : normal;
}

double resolveGroupedFsaLoopExtraOffset(int groupedLoops) {
  return (groupedLoops > 0 ? groupedLoops - 1 : 0) * kGroupedFsaLoopSpacing;
}
