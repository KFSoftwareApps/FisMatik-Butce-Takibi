import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/supabase_database_service.dart';
import '../models/membership_model.dart';
import '../services/auth_service.dart';
import 'admin_notifications_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_user_detail_screen.dart';
import 'admin_product_mapping_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  // Filter enum
  String _filter = 'active'; // 'active', 'blocked', 'deleted', 'pending_deletion'
  // Sort enum
  String _sort = 'join_date'; // 'join_date', 'receipt_count', 'last_receipt', 'last_joined'
  
  List<Map<String, dynamic>> _deletedUsers = [];
  Map<String, Map<String, dynamic>> _userStats = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadUsers() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("AdminScreen: _loadData started");
      final stats = await _databaseService.getAdminStats();
      print("AdminScreen: Stats fetched: $stats");
      
      final users = await _databaseService.getAllUsersForAdmin();
      print("AdminScreen: Users fetched: ${users.length}");

      final deletedUsers = await _databaseService.getDeletedUsers();
      print("AdminScreen: Deleted users fetched: ${deletedUsers.length}");

      final userStats = await _databaseService.getUserStatsForAdmin();
      print("AdminScreen: User stats fetched: ${userStats.length}");

      if (mounted) {
        setState(() {
          _stats = stats;
          _users = users;
          _deletedUsers = deletedUsers;
          _userStats = userStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("AdminScreen: _loadData error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Veriler yüklenirken hata oluştu: $e";
          _isLoading = false;
        });
      }
    }
  }







  List<Map<String, dynamic>> _getSortedUsers(List<Map<String, dynamic>> users) {
    // Önce filtrele
    var filtered = users.where((user) {
      final isBlocked = user['is_blocked'] == true;
      
      // Filter logic
      if (_filter == 'active' && isBlocked) return false;
      if (_filter == 'blocked' && !isBlocked) return false;
      
      final accountStatus = user['account_status'] ?? user['raw_user_meta_data']?['account_status'];
      if (_filter == 'pending_deletion' && accountStatus != 'pending_deletion') return false;
      if (_filter == 'active' && accountStatus == 'pending_deletion') return false;

      if (_searchQuery.isEmpty) return true;
      final email = (user['email'] ?? '').toString().toLowerCase();
      final id = (user['user_id'] ?? user['id'] ?? '').toString().toLowerCase();
      return email.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();

    // Sonra sırala
    filtered.sort((a, b) {
      // 1. Adminler her zaman en üstte
      final isAdminA = a['is_admin'] == true;
      final isAdminB = b['is_admin'] == true;
      if (isAdminA && !isAdminB) return -1;
      if (!isAdminA && isAdminB) return 1;

      final idA = a['user_id'] ?? a['id'];
      final idB = b['user_id'] ?? b['id'];
      
      switch (_sort) {
        case 'receipt_count':
          final countA = _userStats[idA]?['receipt_count'] ?? 0;
          final countB = _userStats[idB]?['receipt_count'] ?? 0;
          return countB.compareTo(countA); // Descending
        
        case 'last_receipt':
          final dateA = _userStats[idA]?['last_receipt_date'] as DateTime? ?? DateTime(2000);
          final dateB = _userStats[idB]?['last_receipt_date'] as DateTime? ?? DateTime(2000);
          return dateB.compareTo(dateA); // Descending
          
        case 'last_joined':
        case 'join_date':
        case 'all':
        default:
          final dateA = DateTime.tryParse(a['join_date'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['join_date'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA); // Descending
      }
    });

    return filtered;
  }

  // ... (existing _getSortedUsers)

  Future<String?> _showEmailConfirmationDialog(String email) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Onay Gerekli"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bu işlem geri alınamaz. Devam etmek için lütfen kullanıcının e-posta adresini ($email) yazın."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "E-posta Adresi",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim() == email) {
                Navigator.pop(context, email);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("E-posta adresi eşleşmiyor.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock(String userId, bool currentStatus) async {
    try {
      await _databaseService.toggleBlockUser(userId, !currentStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentStatus ? "Engel kaldırıldı" : "Kullanıcı engellendi")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İşlem başarısız: $e")),
        );
      }
    }
  }

  Future<void> _toggleAdmin(String userId, bool makeAdmin) async {
    try {
      await _databaseService.toggleAdminStatus(userId, makeAdmin);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(makeAdmin ? "Kullanıcı yönetici yapıldı" : "Yöneticilik alındı")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İşlem başarısız: $e")),
        );
      }
    }
  }

  Future<void> _resetUserPassword(String email) async {
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Şifre sıfırlama e-postası gönderildi")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  Future<void> _changeTier(String userId, String currentTier) async {
    final newTier = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Üyelik Tipi Seçin"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'standart'),
            child: const Text("Ücretsiz"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'premium'),
            child: const Text("Standart"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'limitless'),
            child: const Text("Pro"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'limitless_family'),
            child: const Text("Aile Ekonomisi"),
          ),
        ],
      ),
    );

    if (newTier != null && newTier != currentTier) {
      try {
        await _databaseService.updateUserTierForAdmin(userId, newTier);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Üyelik tipi güncellendi: $newTier")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e")),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    // Güvenli Silme: E-posta doğrulama
    final confirmedEmail = await _showEmailConfirmationDialog(email);
    if (confirmedEmail != email) {
      if (mounted && confirmedEmail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-posta eşleşmedi, işlem iptal edildi.")),
        );
      }
      return;
    }

    // Loading göster
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Önce arşive ekle
      await _databaseService.archiveDeletedUser(email);

      // RPC ile hem veritabanından hem auth'dan sil
      // RPC ile hem veritabanından hem auth'dan sil (Edge Function kullanan güvenli metot)
      await _databaseService.deleteUserViaEdgeFunction(userId);

      if (!mounted) return;
      Navigator.pop(context); // Loading kapat

      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı kalıcı olarak silindi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız: $e")),
      );
    }
  }

  Future<void> _showCreateUserDialog() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController(); // [NEW] Ad Soyad Controller
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Yeni Kullanıcı Oluştur"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   // [NEW] Ad Soyad Alanı
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Ad Soyad",
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "E-posta",
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta gerekli';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: "Şifre",
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        if (value.length < 6) {
                          return 'En az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              await _databaseService.createUserForAdmin(
                                emailController.text.trim(),
                                passwordController.text,
                                nameController.text.trim().isNotEmpty ? nameController.text.trim() : null, // [NEW]
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Kullanıcı başarıyla oluşturuldu."),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadData(); // Listeyi yenile
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Hata: $e")),
                                );
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Oluştur"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.red, size: 30), // Kırmızı ve büyük + butonu
            tooltip: "Yeni Kullanıcı Ekle",
            onPressed: _showCreateUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Detaylı İstatistikler",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminStatisticsScreen(),
                ),
              );
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _databaseService.getNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => n['is_read'] != true).length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      // İSTATİSTİK KARTLARI
                      _buildStatsSummary(),
                      const SizedBox(height: 16),
                      
                      // HIZLI İŞLEMLER
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.auto_fix_high, color: AppColors.primary),
                          title: const Text("Ürün İsimlerini Düzenle"),
                          subtitle: const Text("Fişlerdeki ürün isimlerini standartlaştırın"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminProductMappingScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ARAMA ÇUBUĞU VE BAŞLIK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Kullanıcılar",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Ara (Email/ID)",
                                prefixIcon: Icon(Icons.search, size: 20),
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // SIRALAMA VE FİLTRELER
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filtreler
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('Aktif', 'active', Colors.green),
                                const SizedBox(width: 8),
                                _buildFilterChip('Engelli', 'blocked', Colors.red),
                                const SizedBox(width: 8),
                                _buildFilterChip('Silme Talebi', 'pending_deletion', Colors.orange),
                                const SizedBox(width: 8),
                                _buildFilterChip('Silinen', 'deleted', Colors.grey),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Sıralama
                          if (_filter != 'deleted')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sort,
                                  isExpanded: true,
                                  icon: const Icon(Icons.sort),
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text("Tümü")),
                                    DropdownMenuItem(value: 'join_date', child: Text("En Son Katılanlar")),
                                    DropdownMenuItem(value: 'receipt_count', child: Text("En Çok Fiş Ekleyenler")),
                                    DropdownMenuItem(value: 'last_receipt', child: Text("En Son Fiş Ekleyenler")),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _sort = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // KULLANICI LİSTESİ
                      if (_filter == 'deleted')
                        ..._deletedUsers.where((user) {
                          if (_searchQuery.isEmpty) return true;
                          final email = (user['email'] ?? '').toString().toLowerCase();
                          return email.contains(_searchQuery);
                        }).map((user) {
                          final email = user['email'] ?? 'No Email';
                          final deletedAt = user['deleted_at'] != null 
                              ? DateTime.tryParse(user['deleted_at']) 
                              : null;
                          
                          return Card(
                            color: Colors.grey.shade100,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
                              subtitle: Text("Silinme: ${deletedAt != null ? deletedAt.toString().substring(0, 16) : 'Bilinmiyor'}"),
                            ),
                          );
                        })
                      else
                        ..._getSortedUsers(_users).map((user) {
                          final userId = user['user_id'] ?? user['id'];
                          final email = user['email'] ?? 'No Email';
                          final tier = user['tier_id'] ?? 'standart';
                          final isBlocked = user['is_blocked'] == true;
                          final isAdmin = user['is_admin'] == true;
                          final accountStatus = user['account_status'] ?? user['raw_user_meta_data']?['account_status'];
                          final isPendingDeletion = accountStatus == 'pending_deletion';
                          final isCurrentUser = userId == Supabase.instance.client.auth.currentUser?.id;
                          
                          // İstatistikleri göster
                          final stats = _userStats[userId];
                          final receiptCount = stats?['receipt_count'] ?? 0;
                          final lastReceipt = stats?['last_receipt_date'] as DateTime?;
                          final lastReceiptStr = lastReceipt != null 
                              ? DateFormat('dd.MM HH:mm').format(lastReceipt) 
                              : '-';

                          return Card(
                            color: isBlocked 
                                ? Colors.red.shade50 
                                : (isPendingDeletion 
                                    ? Colors.orange.shade50 
                                    : (isAdmin ? Colors.deepPurple.shade50 : Colors.white)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminUserDetailScreen(user: user),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: isBlocked
                                    ? Colors.red
                                    : (isAdmin 
                                        ? AppColors.primary 
                                        : () {
                                            switch (tier) {
                                              case 'limitless_family':
                                                return Colors.purple;
                                              case 'limitless':
                                                return Colors.orange;
                                              case 'premium':
                                                return Colors.blue;
                                              case 'standart':
                                              default:
                                                return Colors.grey;
                                            }
                                          }()),
                                child: Icon(
                                  isBlocked 
                                      ? Icons.block 
                                      : (isPendingDeletion 
                                          ? Icons.person_remove 
                                          : (isAdmin ? Icons.admin_panel_settings : Icons.person)),
                                  color: Colors.white,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      email, 
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAdmin)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_user, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            "ADMIN",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isPendingDeletion)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            "SİLME TALEBİ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text("ID: ${userId.substring(0, 8)}...", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(width: 8),
                                      _buildTierBadge(tier),
                                    ],
                                  ),
                                  if (_sort != 'all')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Builder(
                                        builder: (context) {
                                          String text = '';
                                          if (_sort == 'receipt_count') {
                                            text = "Toplam Fiş: $receiptCount";
                                          } else if (_sort == 'last_receipt') {
                                            text = "Son Fiş: $lastReceiptStr";
                                          } else if (_sort == 'join_date') {
                                            final joinDate = DateTime.tryParse(user['join_date'] ?? '');
                                            final joinDateStr = joinDate != null 
                                                ? DateFormat('dd.MM.yyyy HH:mm').format(joinDate) 
                                                : '-';
                                            text = "Katılma: $joinDateStr";
                                          }
                                          
                                          if (text.isEmpty) return const SizedBox.shrink();

                                          return Text(
                                            text,
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isCurrentUser)
                                    IconButton(
                                      icon: Icon(
                                        isBlocked ? Icons.lock_open : Icons.block,
                                        color: isBlocked ? Colors.green : Colors.red,
                                      ),
                                      onPressed: () => _toggleBlock(userId, isBlocked),
                                      tooltip: isBlocked ? "Engeli Kaldır" : "Engelle",
                                    ),
                                  
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete_user') {
                                        _deleteUser(userId, email);
                                      } else if (value == 'toggle_admin') {
                                        _toggleAdmin(userId, !isAdmin);
                                      } else if (value == 'reset_password') {
                                        _resetUserPassword(email);
                                      } else if (value == 'change_tier') {
                                        _changeTier(userId, tier);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        if (!isCurrentUser)
                                          PopupMenuItem(
                                            value: 'toggle_admin',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isAdmin ? Icons.remove_moderator : Icons.add_moderator,
                                                  color: isAdmin ? Colors.red : Colors.green,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(isAdmin ? "Adminliği Al" : "Admin Yap"),
                                              ],
                                            ),
                                          ),
                                        
                                        const PopupMenuItem(
                                          value: 'reset_password',
                                          child: Row(
                                            children: [
                                              Icon(Icons.lock_reset, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text("Şifre Sıfırla"),
                                            ],
                                          ),
                                        ),

                                        const PopupMenuItem(
                                          value: 'change_tier',
                                          child: Row(
                                            children: [
                                              Icon(Icons.card_membership, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text("Üyelik Tipi Değiştir"),
                                            ],
                                          ),
                                        ),
                                        
                                        if (!isCurrentUser)
                                          const PopupMenuItem(
                                            value: 'delete_user',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_forever, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text("Kullanıcıyı Sil"),
                                              ],
                                            ),
                                          ),
                                      ];
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTierBadge(String tierId) {
    String label;
    Color color;
    IconData icon;

    switch (tierId) {
      case 'limitless_family':
        label = 'Aile';
        color = Colors.purple;
        icon = Icons.family_restroom;
        break;
      case 'limitless':
        label = 'Pro';
        color = Colors.orange;
        icon = Icons.star;
        break;
      case 'premium':
        label = 'Standart';
        color = Colors.blue;
        icon = Icons.verified;
        break;
      case 'standart':
      default:
        label = 'Ücretsiz';
        color = Colors.grey;
        icon = Icons.person_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: isSelected ? Icon(Icons.check, size: 18, color: color) : null,
    );
  }

  Widget _buildStatsSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          "Toplam Kullanıcı",
          "${_stats['total_users'] ?? 0}",
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          "Toplam Fiş",
          "${_stats['total_receipts'] ?? 0}",
          Icons.receipt_long,
          Colors.orange,
        ),
        _buildStatCard(
          "Aktif Abonelik",
          "${_stats['active_subscriptions'] ?? 0}",
          Icons.subscriptions,
          Colors.purple,
        ),
        _buildStatCard(
          "Silinen Kullanıcı",
          "${_stats['pending_deletions'] ?? 0}",
          Icons.person_remove,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
