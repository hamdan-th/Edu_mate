import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tracks whether the current session is a "guest" (anonymous) session.
///
/// Automatically initializes based on the current Firebase user.
class GuestProvider extends ChangeNotifier {
  bool _isGuest = false;

  GuestProvider() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    _isGuest = user != null && user.isAnonymous;
    debugPrint('[GuestProvider] Initialized: isGuest=$_isGuest');
    
    // Listen to auth changes to keep state in sync
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final newGuestStatus = user != null && user.isAnonymous;
      if (_isGuest != newGuestStatus) {
        _isGuest = newGuestStatus;
        debugPrint('[GuestProvider] State changed: isGuest=$_isGuest');
        notifyListeners();
      }
    });
  }

  bool get isGuest => _isGuest;

  void setGuest(bool value) {
    if (_isGuest == value) return;
    _isGuest = value;
    notifyListeners();
  }
}
