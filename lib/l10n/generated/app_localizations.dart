import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FişMatik'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Please fill all fields.'**
  String get loginEmptyFields;

  /// No description provided for @loginPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Passwords do not match.'**
  String get loginPasswordMismatch;

  /// No description provided for @loginAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You must accept the Privacy Policy and Terms.'**
  String get loginAgreementRequired;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmailHint;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @dailyLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the daily scan limit.'**
  String get dailyLimitExceeded;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users and limits'**
  String get adminSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @dailyReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder enabled'**
  String get dailyReminderOn;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the FişMatik family, take control of your spending.'**
  String get registerSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Privacy Policy and Terms.'**
  String get agreeTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @registrationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful! 🎉'**
  String get registrationSuccessTitle;

  /// No description provided for @registrationSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Please click the verification link sent to your email and then login.'**
  String get registrationSuccessContent;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Please fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Passwords do not match.'**
  String get passwordsMismatch;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Registration failed'**
  String get registrationFailed;

  /// No description provided for @dailyReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder disabled'**
  String get dailyReminderOff;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(Object error);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @receiptCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Receipts'**
  String receiptCount(Object count);

  /// No description provided for @totalSpending.
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get totalSpending;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit'**
  String get monthlyLimit;

  /// No description provided for @remainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining Budget'**
  String get remainingBudget;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @expenseAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Expense Analysis'**
  String get expenseAnalysis;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get categories;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'PRODUCTS'**
  String get products;

  /// No description provided for @noDataInDateRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this date range.'**
  String get noDataInDateRange;

  /// No description provided for @noProductsToShow.
  ///
  /// In en, this message translates to:
  /// **'No products to show.'**
  String get noProductsToShow;

  /// No description provided for @timesBought.
  ///
  /// In en, this message translates to:
  /// **'Bought {count} times'**
  String timesBought(Object count);

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @mostSpentCategory.
  ///
  /// In en, this message translates to:
  /// **'Most Spent Category'**
  String get mostSpentCategory;

  /// No description provided for @categoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category Distribution'**
  String get categoryDistribution;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months Expenses'**
  String get last6Months;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @foodAndDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get foodAndDrink;

  /// No description provided for @clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @scanReceiptToStart.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt to start!'**
  String get scanReceiptToStart;

  /// No description provided for @setBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Set Budget Limit'**
  String get setBudgetLimit;

  /// No description provided for @monthlyLimitAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit Amount'**
  String get monthlyLimitAmount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @scanReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the receipt'**
  String get scanReceiptTitle;

  /// No description provided for @scanFeatureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanning is currently unavailable. Please try again later.'**
  String get scanFeatureUnavailable;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get noInternet;

  /// No description provided for @subscriptionDetected.
  ///
  /// In en, this message translates to:
  /// **'Subscription Detected'**
  String get subscriptionDetected;

  /// No description provided for @subscriptionDetectedContent.
  ///
  /// In en, this message translates to:
  /// **'This expense looks like a subscription ({merchant}). Would you like to add it to your subscriptions?'**
  String subscriptionDetectedContent(Object merchant);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @subscriptionAdded.
  ///
  /// In en, this message translates to:
  /// **'Subscription added!'**
  String get subscriptionAdded;

  /// No description provided for @cameraGalleryPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera / Gallery permission required. Please enable it in settings.'**
  String get cameraGalleryPermission;

  /// No description provided for @readingText.
  ///
  /// In en, this message translates to:
  /// **'Reading text...'**
  String get readingText;

  /// No description provided for @waitingForDevice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for system dialog...'**
  String get waitingForDevice;

  /// No description provided for @longWaitWarning.
  ///
  /// In en, this message translates to:
  /// **'Please wait, dialog is opening...'**
  String get longWaitWarning;

  /// No description provided for @connectionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking connection, please do not close the page.'**
  String get connectionChecking;

  /// No description provided for @aiExtractingData.
  ///
  /// In en, this message translates to:
  /// **'AI is extracting data...'**
  String get aiExtractingData;

  /// No description provided for @processSuccess.
  ///
  /// In en, this message translates to:
  /// **'Process successful!'**
  String get processSuccess;

  /// No description provided for @dataExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Data extraction failed. The receipt might be blurry, please try again.'**
  String get dataExtractionFailed;

  /// No description provided for @monthlyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly receipt limit reached. Upgrade to Limitless for more.'**
  String get monthlyLimitReached;

  /// No description provided for @rateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'You are trying too often, please wait a couple of minutes.'**
  String get rateLimitExceeded;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get locationSettings;

  /// No description provided for @locationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update city and district information'**
  String get locationSettingsSubtitle;

  /// No description provided for @locationOnboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'To provide you with personalized local price comparisons and more accurate analysis, you must specify your location.'**
  String get locationOnboardingDescription;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. London'**
  String get cityHint;

  /// No description provided for @districtHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Westminster'**
  String get districtHint;

  /// No description provided for @cheapestInCity.
  ///
  /// In en, this message translates to:
  /// **'Cheapest in {city}'**
  String cheapestInCity(Object city);

  /// No description provided for @cheapestInCommunity.
  ///
  /// In en, this message translates to:
  /// **'Cheapest in community'**
  String get cheapestInCommunity;

  /// No description provided for @analysisError.
  ///
  /// In en, this message translates to:
  /// **'Error analyzing receipt. Please try again later.'**
  String get analysisError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please check your connection and try again.'**
  String get genericError;

  /// No description provided for @howToEnter.
  ///
  /// In en, this message translates to:
  /// **'How would you like to enter?'**
  String get howToEnter;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @addManualExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Manual Expense'**
  String get addManualExpense;

  /// No description provided for @standardMembershipAdWarning.
  ///
  /// In en, this message translates to:
  /// **'Ads are shown in Standard membership. Upgrade to Limitless for ad-free experience and higher limits.'**
  String get standardMembershipAdWarning;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String saveError(Object error);

  /// No description provided for @merchantTitle.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Description'**
  String get merchantTitle;

  /// No description provided for @merchantHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Market, Rent etc.'**
  String get merchantHint;

  /// No description provided for @amountTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountTitle;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get amountHint;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteTitle;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'A short note about the expense...'**
  String get noteHint;

  /// No description provided for @manualQuotaError.
  ///
  /// In en, this message translates to:
  /// **'Could not get quota info'**
  String get manualQuotaError;

  /// No description provided for @manualQuotaStatus.
  ///
  /// In en, this message translates to:
  /// **'Manual entry quota for this month: {used} / {limit}'**
  String manualQuotaStatus(Object limit, Object used);

  /// No description provided for @manualQuotaStatusInfinite.
  ///
  /// In en, this message translates to:
  /// **'{used} manual entries made this month (Unlimited)'**
  String manualQuotaStatusInfinite(Object used);

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportExcel;

  /// No description provided for @totalSavings.
  ///
  /// In en, this message translates to:
  /// **'Total Savings'**
  String get totalSavings;

  /// No description provided for @taxPaid.
  ///
  /// In en, this message translates to:
  /// **'Tax Paid'**
  String get taxPaid;

  /// No description provided for @taxReport.
  ///
  /// In en, this message translates to:
  /// **'Tax Report'**
  String get taxReport;

  /// No description provided for @dailyTax.
  ///
  /// In en, this message translates to:
  /// **'Daily Tax'**
  String get dailyTax;

  /// No description provided for @monthlyTax.
  ///
  /// In en, this message translates to:
  /// **'Monthly Tax'**
  String get monthlyTax;

  /// No description provided for @yearlyTax.
  ///
  /// In en, this message translates to:
  /// **'Yearly Tax'**
  String get yearlyTax;

  /// No description provided for @exportTaxReport.
  ///
  /// In en, this message translates to:
  /// **'Download Tax Report'**
  String get exportTaxReport;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @taxSection.
  ///
  /// In en, this message translates to:
  /// **'Tax Details'**
  String get taxSection;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account and start managing your receipts.'**
  String get loginSubtitle;

  /// No description provided for @familyPlan.
  ///
  /// In en, this message translates to:
  /// **'Family Plan'**
  String get familyPlan;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Will be active in the next update'**
  String get comingSoonMessage;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @setMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Monthly Budget'**
  String get setMonthlyBudget;

  /// No description provided for @newMonthMessage.
  ///
  /// In en, this message translates to:
  /// **'It\'s a new month! Please set your budget for this month.'**
  String get newMonthMessage;

  /// No description provided for @upgradeMembership.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Membership'**
  String get upgradeMembership;

  /// No description provided for @familySettings.
  ///
  /// In en, this message translates to:
  /// **'Family Settings'**
  String get familySettings;

  /// No description provided for @setSalaryDay.
  ///
  /// In en, this message translates to:
  /// **'Set Salary Day'**
  String get setSalaryDay;

  /// No description provided for @salaryDayQuestion.
  ///
  /// In en, this message translates to:
  /// **'On which day of the month do you receive your salary?'**
  String get salaryDayQuestion;

  /// No description provided for @salaryDayDescription.
  ///
  /// In en, this message translates to:
  /// **'Your spending period will be calculated based on this day.'**
  String get salaryDayDescription;

  /// No description provided for @salaryDaySetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Salary day set to {day}.'**
  String salaryDaySetSuccess(Object day);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications.'**
  String get noNewNotifications;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter Address'**
  String get enterAddress;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddress;

  /// No description provided for @familyJoinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the family.'**
  String get familyJoinedSuccess;

  /// No description provided for @fixedExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Expenses: {amount}'**
  String fixedExpensesLabel(Object amount);

  /// No description provided for @allNotificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared.'**
  String get allNotificationsCleared;

  /// No description provided for @inviteRejected.
  ///
  /// In en, this message translates to:
  /// **'Invite rejected.'**
  String get inviteRejected;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get invalidAmount;

  /// No description provided for @budgetLimitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget limit updated.'**
  String get budgetLimitUpdated;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get confirmLogoutMessage;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statsThisMonth;

  /// No description provided for @statsTotalReceipts.
  ///
  /// In en, this message translates to:
  /// **'Total Receipts'**
  String get statsTotalReceipts;

  /// No description provided for @statsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statsAverage;

  /// No description provided for @membershipTierLabel.
  ///
  /// In en, this message translates to:
  /// **'{tier} Membership'**
  String membershipTierLabel(Object tier);

  /// No description provided for @manageCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage / Cancel Subscription'**
  String get manageCancelSubscription;

  /// No description provided for @membershipStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Your membership has expired.'**
  String get membershipStatusExpired;

  /// No description provided for @membershipStatusDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String membershipStatusDaysLeft(Object days);

  /// No description provided for @membershipStatusHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours left'**
  String membershipStatusHoursLeft(Object hours);

  /// No description provided for @membershipStatusMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes left'**
  String membershipStatusMinutesLeft(Object minutes);

  /// No description provided for @membershipStatusSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get membershipStatusSoon;

  /// No description provided for @familyPlanMembersLimit.
  ///
  /// In en, this message translates to:
  /// **'35 receipts/day • 20 AI Chats • 200 Manual Entries • Family Sharing'**
  String get familyPlanMembersLimit;

  /// No description provided for @limitlessPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'25 receipts/day • 10 AI Chats • 100 Manual Entries'**
  String get limitlessPlanLimit;

  /// No description provided for @premiumPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'10 receipts/day • 50 Manual Entries'**
  String get premiumPlanLimit;

  /// No description provided for @standardPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'1 receipt/day • 20 Manual Entries'**
  String get standardPlanLimit;

  /// No description provided for @receiptLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Receipt Limit'**
  String get receiptLimitTitle;

  /// No description provided for @receiptLimitContent.
  ///
  /// In en, this message translates to:
  /// **'You have reached your membership\'s monthly receipt limit ({limit}). You can upgrade your membership for more.'**
  String receiptLimitContent(Object limit);

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded! {amount} too much'**
  String budgetExceeded(Object amount);

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String remainingLabel(Object amount);

  /// No description provided for @setBudgetLimitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set a budget limit'**
  String get setBudgetLimitPrompt;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noReceiptsYet.
  ///
  /// In en, this message translates to:
  /// **'No Receipts Yet'**
  String get noReceiptsYet;

  /// No description provided for @memberToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Tools'**
  String get memberToolsTitle;

  /// No description provided for @featureScanSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan & Detect Subscriptions'**
  String get featureScanSubTitle;

  /// No description provided for @featureScanSubDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered bill recognition and tracking'**
  String get featureScanSubDesc;

  /// No description provided for @featurePriceCompTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is it Cheaper?'**
  String get featurePriceCompTitle;

  /// No description provided for @featurePriceCompDesc.
  ///
  /// In en, this message translates to:
  /// **'Market-based price comparison'**
  String get featurePriceCompDesc;

  /// No description provided for @smartPriceTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Savings Center'**
  String get smartPriceTrackerTitle;

  /// No description provided for @smartPriceTrackerSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Track price changes and get market recommendations for your top products.'**
  String get smartPriceTrackerSubTitle;

  /// No description provided for @marketRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Best market for you: {market}'**
  String marketRecommendation(Object market);

  /// No description provided for @priceComparisonMode.
  ///
  /// In en, this message translates to:
  /// **'Price Comparison Mode'**
  String get priceComparisonMode;

  /// No description provided for @brandSpecificMode.
  ///
  /// In en, this message translates to:
  /// **'Brand-Specific'**
  String get brandSpecificMode;

  /// No description provided for @genericProductMode.
  ///
  /// In en, this message translates to:
  /// **'Generic Product'**
  String get genericProductMode;

  /// No description provided for @brandCount.
  ///
  /// In en, this message translates to:
  /// **'{count} different brands'**
  String brandCount(Object count);

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'₺{min} - ₺{max}'**
  String priceRange(Object max, Object min);

  /// No description provided for @cheapestAt.
  ///
  /// In en, this message translates to:
  /// **'Cheaper at {merchant}!'**
  String cheapestAt(Object merchant);

  /// No description provided for @viewAllBrands.
  ///
  /// In en, this message translates to:
  /// **'View All Brands'**
  String get viewAllBrands;

  /// No description provided for @switchToGeneric.
  ///
  /// In en, this message translates to:
  /// **'Switch to generic view'**
  String get switchToGeneric;

  /// No description provided for @switchToBrand.
  ///
  /// In en, this message translates to:
  /// **'Switch to brand view'**
  String get switchToBrand;

  /// No description provided for @bestPriceRecently.
  ///
  /// In en, this message translates to:
  /// **'Best price was found here recently.'**
  String get bestPriceRecently;

  /// No description provided for @noProductHistory.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for this product yet.'**
  String get noProductHistory;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @frequentProducts.
  ///
  /// In en, this message translates to:
  /// **'Frequently Bought Products'**
  String get frequentProducts;

  /// No description provided for @featurePremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'This feature is for Premium & Family members only.'**
  String get featurePremiumOnly;

  /// No description provided for @retryDetected.
  ///
  /// In en, this message translates to:
  /// **'Retry detected. Your credit has been refunded. ({count})'**
  String retryDetected(Object count);

  /// No description provided for @dailyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'{usage} / {limit} receipts scanned'**
  String dailyLimitLabel(Object limit, Object usage);

  /// No description provided for @noInternetError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get noInternetError;

  /// No description provided for @productsOptional.
  ///
  /// In en, this message translates to:
  /// **'Products (Optional)'**
  String get productsOptional;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @receiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt not found.'**
  String get receiptNotFound;

  /// No description provided for @manualEntrySource.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get manualEntrySource;

  /// No description provided for @scanReceiptSource.
  ///
  /// In en, this message translates to:
  /// **'Receipt scan'**
  String get scanReceiptSource;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalLabel;

  /// No description provided for @deleteReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Receipt'**
  String get deleteReceiptTitle;

  /// No description provided for @deleteReceiptMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this receipt?'**
  String get deleteReceiptMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @receiptDeleted.
  ///
  /// In en, this message translates to:
  /// **'Receipt deleted.'**
  String get receiptDeleted;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @noHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'When you start adding receipts, you can see your spending history here.'**
  String get noHistoryDescription;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @getReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Get Report'**
  String get getReportTooltip;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data found for this period'**
  String get noDataForPeriod;

  /// No description provided for @createReport.
  ///
  /// In en, this message translates to:
  /// **'Create Report'**
  String get createReport;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @downloadPdfAndShare.
  ///
  /// In en, this message translates to:
  /// **'Download PDF & Share'**
  String get downloadPdfAndShare;

  /// No description provided for @downloadExcelAndShare.
  ///
  /// In en, this message translates to:
  /// **'Download Excel & Share'**
  String get downloadExcelAndShare;

  /// No description provided for @preparingReport.
  ///
  /// In en, this message translates to:
  /// **'Preparing report...'**
  String get preparingReport;

  /// No description provided for @noReportData.
  ///
  /// In en, this message translates to:
  /// **'No data found for report.'**
  String get noReportData;

  /// No description provided for @categoryManagementUpgradePrompt.
  ///
  /// In en, this message translates to:
  /// **'Category management is exclusive to Standard/Pro membership.'**
  String get categoryManagementUpgradePrompt;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @monthlyBudgetLimitOptional.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Limit (Optional)'**
  String get monthlyBudgetLimitOptional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @limitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitLabel;

  /// No description provided for @monthlyBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Limit'**
  String get monthlyBudgetLimit;

  /// No description provided for @myCategories.
  ///
  /// In en, this message translates to:
  /// **'My Categories'**
  String get myCategories;

  /// No description provided for @spendingVsLimit.
  ///
  /// In en, this message translates to:
  /// **'Spending: {spending} / {limit} TL'**
  String spendingVsLimit(Object limit, Object spending);

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @spendingTrends.
  ///
  /// In en, this message translates to:
  /// **'Spending Trends'**
  String get spendingTrends;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @averageDailySpending.
  ///
  /// In en, this message translates to:
  /// **'Average Daily Spending'**
  String get averageDailySpending;

  /// No description provided for @highestSpendingDay.
  ///
  /// In en, this message translates to:
  /// **'Highest Spending Day'**
  String get highestSpendingDay;

  /// No description provided for @last12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 Months'**
  String get last12Months;

  /// No description provided for @dailySpendingChart.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending'**
  String get dailySpendingChart;

  /// No description provided for @fiveDaySpendingChart.
  ///
  /// In en, this message translates to:
  /// **'5-Day Spending'**
  String get fiveDaySpendingChart;

  /// No description provided for @monthlySpendingChart.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get monthlySpendingChart;

  /// No description provided for @fixedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Fixed Expenses'**
  String get fixedExpenses;

  /// No description provided for @editCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Credit Card'**
  String get editCreditCard;

  /// No description provided for @editCredit.
  ///
  /// In en, this message translates to:
  /// **'Edit Credit'**
  String get editCredit;

  /// No description provided for @addNewCredit.
  ///
  /// In en, this message translates to:
  /// **'Add New Credit'**
  String get addNewCredit;

  /// No description provided for @creditNameHint.
  ///
  /// In en, this message translates to:
  /// **'Credit/Card Name'**
  String get creditNameHint;

  /// No description provided for @currentTotalDebt.
  ///
  /// In en, this message translates to:
  /// **'Current Total Debt'**
  String get currentTotalDebt;

  /// No description provided for @totalCreditAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Credit Amount'**
  String get totalCreditAmount;

  /// No description provided for @minimumPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment Amount'**
  String get minimumPaymentAmount;

  /// No description provided for @monthlyInstallmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Installment Amount'**
  String get monthlyInstallmentAmount;

  /// No description provided for @totalInstallmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Installments'**
  String get totalInstallmentsLabel;

  /// No description provided for @remainingInstallmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Installments'**
  String get remainingInstallmentsLabel;

  /// No description provided for @paymentDayHint.
  ///
  /// In en, this message translates to:
  /// **'Payment Day'**
  String get paymentDayHint;

  /// No description provided for @addCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Add Credit Card'**
  String get addCreditCard;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankNameHint;

  /// No description provided for @cardLimit.
  ///
  /// In en, this message translates to:
  /// **'Card Limit'**
  String get cardLimit;

  /// No description provided for @cardLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'Your total limit'**
  String get cardLimitHelper;

  /// No description provided for @currentStatementDebt.
  ///
  /// In en, this message translates to:
  /// **'Next Statement Debt'**
  String get currentStatementDebt;

  /// No description provided for @lastPaymentDayHint.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get lastPaymentDayHint;

  /// No description provided for @minPaymentCalculated.
  ///
  /// In en, this message translates to:
  /// **'Min payment: {amount}'**
  String minPaymentCalculated(Object amount);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteCreditMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get deleteCreditMessage;

  /// No description provided for @selectExpense.
  ///
  /// In en, this message translates to:
  /// **'Select Expense'**
  String get selectExpense;

  /// No description provided for @searchExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Search expense...'**
  String get searchExpenseHint;

  /// No description provided for @addCreditInstallment.
  ///
  /// In en, this message translates to:
  /// **'Add Credit Installment'**
  String get addCreditInstallment;

  /// No description provided for @addCreditInstallmentSub.
  ///
  /// In en, this message translates to:
  /// **'Bank loans, installment purchases, etc.'**
  String get addCreditInstallmentSub;

  /// No description provided for @addCreditCardSub.
  ///
  /// In en, this message translates to:
  /// **'Automatic minimum payment calculation'**
  String get addCreditCardSub;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @addCustomSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Subscription'**
  String get addCustomSubscription;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @newFixedExpense.
  ///
  /// In en, this message translates to:
  /// **'New Fixed Expense'**
  String get newFixedExpense;

  /// No description provided for @expenseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense Name'**
  String get expenseNameLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Day (1-31)'**
  String get dayLabel;

  /// No description provided for @totalMonthlyFixedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Fixed Expenses'**
  String get totalMonthlyFixedExpenses;

  /// No description provided for @myCredits.
  ///
  /// In en, this message translates to:
  /// **'My Credits'**
  String get myCredits;

  /// No description provided for @noCreditsAdded.
  ///
  /// In en, this message translates to:
  /// **'No credits added yet.'**
  String get noCreditsAdded;

  /// No description provided for @creditCardDetail.
  ///
  /// In en, this message translates to:
  /// **'Credit Card • {day}th of month'**
  String creditCardDetail(Object day);

  /// No description provided for @creditInstallmentDetail.
  ///
  /// In en, this message translates to:
  /// **'{remaining} / {total} Installments Left • {day}th of month'**
  String creditInstallmentDetail(Object day, Object remaining, Object total);

  /// No description provided for @estimatedMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly (est.)'**
  String get estimatedMonthly;

  /// No description provided for @subscriptionsOther.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions / Other'**
  String get subscriptionsOther;

  /// No description provided for @noSubscriptionsAdded.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions added yet.'**
  String get noSubscriptionsAdded;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'{day}th of month'**
  String dayOfMonth(Object day);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'FişMatik is a smart financial assistant that helps you easily track expenses, digitize receipts by scanning, and manage your budget.'**
  String get appDescription;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2025 FişMatik. All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @notificationInstantTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Notifications'**
  String get notificationInstantTitle;

  /// No description provided for @notificationInstantDesc.
  ///
  /// In en, this message translates to:
  /// **'FişMatik instant notification channel'**
  String get notificationInstantDesc;

  /// No description provided for @notificationDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notificationDailyTitle;

  /// No description provided for @notificationDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminds you of your receipts every day'**
  String get notificationDailyDesc;

  /// No description provided for @notificationDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Heey! How\'s Your Wallet? 😉|Don\'t Let Receipts Pile Up! 🏔️|Those Papers in Your Pocket... 📄'**
  String get notificationDailyReminderTitle;

  /// No description provided for @notificationDailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Going to sleep without recording today\'s expenses? Your wallet will be sad!|Scan your receipts in two minutes, keep your budget under control. I\'m waiting!|I know they\'re all crumpled. Transfer them to FişMatik and let\'s clear them out!'**
  String get notificationDailyReminderBody;

  /// No description provided for @notificationBudgetExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Red Alert in Your Wallet! 🛑|The Boss Went Crazy! 🤪|Did You Think It\'s Bottomless? 💸'**
  String get notificationBudgetExceededTitle;

  /// No description provided for @notificationBudgetExceededBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded the budget! Put the wallet down slowly and step away...|Looks like we\'ve shaken the budget a bit (too much) this month. Should we tighten our belts?|Whoops! We crossed the limits. Take a deep breath before your next purchase.'**
  String get notificationBudgetExceededBody;

  /// No description provided for @notificationBudgetWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Careful! Wallet Is Getting Thinner 🤏|Yellow Light is On! 🟡'**
  String get notificationBudgetWarningTitle;

  /// No description provided for @notificationBudgetWarningBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve already spent {ratio}% of the budget. Should we slow down a bit?|Approaching the limits, Captain! Better tap the brakes a little.'**
  String notificationBudgetWarningBody(Object ratio);

  /// No description provided for @notificationSubscriptionReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Netflix & Chill... & Debt 🍿|{name} Is Coming! 🎶'**
  String notificationSubscriptionReminderTitle(Object name);

  /// No description provided for @notificationSubscriptionReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{name} bill is at the door again. Let\'s see how many series you finished this month?|Get your headphones ready, {name} is about to be paid for {amount}. Enjoy the rhythm!'**
  String notificationSubscriptionReminderBody(Object amount, Object name);

  /// No description provided for @notificationCategoryExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} Out of Control! 🔥'**
  String notificationCategoryExceededTitle(Object category);

  /// No description provided for @notificationCategoryExceededBody.
  ///
  /// In en, this message translates to:
  /// **'We burned through the budget for {category}. How about a little break?'**
  String notificationCategoryExceededBody(Object category);

  /// No description provided for @notificationCategoryWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} Warning! ⚠️'**
  String notificationCategoryWarningTitle(Object category);

  /// No description provided for @notificationCategoryWarningBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve swallowed {ratio}% of the {category} budget. Watch out!'**
  String notificationCategoryWarningBody(Object category, Object ratio);

  /// No description provided for @notificationSubscriptionChannel.
  ///
  /// In en, this message translates to:
  /// **'Subscription Reminder'**
  String get notificationSubscriptionChannel;

  /// No description provided for @notificationSubscriptionChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminds you of subscription payments'**
  String get notificationSubscriptionChannelDesc;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @creditInstallmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Bank loan or installments'**
  String get creditInstallmentDesc;

  /// No description provided for @addCustomExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Expense'**
  String get addCustomExpense;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @expenseWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This expense will be permanently deleted.'**
  String get expenseWillBeDeleted;

  /// No description provided for @monthlyFixedExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Expense'**
  String get monthlyFixedExpense;

  /// No description provided for @activeExpensesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Active Expenses'**
  String activeExpensesCount(Object count);

  /// No description provided for @noFixedExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No fixed expenses added yet.'**
  String get noFixedExpensesYet;

  /// No description provided for @renewsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Weekly / Day {day} of month'**
  String renewsOnDay(Object day);

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: '**
  String get lastUpdated;

  /// No description provided for @privacyPolicyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'December 19, 2025'**
  String get privacyPolicyLastUpdated;

  /// No description provided for @privacyPolicySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Data Collected'**
  String get privacyPolicySection1Title;

  /// No description provided for @privacyPolicySection1Content.
  ///
  /// In en, this message translates to:
  /// **'The FişMatik application collects data such as receipt images, expenditure items, and transaction amounts to enable you to track and manage your spending.'**
  String get privacyPolicySection1Content;

  /// No description provided for @privacyPolicySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Use of Data'**
  String get privacyPolicySection2Title;

  /// No description provided for @privacyPolicySection2Content.
  ///
  /// In en, this message translates to:
  /// **'Collected data is utilized to provide you with comprehensive budget analysis and personalized financial coaching services.'**
  String get privacyPolicySection2Content;

  /// No description provided for @privacyPolicySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Security'**
  String get privacyPolicySection3Title;

  /// No description provided for @privacyPolicySection3Content.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely using the Supabase cloud infrastructure.'**
  String get privacyPolicySection3Content;

  /// No description provided for @privacyPolicySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Sharing'**
  String get privacyPolicySection4Title;

  /// No description provided for @privacyPolicySection4Content.
  ///
  /// In en, this message translates to:
  /// **'We do not share your data with third parties for advertising or marketing purposes.'**
  String get privacyPolicySection4Content;

  /// No description provided for @privacyPolicySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacyPolicySection5Title;

  /// No description provided for @privacyPolicySection5Content.
  ///
  /// In en, this message translates to:
  /// **'You have the right to delete or export your personal data at any time through the application settings.'**
  String get privacyPolicySection5Content;

  /// No description provided for @privacyPolicySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Cookies'**
  String get privacyPolicySection6Title;

  /// No description provided for @privacyPolicySection6Content.
  ///
  /// In en, this message translates to:
  /// **'The application uses essential cookies solely for session management and security purposes.'**
  String get privacyPolicySection6Content;

  /// No description provided for @privacyPolicyFooter.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy is designed to inform FişMatik users about our data practices.'**
  String get privacyPolicyFooter;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'November 26, 2024'**
  String get termsLastUpdated;

  /// No description provided for @termsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Service Description'**
  String get termsSection1Title;

  /// No description provided for @termsSection1Content.
  ///
  /// In en, this message translates to:
  /// **'FişMatik is a mobile application that allows users to scan and digitize their shopping receipts, track their expenses, and manage their budget.'**
  String get termsSection1Content;

  /// No description provided for @termsSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Account Creation'**
  String get termsSection2Title;

  /// No description provided for @termsSection2Content.
  ///
  /// In en, this message translates to:
  /// **'• You must be over 13 years old\n• You must provide a valid email address\n• You must provide accurate and up-to-date information\n• You are responsible for the security of your password'**
  String get termsSection2Content;

  /// No description provided for @termsSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Membership Levels'**
  String get termsSection3Title;

  /// No description provided for @termsSection3Content.
  ///
  /// In en, this message translates to:
  /// **'Free (0 TL):\n• 1 receipt scan per day\n• 20 manual entries per month\n• Unlimited subscription tracking\n• Ad-supported experience\n\nStandard (49.99 TL / Month):\n• 10 receipt scans per day\n• 50 manual entries per month\n• Unlimited subscription tracking\n• Category management\n• Ad-free experience\n• Reports\n• Shopping Guide\n\nPremium (79.99 TL / Month):\n• 25 receipt scans per day\n• 100 manual entries per month\n• Unlimited subscription tracking\n• Ad-free experience\n• AI Finance Coach\n• Smart Budget Forecasting\n• Category management\n• Reports\n• Shopping Guide\n\nFamily Economy (99.99 TL / Month):\n• 35 receipt scans per day (Family total)\n• 200 manual entries per month (Family total)\n• Unlimited subscription tracking\n• Ad-free experience\n• AI Finance Coach\n• Smart Budget Forecasting\n• Category management\n• Reports\n• Shopping Guide\n• Family Sharing'**
  String get termsSection3Content;

  /// No description provided for @termsSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Rules of Use'**
  String get termsSection4Title;

  /// No description provided for @termsSection4Content.
  ///
  /// In en, this message translates to:
  /// **'Allowed:\n• Personal expense tracking\n• Receipt digitization\n• Budget management\n\nProhibited:\n• Commercial use (unauthorized)\n• Manipulating the system\n• Uploading fake receipts or data\n• Use of spam or automated bots'**
  String get termsSection4Content;

  /// No description provided for @termsSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Disclaimer'**
  String get termsSection5Title;

  /// No description provided for @termsSection5Content.
  ///
  /// In en, this message translates to:
  /// **'• You use the app at your own risk\n• We are not responsible for your financial decisions\n• We do not provide tax or accounting advice\n• OCR and AI analysis may not be 100% accurate'**
  String get termsSection5Content;

  /// No description provided for @termsSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Account Termination'**
  String get termsSection6Title;

  /// No description provided for @termsSection6Content.
  ///
  /// In en, this message translates to:
  /// **'• You can delete your account at any time\n• Your account may be suspended in case of violation of terms of use\n• Deletion is irreversible'**
  String get termsSection6Content;

  /// No description provided for @termsSection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Contact'**
  String get termsSection7Title;

  /// No description provided for @termsSection7Content.
  ///
  /// In en, this message translates to:
  /// **'For questions about the terms of use:\n\nEmail: info@kfsoftware.app'**
  String get termsSection7Content;

  /// No description provided for @termsFooter.
  ///
  /// In en, this message translates to:
  /// **'By using the FişMatik application, you declare that you have read, understood, and accepted these terms of use.'**
  String get termsFooter;

  /// No description provided for @salaryDay.
  ///
  /// In en, this message translates to:
  /// **'Salary Day'**
  String get salaryDay;

  /// No description provided for @noReceiptsFoundInRange.
  ///
  /// In en, this message translates to:
  /// **'No receipts found in this date range.'**
  String get noReceiptsFoundInRange;

  /// No description provided for @totalSpendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get totalSpendingLabel;

  /// No description provided for @noCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No category data available.'**
  String get noCategoryData;

  /// No description provided for @noTransactionInCategory.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this category.'**
  String get noTransactionInCategory;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @dailyReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me to scan receipts every day'**
  String get dailyReminderDesc;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @summaryNotifications.
  ///
  /// In en, this message translates to:
  /// **'Summary Notifications'**
  String get summaryNotifications;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @weeklySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Expense summary every Sunday evening'**
  String get weeklySummaryDesc;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @monthlySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed report at the end of the month'**
  String get monthlySummaryDesc;

  /// No description provided for @budgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get budgetAlerts;

  /// No description provided for @budgetAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications at 75%, 90%, and exceed'**
  String get budgetAlertsDesc;

  /// No description provided for @subscriptionReminders.
  ///
  /// In en, this message translates to:
  /// **'Subscription Reminders'**
  String get subscriptionReminders;

  /// No description provided for @subscriptionRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind renewal dates'**
  String get subscriptionRemindersDesc;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ Test Notification'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are working successfully!'**
  String get testNotificationBody;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied.'**
  String get notificationPermissionDenied;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded'**
  String get settingsLoadError;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved'**
  String get settingsSaveError;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleSignIn;

  /// No description provided for @unconfirmedEmailError.
  ///
  /// In en, this message translates to:
  /// **'Email address not confirmed.'**
  String get unconfirmedEmailError;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidCredentialsError;

  /// No description provided for @accountBlockedError.
  ///
  /// In en, this message translates to:
  /// **'Your account is blocked.'**
  String get accountBlockedError;

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get generalError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Login failed'**
  String get loginFailed;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @mustAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the terms.'**
  String get mustAgreeToTerms;

  /// No description provided for @verificationEmailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Email Sent'**
  String get verificationEmailSentTitle;

  /// No description provided for @verificationEmailSentBody.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address and then log in.'**
  String get verificationEmailSentBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @weakPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Weak password.'**
  String get weakPasswordError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmailError;

  /// No description provided for @googleSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get googleSignUp;

  /// No description provided for @readAndAcceptPre.
  ///
  /// In en, this message translates to:
  /// **'I have read and '**
  String get readAndAcceptPre;

  /// No description provided for @readAndAcceptAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get readAndAcceptAnd;

  /// No description provided for @readAndAcceptPost.
  ///
  /// In en, this message translates to:
  /// **' I accept.'**
  String get readAndAcceptPost;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a password reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @resetPasswordLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent.'**
  String get resetPasswordLinkSent;

  /// No description provided for @enterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get enterEmailError;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @photoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Photo could not be uploaded'**
  String get photoUploadError;

  /// No description provided for @nameOrSurnameRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to enter at least a first or last name.'**
  String get nameOrSurnameRequired;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your profile information has been updated.'**
  String get profileUpdated;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be updated'**
  String get profileUpdateError;

  /// No description provided for @fillAllPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all password fields.'**
  String get fillAllPasswordFields;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session information not found.'**
  String get sessionNotFound;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully updated!'**
  String get passwordUpdated;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The current password is not correct.'**
  String get currentPasswordIncorrect;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Password could not be updated.'**
  String get passwordUpdateFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountDataNotice.
  ///
  /// In en, this message translates to:
  /// **'All your data (receipts, categories, settings) will be permanently deleted.'**
  String get deleteAccountDataNotice;

  /// No description provided for @whyLeaving.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get whyLeaving;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectReason;

  /// No description provided for @reasonAppNotUsed.
  ///
  /// In en, this message translates to:
  /// **'I don\'t use the app anymore'**
  String get reasonAppNotUsed;

  /// No description provided for @reasonAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'I will open another account'**
  String get reasonAnotherAccount;

  /// No description provided for @reasonPrivacyConcerns.
  ///
  /// In en, this message translates to:
  /// **'I have data privacy concerns'**
  String get reasonPrivacyConcerns;

  /// No description provided for @reasonNotMeetingExpectations.
  ///
  /// In en, this message translates to:
  /// **'The application did not meet my expectations'**
  String get reasonNotMeetingExpectations;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @pleaseSpecifyReason.
  ///
  /// In en, this message translates to:
  /// **'Please specify the reason'**
  String get pleaseSpecifyReason;

  /// No description provided for @enterPasswordToDelete.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to delete your account:'**
  String get enterPasswordToDelete;

  /// No description provided for @emailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email not found'**
  String get emailNotFound;

  /// No description provided for @requestReceived.
  ///
  /// In en, this message translates to:
  /// **'Request Received'**
  String get requestReceived;

  /// No description provided for @deleteRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account deletion request has been successfully received. Your account is under review and you will not be able to log in during this process.'**
  String get deleteRequestSuccess;

  /// No description provided for @accountStats.
  ///
  /// In en, this message translates to:
  /// **'Account Statistics'**
  String get accountStats;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSinceLabel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @saveProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Save My Profile'**
  String get saveProfileButton;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password (Confirm)'**
  String get confirmNewPasswordLabel;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update My Password'**
  String get updatePasswordButton;

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can permanently delete your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data (receipts, categories, settings) will be permanently deleted.'**
  String get deleteAccountNotice;

  /// No description provided for @createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create Family'**
  String get createFamily;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Name (e.g., Smith Family)'**
  String get familyNameLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Address (Required)'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Shared living area address'**
  String get addressHint;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Entering an address is mandatory.'**
  String get addressRequired;

  /// No description provided for @familyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Family successfully created!'**
  String get familyCreatedSuccess;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMember;

  /// No description provided for @familyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Family plan limit reached (Maximum 5 people).'**
  String get familyLimitReached;

  /// No description provided for @enterEmailToInvite.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of the person you want to invite.'**
  String get enterEmailToInvite;

  /// No description provided for @inviteSending.
  ///
  /// In en, this message translates to:
  /// **'Sending invitation...'**
  String get inviteSending;

  /// No description provided for @inviteSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation successfully sent.'**
  String get inviteSentSuccess;

  /// No description provided for @leaveFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Family'**
  String get leaveFamilyTitle;

  /// No description provided for @leaveFamilyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the family? You will lose access to shared data and return to the Standard plan.'**
  String get leaveFamilyConfirm;

  /// No description provided for @leaveFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveFamilyButton;

  /// No description provided for @leftFamilySuccess.
  ///
  /// In en, this message translates to:
  /// **'You have left the family.'**
  String get leftFamilySuccess;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the member with email {email} from the family?'**
  String removeMemberConfirm(Object email);

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @memberRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed.'**
  String get memberRemovedSuccess;

  /// No description provided for @familyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Plan'**
  String get familyPlanTitle;

  /// No description provided for @noFamilyYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a family yet.'**
  String get noFamilyYet;

  /// No description provided for @familyPlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your spending together with the Family Plan, track your budget as a team.'**
  String get familyPlanDesc;

  /// No description provided for @adminLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminLabel;

  /// No description provided for @memberLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberLabel;

  /// No description provided for @familyMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembersCount;

  /// No description provided for @removeFromFamilyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from Family'**
  String get removeFromFamilyTooltip;

  /// No description provided for @ownerCannotLeaveNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: As a family admin, you cannot leave the family. To completely delete the family, please contact support.'**
  String get ownerCannotLeaveNotice;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement Badges'**
  String get badgesTitle;

  /// No description provided for @earnedBadges.
  ///
  /// In en, this message translates to:
  /// **'Earned Badges'**
  String get earnedBadges;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned!'**
  String get earned;

  /// No description provided for @oneMonthProGift.
  ///
  /// In en, this message translates to:
  /// **'1 Month Pro Gift!'**
  String get oneMonthProGift;

  /// No description provided for @earnThisBadge.
  ///
  /// In en, this message translates to:
  /// **'To earn this badge'**
  String get earnThisBadge;

  /// No description provided for @myAchievements.
  ///
  /// In en, this message translates to:
  /// **'My Achievements'**
  String get myAchievements;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Data could not be loaded'**
  String get dataLoadError;

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My Badges'**
  String get myBadges;

  /// No description provided for @dailyStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreakLabel;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// No description provided for @earnedStat.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earnedStat;

  /// No description provided for @lockedStat.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedStat;

  /// No description provided for @completionStat.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completionStat;

  /// No description provided for @notEarnedYet.
  ///
  /// In en, this message translates to:
  /// **'Not Earned Yet'**
  String get notEarnedYet;

  /// No description provided for @xpReward.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpReward(Object xp);

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level Up!'**
  String get levelUpTitle;

  /// No description provided for @levelUpBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached level {level}: {levelName}'**
  String levelUpBody(Object level, Object levelName);

  /// No description provided for @newBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Badge!'**
  String get newBadgeTitle;

  /// No description provided for @newBadgeBody.
  ///
  /// In en, this message translates to:
  /// **'You earned the {name} badge! +{xp} XP'**
  String newBadgeBody(Object name, Object xp);

  /// No description provided for @badge_first_receipt_name.
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get badge_first_receipt_name;

  /// No description provided for @badge_first_receipt_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned your first receipt!'**
  String get badge_first_receipt_desc;

  /// No description provided for @badge_first_receipt_msg.
  ///
  /// In en, this message translates to:
  /// **'🎉 Great start! Every great journey begins with a single step.'**
  String get badge_first_receipt_msg;

  /// No description provided for @badge_receipt_5_name.
  ///
  /// In en, this message translates to:
  /// **'Regular User'**
  String get badge_receipt_5_name;

  /// No description provided for @badge_receipt_5_desc.
  ///
  /// In en, this message translates to:
  /// **'You added 5 receipts.'**
  String get badge_receipt_5_desc;

  /// No description provided for @badge_receipt_5_msg.
  ///
  /// In en, this message translates to:
  /// **'💪 You\'re great! Regular tracking is the key to success.'**
  String get badge_receipt_5_msg;

  /// No description provided for @badge_receipt_10_name.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get badge_receipt_10_name;

  /// No description provided for @badge_receipt_10_desc.
  ///
  /// In en, this message translates to:
  /// **'You added 10 receipts.'**
  String get badge_receipt_10_desc;

  /// No description provided for @badge_receipt_10_msg.
  ///
  /// In en, this message translates to:
  /// **'🌟 You\'re amazing! You\'re a professional now!'**
  String get badge_receipt_10_msg;

  /// No description provided for @badge_receipt_50_name.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get badge_receipt_50_name;

  /// No description provided for @badge_receipt_50_desc.
  ///
  /// In en, this message translates to:
  /// **'You added 50 receipts.'**
  String get badge_receipt_50_desc;

  /// No description provided for @badge_receipt_50_msg.
  ///
  /// In en, this message translates to:
  /// **'🏆 You\'re a legend! Very few people reach this level.'**
  String get badge_receipt_50_msg;

  /// No description provided for @badge_saver_name.
  ///
  /// In en, this message translates to:
  /// **'Saver'**
  String get badge_saver_name;

  /// No description provided for @badge_saver_desc.
  ///
  /// In en, this message translates to:
  /// **'You recorded a total of 1000 TL in spending.'**
  String get badge_saver_desc;

  /// No description provided for @badge_saver_msg.
  ///
  /// In en, this message translates to:
  /// **'💰 Great! Tracking your spending is the first step to wealth.'**
  String get badge_saver_msg;

  /// No description provided for @badge_big_spender_name.
  ///
  /// In en, this message translates to:
  /// **'Big Spender'**
  String get badge_big_spender_name;

  /// No description provided for @badge_big_spender_desc.
  ///
  /// In en, this message translates to:
  /// **'You spent over 500 TL in one go.'**
  String get badge_big_spender_desc;

  /// No description provided for @badge_big_spender_msg.
  ///
  /// In en, this message translates to:
  /// **'💳 Big spending brings big responsibilities!'**
  String get badge_big_spender_msg;

  /// No description provided for @badge_budget_master_name.
  ///
  /// In en, this message translates to:
  /// **'Budget Master'**
  String get badge_budget_master_name;

  /// No description provided for @badge_budget_master_desc.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t exceed your budget for a full month.'**
  String get badge_budget_master_desc;

  /// No description provided for @badge_budget_master_msg.
  ///
  /// In en, this message translates to:
  /// **'🎯 Perfect! Discipline is the basis of success.'**
  String get badge_budget_master_msg;

  /// No description provided for @badge_night_owl_name.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get badge_night_owl_name;

  /// No description provided for @badge_night_owl_desc.
  ///
  /// In en, this message translates to:
  /// **'You added a receipt after midnight.'**
  String get badge_night_owl_desc;

  /// No description provided for @badge_night_owl_msg.
  ///
  /// In en, this message translates to:
  /// **'🌙 What are you doing up at night? But well done!'**
  String get badge_night_owl_msg;

  /// No description provided for @badge_early_bird_name.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get badge_early_bird_name;

  /// No description provided for @badge_early_bird_desc.
  ///
  /// In en, this message translates to:
  /// **'You added a receipt before 6 AM.'**
  String get badge_early_bird_desc;

  /// No description provided for @badge_early_bird_msg.
  ///
  /// In en, this message translates to:
  /// **'🌅 The early bird catches the worm! You\'re on your way.'**
  String get badge_early_bird_msg;

  /// No description provided for @badge_weekend_shopper_name.
  ///
  /// In en, this message translates to:
  /// **'Weekend Shopper'**
  String get badge_weekend_shopper_name;

  /// No description provided for @badge_weekend_shopper_desc.
  ///
  /// In en, this message translates to:
  /// **'You shopped on the weekend.'**
  String get badge_weekend_shopper_desc;

  /// No description provided for @badge_weekend_shopper_msg.
  ///
  /// In en, this message translates to:
  /// **'🛍️ Shopping on weekends is something else!'**
  String get badge_weekend_shopper_msg;

  /// No description provided for @badge_loyal_user_name.
  ///
  /// In en, this message translates to:
  /// **'Loyal Member'**
  String get badge_loyal_user_name;

  /// No description provided for @badge_loyal_user_desc.
  ///
  /// In en, this message translates to:
  /// **'You used the app for 30 days.'**
  String get badge_loyal_user_desc;

  /// No description provided for @badge_loyal_user_msg.
  ///
  /// In en, this message translates to:
  /// **'❤️ It\'s great to be with you! Thanks!'**
  String get badge_loyal_user_msg;

  /// No description provided for @badge_category_master_name.
  ///
  /// In en, this message translates to:
  /// **'Category Expert'**
  String get badge_category_master_name;

  /// No description provided for @badge_category_master_desc.
  ///
  /// In en, this message translates to:
  /// **'You spent in 5 different categories.'**
  String get badge_category_master_desc;

  /// No description provided for @badge_category_master_msg.
  ///
  /// In en, this message translates to:
  /// **'📊 Variety is good! You distribute your spending well.'**
  String get badge_category_master_msg;

  /// No description provided for @badge_ultimate_master_name.
  ///
  /// In en, this message translates to:
  /// **'Ultimate Master'**
  String get badge_ultimate_master_name;

  /// No description provided for @badge_ultimate_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Add 100 receipts and record 10,000 TL spending.'**
  String get badge_ultimate_master_desc;

  /// No description provided for @badge_ultimate_master_msg.
  ///
  /// In en, this message translates to:
  /// **'👑 LEGEND! You are a true master! 1 month Pro gift is yours!'**
  String get badge_ultimate_master_msg;

  /// No description provided for @badge_receipt_100_name.
  ///
  /// In en, this message translates to:
  /// **'100 Receipts'**
  String get badge_receipt_100_name;

  /// No description provided for @badge_receipt_100_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned 100 receipts!'**
  String get badge_receipt_100_desc;

  /// No description provided for @badge_receipt_500_name.
  ///
  /// In en, this message translates to:
  /// **'500 Receipts'**
  String get badge_receipt_500_name;

  /// No description provided for @badge_receipt_500_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned 500 receipts!'**
  String get badge_receipt_500_desc;

  /// No description provided for @badge_receipt_1000_name.
  ///
  /// In en, this message translates to:
  /// **'1000 Receipts'**
  String get badge_receipt_1000_name;

  /// No description provided for @badge_receipt_1000_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned 1000 receipts! Incredible!'**
  String get badge_receipt_1000_desc;

  /// No description provided for @badge_streak_7_name.
  ///
  /// In en, this message translates to:
  /// **'7 Day Streak'**
  String get badge_streak_7_name;

  /// No description provided for @badge_streak_7_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned receipts 7 days in a row!'**
  String get badge_streak_7_desc;

  /// No description provided for @badge_streak_30_name.
  ///
  /// In en, this message translates to:
  /// **'30 Day Streak'**
  String get badge_streak_30_name;

  /// No description provided for @badge_streak_30_desc.
  ///
  /// In en, this message translates to:
  /// **'You scanned receipts 30 days in a row!'**
  String get badge_streak_30_desc;

  /// No description provided for @badge_streak_365_name.
  ///
  /// In en, this message translates to:
  /// **'Yearly Champion'**
  String get badge_streak_365_name;

  /// No description provided for @badge_streak_365_desc.
  ///
  /// In en, this message translates to:
  /// **'365 days of active use!'**
  String get badge_streak_365_desc;

  /// No description provided for @badge_saver_master_name.
  ///
  /// In en, this message translates to:
  /// **'Savings Master'**
  String get badge_saver_master_name;

  /// No description provided for @badge_saver_master_desc.
  ///
  /// In en, this message translates to:
  /// **'You saved 20% of your budget!'**
  String get badge_saver_master_desc;

  /// No description provided for @badge_goal_hunter_name.
  ///
  /// In en, this message translates to:
  /// **'Goal Hunter'**
  String get badge_goal_hunter_name;

  /// No description provided for @badge_goal_hunter_desc.
  ///
  /// In en, this message translates to:
  /// **'You hit your monthly goal 3 months in a row!'**
  String get badge_goal_hunter_desc;

  /// No description provided for @badge_market_master_name.
  ///
  /// In en, this message translates to:
  /// **'Grocery Master'**
  String get badge_market_master_name;

  /// No description provided for @badge_market_master_desc.
  ///
  /// In en, this message translates to:
  /// **'50 receipts in the Grocery category!'**
  String get badge_market_master_desc;

  /// No description provided for @badge_fuel_tracker_name.
  ///
  /// In en, this message translates to:
  /// **'Fuel Tracker'**
  String get badge_fuel_tracker_name;

  /// No description provided for @badge_fuel_tracker_desc.
  ///
  /// In en, this message translates to:
  /// **'30 receipts in the Fuel category!'**
  String get badge_fuel_tracker_desc;

  /// No description provided for @badge_gourmet_name.
  ///
  /// In en, this message translates to:
  /// **'Gourmet'**
  String get badge_gourmet_name;

  /// No description provided for @badge_gourmet_desc.
  ///
  /// In en, this message translates to:
  /// **'50 receipts in the Food & Drink category!'**
  String get badge_gourmet_desc;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(Object level);

  /// No description provided for @nextLevelXp.
  ///
  /// In en, this message translates to:
  /// **'Next level: {xp} XP'**
  String nextLevelXp(Object xp);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'Maximum Level!'**
  String get maxLevel;

  /// No description provided for @level_1_name.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get level_1_name;

  /// No description provided for @level_2_name.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get level_2_name;

  /// No description provided for @level_3_name.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get level_3_name;

  /// No description provided for @level_4_name.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get level_4_name;

  /// No description provided for @level_5_name.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get level_5_name;

  /// No description provided for @level_6_name.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get level_6_name;

  /// No description provided for @level_7_name.
  ///
  /// In en, this message translates to:
  /// **'Observer'**
  String get level_7_name;

  /// No description provided for @level_8_name.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get level_8_name;

  /// No description provided for @level_9_name.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get level_9_name;

  /// No description provided for @level_10_name.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get level_10_name;

  /// No description provided for @editReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt'**
  String get editReceiptTitle;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get selectCategoryError;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get changesSaved;

  /// No description provided for @merchantLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchant Name'**
  String get merchantLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @receiptDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDateLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListTitle;

  /// No description provided for @shoppingHint.
  ///
  /// In en, this message translates to:
  /// **'What will you buy? (e.g., Milk)'**
  String get shoppingHint;

  /// No description provided for @checkingPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'Checking price history...'**
  String get checkingPriceHistory;

  /// No description provided for @lastPriceInfo.
  ///
  /// In en, this message translates to:
  /// **'You last bought it from {merchant} on {date} for {price} TL.'**
  String lastPriceInfo(Object date, Object merchant, Object price);

  /// No description provided for @emptyShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get emptyShoppingList;

  /// No description provided for @detailedFilter.
  ///
  /// In en, this message translates to:
  /// **'Detailed Filter'**
  String get detailedFilter;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount Range'**
  String get amountRange;

  /// No description provided for @minAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Min TL'**
  String get minAmountLabel;

  /// No description provided for @maxAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Max TL'**
  String get maxAmountLabel;

  /// No description provided for @categorySelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get categorySelectHint;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search store or product...'**
  String get searchHint;

  /// No description provided for @expenditureCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending Calendar'**
  String get expenditureCalendarTitle;

  /// No description provided for @startTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first receipt to start tracking your spending!'**
  String get startTrackingDescription;

  /// No description provided for @scanReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceiptAction;

  /// No description provided for @manualEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntryLabel;

  /// No description provided for @scanReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceiptLabel;

  /// No description provided for @unlimitedFixedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Fixed Expenses'**
  String get unlimitedFixedExpenses;

  /// No description provided for @unlimitedManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Manual Entry'**
  String get unlimitedManualEntry;

  /// No description provided for @manualEntryLimitText.
  ///
  /// In en, this message translates to:
  /// **'{limit} Manual Entries'**
  String manualEntryLimitText(Object limit);

  /// No description provided for @adContent.
  ///
  /// In en, this message translates to:
  /// **'Contains Ads'**
  String get adContent;

  /// No description provided for @adFreeUsage.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Usage'**
  String get adFreeUsage;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @standardCategoriesOnly.
  ///
  /// In en, this message translates to:
  /// **'Standard Categories Only'**
  String get standardCategoriesOnly;

  /// No description provided for @noRefund.
  ///
  /// In en, this message translates to:
  /// **'No Refund for Errors'**
  String get noRefund;

  /// No description provided for @smartRefund.
  ///
  /// In en, this message translates to:
  /// **'Smart Error Refund'**
  String get smartRefund;

  /// No description provided for @currentMembership.
  ///
  /// In en, this message translates to:
  /// **'Your Current Membership'**
  String get currentMembership;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @specialLabel.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL'**
  String get specialLabel;

  /// No description provided for @familyPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Family-wide receipt and spending tracking.'**
  String get familyPlanDescription;

  /// No description provided for @familyFeature1.
  ///
  /// In en, this message translates to:
  /// **'Common spending dashboard for all family members'**
  String get familyFeature1;

  /// No description provided for @familyFeature2.
  ///
  /// In en, this message translates to:
  /// **'Add family members via email'**
  String get familyFeature2;

  /// No description provided for @familyFeature3.
  ///
  /// In en, this message translates to:
  /// **'All members can view receipt history*'**
  String get familyFeature3;

  /// No description provided for @familyFeature4.
  ///
  /// In en, this message translates to:
  /// **'One bill, shared control'**
  String get familyFeature4;

  /// No description provided for @membershipUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Membership'**
  String get membershipUpgradeTitle;

  /// No description provided for @currentMembershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Membership: {tier}'**
  String currentMembershipStatus(Object tier);

  /// No description provided for @tier_free_name.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tier_free_name;

  /// No description provided for @tier_standart_name.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get tier_standart_name;

  /// No description provided for @tier_premium_name.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get tier_premium_name;

  /// No description provided for @tier_limitless_family_name.
  ///
  /// In en, this message translates to:
  /// **'Family Economy'**
  String get tier_limitless_family_name;

  /// No description provided for @sessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionEndedTitle;

  /// No description provided for @sessionEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended for security reasons. Please log in again.'**
  String get sessionEndedMessage;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Blocked'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been blocked for violating our terms. Please contact support.'**
  String get accountBlockedMessage;

  /// No description provided for @loginLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get loginLogout;

  /// No description provided for @accountDeletionPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion Pending'**
  String get accountDeletionPendingTitle;

  /// No description provided for @accountDeletionPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is marked for deletion. You cannot log in until the process is complete.'**
  String get accountDeletionPendingMessage;

  /// No description provided for @customCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get customCalendar;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @membershipCheckError.
  ///
  /// In en, this message translates to:
  /// **'Membership check error: {error}'**
  String membershipCheckError(Object error);

  /// No description provided for @notificationsEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications Active'**
  String get notificationsEnabledTitle;

  /// No description provided for @notificationsEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders successfully set.'**
  String get notificationsEnabledBody;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @spendingTrendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your spending habits'**
  String get spendingTrendsSubtitle;

  /// No description provided for @achievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your earned badges'**
  String get achievementsSubtitle;

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage reminders'**
  String get notificationSettingsSubtitle;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySettings;

  /// No description provided for @securitySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Password and security settings'**
  String get securitySettingsSubtitle;

  /// No description provided for @smsTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic SMS Tracking'**
  String get smsTrackingTitle;

  /// No description provided for @smsTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically capture expense SMS'**
  String get smsTrackingDesc;

  /// No description provided for @otherSection.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherSection;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @subscriptionPageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription page.'**
  String get subscriptionPageLoadError;

  /// No description provided for @manualEntryLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry Limit'**
  String get manualEntryLimitTitle;

  /// No description provided for @manualEntryLimitContent.
  ///
  /// In en, this message translates to:
  /// **'With your current plan, you can make a maximum of {limit} manual entries per month.'**
  String manualEntryLimitContent(Object limit);

  /// No description provided for @manualEntryLimitError.
  ///
  /// In en, this message translates to:
  /// **'Error checking limit: {error}'**
  String manualEntryLimitError(Object error);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @manualExpense.
  ///
  /// In en, this message translates to:
  /// **'Manual Expense'**
  String get manualExpense;

  /// No description provided for @manualExpenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Manual expense saved successfully.'**
  String get manualExpenseSaved;

  /// No description provided for @manualEntryLimitStatus.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} manual entries made'**
  String manualEntryLimitStatus(Object limit, Object used);

  /// No description provided for @totalReceiptsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Receipts'**
  String totalReceiptsLabel(Object count);

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @pleaseWaitAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing, please wait...'**
  String get pleaseWaitAnalyzing;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsLabel;

  /// No description provided for @savingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Saving receipt...'**
  String get savingReceipt;

  /// No description provided for @receiptSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved successfully!'**
  String get receiptSavedSuccess;

  /// No description provided for @saveReceiptButton.
  ///
  /// In en, this message translates to:
  /// **'Save Receipt'**
  String get saveReceiptButton;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(Object count);

  /// No description provided for @receiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save receipt: {error}'**
  String receiptSaveFailed(Object error);

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @waterBill.
  ///
  /// In en, this message translates to:
  /// **'Water Bill'**
  String get waterBill;

  /// No description provided for @gasBill.
  ///
  /// In en, this message translates to:
  /// **'Natural Gas Bill'**
  String get gasBill;

  /// No description provided for @internetBill.
  ///
  /// In en, this message translates to:
  /// **'Internet Bill'**
  String get internetBill;

  /// No description provided for @phoneBill.
  ///
  /// In en, this message translates to:
  /// **'Phone Bill'**
  String get phoneBill;

  /// No description provided for @managementFee.
  ///
  /// In en, this message translates to:
  /// **'Management Fee'**
  String get managementFee;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @electricityBill.
  ///
  /// In en, this message translates to:
  /// **'Electricity Bill'**
  String get electricityBill;

  /// No description provided for @propertyTax.
  ///
  /// In en, this message translates to:
  /// **'Property Tax'**
  String get propertyTax;

  /// No description provided for @incomeTax.
  ///
  /// In en, this message translates to:
  /// **'Income Tax'**
  String get incomeTax;

  /// No description provided for @vatPayment.
  ///
  /// In en, this message translates to:
  /// **'VAT Payment'**
  String get vatPayment;

  /// No description provided for @withholdingTax.
  ///
  /// In en, this message translates to:
  /// **'Withholding Tax'**
  String get withholdingTax;

  /// No description provided for @trafficFine.
  ///
  /// In en, this message translates to:
  /// **'Traffic Fine'**
  String get trafficFine;

  /// No description provided for @socialSecurityPremium.
  ///
  /// In en, this message translates to:
  /// **'Social Security (SGK) Premium'**
  String get socialSecurityPremium;

  /// No description provided for @studentLoan.
  ///
  /// In en, this message translates to:
  /// **'Student Loan (KYK)'**
  String get studentLoan;

  /// No description provided for @motorVehicleTax.
  ///
  /// In en, this message translates to:
  /// **'Motor Vehicle Tax (MTV)'**
  String get motorVehicleTax;

  /// No description provided for @healthCategory.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthCategory;

  /// No description provided for @categoryMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get categoryMarket;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get categoryFood;

  /// No description provided for @categoryGas.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryGas;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// No description provided for @categoryTech.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get categoryTech;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home Goods'**
  String get categoryHome;

  /// No description provided for @addFirstReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Receipt'**
  String get addFirstReceipt;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated!'**
  String get budgetUpdated;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @thisMonthShort.
  ///
  /// In en, this message translates to:
  /// **'(This Month)'**
  String get thisMonthShort;

  /// No description provided for @salaryDayShort.
  ///
  /// In en, this message translates to:
  /// **'Salary Day'**
  String get salaryDayShort;

  /// No description provided for @mobileAppRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile App Required'**
  String get mobileAppRequired;

  /// No description provided for @budgetForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Month-End Forecast'**
  String get budgetForecastTitle;

  /// No description provided for @budgetForecastMessage.
  ///
  /// In en, this message translates to:
  /// **'At this rate, you\'ll reach {amount}.'**
  String budgetForecastMessage(Object amount);

  /// No description provided for @onTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'Great! You are on track.'**
  String get onTrackMessage;

  /// No description provided for @overBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Warning! You might overspend.'**
  String get overBudgetMessage;

  /// No description provided for @forecastLabel.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecastLabel;

  /// No description provided for @tabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get tabReceipts;

  /// No description provided for @tabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tabProducts;

  /// No description provided for @searchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search product (e.g. Milk)'**
  String get searchProductHint;

  /// No description provided for @cheapestPrice.
  ///
  /// In en, this message translates to:
  /// **'Cheapest: {price} TL'**
  String cheapestPrice(Object price);

  /// No description provided for @lastPrice.
  ///
  /// In en, this message translates to:
  /// **'Last Price: {price} TL'**
  String lastPrice(Object price);

  /// No description provided for @seenAt.
  ///
  /// In en, this message translates to:
  /// **'Seen on {date}'**
  String seenAt(Object date);

  /// No description provided for @priceDropAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Drop Detected!'**
  String get priceDropAlertTitle;

  /// No description provided for @priceDropAlertBody.
  ///
  /// In en, this message translates to:
  /// **'{product} is cheaper now! {oldPrice}₺ -> {newPrice}₺'**
  String priceDropAlertBody(Object newPrice, Object oldPrice, Object product);

  /// No description provided for @priceRiseAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Hike Alert'**
  String get priceRiseAlertTitle;

  /// No description provided for @priceRiseAlertBody.
  ///
  /// In en, this message translates to:
  /// **'{product} price increased. {oldPrice}₺ -> {newPrice}₺'**
  String priceRiseAlertBody(Object newPrice, Object oldPrice, Object product);

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FişMatik! 🎉'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Scan your receipts, invoices, and slips to record all your expenses in seconds. Budget tracking is now much smarter!'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanning & Subscription Detection 📸'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Scan your receipt or statement; let AI record your expenses and automatically detect your bills and subscriptions.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Smart Analysis & Budget Forecast 🔮'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'See end-of-month spending forecasts and savings tips based on your spending habits, warning you in advance.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Where Is It Cheaper? 🏷️'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'View the price history of products you buy, discover which store sells them cheaper, and save money.'**
  String get onboardingDesc4;

  /// No description provided for @onboardingTitle5.
  ///
  /// In en, this message translates to:
  /// **'Detailed Reports 📊'**
  String get onboardingTitle5;

  /// No description provided for @onboardingDesc5.
  ///
  /// In en, this message translates to:
  /// **'Take full control of your financial situation with charts and Excel reports.'**
  String get onboardingDesc5;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start!'**
  String get onboardingStart;

  /// No description provided for @featureDailyScans.
  ///
  /// In en, this message translates to:
  /// **'Daily Receipt Scans'**
  String get featureDailyScans;

  /// No description provided for @featureMonthlyManual.
  ///
  /// In en, this message translates to:
  /// **'Monthly Manual Entries'**
  String get featureMonthlyManual;

  /// No description provided for @featureUnlimitedSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Subscription Tracking'**
  String get featureUnlimitedSubscriptions;

  /// No description provided for @featureAdFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get featureAdFree;

  /// No description provided for @featureCategoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get featureCategoryManagement;

  /// No description provided for @featureBudgetForecasting.
  ///
  /// In en, this message translates to:
  /// **'Smart Budget Forecasting'**
  String get featureBudgetForecasting;

  /// No description provided for @featureSmartRefund.
  ///
  /// In en, this message translates to:
  /// **'Smart Error Refund'**
  String get featureSmartRefund;

  /// No description provided for @featureExcelReports.
  ///
  /// In en, this message translates to:
  /// **'Excel Report Download'**
  String get featureExcelReports;

  /// No description provided for @featurePdfReports.
  ///
  /// In en, this message translates to:
  /// **'PDF Report Download'**
  String get featurePdfReports;

  /// No description provided for @featureTaxReports.
  ///
  /// In en, this message translates to:
  /// **'Tax Report'**
  String get featureTaxReports;

  /// No description provided for @featurePriceHistory.
  ///
  /// In en, this message translates to:
  /// **'Product Price History'**
  String get featurePriceHistory;

  /// No description provided for @featureCheapestStore.
  ///
  /// In en, this message translates to:
  /// **'Cheapest Store Suggestion'**
  String get featureCheapestStore;

  /// No description provided for @featurePriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price Drop Alerts'**
  String get featurePriceAlerts;

  /// No description provided for @featureFamilySharing.
  ///
  /// In en, this message translates to:
  /// **'Family Sharing (5 members)'**
  String get featureFamilySharing;

  /// No description provided for @featureSharedDashboard.
  ///
  /// In en, this message translates to:
  /// **'Shared Expense Dashboard'**
  String get featureSharedDashboard;

  /// No description provided for @intelligenceTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Insights & Alerts'**
  String get intelligenceTitle;

  /// No description provided for @budgetPrediction.
  ///
  /// In en, this message translates to:
  /// **'Budget Forecasting'**
  String get budgetPrediction;

  /// No description provided for @predictedEndOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Predicted spending by month end: {amount} ₺'**
  String predictedEndOfMonth(Object amount);

  /// No description provided for @budgetSafe.
  ///
  /// In en, this message translates to:
  /// **'Your budget looks safe! ✅'**
  String get budgetSafe;

  /// No description provided for @budgetDanger.
  ///
  /// In en, this message translates to:
  /// **'Spending fast! You might exceed your budget. ⚠️'**
  String get budgetDanger;

  /// No description provided for @addAsSubscriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAsSubscriptionShort;

  /// No description provided for @potentialSubsTitle.
  ///
  /// In en, this message translates to:
  /// **'Potential Subscriptions'**
  String get potentialSubsTitle;

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving Tip'**
  String get tipsTitle;

  /// No description provided for @unlockIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Unlock Insights'**
  String get unlockIntelligence;

  /// No description provided for @intelligenceProOnly.
  ///
  /// In en, this message translates to:
  /// **'Smart forecasting and saving tips are for Limitless members only.'**
  String get intelligenceProOnly;

  /// No description provided for @compareFeatures.
  ///
  /// In en, this message translates to:
  /// **'Compare Features'**
  String get compareFeatures;

  /// No description provided for @scansPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count} scans/day'**
  String scansPerDay(Object count);

  /// No description provided for @entriesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} entries/month'**
  String entriesPerMonth(Object count);

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get limited;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @clearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear Checked Items'**
  String get clearChecked;

  /// No description provided for @clearCheckedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all checked items from the list?'**
  String get clearCheckedConfirm;

  /// No description provided for @frequentlyBought.
  ///
  /// In en, this message translates to:
  /// **'Frequently Bought (Suggestions)'**
  String get frequentlyBought;

  /// No description provided for @notificationExactAlarmWarning.
  ///
  /// In en, this message translates to:
  /// **'Exact Notifications Disabled'**
  String get notificationExactAlarmWarning;

  /// No description provided for @notificationExactAlarmDesc.
  ///
  /// In en, this message translates to:
  /// **'To receive notifications on time, please enable \'Exact Alarm\' permission in settings.'**
  String get notificationExactAlarmDesc;

  /// No description provided for @notificationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationOpenSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
