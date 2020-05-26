/// Code adapted from https://github.com/matanlurey/fps
/// See link for license and copyright

import 'dart:async';
import 'dart:math' as math show min;

import 'clock_native.dart' if (dart.library.html) 'clock_web.dart';

/// Returns a [Stream] that fires every [animationFrame].
///
/// May provide a function that returns a future completing in the next
/// available frame. For example in a browser environment this may be delegated
/// to `window.animationFrame`:
///
/// ```
/// eachFrame(animationFrame: () => window.animationFrame)
/// ```
Stream<num> eachFrame({Future<num> Function() animationFrame: nextFrame}) {
  StreamController<num> controller;
  var cancelled = false;
  void onNext(num timestamp) {
    if (cancelled) return;
    controller.add(timestamp);
    animationFrame().then(onNext);
  }

  controller = StreamController<num>(
    sync: true,
    onListen: () => animationFrame().then(onNext),
    onCancel: () => cancelled = true,
  );
  return controller.stream;
}

/// Computes frames-per-second given a [Stream<num>] of timestamps.
///
/// The resulting [Stream] is capped at reporting a maximum of 60 FPS.
///
/// ```
/// // Listens to FPS for 10 frames, and reports at FPS, printing to console.
/// eachFrame()
///   .take(10)
///   .transform(const ComputeFps())
///   .listen(print);
/// ```
class ComputeFps implements StreamTransformer<num, num> {
  final num _filterStrength;

  /// Create a transformer.
  ///
  /// Optionally specify a `filterStrength`, or how little to reflect temporary
  /// variations in FPS. A value of `1` will only keep the last value.
  const ComputeFps([this._filterStrength = 20]);

  @override
  Stream<num> bind(Stream<num> stream) {
    StreamController<num> controller;
    StreamSubscription<num> subscription;
    num frameTime = 0;
    num lastLoop;
    controller = StreamController<num>(
      sync: true,
      onListen: () {
        subscription = stream.listen((thisLoop) {
          if (lastLoop != null) {
            var thisFrameTime = thisLoop - lastLoop;
            frameTime += (thisFrameTime - frameTime) / _filterStrength;
            controller.add(math.min(1000 / frameTime, 60));
          }
          lastLoop = thisLoop;
        });
      },
      onCancel: () => subscription.cancel(),
    );
    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => this.cast<RS, RT>();
}
