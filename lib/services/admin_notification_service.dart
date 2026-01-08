import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminNotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Admin kullanıcılarını getir
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _client.rpc('get_admin_users');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Admin kullanıcıları getirilemedi: $e');
      return [];
    }
  }



  /// Bekleyen silme taleplerini getir (Admin için)
  Future<List<Map<String, dynamic>>> getPendingDeletionRequests() async {
    try {
      final response = await _client.rpc('get_pending_deletions');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Bekleyen talepler getirilemedi: $e');
      return [];
    }
  }
}
