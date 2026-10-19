import 'package:flutter_test/flutter_test.dart';
import 'package:sarv_authenticator/core/base32.dart';
import 'package:sarv_authenticator/core/otpauth_uri.dart';
import 'package:sarv_authenticator/core/totp.dart';

void main() {
  group('TOTP — RFC 6238 Appendix B test vectors', () {
    // RFC 6238 seed "12345678901234567890" (ASCII), Base32-encoded.
    final secret = base32Decode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');

    String codeAt(int unixSeconds) => generateTotp(
          secret: secret,
          atUtc: DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000,
              isUtc: true,),
          digits: 8,
        );

    test('matches every published SHA1 vector', () {
      expect(codeAt(59), '94287082');
      expect(codeAt(1111111109), '07081804');
      expect(codeAt(1111111111), '14050471');
      expect(codeAt(1234567890), '89005924');
      expect(codeAt(2000000000), '69279037');
      expect(codeAt(20000000000), '65353130');
    });
  });

  group('HOTP — RFC 4226 Appendix D test vectors', () {
    final secret = base32Decode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');

    test('matches the published 6-digit counter sequence', () {
      final expected = [
        '755224', '287082', '359152', '969429', '338314',
        '254676', '287922', '162583', '399871', '520489',
      ];
      for (var counter = 0; counter < expected.length; counter++) {
        expect(generateHotp(secret: secret, counter: counter), expected[counter]);
      }
    });
  });

  group('otpauth URI parsing', () {
    test('extracts issuer, account and params', () {
      final data = parseOtpauthUri(
        'otpauth://totp/GitHub:ankur.d@sarv.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=6&period=30&algorithm=SHA1',
      );
      expect(data.issuer, 'GitHub');
      expect(data.account, 'ankur.d@sarv.com');
      expect(data.secretBase32, 'JBSWY3DPEHPK3PXP');
      expect(data.digits, 6);
      expect(data.period, 30);
      expect(data.algorithm, OtpAlgorithm.sha1);
    });

    test('throws when the secret is missing', () {
      expect(
        () => parseOtpauthUri('otpauth://totp/Acme:bob?issuer=Acme'),
        throwsFormatException,
      );
    });
  });
}
