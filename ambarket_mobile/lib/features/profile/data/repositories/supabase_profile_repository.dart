import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<ProfileModel> fetchCurrentProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  @override
  Future<ProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    // Exclude protected fields
    data.remove('id');
    data.remove('role');
    data.remove('created_at');

    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(response);
  }
}
