import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> fetchCurrentProfile(String userId);
  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> data);
}
