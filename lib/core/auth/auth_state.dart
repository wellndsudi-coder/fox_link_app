import 'package:flutter/foundation.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isChecking => _status == AuthStatus.checking;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  void setAuthenticated() {
    if (_status != AuthStatus.authenticated) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  void setUnauthenticated() {
    if (_status != AuthStatus.unauthenticated) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void setChecking() {
    if (_status != AuthStatus.checking) {
      _status = AuthStatus.checking;
      notifyListeners();
    }
  }
}
