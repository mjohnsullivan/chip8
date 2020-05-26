import 'dart:math' as math;

int _previous = 0;

/// A cross-platform implementation for requesting the next animation frame.
///
/// Returns a [Future<num>] that completes as close as it can to the next
/// frame, given that it will attempt to be called 60 times per second (60 FPS)
/// by default - customize by setting the [target].
Future<num> nextFrame([num target = 60]) {
  final current = DateTime.now().millisecondsSinceEpoch;
  final call = math.max(0, (1000 ~/ target) - (current - _previous));
  return Future.delayed(
    Duration(milliseconds: call),
    () => _previous = DateTime.now().millisecondsSinceEpoch,
  );
}
