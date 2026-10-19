import 'package:flutter/material.dart';

import '../data/account.dart';
import '../data/account_store.dart';
import '../data/app_lock.dart';
import '../data/theme_controller.dart';
import 'account_tile.dart';
import 'app_logo.dart';
import 'manual_entry_screen.dart';
import 'rename_dialog.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// The main screen: a scrollable list of codes with a scan FAB — the shape of
/// Google Authenticator's home, themed with Sarv tokens. Supports search,
/// swipe-to-edit / swipe-to-delete, and a long-press actions menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.lock,
    required this.theme,
  });

  final AccountStore store;
  final AppLock lock;
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  AccountStore get store => widget.store;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Case-insensitive match on issuer or account label.
  List<Account> get _visibleAccounts {
    if (_query.isEmpty) return store.accounts;
    final needle = _query.toLowerCase();
    return store.accounts
        .where(
          (a) =>
              a.issuer.toLowerCase().contains(needle) ||
              a.account.toLowerCase().contains(needle),
        )
        .toList();
  }

  Future<void> _addFromScan() async {
    final account = await Navigator.of(context).push<Account>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (account != null) await store.add(account);
  }

  Future<void> _addManually() async {
    final account = await Navigator.of(context).push<Account>(
      MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
    );
    if (account != null) await store.add(account);
  }

  /// Offers the two enrollment paths, like Google Authenticator's add menu.
  Future<void> _showAddSheet() async {
    final tokens = context.tokens;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.rXl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.qr_code_scanner, color: tokens.brand),
              title: const Text('Scan a QR code'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addFromScan();
              },
            ),
            ListTile(
              leading: Icon(Icons.keyboard, color: tokens.brand),
              title: const Text('Enter a setup key'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addManually();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Per-account actions, triggered from the tile's overflow button.
  Future<void> _showAccountMenu(Account account) async {
    final tokens = context.tokens;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.rXl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: tokens.brand),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _rename(account);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: tokens.danger),
              title: Text('Remove', style: TextStyle(color: tokens.danger)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteWithConfirm(account);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(Account account) async {
    final result = await showRenameDialog(
      context,
      issuer: account.issuer,
      account: account.account,
    );
    if (result != null) {
      await store.rename(
        account.id,
        issuer: result.issuer,
        account: result.account,
      );
    }
  }

  /// Shows the remove-confirmation dialog and returns whether the user agreed.
  /// Does NOT remove the account — the caller decides what to do on confirm, so
  /// the swipe path can let [Dismissible] animate the row out first.
  Future<bool> _confirmRemove(Account account) async {
    final tokens = context.tokens;
    final label = account.issuer.isNotEmpty ? account.issuer : account.account;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tokens.surface,
        title: const Text('Remove account?'),
        content: Text(
          'Remove $label? You will lose access to its codes unless you have the '
          'original setup key or a backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              // White label on the danger fill in both themes — reads cleaner
              // than black on the light-theme red.
              backgroundColor: tokens.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Confirm-then-remove, used by the long-press menu.
  Future<void> _deleteWithConfirm(Account account) async {
    if (await _confirmRemove(account)) await store.remove(account.id);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          lock: widget.lock,
          store: store,
          theme: widget.theme,
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        title: _searching ? _buildSearchField(tokens) : _buildTitle(tokens),
        actions: [
          IconButton(
            icon: Icon(
              _searching ? Icons.close : Icons.search,
              color: tokens.muted,
            ),
            tooltip: _searching ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          if (!_searching)
            IconButton(
              icon: Icon(Icons.settings_outlined, color: tokens.muted),
              tooltip: 'Settings',
              onPressed: _openSettings,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (store.accounts.isEmpty) return const _EmptyState();
          final visible = _visibleAccounts;
          if (visible.isEmpty) return const _NoMatches();
          return _buildList(visible);
        },
      ),
      floatingActionButton: _searching
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddSheet,
              backgroundColor: tokens.brand,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }

  Widget _buildTitle(AppTokens tokens) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 28),
          const SizedBox(width: AppTokens.space2),
          Text(
            'Sarv Authenticator',
            style: TextStyle(
              fontFamily: AppTokens.fontSans,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
              fontSize: 18,
            ),
          ),
        ],
      );

  Widget _buildSearchField(AppTokens tokens) => TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _query = value.trim()),
        style: TextStyle(color: tokens.ink, fontFamily: AppTokens.fontSans),
        decoration: InputDecoration(
          hintText: 'Search accounts',
          border: InputBorder.none,
          hintStyle: TextStyle(color: tokens.muted),
        ),
      );

  Widget _buildList(List<Account> accounts) => ListView.builder(
        padding: const EdgeInsets.all(AppTokens.space4),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _SwipeableTile(
            key: ValueKey(account.id),
            account: account,
            onEdit: () => _rename(account),
            onConfirmRemove: () => _confirmRemove(account),
            onRemoved: () => store.remove(account.id),
            onMenu: () => _showAccountMenu(account),
          );
        },
      );
}

/// Wraps an [AccountTile] in a [Dismissible] so the row can be swiped:
/// a left swipe (content moves right→left) opens the editor, a right swipe
/// (content moves left→right) deletes after a confirmation. The swipe reveals a
/// brand edit panel on one side and a danger delete panel on the other, both
/// built from design tokens.
class _SwipeableTile extends StatelessWidget {
  const _SwipeableTile({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onConfirmRemove,
    required this.onRemoved,
    required this.onMenu,
  });

  final Account account;
  final VoidCallback onEdit;
  final Future<bool> Function() onConfirmRemove;
  final VoidCallback onRemoved;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Dismissible(
      key: ValueKey(account.id),
      // Right swipe = delete (destructive, so confirm); left swipe = edit, which
      // never dismisses the row — it opens the editor and snaps back.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return onConfirmRemove();
        }
        onEdit();
        return false;
      },
      onDismissed: (_) => onRemoved(),
      // Right-swipe panel: delete.
      background: _SwipePanel(
        color: tokens.danger,
        icon: Icons.delete_outline,
        label: 'Remove',
        alignment: Alignment.centerLeft,
        foreground: Colors.white,
      ),
      // Left-swipe panel: edit.
      secondaryBackground: _SwipePanel(
        color: tokens.brand,
        icon: Icons.edit_outlined,
        label: 'Edit',
        alignment: Alignment.centerRight,
        foreground: Colors.white,
      ),
      child: AccountTile(account: account, onMenu: onMenu),
    );
  }
}

/// The coloured panel revealed behind a row while it is being swiped.
class _SwipePanel extends StatelessWidget {
  const _SwipePanel({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
    required this.foreground,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final leading = alignment == Alignment.centerLeft;
    final children = [
      Icon(icon, color: foreground, size: 22),
      const SizedBox(width: AppTokens.space2),
      Text(
        label,
        style: TextStyle(
          fontFamily: AppTokens.fontSans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    ];
    return Container(
      // Match the tile's own bottom gap so the panel aligns with the card.
      margin: const EdgeInsets.only(bottom: AppTokens.space3),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading ? children : children.reversed.toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 56, color: tokens.muted),
            const SizedBox(height: AppTokens.space4),
            Text(
              'No accounts yet',
              style: TextStyle(
                fontFamily: AppTokens.fontSans,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Tap Add to scan a QR code or enter a setup key and add your first code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTokens.fontSans,
                fontSize: 13,
                color: tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Text(
        'No accounts match your search.',
        style: TextStyle(
          fontFamily: AppTokens.fontSans,
          fontSize: 14,
          color: tokens.muted,
        ),
      ),
    );
  }
}
