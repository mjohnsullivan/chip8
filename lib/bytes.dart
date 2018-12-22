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

/// Returns the value of the least significant tribble (12 bits) from a word
int leastSignificantTribble(final int word) {
  return word & 0x0FFF;
}
