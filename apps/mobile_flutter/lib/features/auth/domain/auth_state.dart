import 'user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? errorCode;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message, [String? code]) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
        errorCode: code,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
}
