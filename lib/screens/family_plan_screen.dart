import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../core/app_theme.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class FamilyPlanScreen extends StatefulWidget {
  const FamilyPlanScreen({super.key});

  @override
  State<FamilyPlanScreen> createState() => _FamilyPlanScreenState();
}

class _FamilyPlanScreenState extends State<FamilyPlanScreen> {
  final FamilyService _familyService = FamilyService();
  bool _isLoading = true;
  Map<String, dynamic>? _familyStatus;
  List<Map<String, dynamic>> _pendingInvitations = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyStatus();
  }

  Future<void> _loadFamilyStatus() async {
    print("DEBUG: _loadFamilyStatus started");
    setState(() => _isLoading = true);
    try {
      print("DEBUG: fetching getFamilyStatus...");
      final status = await _familyService.getFamilyStatus();
      print("DEBUG: fetching getPendingInvitations...");
      final invitations = await _familyService.getPendingInvitations();
      print("DEBUG: updating state with status: $status");
      setState(() {
        _familyStatus = status;
        _pendingInvitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG: Aile durumu yüklenirken hata: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createFamily),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.familyNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.addressLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.addressHint,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.addressRequired)),
                );
                return;
              }
              
              print("DEBUG: create family button clicked");
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                print("DEBUG: calling createFamilyWrapper...");
                final result = await _familyService.createFamilyWrapper(
                  nameController.text.isEmpty ? "Ailem" : nameController.text,
                  addressController.text,
                );
                print("DEBUG: createFamilyWrapper result: $result");
                
                if (result['success'] == true) {
                  await _loadFamilyStatus();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.familyCreatedSuccess)),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? "Hata oluştu")),
                    );
                  }
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: $e")),
                  );
                }
                setState(() => _isLoading = false);
              }
            },
            child: Text(AppLocalizations.of(context)!.createButton),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteMember() async {
    final members = (_familyStatus?['members'] as List?) ?? [];
    if (members.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.familyLimitReached),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.inviteMember),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterEmailToInvite),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.loginEmailHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.inviteSending)),
              );

              try {
                final result = await _familyService.sendFamilyInvite(emailController.text.trim());
                
                if (mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.inviteSentSuccess)),
                    );
                    await _loadFamilyStatus();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? "Hata oluştu"), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.inviteMember),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.leaveFamilyTitle),
        content: Text(AppLocalizations.of(context)!.leaveFamilyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.leaveFamilyButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final result = await _familyService.leaveFamily();
        if (result['success'] == true) {
          await _loadFamilyStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.leftFamilySuccess)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? "Hata oluştu")),
            );
          }
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e")),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeMemberTitle),
        content: Text(AppLocalizations.of(context)!.removeMemberConfirm(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.removeButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final result = await _familyService.removeFamilyMemberById(userId);
        if (result['success'] == true) {
          await _loadFamilyStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.memberRemovedSuccess)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? "Hata oluştu")),
            );
          }
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.familyPlanTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final hasFamily = _familyStatus?['has_family'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingInvitations.isNotEmpty) _buildPendingInvitations(),
          if (!hasFamily) _buildNoFamilyUI(),
          if (hasFamily) _buildFamilyDetailsUI(),
        ],
      ),
    );
  }

  Widget _buildPendingInvitations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bekleyen Davetler",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._pendingInvitations.map((inv) => Card(
          color: Colors.blue.shade50,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text("${inv['family_name']} Ailesi"),
            subtitle: Text("Davet eden: ${inv['owner_email']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _handleAcceptInvite(inv['family_id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _handleRejectInvite(inv['family_id']),
                ),
              ],
            ),
          ),
        )),
        const Divider(height: 32),
      ],
    );
  }

  Future<void> _handleAcceptInvite(String familyId) async {
    setState(() => _isLoading = true);
    final result = await _familyService.acceptFamilyInvite(familyId);
    if (result['success']) {
      await _loadFamilyStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aileye başarıyla katıldınız.")),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  Future<void> _handleRejectInvite(String familyId) async {
    setState(() => _isLoading = true);
    final result = await _familyService.rejectFamilyInvite(familyId);
    if (result['success']) {
      await _loadFamilyStatus();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildNoFamilyUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 80, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noFamilyYet,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.familyPlanDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createFamily,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createFamily),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyDetailsUI() {
    final householdName = _familyStatus?['household_name'] ?? 'Ailem';
    final role = _familyStatus?['role'];
    final members = (_familyStatus?['members'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.home, size: 30, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          householdName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          role == 'owner' ? AppLocalizations.of(context)!.adminLabel : AppLocalizations.of(context)!.memberLabel,
                          style: TextStyle(
                            color: role == 'owner' ? Colors.orange : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Members Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.familyMembersCount,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: members.length >= 5 ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${members.length}/5",
                      style: TextStyle(
                        color: members.length >= 5 ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (role == 'owner')
                TextButton.icon(
                  onPressed: members.length >= 5 ? null : _inviteMember,
                  icon: const Icon(Icons.person_add),
                  label: Text(AppLocalizations.of(context)!.inviteMember),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member['user_id'] == _familyService.currentUser?.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      (member['email'] as String).isNotEmpty ? (member['email'] as String)[0].toUpperCase() : "?",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(member['email']),
                  subtitle: Row(
                    children: [
                      Text(member['role'] == 'owner' ? AppLocalizations.of(context)!.adminLabel : AppLocalizations.of(context)!.memberLabel),
                      if (member['status'] == 'pending') ...[
                        const Text(" • "),
                        Text(
                          "Bekliyor",
                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  trailing: (role == 'owner' && !isMe)
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeMember(member['user_id'], member['email']),
                          tooltip: AppLocalizations.of(context)!.removeFromFamilyTooltip,
                        )
                      : (member['role'] == 'owner' 
                          ? const Icon(Icons.star, color: Colors.orange) 
                          : null),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Leave Button
          if (role != 'owner')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _leaveFamily,
                icon: const Icon(Icons.exit_to_app),
                label: Text(AppLocalizations.of(context)!.leaveFamilyTitle),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            if (role == 'owner')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.ownerCannotLeaveNotice,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
        ],
    );
  }
}
