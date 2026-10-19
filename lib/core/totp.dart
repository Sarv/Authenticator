import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Clean-room implementation of HOTP (RFC 4226) and TOTP (RFC 6238).
///
/// This is the entire cryptographic heart of any authenticator app
/// (Google Authenticator, Authy, Aegis, ...). No network, no proprietary
/// protocol — just an HMAC over a counter, truncated to N digits.
///
/// The HMAC primitive itself comes from the vetted `crypto` package; we never
/// hand-roll a hash. Everything here is pure: same inputs -> same output.

enum OtpAlgorithm { sha1, sha256, sha512 }

/// Picks the HMAC implementation for an algorithm. Isolated so the rest of the
/// module stays free of library-specific types.
Hmac _hmacFor(OtpAlgorithm algorithm, List<int> secret) {
  switch (algorithm) {
    case OtpAlgorithm.sha1:
      return Hmac(sha1, secret);
    case OtpAlgorithm.sha256:
      return Hmac(sha256, secret);
    case OtpAlgorithm.sha512:
      return Hmac(sha512, secret);
  }
}

/// Encodes a counter as an 8-byte big-endian value, per RFC 4226 §5.3.
Uint8List counterToBytes(int counter) {
  final bytes = ByteData(8);
  bytes.setUint64(0, counter);
  return bytes.buffer.asUint8List();
}

/// HOTP(secret, counter) — RFC 4226.
///
/// 1. digest = HMAC(secret, counter)
/// 2. dynamic truncation: low 4 bits of the last byte give an offset;
///    read the 4 bytes at that offset, mask the top bit.
/// 3. the 31-bit number mod 10^digits, left-padded with zeros.
String generateHotp({
  required List<int> secret,
  required int counter,
  int digits = 6,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) {
  final digest = _hmacFor(algorithm, secret).convert(counterToBytes(counter)).bytes;

  final offset = digest[digest.length - 1] & 0x0f;
  final binary = ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff);

  final code = binary % _pow10(digits);
  return code.toString().padLeft(digits, '0');
}

/// TOTP(secret, time) — RFC 6238. Just HOTP with counter = time / period.
///
/// Time is always derived from UTC (Unix epoch is zone-agnostic), so a code is
/// identical on every device regardless of local time zone.
String generateTotp({
  required List<int> secret,
  required DateTime atUtc,
  int period = 30,
  int digits = 6,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) {
  final counter = atUtc.millisecondsSinceEpoch ~/ 1000 ~/ period;
  return generateHotp(
    secret: secret,
    counter: counter,
    digits: digits,
    algorithm: algorithm,
  );
}

/// Seconds remaining in the current TOTP window — drives the countdown ring.
int secondsRemaining({required DateTime atUtc, int period = 30}) {
  final epochSeconds = atUtc.millisecondsSinceEpoch ~/ 1000;
  return period - (epochSeconds % period);
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
