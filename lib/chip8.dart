import 'dart:async';
import 'dart:typed_data';

import 'package:chip8/bytes.dart';
import 'package:chip8/font.dart';
import 'package:chip8/utils.dart';

final fontMemoryBase = 0;
final programMemoryBase = 0x200;

class Chip8 {
  Chip8() {
    loadFonts();
    _runTimer();
  }

  // 35 opcodes - each 2 bytes in length
  final opcodes = ByteData.view(Uint16List(35).buffer);

  // 16 registers; 15 general and 16th for carry flag
  final ByteData registers = ByteData.view(Uint8List(16).buffer);

  // Index register, 12 bits in size
  int indexRegister;

  // Program register, 12 bits in size
  int _programCounter = 0x200;
  void set programCounter(int val) => _programCounter = val & 0xFFF;
  int get programCounter => _programCounter;

  // Memory, 4096 bytes in size
  ByteData memory = ByteData.view(Uint8List(4096).buffer);

  /// End of loaded program in memory
  var programMemoryEnd = 0;

  // Display is 64x32 of binary pixels
  final display =
      List<bool>.from(List.generate(64 * 32, (_) => false), growable: false);

  /// Paints a pixel at (x,y)
  void draw(int x, int y, bool value) {
    assert(y >= 0 && x >= 0);
    // If the draw falls off the right or bottom of the screen,
    // then ignore, as sprites can be partially shown at the edges
    if (y < 32 && x < 64) {
      display[(y * 64) + x] = value;
    }
  }

  /// Delay timer
  var delayTimer = 0;

  /// Sound timer
  var soundTimer = 0;

  /// Internal Dart timer to drive the timers
  Timer timerDriver;

  /// Timer to handle throttling emulator cycles
  Timer cycleTimer;

  /// Stack
  final _stack = List<int>();
  void set push(int val) => _stack.add(val & 0xFFF);
  int get pop => _stack.removeLast();

  /// Keypad
  final keypad =
      List<bool>.from(List.generate(16, (_) => false), growable: false);

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

  /// Checks to see if any key is pressed
  bool isAnyKeyPressed() => keypad.any((key) => true);

  /// Returns the index of the pressed key, or -1 of no keys are pressed
  int pressedKey() => keypad.indexOf(true);

  /// Loads font data into memory
  void loadFonts() {
    for (int i = 0; i < fonts.length; i++) {
      memory.setUint8(fontMemoryBase + i, fonts[i]);
    }
  }

  /// Returns the memory location of a sprite for the character
  int fontLocation(int char) {
    assert(char >= 0 && char <= 0xF);
    return fontMemoryBase + (char * 5);
  }

  /// Loads a program into memory
  void loadProgram(List<int> program) {
    for (int i = 0; i < program.length; i++) {
      memory.setUint8(programMemoryBase + i, program[i]);
    }
    programMemoryEnd = programMemoryBase + program.length;
  }

  void _runTimer() {
    timerDriver = Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (_) {
      if (delayTimer > 0) {
        --delayTimer;
      }
      if (soundTimer > 0) {
        --soundTimer;
        if (soundTimer == 0) {
          print('BEEEEEP!');
        }
      }
    });
  }

  /// Executes the loaded program
  void run([int maxCycles]) {
    int cycle = 0;
    programCounter = programMemoryBase;
    while (programCounter < programMemoryEnd) {
      step();
      if (maxCycles != null && cycle++ >= maxCycles) {
        break;
      }
    }
  }

  /// Executes the loading program asychronously
  /// There's a pause between instruction steps
  Future runAsync() async {
    final completer = Completer();
    if (cycleTimer == null) {
      programCounter = programMemoryBase;
      cycleTimer = Timer.periodic(Duration(milliseconds: 1), (_) {
        step();
        if (programCounter >= programMemoryEnd) {
          cycleTimer.cancel();
          completer.complete();
        }
      });
    }
    return completer.future;
  }

  /// Execute a single CPU cycle
  void step() {
    // Read the opcode
    final opcode = memory.getUint16(programCounter);
    // Execute the opcode
    executeOpcode(opcode);
    // Advance the program counter
    programCounter += 2;
  }

  /// Executes an opcode
  void executeOpcode(int opcode) {
    final opPrefix = mostSignificantNibble(opcode);
    if (opPrefix == 0) {
      switch (leastSignificantTribble(opcode)) {
        case 0x0E0:
          // 00E0 - clears the screen
          display.setAll(0, List.generate(64 * 32, (_) => false));
          return;
        case 0x0EE:
          // 00EE - returns from a subroutine
          // -2 to offset the advance of the PC in step()
          programCounter = pop - 2;
          return;
        default:
          // 0NNN - calls RCA 1802 program at address NNN. Not necessary for most ROMs
          print('RCA program called at address ${printBytes(opcode, 3)}');
        //throw Exception(
        //  'RCA program called at address ${printBytes(opcode, 3)}');
      }
    }
    if (opPrefix == 1) {
      // 1NNN - jumps to address NNN
      // -2 to offset the advance of the PC in step()
      programCounter = leastSignificantTribble(opcode) - 2;
      return;
    }
    if (opPrefix == 2) {
      // 2NNN - calls subroutine at NNN
      final addr = leastSignificantTribble(opcode);
      push = programCounter + 2;
      // -2 to offset the advance of the PC in step()
      programCounter = addr - 2;
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
    if (opPrefix == 0xD) {
      // DXYN - draws a sprite at coordinate (VX, VY) that has a width of 8 pixels
      // and a height of N pixels. Each row of 8 pixels is read as bit-coded starting
      // from memory location I; I value doesn’t change after the execution of this
      // instruction. As described above, VF is set to 1 if any screen pixels are
      // flipped from set to unset when the sprite is drawn, and to 0 if that doesn’t
      // happen
      final vx = secondSignificantNibble(opcode);
      final vy = thirdSignificantNibble(opcode);
      final spriteHeight = leastSignificantNibble(opcode);
      final xCoord = getRegister(vx);
      final yCoord = getRegister(vy);
      var memoryPointer = indexRegister;

      // Iterate through each row
      // e.g. to draw a row, i.e. single byte of pixels
      // draw(xCoord, yCoord, (spriteByte >> 7 & 0x01) == 0x01);
      // draw(xCoord + 1, yCoord, (spriteByte >> 6 & 0x01) == 0x01);
      // draw(xCoord + 7, yCoord, (spriteByte >> 0 & 0x01) == 0x01);
      for (int row = 0; row < spriteHeight; row++) {
        final spriteByte = memory.getUint8(memoryPointer++);
        for (int bit = 7; bit >= 0; bit--) {
          draw(
            xCoord + (7 - bit),
            yCoord + row,
            (spriteByte >> bit & 0x01) == 0x01,
          );
        }
      }
      _fireDrawEvent();
      return;
    }
    if (opPrefix == 0xE) {
      switch (leastSignificantByte(opcode)) {
        case 0x9E:
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
          // FX0A - key press is awaited, and then stored in VX
          // Blocking Operation - all instruction halted until next key event
          final key = pressedKey();
          if (key != -1) {
            final vx = secondSignificantNibble(opcode);
            setRegister(vx, key);
          } else {
            // program should not advance; keep PC on this instruction
            programCounter -= 2;
          }
          return;
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
        case 0x29:
          // FX29 - sets I to the location of the sprite for the character in VX
          // Characters 0-F (in hexadecimal) are represented by a 4x5 font
          final vx = secondSignificantNibble(opcode);
          final char = getRegister(vx);
          indexRegister = fontLocation(char);
          return;
        case 0x33:
          // FX33 - stores the binary-coded decimal representation of VX,
          // with the most significant of three digits at the address in I,
          // the middle digit at I plus 1, and the least significant digit at I plus 2

          // Take the decimal representation of VX,
          // place the hundreds digit in memory at location in I,
          // the tens digit at location I+1, and the ones digit at location I+2
          final vx = secondSignificantNibble(opcode);
          final value = getRegister(vx);
          memory.setUint8(indexRegister, (value ~/ 100) % 10);
          memory.setUint8(indexRegister + 1, (value ~/ 10) % 10);
          memory.setUint8(indexRegister + 2, value % 10);
          return;
        case 0x55:
          // FX55 - stores V0 to VX (including VX) in memory starting at address I.
          // The offset from I is increased by 1 for each value written,
          // but I itself is left unmodified
          final vx = secondSignificantNibble(opcode);
          var memoryPointer = indexRegister;
          for (var vi = 0; vi <= vx; vi++) {
            final value = getRegister(vi);
            memory.setInt8(memoryPointer++, value);
          }
          return;
        case 0x56:
          // FX56 - fills V0 to VX (including VX) with values from memory starting at
          // address I. The offset from I is increased by 1 for each value written,
          // but I itself is left unmodified
          final vx = secondSignificantNibble(opcode);
          var memoryPointer = indexRegister;
          for (var vi = 0; vi <= vx; vi++) {
            final value = memory.getUint8(memoryPointer++);
            setRegister(vi, value);
          }
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

  /// Returns a dump of the emulator state
  String dump() {
    final buffer = StringBuffer();
    buffer.write('Program size: ${memory.lengthInBytes}\n');
    buffer.write('Program counter: ${printBytes(programCounter)}\n');
    // Display memory at and after program counter
    buffer.write('Memory at ${printBytes(programCounter)}: ');
    buffer.write('${printBytes(memory.getUint64(programCounter), 8)}');
    return buffer.toString();
  }

  /// Subscribed listeners
  final Set<Function> listeners = Set<Function>();

  /// Listen for events fired by the chip8 emulator
  void listen(Function listener) => listeners.add(listener);

  /// Remove a listener
  void remove(Function listener) => listeners.remove(listener);

  /// Fire a draw event
  void _fireDrawEvent() => listeners.forEach((listener) => listener());

  void dispose() {
    timerDriver?.cancel();
    cycleTimer?.cancel();
  }
}
