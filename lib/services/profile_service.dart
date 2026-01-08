import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getUserProfile(String userId) async {
    // For now we ignore userId if it's strictly for the current user, 
    // or we use it if we want to fetch specific user (but RLS might block).
    // Assuming mostly for current user or public profile logic.
    if (userId == _client.auth.currentUser?.id) {
      return getMyProfileOnce();
    }
    // Logic for other users if needed:
    try {
      final data = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }
    return user.id;
  }

  String get _email {
    final user = _client.auth.currentUser;
    return user?.email ?? '';
  }

  // Canlı profil dinleme
  Stream<UserProfile?> watchMyProfile() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _client
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((maps) {
          if (maps.isEmpty) return null;
          final data = maps.first;
          // Supabase stream returns data directly, but we might need to inject ID if it's not in the map (usually it is)
          return UserProfile.fromMap(data);
        });
  }

  // Tek seferlik okuma
  Future<UserProfile?> getMyProfileOnce() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      print("Profil getirme hatası: $e");
      return null;
    }
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? city,
    String? district,
    String currency = 'TRY',
  }) async {
    final uid = _uid;
    final email = _email;

    await _client.from('user_profiles').upsert({
      'id': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'city': city,
      'district': district,
      'currency': currency,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
