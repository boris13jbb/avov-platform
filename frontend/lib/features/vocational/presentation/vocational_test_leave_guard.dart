/// Impide abandonar el cuestionario con una selección no confirmada por el servidor.
///
/// Lo registra [VocationalTestScreen] y lo consulta GoRouter `onExit`.
class VocationalTestLeaveGuard {
  VocationalTestLeaveGuard._();

  static final Map<int, Future<bool> Function()> _guards = {};

  static void register(int sessionId, Future<bool> Function() canLeave) {
    _guards[sessionId] = canLeave;
  }

  static void unregister(int sessionId) {
    _guards.remove(sessionId);
  }

  static Future<bool> allowLeave(int sessionId) async {
    final guard = _guards[sessionId];
    if (guard == null) {
      return true;
    }
    return guard();
  }
}
