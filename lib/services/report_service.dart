import 'package:universal_io/io.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/currency_formatter.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../models/receipt_model.dart';

class ReportService {
  // --- PDF RAPORU ---
  Future<void> generateAndSharePdfReport(List<Receipt> receipts, DateTime start, DateTime end, {String? title, bool isTaxReport = false}) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Using CurrencyFormatter
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');

    double totalAmount = receipts.fold(0, (sum, item) => sum + item.totalAmount);
    double totalTax = receipts.fold(0, (sum, item) {
      final tax = item.taxAmount > 0 ? item.taxAmount : (item.totalAmount / 1.10 * 0.10);
      return sum + tax;
    });

    final reportTitle = title ?? (isTaxReport ? 'Vergi Raporu' : 'Harcama Raporu');
    final primaryColor = isTaxReport ? PdfColors.red700 : PdfColors.indigo700;

    // Kategori Özeti
    final Map<String, double> categorySpending = {};
    for (var r in receipts) {
      categorySpending[r.category] = (categorySpending[r.category] ?? 0) + r.totalAmount;
    }
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            // BAŞLIK
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FişMatik $reportTitle', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.Text(dateFormat.format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Tarih Aralığı: ${dateFormat.format(start)} - ${dateFormat.format(end)}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // ÖZET KUTULARI
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('Toplam Gider', CurrencyFormatter.format(totalAmount), primaryColor),
                _buildSummaryBox('Toplam KDV', CurrencyFormatter.format(totalTax), PdfColors.teal700),
                _buildSummaryBox('İşlem Sayısı', receipts.length.toString(), PdfColors.blueGrey700),
              ],
            ),
            pw.SizedBox(height: 20),

            // KATEGORİ ÖZETİ (İLK 5)
            pw.Text('Kategori Bazlı Harcama (Top 5)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Kategori', 'Tutar', 'Oran'],
              data: sortedCategories.take(5).map((e) {
                final percent = (e.value / totalAmount * 100).toStringAsFixed(1);
                return [e.key, CurrencyFormatter.format(e.value), '%$percent'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),

            // DETAYLI LİSTE
            pw.Text(isTaxReport ? 'Vergi Detayları (KDV)' : 'Harcama Detayları', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: isTaxReport 
                ? ['Tarih', 'İşyeri', 'Matrah', 'KDV', 'Toplam']
                : ['Tarih', 'İşyeri', 'Kategori', 'Tutar'],
              data: receipts.map((r) {
                if (isTaxReport) {
                  final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
                  final matrah = r.totalAmount - tax;
                  return [
                    dateFormat.format(r.date),
                    r.merchantName,
                    CurrencyFormatter.format(matrah),
                    CurrencyFormatter.format(tax),
                    CurrencyFormatter.format(r.totalAmount),
                  ];
                }
                return [
                  dateFormat.format(r.date),
                  r.merchantName,
                  r.category,
                  CurrencyFormatter.format(r.totalAmount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellAlignments: isTaxReport 
                ? {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  }
                : {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerRight,
                  },
            ),
          ];
        },
      ),
    );

    // Dosya adı Belirle
    final filename = isTaxReport ? 'fismatik_vergi_raporu.pdf' : 'fismatik_harcama_raporu.pdf';

    // Paylaş
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  pw.Widget _buildSummaryBox(String title, String value, PdfColor color) {
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ],
      ),
    );
  }

  // --- EXCEL RAPORU ---
  Future<void> generateAndShareExcelReport(List<Receipt> receipts, {bool isTaxReport = false}) async {
    var excel = Excel.createExcel();
    String sheetName = isTaxReport ? 'Vergi Raporu' : 'Harcamalar';
    Sheet sheetObject = excel[sheetName];
    excel.delete('Sheet1'); // Varsayılan boş sayfayı sil

    // STİLLER
    var headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: ExcelColor.fromHexString(isTaxReport ? "#C62828" : "#1A237E"), // Red 800 for Tax, Indigo 900 for General
      fontSize: 12,
    );

    var titleStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: ExcelColor.fromHexString(isTaxReport ? "#E53935" : "#3949AB"), // Red 600 for Tax, Indigo 600 for General
      fontSize: 16,
    );

    var zebraStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#F5F5F5"), // Light Grey
    );

    // 1. SATIR: ANA BAŞLIK
    sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), 
                      CellIndex.indexByColumnRow(columnIndex: isTaxReport ? 4 : 5, rowIndex: 0));
    var titleCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(isTaxReport ? 'FİŞMATİK VERGİ RAPORU' : 'FİŞMATİK HARCAMA RAPORU');
    titleCell.cellStyle = titleStyle;
    sheetObject.setRowHeight(0, 30);

    // 2. SATIR: SÜTUN BAŞLIKLARI
    List<String> headers = isTaxReport 
      ? ['Tarih', 'İşyeri', 'Matrah (Ürün/Hizmet)', 'KDV', 'Toplam']
      : ['Tarih', 'İşyeri', 'Kategori', 'Tutar', 'KDV', 'Açıklama/Ürünler'];
      
    for (int i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // VERİLER
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    double totalAmt = 0;
    double totalTx = 0;

    for (int i = 0; i < receipts.length; i++) {
      final r = receipts[i];
      final rowIndex = i + 2;
      
      totalAmt += r.totalAmount;
      totalTx += r.taxAmount;

      if (isTaxReport) {
        final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
        final matrah = r.totalAmount - tax;
        _setCell(sheetObject, 0, rowIndex, TextCellValue(dateFormat.format(r.date)), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 1, rowIndex, TextCellValue(r.merchantName), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 2, rowIndex, DoubleCellValue(matrah), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 3, rowIndex, DoubleCellValue(tax), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 4, rowIndex, DoubleCellValue(r.totalAmount), i.isEven ? zebraStyle : null);
      } else {
        final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
        final itemsStr = r.items.map((it) => "${it.name} (${it.price})").join(", ");
        _setCell(sheetObject, 0, rowIndex, TextCellValue(dateFormat.format(r.date)), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 1, rowIndex, TextCellValue(r.merchantName), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 2, rowIndex, TextCellValue(r.category), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 3, rowIndex, DoubleCellValue(r.totalAmount), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 4, rowIndex, DoubleCellValue(tax), i.isEven ? zebraStyle : null);
        _setCell(sheetObject, 5, rowIndex, TextCellValue(itemsStr), i.isEven ? zebraStyle : null);
      }
    }

    // ÖZET SATIRI
    final summaryRowIndex = receipts.length + 3;
    if (isTaxReport) {
      sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIndex), 
                        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRowIndex));
      
      _setCell(sheetObject, 0, summaryRowIndex, TextCellValue('TOPLAM'), headerStyle);
      _setCell(sheetObject, 2, summaryRowIndex, DoubleCellValue(totalAmt - totalTx), headerStyle);
      _setCell(sheetObject, 3, summaryRowIndex, DoubleCellValue(totalTx), headerStyle);
      _setCell(sheetObject, 4, summaryRowIndex, DoubleCellValue(totalAmt), headerStyle);
    } else {
      sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIndex), 
                        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRowIndex));
      
      _setCell(sheetObject, 0, summaryRowIndex, TextCellValue('TOPLAM'), headerStyle);
      _setCell(sheetObject, 3, summaryRowIndex, DoubleCellValue(totalAmt), headerStyle);
      _setCell(sheetObject, 4, summaryRowIndex, DoubleCellValue(totalTx), headerStyle);
    }

    // SÜTUN GENİŞLİKLERİ
    if (isTaxReport) {
      sheetObject.setColumnWidth(0, 20);
      sheetObject.setColumnWidth(1, 25);
      sheetObject.setColumnWidth(2, 18);
      sheetObject.setColumnWidth(3, 12);
      sheetObject.setColumnWidth(4, 15);
    } else {
      sheetObject.setColumnWidth(0, 20);
      sheetObject.setColumnWidth(1, 25);
      sheetObject.setColumnWidth(2, 15);
      sheetObject.setColumnWidth(3, 12);
      sheetObject.setColumnWidth(4, 10);
      sheetObject.setColumnWidth(5, 50);
    }

    // Dosyayı kaydet ve paylaş
    final fileBytes = excel.save();
    final fileName = isTaxReport ? "fismatik_vergi_raporu.xlsx" : "fismatik_excel_rapor.xlsx";

    if (fileBytes != null) {
      if (kIsWeb) {
        // WEB: Blob ile indir
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // MOBİL: Temporary directory ve Share
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/$fileName";
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
          
        await Share.shareXFiles([XFile(path)], text: isTaxReport ? 'FişMatik Vergi Raporu' : 'FişMatik Excel Raporu');
      }
    }
  }

  void _setCell(Sheet sheet, int col, int row, CellValue value, CellStyle? style) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }
}
