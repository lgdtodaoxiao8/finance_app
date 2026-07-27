// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionPreferences => 'Параметры';

  @override
  String get appearance => 'Оформление';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get weekStart => 'Начало недели';

  @override
  String get weekStartMonday => 'Понедельник';

  @override
  String get weekStartSunday => 'Воскресенье';

  @override
  String get privacy => 'Приватность';

  @override
  String get hideAmounts => 'Скрывать суммы';

  @override
  String get hideAmountsSubtitle =>
      'Маскировать балансы и суммы во всём приложении';

  @override
  String get baseCurrency => 'Базовая валюта';

  @override
  String get accounts => 'Счета';

  @override
  String get categories => 'Категории';

  @override
  String get goPremium => 'Перейти на Premium';

  @override
  String get goPremiumSubtitle =>
      'AI-инсайты, прогнозы, синхронизация и другое';

  @override
  String get upgrade => 'Улучшить';

  @override
  String get premiumActive => 'Premium активен — пользуйтесь!';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get signedIn => 'Вы вошли';

  @override
  String get syncedAutomatically => 'Синхронизируется автоматически';

  @override
  String get save => 'Сохранить';

  @override
  String get navHome => 'Главная';

  @override
  String get navTransactions => 'Операции';

  @override
  String get navSettings => 'Настройки';

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get transactionsTitle => 'Операции';

  @override
  String get periodDay => 'День';

  @override
  String get periodWeek => 'Неделя';

  @override
  String get periodMonth => 'Месяц';

  @override
  String get periodYear => 'Год';

  @override
  String get periodOther => 'Другое';

  @override
  String get periodToday => 'Сегодня';

  @override
  String get periodCustom => 'Период';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get income => 'Доход';

  @override
  String get expense => 'Расход';

  @override
  String get total => 'Всего';

  @override
  String get spendingByCategory => 'Траты по категориям';

  @override
  String get noExpenses => 'Нет расходов';

  @override
  String get noExpensesSubtitle => 'Добавьте операцию, чтобы увидеть разбивку';

  @override
  String get noTransactions => 'Нет операций';

  @override
  String get nothingInPeriod => 'За этот период пока ничего нет';

  @override
  String get loggingStreak => 'Серия записей';

  @override
  String get biggestThisMonth => 'Крупнейшие в этом месяце';

  @override
  String get dailySpending => 'Траты по дням';

  @override
  String get noSpendingThisMonth => 'В этом месяце трат пока нет';

  @override
  String get notEnoughHistory => 'Пока мало истории';

  @override
  String get sixMonthTrend => 'Тренд за 6 месяцев';

  @override
  String get legendIn => 'Приход';

  @override
  String get legendOut => 'Расход';

  @override
  String get recentActivity => 'Последние операции';

  @override
  String get totalBalance => 'Общий баланс';

  @override
  String get thisWeekVsLast => 'Эта неделя к прошлой';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get lastWeek => 'Прошлая неделя';

  @override
  String get whenYouSpend => 'Когда вы тратите';

  @override
  String youSpendMostOn(String day) {
    return 'Больше всего вы тратите $day';
  }

  @override
  String get weekdayMondays => 'по понедельникам';

  @override
  String get weekdayTuesdays => 'по вторникам';

  @override
  String get weekdayWednesdays => 'по средам';

  @override
  String get weekdayThursdays => 'по четвергам';

  @override
  String get weekdayFridays => 'по пятницам';

  @override
  String get weekdaySaturdays => 'по субботам';

  @override
  String get weekdaySundays => 'по воскресеньям';

  @override
  String get weekdayShortMon => 'Пн';

  @override
  String get weekdayShortTue => 'Вт';

  @override
  String get weekdayShortWed => 'Ср';

  @override
  String get weekdayShortThu => 'Чт';

  @override
  String get weekdayShortFri => 'Пт';

  @override
  String get weekdayShortSat => 'Сб';

  @override
  String get weekdayShortSun => 'Вс';

  @override
  String get statSaved => 'накоплено';

  @override
  String get statPerDay => 'в день';

  @override
  String get statBiggest => 'максимум';

  @override
  String get statThisMonth => 'в этом месяце';

  @override
  String get statActiveDays => 'активных дней';

  @override
  String get weeklyDigestTitle => 'Ваш AI-дайджест недели';

  @override
  String get weeklyDigestSubtitle =>
      'Куда ушли деньги, что изменить и ваш финансовый балл — простым языком.';

  @override
  String get add => 'Добавить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get done => 'Готово';

  @override
  String get name => 'Название';

  @override
  String get amount => 'Сумма';

  @override
  String get currency => 'Валюта';

  @override
  String get note => 'Заметка';

  @override
  String get transfer => 'Перевод';

  @override
  String get all => 'Все';

  @override
  String get addTransactionTitle => 'Новая операция';

  @override
  String get editTransactionTitle => 'Изменить операцию';

  @override
  String get deleteTransactionQuestion => 'Удалить операцию?';

  @override
  String get actionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get blockerNoAccount => 'Вы не добавили ни одного счёта';

  @override
  String get blockerNoCategory => 'Вы не добавили ни одной категории';

  @override
  String get blockerNoCurrency => 'Вы не добавили ни одной валюты';

  @override
  String get blockerNoSecondAccount => 'Нет второго счёта для перевода';

  @override
  String get blockerSameAccounts =>
      'Счёт списания и счёт зачисления должны отличаться';

  @override
  String activeDaysOf(int active, int total) {
    return '$active/$total дней';
  }

  @override
  String get mustBeNumber => 'Должно быть числом';

  @override
  String get mustBeMoreThanZero => 'Должно быть больше 0';

  @override
  String get mustBeAtLeast4 => 'Минимум 4 символа.';

  @override
  String get maximum30 => 'Максимум 30 символов.';

  @override
  String get cannotBeZero => 'Не может быть нулём';

  @override
  String get cannotBeNegative => 'Не может быть отрицательным';

  @override
  String get fromAccount => 'Со счёта';

  @override
  String get toAccount => 'На счёт';

  @override
  String get fromCategory => 'Из категории';

  @override
  String get toCategory => 'В категорию';

  @override
  String get setupBaseCurrencyTitle => 'Задайте базовую валюту';

  @override
  String get setupBaseCurrencyBody =>
      'Выберите валюту, в которой вы всё считаете. Другие валюты можно добавить позже.';

  @override
  String get setupBaseCurrencyAction => 'Задать базовую валюту';

  @override
  String get setupAccountTitle => 'Добавьте счёт';

  @override
  String get setupAccountBody =>
      'Создайте счёт (наличные, карта, банк…), чтобы записывать операции.';

  @override
  String get setupAccountAction => 'Добавить счёт';

  @override
  String get setupCategoryTitle => 'Добавьте категорию';

  @override
  String get setupCategoryBody =>
      'Создайте хотя бы одну категорию для операций.';

  @override
  String get setupCategoryAction => 'Добавить категорию';

  @override
  String get newAccountTitle => 'Новый счёт';

  @override
  String get newCategoryTitle => 'Новая категория';

  @override
  String get newCurrencyTitle => 'Новая валюта';

  @override
  String get accountCurrency => 'Валюта счёта';

  @override
  String get allCurrencies => 'Все валюты';

  @override
  String get chooseBaseCurrency => 'Выберите базовую валюту';

  @override
  String get rateToBase => 'Курс к базовой';

  @override
  String get exchangeRateToBase => 'Курс к базовой валюте';

  @override
  String rateEquals(String base, String rate, String target) {
    return '1 $base  равен  $rate $target';
  }

  @override
  String get rateHint => 'напр. 1,25 или 0,73';

  @override
  String get setBaseCurrencyTitle => 'Базовая валюта';

  @override
  String get haveNoItems => 'Пока пусто';

  @override
  String get addOne => 'Добавить';

  @override
  String get noAccountsYet => 'Счетов пока нет';

  @override
  String get noCategoriesYet => 'Категорий пока нет';

  @override
  String deleteItemQuestion(String what) {
    return 'Удалить «$what»?';
  }

  @override
  String get colorPicker => 'Выбор цвета';

  @override
  String get iconPicker => 'Выбор иконки';

  @override
  String get iconCategories => 'Категории иконок';

  @override
  String get other => 'Другое';

  @override
  String get uncategorized => 'Без категории';

  @override
  String get tryAgain => 'Повторить';

  @override
  String somethingWentWrongDetail(String error) {
    return 'Что-то пошло не так. $error';
  }

  @override
  String get insights => 'Инсайты';

  @override
  String get aiCoach => 'AI-коуч';

  @override
  String get forecast => 'Прогноз';

  @override
  String get thisMonthTitle => 'Этот месяц';

  @override
  String get topCategory => 'Топ-категория';

  @override
  String get netThisMonth => 'чистыми за месяц';

  @override
  String get healthScore => 'финансовый балл';

  @override
  String get noSpendYet => 'трат пока нет';

  @override
  String percentOfSpending(int pct) {
    return '$pct% всех трат';
  }

  @override
  String get projectedMonthEnd => 'прогноз на конец месяца';

  @override
  String get aiReadOnSpending => 'Разбор трат от ИИ + совет';

  @override
  String get tapToAnalyze => 'Нажмите для анализа';

  @override
  String get previewUnlock => 'Превью · открыть';

  @override
  String get overspending => 'Перерасход';

  @override
  String get headingNegative => 'Уходите в минус';

  @override
  String get onPaceToStayPositive => 'Идёте с плюсом';

  @override
  String inOutSummary(String inAmount, String outAmount) {
    return 'приход $inAmount · расход $outAmount';
  }

  @override
  String get aiInsightsTitle => 'AI-инсайты';

  @override
  String get aiCoachBadge => 'AI-КОУЧ';

  @override
  String get financialHealth => 'Финансовое здоровье';

  @override
  String get outOf100 => 'из 100';

  @override
  String get coachTip => 'Совет коуча';

  @override
  String get reAnalyze => 'Проанализировать заново';

  @override
  String get readingYourSpending => 'Изучаем ваши траты…';

  @override
  String get authNotConfigured =>
      'Синхронизация ещё не настроена — добавьте ключи Supabase, чтобы включить аккаунты.';

  @override
  String get aiErrorBackendOff =>
      'Для ИИ нужно настроить бэкенд (Supabase + ключ).';

  @override
  String get aiErrorNoCredit =>
      'У провайдера ИИ закончились средства. Пополните баланс на platform.openai.com → Billing и попробуйте снова.';

  @override
  String get aiErrorInvalidKey =>
      'Ключ ИИ на сервере недействителен. Задайте его заново: `supabase secrets set OPENAI_API_KEY=...`.';

  @override
  String get aiErrorKeyNotSet =>
      'ИИ ещё не настроен: задайте OPENAI_API_KEY в секретах Supabase.';

  @override
  String get aiErrorBadResponse => 'Неожиданный ответ ИИ.';

  @override
  String get spendingBreakdown => 'Разбивка трат';

  @override
  String get totalSpentThisMonth => 'Всего потрачено в этом месяце';

  @override
  String get noExpensesThisMonthYet => 'В этом месяце трат пока нет.';

  @override
  String acrossNCategories(int count) {
    return 'по $count категориям';
  }

  @override
  String get forecastBadge => 'ПРОГНОЗ';

  @override
  String get projectedMonthEndBalance => 'Прогноз баланса на конец месяца';

  @override
  String get onTrackGreen => 'Идёте к тому, чтобы закончить месяц в плюсе.';

  @override
  String get atThisPaceNegative => 'При таком темпе месяц закончится в минусе.';

  @override
  String get incomeThisMonth => 'Доход за месяц';

  @override
  String get spentSoFar => 'Потрачено на сейчас';

  @override
  String get projectedTotalSpend => 'Прогноз общих трат';

  @override
  String get dailySpendRate => 'Темп трат в день';

  @override
  String get daysLeftInMonth => 'Дней до конца месяца';

  @override
  String get netThisMonthTitle => 'Чистыми за месяц';

  @override
  String get whereItWent => 'Куда ушло';

  @override
  String youKeptPercent(int pct) {
    return 'Вы сохранили $pct% дохода.';
  }

  @override
  String youSpentMorePercent(int pct) {
    return 'Вы потратили на $pct% больше, чем заработали.';
  }

  @override
  String spendingUpVsLast(int pct) {
    return 'Траты выросли на $pct% к прошлому месяцу';
  }

  @override
  String spendingDownVsLast(int pct) {
    return 'Траты снизились на $pct% к прошлому месяцу';
  }

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get createYourAccount => 'Создайте аккаунт';

  @override
  String get authSubtitle =>
      'Синхронизируйте данные между телефоном и вебом и держите их в надёжной копии.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get password => 'Пароль';

  @override
  String get enterValidEmail => 'Введите корректный email.';

  @override
  String get passwordMin6 => 'Пароль должен быть не короче 6 символов.';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get newHereCreate => 'Впервые здесь? Создать аккаунт';

  @override
  String get signInToSync => 'Войдите, чтобы синхронизировать устройства';

  @override
  String get syncing => 'Синхронизация…';

  @override
  String get cloudSyncNotSetUp => 'Облачная синхронизация ещё не настроена';

  @override
  String get turnTrackingIntoPlan => 'Превратите учёт в план';

  @override
  String get paywallBody =>
      'Учёт показывает прошлое. Premium меняет то, что будет дальше — обычно подписка окупается уже в первую неделю, если вовремя ловить перерасход.';

  @override
  String get continueOnWeb => 'Продолжить в браузере';

  @override
  String get secureCheckout =>
      'Безопасная оплата в браузере — без комиссий App Store.';

  @override
  String get couldNotOpenBrowser => 'Не удалось открыть браузер.';

  @override
  String get unlockWithPremium => 'Открыть с Premium';

  @override
  String get featureAiCoachTitle => 'AI-коуч по деньгам';

  @override
  String get featureAiCoachBody =>
      'Личный разбор, где утекают деньги — и одно действие, чтобы это исправить.';

  @override
  String get featureForecastTitle => 'Прогноз на конец месяца';

  @override
  String get featureForecastBody =>
      'Видите, чем закончится месяц, пока ещё можно всё изменить.';

  @override
  String get featureHealthTitle => 'Финансовый балл';

  @override
  String get featureHealthBody =>
      'Одно число, которое говорит, всё ли идёт по плану — и что на него влияет.';

  @override
  String get featureAlertsTitle => 'Умные уведомления';

  @override
  String get featureAlertsBody =>
      'Подсказка до того, как категория выйдет за бюджет — ловите перерасход заранее.';

  @override
  String get featureSyncTitle => 'Синхронизация везде';

  @override
  String get featureSyncBody =>
      'Ваши деньги на телефоне и в вебе, всегда с резервной копией. Ничего не потеряется.';

  @override
  String get featureAskTitle => 'Спросите свои финансы';

  @override
  String get featureAskBody =>
      'Спрашивайте обычным языком и получайте ответ по своим же цифрам.';

  @override
  String get onboardTrackTitle => 'Записывайте каждую трату';

  @override
  String get onboardTrackBody =>
      'Запись расхода в пару касаний — даже прямо с виджета на экране «Домой». Никаких таблиц и трения.';

  @override
  String get onboardInsightsTitle => 'Видите, куда уходят деньги';

  @override
  String get onboardInsightsBody =>
      'Понятные графики и разбивки по месяцам превращают историю в выводы, по которым можно действовать.';

  @override
  String get onboardAiTitle => 'ИИ, который планирует наперёд';

  @override
  String get onboardAiBody =>
      'Персональный бюджет-коучинг, прогнозы трат и умные уведомления — ваши деньги на автопилоте.';

  @override
  String get skip => 'Пропустить';

  @override
  String get next => 'Далее';

  @override
  String get getStarted => 'Начать';

  @override
  String get onboardCurrencyBody =>
      'В этой валюте показываются все итоги и графики. Другие валюты можно добавить позже.';

  @override
  String get enterTheApp => 'Войти в приложение';

  @override
  String get pickCurrencyToContinue => 'Выберите валюту, чтобы продолжить';

  @override
  String get yourAccounts => 'Ваши счета';

  @override
  String get addAccountInSettings =>
      'Добавьте счёт в Настройках, чтобы видеть балансы';

  @override
  String acrossNAccounts(int count) {
    return 'по $count счетам';
  }

  @override
  String get widgetsTitle => 'Виджеты на экране';

  @override
  String get widgetsSubtitle =>
      'Записывайте трату в одно касание с домашнего экрана';

  @override
  String get widgetConfigIntro =>
      'Закрепите категории в виджете быстрого добавления. Кнопка с фиксированной суммой пишет трату мгновенно; пресеты дают выбрать частую сумму; либо откройте приложение, чтобы ввести любую сумму.';

  @override
  String get widgetOnYourWidget => 'В вашем виджете';

  @override
  String get widgetNoShortcuts => 'Пока не закреплено ни одной категории';

  @override
  String get widgetAddCategory => 'Добавить категорию';

  @override
  String get widgetAllPinned => 'Все категории уже закреплены';

  @override
  String get widgetPreviewEmpty => 'Добавьте категории, чтобы увидеть их здесь';

  @override
  String get widgetShortcutModeFixed => 'Фиксир.';

  @override
  String get widgetShortcutModePresets => 'Пресеты';

  @override
  String get widgetShortcutModeOpen => 'Каждый раз';

  @override
  String get widgetFixedAmountHint =>
      'Одно касание записывает ровно эту сумму.';

  @override
  String get widgetPresetsHint =>
      'Нажмите пресет, чтобы записать трату мгновенно.';

  @override
  String get widgetPresetsHintIncome =>
      'Нажмите пресет, чтобы записать доход мгновенно.';

  @override
  String get categoryType => 'Тип';

  @override
  String get widgetOpenHint =>
      'Сумма набирается прямо в виджете и сразу записывается.';

  @override
  String get widgetStepsTitle => 'Шаги суммы';

  @override
  String get widgetStepsHint =>
      'Оставьте пустым — подстроятся под ваши траты автоматически.';

  @override
  String get compactThousands => 'К';

  @override
  String get compactMillions => 'М';

  @override
  String get widgetGroupsIntro =>
      'Создавайте наборы категорий для виджета быстрого добавления. Зажмите виджет на экране → «Изменить виджет», чтобы выбрать, какой набор он показывает.';

  @override
  String get widgetGroupDefault => 'Основное';

  @override
  String get widgetAddGroup => 'Добавить набор';

  @override
  String get widgetGroupName => 'Название набора';

  @override
  String get widgetGroupNameHint => 'напр. Повседневное, Работа';

  @override
  String widgetGroupCategories(int count) {
    return '$count категорий';
  }

  @override
  String get editCategoryTitle => 'Изменить категорию';

  @override
  String get editAccountTitle => 'Изменить счёт';

  @override
  String get iconGroupAll => 'Все';

  @override
  String get iconGroupFinance => 'Финансы';

  @override
  String get iconGroupMovement => 'Транспорт';

  @override
  String get iconGroupFood => 'Еда';

  @override
  String get iconGroupRetail => 'Покупки';

  @override
  String get iconGroupHousing => 'Дом';

  @override
  String get iconGroupHealth => 'Здоровье';

  @override
  String get iconGroupOther => 'Прочее';

  @override
  String get widgetPreviewSmall => 'Маленький';

  @override
  String get widgetPreviewMedium => 'Средний';

  @override
  String get widgetAddPreset => 'Добавить сумму';

  @override
  String get selectCategory => 'Выберите категорию';

  @override
  String get quickAddTitle => 'Быстрое добавление';

  @override
  String get quickIncomeTitle => 'Быстрый доход';

  @override
  String get quickAddSaved => 'Сохранено';

  @override
  String get quickAddIncompleteSetup =>
      'Сначала добавьте категорию, счёт и базовую валюту.';

  @override
  String get widgetFlowExpense => 'Расход';

  @override
  String get widgetFlowIncome => 'Доход';

  @override
  String get widgetFlowQuestion => 'Что записывает виджет?';

  @override
  String get widgetFlowExpenseHint => 'Деньги уходят — трата.';

  @override
  String get widgetFlowIncomeHint =>
      'Деньги приходят — зарплата, подарок, возврат.';
}
