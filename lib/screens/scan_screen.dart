import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category; // [NEW]
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/subscription_model.dart';
import '../models/membership_model.dart'; // Added
import '../models/category_model.dart'; // Added
import '../services/ocr_service.dart'; // Added
import '../services/auth_service.dart'; // Added
import '../services/ad_service.dart'; // Added
import '../services/usage_guard.dart'; // Added
import '../services/ai_service.dart'; // Added
import '../services/supabase_database_service.dart'; // Added
import '../services/gamification_service.dart'; // Added
import '../models/user_level.dart'; // Added
import '../services/notification_service.dart'; // Added
import '../core/app_theme.dart'; // Added

import 'manual_entry_screen.dart';
import 'upgrade_screen.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../utils/string_similarity.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isScanning = false;
  String _statusMessage = "";
  Map<String, dynamic>? _receiptData;
  Map<String, Map<String, dynamic>> _priceHistory = {};

  final OcrService _ocrService = OcrService();
  final AiService _aiService = AiService();
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();
  final AdService _adService = AdService();

  // Daily Limit State
  int _dailyUsage = 0;
  int _dailyLimit = 0;
  bool _dailyLimitLoaded = false;
  bool _scanQuotaLoaded = false; // Added this as it was referenced in errors

  // Smart Retry Variables
  String? _lastScannedText;
  int _retryCount = 0;

  // Editing State
  final Map<String, bool> _editingStates = {
    'merchant': false,
    'total': false,
    'tax': false,
  };
  final Set<int> _editingItemIndices = {};
  
  // Controllers for editing
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final Map<int, TextEditingController> _itemNameControllers = {};
  final Map<int, TextEditingController> _itemPriceControllers = {};

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    for (var c in _itemNameControllers.values) c.dispose();
    for (var c in _itemPriceControllers.values) c.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDailyUsage();
    _adService.loadAd(); // Reklamı önceden yükle
  }

  Future<void> _loadDailyUsage() async {
    try {
      final usage = await UsageGuard.getDailyUsage(UsageFeature.ocrScan);
      if (!mounted) return;
      setState(() {
        _dailyUsage = usage['current'] ?? 0;
        _dailyLimit = usage['limit'] ?? 0;
        _dailyLimitLoaded = true;
      });
    } catch (e) {
      debugPrint("Günlük limit yükleme hatası: $e");
    }
  }


  // --- KAMERA/GALERİ İŞLEMİ ---
  Future<void> _pickImage(ImageSource source) async {
    // 0) Race Condition Önlemi: Hemen loading durumuna geç
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    // 1) Önce kullanım limiti kontrolü (SADECE KONTROL, DÜŞME YOK)
    // Düşme işlemi server-side (Edge Function) tarafında yapılacak.
    final usageResult = await UsageGuard.checkAndConsume(
      UsageFeature.ocrScan, 
      checkOnly: true
    );

    if (!usageResult.isAllowed) {
      if (!mounted) return;

      final message = usageResult.message ??
          AppLocalizations.of(context)!.scanFeatureUnavailable;

      setState(() {
        _statusMessage = message;
        _isScanning = false; // Hata durumunda loading kapat
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    // 2) Üyelik tipini al
    final MembershipTier tier = await _authService.getCurrentTier();

    // 3) Kamerayı/galeriyi açan asıl fonksiyon
    Future<void> launchCameraOrGallery() async {
      // İzin Kontrolü (Sadece Mobilde)
      if (!kIsWeb) {
        PermissionStatus status;

        if (source == ImageSource.camera) {
          status = await Permission.camera.request();
        } else {
          if (await Permission.photos.request().isGranted ||
              await Permission.storage.request().isGranted) {
            status = PermissionStatus.granted;
          } else {
            status = PermissionStatus.denied;
          }
        }

        if (!status.isGranted && status != PermissionStatus.limited) {
          if (mounted) {
            setState(() {
              _isScanning = false; // İzin yoksa loading kapat
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.cameraGalleryPermission,
                ),
              ),
            );
          }
          return;
        }
      }

      try {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 2000,
          maxHeight: 2000,
          imageQuality: 85,
        );
        if (pickedFile == null) {
          if (mounted) {
            setState(() {
              _isScanning = false; // İptal edildiyse loading kapat
            });
          }
          return;
        }

        setState(() {
          _image = pickedFile;
          _statusMessage = AppLocalizations.of(context)!.readingText;
          _receiptData = null;
        });

        Map<String, dynamic>? aiResult;

        // --- VISION-FIRST STRATEGY (Unify Web and Mobile) ---
        final bytes = await _image!.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.aiExtractingData;
        });

        try {
          // Gemini Vision ile çok daha kaliteli sonuçlar
          aiResult = await _aiService.parseReceiptWithImage(base64Image);
        } catch (e) {
          debugPrint("Vision service failed, falling back to local OCR: $e");
          
          if (!kIsWeb) {
            // MOBİL FALLBACK: Yerel OCR + Backend Parse
            final rawText = await _ocrService.scanReceipt(_image!);
            aiResult = await _aiService.parseReceiptText(rawText);
          } else {
            rethrow;
          }
        }

        setState(() {
          _isScanning = false;
          if (aiResult != null) {
            _receiptData = aiResult;
            _statusMessage = AppLocalizations.of(context)!.processSuccess;
            _loadDailyUsage();
          } else {
            _statusMessage = AppLocalizations.of(context)!.dataExtractionFailed;
          }
        });

        // --- FETCH PRICE HISTORY (Faz 1) ---
        if (_receiptData != null && _receiptData!['items'] != null) {
          final List<String> itemNames = (_receiptData!['items'] as List)
              .map((e) => e['name'].toString())
              .toList();
          final history = await _databaseService.getPriceHistoryForProducts(itemNames);
          if (mounted) {
            setState(() {
              _priceHistory = history;
            });
          }
        }
      } on AiBackendException catch (e) {
         if (!mounted) return;

        debugPrint(
          "BACKEND HATA (${e.code}): ${e.message} (status: ${e.statusCode})",
        );

        setState(() {
          _isScanning = false;
        });

        String uiMessage;

        if (e.code == 'SCAN_LIMIT_REACHED') {
          uiMessage =
              AppLocalizations.of(context)!.monthlyLimitReached;
        } else if (e.code == 'RATE_LIMIT') {
          uiMessage = e.message.isNotEmpty
              ? e.message
              : AppLocalizations.of(context)!.rateLimitExceeded;
        } else if (e.code == 'NETWORK_ERROR') {
          uiMessage =
              AppLocalizations.of(context)!.networkError;
        } else {
          uiMessage =
              AppLocalizations.of(context)!.analysisError;
        }

        setState(() {
          _statusMessage = uiMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiMessage)),
        );
      } catch (e) {
        debugPrint("Fiş tarama hatası: $e");

        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _statusMessage =
              AppLocalizations.of(context)!.genericError;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.analysisError,
            ),
          ),
        );
      }
    }

    // 3) REKLAM KONTROLÜ
    if (tier.id == 'standart') {
      _adService.showInterstitialAd(
        context: context,
        onAdDismissed: () {
          launchCameraOrGallery();
        },
      );
    } else {
      await launchCameraOrGallery();
    }
  }

  // Ana Sayfadaki FAB butonu bu dialogu açacak
  static void showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.howToEnter,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOptionButton(
                    context,
                    icon: Icons.camera_alt,
                    label: AppLocalizations.of(context)!.scanReceipt,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ScanScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.edit_note,
                    label: AppLocalizations.of(context)!.manualEntry,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ManualEntryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: null, // Hero animasyonu istemiyoruz veya unique olmalı
          onPressed: onTap,
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.scanReceipt)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTOĞRAF ALANI
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                image: _image != null
                    ? DecorationImage(
                        image: kIsWeb 
                            ? NetworkImage(_image!.path) 
                            : FileImage(File(_image!.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _image == null
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            // BUTONLAR
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isScanning ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: Text(AppLocalizations.of(context)!.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isScanning ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: Text(AppLocalizations.of(context)!.gallery),
                  ),
                ),
              ],
            ),

            // GÜNLÜK LİMİT BİLGİSİ
            if (_dailyLimitLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.dailyLimitLabel(_dailyUsage.toString(), _dailyLimit.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _dailyUsage >= _dailyLimit ? AppColors.danger : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // MANUEL GİRİŞ BUTONU
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isScanning
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManualEntryScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.edit_note),
                label: Text(AppLocalizations.of(context)!.addManualExpense),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_scanQuotaLoaded)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  AppLocalizations.of(context)!.standardMembershipAdWarning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),

            if (_isScanning)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.pleaseWaitAnalyzing),
                ],
              )
            else if (_receiptData != null)
              _buildResultCard(context)
            else
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final items = _receiptData!['items'] as List;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MERCHANT NAME EDITING ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _editingStates['merchant'] == true
                      ? Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _merchantController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: AppColors.success),
                              onPressed: () {
                                setState(() {
                                  _receiptData!['merchantName'] = _merchantController.text;
                                  _editingStates['merchant'] = false;
                                });
                              },
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: () {
                             setState(() {
                               _merchantController.text = _receiptData!['merchantName'];
                               _editingStates['merchant'] = true;
                             });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Text(
                              _receiptData!['merchantName'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            
            // --- TOTAL AMOUNT EDITING ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _editingStates['total'] == true
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _totalController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                prefixText: '₺',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.success),
                            onPressed: () {
                              setState(() {
                                double? val = double.tryParse(_totalController.text.replaceAll(',', '.'));
                                if (val != null) {
                                  _receiptData!['totalAmount'] = val;
                                }
                                _editingStates['total'] = false;
                              });
                            },
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            _totalController.text = _receiptData!['totalAmount'].toString();
                            _editingStates['total'] = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                           child: Text(
                            "₺${_receiptData!['totalAmount']}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
              ],
            ),

            // --- TAX AMOUNT EDITING ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "KDV: ",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                _editingStates['tax'] == true
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                prefixText: '₺',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.success, size: 20),
                            onPressed: () {
                              setState(() {
                                double? val = double.tryParse(_taxController.text.replaceAll(',', '.'));
                                if (val != null) {
                                  _receiptData!['taxAmount'] = val;
                                }
                                _editingStates['tax'] = false;
                              });
                            },
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                           setState(() {
                             _taxController.text = (_receiptData!['taxAmount'] ?? 0.0).toString();
                             _editingStates['tax'] = true;
                           });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Text(
                            "₺${_receiptData!['taxAmount'] ?? 0.0}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
              ],
            ),

            const Divider(),
            
            // --- GENERAL CATEGORY EDITING ---
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context)!.categoryLabel} ",
                  style: const TextStyle(color: Colors.grey),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: Category.defaultCategories.any((c) => c.name == _receiptData!['category']) 
                        ? _receiptData!['category'] 
                        : 'Diğer',
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    items: Category.defaultCategories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.name,
                        child: Text(c.name, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _receiptData!['category'] = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            // --- DATE EDITING ---
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context)!.dateLabel} ${_receiptData!['date']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
                  onPressed: () async {
                    DateTime? initialDate = DateTime.tryParse(_receiptData!['date']);
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        // Format: YYYY-MM-DD
                        String formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        _receiptData!['date'] = formatted;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.productsLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            
            // --- ITEMS EDITING ---
            ...items.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;
              bool isEditing = _editingItemIndices.contains(index);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: isEditing
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _itemNameControllers[index],
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _itemPriceControllers[index],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                prefixText: '₺',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Item Category mini-dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<String>(
                              value: (item['category'] != null && 
                                      ["Gıda", "Et & Tavuk", "İçecek", "Baharat & Çeşni", "Meyve & Sebze", "Atıştırmalık", "Temizlik & Bakım", "Sigara", "Alkol", "Akaryakıt", "Kişisel Bakım", "Ev Eşyası", "Giyim", "Elektronik", "Hizmet", "Diğer"].contains(item['category']))
                                  ? item['category']
                                  : 'Diğer',
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                              items: ["Gıda", "Et & Tavuk", "İçecek", "Baharat & Çeşni", "Meyve & Sebze", "Atıştırmalık", "Temizlik & Bakım", "Sigara", "Alkol", "Akaryakıt", "Kişisel Bakım", "Ev Eşyası", "Giyim", "Elektronik", "Hizmet", "Diğer"].map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    item['category'] = val;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.success),
                            onPressed: () {
                              setState(() {
                                item['name'] = _itemNameControllers[index]!.text;
                                double? val = double.tryParse(_itemPriceControllers[index]!.text.replaceAll(',', '.'));
                                if (val != null) {
                                  item['price'] = val;
                                }
                                _editingItemIndices.remove(index);
                                
                                // Clean up controllers
                                _itemNameControllers[index]?.dispose();
                                _itemPriceControllers[index]?.dispose();
                                _itemNameControllers.remove(index);
                                _itemPriceControllers.remove(index);
                              
                                // Optionally recalculate total
                                double newTotal = 0;
                                for (var i in items) {
                                  newTotal += (i['price'] is int) ? (i['price'] as int).toDouble() : (i['price'] as double);
                                }
                                _receiptData!['totalAmount'] = newTotal;
                                _receiptData!['taxAmount'] = newTotal / 1.10 * 0.10;
                              });
                            },
                          ),
                        ],
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Row(
                          children: [
                            Text(
                              item['category'] ?? 'Diğer',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                             if (_priceHistory.containsKey(item['name'].toString().toLowerCase())) 
                                _buildPriceComparison(item['name'].toString(), item['price']),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₺${item['price']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  setState(() {
                                    _itemNameControllers[index] = TextEditingController(text: item['name']);
                                    _itemPriceControllers[index] = TextEditingController(text: item['price'].toString());
                                    // Dropdown otomatik olarak item['category']'den alacak
                                    _editingItemIndices.add(index);
                                  });
                                } else if (value == 'delete') {
                                  setState(() {
                                    items.removeAt(index);
                                    // Yeniden hesapla
                                    double newTotal = 0;
                                    for (var i in items) {
                                      newTotal += (i['price'] is int) ? (i['price'] as int).toDouble() : (i['price'] as double);
                                    }
                                    _receiptData!['totalAmount'] = newTotal;
                                    _receiptData!['taxAmount'] = newTotal / 1.10 * 0.10;
                                  });
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                                      SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: AppColors.danger),
                                      SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              );
            }).toList(),
            
            const SizedBox(height: 10),
            
            // --- ADD ITEM BUTTON ---
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    items.add({'name': 'Yeni Ürün', 'price': 0.0});
                    int newIndex = items.length - 1;
                    _itemNameControllers[newIndex] = TextEditingController(text: 'Yeni Ürün');
                    _itemPriceControllers[newIndex] = TextEditingController(text: '0.0');
                    _editingItemIndices.add(newIndex);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                label: const Text("Eksik Ürün Ekle", style: TextStyle(color: AppColors.primary)),
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.savingReceipt),
                      ),
                    );
                      
                      // Sayısal değerleri double'a dönüştür
                      final receiptDataToSave = Map<String, dynamic>.from(_receiptData!);
                      
                      // totalAmount'u double'a çevir
                      if (receiptDataToSave['totalAmount'] is int) {
                        receiptDataToSave['totalAmount'] = (receiptDataToSave['totalAmount'] as int).toDouble();
                      } else if (receiptDataToSave['totalAmount'] is String) {
                         receiptDataToSave['totalAmount'] = double.tryParse(receiptDataToSave['totalAmount']) ?? 0.0;
                      }
                      
                      if (receiptDataToSave['taxAmount'] is int) {
                        receiptDataToSave['taxAmount'] = (receiptDataToSave['taxAmount'] as int).toDouble();
                      } else if (receiptDataToSave['taxAmount'] is String) {
                         receiptDataToSave['taxAmount'] = double.tryParse(receiptDataToSave['taxAmount']) ?? 0.0;
                      } else if (receiptDataToSave['taxAmount'] == null) {
                        // Eğer KDV boşsa ve fiş market/yemek gibi bir yerse %10 varsayalım mı?
                        // Kullanıcıya bırakıyoruz ama 0 olmasın diye %10 hesaplayalım eğer hala 0 ise
                        if (receiptDataToSave['totalAmount'] > 0) {
                           receiptDataToSave['taxAmount'] = receiptDataToSave['totalAmount'] / 1.10 * 0.10;
                        } else {
                           receiptDataToSave['taxAmount'] = 0.0;
                        }
                      }

                      // items içindeki price değerlerini double'a çevir
                      if (receiptDataToSave['items'] is List) {
                        receiptDataToSave['items'] = (receiptDataToSave['items'] as List).map((item) {
                          final itemMap = Map<String, dynamic>.from(item);
                          if (itemMap['price'] is int) {
                            itemMap['price'] = (itemMap['price'] as int).toDouble();
                          } else if (itemMap['price'] is String) {
                            itemMap['price'] = double.tryParse(itemMap['price']) ?? 0.0;
                          }
                          return itemMap;
                        }).toList();
                      }
                      
                      // Internet kontrolü (Basit check - Sadece Mobilde)
                      if (!kIsWeb) {
                        try {
                          await InternetAddress.lookup('google.com');
                        } on SocketException catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.noInternet),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // [NEW] Toplam Fiş Limit Kontrolü
                      final currentReceiptCount = await _databaseService.getCurrentReceiptCount();
                      final canAddReceipt = await _authService.canAddReceipts(currentReceiptCount);
                      
                      if (!canAddReceipt) {
                        if (context.mounted) {
                          final tier = await _authService.getCurrentTier();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.receiptLimitTitle),
                              content: Text(
                                AppLocalizations.of(context)!.receiptLimitContent(tier.receiptLimit),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppLocalizations.of(context)!.close),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (c) => UpgradeScreen()),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.upgradeMembership,
                                    style: const TextStyle(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }

                      // Online mode - Supabase'e kaydet
                      await _databaseService.saveReceipt(receiptDataToSave);

                      // Rozet Kontrolü - GamificationService içinde yapılıyor


                      // Bütçe Kontrolü
                      try {
                        final categoryName = receiptDataToSave['category'] ?? 'Diğer';
                        
                        final categories = await _databaseService.getCategoriesOnce();
                        final category = categories.firstWhere(
                          (c) => c.name == categoryName, 
                          orElse: () => Category(id: '', name: categoryName, colorValue: 0, iconCode: 0, budgetLimit: 0)
                        );

                        if (category.budgetLimit > 0) {
                          final spendingMap = await _databaseService.getCategorySpendingThisMonth();
                          final currentSpending = spendingMap[categoryName] ?? 0.0;
                          
                          // Bildirim servisini çağır
                          await NotificationService().checkCategoryBudgetAndNotify(
                            context,
                            categoryName, 
                            currentSpending, 
                            category.budgetLimit
                          );
                        }
                      } catch (e) {
                        debugPrint("Bütçe kontrol hatası: $e");
                      }
                      
                      // Abonelik Algılama (AI Destekli)
                      try {
                        bool isRecurring = receiptDataToSave['is_recurring'] == true;
                        
                        // Fallback: AI kaçırdıysa manuel liste kontrolü
                        final merchant = receiptDataToSave['merchantName'].toString().toLowerCase();
                        if (!isRecurring) {
                          final knownSubs = ['netflix', 'spotify', 'youtube', 'amazon prime', 'disney', 'exxen', 'blutv', 'apple', 'icloud', 'google one', 'enerjisa', 'iski', 'igdaş', 'turkcell', 'vodafone', 'türk telekom'];
                          if (knownSubs.any((sub) => merchant.contains(sub))) {
                            isRecurring = true;
                          }
                        }

                        if (isRecurring) {
                          if (context.mounted) {
                            final shouldAdd = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.subscriptionDetected),
                                content: Text(AppLocalizations.of(context)!.subscriptionDetectedContent(receiptDataToSave['merchantName'])),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.no)),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.yes)),
                                ],
                              ),
                            );

                            if (shouldAdd == true) {
                              // AI'dan gelen gün verisi varsa kullan, yoksa bugünü al
                              int renewalDay = DateTime.now().day;
                              if (receiptDataToSave['renewal_day'] != null && receiptDataToSave['renewal_day'] is int) {
                                renewalDay = receiptDataToSave['renewal_day'];
                              } else {
                                final date = DateTime.tryParse(receiptDataToSave['date'] ?? '');
                                if (date != null) renewalDay = date.day;
                              }

                              final subName = receiptDataToSave['subscription_name'] ?? receiptDataToSave['merchantName'];
                              final subPrice = receiptDataToSave['totalAmount'];
                              
                              final newSub = Subscription(
                                id: const Uuid().v4(),
                                name: subName,
                                price: (subPrice is int) ? subPrice.toDouble() : subPrice,
                                renewalDay: renewalDay,
                                colorHex: 'FF2196F3', // Varsayılan mavi
                              );
                              
                              await _databaseService.addSubscription(newSub);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context)!.subscriptionAdded)),
                                );
                              }
                            }
                          }
                        }
                      } catch (e) {
                         debugPrint("Abonelik algılama hatası: $e");
                      }
                      
                      // Gamification & Rozet Kontrolü
                      if (context.mounted) {
                        try {
                          final gamificationService = GamificationService();
                          
                          // 1. XP Ekle
                          await gamificationService.addXp(XpActivity.scanReceipt);
                          
                          // 2. İstatistikleri al
                          final count = await _databaseService.getCurrentReceiptCount();
                          final totalSpending = await _databaseService.getTotalSpending();
                          final joinDate = await _authService.getJoinDate(); // AuthService'e bu metodu eklememiz gerekebilir veya user metadata'dan alabiliriz
                          
                          // 3. Tüm başarımları kontrol et
                          await gamificationService.checkAllAchievements(
                            totalReceipts: count,
                            totalSpending: totalSpending,
                            transactionDate: DateTime.now(),
                            joinDate: joinDate,
                          );

                        } catch (e) {
                          debugPrint("Gamification hatası: $e");
                        }
                      }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.receiptSavedSuccess),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          // Başarılı kayıt sonrası retry geçmişini temizle
                          setState(() {
                            _lastScannedText = null;
                            _retryCount = 0;
                          });
                          // Confetti Animation Dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) {
                              Future.delayed(const Duration(seconds: 2), () {
                                if (ctx.mounted) Navigator.pop(ctx); // Close dialog
                                if (context.mounted) Navigator.pop(context); // Close ScanScreen
                              });
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                shadowColor: Colors.transparent,
                                child: Lottie.asset(
                                  'assets/lottie/confetti.json',
                                  repeat: false,
                                  errorBuilder: (context, error, stackTrace) {
                                     // If asset missing, close immediately
                                     return const SizedBox();
                                  },
                                ),
                              );
                            }
                          );

                          // Başarılı kayıt sonrası retry geçmişini temizle
                          setState(() {
                            _lastScannedText = null;
                            _retryCount = 0;
                          });
                        }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.receiptSaveFailed(e.toString())),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.saveReceiptButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceComparison(String name, dynamic currentPriceValue) {
    // Check if we have history for this product
    final history = _priceHistory[name.toLowerCase()];
    if (history == null) return const SizedBox();

    final prevPrice = (history['price'] is int) 
        ? (history['price'] as int).toDouble() 
        : (history['price'] as double);
        
    final currentPrice = (currentPriceValue is int) 
        ? (currentPriceValue as int).toDouble() 
        : (currentPriceValue as double);

    if (currentPrice > prevPrice) {
      final diff = currentPrice - prevPrice;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_drop_up, color: Colors.red, size: 16),
            Text(
              "${diff.toStringAsFixed(2)}₺", 
              style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    } else if (currentPrice < prevPrice) {
      final diff = prevPrice - currentPrice;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_drop_down, color: Colors.green, size: 16),
            Text(
              "${diff.toStringAsFixed(2)}₺", 
              style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: const Icon(Icons.remove, color: Colors.grey, size: 12),
      );
    }
  }
}
