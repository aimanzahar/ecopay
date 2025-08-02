import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_zh.dart';

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
    Locale('ms'),
    Locale('ta'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'EcoPay'**
  String get appTitle;

  /// Text for eWallet balance section
  ///
  /// In en, this message translates to:
  /// **'eWallet balance'**
  String get ewalletBalance;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Button text for reloading balance
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Text for transaction history link
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Scan QR code button
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// Pay button
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// Transfer button
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// GO+ service button
  ///
  /// In en, this message translates to:
  /// **'GO+'**
  String get goPlus;

  /// Goals section
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Vouchers section
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get vouchers;

  /// One reward text
  ///
  /// In en, this message translates to:
  /// **'1 Reward'**
  String get oneReward;

  /// Three vouchers text
  ///
  /// In en, this message translates to:
  /// **'3 Vouchers'**
  String get threeVouchers;

  /// Highlights section title
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// Placeholder for promotional content
  ///
  /// In en, this message translates to:
  /// **'Promotional Content'**
  String get promotionalContent;

  /// Dialog title for editing balance
  ///
  /// In en, this message translates to:
  /// **'Edit Balance'**
  String get editBalance;

  /// Dialog text for amount input
  ///
  /// In en, this message translates to:
  /// **'Enter the amount to add to your balance:'**
  String get enterAmountToAdd;

  /// Label for amount input field
  ///
  /// In en, this message translates to:
  /// **'Amount (RM)'**
  String get amountRM;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Add balance button text
  ///
  /// In en, this message translates to:
  /// **'Add Balance'**
  String get addBalance;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBeGreaterThanZero;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed RM 10,000'**
  String get amountCannotExceed;

  /// Welcome message in EcoPay screen
  ///
  /// In en, this message translates to:
  /// **'🌱 Welcome to EcoPay'**
  String get welcomeToEcoPay;

  /// Subtitle in EcoPay screen
  ///
  /// In en, this message translates to:
  /// **'Your sustainable payment solution'**
  String get yourSustainablePaymentSolution;

  /// CO2 saved metric
  ///
  /// In en, this message translates to:
  /// **'CO₂ Saved'**
  String get co2Saved;

  /// Transactions metric
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// My contribution button
  ///
  /// In en, this message translates to:
  /// **'My Contribution'**
  String get myContribution;

  /// History button
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Gamification section title
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get gamification;

  /// Leaderboard feature
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Challenges feature
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// Achievements feature
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// EcoPayTree feature
  ///
  /// In en, this message translates to:
  /// **'EcoPayTree'**
  String get ecoPayTree;

  /// ESG Features section title
  ///
  /// In en, this message translates to:
  /// **'ESG Features'**
  String get esgFeatures;

  /// Environmental ESG category
  ///
  /// In en, this message translates to:
  /// **'Environmental'**
  String get environmental;

  /// Social ESG category
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// Governance ESG category
  ///
  /// In en, this message translates to:
  /// **'Governance'**
  String get governance;

  /// Carbon footprint section title
  ///
  /// In en, this message translates to:
  /// **'Carbon Footprint'**
  String get carbonFootprint;

  /// This month period
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Calculate button
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// Comparison with last month
  ///
  /// In en, this message translates to:
  /// **'↓ 23% vs last month'**
  String get vsLastMonth;

  /// Green rewards section title
  ///
  /// In en, this message translates to:
  /// **'Green Rewards'**
  String get greenRewards;

  /// Description for green rewards
  ///
  /// In en, this message translates to:
  /// **'Redeem points for sustainable products & services'**
  String get redeemPointsFor;

  /// Redeem button
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// Points needed for next reward
  ///
  /// In en, this message translates to:
  /// **'253 points to next reward'**
  String get pointsToNextReward;

  /// Sustainability tips section title
  ///
  /// In en, this message translates to:
  /// **'Sustainability Tips'**
  String get sustainabilityTips;

  /// Sustainability tip
  ///
  /// In en, this message translates to:
  /// **'Use digital receipts'**
  String get useDigitalReceipts;

  /// Sustainability tip description
  ///
  /// In en, this message translates to:
  /// **'Save up to 2.5kg CO₂ per year'**
  String get saveUpToCO2;

  /// Sustainability tip
  ///
  /// In en, this message translates to:
  /// **'Walk to nearby stores'**
  String get walkToNearbyStores;

  /// Sustainability tip description
  ///
  /// In en, this message translates to:
  /// **'Reduce transport emissions by 65%'**
  String get reduceTransportEmissions;

  /// Sustainability tip
  ///
  /// In en, this message translates to:
  /// **'Choose eco-friendly businesses'**
  String get chooseEcoFriendlyBusinesses;

  /// Sustainability tip description
  ///
  /// In en, this message translates to:
  /// **'Support sustainable practices'**
  String get supportSustainablePractices;

  /// Enable EcoPay switch text
  ///
  /// In en, this message translates to:
  /// **'Enable EcoPay'**
  String get enableEcoPay;

  /// Activate EcoPay title
  ///
  /// In en, this message translates to:
  /// **'Activate EcoPay'**
  String get activateEcoPay;

  /// EcoPay activation description
  ///
  /// In en, this message translates to:
  /// **'Round up your payments to support verified green projects. Track your CO₂ savings, earn rewards, and join a sustainability-driven community!'**
  String get roundUpPayments;

  /// Scan QR code screen title
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// QR scanner instruction
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a DUITNOW QR code'**
  String get pointCameraAtQR;

  /// Gallery selection instruction
  ///
  /// In en, this message translates to:
  /// **'Or tap the gallery icon to select an image'**
  String get tapGalleryIcon;

  /// Processing QR code message
  ///
  /// In en, this message translates to:
  /// **'Processing QR Code...'**
  String get processingQRCode;

  /// Leaderboard screen title
  ///
  /// In en, this message translates to:
  /// **'Eco Leaderboard'**
  String get ecoLeaderboard;

  /// Weekly tab
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly tab
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// All time tab
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// Friends tab
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// Current rank stat
  ///
  /// In en, this message translates to:
  /// **'Current Rank'**
  String get currentRank;

  /// Total points stat
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// This week stat
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Friends beat stat
  ///
  /// In en, this message translates to:
  /// **'Friends Beat'**
  String get friendsBeat;

  /// Points text
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get points;

  /// Add friends button
  ///
  /// In en, this message translates to:
  /// **'Add Friends'**
  String get addFriends;

  /// Achievements screen title
  ///
  /// In en, this message translates to:
  /// **'Your Eco Achievements'**
  String get yourEcoAchievements;

  /// Unlocked tab
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// In progress tab
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Categories tab
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Completed stat
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Points earned text
  ///
  /// In en, this message translates to:
  /// **'points earned'**
  String get pointsEarned;

  /// Bronze tier
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// Silver tier
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// Gold tier
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// Platinum tier
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// Diamond tier
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get diamond;

  /// AI assistant name
  ///
  /// In en, this message translates to:
  /// **'EcoPay Assistant'**
  String get ecoPayAssistant;

  /// AI assistant status
  ///
  /// In en, this message translates to:
  /// **'Powered by Trees 🌱'**
  String get poweredByTrees;

  /// AI assistant offline status
  ///
  /// In en, this message translates to:
  /// **'Offline mode 🌱'**
  String get offlineMode;

  /// Language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Bahasa Melayu language option
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get bahasaMelayu;

  /// Mandarin language option
  ///
  /// In en, this message translates to:
  /// **'中文 (简体)'**
  String get mandarin;

  /// Tamil language option
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get tamil;

  /// Language settings screen title
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// Loading message when changing language
  ///
  /// In en, this message translates to:
  /// **'Changing Language...'**
  String get changingLanguage;

  /// Success message after language change
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully!'**
  String get languageChanged;

  /// Selected indicator text
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// Description for English language
  ///
  /// In en, this message translates to:
  /// **'English (International)'**
  String get englishDescription;

  /// Description for Malay language
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu (Malaysia)'**
  String get malayDescription;

  /// Description for Chinese language
  ///
  /// In en, this message translates to:
  /// **'中文 (简体中文)'**
  String get chineseDescription;

  /// Description for Tamil language
  ///
  /// In en, this message translates to:
  /// **'தமிழ் (Tamil)'**
  String get tamilDescription;
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
      <String>['en', 'ms', 'ta', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'ta':
      return AppLocalizationsTa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
