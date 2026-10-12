import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';

/// The signed-in user (null when signed out).
class SessionController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() => ref.watch(authRepositoryProvider).restoreSession();

  /// Errors are rethrown so the calling form can show them inline.
  Future<void> signIn(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> signInWithDemo() async {
    final user = await ref.read(authRepositoryProvider).signInWithDemo();
    state = AsyncData(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
  }) async {
    final user = await ref.read(authRepositoryProvider).register(
        name: name, email: email, password: password, accountType: accountType);
    state = AsyncData(user);
  }

  Future<void> updateProfile(AppUser user) async {
    final saved = await ref.read(authRepositoryProvider).updateProfile(user);
    state = AsyncData(saved);
  }

  Future<void> switchAccountType(AccountType type) async {
    final user = state.value;
    if (user == null || user.accountType == type) return;
    // Optimistic: navigation adapts immediately.
    state = AsyncData(user.copyWith(accountType: type));
    await ref.read(authRepositoryProvider).updateProfile(user.copyWith(accountType: type));
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, AppUser?>(SessionController.new);

/// Current workspace mode; defaults to business while loading.
final accountTypeProvider = Provider<AccountType>(
  (ref) => ref.watch(sessionProvider.select((s) => s.value?.accountType ?? AccountType.business)),
);
