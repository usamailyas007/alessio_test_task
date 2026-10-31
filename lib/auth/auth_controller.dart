import 'dart:async';

import 'package:alessio_test_task/auth/auth_repository.dart';
import 'package:alessio_test_task/auth/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedOut extends AuthState {
  const SignedOut();
}

class SignedIn extends AuthState {
  const SignedIn(this.user);

  final User user;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_restore());
    return const AuthLoading();
  }

  Future<void> signIn(String username, String password) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(username, password);
    state = SignedIn(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const SignedOut();
  }

  void expire() => state = const SignedOut();

  Future<void> _restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).restore();
      state = user == null ? const SignedOut() : SignedIn(user);
    } on Object {
      state = const SignedOut();
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
