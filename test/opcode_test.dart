import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
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
  test('8XY5 - VY subtracted from VX, VF is set to 0 when borrow, 1 otherwise',
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
  test('8XY6 - stores the VX least significant bit in VF, shifts VX right by 1',
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
}
