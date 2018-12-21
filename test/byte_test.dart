import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
  test('mostSignificantNibble returns the most significant nibble from a word',
      () {
    expect(mostSignificantNibble(0x1234), 1);
    expect(mostSignificantNibble(0xABCD), 0xA);
    expect(mostSignificantNibble(0xFFFF), 0xF);
  });
  test(
      'secondSignificantNibble returns the 2nd most significant nibble from a word',
      () {
    expect(secondSignificantNibble(0x1234), 2);
    expect(secondSignificantNibble(0xABCD), 0xB);
    expect(secondSignificantNibble(0xFFFF), 0xF);
  });

  test(
      'thirdSignificantNibble returns the 3nd most significant nibble from a word',
      () {
    expect(thirdSignificantNibble(0x1234), 3);
    expect(thirdSignificantNibble(0xABCD), 0xC);
    expect(thirdSignificantNibble(0xFFFF), 0xF);
  });

  test('leastSignificantByte returns the least significant byte from a word',
      () {
    expect(leastSignificantByte(0x1234), 0x34);
    expect(leastSignificantByte(0xABCD), 0xCD);
    expect(leastSignificantByte(0xFFFF), 0xFF);
  });
  test(
      'leastSignificantNibble returns the least significant nibble from a word',
      () {
    expect(leastSignificantNibble(0x1234), 0x4);
    expect(leastSignificantNibble(0xABCD), 0xD);
    expect(leastSignificantNibble(0xFFFF), 0xF);
  });
}
