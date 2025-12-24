// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'FişMatik';

  @override
  String get loginTitle => 'Giriş';

  @override
  String get loginEmailHint => 'E-posta';

  @override
  String get loginPasswordHint => 'Şifre';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get loginEmptyFields => '⚠️ Lütfen tüm alanları doldurun.';

  @override
  String get loginPasswordMismatch => '⚠️ Şifreler eşleşmiyor.';

  @override
  String get loginAgreementRequired =>
      '⚠️ Gizlilik Politikası ve Kullanım Şartlarını kabul etmelisiniz.';

  @override
  String get registerTitle => 'Hesap Oluştur';

  @override
  String get registerEmailHint => 'E-posta';

  @override
  String get registerPasswordHint => 'Şifre';

  @override
  String get registerConfirmPasswordHint => 'Şifreyi Tekrarla';

  @override
  String get registerButton => 'Kayıt Ol';

  @override
  String get profileTitle => 'Profilim';

  @override
  String get profileLogout => 'Çıkış Yap';

  @override
  String get profileLanguage => 'Dil';

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get termsOfServiceTitle => 'Kullanım Şartları';

  @override
  String get dailyLimitExceeded => 'You have exceeded the daily scan limit.';

  @override
  String get adminPanel => 'Admin Paneli';

  @override
  String get adminSubtitle => 'Kullanıcıları ve limitleri yönet';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get language => 'Dil';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get dailyReminderOn => 'Günlük hatırlatıcı açıldı';

  @override
  String get registerSubtitle =>
      'FişMatik ailesine katıl, harcamalarını kontrol et.';

  @override
  String get emailHint => 'E-posta';

  @override
  String get passwordHint => 'Şifre';

  @override
  String get confirmPasswordHint => 'Şifre Tekrar';

  @override
  String get agreeTerms =>
      'Gizlilik Politikası ve Kullanım Şartlarını kabul etmelisiniz.';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfService => 'Kullanım Koşulları';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı? Giriş Yap';

  @override
  String get registrationSuccessTitle => 'Kayıt Başarılı! 🎉';

  @override
  String get registrationSuccessContent =>
      'Lütfen e-posta adresine gönderilen doğrulama linkine tıkla ve ardından giriş yap.';

  @override
  String get okButton => 'Tamam';

  @override
  String get fillAllFields => '⚠️ Lütfen tüm alanları doldurun.';

  @override
  String get passwordsMismatch => '⚠️ Şifreler eşleşmiyor.';

  @override
  String get registrationFailed => '❌ Kayıt oluşturulamadı';

  @override
  String get dailyReminderOff => 'Günlük hatırlatıcı kapatıldı';

  @override
  String errorOccurred(Object error) {
    return 'Bir hata oluştu: $error';
  }

  @override
  String get noData => 'Veri Yok';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get scanReceipt => 'Fiş Tara';

  @override
  String get analysis => 'Analiz';

  @override
  String get summary => 'Özet';

  @override
  String get calendar => 'Takvim';

  @override
  String get expenses => 'Harcamalar';

  @override
  String receiptCount(Object count) {
    return '$count Fiş';
  }

  @override
  String get totalSpending => 'Toplam Harcama';

  @override
  String get monthlyLimit => 'Aylık Limit';

  @override
  String get remainingBudget => 'Kalan Bütçe';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get thisMonth => 'Bu Ay';

  @override
  String get thisYear => 'Bu Yıl';

  @override
  String get all => 'Tümü';

  @override
  String get expenseAnalysis => 'Harcama Analizi';

  @override
  String get categories => 'KATEGORİLER';

  @override
  String get products => 'ÜRÜNLER';

  @override
  String get noDataInDateRange => 'Bu tarih aralığında veri yok.';

  @override
  String get noProductsToShow => 'Gösterilecek ürün yok.';

  @override
  String timesBought(Object count) {
    return '$count kez alındı';
  }

  @override
  String get statistics => 'İstatistikler';

  @override
  String get mostSpentCategory => 'En Çok Harcanan';

  @override
  String get categoryDistribution => 'Kategori Dağılımı';

  @override
  String get last6Months => 'Son 6 Ay Harcamaları';

  @override
  String get market => 'Market';

  @override
  String get fuel => 'Akaryakıt';

  @override
  String get foodAndDrink => 'Yeme-İçme';

  @override
  String get clothing => 'Giyim';

  @override
  String get technology => 'Teknoloji';

  @override
  String get other => 'Diğer';

  @override
  String get scanReceiptToStart => 'Başlamak için fiş tara!';

  @override
  String get setBudgetLimit => 'Bütçe Limiti Belirle';

  @override
  String get monthlyLimitAmount => 'Aylık Limit Tutarı';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get edit => 'Düzenle';

  @override
  String get scanReceiptTitle => 'Fişin fotoğrafını çekin';

  @override
  String get scanFeatureUnavailable =>
      'Fiş tarama şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get noInternet =>
      'İnternet bağlantısı yok. Lütfen ağınızı kontrol edin.';

  @override
  String get subscriptionDetected => 'Abonelik Algılandı';

  @override
  String subscriptionDetectedContent(Object merchant) {
    return 'Bu harcama bir abonelik gibi görünüyor ($merchant). Aboneliklerinize eklemek ister misiniz?';
  }

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get subscriptionAdded => 'Abonelik eklendi!';

  @override
  String get cameraGalleryPermission =>
      'Kamera / Galeri izni gerekli. Lütfen ayarlardan etkinleştirin.';

  @override
  String get readingText => 'Yazılar okunuyor...';

  @override
  String get aiExtractingData => 'Yapay zeka verileri ayıklıyor...';

  @override
  String get processSuccess => 'İşlem başarılı!';

  @override
  String get dataExtractionFailed =>
      'Veriler ayıklanamadı. Fiş biraz bulanık olabilir, daha net çekip tekrar deneyebilirsin.';

  @override
  String get monthlyLimitReached =>
      'Bu ayki fiş hakkın doldu. Limitless’a geçersen daha fazla fiş tarayabilirsin.';

  @override
  String get rateLimitExceeded =>
      'Şu anda çok sık deneme yaptın, iki dakika sonra tekrar deneyebilirsin.';

  @override
  String get networkError =>
      'Sunucuya bağlanırken bir sorun oluştu. İnternet bağlantını kontrol edip tekrar deneyebilirsin.';

  @override
  String get analysisError =>
      'Fiş analiz edilirken bir hata oluştu. Biraz sonra tekrar deneyebilirsin.';

  @override
  String get genericError =>
      'Bir şeyler ters gitti. İnternet bağlantını kontrol edip biraz sonra tekrar deneyebilirsin.';

  @override
  String get howToEnter => 'Nasıl Giriş Yapmak İstersin?';

  @override
  String get manualEntry => 'Manuel Giriş';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get addManualExpense => 'Manuel Gider Ekle';

  @override
  String get standardMembershipAdWarning =>
      'Standart üyelikte her işlemde reklam gösterilir. Reklamsız ve daha yüksek limit için Limitless’a geçebilirsin.';

  @override
  String saveError(Object error) {
    return 'Kaydetme hatası: $error';
  }

  @override
  String get merchantTitle => 'İş Yeri / Açıklama';

  @override
  String get merchantHint => 'Örn: Market, Kira vb.';

  @override
  String get amountTitle => 'Tutar';

  @override
  String get amountHint => '0.00';

  @override
  String get date => 'Tarih';

  @override
  String get category => 'Kategori';

  @override
  String get noteTitle => 'Not';

  @override
  String get noteHint => 'Gider hakkında kısa bir not...';

  @override
  String get manualQuotaError => 'Kota bilgisi alınamadı';

  @override
  String manualQuotaStatus(Object limit, Object used) {
    return 'Bu ayki manuel giriş kotası: $used / $limit';
  }

  @override
  String manualQuotaStatusInfinite(Object used) {
    return 'Bu ay $used manuel giriş yapıldı (Sınırsız)';
  }

  @override
  String get exportExcel => 'Excel\'e Aktar';

  @override
  String get totalSavings => 'Toplam İndirim Kazancı';

  @override
  String get taxPaid => 'Ödenen Vergi';

  @override
  String get taxReport => 'Vergi Raporu';

  @override
  String get dailyTax => 'Günlük Vergi';

  @override
  String get monthlyTax => 'Aylık Vergi';

  @override
  String get yearlyTax => 'Yıllık Vergi';

  @override
  String get exportTaxReport => 'Vergi Raporu İndir';

  @override
  String get daily => 'Günlük';

  @override
  String get monthly => 'Aylık';

  @override
  String get yearly => 'Yıllık';

  @override
  String get custom => 'Özel';

  @override
  String get selectDateRange => 'Tarih Aralığı Seç';

  @override
  String get from => 'Başlangıç';

  @override
  String get to => 'Bitiş';

  @override
  String get taxSection => 'Vergi Detayları';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get dontHaveAccount => 'Hesabın yok mu? ';

  @override
  String get loginSubtitle =>
      'Hesabına giriş yap ve fişlerini yönetmeye başla.';

  @override
  String get familyPlan => 'Aile Planı';

  @override
  String get comingSoonMessage => 'Gelecek güncellemede aktif olacaktır';

  @override
  String get history => 'Geçmiş';

  @override
  String get monthlyBudget => 'Aylık Bütçe';

  @override
  String get setMonthlyBudget => 'Aylık Bütçe Belirle';

  @override
  String get newMonthMessage =>
      'Yeni bir aya girdik! Lütfen bu ay için bütçenizi belirleyin.';

  @override
  String get upgradeMembership => 'Üyeliği Yükselt';

  @override
  String get familySettings => 'Aile Ayarları';

  @override
  String get setSalaryDay => 'Maaş Gününü Ayarla';

  @override
  String get salaryDayQuestion => 'Maaşınızı ayın hangi günü alıyorsunuz?';

  @override
  String get salaryDayDescription =>
      'Harcama döneminiz bu güne göre hesaplanacaktır.';

  @override
  String salaryDaySetSuccess(Object day) {
    return 'Maaş günü $day olarak ayarlandı.';
  }

  @override
  String get clearAll => 'Hepsini Temizle';

  @override
  String get noNewNotifications => 'Yeni bildirim yok.';

  @override
  String get notificationDefaultTitle => 'Bildirim';

  @override
  String get reject => 'Reddet';

  @override
  String get enterAddress => 'Adres Gir';

  @override
  String get homeAddress => 'Ev Adresi';

  @override
  String get familyJoinedSuccess => 'Aileye başarıyla katıldınız.';

  @override
  String fixedExpensesLabel(Object amount) {
    return 'Sabit Giderler: $amount';
  }

  @override
  String get allNotificationsCleared => 'Tüm bildirimler temizlendi.';

  @override
  String get inviteRejected => 'Davet reddedildi.';

  @override
  String get invalidAmount => 'Geçersiz tutar.';

  @override
  String get budgetLimitUpdated => 'Bütçe limiti güncellendi.';

  @override
  String get selectLanguage => 'Dili Değiştir';

  @override
  String get confirmLogoutTitle => 'Çıkış Yap';

  @override
  String get confirmLogoutMessage =>
      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';

  @override
  String get statsThisMonth => 'Bu Ay';

  @override
  String get statsTotalReceipts => 'Toplam Fiş';

  @override
  String get statsAverage => 'Ortalama';

  @override
  String membershipTierLabel(Object tier) {
    return '$tier Üyelik';
  }

  @override
  String get manageCancelSubscription => 'Aboneliği Yönet / İptal Et';

  @override
  String get membershipStatusExpired => 'Üyeliğiniz sona erdi.';

  @override
  String membershipStatusDaysLeft(Object days) {
    return '$days gün kaldı';
  }

  @override
  String membershipStatusHoursLeft(Object hours) {
    return '$hours saat kaldı';
  }

  @override
  String membershipStatusMinutesLeft(Object minutes) {
    return '$minutes dakika kaldı';
  }

  @override
  String get membershipStatusSoon => 'Az kaldı';

  @override
  String get familyPlanMembersLimit =>
      '35 fiş/gün • 20 AI Sohbet • 200 Manuel Giriş • Aile Paylaşımı';

  @override
  String get limitlessPlanLimit =>
      '25 fiş/gün • 10 AI Sohbet • 100 Manuel Giriş';

  @override
  String get premiumPlanLimit => '10 fiş/gün • 50 Manuel Giriş';

  @override
  String get standardPlanLimit => '1 fiş/gün • 20 Manuel Giriş';

  @override
  String get receiptLimitTitle => 'Aylık Fiş Limiti';

  @override
  String receiptLimitContent(Object limit) {
    return 'Üyeliğinizin aylık fiş limitine ($limit) ulaştınız. Daha fazlası için üyeliğinizi yükseltebilirsiniz.';
  }

  @override
  String budgetExceeded(Object amount) {
    return 'Bütçe aşıldı! $amount fazla';
  }

  @override
  String remainingLabel(Object amount) {
    return 'Kalan: $amount';
  }

  @override
  String get setBudgetLimitPrompt => 'Bütçe limiti belirleyin';

  @override
  String get recentActivity => 'Son Aktivite';

  @override
  String get seeAll => 'Tümünü Gör';

  @override
  String get noReceiptsYet => 'Henüz Fiş Yok';

  @override
  String get memberToolsTitle => 'Üye Araçları';

  @override
  String get featureScanSubTitle => 'Fiş Tara & Abonelik Tespiti';

  @override
  String get featureScanSubDesc => 'AI ile fatura tanıma ve otomatik takip';

  @override
  String get featurePriceCompTitle => 'Nerede En Ucuz?';

  @override
  String get featurePriceCompDesc => 'Market bazlı fiyat karşılaştırma';

  @override
  String get smartPriceTrackerTitle => 'Akıllı Tasarruf Rehberiniz';

  @override
  String get smartPriceTrackerSubTitle =>
      'En çok aldığınız ürünlerin fiyat değişimlerini ve market önerilerini görün.';

  @override
  String marketRecommendation(Object market) {
    return 'Sizin için en uygun market: $market';
  }

  @override
  String get priceComparisonMode => 'Fiyat Karşılaştırma Modu';

  @override
  String get brandSpecificMode => 'Marka Bazlı';

  @override
  String get genericProductMode => 'Ürün Bazlı';

  @override
  String brandCount(Object count) {
    return '$count farklı marka';
  }

  @override
  String priceRange(Object max, Object min) {
    return '₺$min - ₺$max';
  }

  @override
  String cheapestAt(Object merchant) {
    return '$merchant marketinde daha ucuz!';
  }

  @override
  String get viewAllBrands => 'Tüm Markaları Gör';

  @override
  String get switchToGeneric => 'Ürün bazlı görünüme geç';

  @override
  String get switchToBrand => 'Marka bazlı görünüme geç';

  @override
  String get bestPriceRecently => 'Son dönem en ucuz fiyat burada bulundu.';

  @override
  String get noProductHistory => 'Bu ürün için henüz yeterli veri yok.';

  @override
  String get viewHistory => 'Geçmişi Gör';

  @override
  String get frequentProducts => 'Sık Aldığınız Ürünler';

  @override
  String get featurePremiumOnly =>
      'Bu özellik sadece Premium ve Aile üyeleri içindir.';

  @override
  String retryDetected(Object count) {
    return 'Tekrar deneme algılandı. Hakkınız iade edildi. ($count)';
  }

  @override
  String dailyLimitLabel(Object limit, Object usage) {
    return '$usage / $limit fiş tarandı';
  }

  @override
  String get noInternetError => 'İnternet bağlantısı yok.';

  @override
  String get productsOptional => 'Ürünler (Opsiyonel)';

  @override
  String get productName => 'Ürün Adı';

  @override
  String get addProduct => 'Ürün Ekle';

  @override
  String get unitPrice => 'Birim Fiyat';

  @override
  String get receiptNotFound => 'Fiş bulunamadı.';

  @override
  String get manualEntrySource => 'Manuel giriş';

  @override
  String get scanReceiptSource => 'Fiş tarama';

  @override
  String get totalLabel => 'TOPLAM';

  @override
  String get deleteReceiptTitle => 'Fişi Sil';

  @override
  String get deleteReceiptMessage =>
      'Bu fişi kalıcı olarak silmek istediğine emin misin?';

  @override
  String get delete => 'Sil';

  @override
  String get receiptDeleted => 'Fiş silindi.';

  @override
  String get noHistoryYet => 'Henüz Geçmiş Yok';

  @override
  String get noHistoryDescription =>
      'Fiş eklemeye başladığınızda geçmiş harcamalarınızı burada görebilirsiniz.';

  @override
  String errorPrefix(Object error) {
    return 'Hata: $error';
  }

  @override
  String get getReportTooltip => 'Rapor Al';

  @override
  String get noDataForPeriod => 'Bu dönem için veri bulunamadı';

  @override
  String get createReport => 'Rapor Oluştur';

  @override
  String get reports => 'Raporlar';

  @override
  String get downloadPdfAndShare => 'PDF Olarak İndir ve Paylaş';

  @override
  String get downloadExcelAndShare => 'Excel Olarak İndir ve Paylaş';

  @override
  String get preparingReport => 'Rapor hazırlanıyor...';

  @override
  String get noReportData => 'Rapor için veri bulunamadı.';

  @override
  String get categoryManagementUpgradePrompt =>
      'Kategori yönetimi Standart/Pro üyeliğe özeldir.';

  @override
  String get newCategory => 'Yeni Kategori';

  @override
  String get categoryName => 'Kategori Adı';

  @override
  String get monthlyBudgetLimitOptional => 'Aylık Bütçe Limiti (Opsiyonel)';

  @override
  String get add => 'Ekle';

  @override
  String get limitLabel => 'Limiti';

  @override
  String get monthlyBudgetLimit => 'Aylık Bütçe Limiti';

  @override
  String get myCategories => 'Kategorilerim';

  @override
  String spendingVsLimit(Object limit, Object spending) {
    return 'Harcama: $spending / $limit TL';
  }

  @override
  String get noLimit => 'Limit yok';

  @override
  String get spendingTrends => 'Harcama Trendleri';

  @override
  String get last7Days => 'Son 7 Gün';

  @override
  String get last30Days => 'Son 30 Gün';

  @override
  String get averageDailySpending => 'Ortalama Günlük Harcama';

  @override
  String get highestSpendingDay => 'En Çok Harcama Yapılan Gün';

  @override
  String get last12Months => 'Son 12 Ay';

  @override
  String get dailySpendingChart => 'Günlük Harcama';

  @override
  String get fiveDaySpendingChart => '5 Günlük Harcama';

  @override
  String get monthlySpendingChart => 'Aylık Harcama';

  @override
  String get fixedExpenses => 'Sabit Giderler';

  @override
  String get editCreditCard => 'Kredi Kartı Düzenle';

  @override
  String get editCredit => 'Krediyi Düzenle';

  @override
  String get addNewCredit => 'Yeni Kredi Ekle';

  @override
  String get creditNameHint => 'Kredi/Kart Adı';

  @override
  String get currentTotalDebt => 'Güncel Toplam Borç';

  @override
  String get totalCreditAmount => 'Toplam Kredi Tutarı';

  @override
  String get minimumPaymentAmount => 'Asgari Ödeme Tutarı';

  @override
  String get monthlyInstallmentAmount => 'Aylık Taksit Tutarı';

  @override
  String get totalInstallmentsLabel => 'Toplam Taksit';

  @override
  String get remainingInstallmentsLabel => 'Kalan Taksit';

  @override
  String get paymentDayHint => 'Ödeme Günü';

  @override
  String get addCreditCard => 'Kredi Kartı Ekle';

  @override
  String get bankNameHint => 'Banka Adı';

  @override
  String get cardLimit => 'Kart Limiti';

  @override
  String get cardLimitHelper => 'Toplam limitiniz';

  @override
  String get currentStatementDebt => 'Gelecek Ekstre Borcu';

  @override
  String get lastPaymentDayHint => 'Son Ödeme Günü';

  @override
  String minPaymentCalculated(Object amount) {
    return 'Asgari ödeme: $amount';
  }

  @override
  String get deleteConfirmTitle => 'Silme Onayı';

  @override
  String get deleteCreditMessage =>
      'Bu kaydı silmek istediğinize emin misiniz?';

  @override
  String get selectExpense => 'Gider Seçin';

  @override
  String get searchExpenseHint => 'Gider ara...';

  @override
  String get addCreditInstallment => 'Kredi Taksiti Ekle';

  @override
  String get addCreditInstallmentSub => 'Banka kredisi, eşya taksidi vb.';

  @override
  String get addCreditCardSub => 'Otomatik asgari ödeme hesaplama';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String get addCustomSubscription => 'Özel Abonelik Ekle';

  @override
  String get editExpense => 'Gideri Düzenle';

  @override
  String get newFixedExpense => 'Yeni Sabit Gider';

  @override
  String get expenseNameLabel => 'Gider Adı';

  @override
  String get amountLabel => 'Tutar';

  @override
  String get dayLabel => 'Ödeme Günü (1-31)';

  @override
  String get totalMonthlyFixedExpenses => 'Aylık Toplam Sabit Gider';

  @override
  String get myCredits => 'Kredilerim';

  @override
  String get noCreditsAdded => 'Henüz kredi eklenmedi.';

  @override
  String creditCardDetail(Object day) {
    return 'Kredi Kartı • Ayın $day. günü';
  }

  @override
  String creditInstallmentDetail(Object day, Object remaining, Object total) {
    return '$remaining / $total Taksit Kaldı • Ayın $day. günü';
  }

  @override
  String get estimatedMonthly => 'Aylık (tahmini)';

  @override
  String get subscriptionsOther => 'Abonelikler / Diğer';

  @override
  String get noSubscriptionsAdded => 'Henüz abonelik eklenmedi.';

  @override
  String dayOfMonth(Object day) {
    return 'Ayın $day. günü';
  }

  @override
  String get about => 'Hakkında';

  @override
  String get appDescription =>
      'FişMatik; fiş, fatura ve dekont tarama, otomatik abonelik tespiti, akıllı bütçe tahminleme ve en ucuz fiyatı bulmanızı sağlayan alışveriş rehberi özellikleriyle tam donanımlı finans asistanınızdır.';

  @override
  String get website => 'Web Sitesi';

  @override
  String get contact => 'İletişim';

  @override
  String get allRightsReserved => '© 2025 FişMatik. Tüm hakları saklıdır.';

  @override
  String get notificationInstantTitle => 'Anlık Bildirimler';

  @override
  String get notificationInstantDesc => 'FişMatik anlık bildirim kanalı';

  @override
  String get notificationDailyTitle => 'Günlük Hatırlatıcı';

  @override
  String get notificationDailyDesc => 'Her gün fişlerini hatırlatır';

  @override
  String get notificationDailyReminderTitle =>
      'Heey! Cüzdanın Ne Alemde? 😉|Fiş Dağ Olmasın! 🏔️|Cebindeki Kağıtlar... 📄';

  @override
  String get notificationDailyReminderBody =>
      'Bugünkü harcamaları girmeden mi uyuyorsun? Cüzdanın darılır!|İki dakikada fişlerini tara, bütçeni kontrol altında tut. Hadi bekliyorum!|Buruş buruş olduklarını biliyorum. Onları FişMatik\'e aktar da ferahlayalım!';

  @override
  String get notificationBudgetExceededTitle =>
      'Cüzdanda Kırmızı Alarm! 🛑|Patron Çıldırdı! 🤪|Harca Harca Bitmez Sandın... 💸';

  @override
  String get notificationBudgetExceededBody =>
      'Bütçeyi aştın! Cüzdanı yavaşça masaya bırak ve oradan uzaklaş...|Bu ay bütçeyi biraz (fazlaca) sarsmışız sanki. Kemerleri biraz sıkalım mı?|Hop dedik! Limitleri biraz aştık. Bir sonraki harcamadan önce derin bir nefes al.';

  @override
  String get notificationBudgetWarningTitle =>
      'Dikkat! Cüzdan İnceltiliyor 🤏|Sarı Işık Yandı! 🟡';

  @override
  String notificationBudgetWarningBody(Object ratio) {
    return 'Bütçenin %$ratio\'sini bitirdik bile. Yavaşlasak mı biraz?|Limitlere yaklaşıyoruz kaptan! Frenlere biraz dokunmakta fayda var.';
  }

  @override
  String notificationSubscriptionReminderTitle(Object name) {
    return 'Netflix & Chill... & Borç 🍿|$name Geliyor! 🎶';
  }

  @override
  String notificationSubscriptionReminderBody(Object amount, Object name) {
    return '$name faturası yine kapıda. Bakalım bu ay kaç dizi bitirdin?|Kulaklıkları hazırla, $name için $amount ödenmek üzere. Ritmine devam!';
  }

  @override
  String notificationCategoryExceededTitle(Object category) {
    return '$category Kontrolden Çıktı! 🔥';
  }

  @override
  String notificationCategoryExceededBody(Object category) {
    return '$category için bütçeyi yakıp geçtik. Biraz mola vermeye ne dersin?';
  }

  @override
  String notificationCategoryWarningTitle(Object category) {
    return '$category Uyarı Veriyor! ⚠️';
  }

  @override
  String notificationCategoryWarningBody(Object category, Object ratio) {
    return '$category bütçesinin %$ratio\'sini yutmuşuz. Aman dikkat!';
  }

  @override
  String get notificationSubscriptionChannel => 'Abonelik Hatırlatıcı';

  @override
  String get notificationSubscriptionChannelDesc =>
      'Abonelik ödemelerini hatırlatır';

  @override
  String get close => 'Kapat';

  @override
  String get creditInstallmentDesc => 'Banka kredisi veya taksitli borç';

  @override
  String get addCustomExpense => 'Özel Gider Ekle';

  @override
  String get areYouSure => 'Emin misiniz?';

  @override
  String get expenseWillBeDeleted => 'Bu gider kalıcı olarak silinecektir.';

  @override
  String get monthlyFixedExpense => 'Aylık Toplam Gider';

  @override
  String activeExpensesCount(Object count) {
    return '$count Aktif Gider';
  }

  @override
  String get noFixedExpensesYet => 'Henüz sabit gider eklenmedi.';

  @override
  String renewsOnDay(Object day) {
    return 'Haftalık / Ayın $day. günü';
  }

  @override
  String get lastUpdated => 'Son Güncelleme: ';

  @override
  String get privacyPolicyLastUpdated => '19 Aralık 2025';

  @override
  String get privacyPolicySection1Title => '1. Toplanan Veriler';

  @override
  String get privacyPolicySection1Content =>
      'FişMatik uygulaması, harcamalarınızı takip edebilmeniz için fiş görselleri, harcama kalemleri ve tutarları gibi verileri toplar.';

  @override
  String get privacyPolicySection2Title => '2. Verilerin Kullanımı';

  @override
  String get privacyPolicySection2Content =>
      'Toplanan veriler size bütçe analizi sunmak ve finansal koçluk hizmeti sağlamak için kullanılır.';

  @override
  String get privacyPolicySection3Title => '3. Veri Güvenliği';

  @override
  String get privacyPolicySection3Content =>
      'Verileriniz Supabase altyapısında güvenle saklanmaktadır.';

  @override
  String get privacyPolicySection4Title => '4. Paylaşım';

  @override
  String get privacyPolicySection4Content =>
      'Verileriniz üçüncü şahıslarla reklam amaçlı paylaşılmaz.';

  @override
  String get privacyPolicySection5Title => '5. Haklarınız';

  @override
  String get privacyPolicySection5Content =>
      'Verilerinizi istediğiniz zaman silebilir veya dışa aktarabilirsiniz.';

  @override
  String get privacyPolicySection6Title => '6. Çerezler';

  @override
  String get privacyPolicySection6Content =>
      'Uygulama içinde oturum yönetimi için gerekli çerezler kullanılır.';

  @override
  String get privacyPolicyFooter =>
      'Bu gizlilik politikası FişMatik kullanıcılarını bilgilendirmek amacıyla hazırlanmıştır.';

  @override
  String get termsLastUpdated => '26 Kasım 2024';

  @override
  String get termsSection1Title => '1. Hizmet Tanımı';

  @override
  String get termsSection1Content =>
      'FişMatik; harcama takibi, fiş/fatura/dekont tarama, abonelik ve düzenli ödeme tespiti, yapay zeka destekli bütçe tahminleme (Forecasting) ve ürün fiyat karşılaştırması (Alışveriş Rehberi) hizmetlerini sunan kapsamlı bir finansal yönetim uygulamasıdır.';

  @override
  String get termsSection2Title => '2. Hesap Oluşturma';

  @override
  String get termsSection2Content =>
      '• 13 yaşından büyük olmalısınız\n• Geçerli bir e-posta adresi sağlamalısınız\n• Doğru ve güncel bilgiler vermelisiniz\n• Şifrenizin güvenliğinden siz sorumlusunuz';

  @override
  String get termsSection3Title => '3. Üyelik Seviyeleri';

  @override
  String get termsSection3Content =>
      'Ücretsiz (0 TL):\n• Günlük 1 fiş tarama\n• Aylık 20 manuel giriş\n• Sınırsız abonelik takibi\n• Reklamlı deneyim\n\nStandart (49.99 TL / Ay):\n• Günlük 10 fiş tarama\n• Aylık 50 manuel giriş\n• Sınırsız abonelik takibi\n• Kategori yönetimi\n• Reklamsız deneyim\n• Raporlar\n• Alışveriş Rehberi\n\nPremium (79.99 TL / Ay):\n• Günlük 25 fiş tarama\n• Aylık 100 manuel giriş\n• Sınırsız abonelik takibi\n• Reklamsız deneyim\n• AI Finans Koçu\n• Akıllı Bütçe Tahmini\n• Kategori yönetimi\n• Raporlar\n• Alışveriş Rehberi\n\nAile Ekonomisi (99.99 TL / Ay):\n• Günlük 35 fiş tarama (Aile toplamı)\n• Aylık 200 manuel giriş (Aile toplamı)\n• Sınırsız abonelik takibi\n• Reklamsız deneyim\n• AI Finans Koçu\n• Akıllı Bütçe Tahmini\n• Kategori yönetimi\n• Raporlar\n• Alışveriş Rehberi\n• Aile Paylaşımı';

  @override
  String get termsSection4Title => '4. Kullanım Kuralları';

  @override
  String get termsSection4Content =>
      'İzin Verilen:\n• Kişisel harcama takibi\n• Fiş dijitalleştirme\n• Bütçe yönetimi\n\nYasak:\n• Ticari amaçlı kullanım (izinsiz)\n• Sistemi manipüle etme\n• Sahte fiş veya veri yükleme\n• Spam veya otomatik bot kullanımı';

  @override
  String get termsSection5Title => '5. Sorumluluk Reddi';

  @override
  String get termsSection5Content =>
      '• Uygulamayı kendi riskinizle kullanırsınız\n• Mali kararlarınızdan biz sorumlu değiliz\n• Vergi veya muhasebe danışmanlığı sağlamıyoruz\n• OCR ve AI analizi %100 doğru olmayabilir';

  @override
  String get termsSection6Title => '6. Hesap Sonlandırma';

  @override
  String get termsSection6Content =>
      '• Hesabınızı istediğiniz zaman silebilirsiniz\n• Kullanım şartlarını ihlal durumunda hesabınız askıya alınabilir\n• Silme işlemi geri alınamaz';

  @override
  String get termsSection7Title => '7. İletişim';

  @override
  String get termsSection7Content =>
      'Kullanım şartları hakkında sorularınız için:\n\nE-posta: info@kfsoftware.app';

  @override
  String get termsFooter =>
      'FişMatik uygulamasını kullanarak bu kullanım şartlarını okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan edersiniz.';

  @override
  String get salaryDay => 'Maaş Günü';

  @override
  String get noReceiptsFoundInRange => 'Bu tarih aralığında fiş bulunamadı.';

  @override
  String get totalSpendingLabel => 'Toplam Harcama';

  @override
  String get noCategoryData => 'Kategori verisi bulunmuyor.';

  @override
  String get noTransactionInCategory => 'Bu kategoride işlem bulunmuyor.';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get dailyReminderDesc => 'Her gün fiş taramayı hatırlat';

  @override
  String get reminderTime => 'Hatırlatma Saati';

  @override
  String get summaryNotifications => 'Özet Bildirimleri';

  @override
  String get weeklySummary => 'Haftalık Özet';

  @override
  String get weeklySummaryDesc => 'Her Pazar akşamı harcama özeti';

  @override
  String get monthlySummary => 'Aylık Özet';

  @override
  String get monthlySummaryDesc => 'Ay sonunda detaylı rapor';

  @override
  String get budgetAlerts => 'Bütçe Uyarıları';

  @override
  String get budgetAlertsDesc => '%75, %90 ve aşım bildirimleri';

  @override
  String get subscriptionReminders => 'Abonelik Hatırlatıcıları';

  @override
  String get subscriptionRemindersDesc => 'Yenileme tarihlerini hatırlat';

  @override
  String get sendTestNotification => 'Test Bildirimi Gönder';

  @override
  String get testNotificationTitle => '✅ Test Bildirimi';

  @override
  String get testNotificationBody => 'Bildirimler başarıyla çalışıyor!';

  @override
  String get notificationPermissionDenied => 'Bildirim izni reddedildi.';

  @override
  String get settingsLoadError => 'Ayarlar yüklenemedi';

  @override
  String get settingsSaveError => 'Ayarlar kaydedilemedi';

  @override
  String get googleSignIn => 'Google ile Giriş Yap';

  @override
  String get unconfirmedEmailError => 'E-posta adresi doğrulanmamış.';

  @override
  String get invalidCredentialsError => 'E-posta veya şifre hatalı.';

  @override
  String get accountBlockedError => 'Hesabınız engellenmiştir.';

  @override
  String get generalError => 'Bir hata oluştu.';

  @override
  String get loginFailed => '❌ Giriş yapılamadı';

  @override
  String get passwordConfirmLabel => 'Şifre (Tekrar)';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor.';

  @override
  String get mustAgreeToTerms => 'Şartları kabul etmelisiniz.';

  @override
  String get verificationEmailSentTitle => 'Doğrulama E-postası Gönderildi';

  @override
  String get verificationEmailSentBody =>
      'Lütfen e-posta adresinizi doğrulayın ve ardından giriş yapın.';

  @override
  String get ok => 'Tamam';

  @override
  String get weakPasswordError => 'Şifre çok zayıf.';

  @override
  String get invalidEmailError => 'Geçersiz e-posta adresi.';

  @override
  String get googleSignUp => 'Google ile Kayıt Ol';

  @override
  String get readAndAcceptPre => 'Okudum ve ';

  @override
  String get readAndAcceptAnd => ' ve ';

  @override
  String get readAndAcceptPost => ' kabul ediyorum.';

  @override
  String get forgotPasswordTitle => 'Şifremi Unuttum';

  @override
  String get forgotPasswordSubtitle =>
      'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.';

  @override
  String get resetPasswordLinkSent => 'Şifre sıfırlama bağlantısı gönderildi.';

  @override
  String get enterEmailError => 'Lütfen e-posta adresinizi girin.';

  @override
  String get send => 'Gönder';

  @override
  String get profilePhotoUpdated => 'Profil fotoğrafı güncellendi!';

  @override
  String get photoUploadError => 'Fotoğraf yüklenemedi';

  @override
  String get nameOrSurnameRequired =>
      'En azından ad veya soyad girmen gerekiyor.';

  @override
  String get profileUpdated => 'Profil bilgilerin güncellendi.';

  @override
  String get profileUpdateError => 'Profil güncellenemedi';

  @override
  String get fillAllPasswordFields => 'Tüm şifre alanlarını doldur.';

  @override
  String get sessionNotFound => 'Oturum bilgisi bulunamadı.';

  @override
  String get passwordUpdated => 'Şifren başarıyla güncellendi!';

  @override
  String get currentPasswordIncorrect => 'Mevcut şifre doğru değil.';

  @override
  String get passwordUpdateFailed => 'Şifre güncellenemedi.';

  @override
  String get deleteAccountTitle => 'Hesabı Sil';

  @override
  String get deleteAccountWarning => 'Bu işlem geri alınamaz!';

  @override
  String get deleteAccountDataNotice =>
      'Tüm verileriniz (fişler, kategoriler, ayarlar) kalıcı olarak silinecektir.';

  @override
  String get whyLeaving => 'Neden ayrılıyorsunuz?';

  @override
  String get selectReason => 'Bir sebep seçin';

  @override
  String get reasonAppNotUsed => 'Uygulamayı artık kullanmıyorum';

  @override
  String get reasonAnotherAccount => 'Başka bir hesap açacağım';

  @override
  String get reasonPrivacyConcerns => 'Veri gizliliği endişelerim var';

  @override
  String get reasonNotMeetingExpectations =>
      'Uygulama beklentilerimi karşılamadı';

  @override
  String get reasonOther => 'Diğer';

  @override
  String get pleaseSpecifyReason => 'Lütfen sebebi belirtin';

  @override
  String get enterPasswordToDelete => 'Hesabınızı silmek için şifrenizi girin:';

  @override
  String get emailNotFound => 'E-posta bulunamadı';

  @override
  String get requestReceived => 'Talep Alındı';

  @override
  String get deleteRequestSuccess =>
      'Hesap silme talebiniz başarıyla alındı. Hesabınız inceleme sürecine alınmıştır ve bu süreçte giriş yapamayacaksınız.';

  @override
  String get accountStats => 'Hesap İstatistikleri';

  @override
  String get memberSinceLabel => 'Üye Olma';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get firstNameLabel => 'Ad';

  @override
  String get lastNameLabel => 'Soyad';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get saveProfileButton => 'Profilimi Kaydet';

  @override
  String get changePasswordTitle => 'Şifre Değiştir';

  @override
  String get currentPasswordLabel => 'Mevcut Şifre';

  @override
  String get newPasswordLabel => 'Yeni Şifre';

  @override
  String get confirmNewPasswordLabel => 'Yeni Şifre (Tekrar)';

  @override
  String get updatePasswordButton => 'Şifremi Güncelle';

  @override
  String get dangerZoneTitle => 'Tehlikeli Bölge';

  @override
  String get deleteAccountSubtitle => 'Hesabınızı kalıcı olarak silebilirsiniz';

  @override
  String get deleteAccountNotice =>
      'Bu işlem geri alınamaz. Tüm verileriniz (fişler, kategoriler, ayarlar) kalıcı olarak silinecektir.';

  @override
  String get createFamily => 'Aile Oluştur';

  @override
  String get familyNameLabel => 'Aile Adı (Örn: Yılmaz Ailesi)';

  @override
  String get addressLabel => 'Ev Adresi (Zorunlu)';

  @override
  String get addressHint => 'Ortak yaşam alanı adresi';

  @override
  String get addressRequired => 'Adres girmek zorunludur.';

  @override
  String get familyCreatedSuccess => 'Aile başarıyla oluşturuldu!';

  @override
  String get inviteMember => 'Üye Davet Et';

  @override
  String get familyLimitReached => 'Aile planı limiti doldu (Maksimum 5 kişi).';

  @override
  String get enterEmailToInvite =>
      'Davet etmek istediğiniz kişinin e-posta adresini girin.';

  @override
  String get inviteSending => 'Davet gönderiliyor...';

  @override
  String get inviteSentSuccess => 'Davet başarıyla gönderildi.';

  @override
  String get leaveFamilyTitle => 'Aileden Ayrıl';

  @override
  String get leaveFamilyConfirm =>
      'Aileden ayrılmak istediğinize emin misiniz? Ortak verilere erişiminizi kaybedeceksiniz ve Standart plana döneceksiniz.';

  @override
  String get leaveFamilyButton => 'Ayrıl';

  @override
  String get leftFamilySuccess => 'Aileden ayrıldınız.';

  @override
  String get removeMemberTitle => 'Üyeyi Çıkar';

  @override
  String removeMemberConfirm(Object email) {
    return '$email adresli üyeyi aileden çıkarmak istediğinize emin misiniz?';
  }

  @override
  String get removeButton => 'Çıkar';

  @override
  String get memberRemovedSuccess => 'Üye çıkarıldı.';

  @override
  String get familyPlanTitle => 'Aile Planı';

  @override
  String get noFamilyYet => 'Henüz bir aileniz yok.';

  @override
  String get familyPlanDesc =>
      'Aile Planı ile harcamalarınızı ortak yönetin, bütçenizi birlikte takip edin.';

  @override
  String get adminLabel => 'Yönetici';

  @override
  String get memberLabel => 'Üye';

  @override
  String get familyMembersCount => 'Aile Üyeleri';

  @override
  String get removeFromFamilyTooltip => 'Aileden Çıkar';

  @override
  String get ownerCannotLeaveNotice =>
      'Not: Aile yöneticisi olarak aileden ayrılamazsınız. Aileyi tamamen silmek için lütfen destek ile iletişime geçin.';

  @override
  String get badgesTitle => 'Başarı Rozetleri';

  @override
  String get earnedBadges => 'Kazanılan Rozetler';

  @override
  String get locked => 'Kilitli';

  @override
  String get earned => 'Kazanıldı!';

  @override
  String get oneMonthProGift => '1 Ay Pro Hediye!';

  @override
  String get earnThisBadge => 'Bu rozeti kazanmak için';

  @override
  String get myAchievements => 'Başarımlarım';

  @override
  String get dataLoadError => 'Veri yüklenemedi';

  @override
  String get myBadges => 'Rozetlerim';

  @override
  String get dailyStreakLabel => 'Günlük Seri';

  @override
  String get keepGoing => 'Devam et!';

  @override
  String get earnedStat => 'Kazanılan';

  @override
  String get lockedStat => 'Kilitli';

  @override
  String get completionStat => 'Tamamlama';

  @override
  String get notEarnedYet => 'Henüz Kazanılmadı';

  @override
  String xpReward(Object xp) {
    return '+$xp XP';
  }

  @override
  String get levelUpTitle => 'Seviye Atladın!';

  @override
  String levelUpBody(Object level, Object levelName) {
    return 'Tebrikler! Seviye $level\'e ulaştın: $levelName';
  }

  @override
  String get newBadgeTitle => 'Yeni Rozet!';

  @override
  String newBadgeBody(Object name, Object xp) {
    return '$name rozetini kazandın! +$xp XP';
  }

  @override
  String get badge_first_receipt_name => 'İlk Adım';

  @override
  String get badge_first_receipt_desc => 'İlk fişini tarattın!';

  @override
  String get badge_first_receipt_msg =>
      '🎉 Harika bir başlangıç! Her büyük yolculuk bir adımla başlar.';

  @override
  String get badge_receipt_5_name => 'Düzenli Kullanıcı';

  @override
  String get badge_receipt_5_desc => '5 fiş ekledin.';

  @override
  String get badge_receipt_5_msg =>
      '💪 Harikasın! Düzenli takip başarının anahtarı.';

  @override
  String get badge_receipt_10_name => 'Profesyonel';

  @override
  String get badge_receipt_10_desc => '10 fiş ekledin.';

  @override
  String get badge_receipt_10_msg =>
      '🌟 İnanılmazsın! Artık bir profesyonelsin!';

  @override
  String get badge_receipt_50_name => 'Uzman';

  @override
  String get badge_receipt_50_desc => '50 fiş ekledin.';

  @override
  String get badge_receipt_50_msg =>
      '🏆 Efsanesin! Bu seviyeye çok az kişi ulaşır.';

  @override
  String get badge_saver_name => 'Tasarrufçu';

  @override
  String get badge_saver_desc => 'Toplam 1000 TL harcama kaydettin.';

  @override
  String get badge_saver_msg =>
      '💰 Harika! Harcamalarını takip etmek zenginliğin ilk adımı.';

  @override
  String get badge_big_spender_name => 'Büyük Harcama';

  @override
  String get badge_big_spender_desc =>
      'Tek seferde 500 TL üzeri harcama yaptın.';

  @override
  String get badge_big_spender_msg =>
      '💳 Büyük harcamalar büyük sorumluluklar getirir!';

  @override
  String get badge_budget_master_name => 'Bütçe Ustası';

  @override
  String get badge_budget_master_desc => 'Bir ay boyunca bütçeni aşmadın.';

  @override
  String get badge_budget_master_msg =>
      '🎯 Mükemmel! Disiplin başarının temelidir.';

  @override
  String get badge_night_owl_name => 'Gece Kuşu';

  @override
  String get badge_night_owl_desc => 'Gece yarısından sonra fiş ekledin.';

  @override
  String get badge_night_owl_msg =>
      '🌙 Gece gece ne yapıyorsun sen? Ama helal olsun!';

  @override
  String get badge_early_bird_name => 'Erken Kuş';

  @override
  String get badge_early_bird_desc => 'Sabah 6\'dan önce fiş ekledin.';

  @override
  String get badge_early_bird_msg =>
      '🌅 Erken kalkan yol alır! Sen de yoldasın.';

  @override
  String get badge_weekend_shopper_name => 'Hafta Sonu Alışverişçisi';

  @override
  String get badge_weekend_shopper_desc => 'Hafta sonu alışveriş yaptın.';

  @override
  String get badge_weekend_shopper_msg =>
      '🛍️ Hafta sonları alışverişin tadı bir başka!';

  @override
  String get badge_loyal_user_name => 'Sadık Üye';

  @override
  String get badge_loyal_user_desc => 'Uygulamayı 30 gün boyunca kullandın.';

  @override
  String get badge_loyal_user_msg => '❤️ Seninle olmak harika! Teşekkürler!';

  @override
  String get badge_category_master_name => 'Kategori Uzmanı';

  @override
  String get badge_category_master_desc =>
      '5 farklı kategoride harcama yaptın.';

  @override
  String get badge_category_master_msg =>
      '📊 Çeşitlilik güzeldir! Harcamalarını iyi dağıtıyorsun.';

  @override
  String get badge_ultimate_master_name => 'Nihai Usta';

  @override
  String get badge_ultimate_master_desc =>
      '100 fiş ekle ve 10.000 TL harcama kaydet.';

  @override
  String get badge_ultimate_master_msg =>
      '👑 EFSANE! Sen gerçek bir ustasın! 1 ay Pro hediyemiz seninle!';

  @override
  String get badge_receipt_100_name => '100 Fiş';

  @override
  String get badge_receipt_100_desc => '100 fiş taradın!';

  @override
  String get badge_receipt_500_name => '500 Fiş';

  @override
  String get badge_receipt_500_desc => '500 fiş taradın!';

  @override
  String get badge_receipt_1000_name => '1000 Fiş';

  @override
  String get badge_receipt_1000_desc => '1000 fiş taradın! İnanılmaz!';

  @override
  String get badge_streak_7_name => '7 Günlük Seri';

  @override
  String get badge_streak_7_desc => '7 gün üst üste fiş taradın!';

  @override
  String get badge_streak_30_name => '30 Günlük Seri';

  @override
  String get badge_streak_30_desc => '30 gün üst üste fiş taradın!';

  @override
  String get badge_streak_365_name => 'Yıllık Şampiyon';

  @override
  String get badge_streak_365_desc => '365 gün aktif kullanım!';

  @override
  String get badge_saver_master_name => 'Tasarruf Ustası';

  @override
  String get badge_saver_master_desc => 'Bütçenin %20\'sini biriktirdin!';

  @override
  String get badge_goal_hunter_name => 'Hedef Avcısı';

  @override
  String get badge_goal_hunter_desc => 'Aylık hedefini 3 ay üst üste tuttun!';

  @override
  String get badge_market_master_name => 'Market Ustası';

  @override
  String get badge_market_master_desc => 'Market kategorisinde 50 fiş!';

  @override
  String get badge_fuel_tracker_name => 'Yakıt Takipçisi';

  @override
  String get badge_fuel_tracker_desc => 'Akaryakıt kategorisinde 30 fiş!';

  @override
  String get badge_gourmet_name => 'Gurme';

  @override
  String get badge_gourmet_desc => 'Yeme-İçme kategorisinde 50 fiş!';

  @override
  String levelLabel(Object level) {
    return 'Seviye $level';
  }

  @override
  String nextLevelXp(Object xp) {
    return 'Sonraki seviye: $xp XP';
  }

  @override
  String get maxLevel => 'Maksimum Seviye!';

  @override
  String get level_1_name => 'Acemi';

  @override
  String get level_2_name => 'Çaylak';

  @override
  String get level_3_name => 'Kıdemli';

  @override
  String get level_4_name => 'Usta';

  @override
  String get level_5_name => 'Üstat';

  @override
  String get level_6_name => 'Efsane';

  @override
  String get level_7_name => 'Gözlemci';

  @override
  String get level_8_name => 'Yönetici';

  @override
  String get level_9_name => 'Şampiyon';

  @override
  String get level_10_name => 'Kral';

  @override
  String get editReceiptTitle => 'Fişi Düzenle';

  @override
  String get selectCategoryError => 'Lütfen bir kategori seçin.';

  @override
  String get changesSaved => 'Değişiklikler kaydedildi.';

  @override
  String get merchantLabel => 'Mağaza Adı';

  @override
  String get totalAmountLabel => 'Toplam Tutar';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get receiptDateLabel => 'Tarih';

  @override
  String get saveChangesButton => 'Değişiklikleri Kaydet';

  @override
  String get shoppingListTitle => 'Alışveriş Listesi';

  @override
  String get shoppingHint => 'Ne alacaksınız? (Örn: Süt)';

  @override
  String get checkingPriceHistory => 'Fiyat geçmişi kontrol ediliyor...';

  @override
  String lastPriceInfo(Object date, Object merchant, Object price) {
    return 'En son $merchant\'den $date tarihinde $price TL\'ye aldınız.';
  }

  @override
  String get emptyShoppingList => 'Listeniz boş';

  @override
  String get detailedFilter => 'Detaylı Filtrele';

  @override
  String get amountRange => 'Tutar Aralığı';

  @override
  String get minAmountLabel => 'Min TL';

  @override
  String get maxAmountLabel => 'Max TL';

  @override
  String get categorySelectHint => 'Kategori Seç';

  @override
  String get clearFilters => 'Filtreleri Temizle';

  @override
  String get searchHint => 'Mağaza veya ürün ara...';

  @override
  String get expenditureCalendarTitle => 'Harcama Takvimi';

  @override
  String get startTrackingDescription =>
      'Harcamalarınızı takip etmeye başlamak için\nilk fişinizi ekleyin!';

  @override
  String get scanReceiptAction => 'Fiş Tara';

  @override
  String get manualEntryLabel => 'Manuel Giriş';

  @override
  String get scanReceiptLabel => 'Fiş Tarama';

  @override
  String get unlimitedFixedExpenses => 'Sınırsız Sabit Giderler';

  @override
  String get unlimitedManualEntry => 'Sınırsız Manuel Giriş';

  @override
  String manualEntryLimitText(Object limit) {
    return '$limit Manuel Giriş';
  }

  @override
  String get adContent => 'Reklamlı içerik';

  @override
  String get adFreeUsage => 'Reklamsız kullanım';

  @override
  String get categoryManagement => 'Kategori Yönetimi';

  @override
  String get standardCategoriesOnly => 'Sadece Standart Kategoriler';

  @override
  String get noRefund => 'Hatalı Çekim İadesi Yok';

  @override
  String get smartRefund => 'Akıllı Hatalı Çekim İadesi';

  @override
  String get currentMembership => 'Mevcut Üyeliğiniz';

  @override
  String get buyNow => 'Satın Al';

  @override
  String get specialLabel => 'ÖZEL';

  @override
  String get familyPlanDescription => 'Aile boyu fiş ve harcama takibi.';

  @override
  String get familyFeature1 => 'Tüm aile bireyleri için ortak harcama ekranı';

  @override
  String get familyFeature2 => 'Mail ile aile üyesi ekleme';

  @override
  String get familyFeature3 => 'Tüm üyeler aynı fiş geçmişini görebilir*';

  @override
  String get familyFeature4 => 'Tek fatura, ortak kontrol';

  @override
  String get membershipUpgradeTitle => 'Üyelik Yükseltme';

  @override
  String currentMembershipStatus(Object tier) {
    return 'Mevcut Üyeliğiniz: $tier';
  }

  @override
  String get tier_free_name => 'Ücretsiz';

  @override
  String get tier_standart_name => 'Standart';

  @override
  String get tier_premium_name => 'Premium';

  @override
  String get tier_limitless_family_name => 'Aile Ekonomisi';

  @override
  String get sessionEndedTitle => 'Oturum Sona Erdi';

  @override
  String get sessionEndedMessage =>
      'Güvenliğiniz için oturumunuz sonlandırıldı. Lütfen tekrar giriş yapın.';

  @override
  String get accountBlockedTitle => 'Hesabınız Engellendi';

  @override
  String get accountBlockedMessage =>
      'Hesabınız kullanım şartlarını ihlal ettiği için engellenmiştir. Destek için bizimle iletişime geçebilirsiniz.';

  @override
  String get loginLogout => 'Çıkış Yap';

  @override
  String get accountDeletionPendingTitle => 'Hesap Silme Beklemede';

  @override
  String get accountDeletionPendingMessage =>
      'Hesabınız silinmek üzere işaretlenmiştir. İşlem tamamlanana kadar giriş yapamazsınız.';

  @override
  String get customCalendar => 'Takvim';

  @override
  String get today => 'Bugün';

  @override
  String membershipCheckError(Object error) {
    return 'Üyelik kontrolünde hata: $error';
  }

  @override
  String get notificationsEnabledTitle => 'Bildirimler Aktif';

  @override
  String get notificationsEnabledBody =>
      'Günlük hatırlatıcılar başarıyla ayarlandı.';

  @override
  String daysAgo(Object days) {
    return '$days gün önce';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours saat önce';
  }

  @override
  String minutesAgo(Object minutes) {
    return '$minutes dakika önce';
  }

  @override
  String get justNow => 'Az önce';

  @override
  String get accountSection => 'Hesap';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get spendingTrendsSubtitle => 'Harcama alışkanlıklarınızı görün';

  @override
  String get achievementsSubtitle => 'Kazandığınız rozetleri görün';

  @override
  String get settingsSection => 'Ayarlar';

  @override
  String get notificationSettingsSubtitle => 'Hatırlatıcıları yönetin';

  @override
  String get securitySettings => 'Güvenlik';

  @override
  String get securitySettingsSubtitle => 'Şifre ve güvenlik ayarları';

  @override
  String get smsTrackingTitle => 'Otomatik SMS Takibi';

  @override
  String get smsTrackingDesc => 'Harcama SMS\'lerini otomatik yakala';

  @override
  String get otherSection => 'Diğer';

  @override
  String get aboutUs => 'Hakkımızda';

  @override
  String get subscriptionPageLoadError =>
      'Abonelik sayfası yüklenirken hata oluştu.';

  @override
  String get manualEntryLimitTitle => 'Manuel Giriş Limiti';

  @override
  String manualEntryLimitContent(Object limit) {
    return 'Mevcut paketinizle aylık en fazla $limit manuel giriş yapabilirsiniz.';
  }

  @override
  String manualEntryLimitError(Object error) {
    return 'Limit kontrolünde hata: $error';
  }

  @override
  String get enterValidAmount => 'Lütfen geçerli bir tutar girin.';

  @override
  String get manualExpense => 'Manuel Gider';

  @override
  String get manualExpenseSaved => 'Manuel gider başarıyla kaydedildi.';

  @override
  String manualEntryLimitStatus(Object limit, Object used) {
    return '$used / $limit manuel giriş yapıldı';
  }

  @override
  String totalReceiptsLabel(Object count) {
    return '$count Fiş';
  }

  @override
  String get createButton => 'Oluştur';

  @override
  String get pleaseWaitAnalyzing => 'Analiz ediliyor, lütfen bekleyin...';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get productsLabel => 'Ürünler';

  @override
  String get savingReceipt => 'Fiş kaydediliyor...';

  @override
  String get receiptSavedSuccess => 'Fiş başarıyla kaydedildi!';

  @override
  String get saveReceiptButton => 'Fişi Kaydet';

  @override
  String daysCount(Object count) {
    return '$count gün';
  }

  @override
  String receiptSaveFailed(Object error) {
    return 'Fiş kaydedilemedi: $error';
  }

  @override
  String get dailyReminder => 'Günlük Hatırlatıcı';

  @override
  String get waterBill => 'Su Faturası';

  @override
  String get gasBill => 'Doğalgaz Faturası';

  @override
  String get internetBill => 'İnternet Faturası';

  @override
  String get phoneBill => 'Cep Telefonu Faturası';

  @override
  String get managementFee => 'Site Aidatı';

  @override
  String get rent => 'Kira';

  @override
  String get electricityBill => 'Elektrik Faturası';

  @override
  String get propertyTax => 'Emlak Vergisi';

  @override
  String get incomeTax => 'Gelir Vergisi';

  @override
  String get vatPayment => 'KDV Ödemesi';

  @override
  String get withholdingTax => 'Muhtasar Beyanname';

  @override
  String get trafficFine => 'Trafik Cezası';

  @override
  String get socialSecurityPremium => 'SGK Primi';

  @override
  String get studentLoan => 'KYK Kredi Ödemesi';

  @override
  String get motorVehicleTax => 'MTV (Motorlu Taşıtlar Vergisi)';

  @override
  String get healthCategory => 'Sağlık';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryFood => 'Yeme-İçme';

  @override
  String get categoryGas => 'Akaryakıt';

  @override
  String get categoryClothing => 'Giyim';

  @override
  String get categoryTech => 'Teknoloji';

  @override
  String get categoryHome => 'Ev Eşyası';

  @override
  String get addFirstReceipt => 'İlk Fişini Ekle';

  @override
  String get budgetUpdated => 'Bütçe güncellendi!';

  @override
  String get accept => 'Kabul Et';

  @override
  String get thisMonthShort => '(Bu Ay)';

  @override
  String get salaryDayShort => 'Maaş Günü';

  @override
  String get mobileAppRequired => 'Mobil Uygulama Gerekli';

  @override
  String get budgetForecastTitle => 'Ay Sonu Tahmini';

  @override
  String budgetForecastMessage(Object amount) {
    return 'Mevcut hızla $amount tutarına ulaşacaksınız.';
  }

  @override
  String get onTrackMessage => 'Harika! Bütçe dostu gidiyorsun.';

  @override
  String get overBudgetMessage => 'Dikkat! Bütçeni aşabilirsin.';

  @override
  String get forecastLabel => 'Tahmini';

  @override
  String get tabReceipts => 'Fişler';

  @override
  String get tabProducts => 'Ürünler';

  @override
  String get searchProductHint => 'Ürün ara (örn. Süt)';

  @override
  String cheapestPrice(Object price) {
    return 'En Ucuz: $price TL';
  }

  @override
  String lastPrice(Object price) {
    return 'Son Fiyat: $price TL';
  }

  @override
  String seenAt(Object date) {
    return '$date tarihinde görüldü';
  }

  @override
  String get priceDropAlertTitle => 'İndirim Yakaladın!';

  @override
  String priceDropAlertBody(Object newPrice, Object oldPrice, Object product) {
    return '$product fiyatı düştü! $oldPrice₺ -> $newPrice₺';
  }

  @override
  String get priceRiseAlertTitle => 'Fiyat Artışı';

  @override
  String priceRiseAlertBody(Object newPrice, Object oldPrice, Object product) {
    return '$product fiyatı yükseldi. $oldPrice₺ -> $newPrice₺';
  }

  @override
  String get onboardingTitle1 => 'FişMatik\'e Hoş Geldiniz! 🎉';

  @override
  String get onboardingDesc1 =>
      'Fiş, fatura ve dekontlarınızı taratarak tüm harcamalarınızı saniyeler içinde kaydedin. Bütçe takibi artık çok daha akıllı!';

  @override
  String get onboardingTitle2 => 'Fiş Tarama & Abonelik Tespiti 📸';

  @override
  String get onboardingDesc2 =>
      'Fiş veya ekstrenizi taratın; yapay zeka harcamalarınızı kaydetsin, fatura ve aboneliklerinizi otomatik tespit etsin.';

  @override
  String get onboardingTitle3 => 'Akıllı Analiz & Bütçe Tahmini 🔮';

  @override
  String get onboardingDesc3 =>
      'Harcama alışkanlıklarınıza göre ay sonu harcama tahminlerini ve tasarruf ipuçlarını görün.';

  @override
  String get onboardingTitle4 => 'Nerede Daha Ucuz? 🏷️';

  @override
  String get onboardingDesc4 =>
      'Aldığınız ürünlerin fiyat geçmişini görün, hangi markette daha ucuza satıldığını keşfedin ve tasarruf edin.';

  @override
  String get onboardingTitle5 => 'Detaylı Raporlar 📊';

  @override
  String get onboardingDesc5 =>
      'Grafikler ve Excel raporları ile finansal durumunuzu tam kontrol edin.';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başlayalım!';

  @override
  String get featureDailyScans => 'Günlük Fiş Tarama';

  @override
  String get featureMonthlyManual => 'Aylık Manuel Giriş';

  @override
  String get featureUnlimitedSubscriptions => 'Sınırsız Abonelik Takibi';

  @override
  String get featureAdFree => 'Reklamsız Deneyim';

  @override
  String get featureCategoryManagement => 'Kategori Yönetimi';

  @override
  String get featureBudgetForecasting => 'Akıllı Bütçe Tahmini';

  @override
  String get featureSmartRefund => 'Akıllı Hatalı Çekim İadesi';

  @override
  String get featureExcelReports => 'Excel Raporu İndirme';

  @override
  String get featurePdfReports => 'PDF Raporu İndirme';

  @override
  String get featureTaxReports => 'Vergi Raporu';

  @override
  String get featurePriceHistory => 'Ürün Fiyat Geçmişi';

  @override
  String get featureCheapestStore => 'En Ucuz Market Önerisi';

  @override
  String get featurePriceAlerts => 'Fiyat Düşüş Bildirimleri';

  @override
  String get featureFamilySharing => 'Aile Paylaşımı (5 kişi)';

  @override
  String get featureSharedDashboard => 'Ortak Harcama Ekranı';

  @override
  String get intelligenceTitle => 'Akıllı Analiz ve İpuçları';

  @override
  String get budgetPrediction => 'Bütçe Tahmini';

  @override
  String predictedEndOfMonth(Object amount) {
    return 'Ay sonu harcama tahmini: $amount ₺';
  }

  @override
  String get budgetSafe => 'Bütçen güvende gözüküyor! ✅';

  @override
  String get budgetDanger =>
      'Daha dikkatli harcamalısın, bütçeni aşabilirsin! ⚠️';

  @override
  String get addAsSubscriptionShort => 'Ekle';

  @override
  String get potentialSubsTitle => 'Olası Abonelikler';

  @override
  String get tipsTitle => 'Tasarruf İpucu';

  @override
  String get unlockIntelligence => 'Analizleri kilidini aç';

  @override
  String get intelligenceProOnly =>
      'Akıllı tahminler ve tasarruf ipuçları Limitless üyelere özeldir.';

  @override
  String get compareFeatures => 'Özellikleri Karşılaştır';

  @override
  String scansPerDay(Object count) {
    return '$count fiş/gün';
  }

  @override
  String entriesPerMonth(Object count) {
    return '$count giriş/ay';
  }

  @override
  String get unlimited => 'Sınırsız';

  @override
  String get limited => 'Kısıtlı';

  @override
  String get notAvailable => 'Yok';

  @override
  String get clearChecked => 'İşaretli olanları temizle';

  @override
  String get clearCheckedConfirm =>
      'Alınan tüm ürünleri listeden silmek istediğinize emin misiniz?';

  @override
  String get frequentlyBought => 'Sık Aldıkların (Öneri)';

  @override
  String get notificationExactAlarmWarning => 'Tam Zamanlı Bildirimler Kapalı';

  @override
  String get notificationExactAlarmDesc =>
      'Bildirimleri saniyesi saniyesine alabilmek için lütfen ayarlardan \'Tam Zamanlı Alarm\' iznini verin.';

  @override
  String get notificationOpenSettings => 'Ayarları Aç';
}
