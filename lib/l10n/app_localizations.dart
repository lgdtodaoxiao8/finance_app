import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ru'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sectionPreferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @weekStart.
  ///
  /// In en, this message translates to:
  /// **'Start of week'**
  String get weekStart;

  /// No description provided for @weekStartMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekStartMonday;

  /// No description provided for @weekStartSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekStartSunday;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @hideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get hideAmounts;

  /// No description provided for @hideAmountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mask balances and amounts across the app'**
  String get hideAmountsSubtitle;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get baseCurrency;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @goPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI insights, forecasts, sync & more'**
  String get goPremiumSubtitle;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active — enjoy!'**
  String get premiumActive;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @syncedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Synced automatically'**
  String get syncedAutomatically;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @periodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get periodOther;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses'**
  String get noExpenses;

  /// No description provided for @noExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction to see the breakdown'**
  String get noExpensesSubtitle;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @nothingInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period yet'**
  String get nothingInPeriod;

  /// No description provided for @loggingStreak.
  ///
  /// In en, this message translates to:
  /// **'Logging streak'**
  String get loggingStreak;

  /// No description provided for @biggestThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Biggest this month'**
  String get biggestThisMonth;

  /// No description provided for @dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get dailySpending;

  /// No description provided for @noSpendingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No spending this month yet'**
  String get noSpendingThisMonth;

  /// No description provided for @notEnoughHistory.
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet'**
  String get notEnoughHistory;

  /// No description provided for @sixMonthTrend.
  ///
  /// In en, this message translates to:
  /// **'6-month trend'**
  String get sixMonthTrend;

  /// No description provided for @legendIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get legendIn;

  /// No description provided for @legendOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get legendOut;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @thisWeekVsLast.
  ///
  /// In en, this message translates to:
  /// **'This week vs last'**
  String get thisWeekVsLast;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get lastWeek;

  /// No description provided for @whenYouSpend.
  ///
  /// In en, this message translates to:
  /// **'When you spend'**
  String get whenYouSpend;

  /// No description provided for @youSpendMostOn.
  ///
  /// In en, this message translates to:
  /// **'You spend the most {day}'**
  String youSpendMostOn(String day);

  /// No description provided for @weekdayMondays.
  ///
  /// In en, this message translates to:
  /// **'on Mondays'**
  String get weekdayMondays;

  /// No description provided for @weekdayTuesdays.
  ///
  /// In en, this message translates to:
  /// **'on Tuesdays'**
  String get weekdayTuesdays;

  /// No description provided for @weekdayWednesdays.
  ///
  /// In en, this message translates to:
  /// **'on Wednesdays'**
  String get weekdayWednesdays;

  /// No description provided for @weekdayThursdays.
  ///
  /// In en, this message translates to:
  /// **'on Thursdays'**
  String get weekdayThursdays;

  /// No description provided for @weekdayFridays.
  ///
  /// In en, this message translates to:
  /// **'on Fridays'**
  String get weekdayFridays;

  /// No description provided for @weekdaySaturdays.
  ///
  /// In en, this message translates to:
  /// **'on Saturdays'**
  String get weekdaySaturdays;

  /// No description provided for @weekdaySundays.
  ///
  /// In en, this message translates to:
  /// **'on Sundays'**
  String get weekdaySundays;

  /// No description provided for @weekdayShortMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdayShortSun;

  /// No description provided for @statSaved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get statSaved;

  /// No description provided for @statPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get statPerDay;

  /// No description provided for @statBiggest.
  ///
  /// In en, this message translates to:
  /// **'biggest'**
  String get statBiggest;

  /// No description provided for @statThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get statThisMonth;

  /// No description provided for @statActiveDays.
  ///
  /// In en, this message translates to:
  /// **'active days'**
  String get statActiveDays;

  /// No description provided for @weeklyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly AI digest'**
  String get weeklyDigestTitle;

  /// No description provided for @weeklyDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where your money went, what to change, and your health score — in plain language.'**
  String get weeklyDigestSubtitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @addTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransactionTitle;

  /// No description provided for @editTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransactionTitle;

  /// No description provided for @deleteTransactionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get deleteTransactionQuestion;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @blockerNoAccount.
  ///
  /// In en, this message translates to:
  /// **'You have not added any account'**
  String get blockerNoAccount;

  /// No description provided for @blockerNoCategory.
  ///
  /// In en, this message translates to:
  /// **'You have not added any category'**
  String get blockerNoCategory;

  /// No description provided for @blockerNoCurrency.
  ///
  /// In en, this message translates to:
  /// **'You have not added any currency'**
  String get blockerNoCurrency;

  /// No description provided for @blockerNoSecondAccount.
  ///
  /// In en, this message translates to:
  /// **'You have no second account to transfer'**
  String get blockerNoSecondAccount;

  /// No description provided for @blockerSameAccounts.
  ///
  /// In en, this message translates to:
  /// **'Account departure and destination must be different'**
  String get blockerSameAccounts;

  /// No description provided for @activeDaysOf.
  ///
  /// In en, this message translates to:
  /// **'{active}/{total} days'**
  String activeDaysOf(int active, int total);

  /// No description provided for @mustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get mustBeNumber;

  /// No description provided for @mustBeMoreThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be more than 0'**
  String get mustBeMoreThanZero;

  /// No description provided for @mustBeAtLeast4.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 4 characters long.'**
  String get mustBeAtLeast4;

  /// No description provided for @maximum30.
  ///
  /// In en, this message translates to:
  /// **'Maximum 30 characters long.'**
  String get maximum30;

  /// No description provided for @cannotBeZero.
  ///
  /// In en, this message translates to:
  /// **'Can not be null'**
  String get cannotBeZero;

  /// No description provided for @cannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Can not be negative'**
  String get cannotBeNegative;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @fromCategory.
  ///
  /// In en, this message translates to:
  /// **'From category'**
  String get fromCategory;

  /// No description provided for @toCategory.
  ///
  /// In en, this message translates to:
  /// **'To category'**
  String get toCategory;

  /// No description provided for @setupBaseCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your base currency'**
  String get setupBaseCurrencyTitle;

  /// No description provided for @setupBaseCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the currency you track everything in. You can add more currencies later.'**
  String get setupBaseCurrencyBody;

  /// No description provided for @setupBaseCurrencyAction.
  ///
  /// In en, this message translates to:
  /// **'Set base currency'**
  String get setupBaseCurrencyAction;

  /// No description provided for @setupAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get setupAccountTitle;

  /// No description provided for @setupAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account (Cash, Card, Bank…) to log your transactions into.'**
  String get setupAccountBody;

  /// No description provided for @setupAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get setupAccountAction;

  /// No description provided for @setupCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a category'**
  String get setupCategoryTitle;

  /// No description provided for @setupCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Create at least one category for your transactions.'**
  String get setupCategoryBody;

  /// No description provided for @setupCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get setupCategoryAction;

  /// No description provided for @newAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get newAccountTitle;

  /// No description provided for @newCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategoryTitle;

  /// No description provided for @newCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'New Currency'**
  String get newCurrencyTitle;

  /// No description provided for @accountCurrency.
  ///
  /// In en, this message translates to:
  /// **'Account currency'**
  String get accountCurrency;

  /// No description provided for @allCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get allCurrencies;

  /// No description provided for @chooseBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose the base currency'**
  String get chooseBaseCurrency;

  /// No description provided for @rateToBase.
  ///
  /// In en, this message translates to:
  /// **'Rate to base'**
  String get rateToBase;

  /// No description provided for @exchangeRateToBase.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate to base cur.'**
  String get exchangeRateToBase;

  /// No description provided for @rateEquals.
  ///
  /// In en, this message translates to:
  /// **'1 {base}  is equal  {rate} {target}'**
  String rateEquals(String base, String rate, String target);

  /// No description provided for @rateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.25 or 0.73'**
  String get rateHint;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get exchangeRates;

  /// No description provided for @editRate.
  ///
  /// In en, this message translates to:
  /// **'Edit rate'**
  String get editRate;

  /// No description provided for @ratePerUnit.
  ///
  /// In en, this message translates to:
  /// **'1 {code} = {rate} {base}'**
  String ratePerUnit(String code, String rate, String base);

  /// No description provided for @editRateNote.
  ///
  /// In en, this message translates to:
  /// **'Only new transactions use the new rate — past ones keep the rate they were logged at.'**
  String get editRateNote;

  /// No description provided for @setBaseCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Base Currency'**
  String get setBaseCurrencyTitle;

  /// No description provided for @haveNoItems.
  ///
  /// In en, this message translates to:
  /// **'Have no items'**
  String get haveNoItems;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get addOne;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYet;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @deleteItemQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{what}\"?'**
  String deleteItemQuestion(String what);

  /// No description provided for @colorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get colorPicker;

  /// No description provided for @iconPicker.
  ///
  /// In en, this message translates to:
  /// **'Icon Picker'**
  String get iconPicker;

  /// No description provided for @iconCategories.
  ///
  /// In en, this message translates to:
  /// **'Icons categories'**
  String get iconCategories;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrongDetail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. {error}'**
  String somethingWentWrongDetail(String error);

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCoach;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @thisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonthTitle;

  /// No description provided for @topCategory.
  ///
  /// In en, this message translates to:
  /// **'Top category'**
  String get topCategory;

  /// No description provided for @netThisMonth.
  ///
  /// In en, this message translates to:
  /// **'net this month'**
  String get netThisMonth;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'health score'**
  String get healthScore;

  /// No description provided for @noSpendYet.
  ///
  /// In en, this message translates to:
  /// **'no spend yet'**
  String get noSpendYet;

  /// No description provided for @percentOfSpending.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of spending'**
  String percentOfSpending(int pct);

  /// No description provided for @projectedMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'projected month-end'**
  String get projectedMonthEnd;

  /// No description provided for @aiReadOnSpending.
  ///
  /// In en, this message translates to:
  /// **'AI read on your spending'**
  String get aiReadOnSpending;

  /// No description provided for @tapToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Tap to analyze'**
  String get tapToAnalyze;

  /// No description provided for @previewUnlock.
  ///
  /// In en, this message translates to:
  /// **'Preview · unlock'**
  String get previewUnlock;

  /// No description provided for @overspending.
  ///
  /// In en, this message translates to:
  /// **'Overspending'**
  String get overspending;

  /// No description provided for @headingNegative.
  ///
  /// In en, this message translates to:
  /// **'Heading negative'**
  String get headingNegative;

  /// No description provided for @onPaceToStayPositive.
  ///
  /// In en, this message translates to:
  /// **'On pace to stay positive'**
  String get onPaceToStayPositive;

  /// No description provided for @inOutSummary.
  ///
  /// In en, this message translates to:
  /// **'in {inAmount} · out {outAmount}'**
  String inOutSummary(String inAmount, String outAmount);

  /// No description provided for @aiInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsightsTitle;

  /// No description provided for @aiCoachBadge.
  ///
  /// In en, this message translates to:
  /// **'AI COACH'**
  String get aiCoachBadge;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial health'**
  String get financialHealth;

  /// No description provided for @outOf100.
  ///
  /// In en, this message translates to:
  /// **'out of 100'**
  String get outOf100;

  /// No description provided for @coachTip.
  ///
  /// In en, this message translates to:
  /// **'Coach tip'**
  String get coachTip;

  /// No description provided for @reAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reAnalyze;

  /// No description provided for @readingYourSpending.
  ///
  /// In en, this message translates to:
  /// **'Reading your spending…'**
  String get readingYourSpending;

  /// No description provided for @authNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync isn\'t set up yet — add your Supabase keys to enable accounts.'**
  String get authNotConfigured;

  /// No description provided for @aiErrorBackendOff.
  ///
  /// In en, this message translates to:
  /// **'AI needs the backend configured (Supabase + key).'**
  String get aiErrorBackendOff;

  /// No description provided for @aiErrorNoCredit.
  ///
  /// In en, this message translates to:
  /// **'The AI provider is out of credit. Add billing at platform.openai.com → Billing, then try again.'**
  String get aiErrorNoCredit;

  /// No description provided for @aiErrorInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'The AI key on the server is invalid. Re-set it with `supabase secrets set OPENAI_API_KEY=...`.'**
  String get aiErrorInvalidKey;

  /// No description provided for @aiErrorKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t set up yet: set OPENAI_API_KEY in Supabase secrets.'**
  String get aiErrorKeyNotSet;

  /// No description provided for @aiErrorBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected AI response.'**
  String get aiErrorBadResponse;

  /// No description provided for @aiErrorDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s question limit. It resets tomorrow.'**
  String get aiErrorDailyLimit;

  /// No description provided for @askYourMoney.
  ///
  /// In en, this message translates to:
  /// **'Ask your money'**
  String get askYourMoney;

  /// No description provided for @askYourMoneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with your finances — \'Can I afford this?\''**
  String get askYourMoneySubtitle;

  /// No description provided for @askMoneyBadge.
  ///
  /// In en, this message translates to:
  /// **'Ask your money'**
  String get askMoneyBadge;

  /// No description provided for @askMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your money…'**
  String get askMoneyHint;

  /// No description provided for @askMoneyIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your money'**
  String get askMoneyIntroTitle;

  /// No description provided for @askMoneyIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers grounded in your real spending. Ask one question and a single follow-up.'**
  String get askMoneyIntroSubtitle;

  /// No description provided for @askMoneyTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get askMoneyTryAsking;

  /// No description provided for @askMoneyStarter1.
  ///
  /// In en, this message translates to:
  /// **'Where did my money go this month?'**
  String get askMoneyStarter1;

  /// No description provided for @askMoneyStarter2.
  ///
  /// In en, this message translates to:
  /// **'Am I saving enough?'**
  String get askMoneyStarter2;

  /// No description provided for @askMoneyStarter3.
  ///
  /// In en, this message translates to:
  /// **'What\'s my biggest waste?'**
  String get askMoneyStarter3;

  /// No description provided for @askMoneyThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get askMoneyThinking;

  /// No description provided for @askMoneyFollowUpHint.
  ///
  /// In en, this message translates to:
  /// **'Ask one follow-up'**
  String get askMoneyFollowUpHint;

  /// No description provided for @askMoneyNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get askMoneyNewQuestion;

  /// No description provided for @askMoneyDone.
  ///
  /// In en, this message translates to:
  /// **'That\'s a question and a follow-up. Start a new one anytime.'**
  String get askMoneyDone;

  /// No description provided for @askMoneySignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to chat with your money.'**
  String get askMoneySignInRequired;

  /// No description provided for @askMoneyQuestionsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left today'**
  String askMoneyQuestionsLeft(int count);

  /// No description provided for @spendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending breakdown'**
  String get spendingBreakdown;

  /// No description provided for @totalSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total spent this month'**
  String get totalSpentThisMonth;

  /// No description provided for @noExpensesThisMonthYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month yet.'**
  String get noExpensesThisMonthYet;

  /// No description provided for @acrossNCategories.
  ///
  /// In en, this message translates to:
  /// **'across {count} categories'**
  String acrossNCategories(int count);

  /// No description provided for @forecastBadge.
  ///
  /// In en, this message translates to:
  /// **'FORECAST'**
  String get forecastBadge;

  /// No description provided for @projectedMonthEndBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected month-end balance'**
  String get projectedMonthEndBalance;

  /// No description provided for @onTrackGreen.
  ///
  /// In en, this message translates to:
  /// **'On track to finish the month in the green.'**
  String get onTrackGreen;

  /// No description provided for @atThisPaceNegative.
  ///
  /// In en, this message translates to:
  /// **'At this pace you\'ll end the month negative.'**
  String get atThisPaceNegative;

  /// No description provided for @incomeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get incomeThisMonth;

  /// No description provided for @spentSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get spentSoFar;

  /// No description provided for @projectedTotalSpend.
  ///
  /// In en, this message translates to:
  /// **'Projected total spend'**
  String get projectedTotalSpend;

  /// No description provided for @dailySpendRate.
  ///
  /// In en, this message translates to:
  /// **'Daily spend rate'**
  String get dailySpendRate;

  /// No description provided for @daysLeftInMonth.
  ///
  /// In en, this message translates to:
  /// **'Days left in month'**
  String get daysLeftInMonth;

  /// No description provided for @netThisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Net this month'**
  String get netThisMonthTitle;

  /// No description provided for @whereItWent.
  ///
  /// In en, this message translates to:
  /// **'Where it went'**
  String get whereItWent;

  /// No description provided for @youKeptPercent.
  ///
  /// In en, this message translates to:
  /// **'You kept {pct}% of your income.'**
  String youKeptPercent(int pct);

  /// No description provided for @youSpentMorePercent.
  ///
  /// In en, this message translates to:
  /// **'You spent {pct}% more than you earned.'**
  String youSpentMorePercent(int pct);

  /// No description provided for @spendingUpVsLast.
  ///
  /// In en, this message translates to:
  /// **'Spending is up {pct}% vs last month'**
  String spendingUpVsLast(int pct);

  /// No description provided for @spendingDownVsLast.
  ///
  /// In en, this message translates to:
  /// **'Spending is down {pct}% vs last month'**
  String spendingDownVsLast(int pct);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync your data across phone and web, and keep it safely backed up.'**
  String get authSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get enterValidEmail;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMin6;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @newHereCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreate;

  /// No description provided for @signInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync across devices'**
  String get signInToSync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @cloudSyncNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t set up yet'**
  String get cloudSyncNotSetUp;

  /// No description provided for @turnTrackingIntoPlan.
  ///
  /// In en, this message translates to:
  /// **'Turn tracking into a plan'**
  String get turnTrackingIntoPlan;

  /// No description provided for @paywallBody.
  ///
  /// In en, this message translates to:
  /// **'Tracking shows the past. Premium changes what happens next — most people find the price back in the first week of catching overspend early.'**
  String get paywallBody;

  /// No description provided for @continueOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Continue on the web'**
  String get continueOnWeb;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout in your browser — no App Store fees.'**
  String get secureCheckout;

  /// No description provided for @couldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser.'**
  String get couldNotOpenBrowser;

  /// No description provided for @unlockWithPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Premium'**
  String get unlockWithPremium;

  /// No description provided for @featureAiCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'AI money coach'**
  String get featureAiCoachTitle;

  /// No description provided for @featureAiCoachBody.
  ///
  /// In en, this message translates to:
  /// **'A personal read on where your money leaks — and the one move to fix it.'**
  String get featureAiCoachBody;

  /// No description provided for @featureForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Month-end forecast'**
  String get featureForecastTitle;

  /// No description provided for @featureForecastBody.
  ///
  /// In en, this message translates to:
  /// **'See how the month will end while you can still change it, not after.'**
  String get featureForecastBody;

  /// No description provided for @featureHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial health score'**
  String get featureHealthTitle;

  /// No description provided for @featureHealthBody.
  ///
  /// In en, this message translates to:
  /// **'One number that tells you if you\'re on track — and what moves it.'**
  String get featureHealthBody;

  /// No description provided for @featureAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart alerts'**
  String get featureAlertsTitle;

  /// No description provided for @featureAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'A nudge before a category blows its budget — catch overspend early.'**
  String get featureAlertsBody;

  /// No description provided for @featureSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync everywhere'**
  String get featureSyncTitle;

  /// No description provided for @featureSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Your money on phone and web, always backed up. Never lose a record.'**
  String get featureSyncBody;

  /// No description provided for @featureAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your money anything'**
  String get featureAskTitle;

  /// No description provided for @featureAskBody.
  ///
  /// In en, this message translates to:
  /// **'Ask in plain language and get an answer from your own numbers.'**
  String get featureAskBody;

  /// No description provided for @onboardTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every spend'**
  String get onboardTrackTitle;

  /// No description provided for @onboardTrackBody.
  ///
  /// In en, this message translates to:
  /// **'Log an expense in a couple of taps — even straight from your home-screen widget. No spreadsheet, no friction.'**
  String get onboardTrackBody;

  /// No description provided for @onboardInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'See where your money goes'**
  String get onboardInsightsTitle;

  /// No description provided for @onboardInsightsBody.
  ///
  /// In en, this message translates to:
  /// **'Clean charts and monthly breakdowns turn your history into insights you can actually act on.'**
  String get onboardInsightsBody;

  /// No description provided for @onboardAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI that plans ahead'**
  String get onboardAiTitle;

  /// No description provided for @onboardAiBody.
  ///
  /// In en, this message translates to:
  /// **'Personal budget coaching, spending forecasts and smart alerts — your money on autopilot, powered by AI.'**
  String get onboardAiBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'This is the currency your totals and charts are shown in. You can add more currencies later.'**
  String get onboardCurrencyBody;

  /// No description provided for @enterTheApp.
  ///
  /// In en, this message translates to:
  /// **'Enter the app'**
  String get enterTheApp;

  /// No description provided for @pickCurrencyToContinue.
  ///
  /// In en, this message translates to:
  /// **'Pick a currency to continue'**
  String get pickCurrencyToContinue;

  /// No description provided for @yourAccounts.
  ///
  /// In en, this message translates to:
  /// **'Your accounts'**
  String get yourAccounts;

  /// No description provided for @addAccountInSettings.
  ///
  /// In en, this message translates to:
  /// **'Add an account in Settings to track balances'**
  String get addAccountInSettings;

  /// No description provided for @acrossNAccounts.
  ///
  /// In en, this message translates to:
  /// **'across {count} accounts'**
  String acrossNAccounts(int count);

  /// No description provided for @widgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home widgets'**
  String get widgetsTitle;

  /// No description provided for @widgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log a spend in one tap from your home screen'**
  String get widgetsSubtitle;

  /// No description provided for @widgetConfigIntro.
  ///
  /// In en, this message translates to:
  /// **'Pin categories to your quick-add widget. A fixed-amount tap logs instantly; presets let you pick a common amount; or open the app to type any amount.'**
  String get widgetConfigIntro;

  /// No description provided for @widgetOnYourWidget.
  ///
  /// In en, this message translates to:
  /// **'On your widget'**
  String get widgetOnYourWidget;

  /// No description provided for @widgetNoShortcuts.
  ///
  /// In en, this message translates to:
  /// **'No categories pinned yet'**
  String get widgetNoShortcuts;

  /// No description provided for @widgetAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add a category'**
  String get widgetAddCategory;

  /// No description provided for @widgetAllPinned.
  ///
  /// In en, this message translates to:
  /// **'All categories are already pinned'**
  String get widgetAllPinned;

  /// No description provided for @widgetPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add categories to see them here'**
  String get widgetPreviewEmpty;

  /// No description provided for @widgetShortcutModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get widgetShortcutModeFixed;

  /// No description provided for @widgetShortcutModePresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get widgetShortcutModePresets;

  /// No description provided for @widgetShortcutModeOpen.
  ///
  /// In en, this message translates to:
  /// **'Ask each time'**
  String get widgetShortcutModeOpen;

  /// No description provided for @widgetFixedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'One tap logs this exact amount.'**
  String get widgetFixedAmountHint;

  /// No description provided for @widgetPresetsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a preset to log it instantly.'**
  String get widgetPresetsHint;

  /// No description provided for @widgetPresetsHintIncome.
  ///
  /// In en, this message translates to:
  /// **'Tap a preset to log the income instantly.'**
  String get widgetPresetsHintIncome;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoryType;

  /// No description provided for @widgetOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Tap builds the amount right on the widget, then logs it.'**
  String get widgetOpenHint;

  /// No description provided for @widgetStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount steps'**
  String get widgetStepsTitle;

  /// No description provided for @widgetStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to adapt to your spending automatically.'**
  String get widgetStepsHint;

  /// No description provided for @compactThousands.
  ///
  /// In en, this message translates to:
  /// **'K'**
  String get compactThousands;

  /// No description provided for @compactMillions.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get compactMillions;

  /// No description provided for @widgetGroupsIntro.
  ///
  /// In en, this message translates to:
  /// **'Create category sets for the quick-add widget. Long-press a widget on the home screen → “Edit Widget” to choose which set it shows.'**
  String get widgetGroupsIntro;

  /// No description provided for @widgetGroupDefault.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get widgetGroupDefault;

  /// No description provided for @widgetAddGroup.
  ///
  /// In en, this message translates to:
  /// **'Add a set'**
  String get widgetAddGroup;

  /// No description provided for @widgetGroupName.
  ///
  /// In en, this message translates to:
  /// **'Set name'**
  String get widgetGroupName;

  /// No description provided for @widgetGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Everyday, Work'**
  String get widgetGroupNameHint;

  /// No description provided for @widgetGroupCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String widgetGroupCategories(int count);

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategoryTitle;

  /// No description provided for @editAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccountTitle;

  /// No description provided for @iconGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get iconGroupAll;

  /// No description provided for @iconGroupFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get iconGroupFinance;

  /// No description provided for @iconGroupMovement.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get iconGroupMovement;

  /// No description provided for @iconGroupFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get iconGroupFood;

  /// No description provided for @iconGroupRetail.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get iconGroupRetail;

  /// No description provided for @iconGroupHousing.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get iconGroupHousing;

  /// No description provided for @iconGroupHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get iconGroupHealth;

  /// No description provided for @iconGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get iconGroupOther;

  /// No description provided for @widgetPreviewSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get widgetPreviewSmall;

  /// No description provided for @widgetPreviewMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get widgetPreviewMedium;

  /// No description provided for @widgetAddPreset.
  ///
  /// In en, this message translates to:
  /// **'Add amount'**
  String get widgetAddPreset;

  /// No description provided for @widgetPresetsMaxed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count}'**
  String widgetPresetsMaxed(int count);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAddTitle;

  /// No description provided for @quickIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick income'**
  String get quickIncomeTitle;

  /// No description provided for @quickAddSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quickAddSaved;

  /// No description provided for @quickAddIncompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Add a category, an account and a base currency first.'**
  String get quickAddIncompleteSetup;

  /// No description provided for @widgetFlowExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get widgetFlowExpense;

  /// No description provided for @widgetFlowIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get widgetFlowIncome;

  /// No description provided for @widgetFlowQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should this widget log?'**
  String get widgetFlowQuestion;

  /// No description provided for @widgetFlowExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Money going out — a spend.'**
  String get widgetFlowExpenseHint;

  /// No description provided for @widgetFlowIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'Money coming in — a paycheck, a gift, a refund.'**
  String get widgetFlowIncomeHint;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @txOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get txOn;

  /// No description provided for @txFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get txFrom;

  /// No description provided for @txTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get txTo;

  /// No description provided for @sentenceNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get sentenceNote;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'choose category'**
  String get chooseCategory;

  /// No description provided for @chooseAccount.
  ///
  /// In en, this message translates to:
  /// **'choose account'**
  String get chooseAccount;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
