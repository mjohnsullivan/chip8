import 'dart:typed_data';

main() {
  print('Hello World');
}

class Chip8 {
  // 35 opcodes - each 2 bytes in length
  final opcodes = ByteData.view(Uint16List(35).buffer);

  // 16 registers; 15 general and 16th for carry flag
  final ByteData registers = ByteData.view(Uint16List(16).buffer);

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
    registers.setUint16(register * 2, value);
  }

  /// Gets the value from a register, registers numbering 0..15
  int getRegister(int register) => registers.getUint16(register * 2);

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

/// Returns the value of the least significant byte from a word
int leastSignificantByte(final int word) {
  return word & 0x00FF;
}
