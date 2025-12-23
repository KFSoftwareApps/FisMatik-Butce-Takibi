import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import 'edit_receipt_screen.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final Receipt receipt; // Başlangıç verisi (Listeden gelen)

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  String? _creatorEmail;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _loadCreatorInfo();
  }

  Future<void> _loadCreatorInfo() async {
    // Sadece aile planındaysa çalışır
    final status = await SupabaseDatabaseService().getFamilyStatus();
    if (status['has_family'] == true) {
      final members = status['members'] as List?;
      if (members != null) {
        final member = members.firstWhere(
          (m) => m['user_id'] == widget.receipt.createdBy,
          orElse: () => null,
        );
        if (member != null && mounted) {
          setState(() {
            _creatorEmail = member['email'];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder ile veritabanını canlı dinliyoruz
    return StreamBuilder<Receipt>(
      stream: SupabaseDatabaseService().getReceiptStream(widget.receipt.id),
      initialData: widget.receipt, // İlk ekranda listeden gelen veriyi göster
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text(AppLocalizations.of(context)!.receiptNotFound)),
          );
        }

        final currentReceipt = snapshot.data!;
        final locale = Localizations.localeOf(context).toString();
        final currencyFormat =
            NumberFormat.currency(locale: locale, symbol: '₺');
        final dateFormat =
            DateFormat('dd MMMM yyyy • HH:mm', locale);

        final bool isManual = currentReceipt.isManual;
        final Color accentColor =
            isManual ? AppColors.warning : AppColors.primary;
        final IconData iconData =
            isManual ? Icons.edit_note : Icons.store;
        final String sourceText =
            isManual ? AppLocalizations.of(context)!.manualEntrySource : AppLocalizations.of(context)!.scanReceiptSource;

        return Scaffold(
          backgroundColor: AppColors.headerBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, _isEdited),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditReceiptScreen(receipt: currentReceipt),
                    ),
                  );
                  
                  if (result == true && mounted) {
                    setState(() {
                      _isEdited = true;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                onPressed: () =>
                    _showDeleteConfirmDialog(context, currentReceipt.id),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // FİŞ KAĞIDI
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_creatorEmail != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _creatorEmail!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.headerBackground,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            iconData,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          currentReceipt.merchantName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kategori + Kaynak Etiketleri
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                currentReceipt.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                sourceText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(currentReceipt.date),
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Divider(
                          color: Colors.black12,
                          thickness: 1,
                        ),
                        const SizedBox(height: 16),

                        ...currentReceipt.items
                            .where((item) => !item.name.toUpperCase().contains('İNDİRİM'))
                            .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item.quantity > 1 ? '${item.quantity}x ' : ''}${item.name}",
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(item.price),
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(
                          color: Colors.black12,
                          thickness: 1,
                          height: 30,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.totalLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              currencyFormat
                                  .format(currentReceipt.totalAmount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Zigzag Efekti
                  Container(
                    height: 20,
                    color: Colors.transparent,
                    child: Row(
                      children: List.generate(
                        20,
                        (index) => Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Transform.translate(
                              offset: const Offset(0, 10),
                              child: Transform.rotate(
                                angle: 3.14 / 4,
                                child: Container(
                                  color: AppColors.headerBackground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteReceiptTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteReceiptMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseDatabaseService().deleteReceipt(id);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.receiptDeleted)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
