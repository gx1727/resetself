import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/identity_anchor.dart';
import '../repositories/user_profile_repository.dart';
import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(appDatabaseProvider));
});

final activeIdentityAnchorsProvider = FutureProvider<List<IdentityAnchor>>((ref) async {
  return ref.watch(userProfileRepositoryProvider).getActiveIdentityAnchors();
});

final currentIdentityAnchorProvider =
    FutureProvider<IdentityAnchor?>((ref) async {
  return ref.watch(userProfileRepositoryProvider).getCurrentIdentityAnchor();
});
