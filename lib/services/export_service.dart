import 'package:universal_io/io.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart'; // [NEW] kIsWeb için
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart'; 
import 'package:universal_html/html.dart' as html; // [NEW] Web download için
import 'supabase_database_service.dart';
import 'report_service.dart';
import '../models/receipt_model.dart';

class ExportService {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();

  // Yardımcı Metot: Dosyayı İndirilenler Klasörüne Kaydet
  Future<String?> _saveFileToDownloads(List<int> bytes, String fileName) async {
    // WEB PLATFORMU
    if (kIsWeb) {
      try {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return "İndirilenler klasörü (Tarayıcı)";
      } catch (e) {
        print("Web indirme hatası: $e");
        return null;
      }
    }

    // MOBİL PLATFORM
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String filePath = "${directory!.path}/$fileName";
      final File file = File(filePath);
      
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print("Dosya kaydetme hatası: $e");
      return null;
    }
  }

  // İzin İsteme Yardımcısı
  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (kIsWeb) return true; // Web'de izne gerek yok

    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Depolama izni reddedildi. Ayarlardan açmanız gerekebilir.")),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> exportReceiptsToExcel(BuildContext context) async {
    try {
      final List<Receipt> receipts = await _databaseService.getAllReceiptsOnce();
      if (receipts.isEmpty) return;
      
      await ReportService().generateAndShareExcelReport(receipts);
    } catch (e) {
      debugPrint("Excel Export Hatası: $e");
    }
  }

  Future<void> exportTaxReportToExcel(BuildContext context) async {
    try {
      final List<Receipt> receipts = await _databaseService.getAllReceiptsOnce();
      if (receipts.isEmpty) return;

      await ReportService().generateAndShareExcelReport(receipts, isTaxReport: true);
    } catch (e) {
      debugPrint("Vergi Raporu Hatası: $e");
    }
  }
}
