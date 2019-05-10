import 'dart:io';

/// Assembler for the Chip8
void writeMachineCode(String path) {
  for (int i = 0; i < 8; i++) {
    File(path).writeAsBytesSync([0x60, 0x01, 0x61, 0xA0]);
  }
}
