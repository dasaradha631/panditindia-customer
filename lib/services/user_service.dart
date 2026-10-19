import 'dart:convert';

import '../core/network/api_client.dart';
import '../models/user_session.dart';

class UserService {
  Future<CustomerProfile?> getProfile() async {
    try {
      final res = await ApiClient.get('/user/profile');
      final body = res.body;
      final user = body['user'];
      if (user is Map<String, dynamic>) return CustomerProfile.fromJson(user);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(CustomerProfile profile) async {
    try {
      final res = await ApiClient.put(
        '/user/profile',
        body: profile.toUpdatePayload(),
      );
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<FamilyMember>> familyMembers(CustomerProfile profile) async {
    final raw = profile.familyMembers;
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
