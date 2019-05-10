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
  test('Chip8 XORs pixels to the display', () {
    final chip8 = Chip8();
    expect(chip8.display[0], false);
    // XOR 0 and 1
    chip8.draw(0, 0, true);
    expect(chip8.display[0], true);
    // XOR 1 and 0
    chip8.draw(0, 0, false);
    expect(chip8.display[0], true);
    // XOR 1 and 1
    chip8.draw(0, 0, true);
    expect(chip8.display[0], false);
    // XOR 0 and 0
    chip8.draw(0, 0, false);
    expect(chip8.display[0], false);
    // Test random pixels around the screen
    chip8.draw(0, 1, true);
    expect(chip8.display[64], true);
    chip8.draw(10, 10, true);
    expect(chip8.display[650], true);
    chip8.draw(63, 31, true);
    expect(chip8.display[2047], true);
    chip8.draw(64, 0, true); // nothing happens as this is out of bounds
    chip8.draw(0, 32, true); // nothing happens as this is out of bounds
  });
  test('Chip8 correctly loads a program', () {
    final program = [0x60, 0x01, 0x61, 0x02, 0x62, 0x03];
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x206);
    expect(chip8.memory.getUint16(0x200), 0x6001);
    expect(chip8.memory.getUint16(0x202), 0x6102);
    expect(chip8.memory.getUint16(0x204), 0x6203);
    expect(chip8.memory.getUint16(0x206), 0);
  });
}
