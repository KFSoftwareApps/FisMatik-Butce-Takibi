import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../models/category_model.dart'; // Kategori modelini ekledik
import '../services/supabase_database_service.dart';
import '../core/app_icons.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class EditReceiptScreen extends StatefulWidget {
  final Receipt receipt;

  const EditReceiptScreen({super.key, required this.receipt});

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  String? _selectedCategory; // Nullable yaptık, yüklenince dolacak

  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.receipt.merchantName);
    _amountController = TextEditingController(text: CurrencyFormatter.formatDecimal(widget.receipt.totalAmount));
    _selectedDate = widget.receipt.date;
    _selectedCategory = widget.receipt.category;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final double? amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
      if (amount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidAmount)));
        }
        return;
      }

      if (_selectedCategory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectCategoryError)));
        }
        return;
      }

      final updatedReceipt = Receipt(
        id: widget.receipt.id,
        userId: widget.receipt.userId,
        merchantName: _merchantController.text,
        date: _selectedDate,
        totalAmount: amount,
        category: _selectedCategory!,
        items: widget.receipt.items,
        imageUrl: widget.receipt.imageUrl,
      );

      await _databaseService.updateReceipt(updatedReceipt);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.changesSaved)));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CurrencyProvider>(); // Rebuilds when currency changes
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editReceiptTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: StreamBuilder<List<Category>>(
        stream: _databaseService.getCategories(),
        builder: (context, snapshot) {
          // Kategoriler yüklenirken loading göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gelen kategori listesi (yoksa varsayılanları kullan)
          final categories = snapshot.data ?? Category.defaultCategories;

          // Eğer seçili kategori listede yoksa (örn: silinmişse), listenin ilkini veya "Diğer"i seçelim
          // Amaç: Dropdown hata vermesin.
          final categoryNames = categories.map((e) => e.name).toList();
          if (!categoryNames.contains(_selectedCategory)) {
             // Listede yoksa "Diğer" var mı diye bak, yoksa ilkini seç
             if (categoryNames.contains("Diğer")) {
               _selectedCategory = "Diğer";
             } else if (categoryNames.isNotEmpty) {
               _selectedCategory = categoryNames.first;
             }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // MAĞAZA ADI
              TextField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.merchantLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 20),

              // TUTAR
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.totalAmountLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: CurrencyFormatter.currencySymbol,
                ),
              ),
              const SizedBox(height: 20),

              // KATEGORİ (CANLI DROPDOWN)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.categoryLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: categories.map((Category category) {
                  return DropdownMenuItem(
                    value: category.name,
                    child: Row(
                      children: [
                        Icon(AppIcons.getIcon(category.iconCode), 
                             color: Color(category.colorValue), size: 20),
                        const SizedBox(width: 10),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 20),

              // TARİH
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.receiptDateLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', Localizations.localeOf(context).toString()).format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // KAYDET BUTONU
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(AppLocalizations.of(context)!.saveChangesButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
