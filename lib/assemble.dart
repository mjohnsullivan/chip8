import 'dart:io';
import 'dart:typed_data';

/// Assembler for the Chip8

void writeMachineCode(String path) {
  /*
  final program = ByteData.view(Uint16List(4).buffer);
  program.setUint16(0, 0x6001);
  program.setUint16(0, 0x6002);
  program.setUint16(0, 0x6003);
  program.setUint16(0, 0x6004);
  */
  final progFile = File(path);
  for (int i = 0; i < 8; i++) {
    progFile.writeAsBytesSync([0x60, 0x01, 0x61, 0xA0]);
  }
}
