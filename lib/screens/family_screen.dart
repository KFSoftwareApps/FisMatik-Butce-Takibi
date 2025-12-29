import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/family_model.dart';
import '../services/family_service.dart';
import '../services/auth_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final FamilyService _familyService = FamilyService();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  bool _creatingFamily = false;
  bool _addingMember = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateFamily() async {
    setState(() => _creatingFamily = true);
    try {
      await _familyService.createFamily(name: "Ailem");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aile planı oluşturuldu.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aile oluşturulamadı: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingFamily = false);
        // StreamBuilder'ı tetiklemek için setState
        setState(() {}); 
      }
    }
  }

  Future<void> _handleAddMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir e-posta girin.")),
      );
      return;
    }

    setState(() => _addingMember = true);
    try {
      await _familyService.addMemberByEmail(email: email);
      if (!mounted) return;
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Üye eklendi: $email")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception:", "").trim())),
      );
    } finally {
      if (mounted) {
        setState(() => _addingMember = false);
      }
    }
  }

  Future<void> _handleRemoveMember(FamilyMember member) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Üyeyi Çıkar"),
            content: Text("${member.email} aile planından çıkarılsın mı?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Çıkar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // ÖNEMLİ: servisteki fonksiyon email ile çalışıyor
      await _familyService.removeMemberByEmail(email: member.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${member.email} aile planından çıkarıldı.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Üye çıkarılamadı: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Aile Planı",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: StreamBuilder<Family?>(
        stream: _familyService.watchMyFamily(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final family = snapshot.data;

          if (family == null) {
            return _buildNoFamilyState();
          }

          return _buildFamilyDetail(family);
        },
      ),
    );
  }

  Widget _buildNoFamilyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Henüz bir aile planın yok",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Aile Ekonomisi planıyla bir aile oluşturup\nharcamaları birlikte yönetebilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _creatingFamily ? null : _handleCreateFamily,
              icon: _creatingFamily
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
              label: Text(
                _creatingFamily ? "Oluşturuluyor..." : "Aile Oluştur",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Not: Gerçekte aile planı için Aile Ekonomisi\npaketini satın almış olman gerekir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyDetail(Family family) {
    final currentUser = _authService.currentUser;
    final myEmail = currentUser?.email?.toLowerCase() ?? '';
    final isOwner = family.ownerUserId == currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aile kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name.isNotEmpty ? family.name : "Ailem",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOwner
                            ? "Sen bu ailenin sahibisin."
                            : "Bu aile planına dahilsin.",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Aile Üyeleri",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          ...family.members.map((m) {
            final isMe = m.email.toLowerCase() == myEmail;
            final isOwnerMember = m.role == 'owner';
            final isPending = m.status == 'pending';
            
            final textColor = isPending ? Colors.grey : AppColors.textDark;
            final subTextColor = isPending ? Colors.grey.shade400 : AppColors.textLight;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPending ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isPending ? 0.01 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isPending ? Border.all(color: Colors.grey.shade200) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isPending ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      isOwnerMember ? Icons.star : (isPending ? Icons.hourglass_empty : Icons.person),
                      size: 18,
                      color: isPending 
                          ? Colors.grey 
                          : (isOwnerMember ? Colors.orangeAccent : AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isPending)
                          Text(
                            "Onay Bekleniyor",
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade300, fontWeight: FontWeight.bold),
                          )
                        else
                          Row(
                            children: [
                              if (isOwnerMember)
                                const Text(
                                  "Sahip",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (isOwnerMember && isMe)
                                const Text(
                                  " · ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              if (isMe)
                                const Text(
                                  "Sen",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Actions
                  if (isOwner && !isOwnerMember && !isMe) ...[
                    if (isPending)
                      TextButton(
                        onPressed: () async {
                           try {
                             await _familyService.resendInvite(m.email);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Davet tekrar gönderildi.")),
                             );
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text("Hata: $e")),
                             );
                           }
                        },
                         child: const Text("Tekrar Gönder", style: TextStyle(fontSize: 11)),
                      ),
                    
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _handleRemoveMember(m), // Works for invites too? 
                      // Need to check removeMemberByEmail if it handles invites.
                      // The service update I made doesn't explicitly handle invites in removeMemberByEmail unless email matches.
                      // Since invited members are now in the list with their email, removeMemberByEmail should work 
                      // IF I update removeMemberByEmail to also delete from invitations table.
                    ),
                  ]
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Sadece sahip için: üye ekleme alanı
          if (isOwner) ...[
            const Text(
              "Aile Üyesi Ekle",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Örneğin: kisi@ornek.com",
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addingMember ? null : _handleAddMember,
                icon: _addingMember
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(
                  _addingMember ? "Ekleniyor..." : "Üye Ekle",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Not: Şu an için davet gönderdiğin e-posta ile\nkayıt olan kullanıcılar aileye otomatik bağlanır.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
