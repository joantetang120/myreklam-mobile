import 'dart:async';
import 'package:flutter/material.dart';

/// Auth state to track authentication status
enum AuthState { authenticated, unauthenticated, sessionExpired }

/// Singleton class to manage authentication state across the app
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  AuthState _currentState = AuthState.unauthenticated;
  AuthState get currentState => _currentState;

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setAuthenticated() {
    _currentState = AuthState.authenticated;
    _authStateController.add(_currentState);
  }

  void setUnauthenticated() {
    _currentState = AuthState.unauthenticated;
    _authStateController.add(_currentState);
  }

  /// Call this when token refresh fails or when receiving 401
  void setSessionExpired() {
    _currentState = AuthState.sessionExpired;
    _authStateController.add(_currentState);
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (_navigatorKey?.currentState != null) {
      // Clear navigation stack and go to login
      _navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
