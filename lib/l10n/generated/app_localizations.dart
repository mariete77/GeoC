import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// App name
  ///
  /// In es, this message translates to:
  /// **'GeoQuiz Battle'**
  String get appTitle;

  /// Generic loading text
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// Retry button
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// Go home button
  ///
  /// In es, this message translates to:
  /// **'Ir al Inicio'**
  String get goHome;

  /// 404 error text
  ///
  /// In es, this message translates to:
  /// **'Página no encontrada'**
  String get pageNotFound;

  /// Explorer label above player name
  ///
  /// In es, this message translates to:
  /// **'EXPLORADOR'**
  String get explorer;

  /// Win streak badge
  ///
  /// In es, this message translates to:
  /// **'Streak: {count}'**
  String streak(int count);

  /// Global ranking label
  ///
  /// In es, this message translates to:
  /// **'CLASIFICACIÓN GLOBAL'**
  String get globalRanking;

  /// ELO score subtitle
  ///
  /// In es, this message translates to:
  /// **'Puntuación ELO'**
  String get eloScore;

  /// Quick Play game mode
  ///
  /// In es, this message translates to:
  /// **'Partida Rápida'**
  String get quickPlay;

  /// Quick Play description
  ///
  /// In es, this message translates to:
  /// **'Salta a una partida casual instantánea.'**
  String get quickPlayDesc;

  /// Ranked game mode
  ///
  /// In es, this message translates to:
  /// **'Clasificatoria'**
  String get ranked;

  /// Ranked description
  ///
  /// In es, this message translates to:
  /// **'Compite por ELO y sube en el ranking global.'**
  String get rankedDesc;

  /// Multiplayer game mode
  ///
  /// In es, this message translates to:
  /// **'Multijugador'**
  String get multiplayer;

  /// Multiplayer description
  ///
  /// In es, this message translates to:
  /// **'Enfréntate a otros jugadores en tiempo real.'**
  String get multiplayerDesc;

  /// Ghost Run game mode
  ///
  /// In es, this message translates to:
  /// **'Fantasma'**
  String get ghostRun;

  /// Ghost Run description
  ///
  /// In es, this message translates to:
  /// **'Practica contra las mejores partidas pasadas.'**
  String get ghostRunDesc;

  /// Leaderboard section title
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get leaderboard;

  /// Leaderboard card description
  ///
  /// In es, this message translates to:
  /// **'Mira tu posición respecto a los demás jugadores.'**
  String get leaderboardDesc;

  /// Loading leaderboard text
  ///
  /// In es, this message translates to:
  /// **'Cargando clasificación...'**
  String get leaderboardLoading;

  /// Error loading leaderboard
  ///
  /// In es, this message translates to:
  /// **'Error al cargar clasificación'**
  String get leaderboardError;

  /// Empty leaderboard text
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores todavía'**
  String get noPlayers;

  /// Your position label in leaderboard banner
  ///
  /// In es, this message translates to:
  /// **'TU POSICIÓN'**
  String get yourPosition;

  /// ELO abbreviation
  ///
  /// In es, this message translates to:
  /// **'ELO'**
  String get elo;

  /// Refers to current user in leaderboard
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get you;

  /// History section title
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// Match history card title
  ///
  /// In es, this message translates to:
  /// **'Historial de Partidas'**
  String get matchHistory;

  /// Match history card description
  ///
  /// In es, this message translates to:
  /// **'Revisa el resumen de tus batallas pasadas.'**
  String get matchHistoryDesc;

  /// See all button
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get seeAll;

  /// No matches played yet
  ///
  /// In es, this message translates to:
  /// **'Sin partidas aún'**
  String get noMatchesYet;

  /// Hint when no matches
  ///
  /// In es, this message translates to:
  /// **'Juega tu primera partida para ver tu historial.'**
  String get noMatchesHint;

  /// Wins label
  ///
  /// In es, this message translates to:
  /// **'Victorias'**
  String get victories;

  /// Losses label
  ///
  /// In es, this message translates to:
  /// **'Derrotas'**
  String get defeats;

  /// Win rate label
  ///
  /// In es, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// ELO change label
  ///
  /// In es, this message translates to:
  /// **'ELO'**
  String get eloChange;

  /// Victory result
  ///
  /// In es, this message translates to:
  /// **'¡Victoria!'**
  String get victory;

  /// Defeat result
  ///
  /// In es, this message translates to:
  /// **'Derrota'**
  String get defeat;

  /// Draw result
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get draw;

  /// Match history screen title
  ///
  /// In es, this message translates to:
  /// **'Historial de Partidas'**
  String get matchHistoryTitle;

  /// Filter: all matches
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// Filter: casual matches
  ///
  /// In es, this message translates to:
  /// **'Casual'**
  String get casual;

  /// Filter: ranked matches
  ///
  /// In es, this message translates to:
  /// **'Clasificatoria'**
  String get rankedFilter;

  /// You vs opponent label
  ///
  /// In es, this message translates to:
  /// **'Tú vs'**
  String get youVs;

  /// ELO change in match tile
  ///
  /// In es, this message translates to:
  /// **'ELO'**
  String get eloChangeLabel;

  /// No matches for selected filter
  ///
  /// In es, this message translates to:
  /// **'No hay partidas con este filtro'**
  String get noMatchesFilter;

  /// Quick actions section title
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get quickActions;

  /// Matchmaking screen title
  ///
  /// In es, this message translates to:
  /// **'Buscando partida...'**
  String get matchmakingTitle;

  /// Searching for opponent
  ///
  /// In es, this message translates to:
  /// **'Buscando oponente...'**
  String get matchmakingSearching;

  /// Cancel matchmaking
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get matchmakingCancel;

  /// Opponent found
  ///
  /// In es, this message translates to:
  /// **'¡Oponente encontrado!'**
  String get matchmakingFound;

  /// Login screen welcome
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a GeoC'**
  String get loginWelcome;

  /// Login screen subtitle
  ///
  /// In es, this message translates to:
  /// **'Demuestra tus conocimientos de geografía'**
  String get loginSubtitle;

  /// Google sign in button
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Google'**
  String get loginGoogle;

  /// Apple sign in button
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Apple'**
  String get loginApple;

  /// Anonymous login button
  ///
  /// In es, this message translates to:
  /// **'Continuar sin cuenta'**
  String get loginAnonymous;

  /// Next question button
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get gameNext;

  /// Finish game button
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get gameFinish;

  /// Game results title
  ///
  /// In es, this message translates to:
  /// **'Resultados'**
  String get gameResults;

  /// Points scored
  ///
  /// In es, this message translates to:
  /// **'{points} puntos'**
  String gamePoints(int points);

  /// Correct answer feedback
  ///
  /// In es, this message translates to:
  /// **'¡Correcto!'**
  String get gameCorrect;

  /// Incorrect answer feedback
  ///
  /// In es, this message translates to:
  /// **'Incorrecto'**
  String get gameIncorrect;

  /// Seconds left
  ///
  /// In es, this message translates to:
  /// **'{seconds}s'**
  String gameTimeLeft(int seconds);

  /// Type answer hint
  ///
  /// In es, this message translates to:
  /// **'Escribe tu respuesta...'**
  String get typeYourAnswer;

  /// Submit answer button
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get submitAnswer;

  /// Report question button
  ///
  /// In es, this message translates to:
  /// **'Reportar pregunta'**
  String get reportQuestion;

  /// Report reason label
  ///
  /// In es, this message translates to:
  /// **'Motivo del reporte'**
  String get reportReason;

  /// Report submitted confirmation
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. ¡Gracias!'**
  String get reportSubmitted;

  /// Friends screen title
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get friends;

  /// Add friend button
  ///
  /// In es, this message translates to:
  /// **'Añadir amigo'**
  String get addFriend;

  /// No friends message
  ///
  /// In es, this message translates to:
  /// **'No tienes amigos aún'**
  String get noFriends;

  /// No friends hint
  ///
  /// In es, this message translates to:
  /// **'Añade amigos para competir contra ellos.'**
  String get noFriendsHint;

  /// Online status
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get online;

  /// Offline status
  ///
  /// In es, this message translates to:
  /// **'Desconectado'**
  String get offline;

  /// Today label
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// Yesterday label
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// Days ago
  ///
  /// In es, this message translates to:
  /// **'hace {days} días'**
  String daysAgo(int days);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
