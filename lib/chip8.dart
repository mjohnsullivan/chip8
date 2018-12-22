import 'dart:typed_data';
import 'package:chip8/bytes.dart';
import 'package:chip8/utils.dart';

class Chip8 {
  // 35 opcodes - each 2 bytes in length
  final opcodes = ByteData.view(Uint16List(35).buffer);

  // 16 registers; 15 general and 16th for carry flag
  final ByteData registers = ByteData.view(Uint8List(16).buffer);

  // Index register, 12 bits in size
  int indexRegister;

  // Program register, 12 bits in size
  int programCounter = 0;

  // Memory, 4096 bytes in size
  ByteData memory = ByteData.view(Uint8List(4096).buffer);

  // RAM start
  final ramStart = 0x200;

  // Display is 64x32 of binary pixels
  final display =
      List.from(List.generate(64 * 32, (_) => false), growable: false);

  // Delay timer
  int delayTimer;

  // Sound timer
  int soundTimer;

  // Stack, 16 levels deep
  ByteData stack = ByteData.view(Uint16List(16).buffer);

  // Stack pointer
  int stackPointer;

  // Keypad
  final keypad = List.from(List.generate(16, (_) => false), growable: false);

  /// Sets a register value, registers numbering from 0..15
  void setRegister(int register, int value) =>
      registers.setUint8(register, value);

  /// Gets the value from a register, registers numbering 0..15
  int getRegister(int register) => registers.getUint8(register);

  /// Presses a key
  void pressKey(int key) => keypad[key] = true;

  /// Releases a key
  void releaseKey(int key) => keypad[key] = false;

  /// Checks to see if a key is pressed
  bool isKeyPressed(int key) => keypad[key];

  /// Execute a single CPU cycle
  void step() {
    // Read the opcode
    final opcode = 0x00FF; // Dummy opcode
    // Advance the program counter
    programCounter += 2;
    // Execute the opcode
    executeOpcode(opcode);
  }

  /// Executes an opcode
  void executeOpcode(int opcode) {
    final opPrefix = mostSignificantNibble(opcode);
    if (opPrefix == 1) {
      // 1NNN - jumps to address NNN
      programCounter = leastSignificantTribble(opcode);
      return;
    }
    if (opPrefix == 3) {
      // 3XNN - skips the next instruction if VX equals NN
      final vx = secondSignificantNibble(opcode);
      final xValue = getRegister(vx);
      final value = leastSignificantByte(opcode);
      if (xValue == value) {
        programCounter += 2;
      }
      return;
    }
    if (opPrefix == 4) {
      // 4XNN - skips the next instruction if VX doesn't equal NN
      final vx = secondSignificantNibble(opcode);
      final xValue = getRegister(vx);
      final value = leastSignificantByte(opcode);
      if (xValue != value) {
        programCounter += 2;
      }
      return;
    }
    if (opPrefix == 5) {
      // 5XY0 - skips the next instruction if VX equals VY
      final vx = secondSignificantNibble(opcode);
      final xValue = getRegister(vx);
      final vy = thirdSignificantNibble(opcode);
      final yValue = getRegister(vy);
      if (xValue == yValue) {
        programCounter += 2;
      }
      return;
    }
    if (opPrefix == 6) {
      // 6XNN - sets VX to NN
      final registerNr = secondSignificantNibble(opcode);
      setRegister(registerNr, leastSignificantByte(opcode));
      return;
    }
    if (opPrefix == 7) {
      // 7XNN - Adds NN to VX (Carry flag is not changed)
      final registerNr = secondSignificantNibble(opcode);
      final value = leastSignificantByte(opcode);
      final registerValue = getRegister(registerNr);
      setRegister(registerNr, value + registerValue);
      return;
    }
    if (opPrefix == 8) {
      executeOpcode8(opcode);
      return;
    }
    if (opPrefix == 9) {
      // 9XY0 - skips the next instruction if VX doesn't equal VY
      final vx = secondSignificantNibble(opcode);
      final xValue = getRegister(vx);
      final vy = thirdSignificantNibble(opcode);
      final yValue = getRegister(vy);
      if (xValue != yValue) {
        programCounter += 2;
      }
      return;
    }
    if (opPrefix == 0xA) {
      // ANNN - sets I to the address NNN
      indexRegister = leastSignificantTribble(opcode);
      return;
    }
    if (opPrefix == 0xB) {
      // BNNN - jumps to the address NNN plus V0
      programCounter =
          (leastSignificantTribble(opcode) + getRegister(0)) & 0xFFF;
      return;
    }
    if (opPrefix == 0xC) {
      // CXNN - sets VX to the result of a bitwise and operation on a random number
      // (Typically: 0 to 255) and NN
      final vx = secondSignificantNibble(opcode);
      final value = leastSignificantByte(opcode);
      final randomValue = randomInt(0xFF);
      setRegister(vx, value & randomValue);
      return;
    }
    if (opPrefix == 0xE) {
      switch (leastSignificantByte(opcode)) {
        case 0x9e:
          // EX9E - skips the next instruction if the key stored in VX is pressed
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          if (isKeyPressed(xValue)) {
            programCounter += 2;
          }
          return;
        case 0xA1:
          // EXA1 - skips the next instruction if the key stored in VX isn't pressed
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          if (!isKeyPressed(xValue)) {
            programCounter += 2;
          }
          return;
      }
    }
    if (opPrefix == 0xF) {
      switch (leastSignificantByte(opcode)) {
        case 0x07:
          // FX07 - sets VX to the value of the delay timer
          final vx = secondSignificantNibble(opcode);
          setRegister(vx, delayTimer);
          return;
        case 0x0A:
          // A key press is awaited, and then stored in VX
          // Blocking Operation - all instruction halted until next key event
          // TODO: implement
          throw Exception();
        case 0x15:
          // FX15 - sets the delay timer to VX
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          delayTimer = xValue;
          return;
        case 0x18:
          // FX18 - sets the sound timer to VX
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          soundTimer = xValue;
          return;
        case 0x1E:
          // FX1E - adds VX to I
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          indexRegister = (indexRegister + xValue) & 0xFFF;
          return;
      }
    }
  }

  void executeOpcode8(int opcode) {
    final op = leastSignificantNibble(opcode);
    final vx = secondSignificantNibble(opcode);
    final vy = thirdSignificantNibble(opcode);
    final xValue = getRegister(vx);
    final yValue = getRegister(vy);
    switch (op) {
      case 0: // 8XY0 - Sets VX to the value of VY
        setRegister(vx, getRegister(vy));
        return;
      case 1: // 8XY1 - Sets VX to VX or VY (Bitwise OR operation)
        setRegister(vx, xValue | yValue);
        return;
      case 2: // 8XY2 - Sets VX to VX and VY (Bitwise AND operation)
        setRegister(vx, xValue & yValue);
        return;
      case 3: // 8XY3 - Sets VX to VX xor VY (Bitwise XOR operation)
        setRegister(vx, xValue ^ yValue);
        return;
      case 4: // 8XY4 - Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't
        final addedValue = xValue + yValue;
        setRegister(vx, addedValue);
        setRegister(0xF, addedValue > 0xFF ? 1 : 0);
        return;
      case 5: // 8XY5 - VY is subtracted from VX, VF is set to 0 when there's a borrow, and 1 when there isn't
        final subtractedValue = xValue - yValue;
        setRegister(vx, subtractedValue);
        setRegister(0xF, subtractedValue >= 0 ? 1 : 0);
        return;
      case 6: // 8XY6 - stores the least significant bit of VX in VF and then shifts VX to the right by 1
        setRegister(0xF, xValue & 0x1);
        setRegister(vx, xValue >> 1);
        return;
      case 7: // 8XY7 - sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't
        final subtractedValue = yValue - xValue;
        setRegister(vx, subtractedValue);
        setRegister(0xF, subtractedValue >= 0 ? 1 : 0);
        return;
      case 0xE: // 8XYE - stores the most significant bit of VX in VF and then shifts VX to the left by 1
        setRegister(0xF, xValue >> 7);
        setRegister(vx, xValue << 1);
        return;
    }
  }
}
