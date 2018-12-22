import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
  test('Chip8 has 35 opcodes, each two bytes in size', () {
    final chip8 = Chip8();
    expect(chip8.opcodes.lengthInBytes, 35 * 2);
  });
  test('Chip8 has 16 registers, each a byte in size', () {
    final chip8 = Chip8();
    expect(chip8.registers.lengthInBytes, 16);
  });
  test('Chip8 has 4k of memory', () {
    final chip8 = Chip8();
    expect(chip8.memory.lengthInBytes, 4096);
  });
  test('Chip8 has a display of 64*32 binary pixels', () {
    final chip8 = Chip8();
    expect(chip8.display.length, 64 * 32);
  });
  test('Chip8 has a stack', () {
    final chip8 = Chip8();
    chip8.push = 2;
    chip8.push = 4;
    expect(chip8.pop, 4);
    expect(chip8.pop, 2);
    expect(() => chip8.pop, throwsA(const TypeMatcher<RangeError>()));
  });
  test('Chip8 has a keypad with 16 keys', () {
    final chip8 = Chip8();
    expect(chip8.keypad.length, 16);
  });
}
