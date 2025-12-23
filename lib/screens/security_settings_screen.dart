import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/app_theme.dart';
import '../services/biometric_service.dart';

/// Güvenlik Ayarları Ekranı
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _autoLockDuration = 'immediate';
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final duration = await _biometricService.getAutoLockDuration();
    final biometrics = await _biometricService.getAvailableBiometrics();

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _autoLockDuration = duration;
      _availableBiometrics = biometrics;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        // Önce test et
        final success = await _biometricService.authenticate(
          reason: 'Biometrik güvenliği etkinleştirmek için kimliğinizi doğrulayın',
        );

        if (success) {
          await _biometricService.setBiometricEnabled(true);
          setState(() => _biometricEnabled = true);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometrik güvenlik etkinleştirildi')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kimlik doğrulama başarısız oldu')),
            );
          }
        }
      } else {
        await _biometricService.setBiometricEnabled(false);
        setState(() => _biometricEnabled = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrik güvenlik devre dışı bırakıldı')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _setAutoLockDuration(String duration) async {
    await _biometricService.setAutoLockDuration(duration);
    setState(() => _autoLockDuration = duration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Güvenlik Ayarları'),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Biometrik Güvenlik
                _buildSection(
                  title: '🔐 Biometrik Güvenlik',
                  children: [
                    if (!_biometricAvailable)
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: const Text('Biometrik Desteği Yok'),
                        subtitle: const Text(
                          'Bu cihazda biometrik kimlik doğrulama desteklenmiyor',
                        ),
                      )
                    else ...[
                      SwitchListTile(
                        title: Text(
                          _biometricService.getBiometricTypeString(_availableBiometrics),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Uygulama açılışında kimlik doğrula'),
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                        activeColor: AppColors.primary,
                      ),
                      
                      if (_biometricEnabled) ...[
                        const Divider(),
                        
                        // Auto-lock süresi
                        ListTile(
                          title: const Text(
                            'Otomatik Kilitleme',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(_getAutoLockLabel(_autoLockDuration)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showAutoLockDialog,
                        ),
                      ],
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Bilgi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Biometrik verileriniz cihazınızda güvenli bir şekilde saklanır ve FişMatik\'e aktarılmaz.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getAutoLockLabel(String duration) {
    switch (duration) {
      case 'immediate':
        return 'Hemen';
      case '1min':
        return '1 Dakika';
      case '5min':
        return '5 Dakika';
      case '15min':
        return '15 Dakika';
      default:
        return 'Hemen';
    }
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otomatik Kilitleme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDurationOption('immediate', 'Hemen'),
            _buildDurationOption('1min', '1 Dakika'),
            _buildDurationOption('5min', '5 Dakika'),
            _buildDurationOption('15min', '15 Dakika'),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String value, String label) {
    final isSelected = _autoLockDuration == value;
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        _setAutoLockDuration(value);
        Navigator.pop(context);
      },
    );
  }
}
