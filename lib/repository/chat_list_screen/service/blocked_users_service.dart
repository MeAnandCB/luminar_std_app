import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maintains an on-device list of blocked user IDs.
///
/// Messages and chats from blocked users are hidden instantly across the
/// app (Guideline 1.2 — user-generated content blocking requirement).
class BlockedUsersService extends ChangeNotifier {
  static const String _prefsKey = 'blocked_user_ids';

  Set<int> _blockedIds = {};

  Set<int> get blockedIds => _blockedIds;

  bool isBlocked(int? userId) =>
      userId != null && _blockedIds.contains(userId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _blockedIds = stored.map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toSet();
    notifyListeners();
  }

  Future<void> blockUser(int userId) async {
    if (_blockedIds.contains(userId)) return;
    _blockedIds.add(userId);
    await _persist();
    notifyListeners();
  }

  Future<void> unblockUser(int userId) async {
    if (!_blockedIds.contains(userId)) return;
    _blockedIds.remove(userId);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _blockedIds.map((e) => e.toString()).toList(),
    );
  }
}
