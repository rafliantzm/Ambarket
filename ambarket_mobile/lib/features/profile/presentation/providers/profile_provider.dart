import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';

// Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client);
});

// Current Profile Provider
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchCurrentProfile(user.id);
});

// Edit Profile Controller
class EditProfileController extends AsyncNotifier<void> {
  late final ProfileRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(profileRepositoryProvider);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');
      
      await _repo.updateProfile(user.id, data);
      
      // Refresh current profile
      ref.invalidate(currentProfileProvider);
    });
  }
}

final editProfileControllerProvider = AsyncNotifierProvider<EditProfileController, void>(() {
  return EditProfileController();
});
