// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:math';
import 'dart:html' as html;

const _keyLeader = 'rifa_presence_leader';
const _keyTabId = 'rifa_presence_tab_id';
const _leaderStaleMs = 5000;

String _getOrCreateTabId() {
  try {
    final storage = html.window.sessionStorage;
    var id = storage[_keyTabId];
    if (id == null || id.isEmpty) {
      id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}';
      storage[_keyTabId] = id;
    }
    return id;
  } catch (_) {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}';
  }
}

// Formato: "timestamp|tabId" para poder parsear sin ambigüedad.
bool _isLeaderStale(String? stored) {
  if (stored == null || stored.isEmpty) return true;
  final idx = stored.indexOf('|');
  if (idx <= 0) return true;
  final ts = int.tryParse(stored.substring(0, idx));
  if (ts == null) return true;
  return DateTime.now().millisecondsSinceEpoch - ts > _leaderStaleMs;
}

bool presenceAmILeader() {
  try {
    final stored = html.window.localStorage[_keyLeader];
    if (stored == null || stored.isEmpty) return false;
    final idx = stored.indexOf('|');
    if (idx <= 0) return false;
    final ts = int.tryParse(stored.substring(0, idx));
    final tabId = stored.substring(idx + 1);
    if (ts == null) return false;
    final myId = _getOrCreateTabId();
    if (tabId != myId) return false;
    return DateTime.now().millisecondsSinceEpoch - ts <= _leaderStaleMs;
  } catch (_) {
    return false;
  }
}

bool presenceTryClaimLeader() {
  try {
    final myId = _getOrCreateTabId();
    final stored = html.window.localStorage[_keyLeader];
    if (!_isLeaderStale(stored)) {
      final idx = stored!.indexOf('|');
      if (idx > 0 && stored.substring(idx + 1) != myId) return false;
    }
    html.window.localStorage[_keyLeader] = '${DateTime.now().millisecondsSinceEpoch}|$myId';
    return true;
  } catch (_) {
    return false;
  }
}

/// Llamar cada ~2s desde un Timer en el widget. Refresca si somos líder; si no y el líder está inactivo, reclama y llama onBecameLeader.
void presenceHeartbeatTick(void Function() onBecameLeader) {
  try {
    if (presenceAmILeader()) {
      final myId = _getOrCreateTabId();
      html.window.localStorage[_keyLeader] = '${DateTime.now().millisecondsSinceEpoch}|$myId';
      return;
    }
    if (_isLeaderStale(html.window.localStorage[_keyLeader])) {
      if (presenceTryClaimLeader()) onBecameLeader();
    }
  } catch (_) {}
}
