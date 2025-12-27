// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FişMatik';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginEmailHint => 'Email';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get loginEmptyFields => '⚠️ Please fill all fields.';

  @override
  String get loginPasswordMismatch => '⚠️ Passwords do not match.';

  @override
  String get loginAgreementRequired =>
      '⚠️ You must accept the Privacy Policy and Terms.';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerEmailHint => 'Email';

  @override
  String get registerPasswordHint => 'Password';

  @override
  String get registerConfirmPasswordHint => 'Confirm Password';

  @override
  String get registerButton => 'Register';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLanguage => 'Language';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get dailyLimitExceeded => 'You have exceeded the daily scan limit.';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminSubtitle => 'Manage users and limits';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get dailyReminderOn => 'Daily reminder enabled';

  @override
  String get registerSubtitle =>
      'Join the FişMatik family, take control of your spending.';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get agreeTerms => 'You must accept the Privacy Policy and Terms.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get registrationSuccessTitle => 'Registration Successful! 🎉';

  @override
  String get registrationSuccessContent =>
      'Please click the verification link sent to your email and then login.';

  @override
  String get okButton => 'OK';

  @override
  String get fillAllFields => '⚠️ Please fill in all fields.';

  @override
  String get passwordsMismatch => '⚠️ Passwords do not match.';

  @override
  String get registrationFailed => '❌ Registration failed';

  @override
  String get dailyReminderOff => 'Daily reminder disabled';

  @override
  String errorOccurred(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String get noData => 'No Data';

  @override
  String get loading => 'Loading...';

  @override
  String get scanReceipt => 'Scan Receipt';

  @override
  String get analysis => 'Analysis';

  @override
  String get summary => 'Summary';

  @override
  String get calendar => 'Calendar';

  @override
  String get expenses => 'Expenses';

  @override
  String receiptCount(Object count) {
    return '$count Receipts';
  }

  @override
  String get totalSpending => 'Total Spending';

  @override
  String get monthlyLimit => 'Monthly Limit';

  @override
  String get remainingBudget => 'Remaining Budget';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get all => 'All';

  @override
  String get expenseAnalysis => 'Expense Analysis';

  @override
  String get categories => 'CATEGORIES';

  @override
  String get products => 'PRODUCTS';

  @override
  String get noDataInDateRange => 'No data in this date range.';

  @override
  String get noProductsToShow => 'No products to show.';

  @override
  String timesBought(Object count) {
    return 'Bought $count times';
  }

  @override
  String get statistics => 'Statistics';

  @override
  String get mostSpentCategory => 'Most Spent Category';

  @override
  String get categoryDistribution => 'Category Distribution';

  @override
  String get last6Months => 'Last 6 Months Expenses';

  @override
  String get market => 'Market';

  @override
  String get fuel => 'Fuel';

  @override
  String get foodAndDrink => 'Food & Drink';

  @override
  String get clothing => 'Clothing';

  @override
  String get technology => 'Technology';

  @override
  String get other => 'Other';

  @override
  String get scanReceiptToStart => 'Scan receipt to start!';

  @override
  String get setBudgetLimit => 'Set Budget Limit';

  @override
  String get monthlyLimitAmount => 'Monthly Limit Amount';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get scanReceiptTitle => 'Take a photo of the receipt';

  @override
  String get scanFeatureUnavailable =>
      'Receipt scanning is currently unavailable. Please try again later.';

  @override
  String get noInternet => 'No internet connection. Please check your network.';

  @override
  String get subscriptionDetected => 'Subscription Detected';

  @override
  String subscriptionDetectedContent(Object merchant) {
    return 'This expense looks like a subscription ($merchant). Would you like to add it to your subscriptions?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get subscriptionAdded => 'Subscription added!';

  @override
  String get cameraGalleryPermission =>
      'Camera / Gallery permission required. Please enable it in settings.';

  @override
  String get goToSettings => 'Settings';

  @override
  String get readingText => 'Reading text...';

  @override
  String get waitingForDevice => 'Waiting for system dialog...';

  @override
  String get longWaitWarning => 'Please wait, dialog is opening...';

  @override
  String get connectionChecking =>
      'Checking connection, please do not close the page.';

  @override
  String get aiExtractingData => 'AI is extracting data...';

  @override
  String get processSuccess => 'Process successful!';

  @override
  String get dataExtractionFailed =>
      'Data extraction failed. The receipt might be blurry, please try again.';

  @override
  String get monthlyLimitReached =>
      'Monthly receipt limit reached. Upgrade to Limitless for more.';

  @override
  String get rateLimitExceeded =>
      'You are trying too often, please wait a couple of minutes.';

  @override
  String get networkError =>
      'Connection error. Please check your internet connection.';

  @override
  String get locationSettings => 'Location Settings';

  @override
  String get locationSettingsSubtitle => 'Update city and district information';

  @override
  String get locationOnboardingDescription =>
      'To provide you with personalized local price comparisons and more accurate analysis, you must specify your location.';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String get cityHint => 'e.g. London';

  @override
  String get districtHint => 'e.g. Westminster';

  @override
  String cheapestInCity(Object city) {
    return 'Cheapest in $city';
  }

  @override
  String get cheapestInCommunity => 'Cheapest in community';

  @override
  String get analysisError =>
      'Error analyzing receipt. Please try again later.';

  @override
  String get detectLocation => 'Auto Detect Location';

  @override
  String get detecting => 'Detecting...';

  @override
  String locationDetected(Object city, Object district) {
    return 'Location detected: $city, $district';
  }

  @override
  String get locationError =>
      'Could not detect location. Please check permissions.';

  @override
  String get genericError =>
      'Something went wrong. Please check your connection and try again.';

  @override
  String get howToEnter => 'How would you like to enter?';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get addManualExpense => 'Add Manual Expense';

  @override
  String get standardMembershipAdWarning =>
      'Ads are shown in Standard membership. Upgrade to Limitless for ad-free experience and higher limits.';

  @override
  String saveError(Object error) {
    return 'Save error: $error';
  }

  @override
  String get merchantTitle => 'Merchant / Description';

  @override
  String get merchantHint => 'e.g. Market, Rent etc.';

  @override
  String get amountTitle => 'Amount';

  @override
  String get amountHint => '0.00';

  @override
  String get date => 'Date';

  @override
  String get category => 'Category';

  @override
  String get noteTitle => 'Note';

  @override
  String get noteHint => 'A short note about the expense...';

  @override
  String get manualQuotaError => 'Could not get quota info';

  @override
  String manualQuotaStatus(Object limit, Object used) {
    return 'Manual entry quota for this month: $used / $limit';
  }

  @override
  String manualQuotaStatusInfinite(Object used) {
    return '$used manual entries made this month (Unlimited)';
  }

  @override
  String get exportExcel => 'Export to Excel';

  @override
  String get totalSavings => 'Total Savings';

  @override
  String get taxPaid => 'Tax Paid';

  @override
  String get taxReport => 'Tax Report';

  @override
  String get dailyTax => 'Daily Tax';

  @override
  String get monthlyTax => 'Monthly Tax';

  @override
  String get yearlyTax => 'Yearly Tax';

  @override
  String get exportTaxReport => 'Download Tax Report';

  @override
  String get daily => 'Daily';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get custom => 'Custom';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get taxSection => 'Tax Details';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get loginSubtitle =>
      'Login to your account and start managing your receipts.';

  @override
  String get familyPlan => 'Family Plan';

  @override
  String get comingSoonMessage => 'Will be active in the next update';

  @override
  String get history => 'History';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get setMonthlyBudget => 'Set Monthly Budget';

  @override
  String get newMonthMessage =>
      'It\'s a new month! Please set your budget for this month.';

  @override
  String get upgradeMembership => 'Upgrade Membership';

  @override
  String get familySettings => 'Family Settings';

  @override
  String get setSalaryDay => 'Set Salary Day';

  @override
  String get salaryDayQuestion =>
      'On which day of the month do you receive your salary?';

  @override
  String get salaryDayDescription =>
      'Your spending period will be calculated based on this day.';

  @override
  String salaryDaySetSuccess(Object day) {
    return 'Salary day set to $day.';
  }

  @override
  String get clearAll => 'Clear All';

  @override
  String get noNewNotifications => 'No new notifications.';

  @override
  String get notificationDefaultTitle => 'Notification';

  @override
  String get reject => 'Reject';

  @override
  String get enterAddress => 'Enter Address';

  @override
  String get homeAddress => 'Home Address';

  @override
  String get familyJoinedSuccess => 'Successfully joined the family.';

  @override
  String fixedExpensesLabel(Object amount) {
    return 'Fixed Expenses: $amount';
  }

  @override
  String get allNotificationsCleared => 'All notifications cleared.';

  @override
  String get inviteRejected => 'Invite rejected.';

  @override
  String get invalidAmount => 'Invalid amount.';

  @override
  String get budgetLimitUpdated => 'Budget limit updated.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get confirmLogoutTitle => 'Log Out';

  @override
  String get confirmLogoutMessage =>
      'Are you sure you want to log out of your account?';

  @override
  String get statsThisMonth => 'This Month';

  @override
  String get statsTotalReceipts => 'Total Receipts';

  @override
  String get statsAverage => 'Average';

  @override
  String membershipTierLabel(Object tier) {
    return '$tier Membership';
  }

  @override
  String get manageCancelSubscription => 'Manage / Cancel Subscription';

  @override
  String get membershipStatusExpired => 'Your membership has expired.';

  @override
  String membershipStatusDaysLeft(Object days) {
    return '$days days left';
  }

  @override
  String membershipStatusHoursLeft(Object hours) {
    return '$hours hours left';
  }

  @override
  String membershipStatusMinutesLeft(Object minutes) {
    return '$minutes minutes left';
  }

  @override
  String get membershipStatusSoon => 'Coming soon';

  @override
  String get familyPlanMembersLimit =>
      '35 receipts/day • 20 AI Chats • 200 Manual Entries • Family Sharing';

  @override
  String get limitlessPlanLimit =>
      '25 receipts/day • 10 AI Chats • 100 Manual Entries';

  @override
  String get premiumPlanLimit => '10 receipts/day • 50 Manual Entries';

  @override
  String get standardPlanLimit => '1 receipt/day • 20 Manual Entries';

  @override
  String get receiptLimitTitle => 'Monthly Receipt Limit';

  @override
  String receiptLimitContent(Object limit) {
    return 'You have reached your membership\'s monthly receipt limit ($limit). You can upgrade your membership for more.';
  }

  @override
  String budgetExceeded(Object amount) {
    return 'Budget exceeded! $amount too much';
  }

  @override
  String remainingLabel(Object amount) {
    return 'Remaining: $amount';
  }

  @override
  String get setBudgetLimitPrompt => 'Set a budget limit';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get seeAll => 'See All';

  @override
  String get noReceiptsYet => 'No Receipts Yet';

  @override
  String get memberToolsTitle => 'Member Tools';

  @override
  String get featureScanSubTitle => 'Scan & Detect Subscriptions';

  @override
  String get featureScanSubDesc => 'AI-powered bill recognition and tracking';

  @override
  String get featurePriceCompTitle => 'Where is it Cheaper?';

  @override
  String get featurePriceCompDesc => 'Market-based price comparison';

  @override
  String get smartPriceTrackerTitle => 'Smart Savings Center';

  @override
  String get smartPriceTrackerSubTitle =>
      'Track price changes and get market recommendations for your top products.';

  @override
  String marketRecommendation(Object market) {
    return 'Best market for you: $market';
  }

  @override
  String get priceComparisonMode => 'Price Comparison Mode';

  @override
  String get brandSpecificMode => 'Brand-Specific';

  @override
  String get genericProductMode => 'Generic Product';

  @override
  String brandCount(Object count) {
    return '$count different brands';
  }

  @override
  String priceRange(Object max, Object min) {
    return '₺$min - ₺$max';
  }

  @override
  String cheapestAt(Object merchant) {
    return 'Cheaper at $merchant!';
  }

  @override
  String get viewAllBrands => 'View All Brands';

  @override
  String get switchToGeneric => 'Switch to generic view';

  @override
  String get switchToBrand => 'Switch to brand view';

  @override
  String get bestPriceRecently => 'Best price was found here recently.';

  @override
  String get noProductHistory => 'Not enough data for this product yet.';

  @override
  String get viewHistory => 'View History';

  @override
  String get frequentProducts => 'Frequently Bought Products';

  @override
  String get featurePremiumOnly =>
      'This feature is for Premium & Family members only.';

  @override
  String retryDetected(Object count) {
    return 'Retry detected. Your credit has been refunded. ($count)';
  }

  @override
  String dailyLimitLabel(Object limit, Object usage) {
    return '$usage / $limit receipts scanned';
  }

  @override
  String get noInternetError => 'No internet connection.';

  @override
  String get productsOptional => 'Products (Optional)';

  @override
  String get productName => 'Product Name';

  @override
  String get addProduct => 'Add Product';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get receiptNotFound => 'Receipt not found.';

  @override
  String get manualEntrySource => 'Manual entry';

  @override
  String get scanReceiptSource => 'Receipt scan';

  @override
  String get totalLabel => 'TOTAL';

  @override
  String get deleteReceiptTitle => 'Delete Receipt';

  @override
  String get deleteReceiptMessage =>
      'Are you sure you want to permanently delete this receipt?';

  @override
  String get delete => 'Delete';

  @override
  String get receiptDeleted => 'Receipt deleted.';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get noHistoryDescription =>
      'When you start adding receipts, you can see your spending history here.';

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get getReportTooltip => 'Get Report';

  @override
  String get noDataForPeriod => 'No data found for this period';

  @override
  String get createReport => 'Create Report';

  @override
  String get reports => 'Reports';

  @override
  String get downloadPdfAndShare => 'Download PDF & Share';

  @override
  String get downloadExcelAndShare => 'Download Excel & Share';

  @override
  String get preparingReport => 'Preparing report...';

  @override
  String get noReportData => 'No data found for report.';

  @override
  String get categoryManagementUpgradePrompt =>
      'Category management is exclusive to Standard/Pro membership.';

  @override
  String get newCategory => 'New Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get monthlyBudgetLimitOptional => 'Monthly Budget Limit (Optional)';

  @override
  String get add => 'Add';

  @override
  String get limitLabel => 'Limit';

  @override
  String get monthlyBudgetLimit => 'Monthly Budget Limit';

  @override
  String get myCategories => 'My Categories';

  @override
  String spendingVsLimit(Object limit, Object spending) {
    return 'Spending: $spending / $limit TL';
  }

  @override
  String get noLimit => 'No limit';

  @override
  String get spendingTrends => 'Spending Trends';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get averageDailySpending => 'Average Daily Spending';

  @override
  String get highestSpendingDay => 'Highest Spending Day';

  @override
  String get last12Months => 'Last 12 Months';

  @override
  String get dailySpendingChart => 'Daily Spending';

  @override
  String get fiveDaySpendingChart => '5-Day Spending';

  @override
  String get monthlySpendingChart => 'Monthly Spending';

  @override
  String get fixedExpenses => 'Fixed Expenses';

  @override
  String get editCreditCard => 'Edit Credit Card';

  @override
  String get editCredit => 'Edit Credit';

  @override
  String get addNewCredit => 'Add New Credit';

  @override
  String get creditNameHint => 'Credit/Card Name';

  @override
  String get currentTotalDebt => 'Current Total Debt';

  @override
  String get totalCreditAmount => 'Total Credit Amount';

  @override
  String get minimumPaymentAmount => 'Minimum Payment Amount';

  @override
  String get monthlyInstallmentAmount => 'Monthly Installment Amount';

  @override
  String get totalInstallmentsLabel => 'Total Installments';

  @override
  String get remainingInstallmentsLabel => 'Remaining Installments';

  @override
  String get paymentDayHint => 'Payment Day';

  @override
  String get addCreditCard => 'Add Credit Card';

  @override
  String get bankNameHint => 'Bank Name';

  @override
  String get cardLimit => 'Card Limit';

  @override
  String get cardLimitHelper => 'Your total limit';

  @override
  String get currentStatementDebt => 'Next Statement Debt';

  @override
  String get lastPaymentDayHint => 'Due Date';

  @override
  String minPaymentCalculated(Object amount) {
    return 'Min payment: $amount';
  }

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteCreditMessage =>
      'Are you sure you want to delete this record?';

  @override
  String get selectExpense => 'Select Expense';

  @override
  String get searchExpenseHint => 'Search expense...';

  @override
  String get addCreditInstallment => 'Add Credit Installment';

  @override
  String get addCreditInstallmentSub =>
      'Bank loans, installment purchases, etc.';

  @override
  String get addCreditCardSub => 'Automatic minimum payment calculation';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get addCustomSubscription => 'Add Custom Subscription';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get newFixedExpense => 'New Fixed Expense';

  @override
  String get expenseNameLabel => 'Expense Name';

  @override
  String get amountLabel => 'Amount';

  @override
  String get dayLabel => 'Payment Day (1-31)';

  @override
  String get totalMonthlyFixedExpenses => 'Total Monthly Fixed Expenses';

  @override
  String get myCredits => 'My Credits';

  @override
  String get noCreditsAdded => 'No credits added yet.';

  @override
  String creditCardDetail(Object day) {
    return 'Credit Card • ${day}th of month';
  }

  @override
  String creditInstallmentDetail(Object day, Object remaining, Object total) {
    return '$remaining / $total Installments Left • ${day}th of month';
  }

  @override
  String get estimatedMonthly => 'Monthly (est.)';

  @override
  String get subscriptionsOther => 'Subscriptions / Other';

  @override
  String get noSubscriptionsAdded => 'No subscriptions added yet.';

  @override
  String dayOfMonth(Object day) {
    return '${day}th of month';
  }

  @override
  String get about => 'About';

  @override
  String get appDescription =>
      'FişMatik is a smart financial assistant that helps you easily track expenses, digitize receipts by scanning, and manage your budget.';

  @override
  String get website => 'Website';

  @override
  String get contact => 'Contact';

  @override
  String get allRightsReserved => '© 2025 FişMatik. All rights reserved.';

  @override
  String get notificationInstantTitle => 'Instant Notifications';

  @override
  String get notificationInstantDesc => 'FişMatik instant notification channel';

  @override
  String get notificationDailyTitle => 'Daily Reminder';

  @override
  String get notificationDailyDesc => 'Reminds you of your receipts every day';

  @override
  String get notificationDailyReminderTitle =>
      'Heey! How\'s Your Wallet? 😉|Don\'t Let Receipts Pile Up! 🏔️|Those Papers in Your Pocket... 📄';

  @override
  String get notificationDailyReminderBody =>
      'Going to sleep without recording today\'s expenses? Your wallet will be sad!|Scan your receipts in two minutes, keep your budget under control. I\'m waiting!|I know they\'re all crumpled. Transfer them to FişMatik and let\'s clear them out!';

  @override
  String get notificationBudgetExceededTitle =>
      'Red Alert in Your Wallet! 🛑|The Boss Went Crazy! 🤪|Did You Think It\'s Bottomless? 💸';

  @override
  String get notificationBudgetExceededBody =>
      'You\'ve exceeded the budget! Put the wallet down slowly and step away...|Looks like we\'ve shaken the budget a bit (too much) this month. Should we tighten our belts?|Whoops! We crossed the limits. Take a deep breath before your next purchase.';

  @override
  String get notificationBudgetWarningTitle =>
      'Careful! Wallet Is Getting Thinner 🤏|Yellow Light is On! 🟡';

  @override
  String notificationBudgetWarningBody(Object ratio) {
    return 'We\'ve already spent $ratio% of the budget. Should we slow down a bit?|Approaching the limits, Captain! Better tap the brakes a little.';
  }

  @override
  String notificationSubscriptionReminderTitle(Object name) {
    return 'Netflix & Chill... & Debt 🍿|$name Is Coming! 🎶';
  }

  @override
  String notificationSubscriptionReminderBody(Object amount, Object name) {
    return '$name bill is at the door again. Let\'s see how many series you finished this month?|Get your headphones ready, $name is about to be paid for $amount. Enjoy the rhythm!';
  }

  @override
  String notificationCategoryExceededTitle(Object category) {
    return '$category Out of Control! 🔥';
  }

  @override
  String notificationCategoryExceededBody(Object category) {
    return 'We burned through the budget for $category. How about a little break?';
  }

  @override
  String notificationCategoryWarningTitle(Object category) {
    return '$category Warning! ⚠️';
  }

  @override
  String notificationCategoryWarningBody(Object category, Object ratio) {
    return 'We\'ve swallowed $ratio% of the $category budget. Watch out!';
  }

  @override
  String get notificationSubscriptionChannel => 'Subscription Reminder';

  @override
  String get notificationSubscriptionChannelDesc =>
      'Reminds you of subscription payments';

  @override
  String get close => 'Close';

  @override
  String get creditInstallmentDesc => 'Bank loan or installments';

  @override
  String get addCustomExpense => 'Add Custom Expense';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get expenseWillBeDeleted =>
      'This expense will be permanently deleted.';

  @override
  String get monthlyFixedExpense => 'Total Monthly Expense';

  @override
  String activeExpensesCount(Object count) {
    return '$count Active Expenses';
  }

  @override
  String get noFixedExpensesYet => 'No fixed expenses added yet.';

  @override
  String renewsOnDay(Object day) {
    return 'Weekly / Day $day of month';
  }

  @override
  String get lastUpdated => 'Last Updated: ';

  @override
  String get privacyPolicyLastUpdated => 'December 19, 2025';

  @override
  String get privacyPolicySection1Title => '1. Data Collected';

  @override
  String get privacyPolicySection1Content =>
      'The FişMatik application collects data such as receipt images, expenditure items, and transaction amounts to enable you to track and manage your spending.';

  @override
  String get privacyPolicySection2Title => '2. Use of Data';

  @override
  String get privacyPolicySection2Content =>
      'Collected data is utilized to provide you with comprehensive budget analysis and personalized financial coaching services.';

  @override
  String get privacyPolicySection3Title => '3. Data Security';

  @override
  String get privacyPolicySection3Content =>
      'Your data is stored securely using the Supabase cloud infrastructure.';

  @override
  String get privacyPolicySection4Title => '4. Sharing';

  @override
  String get privacyPolicySection4Content =>
      'We do not share your data with third parties for advertising or marketing purposes.';

  @override
  String get privacyPolicySection5Title => '5. Your Rights';

  @override
  String get privacyPolicySection5Content =>
      'You have the right to delete or export your personal data at any time through the application settings.';

  @override
  String get privacyPolicySection6Title => '6. Cookies';

  @override
  String get privacyPolicySection6Content =>
      'The application uses essential cookies solely for session management and security purposes.';

  @override
  String get privacyPolicyFooter =>
      'This privacy policy is designed to inform FişMatik users about our data practices.';

  @override
  String get termsLastUpdated => 'November 26, 2024';

  @override
  String get termsSection1Title => '1. Service Description';

  @override
  String get termsSection1Content =>
      'FişMatik is a mobile application that allows users to scan and digitize their shopping receipts, track their expenses, and manage their budget.';

  @override
  String get termsSection2Title => '2. Account Creation';

  @override
  String get termsSection2Content =>
      '• You must be over 13 years old\n• You must provide a valid email address\n• You must provide accurate and up-to-date information\n• You are responsible for the security of your password';

  @override
  String get termsSection3Title => '3. Membership Levels';

  @override
  String get termsSection3Content =>
      'Free (0 TL):\n• 1 receipt scan per day\n• 20 manual entries per month\n• Unlimited subscription tracking\n• Ad-supported experience\n\nStandard (49.99 TL / Month):\n• 10 receipt scans per day\n• 50 manual entries per month\n• Unlimited subscription tracking\n• Category management\n• Ad-free experience\n• Reports\n• Shopping Guide\n\nPremium (79.99 TL / Month):\n• 25 receipt scans per day\n• 100 manual entries per month\n• Unlimited subscription tracking\n• Ad-free experience\n• AI Finance Coach\n• Smart Budget Forecasting\n• Category management\n• Reports\n• Shopping Guide\n\nFamily Economy (99.99 TL / Month):\n• 35 receipt scans per day (Family total)\n• 200 manual entries per month (Family total)\n• Unlimited subscription tracking\n• Ad-free experience\n• AI Finance Coach\n• Smart Budget Forecasting\n• Category management\n• Reports\n• Shopping Guide\n• Family Sharing';

  @override
  String get termsSection4Title => '4. Rules of Use';

  @override
  String get termsSection4Content =>
      'Allowed:\n• Personal expense tracking\n• Receipt digitization\n• Budget management\n\nProhibited:\n• Commercial use (unauthorized)\n• Manipulating the system\n• Uploading fake receipts or data\n• Use of spam or automated bots';

  @override
  String get termsSection5Title => '5. Disclaimer';

  @override
  String get termsSection5Content =>
      '• You use the app at your own risk\n• We are not responsible for your financial decisions\n• We do not provide tax or accounting advice\n• OCR and AI analysis may not be 100% accurate';

  @override
  String get termsSection6Title => '6. Account Termination';

  @override
  String get termsSection6Content =>
      '• You can delete your account at any time\n• Your account may be suspended in case of violation of terms of use\n• Deletion is irreversible';

  @override
  String get termsSection7Title => '7. Contact';

  @override
  String get termsSection7Content =>
      'For questions about the terms of use:\n\nEmail: info@kfsoftware.app';

  @override
  String get termsFooter =>
      'By using the FişMatik application, you declare that you have read, understood, and accepted these terms of use.';

  @override
  String get salaryDay => 'Salary Day';

  @override
  String get noReceiptsFoundInRange => 'No receipts found in this date range.';

  @override
  String get totalSpendingLabel => 'Total Spending';

  @override
  String get noCategoryData => 'No category data available.';

  @override
  String get noTransactionInCategory => 'No transactions in this category.';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get dailyReminderDesc => 'Remind me to scan receipts every day';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get summaryNotifications => 'Summary Notifications';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get weeklySummaryDesc => 'Expense summary every Sunday evening';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get monthlySummaryDesc => 'Detailed report at the end of the month';

  @override
  String get budgetAlerts => 'Budget Alerts';

  @override
  String get budgetAlertsDesc => 'Notifications at 75%, 90%, and exceed';

  @override
  String get subscriptionReminders => 'Subscription Reminders';

  @override
  String get subscriptionRemindersDesc => 'Remind renewal dates';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get testNotificationTitle => '✅ Test Notification';

  @override
  String get testNotificationBody => 'Notifications are working successfully!';

  @override
  String get notificationPermissionDenied => 'Notification permission denied.';

  @override
  String get settingsLoadError => 'Settings could not be loaded';

  @override
  String get settingsSaveError => 'Settings could not be saved';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get unconfirmedEmailError => 'Email address not confirmed.';

  @override
  String get invalidCredentialsError => 'Invalid email or password.';

  @override
  String get accountBlockedError => 'Your account is blocked.';

  @override
  String get generalError => 'An error occurred.';

  @override
  String get loginFailed => '❌ Login failed';

  @override
  String get passwordConfirmLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get mustAgreeToTerms => 'You must agree to the terms.';

  @override
  String get verificationEmailSentTitle => 'Verification Email Sent';

  @override
  String get verificationEmailSentBody =>
      'Please verify your email address and then log in.';

  @override
  String get ok => 'OK';

  @override
  String get weakPasswordError => 'Weak password.';

  @override
  String get invalidEmailError => 'Invalid email address.';

  @override
  String get googleSignUp => 'Sign up with Google';

  @override
  String get readAndAcceptPre => 'I have read and ';

  @override
  String get readAndAcceptAnd => ' and ';

  @override
  String get readAndAcceptPost => ' I accept.';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address and we\'ll send you a password reset link.';

  @override
  String get resetPasswordLinkSent => 'Password reset link sent.';

  @override
  String get enterEmailError => 'Please enter your email address.';

  @override
  String get send => 'Send';

  @override
  String get profilePhotoUpdated => 'Profile photo updated!';

  @override
  String get photoUploadError => 'Photo could not be uploaded';

  @override
  String get nameOrSurnameRequired =>
      'You need to enter at least a first or last name.';

  @override
  String get profileUpdated => 'Your profile information has been updated.';

  @override
  String get profileUpdateError => 'Profile could not be updated';

  @override
  String get fillAllPasswordFields => 'Fill in all password fields.';

  @override
  String get sessionNotFound => 'Session information not found.';

  @override
  String get passwordUpdated => 'Your password has been successfully updated!';

  @override
  String get currentPasswordIncorrect => 'The current password is not correct.';

  @override
  String get passwordUpdateFailed => 'Password could not be updated.';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountWarning => 'This action cannot be undone!';

  @override
  String get deleteAccountDataNotice =>
      'All your data (receipts, categories, settings) will be permanently deleted.';

  @override
  String get whyLeaving => 'Why are you leaving?';

  @override
  String get selectReason => 'Select a reason';

  @override
  String get reasonAppNotUsed => 'I don\'t use the app anymore';

  @override
  String get reasonAnotherAccount => 'I will open another account';

  @override
  String get reasonPrivacyConcerns => 'I have data privacy concerns';

  @override
  String get reasonNotMeetingExpectations =>
      'The application did not meet my expectations';

  @override
  String get reasonOther => 'Other';

  @override
  String get pleaseSpecifyReason => 'Please specify the reason';

  @override
  String get enterPasswordToDelete =>
      'Enter your password to delete your account:';

  @override
  String get emailNotFound => 'Email not found';

  @override
  String get requestReceived => 'Request Received';

  @override
  String get deleteRequestSuccess =>
      'Your account deletion request has been successfully received. Your account is under review and you will not be able to log in during this process.';

  @override
  String get accountStats => 'Account Statistics';

  @override
  String get memberSinceLabel => 'Member Since';

  @override
  String get unknown => 'Unknown';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get saveProfileButton => 'Save My Profile';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'New Password (Confirm)';

  @override
  String get updatePasswordButton => 'Update My Password';

  @override
  String get dangerZoneTitle => 'Danger Zone';

  @override
  String get deleteAccountSubtitle => 'You can permanently delete your account';

  @override
  String get deleteAccountNotice =>
      'This action cannot be undone. All your data (receipts, categories, settings) will be permanently deleted.';

  @override
  String get createFamily => 'Create Family';

  @override
  String get familyNameLabel => 'Family Name (e.g., Smith Family)';

  @override
  String get addressLabel => 'Home Address (Required)';

  @override
  String get addressHint => 'Shared living area address';

  @override
  String get addressRequired => 'Entering an address is mandatory.';

  @override
  String get familyCreatedSuccess => 'Family successfully created!';

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get familyLimitReached =>
      'Family plan limit reached (Maximum 5 people).';

  @override
  String get enterEmailToInvite =>
      'Enter the email address of the person you want to invite.';

  @override
  String get inviteSending => 'Sending invitation...';

  @override
  String get inviteSentSuccess => 'Invitation successfully sent.';

  @override
  String get leaveFamilyTitle => 'Leave Family';

  @override
  String get leaveFamilyConfirm =>
      'Are you sure you want to leave the family? You will lose access to shared data and return to the Standard plan.';

  @override
  String get leaveFamilyButton => 'Leave';

  @override
  String get leftFamilySuccess => 'You have left the family.';

  @override
  String get removeMemberTitle => 'Remove Member';

  @override
  String removeMemberConfirm(Object email) {
    return 'Are you sure you want to remove the member with email $email from the family?';
  }

  @override
  String get removeButton => 'Remove';

  @override
  String get memberRemovedSuccess => 'Member removed.';

  @override
  String get familyPlanTitle => 'Family Plan';

  @override
  String get noFamilyYet => 'You don\'t have a family yet.';

  @override
  String get familyPlanDesc =>
      'Manage your spending together with the Family Plan, track your budget as a team.';

  @override
  String get adminLabel => 'Admin';

  @override
  String get memberLabel => 'Member';

  @override
  String get familyMembersCount => 'Family Members';

  @override
  String get removeFromFamilyTooltip => 'Remove from Family';

  @override
  String get ownerCannotLeaveNotice =>
      'Note: As a family admin, you cannot leave the family. To completely delete the family, please contact support.';

  @override
  String get badgesTitle => 'Achievement Badges';

  @override
  String get earnedBadges => 'Earned Badges';

  @override
  String get locked => 'Locked';

  @override
  String get earned => 'Earned!';

  @override
  String get oneMonthProGift => '1 Month Pro Gift!';

  @override
  String get earnThisBadge => 'To earn this badge';

  @override
  String get myAchievements => 'My Achievements';

  @override
  String get dataLoadError => 'Data could not be loaded';

  @override
  String get myBadges => 'My Badges';

  @override
  String get dailyStreakLabel => 'Daily Streak';

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get earnedStat => 'Earned';

  @override
  String get lockedStat => 'Locked';

  @override
  String get completionStat => 'Completion';

  @override
  String get notEarnedYet => 'Not Earned Yet';

  @override
  String xpReward(Object xp) {
    return '+$xp XP';
  }

  @override
  String get levelUpTitle => 'Level Up!';

  @override
  String levelUpBody(Object level, Object levelName) {
    return 'Congratulations! You reached level $level: $levelName';
  }

  @override
  String get newBadgeTitle => 'New Badge!';

  @override
  String newBadgeBody(Object name, Object xp) {
    return 'You earned the $name badge! +$xp XP';
  }

  @override
  String get badge_first_receipt_name => 'First Step';

  @override
  String get badge_first_receipt_desc => 'You scanned your first receipt!';

  @override
  String get badge_first_receipt_msg =>
      '🎉 Great start! Every great journey begins with a single step.';

  @override
  String get badge_receipt_5_name => 'Regular User';

  @override
  String get badge_receipt_5_desc => 'You added 5 receipts.';

  @override
  String get badge_receipt_5_msg =>
      '💪 You\'re great! Regular tracking is the key to success.';

  @override
  String get badge_receipt_10_name => 'Professional';

  @override
  String get badge_receipt_10_desc => 'You added 10 receipts.';

  @override
  String get badge_receipt_10_msg =>
      '🌟 You\'re amazing! You\'re a professional now!';

  @override
  String get badge_receipt_50_name => 'Expert';

  @override
  String get badge_receipt_50_desc => 'You added 50 receipts.';

  @override
  String get badge_receipt_50_msg =>
      '🏆 You\'re a legend! Very few people reach this level.';

  @override
  String get badge_saver_name => 'Saver';

  @override
  String get badge_saver_desc => 'You recorded a total of 1000 TL in spending.';

  @override
  String get badge_saver_msg =>
      '💰 Great! Tracking your spending is the first step to wealth.';

  @override
  String get badge_big_spender_name => 'Big Spender';

  @override
  String get badge_big_spender_desc => 'You spent over 500 TL in one go.';

  @override
  String get badge_big_spender_msg =>
      '💳 Big spending brings big responsibilities!';

  @override
  String get badge_budget_master_name => 'Budget Master';

  @override
  String get badge_budget_master_desc =>
      'You didn\'t exceed your budget for a full month.';

  @override
  String get badge_budget_master_msg =>
      '🎯 Perfect! Discipline is the basis of success.';

  @override
  String get badge_night_owl_name => 'Night Owl';

  @override
  String get badge_night_owl_desc => 'You added a receipt after midnight.';

  @override
  String get badge_night_owl_msg =>
      '🌙 What are you doing up at night? But well done!';

  @override
  String get badge_early_bird_name => 'Early Bird';

  @override
  String get badge_early_bird_desc => 'You added a receipt before 6 AM.';

  @override
  String get badge_early_bird_msg =>
      '🌅 The early bird catches the worm! You\'re on your way.';

  @override
  String get badge_weekend_shopper_name => 'Weekend Shopper';

  @override
  String get badge_weekend_shopper_desc => 'You shopped on the weekend.';

  @override
  String get badge_weekend_shopper_msg =>
      '🛍️ Shopping on weekends is something else!';

  @override
  String get badge_loyal_user_name => 'Loyal Member';

  @override
  String get badge_loyal_user_desc => 'You used the app for 30 days.';

  @override
  String get badge_loyal_user_msg => '❤️ It\'s great to be with you! Thanks!';

  @override
  String get badge_category_master_name => 'Category Expert';

  @override
  String get badge_category_master_desc =>
      'You spent in 5 different categories.';

  @override
  String get badge_category_master_msg =>
      '📊 Variety is good! You distribute your spending well.';

  @override
  String get badge_ultimate_master_name => 'Ultimate Master';

  @override
  String get badge_ultimate_master_desc =>
      'Add 100 receipts and record 10,000 TL spending.';

  @override
  String get badge_ultimate_master_msg =>
      '👑 LEGEND! You are a true master! 1 month Pro gift is yours!';

  @override
  String get badge_receipt_100_name => '100 Receipts';

  @override
  String get badge_receipt_100_desc => 'You scanned 100 receipts!';

  @override
  String get badge_receipt_500_name => '500 Receipts';

  @override
  String get badge_receipt_500_desc => 'You scanned 500 receipts!';

  @override
  String get badge_receipt_1000_name => '1000 Receipts';

  @override
  String get badge_receipt_1000_desc =>
      'You scanned 1000 receipts! Incredible!';

  @override
  String get badge_streak_7_name => '7 Day Streak';

  @override
  String get badge_streak_7_desc => 'You scanned receipts 7 days in a row!';

  @override
  String get badge_streak_30_name => '30 Day Streak';

  @override
  String get badge_streak_30_desc => 'You scanned receipts 30 days in a row!';

  @override
  String get badge_streak_365_name => 'Yearly Champion';

  @override
  String get badge_streak_365_desc => '365 days of active use!';

  @override
  String get badge_saver_master_name => 'Savings Master';

  @override
  String get badge_saver_master_desc => 'You saved 20% of your budget!';

  @override
  String get badge_goal_hunter_name => 'Goal Hunter';

  @override
  String get badge_goal_hunter_desc =>
      'You hit your monthly goal 3 months in a row!';

  @override
  String get badge_market_master_name => 'Grocery Master';

  @override
  String get badge_market_master_desc => '50 receipts in the Grocery category!';

  @override
  String get badge_fuel_tracker_name => 'Fuel Tracker';

  @override
  String get badge_fuel_tracker_desc => '30 receipts in the Fuel category!';

  @override
  String get badge_gourmet_name => 'Gourmet';

  @override
  String get badge_gourmet_desc => '50 receipts in the Food & Drink category!';

  @override
  String levelLabel(Object level) {
    return 'Level $level';
  }

  @override
  String nextLevelXp(Object xp) {
    return 'Next level: $xp XP';
  }

  @override
  String get maxLevel => 'Maximum Level!';

  @override
  String get level_1_name => 'Novice';

  @override
  String get level_2_name => 'Rookie';

  @override
  String get level_3_name => 'Senior';

  @override
  String get level_4_name => 'Master';

  @override
  String get level_5_name => 'Grandmaster';

  @override
  String get level_6_name => 'Legend';

  @override
  String get level_7_name => 'Observer';

  @override
  String get level_8_name => 'Manager';

  @override
  String get level_9_name => 'Champion';

  @override
  String get level_10_name => 'King';

  @override
  String get editReceiptTitle => 'Edit Receipt';

  @override
  String get selectCategoryError => 'Please select a category.';

  @override
  String get changesSaved => 'Changes saved.';

  @override
  String get merchantLabel => 'Merchant Name';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get categoryLabel => 'Category';

  @override
  String get receiptDateLabel => 'Date';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get shoppingListTitle => 'Shopping List';

  @override
  String get shoppingHint => 'What will you buy? (e.g., Milk)';

  @override
  String get checkingPriceHistory => 'Checking price history...';

  @override
  String lastPriceInfo(Object date, Object merchant, Object price) {
    return 'You last bought it from $merchant on $date for $price TL.';
  }

  @override
  String get emptyShoppingList => 'Your list is empty';

  @override
  String get detailedFilter => 'Detailed Filter';

  @override
  String get amountRange => 'Amount Range';

  @override
  String get minAmountLabel => 'Min TL';

  @override
  String get maxAmountLabel => 'Max TL';

  @override
  String get categorySelectHint => 'Select Category';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get searchHint => 'Search store or product...';

  @override
  String get expenditureCalendarTitle => 'Spending Calendar';

  @override
  String get startTrackingDescription =>
      'Add your first receipt to start tracking your spending!';

  @override
  String get scanReceiptAction => 'Scan Receipt';

  @override
  String get manualEntryLabel => 'Manual Entry';

  @override
  String get scanReceiptLabel => 'Scan Receipt';

  @override
  String get unlimitedFixedExpenses => 'Unlimited Fixed Expenses';

  @override
  String get unlimitedManualEntry => 'Unlimited Manual Entry';

  @override
  String manualEntryLimitText(Object limit) {
    return '$limit Manual Entries';
  }

  @override
  String get adContent => 'Contains Ads';

  @override
  String get adFreeUsage => 'Ad-Free Usage';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get standardCategoriesOnly => 'Standard Categories Only';

  @override
  String get noRefund => 'No Refund for Errors';

  @override
  String get smartRefund => 'Smart Error Refund';

  @override
  String get currentMembership => 'Your Current Membership';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get specialLabel => 'SPECIAL';

  @override
  String get familyPlanDescription =>
      'Family-wide receipt and spending tracking.';

  @override
  String get familyFeature1 =>
      'Common spending dashboard for all family members';

  @override
  String get familyFeature2 => 'Add family members via email';

  @override
  String get familyFeature3 => 'All members can view receipt history*';

  @override
  String get familyFeature4 => 'One bill, shared control';

  @override
  String get membershipUpgradeTitle => 'Upgrade Membership';

  @override
  String currentMembershipStatus(Object tier) {
    return 'Current Membership: $tier';
  }

  @override
  String get tier_free_name => 'Free';

  @override
  String get tier_standart_name => 'Standard';

  @override
  String get tier_premium_name => 'Premium';

  @override
  String get tier_limitless_family_name => 'Family Economy';

  @override
  String get sessionEndedTitle => 'Session Expired';

  @override
  String get sessionEndedMessage =>
      'Your session has ended for security reasons. Please log in again.';

  @override
  String get accountBlockedTitle => 'Account Blocked';

  @override
  String get accountBlockedMessage =>
      'Your account has been blocked for violating our terms. Please contact support.';

  @override
  String get loginLogout => 'Log Out';

  @override
  String get accountDeletionPendingTitle => 'Account Deletion Pending';

  @override
  String get accountDeletionPendingMessage =>
      'Your account is marked for deletion. You cannot log in until the process is complete.';

  @override
  String get customCalendar => 'Calendar';

  @override
  String get today => 'Today';

  @override
  String membershipCheckError(Object error) {
    return 'Membership check error: $error';
  }

  @override
  String get notificationsEnabledTitle => 'Notifications Active';

  @override
  String get notificationsEnabledBody => 'Daily reminders successfully set.';

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String minutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get accountSection => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get spendingTrendsSubtitle => 'See your spending habits';

  @override
  String get achievementsSubtitle => 'See your earned badges';

  @override
  String get settingsSection => 'Settings';

  @override
  String get notificationSettingsSubtitle => 'Manage reminders';

  @override
  String get smsTrackingTitle => 'Automatic SMS Tracking';

  @override
  String get smsTrackingDesc => 'Automatically capture expense SMS';

  @override
  String get otherSection => 'Other';

  @override
  String get aboutUs => 'About Us';

  @override
  String get subscriptionPageLoadError => 'Error loading subscription page.';

  @override
  String get manualEntryLimitTitle => 'Manual Entry Limit';

  @override
  String manualEntryLimitContent(Object limit) {
    return 'With your current plan, you can make a maximum of $limit manual entries per month.';
  }

  @override
  String manualEntryLimitError(Object error) {
    return 'Error checking limit: $error';
  }

  @override
  String get enterValidAmount => 'Please enter a valid amount.';

  @override
  String get manualExpense => 'Manual Expense';

  @override
  String get manualExpenseSaved => 'Manual expense saved successfully.';

  @override
  String manualEntryLimitStatus(Object limit, Object used) {
    return '$used / $limit manual entries made';
  }

  @override
  String totalReceiptsLabel(Object count) {
    return '$count Receipts';
  }

  @override
  String get createButton => 'Create';

  @override
  String get pleaseWaitAnalyzing => 'Analyzing, please wait...';

  @override
  String get dateLabel => 'Date';

  @override
  String get productsLabel => 'Products';

  @override
  String get savingReceipt => 'Saving receipt...';

  @override
  String get receiptSavedSuccess => 'Receipt saved successfully!';

  @override
  String get saveReceiptButton => 'Save Receipt';

  @override
  String daysCount(Object count) {
    return '$count days';
  }

  @override
  String receiptSaveFailed(Object error) {
    return 'Failed to save receipt: $error';
  }

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get waterBill => 'Water Bill';

  @override
  String get gasBill => 'Natural Gas Bill';

  @override
  String get internetBill => 'Internet Bill';

  @override
  String get phoneBill => 'Phone Bill';

  @override
  String get managementFee => 'Management Fee';

  @override
  String get rent => 'Rent';

  @override
  String get electricityBill => 'Electricity Bill';

  @override
  String get propertyTax => 'Property Tax';

  @override
  String get incomeTax => 'Income Tax';

  @override
  String get vatPayment => 'VAT Payment';

  @override
  String get withholdingTax => 'Withholding Tax';

  @override
  String get trafficFine => 'Traffic Fine';

  @override
  String get socialSecurityPremium => 'Social Security (SGK) Premium';

  @override
  String get studentLoan => 'Student Loan (KYK)';

  @override
  String get motorVehicleTax => 'Motor Vehicle Tax (MTV)';

  @override
  String get healthCategory => 'Health';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryFood => 'Food & Dining';

  @override
  String get categoryGas => 'Fuel';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryTech => 'Technology';

  @override
  String get categoryHome => 'Home Goods';

  @override
  String get addFirstReceipt => 'Add Your First Receipt';

  @override
  String get budgetUpdated => 'Budget updated!';

  @override
  String get accept => 'Accept';

  @override
  String get thisMonthShort => '(This Month)';

  @override
  String get salaryDayShort => 'Salary Day';

  @override
  String get mobileAppRequired => 'Mobile App Required';

  @override
  String get budgetForecastTitle => 'Month-End Forecast';

  @override
  String budgetForecastMessage(Object amount) {
    return 'At this rate, you\'ll reach $amount.';
  }

  @override
  String get onTrackMessage => 'Great! You are on track.';

  @override
  String get overBudgetMessage => 'Warning! You might overspend.';

  @override
  String get forecastLabel => 'Forecast';

  @override
  String get tabReceipts => 'Receipts';

  @override
  String get tabProducts => 'Products';

  @override
  String get searchProductHint => 'Search product (e.g. Milk)';

  @override
  String cheapestPrice(Object price) {
    return 'Cheapest: $price TL';
  }

  @override
  String lastPrice(Object price) {
    return 'Last Price: $price TL';
  }

  @override
  String seenAt(Object date) {
    return 'Seen on $date';
  }

  @override
  String get priceDropAlertTitle => 'Price Drop Detected!';

  @override
  String priceDropAlertBody(Object newPrice, Object oldPrice, Object product) {
    return '$product is cheaper now! $oldPrice₺ -> $newPrice₺';
  }

  @override
  String get priceRiseAlertTitle => 'Price Hike Alert';

  @override
  String priceRiseAlertBody(Object newPrice, Object oldPrice, Object product) {
    return '$product price increased. $oldPrice₺ -> $newPrice₺';
  }

  @override
  String get onboardingTitle1 => 'Welcome to FişMatik! 🎉';

  @override
  String get onboardingDesc1 =>
      'Scan your receipts, invoices, and slips to record all your expenses in seconds. Budget tracking is now much smarter!';

  @override
  String get onboardingTitle2 => 'Receipt Scanning & Subscription Detection 📸';

  @override
  String get onboardingDesc2 =>
      'Scan your receipt or statement; let AI record your expenses and automatically detect your bills and subscriptions.';

  @override
  String get onboardingTitle3 => 'Smart Analysis & Budget Forecast 🔮';

  @override
  String get onboardingDesc3 =>
      'See end-of-month spending forecasts and savings tips based on your spending habits, warning you in advance.';

  @override
  String get onboardingTitle4 => 'Where Is It Cheaper? 🏷️';

  @override
  String get onboardingDesc4 =>
      'View the price history of products you buy, discover which store sells them cheaper, and save money.';

  @override
  String get onboardingTitle5 => 'Detailed Reports 📊';

  @override
  String get onboardingDesc5 =>
      'Take full control of your financial situation with charts and Excel reports.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s Start!';

  @override
  String get featureDailyScans => 'Daily Receipt Scans';

  @override
  String get featureMonthlyManual => 'Monthly Manual Entries';

  @override
  String get featureUnlimitedSubscriptions => 'Unlimited Subscription Tracking';

  @override
  String get featureAdFree => 'Ad-Free Experience';

  @override
  String get featureCategoryManagement => 'Category Management';

  @override
  String get featureBudgetForecasting => 'Smart Budget Forecasting';

  @override
  String get featureSmartRefund => 'Smart Error Refund';

  @override
  String get featureExcelReports => 'Excel Report Download';

  @override
  String get featurePdfReports => 'PDF Report Download';

  @override
  String get featureTaxReports => 'Tax Report';

  @override
  String get featurePriceHistory => 'Product Price History';

  @override
  String get featureCheapestStore => 'Cheapest Store Suggestion';

  @override
  String get featurePriceAlerts => 'Price Drop Alerts';

  @override
  String get featureFamilySharing => 'Family Sharing (5 members)';

  @override
  String get featureSharedDashboard => 'Shared Expense Dashboard';

  @override
  String get intelligenceTitle => 'AI Insights & Alerts';

  @override
  String get budgetPrediction => 'Budget Forecasting';

  @override
  String predictedEndOfMonth(Object amount) {
    return 'Predicted spending by month end: $amount ₺';
  }

  @override
  String get budgetSafe => 'Your budget looks safe! ✅';

  @override
  String get budgetDanger => 'Spending fast! You might exceed your budget. ⚠️';

  @override
  String get addAsSubscriptionShort => 'Add';

  @override
  String get potentialSubsTitle => 'Potential Subscriptions';

  @override
  String get tipsTitle => 'Saving Tip';

  @override
  String get unlockIntelligence => 'Unlock Insights';

  @override
  String get intelligenceProOnly =>
      'Smart forecasting and saving tips are for Limitless members only.';

  @override
  String get compareFeatures => 'Compare Features';

  @override
  String scansPerDay(Object count) {
    return '$count scans/day';
  }

  @override
  String entriesPerMonth(Object count) {
    return '$count entries/month';
  }

  @override
  String get unlimited => 'Unlimited';

  @override
  String get limited => 'Limited';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get clearChecked => 'Clear Checked Items';

  @override
  String get clearCheckedConfirm =>
      'Are you sure you want to remove all checked items from the list?';

  @override
  String get frequentlyBought => 'Frequently Bought (Suggestions)';

  @override
  String get notificationExactAlarmWarning => 'Exact Notifications Disabled';

  @override
  String get notificationExactAlarmDesc =>
      'To receive notifications on time, please enable \'Exact Alarm\' permission in settings.';

  @override
  String get notificationOpenSettings => 'Open Settings';

  @override
  String get installmentExpensesTitle => 'Installment Expenses';

  @override
  String get installmentExpenseTitle => 'Is this an installment?';

  @override
  String get installmentExpenseSub => 'This expense will be reflected monthly.';

  @override
  String get installmentCountLabel => 'Installment Count:';

  @override
  String get monthlyPaymentAmount => 'Monthly Amount';

  @override
  String get installment => 'Installment';

  @override
  String get deleteAllTitle => 'Delete All';

  @override
  String get deleteAllConfirm =>
      'All items in the list will be deleted. Are you sure?';
}
