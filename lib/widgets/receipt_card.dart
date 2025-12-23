import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih ve Para formatı için
import '../core/app_theme.dart';
import '../models/receipt_model.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap; // Karta tıklanınca ne olacak?

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tarih formatlayıcı (Örn: 20 Kasım 2023)
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    // Para formatlayıcı (Örn: ₺254,50)
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // Kartlar arası boşluk
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20), // Köşeleri yuvarla
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Hafif gölge
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. SOL TARAFTAKİ İKON
            _buildIconBox(),
            
            const SizedBox(width: 16), // Boşluk
            
            // 2. ORTA KISIM (Mağaza Adı ve Tarih)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${dateFormat.format(receipt.date)} • Market", // Kategori şimdilik sabit
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // 3. SAĞ KISIM (Tutar)
            Text(
              currencyFormat.format(receipt.totalAmount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900, // Daha kalın yazı
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İkon kutusunu çizen yardımcı fonksiyon
  Widget _buildIconBox() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1), // Yeşilimsi arka plan
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.shopping_cart, // Market ikonu
        color: AppColors.success,
      ),
    );
  }
}
