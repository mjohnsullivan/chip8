import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
  test('Chip8 has 35 opcodes, each two bytes in size', () {
    final chip8 = Chip8();
    expect(chip8.opcodes.lengthInBytes, 35 * 2);
  });
  test('Chip8 has 16 registers, of two bytes in size', () {
    final chip8 = Chip8();
    expect(chip8.registers.lengthInBytes, 16 * 2);
  });
  test('Chip8 has 4k of memory', () {
    final chip8 = Chip8();
    expect(chip8.memory.lengthInBytes, 4096);
  });
  test('Chip8 has a display of 64*32 binary pixels', () {
    final chip8 = Chip8();
    expect(chip8.display.length, 64 * 32);
  });
  test('Chip8 has a stack 16 levels deep', () {
    final chip8 = Chip8();
    expect(chip8.stack.lengthInBytes, 16 * 2);
  });
  test('Chip8 has a keypad with 16 keys', () {
    final chip8 = Chip8();
    expect(chip8.keypad.lengthInBytes, 16);
  });
}
