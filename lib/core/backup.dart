import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../data/account.dart';

/// Password-based encrypted backup of the account list.
///
/// Envelope: the accounts JSON is encrypted with **AES-GCM-256** under a key
/// derived from the user's passphrase via **PBKDF2-HMAC-SHA256**. A fresh
/// random salt and nonce are generated per export, so the same accounts and
/// passphrase never produce the same ciphertext, and GCM's auth tag makes a
/// wrong passphrase fail loudly instead of returning garbage.
///
/// All primitives come from the vetted `cryptography` package — no hand-rolled
/// crypto. These functions are pure given the (securely random) salt/nonce.

const String _backupFormat = 'sarv-authenticator-backup';
const int _backupVersion = 1;
// OWASP 2023 guidance for PBKDF2-HMAC-SHA256.
const int _pbkdf2Iterations = 600000;
const int _saltLength = 16;

final _algorithm = AesGcm.with256bits();

Pbkdf2 _kdf() => Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

/// Encrypts [accounts] under [passphrase] and returns the JSON envelope string
/// that gets written to the backup file.
Future<String> encryptBackup(List<Account> accounts, String passphrase) async {
  if (passphrase.isEmpty) {
    throw ArgumentError('A passphrase is required to encrypt the backup');
  }

  final salt = _randomBytes(_saltLength);
  final secretKey = await _kdf().deriveKeyFromPassword(
    password: passphrase,
    nonce: salt,
  );

  final plaintext = utf8.encode(encodeAccounts(accounts));
  final secretBox = await _algorithm.encrypt(plaintext, secretKey: secretKey);

  return jsonEncode({
    'format': _backupFormat,
    'version': _backupVersion,
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': _pbkdf2Iterations,
    'cipher': 'aes-gcm-256',
    'salt': base64Encode(salt),
    'nonce': base64Encode(secretBox.nonce),
    'ciphertext': base64Encode(secretBox.cipherText),
    'mac': base64Encode(secretBox.mac.bytes),
  });
}

/// Thrown when a backup cannot be decrypted (wrong passphrase or tampered file).
class BackupDecryptException implements Exception {
  const BackupDecryptException(this.message);
  final String message;
  @override
  String toString() => 'BackupDecryptException: $message';
}

/// Decrypts a backup envelope produced by [encryptBackup]. Throws
/// [BackupDecryptException] on a wrong passphrase, tampering, or a malformed
/// / unsupported file.
Future<List<Account>> decryptBackup(String envelopeJson, String passphrase) async {
  late final Map<String, dynamic> envelope;
  try {
    envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
  } catch (_) {
    throw const BackupDecryptException('File is not a valid backup');
  }

  if (envelope['format'] != _backupFormat) {
    throw const BackupDecryptException('Not a Sarv OTP backup');
  }
  if (envelope['version'] != _backupVersion) {
    throw BackupDecryptException('Unsupported backup version: ${envelope['version']}');
  }

  try {
    final salt = base64Decode(envelope['salt'] as String);
    final secretKey = await _kdf().deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );

    final secretBox = SecretBox(
      base64Decode(envelope['ciphertext'] as String),
      nonce: base64Decode(envelope['nonce'] as String),
      mac: Mac(base64Decode(envelope['mac'] as String)),
    );

    final clear = await _algorithm.decrypt(secretBox, secretKey: secretKey);
    return decodeAccounts(utf8.decode(clear));
  } on SecretBoxAuthenticationError {
    throw const BackupDecryptException('Wrong passphrase, or the file was modified');
  } catch (error) {
    throw BackupDecryptException('Could not read backup: $error');
  }
}
