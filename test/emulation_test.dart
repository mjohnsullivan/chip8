import "package:test/test.dart";
import 'package:chip8/chip8.dart';

void main() {
  test('emulator runs a single op program', () {
    final program = [0x6001]; // loads 0x1 into V0
    final chip8 = Chip8();
    chip8.loadProgram(program);
    chip8.run();
    expect(chip8.programCounter, 0x202);
    expect(chip8.registers.getUint8(0), 1);
  });

  test('emulator runs a multi op program', () {
    final program = [0x6001, 0x6102, 0x6203]; // loads 0x1 into V0
    final chip8 = Chip8();
    chip8.loadProgram(program);
    chip8.run();
    expect(chip8.programCounter, 0x206);
    expect(chip8.registers.getUint8(0), 1);
    expect(chip8.registers.getUint8(1), 2);
    expect(chip8.registers.getUint8(2), 3);
  });
}
