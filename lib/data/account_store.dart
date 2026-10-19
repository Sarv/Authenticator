import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'account.dart';

/// Persists accounts in the OS-backed encrypted store (Android Keystore /
/// iOS Keychain). Secrets are the crown jewels — they never touch plain
/// SharedPreferences, a file, or the network. I/O is isolated here, at the
/// edge, so the rest of the app stays pure.
class AccountStore extends ChangeNotifier {
  AccountStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'sarv_authenticator.accounts.v1';
  final FlutterSecureStorage _storage;

  List<Account> _accounts = [];
  List<Account> get accounts => List.unmodifiable(_accounts);

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _key);
      _accounts = (raw == null || raw.isEmpty) ? [] : decodeAccounts(raw);
      notifyListeners();
    } catch (error, stack) {
      debugPrint('AccountStore.load failed: $error\n$stack');
      _accounts = [];
    }
  }

  Future<void> add(Account account) async {
    _accounts = [..._accounts, account];
    await _persist();
  }

  Future<void> remove(String id) async {
    _accounts = _accounts.where((a) => a.id != id).toList();
    await _persist();
  }

  /// Renames an account's issuer/label, keeping its secret and settings.
  Future<void> rename(String id, {String? issuer, String? account}) async {
    _accounts = _accounts
        .map((a) => a.id == id
            ? a.copyWith(issuer: issuer, account: account)
            : a,)
        .toList();
    await _persist();
  }

  /// Moves an account within the list (drag-to-reorder) and persists the order.
  /// [newIndex] is the post-removal target index (as provided by
  /// ReorderableListView's onReorderItem), so no off-by-one adjustment is needed.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final next = [..._accounts];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    _accounts = next;
    await _persist();
  }

  /// Merges imported accounts, skipping ones already present (matched on
  /// issuer + account + secret, not the generated id). Returns how many were
  /// actually added.
  Future<int> importAccounts(List<Account> incoming) async {
    bool exists(Account candidate) => _accounts.any((existing) =>
        existing.issuer == candidate.issuer &&
        existing.account == candidate.account &&
        existing.secretBase32 == candidate.secretBase32,);

    final toAdd = incoming.where((a) => !exists(a)).toList();
    if (toAdd.isEmpty) return 0;

    _accounts = [..._accounts, ...toAdd];
    await _persist();
    return toAdd.length;
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _key, value: encodeAccounts(_accounts));
      notifyListeners();
    } catch (error, stack) {
      debugPrint('AccountStore._persist failed: $error\n$stack');
      rethrow;
    }
  }
}
