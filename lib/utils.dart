import 'dart:math';

/// Returns a random integer from 0 to max inclusive
int randomInt(int max) {
  final random = Random();
  return random.nextInt(max + 1);
}
