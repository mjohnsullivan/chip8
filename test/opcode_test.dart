import "package:test/test.dart";
import '../lib/chip8.dart';

void main() {
  test('6XNN places NN in register VX', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023);
    expect(chip8.registers.getUint16(0), 0x23);
    chip8.executeOpcode(0x6234);
    expect(chip8.registers.getUint16(4), 0x34);
    chip8.executeOpcode(0x6ABC);
    expect(chip8.registers.getUint16(20), 0xBC);
    chip8.executeOpcode(0x6FED);
    expect(chip8.registers.getUint16(30), 0xED);
  });
  test('7XNN adds NN to VX and not set the carry flag', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023);
    chip8.executeOpcode(0x7056);
    expect(chip8.registers.getUint16(0), 0x23 + 0x56);
    chip8.executeOpcode(0x6ABC);
    chip8.executeOpcode(0x7A12);
    expect(chip8.registers.getUint16(20), 0xBC + 0x12);
    chip8.executeOpcode(0x6FED);
    chip8.executeOpcode(0x7FAA);
    expect(chip8.registers.getUint16(30), 0xED + 0xAA);
  });
  test('8XY0 sets VX to the value of VY', () {
    final chip8 = Chip8();
    chip8.executeOpcode(0x6023); // store 0x23 in V0
    chip8.executeOpcode(0x8100); // move value in V0 to V1
    expect(chip8.registers.getUint16(2), 0x23);
    chip8.executeOpcode(0x6BCD); // store 0xCD in V11
    chip8.executeOpcode(0x88B0); // move value in V11 to V8
    expect(chip8.registers.getUint16(16), 0xCD);
  });
}
