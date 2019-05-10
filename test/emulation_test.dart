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

  test('emulator handle a jumps correctly', () {
    final program = [
      0x60, 0x01, // puts 1 in V0
      0x12, 0x06, // jumps to 0x206
      0x70, 0x01, // adds one to V0 (should be skipped)
      0x70, 0x01, // adds another one to V0
    ];
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 8);
    chip8.run();
    expect(chip8.programCounter, 0x208);
    expect(chip8.registers.getUint8(0), 2);
  });

  test('emulator handles suroutines correctly', () {
    final program = [
      0x60, 0x01, // puts 1 in V0                     // 200
      0x22, 0x0A, // calls subroutine at 0x20A        // 202
      0x70, 0x01, // adds 1 to V0                     // 204
      0x12, 0x0E, // jumps to 0x20E                   // 206
      0x70, 0x01, // adds 1 to V0 (should be skipped) // 208
      // subroutine starts here
      0x61, 0x01, // puts 1 to V1                     // 20A
      0x00, 0xEE, // returns from subroutine          // 20C
      // subroutine ends here
      0x62, 0x01, // puts 1 in V2                     // 20E
    ];
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 16);
    chip8.run();
    expect(chip8.programCounter, 0x210);
    expect(chip8.registers.getUint8(0), 2);
    expect(chip8.registers.getUint8(1), 1);
    expect(chip8.registers.getUint8(2), 1);
  });

  test('emulator runs a sophisticated binary program', () {
    final program = File('test/bin/ibm_logo.ch8').readAsBytesSync();
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 132);
    chip8.run(1000);
    expect(chip8.programCounter, 0x228);
  });

  test('emulator runs another sophisticated binary program', () {
    final program =
        File('test/bin/framed_mk1_samways_1980.ch8').readAsBytesSync();
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 176);
    chip8.run(1000);
    expect(chip8.programCounter, 0x228);
  });

  test('emulator runs asynchronously', () async {
    final program = [
      0x60, 0x01, // puts 1 in V0                     // 200
      0x22, 0x0A, // calls subroutine at 0x20A        // 202
      0x70, 0x01, // adds 1 to V0                     // 204
      0x12, 0x0E, // jumps to 0x20E                   // 206
      0x70, 0x01, // adds 1 to V0 (should be skipped) // 208
      // subroutine starts here
      0x61, 0x01, // puts 1 to V1                     // 20A
      0x00, 0xEE, // returns from subroutine          // 20C
      // subroutine ends here
      0x62, 0x01, // puts 1 in V2                     // 20E
    ];
    final chip8 = Chip8();
    chip8.loadProgram(program);
    expect(chip8.programMemoryEnd, 0x200 + 16);
    await chip8.runAsync();
    expect(chip8.programCounter, 0x210);
    expect(chip8.registers.getUint8(0), 2);
    expect(chip8.registers.getUint8(1), 1);
    expect(chip8.registers.getUint8(2), 1);
  });
}
