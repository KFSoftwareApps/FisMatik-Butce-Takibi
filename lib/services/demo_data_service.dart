import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_database_service.dart';
import '../models/receipt_model.dart';

class DemoDataService {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final _client = Supabase.instance.client;

  Future<void> insertDemoData() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    
    // 1. Demo Receipts
    final demoReceipts = [
      {
        'merchantName': 'Migros Jet',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'totalAmount': 452.50,
        'category': 'Market',
        'source': 'demo',
        'items': [
          {'name': 'Süt', 'price': 35.50, 'quantity': 2},
          {'name': 'Ekmek', 'price': 10.00, 'quantity': 3},
          {'name': 'Dana Kıyma', 'price': 350.00, 'quantity': 1},
        ],
      },
      {
        'merchantName': 'Shell Akaryakıt',
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'totalAmount': 1250.00,
        'category': 'Ulaşım',
        'source': 'demo',
        'items': [
          {'name': 'V-Power Diesel', 'price': 1250.00, 'quantity': 1},
        ],
      },
      {
        'merchantName': 'Starbucks Cafe',
        'date': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'totalAmount': 125.00,
        'category': 'Yemek',
        'source': 'demo',
        'items': [
          {'name': 'Caffe Latte', 'price': 85.00, 'quantity': 1},
          {'name': 'Cookie', 'price': 40.00, 'quantity': 1},
        ],
      },
    ];

    for (var data in demoReceipts) {
      await _databaseService.saveReceipt(data);
    }

    // 2. Demo Subscriptions
    final demoSubs = [
      {
        'user_id': user.id,
        'name': 'Netflix Premium',
        'price': 229.99,
        'renewal_day': 15,
        'color_hex': 'FFE50914', // Netflix Red
        'source': 'demo',
      },
      {
        'user_id': user.id,
        'name': 'Spotify Family',
        'price': 99.99,
        'renewal_day': 5,
        'color_hex': 'FF1DB954', // Spotify Green
        'source': 'demo',
      },
    ];

    await _client.from('subscriptions').insert(demoSubs);

    // 3. Demo Installments (Credits)
    final demoCredits = [
      {
        'user_id': user.id,
        'title': 'iPhone 15 Pro Taksit',
        'bank_name': 'Garanti BBVA',
        'total_amount': 60000.0,
        'monthly_amount': 5000.0,
        'total_installments': 12,
        'payment_day': 10,
        'is_completed': false,
        'source': 'demo',
      }
    ];

    await _client.from('user_credits').insert(demoCredits);
    
    // Set a flag that demo data is inserted so we don't do it again automatically
    // But we might want users to be able to reset/re-add.
  }

  Future<void> deleteDemoData() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Delete Demo Receipts
    await _databaseService.deleteReceiptsBySource('demo');

    // 2. Delete Demo Subscriptions
    await _client.from('subscriptions').delete().eq('user_id', user.id).eq('source', 'demo');

    // 3. Delete Demo Credits
    await _client.from('user_credits').delete().eq('user_id', user.id).eq('source', 'demo');
  }
}
