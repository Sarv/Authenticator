import 'dart:typed_data';

/// RFC 4648 Base32 decoder. TOTP secrets in `otpauth://` URIs are Base32
/// (no padding, case-insensitive), so this is the one encoding we must handle.
/// Pure function: a string in, bytes out.
const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

Uint8List base32Decode(String input) {
  final cleaned = input.toUpperCase().replaceAll('=', '').replaceAll(' ', '');
  final bytes = <int>[];
  var buffer = 0;
  var bitsInBuffer = 0;

  for (final char in cleaned.split('')) {
    final value = _alphabet.indexOf(char);
    if (value < 0) {
      throw FormatException('Invalid Base32 character: "$char"');
    }
    buffer = (buffer << 5) | value;
    bitsInBuffer += 5;
    if (bitsInBuffer >= 8) {
      bitsInBuffer -= 8;
      bytes.add((buffer >> bitsInBuffer) & 0xff);
    }
  }
  return Uint8List.fromList(bytes);
}
