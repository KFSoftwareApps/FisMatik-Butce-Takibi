import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  /// Mevcut konumun şehir ve ilçe bilgisini döndürür.
  Future<Map<String, String?>?> getCurrentCityAndDistrict() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Konum servisleri açık mı?
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      // Mevcut pozisyonu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Koordinatları adrese çevir (Reverse Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'city': place.administrativeArea, // Genelde İl (İstanbul)
          'district': place.subAdministrativeArea ?? place.locality, // Genelde İlçe (Kadıköy)
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Konum izni durumunu kontrol eder.
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}
