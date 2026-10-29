import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/app_lock.dart';
import 'lock_screen.dart';

/// Whether [state] means the user has left the app, so the auto-lock clock
/// starts. Android reports the recent-apps screen as paused/hidden, but iOS
/// reports its app switcher as `inactive` only — so on iOS `inactive` counts
/// too, or the app would come back from the switcher unlocked. On Android
/// `inactive` is transient (notification shade, permission dialog) and ignored.
bool startsAutoLockClock(AppLifecycleState state, TargetPlatform platform) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.hidden ||
    (platform == TargetPlatform.iOS && state == AppLifecycleState.inactive);

/// Gates [child] behind the biometric lock. Prompts on first launch and, when
/// the app is backgrounded longer than the configured auto-lock delay, re-locks
/// and shows a blurred overlay over the code list (the list stays recognisable
/// but codes are unreadable until unlocked).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.lock, required this.child});

  final AppLock lock;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _locked = true;
  bool _authenticating = false;
  bool _lockEnabled = true;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    _lockEnabled = await widget.lock.isEnabled();
    if (!_lockEnabled) {
      setState(() => _locked = false);
    } else {
      await _unlock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A biometric prompt — ours or the Settings lock toggle's — pushes the app
    // to inactive/paused. If we treated that as a real backgrounding we would
    // re-lock the moment auth succeeds and loop forever, so ignore all
    // lifecycle changes while a prompt is on screen.
    if (_authenticating || widget.lock.isPrompting) return;

    if (startsAutoLockClock(state, defaultTargetPlatform)) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  /// Re-locks on return to the foreground if enabled and the background time
  /// exceeded the auto-lock delay. Also picks up a freshly toggled preference.
  Future<void> _maybeLockOnResume() async {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    // Never backgrounded (e.g. resume right after the unlock prompt) — nothing
    // to do. Already locked — the lock screen is already showing.
    if (backgroundedAt == null || _locked) return;

    _lockEnabled = await widget.lock.isEnabled();
    if (!_lockEnabled) return;

    final delay = await widget.lock.autoLockDelay();
    final away = DateTime.now().difference(backgroundedAt);
    if (away >= delay) {
      if (!mounted) return;
      setState(() => _locked = true);
      await _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await widget.lock.authenticate();
    // The prompt's own lifecycle churn is over; drop any background timestamp it
    // may have left so the next resume doesn't immediately re-lock.
    _backgroundedAt = null;
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _locked = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          LockScreen(onUnlock: _unlock, authenticating: _authenticating),
      ],
    );
  }
}
