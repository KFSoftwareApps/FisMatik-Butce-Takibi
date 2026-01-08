import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/profile_service.dart';
import '../services/location_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class LocationOnboardingDialog extends StatefulWidget {
  const LocationOnboardingDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final profile = await ProfileService().getMyProfileOnce();
    
    // Check if city or district is missing
    if (profile != null && (profile.city == null || profile.city!.isEmpty) && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationOnboardingDialog(),
      );
    }
  }

  @override
  State<LocationOnboardingDialog> createState() => _LocationOnboardingDialogState();
}

class _LocationOnboardingDialogState extends State<LocationOnboardingDialog> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  bool _isDetecting = false;
  bool _isSaving = false;

  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    try {
      final locationData = await LocationService().getCurrentCityAndDistrict();
      if (locationData != null && mounted) {
        setState(() {
          _cityController.text = locationData['city'] ?? '';
          _districtController.text = locationData['district'] ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.locationDetected(
              locationData['city'] ?? '-',
              locationData['district'] ?? '-',
            )),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.locationError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _handleSave() async {
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cityHint)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await ProfileService().getMyProfileOnce();
      if (profile != null) {
        await ProfileService().saveProfile(
          firstName: profile.firstName,
          lastName: profile.lastName,
          phone: profile.phone,
          city: city,
          district: district.isNotEmpty ? district : null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.processSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing with back button
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.locationSettings,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.locationOnboardingDescription,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.city,
                  hintText: AppLocalizations.of(context)!.cityHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.district,
                  hintText: AppLocalizations.of(context)!.districtHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.place),
                ),
              ),
              const SizedBox(height: 16),
              // OTOMATİK KONUM BUTONU
              TextButton.icon(
                onPressed: _isDetecting ? null : _detectLocation,
                icon: _isDetecting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _isDetecting 
                    ? AppLocalizations.of(context)!.detecting 
                    : AppLocalizations.of(context)!.detectLocation,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
