import 'dart:io';

/// Loads a file for assembly file
void loadAssemblyFile(String path) {}

/// Writes a binary file to disk
void writeBinary(String path, List<int> bytes) =>
    File(path).writeAsBytesSync(bytes);

/// Assembler for the Chip8
List<int> assemble(List<String> tokens) {
  final binary = <int>[];
  int pos = 0;
  while (pos < tokens.length) {
    switch (tokens[pos].toUpperCase()) {
      case 'CLS':
        binary.add(0x00E0);
        pos++;
        break;
    }
  }
  return binary;
}
