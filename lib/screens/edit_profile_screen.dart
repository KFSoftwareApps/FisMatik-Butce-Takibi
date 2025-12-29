import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_io/io.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

import '../core/app_theme.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_formatter.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _initializedFromProfile = false;
  File? _selectedImage;
  String? _avatarUrl;
  String _selectedCurrency = 'TRY';

  final List<Map<String, String>> _currencies = [
    {'code': 'TRY', 'name': 'Türk Lirası (₺)'},
    {'code': 'USD', 'name': 'Amerikan Doları (\$)'},
    {'code': 'EUR', 'name': 'Euro (€)'},
    {'code': 'GBP', 'name': 'İngiliz Sterlini (£)'},
  ];

  @override
  void initState() {
    super.initState();
    _emailController.text = _client.auth.currentUser?.email ?? '';
    _loadUserAvatar();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _profileService.getMyProfileOnce();
    if (profile != null && mounted) {
      setState(() {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _phoneController.text = profile.phone;
        _cityController.text = profile.city ?? '';
        _districtController.text = profile.district ?? '';
        _selectedCurrency = profile.currency;
      });
    }
  }

  Future<void> _loadUserAvatar() async {
    final user = _client.auth.currentUser;
    if (user?.userMetadata?['avatar_url'] != null) {
      setState(() {
        _avatarUrl = user!.userMetadata!['avatar_url'];
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      try {
        final bytes = await _selectedImage!.readAsBytes();
        final userId = _client.auth.currentUser!.id;
        final fileName = 'avatar_$userId.jpg';

        await _client.storage
            .from('avatars')
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);

        await _client.auth.updateUser(
          UserAttributes(data: {'avatar_url': publicUrl}),
        );

        setState(() {
          _avatarUrl = publicUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profilePhotoUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.photoUploadError}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nameOrSurnameRequired),
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);

    try {
      final fullName = [firstName, lastName]
          .where((e) => e.trim().isNotEmpty)
          .join(' ');

      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone,
            'city': city.isNotEmpty ? city : null,
            'district': district.isNotEmpty ? district : null,
            'currency': _selectedCurrency,
          },
        ),
      );

      // Also update the user_profiles table for consistency and the location-based queries
      await _profileService.saveProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        city: city.isNotEmpty ? city : null,
        district: district.isNotEmpty ? district : null,
        currency: _selectedCurrency,
      );

      // Update Currency Provider
      if (mounted) {
        Provider.of<CurrencyProvider>(context, listen: false).setCurrency(_selectedCurrency);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.profileUpdateError}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllPasswordFields)),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch)),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.weakPasswordError)),
      );
      return;
    }

    final user = _client.auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sessionNotFound)),
      );
      return;
    }

    setState(() => _changingPassword = true);

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordUpdated),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } on AuthException catch (e) {
      String msg = AppLocalizations.of(context)!.passwordUpdateFailed;
      if (e.message.contains('Invalid login credentials')) {
        msg = AppLocalizations.of(context)!.currentPasswordIncorrect;
      } else {
        msg = e.message;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.passwordUpdateFailed}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final passwordController = TextEditingController();
    final customReasonController = TextEditingController();
    String? selectedReason;
    
    final List<String> reasons = [
      AppLocalizations.of(context)!.reasonAppNotUsed,
      AppLocalizations.of(context)!.reasonAnotherAccount,
      AppLocalizations.of(context)!.reasonPrivacyConcerns,
      AppLocalizations.of(context)!.reasonNotMeetingExpectations,
      AppLocalizations.of(context)!.reasonOther,
    ];
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.deleteAccountTitle),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteAccountWarning,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.deleteAccountDataNotice,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    AppLocalizations.of(context)!.whyLeaving,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    hint: Text(AppLocalizations.of(context)!.selectReason),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: reasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  
                  if (selectedReason == 'Diğer') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.pleaseSpecifyReason,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.enterPasswordToDelete,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.loginPasswordHint,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  String finalReason = selectedReason ?? 'Belirtilmedi';
                  if (selectedReason == 'Diğer' && customReasonController.text.isNotEmpty) {
                    finalReason = customReasonController.text.trim();
                  }
                  
                  Navigator.pop(dialogContext, {
                    'password': passwordController.text,
                    'reason': finalReason,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  AppLocalizations.of(context)!.deleteAccountTitle,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || result['password'] == null || result['password']!.isEmpty) {
      return;
    }

    final password = result['password']!;
    final reason = result['reason'];

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final user = _client.auth.currentUser;
      final email = user?.email;

      if (email == null) {
        throw Exception(AppLocalizations.of(context)!.emailNotFound);
      }

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final response = await _client.rpc('mark_account_for_deletion', params: {
        'reason': reason,
      });

      if (!mounted) return;
      Navigator.pop(context);

      if (response['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.requestReceived),
            content: Text(
              AppLocalizations.of(context)!.deleteRequestSuccess,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.generalError}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    
    if (!_initializedFromProfile && user != null) {
      _loadUserProfile();
      _initializedFromProfile = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : _avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImage == null && _avatarUrl == null
                          ? Center(
                              child: Text(
                                _firstNameController.text.isNotEmpty
                                    ? _firstNameController.text[0].toUpperCase()
                                    : _emailController.text.isNotEmpty
                                        ? _emailController.text[0].toUpperCase()
                                        : '?',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            StreamBuilder<List>(
              stream: SupabaseDatabaseService().getReceipts(),
              builder: (context, receiptsSnapshot) {
                final receipts = receiptsSnapshot.data ?? [];
                final totalReceipts = receipts.length;
                final totalSpent = receipts.fold<double>(
                  0,
                  (sum, receipt) => sum + (receipt.totalAmount ?? 0),
                );

                final user = _client.auth.currentUser;
                final memberSince = user?.createdAt != null
                    ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(
                        DateTime.parse(user!.createdAt!),
                      )
                    : AppLocalizations.of(context)!.unknown;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2575FC).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.accountStats,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.calendar_today,
                            label: AppLocalizations.of(context)!.memberSinceLabel,
                            value: memberSince,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          _buildStatItem(
                            icon: Icons.receipt_long,
                            label: AppLocalizations.of(context)!.totalReceiptsLabel(totalReceipts.toString()),
                            value: totalReceipts.toString(),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          _buildStatItem(
                            icon: Icons.attach_money,
                            label: AppLocalizations.of(context)!.totalSpendingLabel,
                            value: CurrencyFormatter.format(totalSpent),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.personalInfo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _firstNameController,
              label: AppLocalizations.of(context)!.firstNameLabel,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _lastNameController,
              label: AppLocalizations.of(context)!.lastNameLabel,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _phoneController,
              label: AppLocalizations.of(context)!.phoneLabel,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _emailController,
              label: AppLocalizations.of(context)!.loginEmailHint,
              icon: Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _cityController,
              label: AppLocalizations.of(context)!.city,
              icon: Icons.location_city_outlined,
              hintText: AppLocalizations.of(context)!.cityHint,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _districtController,
              label: AppLocalizations.of(context)!.district,
              icon: Icons.place_outlined,
              hintText: AppLocalizations.of(context)!.districtHint,
            ),
            const SizedBox(height: 16),

            // PARA BİRİMİ SEÇİMİ
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Para Birimi',
                    icon: const Icon(Icons.currency_exchange_outlined, color: AppColors.primary),
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  items: _currencies.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['code'],
                      child: Text(c['name']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCurrency = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _handleSaveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _savingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.saveProfileButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.changePasswordTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _currentPasswordController,
              label: AppLocalizations.of(context)!.currentPasswordLabel,
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _newPasswordController,
              label: AppLocalizations.of(context)!.newPasswordLabel,
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _confirmPasswordController,
              label: AppLocalizations.of(context)!.confirmNewPasswordLabel,
              icon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _changingPassword ? null : _handleChangePassword,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _changingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.updatePasswordButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),

            const Divider(height: 1),
            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.dangerZoneTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.deleteAccountSubtitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                   Text(
                    AppLocalizations.of(context)!.deleteAccountNotice,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleDeleteAccount,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: Text(
                        AppLocalizations.of(context)!.deleteAccountTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      ),
    );
  }
}
