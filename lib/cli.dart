import 'dart:io';

import 'package:args/args.dart';
import 'package:chip8/assemble.dart';
import 'package:chip8/bytes.dart';
import 'package:chip8/utils.dart';

void printUsage(ArgParser parser, [String error]) {
  final out = StringBuffer();
  var message = 'Chip8 emulator tools';
  if (error != null) {
    message = error;
  }

  out.writeln('''$message
Usage: chip8 <file>
${parser.usage}
For more information, see https://github.com/mjohnsullivan/chip8
''');

  print(out.toString());
}

/// Start linting from the command-line.
Future run(List<String> args) async {
  var parser = ArgParser(allowTrailingOptions: true);

  parser
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information.')
    ..addFlag('dump', abbr: 'd', negatable: false, help: 'Dump program in hex.')
    ..addFlag('assemble',
        abbr: 'a', negatable: false, help: 'Assemble a program.');

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  if (options['help']) {
    printUsage(parser);
    return;
  }

  if (options.rest.isEmpty) {
    printUsage(parser, 'Please provide a chip8 program.');
    return;
  }

  if (options['dump']) {
    final program = File(options.rest[0]).readAsBytesSync();
    assert(program.length % 2 == 0);
    for (int i = 0; i < program.length - 1; i += 2) {
      final upperByte = program[i];
      final lowerByte = program[i + 1];
      final word = ((upperByte & 0xFF) << 8) | (lowerByte & 0xFF);
      print('${printBytes(i + 0x200, 3)} -- ' + printOpcode(word));
    }
    return;
  }

  if (options['assemble']) {
    writeMachineCode(options.rest[0]);
  }
}

/// Pretty prints opcodes
String printOpcode(int opcode) {
  final opStr = opcode.toRadixString(16).toUpperCase();
  // 0x00E0
  if (RegExp(r'E0').hasMatch(opStr)) {
    return '0x00E0 - clear the screen';
  }
  // 0x00EE
  if (RegExp(r'EE').hasMatch(opStr)) {
    return '0x00EE - return from a subroutine';
  }
  // 0xANNN
  if (RegExp(r'^A[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    return '${printBytes(opcode)} - put ${printBytes(leastSignificantTribble(opcode))} in index register';
  }
  // 0x6XNN
  if (RegExp(r'^6[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final value = leastSignificantByte(opcode);
    return '${printBytes(opcode)} - put ${printBytes(value)} in V$vx';
  }
  // 0x7XNN
  if (RegExp(r'^7[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final value = leastSignificantByte(opcode);
    return '${printBytes(opcode)} - add ${printBytes(value)} to V$vx';
  }
  // 0xDXYN
  if (RegExp(r'^D[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final vy = thirdSignificantNibble(opcode);
    final height = leastSignificantNibble(opcode);
    return '${printBytes(opcode)} - draw at (V$vx, V$vy) for height $height';
  }
  // 0x1NNN
  if (RegExp(r'^1[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    return '${printBytes(opcode)} - jump to ${printBytes(leastSignificantTribble(opcode))}';
  }
  // 0x2NNN
  if (RegExp(r'^2[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    return '${printBytes(opcode)} - call subroutine at ${printBytes(leastSignificantTribble(opcode))}';
  }
  // 0x3XNN
  if (RegExp(r'^3[A-Z0-9][A-Z0-9][A-Z0-9]$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final val = leastSignificantByte(opcode);
    return '${printBytes(opcode)} - Skips the next instruction if V$vx equals $val';
  }
  //0x8XY6
  if (RegExp(r'^8[A-Z0-9][A-Z0-9]6$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final vy = thirdSignificantNibble(opcode);
    return '${printBytes(opcode)} - stores the value in V$vy shifted right one bit in V$vx; sets VF to the least significant bit prior to the shift';
  }
  //0x8XYE
  if (RegExp(r'^8[A-Z0-9][A-Z0-9]E$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    final vy = thirdSignificantNibble(opcode);
    return '${printBytes(opcode)} - stores the value in V$vy shifted left one bit in V$vx; sets VF to the most significant bit prior to the shift';
  }
  // 0xFX29
  if (RegExp(r'^F[A-Z0-9]29$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - point I to font char in V$vx';
  }
  // 0xFX0A
  if (RegExp(r'^F[A-Z0-9]0A$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - key press is awaited, and then stored in V$vx';
  }
  // 0xFX07
  if (RegExp(r'^F[A-Z0-9]07$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - sets V$vx to the value of the delay timer';
  }
  // 0xFX15
  if (RegExp(r'^F[A-Z0-9]15$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - sets the delay timer to V$vx';
  }
  // 0xFX55
  if (RegExp(r'^F[A-Z0-9]55$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - stores V0 to V$vx in memory starting at I';
  }
  // 0xFX1E
  if (RegExp(r'^F[A-Z0-9]1E$').hasMatch(opStr)) {
    final vx = secondSignificantNibble(opcode);
    return '${printBytes(opcode)} - adds V$vx to I';
  }
  return '${printBytes(opcode)} - ??';
}
