import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric / device-credential app lock. Thin wrapper over `local_auth`
/// plus a persisted on/off preference. All platform I/O is isolated here.
class AppLock {
  AppLock({LocalAuthentication? auth, FlutterSecureStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _prefKey = 'sarv_authenticator.lock_enabled.v1';
  static const _delayKey = 'sarv_authenticator.lock_delay_seconds.v1';
  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  /// Whether the device can actually do biometrics / PIN / pattern.
  Future<bool> get isAvailable async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (error) {
      debugPrint('AppLock.isAvailable failed: $error');
      return false;
    }
  }

  /// User preference. Defaults to OFF — the app does not lock until the user
  /// turns it on in settings.
  Future<bool> isEnabled() async {
    try {
      final raw = await _storage.read(key: _prefKey);
      return raw == 'true';
    } catch (error) {
      debugPrint('AppLock.isEnabled failed: $error');
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      await _storage.write(key: _prefKey, value: value.toString());
    } catch (error) {
      debugPrint('AppLock.setEnabled failed: $error');
      rethrow;
    }
  }

  /// How long the app may stay in the background before it re-locks. Zero means
  /// lock immediately. Defaults to immediate.
  Future<Duration> autoLockDelay() async {
    try {
      final raw = await _storage.read(key: _delayKey);
      final seconds = int.tryParse(raw ?? '') ?? 0;
      return Duration(seconds: seconds);
    } catch (error) {
      debugPrint('AppLock.autoLockDelay failed: $error');
      return Duration.zero;
    }
  }

  Future<void> setAutoLockDelay(Duration delay) async {
    try {
      await _storage.write(key: _delayKey, value: delay.inSeconds.toString());
    } catch (error) {
      debugPrint('AppLock.setAutoLockDelay failed: $error');
      rethrow;
    }
  }

  /// Prompts for biometrics / device credential. Returns true on success.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Sarv OTP to view your codes',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } catch (error, stack) {
      debugPrint('AppLock.authenticate failed: $error\n$stack');
      return false;
    }
  }
}
