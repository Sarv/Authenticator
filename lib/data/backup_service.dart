import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/backup.dart';
import 'account.dart';

/// File-level glue for encrypted backups: turns the [encryptBackup] /
/// [decryptBackup] core into "share a file" and "pick a file" operations.
/// All disk / platform I/O lives here, at the edge.
class BackupService {
  const BackupService();

  static const _extension = 'sauthbackup';

  /// Encrypts [accounts] with [passphrase], writes the envelope to a timestamped
  /// file, and opens the system share sheet so the user can save or send it.
  Future<void> exportAndShare({
    required List<Account> accounts,
    required String passphrase,
  }) async {
    final envelope = await encryptBackup(accounts, passphrase);

    // UTC timestamp in the filename so backups sort correctly everywhere.
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sarv-authenticator-$stamp.$_extension');
    await file.writeAsString(envelope, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Sarv Authenticator backup',
    );
  }

  /// Lets the user pick a backup file and decrypts it with [passphrase].
  /// Returns null if the user cancels the picker.
  Future<List<Account>?> pickAndDecrypt({required String passphrase}) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes = picked.bytes ??
        (picked.path != null ? await File(picked.path!).readAsBytes() : null);
    if (bytes == null) {
      throw const BackupDecryptException('Could not read the selected file');
    }

    return decryptBackup(String.fromCharCodes(bytes), passphrase);
  }
}
