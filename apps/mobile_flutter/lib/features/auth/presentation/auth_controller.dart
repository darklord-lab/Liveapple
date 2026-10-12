import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../../core/errors/app_exception.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState.initial()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = AuthState.loading();
    try {
      final user = await _repository.checkAuthStatus();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } on AppException catch (e) {
      state = AuthState.error(e.message, e.code);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred during login');
      return false;
    }
  }

  Future<bool> acceptInvite({
    required String inviteCode,
    required String password,
    String? name,
    String? phone,
    String? email,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.acceptInvite(
        inviteCode: inviteCode,
        password: password,
        name: name,
        phone: phone,
        email: email,
      );
      state = AuthState.authenticated(user);
      return true;
    } on AppException catch (e) {
      state = AuthState.error(e.message, e.code);
      return false;
    } catch (e) {
      state = AuthState.error('Failed to accept invite');
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }
}
