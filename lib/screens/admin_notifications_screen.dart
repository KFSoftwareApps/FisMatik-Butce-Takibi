import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_database_service.dart'; // [NEW] import
import '../core/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService(); // [NEW] service
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  String _filterType = 'all'; // 'all', 'read', 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Bildirim yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_filterType == 'read') {
      return _notifications.where((n) => n['is_read'] == true).toList();
    } else if (_filterType == 'unread') {
      return _notifications.where((n) => n['is_read'] != true).toList();
    }
    return _notifications;
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // Listeyi güncelle
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('Okundu işaretleme hatası: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // FİLTRE BUTONLARI
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterButton('Tümü', 'all'),
                const SizedBox(width: 8),
                _buildFilterButton('Okunmamış', 'unread'),
                const SizedBox(width: 8),
                _buildFilterButton('Okunmuş', 'read'),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "Bildirim yok",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final notification = filteredList[index];
                            final isRead = notification['is_read'] == true;
                            final type = notification['type'];
                            final createdAt = DateTime.parse(notification['created_at']);

                            IconData icon;
                            Color iconColor;

                            switch (type) {
                              case 'account_deletion_request':
                                icon = Icons.person_remove;
                                iconColor = Colors.red;
                                break;
                              case 'system_test':
                                icon = Icons.build;
                                iconColor = Colors.blue;
                                break;
                              default:
                                icon = Icons.notifications;
                                iconColor = AppColors.primary;
                            }

                            return Dismissible(
                              key: Key(notification['id']),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteNotification(notification['id']),
                              child: Card(
                                color: isRead ? Colors.white : Colors.blue.shade50,
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: iconColor.withOpacity(0.1),
                                        child: Icon(icon, color: iconColor),
                                      ),
                                      title: Text(
                                        notification['title'] ?? 'Bildirim',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(notification['message'] ?? ''),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeago.format(createdAt, locale: 'tr'),
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        if (!isRead) _markAsRead(notification['id']);
                                      },
                                    ),
                                    // AKSİYON BUTONLARI
                                    _buildActionButtons(notification),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String type) {
    final isSelected = _filterType == type;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _filterType = type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // YENİ: Aksiyon Butonları (Onay / Ret)
  Widget _buildActionButtons(Map<String, dynamic> notification) {
    if (notification['type'] != 'account_deletion_request') return const SizedBox.shrink();

    final data = notification['data'] ?? {};
    final targetUserId = data['request_user_id'];
    final requestId = data['request_id'];
    final actionTaken = data['action_taken'] == true || data['action_taken'] == 'true';
    final isRead = notification['is_read'] == true;

    // Butonları gizle eğer: action alınmışsa VEYA bildirim okunmuşsa
    if (targetUserId == null || actionTaken || isRead) {
      return Padding(
        padding: const EdgeInsets.only(left: 72, bottom: 8),
        child: Row(
          children: [
             Icon(Icons.check_circle, size: 16, color: Colors.green),
             const SizedBox(width: 4),
             Text(
               actionTaken ? "İşlem Yapıldı" : "Tamamlandı / Okundu",
               style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
             ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
      child: Row(
        children: [
          // REDDET BUTONU
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleReject(targetUserId, requestId, notification['id']),
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              label: const Text("Reddet", style: TextStyle(color: Colors.grey)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ONAYLA BUTONU
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleApprove(targetUserId, notification['id']),
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text("Onayla (Sil)", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(String targetUserId, dynamic requestId, String notificationId) async {
    try {
      await _client.rpc('admin_reject_deletion', params: {
        'target_user_id': targetUserId,
        'request_id': requestId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Talep reddedildi, kullanıcı erişimi açıldı.")),
      );
      
      // Bildirimi okundu olarak işaretle
      _markAsRead(notificationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  Future<void> _handleApprove(String targetUserId, String notificationId) async {
    // Emin misin diyaloğu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Sil?"),
        content: const Text("Bu işlem geri alınamaz. Kullanıcı ve tüm verileri (fişler, abonelikler vb.) silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("SİL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // YENİ RPC: admin_confirm_deletion (Kullanıcıyı veritabanından siler)
      await _client.rpc('admin_confirm_deletion', params: {
        'target_user_id': targetUserId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı ve tüm verileri başarıyla silindi.")),
      );

      // Bildirimi silmek yerine okundu olarak işaretle ve UI'ı güncelle
      // _deleteNotification(notificationId);
      
      // UI güncellemesi için action_taken bilgisini yerel olarak güncelle
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          // Data objesini kopyala ve güncelle
          final currentData = Map<String, dynamic>.from(_notifications[index]['data'] ?? {});
          currentData['action_taken'] = true;
          _notifications[index]['data'] = currentData;
          _notifications[index]['is_read'] = true;
        }
      });
      
      // Backend'de okundu işaretle (Data update is optional atm as RPC does the heavy lifting)
      await _markAsRead(notificationId);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme hatası: $e")),
      );
    }
  }
}
