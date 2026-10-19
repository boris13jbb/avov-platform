import 'package:flutter/foundation.dart';

/// Avisa a GoRouter cuando la sesión se crea o se invalida.
class SessionListenable extends ChangeNotifier {
  void notifyAuthChanged() {
    notifyListeners();
  }
}
