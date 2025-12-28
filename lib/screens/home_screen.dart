import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/core/app_theme.dart';
import 'package:fismatik/models/category_model.dart';
import 'package:fismatik/models/subscription_model.dart';
import 'package:fismatik/models/credit_model.dart';
import 'package:fismatik/models/receipt_model.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/services/notification_service.dart';
import 'package:fismatik/screens/scan_screen.dart';
import 'package:fismatik/screens/receipt_detail_screen.dart';
import 'package:fismatik/widgets/error_state.dart';
import 'package:fismatik/screens/statistics_screen.dart';
import 'package:fismatik/services/intelligence_service.dart';
import 'package:fismatik/screens/subscriptions_screen.dart'; 
import 'package:fismatik/screens/installment_expenses_screen.dart'; // [NEW]

// ... (existing imports)

  // ... inside _HomeScreenState

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Receipt>>(
      stream: _receiptsStream,
      builder: (context, receiptSnapshot) {
        return StreamBuilder<double>(
          stream: _monthlyLimitStream,
          builder: (context, limitSnapshot) {
            return StreamBuilder<List<Subscription>>(
              stream: _subscriptionsStream,
              builder: (context, subSnapshot) {
                return StreamBuilder<List<Credit>>(
                  stream: _creditsStream,
                  builder: (context, creditSnapshot) {
                    return StreamBuilder<Map<String, dynamic>>(
                      stream: _userSettingsStream,
                      builder: (context, settingsSnapshot) {
                        // Birincil yükleme durumu (En az fiş listesi gelene kadar bekle)
                        if (receiptSnapshot.connectionState == ConnectionState.waiting && receiptSnapshot.data == null) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        // Hata durumu
                        if (receiptSnapshot.hasError) {
                          // ... (error handling code remains same)
                          final error = receiptSnapshot.error.toString();
                          final isNetworkError = error.contains('SocketException') || error.contains('NetworkImage') || error.contains('ClientException');
                          
                          return Scaffold(
                            backgroundColor: Colors.white,
                            body: ErrorState(
                              title: isNetworkError ? (AppLocalizations.of(context)!.noInternet ?? "Bağlantı Hatası") : (AppLocalizations.of(context)!.generalError ?? "Bir Hata Oluştu"),
                              description: isNetworkError 
                                  ? (AppLocalizations.of(context)!.networkError ?? "İnternet bağlantınızı kontrol edip tekrar deneyin.")
                                  : error,
                              icon: isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                              onRetry: () {
                                if (mounted) {
                                  setState(() {
                                    _receiptsStream = _databaseService.getUnifiedReceiptsStream();
                                  });
                                }
                              },
                            ),
                          );
                        }

                        // Verileri hazırla (Fallback değerleri ile)
                        final allReceipts = receiptSnapshot.data ?? [];
                        final monthlyLimit = limitSnapshot.data ?? 5000.0;
                        final subscriptions = subSnapshot.data ?? [];
                        final credits = creditSnapshot.data ?? [];
                        final settings = settingsSnapshot.data ?? {'salary_day': 1};
                        final int salaryDay = settings['salary_day'] as int;

                        // Filtreleme ve Hesaplama
                        final filteredReceipts = _filterReceipts(allReceipts, salaryDay);
                        
                        // Header için sadece gerçek fişleri topla (Sabit giderler ayrıca hesaplanıyor)
                        final realReceipts = filteredReceipts.where((r) => !r.id.startsWith('sub_') && !r.id.startsWith('credit_')).toList();
                        final totalSpending = _calculateTotal(realReceipts);

                        double totalSubscriptions = 0;
                        for (var sub in subscriptions) {
                          totalSubscriptions += sub.price;
                        }

                        double totalInstallments = 0;
                        for (var credit in credits) {
                          totalInstallments += credit.monthlyAmount;
                        }

                        final totalFixedExpenses = totalSubscriptions + totalInstallments;
                        final remainingBudget = monthlyLimit - totalSpending - totalFixedExpenses;

                        // Widget ve Bildirim Kontrolleri (Async)
                        _performBackgroundChecks(context, totalSpending, monthlyLimit, remainingBudget);

                        return Container(
                          color: AppColors.background,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildHeaderSection(context, totalSpending, monthlyLimit, totalFixedExpenses, totalSubscriptions, totalInstallments),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 16)),
                              SliverToBoxAdapter(
                                child: _buildFilterTabs(),
                              ),
                              if (_pendingSmsExpenses.isNotEmpty) 
                                SliverToBoxAdapter(child: _buildPendingSmsBanner()),
                              
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildQuickActions(context),
                                    const SizedBox(height: 24),
                                    _buildSectionHeader(context, filteredReceipts.length),
                                    const SizedBox(height: 16),
                                  ]),
                                ),
                              ),

                              if (filteredReceipts.isEmpty)
                                SliverToBoxAdapter(child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: _buildEmptyState(),
                                ))
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final receipt = filteredReceipts[index];
                                        return _buildHomeReceiptTile(
                                          context: context,
                                          receipt: receipt,
                                        );
                                      },
                                      childCount: filteredReceipts.length,
                                    ),
                                  ),
                                ),

                              const SliverToBoxAdapter(child: SizedBox(height: 16)),
                              if (kIsWeb && _currentTierId == 'standart')
                                const SliverToBoxAdapter(
                                  child: Center(
                                    child: WebAdBanner(
                                      adSlot: '8945074304',
                                      width: 320,
                                      height: 100,
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(child: SizedBox(height: 40)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ... _performBackgroundChecks ...

  // ... _buildQuickActions ...

  // ... _buildSectionHeader ...

  // --- HEADER SECTION ---
  Widget _buildHeaderSection(BuildContext context, double totalSpending, double monthlyLimit, double totalFixedExpenses, double totalSubscriptions, double totalInstallments) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final totalUsed = totalSpending + totalFixedExpenses;
    final percent = monthlyLimit == 0 ? 0.0 : (totalUsed / monthlyLimit).clamp(0.0, 1.0);
    // Kalan bütçeden sabit giderleri de düş
    final remaining = monthlyLimit - totalSpending - totalFixedExpenses;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalSpending,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalSpending),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Sabit Giderler Eklendi
                  if (totalFixedExpenses > 0) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        // Navigation Logic
                        if (totalSubscriptions > 0 && totalInstallments > 0) {
                          // Both exist, ask user
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(AppLocalizations.of(context)!.selectExpense, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.repeat, color: Colors.purple),
                                    title: Text(AppLocalizations.of(context)!.fixedExpenses), // Abonelikler
                                    subtitle: Text(currencyFormat.format(totalSubscriptions)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FixedExpensesScreen())).then((_) => _refreshData());
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.calendar_month, color: Colors.blue),
                                    title: Text(AppLocalizations.of(context)!.installmentExpensesTitle ?? "Taksitli Giderler"), // Taksitler
                                    subtitle: Text(currencyFormat.format(totalInstallments)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InstallmentExpensesScreen())).then((_) => _refreshData());
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        } else if (totalInstallments > 0) {
                          // Only installments
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const InstallmentExpensesScreen()));
                          if (mounted) _refreshData();
                        } else {
                          // Only subscriptions or default
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FixedExpensesScreen()));
                          if (mounted) _refreshData();
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.repeat, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.fixedExpensesLabel(currencyFormat.format(totalFixedExpenses)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                      if (mounted) _refreshData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _databaseService.getNotifications(),
                    builder: (context, snapshot) {
                      final notifications = snapshot.data ?? [];
                      // Admin bildirimlerini (hesap silme vb.) ana ekranda gösterme
                      final filteredNotifications = notifications.where((n) {
                        final type = n['type'];
                        return type != 'account_deletion_request' && type != 'system_test';
                      }).toList();
                      
                      final unreadCount = filteredNotifications.where((n) => n['is_read'] != true).length;

                      return GestureDetector(
                        onTap: () async {
                          await _openNotificationCenter(context);
                          if (mounted) _refreshData();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications, color: Colors.white),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          // Progress Bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.fastOutSlowIn,
            builder: (context, animValue, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: animValue,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent > 1.0 ? AppColors.danger : AppColors.secondary,
                  ),
                  minHeight: 8,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${AppLocalizations.of(context)!.monthlyLimit}: ${currencyFormat.format(monthlyLimit)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: () => _showEditLimitDialog(context, monthlyLimit),
                  child: Text(
                    "${AppLocalizations.of(context)!.remainingBudget}: ${currencyFormat.format(remaining)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  // --- SEKME/BUTON YAPISI ---
  Widget _buildFilterTabs() {
    final selectedColor = AppColors.primary;
    final unselectedColor = Colors.grey.shade400;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(FILTER_WEEK, selectedColor, unselectedColor),
          _buildTabItem(FILTER_MONTH, selectedColor, unselectedColor),
          _buildTabItem(FILTER_SALARY, selectedColor, unselectedColor),
          _buildTabItem(FILTER_YEAR, selectedColor, unselectedColor),
        ],
      ),
    );
  }

  Widget _buildTabItem(String filterKey, Color selectedColor, Color unselectedColor) {
    final isSelected = _selectedFilter == filterKey;
    final isSalaryDayTab = filterKey == FILTER_SALARY;
    final label = _getFilterLabel(filterKey);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected && isSalaryDayTab) {
            _showSalaryDayDialog();
          } else {
            setState(() {
              _selectedFilter = filterKey;
            });
            _saveDateFilter();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Flexible(
                 child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : unselectedColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
               ),
              if (isSalaryDayTab && isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.settings, size: 12, color: Colors.white70),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _showSalaryDayDialog() {
    // Önce mevcut ayarı çekelim, sonra dialogu gösterelim
    _databaseService.getUserSettings().first.then((settings) {
      int currentDay = (settings['salary_day'] as int?) ?? 1;
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          int tempDay = currentDay;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.setSalaryDay),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.salaryDayQuestion),
                    const SizedBox(height: 16),
                    DropdownButton<int>(
                      value: tempDay,
                      menuMaxHeight: 300,
                      items: List.generate(31, (index) => index + 1).map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text("$day"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => tempDay = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.salaryDayDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _databaseService.updateSalaryDay(tempDay);
                      if (context.mounted) Navigator.pop(context);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.salaryDaySetSuccess(tempDay.toString()))),
                        );
                        
                        setState(() {
                          _selectedFilter = AppLocalizations.of(context)!.thisMonth;
                        });
                        _refreshData();
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              );
            }
          );
        },
      );
    });
  }

  void _refreshData() {
    if (mounted) {
      _loadPendingSmsExpenses();
      setState(() {
        _receiptsStream = _databaseService.getReceipts();
        _monthlyLimitStream = _databaseService.getMonthlyLimit();
        _subscriptionsStream = _databaseService.getSubscriptions();
        _creditsStream = _databaseService.getCredits();
        _userSettingsStream = _databaseService.getUserSettings();
      });
    }
  }

  void _showEditLimitDialog(BuildContext context, double currentLimit) {
    final TextEditingController controller =
        TextEditingController(text: currentLimit.toInt().toString());
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.setBudgetLimit),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.monthlyLimitAmount,
                    border: const OutlineInputBorder(),
                    prefixText: "₺",
                  ),
                  enabled: !isLoading,
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final text = controller.text.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
                        final newLimit = double.tryParse(text);
                        
                        if (newLimit != null) {
                          setDialogState(() => isLoading = true);
                          try {
                            await _databaseService.updateMonthlyLimit(newLimit);
                            if (context.mounted) {
                              Navigator.pop(context);
                              // Ana ekranı güncelle
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.budgetLimitUpdated)),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${AppLocalizations.of(context)!.analysisError}: $e")),
                              );
                            }
                          }
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.invalidAmount)),
                           );
                        }
                      },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openNotificationCenter(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allNotifications = snapshot.data ?? [];
                // Admin bildirimlerini filtrele
                final notifications = allNotifications.where((n) {
                  final type = n['type'];
                  return type != 'account_deletion_request' && type != 'system_test';
                }).toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.notifications,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (notifications.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                try {
                                  final ids = notifications.map((n) => n['id'] as String).toList();
                                  await _databaseService.deleteNotifications(ids);
                                  // Stream'i yenilemek için modal state'i güncelle
                                  setModalState(() {});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.of(context)!.allNotificationsCleared)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("${AppLocalizations.of(context)!.analysisError}: $e")),
                                    );
                                  }
                                }
                              },
                              child: Text(AppLocalizations.of(context)!.clearAll),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (notifications.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)!.noNewNotifications,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final type = notification['type'];
                              final data = notification['data'] ?? {};
                              final isRead = notification['is_read'] == true;

                              return Card(
                                color: isRead ? Colors.white : Colors.blue.shade50,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            type == 'family_invite' ? Icons.family_restroom : Icons.notifications,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notification['title'] ?? AppLocalizations.of(context)!.notificationDefaultTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(notification['message'] ?? ''),
                                              ],
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (type == 'family_invite') ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  await _databaseService.rejectFamilyInvite(data['invite_id']);
                                                  await _databaseService.deleteNotification(notification['id']);
                                                  setModalState(() {});
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Davet reddedildi.")),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("${AppLocalizations.of(context)!.analysisError}: $e")),
                                                    );
                                                  }
                                                }
                                              },
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: Text(AppLocalizations.of(context)!.reject),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final addressController = TextEditingController();
                                                await showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(AppLocalizations.of(context)!.enterAddress),
                                                    content: TextField(
                                                      controller: addressController,
                                                      decoration: InputDecoration(
                                                        labelText: AppLocalizations.of(context)!.homeAddress,
                                                        border: const OutlineInputBorder(),
                                                      ),
                                                      maxLines: 2,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: Text(AppLocalizations.of(context)!.cancel),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          if (addressController.text.isEmpty) return;
                                                          Navigator.pop(context);
                                                          
                                                          try {
                                                            final res = await _databaseService.acceptFamilyInvite(
                                                              data['invite_id'],
                                                              addressController.text,
                                                            );
                                                            
                                                            if (res['success'] == true) {
                                                              await _databaseService.deleteNotification(notification['id']);
                                                              setModalState(() {});
                                                              if (ctx.mounted) {
                                                                Navigator.pop(ctx);
                                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                                  SnackBar(content: Text(AppLocalizations.of(ctx)!.familyJoinedSuccess)),
                                                                );
                                                              }
                                                            } else {
                                                              if (ctx.mounted) {
                                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                                  SnackBar(content: Text(res['message'] ?? AppLocalizations.of(ctx)!.analysisError)),
                                                                );
                                                              }
                                                            }
                                                          } catch (e) {
                                                            if (ctx.mounted) {
                                                              ScaffoldMessenger.of(ctx).showSnackBar(
                                                                SnackBar(content: Text("${AppLocalizations.of(ctx)!.analysisError}: $e")),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: Text(AppLocalizations.of(context)!.okButton),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text(AppLocalizations.of(context)!.accept),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {

    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: AppLocalizations.of(context)!.noData,
      description: AppLocalizations.of(context)!.scanReceiptToStart,
      buttonText: AppLocalizations.of(context)!.addFirstReceipt,
      onButtonPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanScreen()),
        );
        if (mounted) _refreshData();
      },
      color: AppColors.primary,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = true,
    Color? customColor,
    Color? customBackgroundColor,
  }) {
    final Color foregroundColor = customColor ??
        (isPrimary ? AppColors.primary : AppColors.success);
    final Color backgroundColor = customBackgroundColor ??
        (isPrimary ? const Color(0xFFE8EAF6) : const Color(0xFFE0F2F1));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: foregroundColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ANA SAYFA FİŞ KARTI (manuel / tarama etiketi ile) ---
  Widget _buildHomeReceiptTile({
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

    final currencyFormat =
        NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '₺', decimalDigits: 2);
    final dateText =
        DateFormat('d MMM yyyy', Localizations.localeOf(context).toString()).format(receipt.date);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReceiptDetailScreen(receipt: receipt),
          ),
        );
        
        if (result == true && mounted) {
          _refreshData();
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
              currencyFormat.format(receipt.totalAmount),
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

  Future<void> _showMonthlyBudgetDialog(BuildContext context, double currentLimit, String key) async {
    final TextEditingController controller = TextEditingController(text: currentLimit.toStringAsFixed(2));

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.newMonthMessage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.setMonthlyBudget),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.monthlyBudget,
                  prefixText: '₺',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final newLimit = double.tryParse(controller.text.replaceAll(',', '.')) ?? currentLimit;
                
                await _databaseService.updateMonthlyLimit(newLimit);
                
                if (mounted) {
                  setState(() {
                    _monthlyLimitStream = _databaseService.getMonthlyLimit();
                  });
                }
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(key, true);
                
                final now = DateTime.now();
                final warningKey = 'budget_warning_shown_${now.year}_${now.month}';
                await prefs.setBool(warningKey, false);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.budgetUpdated)),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingSmsBanner() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sms_failed_outlined, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yeni Harcamalar Tespit Edildi',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() => _pendingSmsExpenses = []);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingSmsExpenses.map((expense) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense['merchant'] ?? 'Bilinmiyor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          currencyFormat.format(expense['amount'] ?? 0),
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _smsService.removePendingExpense(expense['id']),
                    child: const Text('Reddet', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => _addSmsExpenseToDatabase(expense),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Ekle', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _addSmsExpenseToDatabase(Map<String, dynamic> expense) async {
    final receipt = Receipt(
      id: const Uuid().v4(),
      userId: _authService.currentUser?.id ?? '',
      merchantName: expense['merchant'] ?? 'Bilinmiyor',
      date: DateTime.parse(expense['date']),
      totalAmount: (expense['amount'] as num).toDouble(),
      category: 'Diğer', // Fallback as guessCategoryFromName is missing
      items: [],
      isManual: true,
      source: 'sms',
    );

    try {
      await _databaseService.saveManualReceipt(
        merchantName: receipt.merchantName,
        date: receipt.date,
        totalAmount: receipt.totalAmount,
        category: receipt.category,
      );
      await _smsService.removePendingExpense(expense['id']);
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harcama başarıyla eklendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
