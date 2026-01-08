import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../utils/currency_formatter.dart';
import '../core/app_theme.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  bool _isLoadingReceipts = true;
  List<Receipt> _userReceipts = [];
  Map<String, dynamic>? _familyStats;
  String? _errorMessage;
  late Map<String, dynamic> _user;
  String? _expandedReceiptId;

  @override
  void initState() {
    super.initState();
    _user = Map.from(widget.user);
    _loadUserReceipts();
  }

  Future<void> _loadUserReceipts() async {
    setState(() {
      _isLoadingReceipts = true;
    });

    try {
      final userId = _user['user_id'] ?? _user['id'];
      final receipts = await _databaseService.getReceiptsForUser(userId);
      final familyStats = await _databaseService.getUserFamilyStatsForAdmin(userId);
      
      if (mounted) {
        setState(() {
          _userReceipts = receipts;
          _familyStats = familyStats;
          _isLoadingReceipts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Fişler yüklenirken hata: $e";
          _isLoadingReceipts = false;
        });
      }
    }
  }

  Future<void> _reloadUserData() async {
    try {
      final userId = _user['user_id'] ?? _user['id'];
      // Basitçe admin panelindeki gibi tüm kullanıcıları çekip filtrelemek yerine
      // tek bir kullanıcıyı çeken bir metod olması daha iyi olurdu ama
      // şimdilik eldeki veriyi güncelleyelim veya listeyi yenileyelim.
      // Admin panelinden gelen veri yapısını korumak için en kolayı
      // yapılan değişikliği manuel olarak _user map'ine yansıtmak.
      setState(() {});
    } catch (e) {
      debugPrint("Kullanıcı verisi yenileme hatası: $e");
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isBlocked = _user['is_blocked'] == true;
        final isAdmin = _user['is_admin'] == true;
        final userId = _user['user_id'] ?? _user['id'];
        final email = _user['email'];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.card_membership, color: Colors.blue),
                title: const Text("Üyelik Tipi Değiştir"),
                onTap: () {
                  Navigator.pop(context);
                  _changeTier(userId, _user['tier_id'] ?? 'standart');
                },
              ),
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.check_circle : Icons.block,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                title: Text(isBlocked ? "Engeli Kaldır" : "Kullanıcıyı Engelle"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBlock(userId, isBlocked);
                },
              ),
              ListTile(
                leading: Icon(
                  isAdmin ? Icons.remove_moderator : Icons.add_moderator,
                  color: isAdmin ? Colors.red : Colors.deepPurple,
                ),
                title: Text(isAdmin ? "Yöneticiliği Al" : "Yönetici Yap"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAdmin(userId, !isAdmin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.orange),
                title: const Text("Şifre Sıfırla"),
                onTap: () {
                  Navigator.pop(context);
                  _resetPassword(email);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Kullanıcıyı Sil", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteUser(userId, email);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeTier(String userId, String currentTier) async {
    final newTier = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Üyelik Tipi Seçin"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'standart'),
            child: const Text("Ücretsiz (standart)"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'premium'),
            child: const Text("Standart (premium)"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'limitless'),
            child: const Text("Pro (limitless)"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'limitless_family'),
            child: const Text("Aile (limitless_family)"),
          ),
        ],
      ),
    );

    if (newTier != null && newTier != currentTier) {
      try {
        await _databaseService.updateUserTierForAdmin(userId, newTier);
        setState(() {
          _user['tier_id'] = newTier;
        });
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

  Future<void> _toggleBlock(String userId, bool currentStatus) async {
    try {
      await _databaseService.toggleBlockUser(userId, !currentStatus);
      setState(() {
        _user['is_blocked'] = !currentStatus;
      });
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
      setState(() {
        _user['is_admin'] = makeAdmin;
      });
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

  Future<void> _resetPassword(String email) async {
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

  Future<void> _deleteUser(String userId, String email) async {
    final confirmedEmail = await _showEmailConfirmationDialog(email);
    if (confirmedEmail != email) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _databaseService.archiveDeletedUser(email);
      // New: Use Edge Function for robust deletion
      await _databaseService.deleteUserViaEdgeFunction(userId);

      if (!mounted) return;
      Navigator.pop(context); // Loading kapat
      Navigator.pop(context); // Ekrandan çık

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı kalıcı olarak silindi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading kapat
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user['email'] ?? 'No Email';
    final userId = user['user_id'] ?? user['id'];
    final tier = (user['tier_id'] ?? 'standart').toString();
    final joinDateStr = user['join_date'];
    final joinDate = joinDateStr != null 
        ? DateTime.tryParse(joinDateStr) 
        : null;
    final formattedJoinDate = joinDate != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(joinDate) 
        : 'Bilinmiyor';
    
    final isBlocked = user['is_blocked'] == true;
    final isAdmin = user['is_admin'] == true;
    final accountStatus = user['account_status'] ?? user['raw_user_meta_data']?['account_status'];
    final isPendingDeletion = accountStatus == 'pending_deletion';
    final deletionReason = user['deletion_reason'] ?? user['raw_user_meta_data']?['deletion_reason'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Detayı"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionMenu,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPendingDeletion)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "BU KULLANICI SİLİNME TALEBİNDEDİR",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            if (deletionReason != null)
                              Text("Neden: $deletionReason"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isPendingDeletion) const SizedBox(height: 16),
            // PROFİL KARTI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
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
                      child: Text(
                        email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "ID: $userId",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // İSTATİSTİKLER / DURUM
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn("Üyelik", tier.toUpperCase(), Icons.card_membership, Colors.blue),
                        _buildInfoColumn(
                            "Durum", 
                            isBlocked ? "Engelli" : (isPendingDeletion ? "Silinecek" : "Aktif"), 
                            isBlocked ? Icons.block : (isPendingDeletion ? Icons.person_remove : Icons.check_circle), 
                            isBlocked ? Colors.red : (isPendingDeletion ? Colors.orange : Colors.green)),
                        _buildInfoColumn("Yetki", isAdmin ? "Admin" : "Kullanıcı", 
                            isAdmin ? Icons.admin_panel_settings : Icons.person, 
                            isAdmin ? Colors.deepPurple : Colors.grey),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Katılım Tarihi: $formattedJoinDate", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FİŞLER BAŞLIĞI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kullanıcı Fişleri",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_familyStats != null && _familyStats!['has_family'] == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Aile: ${_familyStats!['family_receipt_count']}",
                          style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_userReceipts.length} Fiş",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FİŞ LİSTESİ
            if (_isLoadingReceipts)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            else if (_userReceipts.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("Henüz fiş eklenmemiş.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userReceipts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final receipt = _userReceipts[index];
                  final isExpanded = _expandedReceiptId == receipt.id;

                  return Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedReceiptId = null;
                            } else {
                              _expandedReceiptId = receipt.id;
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: isExpanded ? Colors.orange : Colors.orange.shade100,
                          child: Icon(Icons.receipt, color: isExpanded ? Colors.white : Colors.orange),
                        ),
                        title: Text(receipt.merchantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(receipt.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                            CurrencyFormatter.format(receipt.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fiş İçeriği",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (receipt.items.isEmpty)
                                const Text("Ürün detayı yok.", style: TextStyle(fontSize: 12, color: Colors.grey))
                              else
                                ...receipt.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${item.quantity}x ${item.name}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(item.price * item.quantity),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Kategori:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(receipt.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
