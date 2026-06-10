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
    Locale('tr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'EduNoteAI'**
  String get appTitle;

  /// Home tab title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Notebooks tab title
  ///
  /// In en, this message translates to:
  /// **'Notebooks'**
  String get notebooksTitle;

  /// AI tab title
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// Settings tab title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Create notebook button
  ///
  /// In en, this message translates to:
  /// **'Create Notebook'**
  String get createNotebook;

  /// Notebook name input label
  ///
  /// In en, this message translates to:
  /// **'Notebook Name'**
  String get notebookName;

  /// Notebook name hint text
  ///
  /// In en, this message translates to:
  /// **'e.g. Biology 101 Notes'**
  String get notebookNameHint;

  /// Cover selection section title
  ///
  /// In en, this message translates to:
  /// **'Select Cover'**
  String get selectCover;

  /// Template selection section title
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// Blank paper template
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get templateBlank;

  /// Lined paper template
  ///
  /// In en, this message translates to:
  /// **'Lined'**
  String get templateLined;

  /// Grid/squared paper template
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get templateGrid;

  /// Dotted paper template
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get templateDotted;

  /// Isometric paper template
  ///
  /// In en, this message translates to:
  /// **'Isometric'**
  String get templateIsometric;

  /// Create action button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Rename action button
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search notebooks hint
  ///
  /// In en, this message translates to:
  /// **'Search notebooks...'**
  String get searchNotebooks;

  /// Recent notes section title
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// All notebooks section title
  ///
  /// In en, this message translates to:
  /// **'All Notebooks'**
  String get allNotebooks;

  /// Folders section title
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// Create folder button
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// Folder name input label
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No notebooks yet'**
  String get noNotebooks;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first notebook'**
  String get noNotebooksSubtitle;

  /// Pen tool
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// Highlighter tool
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get highlighter;

  /// Eraser tool
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// Text tool
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// Undo action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo action
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Export as PDF button
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportPdf;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;
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
    'that was used.',
  );
}
