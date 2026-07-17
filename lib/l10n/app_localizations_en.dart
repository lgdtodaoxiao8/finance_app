// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get weekStart => 'Start of week';

  @override
  String get weekStartMonday => 'Monday';

  @override
  String get weekStartSunday => 'Sunday';

  @override
  String get privacy => 'Privacy';

  @override
  String get hideAmounts => 'Hide amounts';

  @override
  String get hideAmountsSubtitle => 'Mask balances and amounts across the app';

  @override
  String get baseCurrency => 'Base currency';

  @override
  String get accounts => 'Accounts';

  @override
  String get categories => 'Categories';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get goPremiumSubtitle => 'AI insights, forecasts, sync & more';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get premiumActive => 'Premium is active — enjoy!';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signedIn => 'Signed in';

  @override
  String get syncedAutomatically => 'Synced automatically';

  @override
  String get save => 'Save';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navSettings => 'Settings';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodOther => 'Other';

  @override
  String get periodToday => 'Today';

  @override
  String get periodCustom => 'Custom';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get total => 'Total';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get noExpenses => 'No expenses';

  @override
  String get noExpensesSubtitle => 'Add a transaction to see the breakdown';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get nothingInPeriod => 'Nothing in this period yet';

  @override
  String get loggingStreak => 'Logging streak';

  @override
  String get biggestThisMonth => 'Biggest this month';

  @override
  String get dailySpending => 'Daily spending';

  @override
  String get noSpendingThisMonth => 'No spending this month yet';

  @override
  String get notEnoughHistory => 'Not enough history yet';

  @override
  String get sixMonthTrend => '6-month trend';

  @override
  String get legendIn => 'In';

  @override
  String get legendOut => 'Out';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get thisWeekVsLast => 'This week vs last';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get whenYouSpend => 'When you spend';

  @override
  String youSpendMostOn(String day) {
    return 'You spend the most $day';
  }

  @override
  String get weekdayMondays => 'on Mondays';

  @override
  String get weekdayTuesdays => 'on Tuesdays';

  @override
  String get weekdayWednesdays => 'on Wednesdays';

  @override
  String get weekdayThursdays => 'on Thursdays';

  @override
  String get weekdayFridays => 'on Fridays';

  @override
  String get weekdaySaturdays => 'on Saturdays';

  @override
  String get weekdaySundays => 'on Sundays';

  @override
  String get weekdayShortMon => 'M';

  @override
  String get weekdayShortTue => 'T';

  @override
  String get weekdayShortWed => 'W';

  @override
  String get weekdayShortThu => 'T';

  @override
  String get weekdayShortFri => 'F';

  @override
  String get weekdayShortSat => 'S';

  @override
  String get weekdayShortSun => 'S';

  @override
  String get statSaved => 'saved';

  @override
  String get statPerDay => 'per day';

  @override
  String get statBiggest => 'biggest';

  @override
  String get statThisMonth => 'this month';

  @override
  String get statActiveDays => 'active days';

  @override
  String get weeklyDigestTitle => 'Your weekly AI digest';

  @override
  String get weeklyDigestSubtitle =>
      'Where your money went, what to change, and your health score — in plain language.';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get name => 'Name';

  @override
  String get amount => 'Amount';

  @override
  String get currency => 'Currency';

  @override
  String get note => 'Note';

  @override
  String get transfer => 'Transfer';

  @override
  String get all => 'All';

  @override
  String get addTransactionTitle => 'Add Transaction';

  @override
  String get editTransactionTitle => 'Edit Transaction';

  @override
  String get deleteTransactionQuestion => 'Delete transaction?';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get blockerNoAccount => 'You have not added any account';

  @override
  String get blockerNoCategory => 'You have not added any category';

  @override
  String get blockerNoCurrency => 'You have not added any currency';

  @override
  String get blockerNoSecondAccount => 'You have no second account to transfer';

  @override
  String get blockerSameAccounts =>
      'Account departure and destination must be different';

  @override
  String activeDaysOf(int active, int total) {
    return '$active/$total days';
  }

  @override
  String get mustBeNumber => 'Must be a number';

  @override
  String get mustBeMoreThanZero => 'Must be more than 0';

  @override
  String get mustBeAtLeast4 => 'Must be at least 4 characters long.';

  @override
  String get maximum30 => 'Maximum 30 characters long.';

  @override
  String get cannotBeZero => 'Can not be null';

  @override
  String get cannotBeNegative => 'Can not be negative';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get fromCategory => 'From category';

  @override
  String get toCategory => 'To category';

  @override
  String get setupBaseCurrencyTitle => 'Set your base currency';

  @override
  String get setupBaseCurrencyBody =>
      'Choose the currency you track everything in. You can add more currencies later.';

  @override
  String get setupBaseCurrencyAction => 'Set base currency';

  @override
  String get setupAccountTitle => 'Add an account';

  @override
  String get setupAccountBody =>
      'Create an account (Cash, Card, Bank…) to log your transactions into.';

  @override
  String get setupAccountAction => 'Add account';

  @override
  String get setupCategoryTitle => 'Add a category';

  @override
  String get setupCategoryBody =>
      'Create at least one category for your transactions.';

  @override
  String get setupCategoryAction => 'Add category';

  @override
  String get newAccountTitle => 'New Account';

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get newCurrencyTitle => 'New Currency';

  @override
  String get accountCurrency => 'Account currency';

  @override
  String get allCurrencies => 'All currencies';

  @override
  String get chooseBaseCurrency => 'Choose the base currency';

  @override
  String get rateToBase => 'Rate to base';

  @override
  String get exchangeRateToBase => 'Exchange rate to base cur.';

  @override
  String rateEquals(String base, String rate, String target) {
    return '1 $base  is equal  $rate $target';
  }

  @override
  String get rateHint => 'e.g. 1.25 or 0.73';

  @override
  String get setBaseCurrencyTitle => 'Set Base Currency';

  @override
  String get haveNoItems => 'Have no items';

  @override
  String get addOne => 'Add one';

  @override
  String get noAccountsYet => 'No accounts yet';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String deleteItemQuestion(String what) {
    return 'Delete \"$what\"?';
  }

  @override
  String get colorPicker => 'Color Picker';

  @override
  String get iconPicker => 'Icon Picker';

  @override
  String get iconCategories => 'Icons categories';

  @override
  String get other => 'Other';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get tryAgain => 'Try again';

  @override
  String somethingWentWrongDetail(String error) {
    return 'Something went wrong. $error';
  }

  @override
  String get insights => 'Insights';

  @override
  String get aiCoach => 'AI Coach';

  @override
  String get forecast => 'Forecast';

  @override
  String get thisMonthTitle => 'This month';

  @override
  String get topCategory => 'Top category';

  @override
  String get netThisMonth => 'net this month';

  @override
  String get healthScore => 'health score';

  @override
  String get noSpendYet => 'no spend yet';

  @override
  String percentOfSpending(int pct) {
    return '$pct% of spending';
  }

  @override
  String get projectedMonthEnd => 'projected month-end';

  @override
  String get aiReadOnSpending => 'AI read on your spending + a tip';

  @override
  String get tapToAnalyze => 'Tap to analyze';

  @override
  String get previewUnlock => 'Preview · unlock';

  @override
  String get overspending => 'Overspending';

  @override
  String get headingNegative => 'Heading negative';

  @override
  String get onPaceToStayPositive => 'On pace to stay positive';

  @override
  String inOutSummary(String inAmount, String outAmount) {
    return 'in $inAmount · out $outAmount';
  }

  @override
  String get aiInsightsTitle => 'AI Insights';

  @override
  String get aiCoachBadge => 'AI COACH';

  @override
  String get financialHealth => 'Financial health';

  @override
  String get outOf100 => 'out of 100';

  @override
  String get coachTip => 'Coach tip';

  @override
  String get reAnalyze => 'Re-analyze';

  @override
  String get readingYourSpending => 'Reading your spending…';

  @override
  String get authNotConfigured =>
      'Sync isn\'t set up yet — add your Supabase keys to enable accounts.';

  @override
  String get aiErrorBackendOff =>
      'AI needs the backend configured (Supabase + key).';

  @override
  String get aiErrorNoCredit =>
      'The AI provider is out of credit. Add billing at platform.openai.com → Billing, then try again.';

  @override
  String get aiErrorInvalidKey =>
      'The AI key on the server is invalid. Re-set it with `supabase secrets set OPENAI_API_KEY=...`.';

  @override
  String get aiErrorKeyNotSet =>
      'AI isn\'t set up yet: set OPENAI_API_KEY in Supabase secrets.';

  @override
  String get aiErrorBadResponse => 'Unexpected AI response.';

  @override
  String get spendingBreakdown => 'Spending breakdown';

  @override
  String get totalSpentThisMonth => 'Total spent this month';

  @override
  String get noExpensesThisMonthYet => 'No expenses this month yet.';

  @override
  String acrossNCategories(int count) {
    return 'across $count categories';
  }

  @override
  String get forecastBadge => 'FORECAST';

  @override
  String get projectedMonthEndBalance => 'Projected month-end balance';

  @override
  String get onTrackGreen => 'On track to finish the month in the green.';

  @override
  String get atThisPaceNegative =>
      'At this pace you\'ll end the month negative.';

  @override
  String get incomeThisMonth => 'Income this month';

  @override
  String get spentSoFar => 'Spent so far';

  @override
  String get projectedTotalSpend => 'Projected total spend';

  @override
  String get dailySpendRate => 'Daily spend rate';

  @override
  String get daysLeftInMonth => 'Days left in month';

  @override
  String get netThisMonthTitle => 'Net this month';

  @override
  String get whereItWent => 'Where it went';

  @override
  String youKeptPercent(int pct) {
    return 'You kept $pct% of your income.';
  }

  @override
  String youSpentMorePercent(int pct) {
    return 'You spent $pct% more than you earned.';
  }

  @override
  String spendingUpVsLast(int pct) {
    return 'Spending is up $pct% vs last month';
  }

  @override
  String spendingDownVsLast(int pct) {
    return 'Spending is down $pct% vs last month';
  }

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get authSubtitle =>
      'Sync your data across phone and web, and keep it safely backed up.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get password => 'Password';

  @override
  String get enterValidEmail => 'Enter a valid email.';

  @override
  String get passwordMin6 => 'Password must be at least 6 characters.';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get newHereCreate => 'New here? Create an account';

  @override
  String get signInToSync => 'Sign in to sync across devices';

  @override
  String get syncing => 'Syncing…';

  @override
  String get cloudSyncNotSetUp => 'Cloud sync isn\'t set up yet';

  @override
  String get turnTrackingIntoPlan => 'Turn tracking into a plan';

  @override
  String get paywallBody =>
      'Tracking shows the past. Premium changes what happens next — most people find the price back in the first week of catching overspend early.';

  @override
  String get continueOnWeb => 'Continue on the web';

  @override
  String get secureCheckout =>
      'Secure checkout in your browser — no App Store fees.';

  @override
  String get couldNotOpenBrowser => 'Could not open the browser.';

  @override
  String get unlockWithPremium => 'Unlock with Premium';

  @override
  String get featureAiCoachTitle => 'AI money coach';

  @override
  String get featureAiCoachBody =>
      'A personal read on where your money leaks — and the one move to fix it.';

  @override
  String get featureForecastTitle => 'Month-end forecast';

  @override
  String get featureForecastBody =>
      'See how the month will end while you can still change it, not after.';

  @override
  String get featureHealthTitle => 'Financial health score';

  @override
  String get featureHealthBody =>
      'One number that tells you if you\'re on track — and what moves it.';

  @override
  String get featureAlertsTitle => 'Smart alerts';

  @override
  String get featureAlertsBody =>
      'A nudge before a category blows its budget — catch overspend early.';

  @override
  String get featureSyncTitle => 'Sync everywhere';

  @override
  String get featureSyncBody =>
      'Your money on phone and web, always backed up. Never lose a record.';

  @override
  String get featureAskTitle => 'Ask your money anything';

  @override
  String get featureAskBody =>
      'Ask in plain language and get an answer from your own numbers.';

  @override
  String get onboardTrackTitle => 'Track every spend';

  @override
  String get onboardTrackBody =>
      'Log an expense in a couple of taps — even straight from your home-screen widget. No spreadsheet, no friction.';

  @override
  String get onboardInsightsTitle => 'See where your money goes';

  @override
  String get onboardInsightsBody =>
      'Clean charts and monthly breakdowns turn your history into insights you can actually act on.';

  @override
  String get onboardAiTitle => 'AI that plans ahead';

  @override
  String get onboardAiBody =>
      'Personal budget coaching, spending forecasts and smart alerts — your money on autopilot, powered by AI.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get onboardCurrencyBody =>
      'This is the currency your totals and charts are shown in. You can add more currencies later.';

  @override
  String get enterTheApp => 'Enter the app';

  @override
  String get pickCurrencyToContinue => 'Pick a currency to continue';

  @override
  String get yourAccounts => 'Your accounts';

  @override
  String get addAccountInSettings =>
      'Add an account in Settings to track balances';

  @override
  String acrossNAccounts(int count) {
    return 'across $count accounts';
  }

  @override
  String get widgetsTitle => 'Home widgets';

  @override
  String get widgetsSubtitle => 'Log a spend in one tap from your home screen';

  @override
  String get widgetConfigIntro =>
      'Pin categories to your quick-add widget. A fixed-amount tap logs instantly; presets let you pick a common amount; or open the app to type any amount.';

  @override
  String get widgetOnYourWidget => 'On your widget';

  @override
  String get widgetNoShortcuts => 'No categories pinned yet';

  @override
  String get widgetAddCategory => 'Add a category';

  @override
  String get widgetAllPinned => 'All categories are already pinned';

  @override
  String get widgetPreviewEmpty => 'Add categories to see them here';

  @override
  String get widgetShortcutModeFixed => 'Fixed';

  @override
  String get widgetShortcutModePresets => 'Presets';

  @override
  String get widgetShortcutModeOpen => 'Ask each time';

  @override
  String get widgetFixedAmountHint => 'One tap logs this exact amount.';

  @override
  String get widgetPresetsHint => 'Tap a preset to log it instantly.';

  @override
  String get widgetOpenHint => 'Tap opens the app to type any amount.';

  @override
  String get widgetAddPreset => 'Add amount';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get quickAddTitle => 'Quick add';

  @override
  String get quickAddSaved => 'Saved';

  @override
  String get quickAddIncompleteSetup =>
      'Add a category, an account and a base currency first.';
}
