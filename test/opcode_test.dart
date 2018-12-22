import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
  test('0NNN calls RCA 1802 program at address NNN - throws exception', () {
    final chip8 = Chip8();
    expect(
      () => chip8.executeOpcode(0x0000),
      throwsA(const TypeMatcher<Exception>()),
    );
  });
  test('00E0 clears the screen', () {
    final chip8 = Chip8();
    // set all pixels to on
    chip8.display.setAll(0, List.generate(64 * 32, (_) => true));
    for (int i = 0; i < 64 * 32; i++) {
      expect(chip8.display[i], true);
    }
    chip8.executeOpcode(0x00E0); // clear the screen
    for (int i = 0; i < 64 * 32; i++) {
      expect(chip8.display[i], false);
    }
  });
  test('1NNN jumps to address NNN', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x1234);
    expect(chip8.programCounter, 0x234);
    chip8.executeOpcode(0x1CDE);
    expect(chip8.programCounter, 0xCDE);
  });
  test('3XNN skips the next instruction if VX equals NN', () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6456); // puts 0x56 in V4
    chip8.executeOpcode(0x3456); // compares V4 to 0x56
    expect(chip8.programCounter, pc + 2);
    chip8.executeOpcode(0x3457); // compares V4 to 0x56
    expect(chip8.programCounter, pc + 2); // pc should not increment further
  });
  test('4XNN skips the next instruction if VX does not equal NN', () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6456); // puts 0x56 in V4
    chip8.executeOpcode(0x4456); // compares V4 to 0x56
    expect(chip8.programCounter, pc); // pc should not increment
    chip8.executeOpcode(0x4457); // compares V4 to 0x56
    expect(chip8.programCounter, pc + 2); // pc should increment
  });
  test('5XY0 skips the next instruction if VX equals VY', () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6456); // puts 0x56 in V4
    chip8.executeOpcode(0x6556); // puts 0x56 in V5
    chip8.executeOpcode(0x5450); // compares V4 to V5
    expect(chip8.programCounter, pc + 2); // pc should increment
    chip8.executeOpcode(0x6557); // puts 0x57 in V5
    chip8.executeOpcode(0x5450); // compares V4 to V5
    expect(chip8.programCounter, pc + 2); // pc should not increment
  });
  test('6XNN places NN in register VX', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023);
    expect(chip8.registers.getUint8(0), 0x23);
    chip8.executeOpcode(0x6234);
    expect(chip8.registers.getUint8(2), 0x34);
    chip8.executeOpcode(0x6ABC);
    expect(chip8.registers.getUint8(10), 0xBC);
    chip8.executeOpcode(0x6FED);
    expect(chip8.registers.getUint8(15), 0xED);
  });
  test('7XNN adds NN to VX and not set the carry flag', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023);
    chip8.executeOpcode(0x7056);
    expect(chip8.registers.getUint8(0), 0x23 + 0x56);
    chip8.executeOpcode(0x6ABC);
    chip8.executeOpcode(0x7A12);
    expect(chip8.registers.getUint8(10), 0xBC + 0x12);
    chip8.executeOpcode(0x6FED);
    chip8.executeOpcode(0x7FAA);
    expect(chip8.registers.getUint8(15), (0xED + 0xAA) & 0x00FF);
  });
  test('8XY0 sets VX to the value of VY', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x8100); // move value in V0 to V1
    expect(chip8.registers.getUint8(1), 0x23);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x88B0); // move value in V11 to V8
    expect(chip8.registers.getUint8(8), 0xCD);
  });
  test('8XY1 sets VX to the value of VX OR VY', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x6145); // store 0x45 in V1
    chip8.executeOpcode(0x8011); // store V0 | V1 in V0
    expect(chip8.registers.getUint8(0), 0x23 | 0x45);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC1); // store V11 | V12 in V11
    expect(chip8.registers.getUint8(11), 0xCD | 0xDE);
  });
  test('8XY2 sets VX to the value of VX AND VY', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x6145); // store 0x45 in V1
    chip8.executeOpcode(0x8012); // store V0 | V1 in V0
    expect(chip8.registers.getUint8(0), 0x23 & 0x45);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC2); // store V11 | V12 in V11
    expect(chip8.registers.getUint8(11), 0xCD & 0xDE);
  });
  test('8XY3 sets VX to the value of VX XOR VY', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x6145); // store 0x45 in V1
    chip8.executeOpcode(0x8013); // store V0 | V1 in V0
    expect(chip8.registers.getUint8(0), 0x23 ^ 0x45);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC3); // store V11 | V12 in V11
    expect(chip8.registers.getUint8(11), 0xCD ^ 0xDE);
  });
  test('8XY4 adds VY to VX. VF is set to 1 or 0 based on carry', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x6145); // store 0x45 in V1
    chip8.executeOpcode(0x8014); // store V0 + V1 in V0
    expect(chip8.registers.getUint8(0), 0x23 + 0x45);
    expect(chip8.registers.getUint8(15), 0x00);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC4); // store V11 + V12 in V11
    expect(chip8.registers.getUint8(11), (0xCD + 0xDE) & 0x00FF);
    expect(chip8.registers.getUint8(15), 0x01);
  });
  test('8XY5 VY subtracted from VX, VF is set to 0 when borrow, 1 otherwise',
      () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6045); // store 0x45 in V0
    chip8.executeOpcode(0x6123); // store 0x23 in V1
    chip8.executeOpcode(0x8015); // store V0 - V1 in V0
    expect(chip8.registers.getUint8(0), 0x45 - 0x23);
    expect(chip8.registers.getUint8(15), 1);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC5); // store V11 - V12 in V11
    expect(chip8.registers.getUint8(11), (0xCD - 0xDE) & 0x00FF);
    expect(chip8.registers.getUint8(15), 0);
  });
  test('8XY6 stores the VX least significant bit in VF, shifts VX right by 1',
      () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6045); // store 0x45 in V0
    chip8.executeOpcode(0x8006); // stores and bit shifts
    expect(chip8.registers.getUint8(0), 0x45 >> 1);
    expect(chip8.registers.getUint8(15), 1);
    chip8.executeOpcode(0x6BCE); // store 0xCD in V11
    chip8.executeOpcode(0x8B06); // stores and bit shifts
    expect(chip8.registers.getUint8(11), 0xCE >> 1);
    expect(chip8.registers.getUint8(15), 0);
  });
  test('8XY7 VX subtracted from VY, VF is set to 0 when borrow, 1 otherwise',
      () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6045); // store 0x45 in V0
    chip8.executeOpcode(0x6123); // store 0x23 in V1
    chip8.executeOpcode(0x8017); // store V1 - V0 in V0
    expect(chip8.registers.getUint8(0), (0x23 - 0x45) & 0xFF);
    expect(chip8.registers.getUint8(15), 0);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x6CDE); // store 0xDE in V12
    chip8.executeOpcode(0x8BC7); // store V12 - V11 in V11
    expect(chip8.registers.getUint8(11), 0xDE - 0xCD);
    expect(chip8.registers.getUint8(15), 1);
  });
  test('8XYE stores the VX most significant bit in VF, shifts VX left by 1',
      () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6045); // store 0x45 in V0
    chip8.executeOpcode(0x800E); // stores and bit shifts
    expect(chip8.registers.getUint8(0), (0x45 << 1) & 0xFF);
    expect(chip8.registers.getUint8(15), 0);
    chip8.executeOpcode(0x6BCE); // store 0x12 in V11
    chip8.executeOpcode(0x8B0E); // stores and bit shifts
    expect(chip8.registers.getUint8(11), (0xCE << 1) & 0xFF);
    expect(chip8.registers.getUint8(15), 1);
  });
  test('9XY0 skips the next instruction if VX is not equal to VY', () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6456); // puts 0x56 in V4
    chip8.executeOpcode(0x6556); // puts 0x56 in V5
    chip8.executeOpcode(0x9450); // compares V4 to V5
    expect(chip8.programCounter, pc); // pc should not increment
    chip8.executeOpcode(0x6557); // puts 0x57 in V5
    chip8.executeOpcode(0x9450); // compares V4 to V5
    expect(chip8.programCounter, pc + 2); // pc should increment
  });
  test('ANNN sets I to the address NNN', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0xA234);
    expect(chip8.indexRegister, 0x234);
    chip8.executeOpcode(0xACDE);
    expect(chip8.indexRegister, 0xCDE);
  });
  test('BNNN jumps to the address NNN plus V0', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6045); // put 0x45 in V0
    chip8.executeOpcode(0xB234); // jump to V0 + 0x234
    expect(chip8.programCounter, (0x45 + 0x234) & 0xFFF);
  });
  test('CXNN jumps to the address NNN plus V0', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0xC845); // put random number in V8
    // No way to test random number, so testing to see if it crashes
  });
  test('EX9E skips next instruction if the key stored in VX is pressed', () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6D05); // store 0x05 in VD
    chip8.executeOpcode(0xED9E); // key 5 not pressed, nothing happens
    expect(chip8.programCounter, pc);
    chip8.pressKey(5);
    chip8.executeOpcode(0xED9E); // key 5 pressed, pc increments
    expect(chip8.programCounter, pc + 2);
  });
  test('EXA1 skips the next instruction if the key stored in VX isnt pressed',
      () {
    final chip8 = Chip8();
    final pc = chip8.programCounter;
    chip8.executeOpcode(0x6D0B); // store 0x0B in VD
    chip8.executeOpcode(0xEDA1); // key 11 not pressed, pc increments
    expect(chip8.programCounter, pc + 2);
    chip8.pressKey(11);
    chip8.executeOpcode(0xEDA1); // key 11 pressed, nothing happens
    expect(chip8.programCounter, pc + 2);
  });
  test('FX07 - sets VX to the value of the delay timer', () {
    final chip8 = Chip8();
    chip8.delayTimer = 45;
    chip8.executeOpcode(0xF907); // store timer in V9
    expect(chip8.registers.getUint8(9), chip8.delayTimer);
  });
  test('FX15 - sets the delay timer to VX', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6312); // set V3 to 0x12
    chip8.executeOpcode(0xF315); // store V3 in timer
    expect(chip8.delayTimer, 0x12);
  });
  test('FX18 - sets the sound timer to VX', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6B03); // set VB to 0x03
    chip8.executeOpcode(0xFB18); // store V3 in timer
    expect(chip8.soundTimer, 3);
  });
  test('FX1E - adds VX to I', () {
    final chip8 = Chip8();
    chip8.indexRegister = 0x42; // set I to 0x42
    chip8.executeOpcode(0x6623); // set V6 to 0x23
    chip8.executeOpcode(0xF61E); // add V6 to I
    expect(chip8.indexRegister, 0x42 + 0x23);
  });
  test('FX55 - stores V0 to VX inclusive in memory starting at address I', () {
    final chip8 = Chip8();
    chip8.indexRegister = 0x42; // set I to 0x42
    chip8.executeOpcode(0x6001); // set V0 to 0x01
    chip8.executeOpcode(0x6102); // set V1 to 0x02
    chip8.executeOpcode(0x6203); // set V2 to 0x03
    chip8.executeOpcode(0x6310); // set V3 to 0x10
    chip8.executeOpcode(0x64FF); // set V3 to 0xFF
    chip8.executeOpcode(0xF455); // move V0 - V4 to memory
    expect(chip8.indexRegister, 0x42); // I does not change
    expect(chip8.memory.getUint8(0x41), 0);
    expect(chip8.memory.getUint8(0x42), 1);
    expect(chip8.memory.getUint8(0x43), 2);
    expect(chip8.memory.getUint8(0x44), 3);
    expect(chip8.memory.getUint8(0x45), 16);
    expect(chip8.memory.getUint8(0x46), 255);
    expect(chip8.memory.getUint8(0x47), 0);
  });
  test('FX56 - fills V0 to VX inclusive with memory values starting at I', () {
    final chip8 = Chip8();
    chip8.indexRegister = 0x42; // set I to 0x42
    chip8.memory.setUint8(0x42, 0x01);
    chip8.memory.setUint8(0x43, 0x02);
    chip8.memory.setUint8(0x44, 0x03);
    chip8.memory.setUint8(0x45, 0x10);
    chip8.memory.setUint8(0x46, 0xFF);
    chip8.executeOpcode(0xF456); // move memory to V0 - V4
    expect(chip8.indexRegister, 0x42); // I does not change
    expect(chip8.registers.getUint8(0), 1);
    expect(chip8.registers.getUint8(1), 2);
    expect(chip8.registers.getUint8(2), 3);
    expect(chip8.registers.getUint8(3), 16);
    expect(chip8.registers.getUint8(4), 255);
    expect(chip8.registers.getUint8(5), 0);
  });
}
