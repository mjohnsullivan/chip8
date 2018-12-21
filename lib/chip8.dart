import 'dart:typed_data';

main() {
  print('Hello World');
}

class Chip8 {
  // 35 opcodes - each 2 bytes in length
  final opcodes = ByteData.view(Uint16List(35).buffer);

  // 16 registers; 15 general and 16th for carry flag
  final ByteData registers = ByteData.view(Uint8List(16).buffer);

  // Index register, 12 bits in size
  int indexRegister;

  // Program register, 12 bits in size
  int programCounter;

  // Memory, 4096 bytes in size
  ByteData memory = ByteData.view(Uint8List(4096).buffer);

  // RAM start
  final ramStart = 0x200;

  // Display is 64x32 of binary pixels
  final display = List.unmodifiable(List.generate(64 * 32, (_) => false));

  // Delay timer
  int delayTimer;

  // Sound timer
  int soundTimer;

  // Stack, 16 levels deep
  ByteData stack = ByteData.view(Uint16List(16).buffer);

  // Stack pointer
  int stackPointer;

  // Keypad
  ByteData keypad = ByteData.view(Uint8List(16).buffer);

  /// Sets a register value, registers numbering from 0..15
  void setRegister(int register, int value) {
    registers.setUint8(register, value);
  }

  /// Gets the value from a register, registers numbering 0..15
  int getRegister(int register) => registers.getUint8(register);

  /// Executes an opcode
  void executeOpcode(int opcode) {
    if (mostSignificantNibble(opcode) == 6) {
      // 6XNN - Sets VX to NN
      final registerNr = secondSignificantNibble(opcode);
      setRegister(registerNr, leastSignificantByte(opcode));
      return;
    }
    if (mostSignificantNibble(opcode) == 7) {
      // 7XNN - Adds NN to VX (Carry flag is not changed)
      final registerNr = secondSignificantNibble(opcode);
      final value = leastSignificantByte(opcode);
      final registerValue = getRegister(registerNr);
      setRegister(registerNr, value + registerValue);
      return;
    }
    if (mostSignificantNibble(opcode) == 8) {
      final op = leastSignificantNibble(opcode);
      switch (op) {
        case 0: // 8XY0 - Sets VX to the value of VY
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          setRegister(xRegisterNr, getRegister(yRegisterNr));
          return;
        case 1: // 8XY1 - Sets VX to VX or VY (Bitwise OR operation)
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          final xValue = getRegister(xRegisterNr);
          final yValue = getRegister(yRegisterNr);
          setRegister(xRegisterNr, xValue | yValue);
          return;
        case 2: // 8XY2 - Sets VX to VX and VY (Bitwise AND operation)
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          final xValue = getRegister(xRegisterNr);
          final yValue = getRegister(yRegisterNr);
          setRegister(xRegisterNr, xValue & yValue);
          return;
        case 3: // 8XY3 - Sets VX to VX xor VY (Bitwise XOR operation)
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          final xValue = getRegister(xRegisterNr);
          final yValue = getRegister(yRegisterNr);
          setRegister(xRegisterNr, xValue ^ yValue);
          return;
        case 4: // 8XY4 - Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          final xValue = getRegister(xRegisterNr);
          final yValue = getRegister(yRegisterNr);
          final addedValue = xValue + yValue;
          setRegister(xRegisterNr, addedValue);
          setRegister(0xF, addedValue > 0xFF ? 1 : 0);
          return;
        case 5: // 8XY5 - VY is subtracted from VX, VF is set to 0 when there's a borrow, and 1 when there isn't
          final xRegisterNr = secondSignificantNibble(opcode);
          final yRegisterNr = thirdSignificantNibble(opcode);
          final xValue = getRegister(xRegisterNr);
          final yValue = getRegister(yRegisterNr);
          final subtractedValue = xValue - yValue;
          setRegister(xRegisterNr, subtractedValue);
          setRegister(0xF, subtractedValue >= 0 ? 1 : 0);
          return;
        case 6:
          // 8XY6 - stores the least significant bit of VX in VF and then shifts VX to the right by 1
          final vx = secondSignificantNibble(opcode);
          final xValue = getRegister(vx);
          setRegister(0xF, xValue & 0x1);
          setRegister(vx, xValue >> 1);
          return;
      }
    }
  }
}

/// Returns the value of the most significant nibble from a word
int mostSignificantNibble(final int word) {
  final clearedWord = word & 0xF000;
  final shiftedWord = clearedWord >> 12;
  return shiftedWord;
}

/// Returns the value of the 2nd most significant nibble from a word
int secondSignificantNibble(final int word) {
  final clearedWord = word & 0x0F00;
  final shiftedWord = clearedWord >> 8;
  return shiftedWord;
}

/// Returns the value of the 3nd most significant nibble from a word
int thirdSignificantNibble(final int word) {
  final clearedWord = word & 0x00F0;
  final shiftedWord = clearedWord >> 4;
  return shiftedWord;
}

/// Returns the value of the least significant byte from a word
int leastSignificantByte(final int word) {
  return word & 0x00FF;
}

/// Returns the value of the least significant nibble from a word
int leastSignificantNibble(final int word) {
  return word & 0x000F;
}
