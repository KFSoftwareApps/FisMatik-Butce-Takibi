import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/services/product_normalization_service.dart';

// Note: Testing an extension usually requires an instance of the class it extends.
// Since SupabaseDatabaseService might require a Supabase client, we'll focus on the
// algorithmic parts or use a mock if possible. For simple logic tests, we can use 
// a real instance if it doesn't try to connect to Supabase on creation.

void main() {
  // Initialize Supabase with dummy values for testing
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        anonKey: 'placeholder',
      );
    } catch (e) {
      // Already initialized or other error
    }
  });

  group('Product Normalization Tests', () {
    final dbService = SupabaseDatabaseService();

    test('Should remove common Turkish brands', () {
      expect(dbService.normalizeProductName('MIGROS SUT'), 'Sut');
      expect(dbService.normalizeProductName('BIM YUMURTA'), 'Yumurta');
      expect(dbService.normalizeProductName('SUTAS AYRAN'), 'Ayran');
      expect(dbService.normalizeProductName('ULKER CIKOLATA'), 'Cikolata');
    });

    test('Should remove weight and quantity patterns', () {
      expect(dbService.normalizeProductName('ELMA 1KG'), 'Elma');
      expect(dbService.normalizeProductName('SUT 1 LT'), 'Sut');
      expect(dbService.normalizeProductName('MADEN SUYU 6X200ML'), 'Maden Suyu');
      expect(dbService.normalizeProductName('BISKUVI 3LU PK'), 'Biskuvi');
    });

    test('Should handle special characters and extra spaces', () {
      expect(dbService.normalizeProductName('  PEYNIR !!! '), 'Peynir');
      expect(dbService.normalizeProductName('COCA-COLA 2.5L'), 'Coca Cola'); // Brand check might remove it though
    });

    test('Should capitalize first letter of each word', () {
      expect(dbService.normalizeProductName('tam yagli sut'), 'Tam Yagli Sut');
      expect(dbService.normalizeProductName('DANA KIYMA'), 'Dana Kiyma');
    });

    test('Should guess categories correctly', () {
      expect(dbService.guessCategoryFromName('EKMEK'), 'Market');
      expect(dbService.guessCategoryFromName('BENZIN'), 'Akaryakıt');
      expect(dbService.guessCategoryFromName('SURAHi'), 'Ev Eşyası');
      expect(dbService.guessCategoryFromName('CIKOLATA'), 'Atıştırmalık');
      expect(dbService.guessCategoryFromName('KDV %1'), 'Diğer');
    });
  });
}
