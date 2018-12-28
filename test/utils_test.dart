import 'package:test/test.dart';
import 'package:chip8/utils.dart';

void main() {
  test('randomInt returns an int between two values', () {
    var result = randomInt(1);
    expect(result == 0 || result == 1, true);
    result = randomInt(10);
    expect(result >= 0 && result <= 10, true);
  });

  test('printBytes pretty prints bytes', () {
    var num = 0xAABBCCDD;
    expect(printBytes(num, 4), '0xAABBCCDD');
    num = 0x2F6D;
    expect(printBytes(num), '0x2F6D');
    num = 0x33DAB5;
    expect(printBytes(num, 3), '0x33DAB5');
  });
}
