import 'dart:io';

import 'package:test/test.dart';
import 'package:chip8/chip8.dart';

void main() {
  test('emulator runs a single op program', () {
    final program = [0x60, 0x01]; // loads 0x1 into V0
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 2);
    chip8.run();
    expect(chip8.programCounter, 0x202);
    expect(chip8.registers.getUint8(0), 1);
  });

  test('emulator runs a multi op program', () {
    final program = [0x60, 0x01, 0x61, 0x02, 0x62, 0x03]; // loads 0x1 into V0
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 6);
    chip8.run();
    expect(chip8.programCounter, 0x206);
    expect(chip8.registers.getUint8(0), 1);
    expect(chip8.registers.getUint8(1), 2);
    expect(chip8.registers.getUint8(2), 3);
  });

  test('emulator loads and runs a simple program correctly', () {
    final program = File('test/bin/simple.ch8').readAsBytesSync();
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 4);
    chip8.run();
  });

  /*
  // TODO: program never finishes, so put in a breaking mechanism
  test('emulator runs a sophisticated, binary program', () {
    final program = File('test/bin/ibm_logo.ch8').readAsBytesSync();
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 132);
    chip8.run();
  });
  */
}
