import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import '../utils/currency_formatter.dart';
import 'receipt_detail_screen.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../widgets/error_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Harcamaları güne göre tutacak Map (Örn: {2025-11-20: [Receipt1, Receipt2]})
  Map<DateTime, List<Receipt>> _events = {};

  late Stream<List<Receipt>> _receiptsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _receiptsStream = _databaseService.getUnifiedReceiptsStream();
  }

  // Tüm fişleri güne göre gruplayan fonksiyon
  void _groupReceipts(List<Receipt> receipts) {
    _events = {};
    for (var receipt in receipts) {
      // Sadece yıl, ay, gün önemli
      final day = DateTime.utc(
        receipt.date.year,
        receipt.date.month,
        receipt.date.day,
      );

      if (_events[day] == null) {
        _events[day] = [];
      }
      _events[day]!.add(receipt);
    }
  }

  // Seçili günün harcamalarını döndür
  List<Receipt> _getEventsForDay(DateTime day) {
    // Harcama Map'i, UTC tarihini kullandığı için gelen günü de UTC'ye çevir
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return _events[utcDay] ?? [];
  }

  // Harcamaların toplam tutarını hesapla
  double _getDailyTotal(DateTime day) {
    return _getEventsForDay(day)
        .fold(0, (sum, receipt) => sum + receipt.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.expenditureCalendarTitle,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Receipt>>(
        stream: _receiptsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             final error = snapshot.error.toString();
             final isNetworkError = error.contains('SocketException') || error.contains('NetworkImage') || error.contains('ClientException');
             return ErrorState(
               title: isNetworkError ? (AppLocalizations.of(context)!.noInternet ?? "Bağlantı Hatası") : (AppLocalizations.of(context)!.generalError ?? "Bir Hata Oluştu"),
               description: isNetworkError 
                   ? (AppLocalizations.of(context)!.networkError ?? "İnternet bağlantınızı kontrol edip tekrar deneyin.")
                   : error,
               icon: isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
               onRetry: () {
                 setState(() {
                   _receiptsStream = _databaseService.getUnifiedReceiptsStream();
                 });
               },
             );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // İkon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 80,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Başlık
                    Text(
                      AppLocalizations.of(context)!.noReceiptsYet,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Açıklama
                    Text(
                      AppLocalizations.of(context)!.startTrackingDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Aksiyon Butonu
                    ElevatedButton.icon(
                      onPressed: () {
                        // Ana ekrana dön ve scan ekranını aç
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.scanReceiptAction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Veri geldiğinde fişleri grupla
          _groupReceipts(snapshot.data!);

          // Seçili günün harcamaları
          final selectedDay =
              _selectedDay ?? DateTime.now();
          final selectedDayReceipts = _getEventsForDay(selectedDay);
          final totalDailySpending = _getDailyTotal(selectedDay);
          final locale = Localizations.localeOf(context).toString();
          // Using CurrencyFormatter

          return Column(
            children: [
              // --- TAKVİM WIDGET'I ---
              TableCalendar<Receipt>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay, // Fişleri yükle
                locale: Localizations.localeOf(context).languageCode, // Dinamik takvim dili
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                // Marker (Harcama olan günün işaretlenmesi)
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      final dayTotal = _getDailyTotal(day);
                      final Color markerColor =
                          dayTotal > 500 ? Colors.red : AppColors.success;

                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 16.0,
                          height: 16.0,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            events.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              const SizedBox(height: 12.0),

              // --- SEÇİLİ GÜN ÖZETİ ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy', Localizations.localeOf(context).toString()).format(selectedDay),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(totalDailySpending),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: totalDailySpending > 0
                            ? AppColors.danger
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // --- SEÇİLİ GÜNÜN FİŞLERİ ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: selectedDayReceipts.length,
                  itemBuilder: (context, index) {
                    final receipt = selectedDayReceipts[index];
                    return _buildCalendarReceiptTile(
                      context: context,
                      receipt: receipt,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Takvim altındaki liste için kart
  Widget _buildCalendarReceiptTile({
    required BuildContext context,
    required Receipt receipt,
  }) {
    final bool isManual = receipt.isManual;
    final Color accentColor =
        isManual ? AppColors.warning : AppColors.primary;
    final IconData icon =
        isManual ? Icons.edit_note : Icons.receipt_long;
    final String sourceText =
        isManual ? AppLocalizations.of(context)!.manualEntryLabel : AppLocalizations.of(context)!.scanReceiptLabel;

    // Using CurrencyFormatter
    final dateText =
        DateFormat('HH:mm', Localizations.localeOf(context).toString()).format(receipt.date);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReceiptDetailScreen(receipt: receipt),
          ),
        );
        // Geri dönüldüğünde state'i yenile
        if (mounted) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "•",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          receipt.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
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
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.format(receipt.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
