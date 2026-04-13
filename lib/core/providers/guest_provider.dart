import 'package:flutter/foundation.dart';

/// Tracks whether the current session is a "guest" (anonymous) session.
///
/// Set to true after a successful `signInAnonymously()` call.
/// Reset to false on sign-out or when a real user logs in.
class GuestProvider extends ChangeNotifier {
  bool _isGuest = false;

  bool get isGuest => _isGuest;

  void setGuest(bool value) {
    if (_isGuest == value) return;
    _isGuest = value;
    notifyListeners();
  }
}
