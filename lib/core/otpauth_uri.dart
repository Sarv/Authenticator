import 'totp.dart';

/// Parses the `otpauth://` URI that a QR code encodes (the Key Uri Format used
/// by Google Authenticator and every compatible app):
///
///   otpauth://totp/Issuer:account?secret=BASE32&issuer=Issuer&digits=6&period=30&algorithm=SHA1
///
/// Pure: a string in, a plain data record out. No storage, no crypto here.
class OtpauthData {
  const OtpauthData({
    required this.type,
    required this.issuer,
    required this.account,
    required this.secretBase32,
    required this.digits,
    required this.period,
    required this.algorithm,
  });

  final String type; // 'totp' or 'hotp'
  final String issuer;
  final String account;
  final String secretBase32;
  final int digits;
  final int period;
  final OtpAlgorithm algorithm;
}

OtpAlgorithm _parseAlgorithm(String? raw) {
  switch ((raw ?? 'SHA1').toUpperCase()) {
    case 'SHA256':
      return OtpAlgorithm.sha256;
    case 'SHA512':
      return OtpAlgorithm.sha512;
    default:
      return OtpAlgorithm.sha1;
  }
}

OtpauthData parseOtpauthUri(String raw) {
  final uri = Uri.parse(raw.trim());
  if (uri.scheme != 'otpauth') {
    throw FormatException('Not an otpauth URI: ${uri.scheme}');
  }

  // Label is "Issuer:account" (issuer prefix optional); it is URL-encoded.
  final label = Uri.decodeComponent(uri.path.replaceFirst('/', ''));
  final labelParts = label.split(':');
  final params = uri.queryParameters;

  final issuer = params['issuer'] ??
      (labelParts.length > 1 ? labelParts.first.trim() : '');
  final account =
      (labelParts.length > 1 ? labelParts.sublist(1).join(':') : label).trim();

  final secret = params['secret'];
  if (secret == null || secret.isEmpty) {
    throw const FormatException('otpauth URI is missing the secret');
  }

  return OtpauthData(
    type: uri.host.toLowerCase(),
    issuer: issuer,
    account: account,
    secretBase32: secret,
    digits: int.tryParse(params['digits'] ?? '') ?? 6,
    period: int.tryParse(params['period'] ?? '') ?? 30,
    algorithm: _parseAlgorithm(params['algorithm']),
  );
}
