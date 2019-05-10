import 'dart:math';

/// Returns a random integer from 0 to max inclusive
int randomInt(int max) => Random().nextInt(max + 1);

/// Pretty prints the last 4 bytes of an int
String printBytes(int num, [int numBytes = 2]) {
  final buffer = <String>[];
  for (int i = 0; i < numBytes; i++) {
    final byte = (num >> (i * 8)) & 0xFF;
    var byteStr = byte.toRadixString(16).toUpperCase();
    if (byteStr.length == 1) {
      byteStr = '0' + byteStr;
    }
    buffer.insert(0, '$byteStr');
  }
  buffer.insert(0, '0x');
  return buffer.join('');
}

/// Pads a string with whitespace to a specified size
String pad(String str, int size) =>
    (str.length > size) ? str.substring(0, size) : str.padRight(size);
