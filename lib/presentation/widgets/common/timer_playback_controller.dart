import 'dart:async';

Timer? cancelPlaybackTimer(Timer? timer) {
  timer?.cancel();
  return null;
}

Timer? schedulePlaybackStep({
  required Timer? currentTimer,
  required bool Function() isPlaying,
  required bool Function() isMounted,
  required bool Function() canAdvance,
  required Duration delay,
  required void Function() clearTimer,
  required void Function() advance,
  required void Function() stop,
  required void Function() scheduleNext,
}) {
  currentTimer?.cancel();

  if (!isPlaying() || !isMounted()) return null;

  if (!canAdvance()) {
    stop();
    return null;
  }

  return Timer(delay, () {
    clearTimer();

    if (!isPlaying() || !isMounted()) return;

    if (canAdvance()) {
      advance();
      scheduleNext();
    } else {
      stop();
    }
  });
}
