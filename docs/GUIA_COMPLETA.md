# GeoQuiz Battle - Guía Completa de Desarrollo

## Índice
1. [Visión General del Proyecto](#1-visión-general-del-proyecto)
2. [Requisitos Previos](#2-requisitos-previos)
3. [Estructura del Proyecto Flutter](#3-estructura-del-proyecto-flutter)
4. [Configuración de Firebase](#4-configuración-de-firebase)
5. [Modelos de Datos](#5-modelos-de-datos)
6. [Autenticación](#6-autenticación)
7. [Sistema de Preguntas](#7-sistema-de-preguntas)
8. [Lógica del Juego](#8-lógica-del-juego)
9. [Sistema de Matchmaking](#9-sistema-de-matchmaking)
10. [Sistema ELO](#10-sistema-elo)
11. [Monetización y Suscripciones](#11-monetización-y-suscripciones)
12. [Cloud Functions](#12-cloud-functions)
13. [UI/UX Guidelines](#13-uiux-guidelines)
14. [Base de Datos de Preguntas](#14-base-de-datos-de-preguntas)
15. [Testing](#15-testing)
16. [Despliegue](#16-despliegue)

---

## 1. Visión General del Proyecto

### Descripción
Juego móvil de preguntas 1v1 sobre geografía con partidas de 1 minuto (10 preguntas, 10 segundos cada una).

### Características Principales
- **Modos de juego**: Partida rápida (casual) y Ranked
- **Matchmaking**: Tiempo real y asíncrono (ghostRun)
- **7 tipos de preguntas**: Siluetas, banderas, capitales, población, ríos, fotos de ciudades, extensión
- **Sistema ELO**: Ranking competitivo basado en rendimiento
- **Modelo Freemium**: 1 casual + 1 ranked gratis/día, suscripción para 5 ranked/día

### Stack Tecnológico
- **Frontend**: Flutter 3.x (Dart)
- **State Management**: Riverpod 2.x
- **Backend**: Firebase (Auth, Firestore, Functions, Storage)
- **Payments**: RevenueCat
- **Analytics**: Firebase Analytics

---

## 2. Requisitos Previos

### Herramientas Necesarias
```bash
# Flutter SDK (3.16+)
flutter --version

# Firebase CLI
npm install -g firebase-tools
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Cuentas Necesarias
- [ ] Cuenta de Firebase (Google Cloud)
- [ ] Apple Developer Account (para iOS)
- [ ] Google Play Console (para Android)
- [ ] RevenueCat Account (para suscripciones)

### Crear Proyecto Flutter
```bash
flutter create --org com.tuempresa geoquiz_battle
cd geoquiz_battle
```

---

## 3. Estructura del Proyecto Flutter

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # Constantes globales
│   │   ├── firebase_constants.dart  # Nombres de colecciones
│   │   └── game_constants.dart      # Tiempos, límites, etc.
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── utils/
│   │   ├── elo_calculator.dart
│   │   ├── validators.dart
│   │   └── extensions.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── data/
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── auth_remote_datasource.dart
│   │   │   ├── user_remote_datasource.dart
│   │   │   ├── match_remote_datasource.dart
│   │   │   └── question_remote_datasource.dart
│   │   └── local/
│   │       └── preferences_datasource.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── match_model.dart
│   │   ├── question_model.dart
│   │   ├── answer_model.dart
│   │   └── ghost_run_model.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── user_repository_impl.dart
│       ├── match_repository_impl.dart
│       └── question_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── match.dart
│   │   ├── question.dart
│   │   └── answer.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── match_repository.dart
│   │   └── question_repository.dart
│   └── usecases/
│       ├── auth/
│       │   ├── sign_in_with_google.dart
│       │   ├── sign_in_with_apple.dart
│       │   └── sign_out.dart
│       ├── match/
│       │   ├── join_matchmaking_queue.dart
│       │   ├── leave_matchmaking_queue.dart
│       │   ├── submit_answer.dart
│       │   └── get_match_stream.dart
│       └── user/
│           ├── get_user_profile.dart
│           └── update_user_stats.dart
│
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── match_provider.dart
│   │   ├── game_provider.dart
│   │   └── subscription_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── widgets/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   ├── matchmaking/
│   │   │   ├── matchmaking_screen.dart
│   │   │   └── widgets/
│   │   ├── game/
│   │   │   ├── game_screen.dart
│   │   │   └── widgets/
│   │   │       ├── question_card.dart
│   │   │       ├── silhouette_question.dart
│   │   │       ├── flag_question.dart
│   │   │       ├── capital_question.dart
│   │   │       ├── population_question.dart
│   │   │       ├── river_question.dart
│   │   │       ├── city_photo_question.dart
│   │   │       ├── area_question.dart
│   │   │       ├── timer_widget.dart
│   │   │       └── answer_options.dart
│   │   ├── results/
│   │   │   ├── results_screen.dart
│   │   │   └── widgets/
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── widgets/
│   │   ├── leaderboard/
│   │   │   ├── leaderboard_screen.dart
│   │   │   └── widgets/
│   │   └── subscription/
│   │       ├── subscription_screen.dart
│   │       └── widgets/
│   └── widgets/
│       ├── common/
│       │   ├── loading_widget.dart
│       │   ├── error_widget.dart
│       │   └── custom_button.dart
│       └── animations/
│           ├── countdown_animation.dart
│           └── score_animation.dart
│
└── services/
    ├── firebase_service.dart
    ├── audio_service.dart
    ├── notification_service.dart
    └── analytics_service.dart
```

### pubspec.yaml - Dependencias
```yaml
name: geoquiz_battle
description: Geography Quiz Battle Game
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_database: ^10.4.0  # Para matchmaking rápido
  firebase_analytics: ^10.8.0

  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Auth
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0

  # Payments
  purchases_flutter: ^6.17.0  # RevenueCat

  # UI
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  lottie: ^3.0.0

  # Utils
  uuid: ^4.3.1
  intl: ^0.18.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  equatable: ^2.0.5
  dartz: ^0.10.1

  # Audio
  audioplayers: ^5.2.1

  # Storage
  shared_preferences: ^2.2.2

  # Routing
  go_router: ^13.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  mockito: ^5.4.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/silhouettes/
    - assets/audio/
    - assets/lottie/
```

---

## 4. Configuración de Firebase

### Paso 4.1: Crear Proyecto en Firebase Console
1. Ir a https://console.firebase.google.com
2. Crear nuevo proyecto: "geoquiz-battle"
3. Habilitar Google Analytics

### Paso 4.2: Configurar FlutterFire
```bash
flutterfire configure --project=geoquiz-battle
```

### Paso 4.3: Inicializar Firebase en main.dart
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: GeoQuizBattleApp(),
    ),
  );
}
```

### Paso 4.4: Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Funciones helper
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isParticipant(match) {
      return request.auth.uid in match.data.players;
    }

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['elo', 'stats', 'subscription']);
      // elo, stats y subscription solo se actualizan via Cloud Functions
    }

    // Matches
    match /matches/{matchId} {
      allow read: if isAuthenticated() && isParticipant(resource);
      allow create: if false; // Solo Cloud Functions
      allow update: if isAuthenticated() && isParticipant(resource) &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['answers']);
    }

    // Match Answers (subcolección)
    match /matches/{matchId}/answers/{oderId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(oderId);
      allow update: if false;
    }

    // Questions - Solo lectura
    match /questions/{questionId} {
      allow read: if isAuthenticated();
      allow write: if false; // Solo admin via console
    }

    // Ghost Runs
    match /ghostRuns/{oderId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(oderId);
      allow update, delete: if false;
    }
  }
}
```

### Paso 4.5: Realtime Database Rules (Matchmaking)
```json
{
  "rules": {
    "matchmaking": {
      "queue": {
        "$oderId": {
          ".read": "auth != null",
          ".write": "auth != null && auth.uid === $oderId",
          ".validate": "newData.hasChildren(['elo', 'timestamp', 'mode'])"
        }
      }
    }
  }
}
```

### Paso 4.6: Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /silhouettes/{fileName} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /flags/{fileName} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /cities/{fileName} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /avatars/{oderId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == oderId;
    }
  }
}
```

---

## 5. Modelos de Datos

### 5.1 User Model
```dart
// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String oderId,
    required String displayName,
    String? email,
    String? photoUrl,
    @Default(1000) int elo,
    @Default(UserStats()) UserStats stats,
    @Default(Subscription()) Subscription subscription,
    @Default(DailyGames()) DailyGames dailyGames,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      'userId': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'lastLoginAt': data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }
}

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int totalGames,
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int totalCorrectAnswers,
    @Default(0) int currentWinStreak,
    @Default(0) int bestWinStreak,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    @Default('free') String type, // 'free', 'premium'
    DateTime? expiresAt,
    @Default(false) bool isActive,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

@freezed
class DailyGames with _$DailyGames {
  const factory DailyGames({
    @Default(0) int casualPlayed,
    @Default(0) int rankedPlayed,
    required DateTime date,
  }) = _DailyGames;

  factory DailyGames.fromJson(Map<String, dynamic> json) =>
      _$DailyGamesFromJson(json);

  factory DailyGames.today() => DailyGames(
    date: DateTime.now(),
  );
}
```

### 5.2 Question Model
```dart
// lib/data/models/question_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

enum QuestionType {
  silhouette,    // Tipo 1
  flag,          // Tipo 2
  capital,       // Tipo 3
  population,    // Tipo 4
  river,         // Tipo 5
  cityPhoto,     // Tipo 6
  area,          // Tipo 7
}

enum Difficulty { easy, medium, hard }

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    required QuestionType type,
    required Difficulty difficulty,
    required String correctAnswer,
    required List<String> options,
    String? imageUrl,
    String? questionText,
    Map<String, dynamic>? extraData, // Para datos específicos (población, área, etc.)
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}
```

### 5.3 Match Model
```dart
// lib/data/models/match_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

enum MatchStatus { waiting, active, finished, cancelled }
enum MatchMode { realtime, async }
enum MatchType { casual, ranked }

@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    required List<String> players,
    required MatchMode mode,
    required MatchType type,
    required MatchStatus status,
    required List<String> questionIds,
    @Default({}) Map<String, List<AnswerModel>> answers,
    MatchResult? result,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }
}

@freezed
class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    required int questionIndex,
    required String selectedAnswer,
    required bool isCorrect,
    required int timeMs, // Tiempo en milisegundos
    required DateTime answeredAt,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerModelFromJson(json);
}

@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    String? oderId, // null si empate
    required Map<String, int> scores, // oderId -> puntuación
    required Map<String, int> eloChanges, // oderId -> cambio de ELO
    required Map<String, int> newElo, // oderId -> nuevo ELO
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);
}
```

### 5.4 Ghost Run Model
```dart
// lib/data/models/ghost_run_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ghost_run_model.freezed.dart';
part 'ghost_run_model.g.dart';

@freezed
class GhostRunModel with _$GhostRunModel {
  const factory GhostRunModel({
    required String oderId,
    required String oderId,
    required int elo,
    required List<String> questionIds,
    required List<GhostAnswerModel> answers,
    required DateTime createdAt,
  }) = _GhostRunModel;

  factory GhostRunModel.fromJson(Map<String, dynamic> json) =>
      _$GhostRunModelFromJson(json);
}

@freezed
class GhostAnswerModel with _$GhostAnswerModel {
  const factory GhostAnswerModel({
    required int questionIndex,
    required bool isCorrect,
    required int timeMs,
  }) = _GhostAnswerModel;

  factory GhostAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$GhostAnswerModelFromJson(json);
}
```

---

## 6. Autenticación

### 6.1 Auth Repository
```dart
// lib/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  User? get currentUser;
}
```

### 6.2 Auth Repository Implementation
```dart
// lib/data/repositories/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(AuthFailure('Google sign in cancelled'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Crear o actualizar usuario en Firestore
      await _createOrUpdateUser(user);

      return Right(User.fromFirebaseUser(user));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user!;

      await _createOrUpdateUser(user);

      return Right(User.fromFirebaseUser(user));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  Future<void> _createOrUpdateUser(firebase.User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Nuevo usuario
      await userDoc.set({
        'displayName': firebaseUser.displayName ?? 'Player',
        'email': firebaseUser.email,
        'photoUrl': firebaseUser.photoURL,
        'elo': 1000,
        'stats': {
          'totalGames': 0,
          'wins': 0,
          'losses': 0,
          'draws': 0,
          'totalCorrectAnswers': 0,
          'currentWinStreak': 0,
          'bestWinStreak': 0,
        },
        'subscription': {
          'type': 'free',
          'isActive': false,
        },
        'dailyGames': {
          'casualPlayed': 0,
          'rankedPlayed': 0,
          'date': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Usuario existente - actualizar último login
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
  }
}
```

### 6.3 Auth Provider (Riverpod)
```dart
// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl();
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.loading();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithApple();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}
```

---

## 7. Sistema de Preguntas

### 7.1 Question Repository
```dart
// lib/data/repositories/question_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  QuestionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<QuestionModel>> getRandomQuestions({
    int count = 10,
    List<QuestionType>? types,
    Difficulty? maxDifficulty,
  }) async {
    // Obtener todas las preguntas elegibles
    Query query = _firestore.collection('questions');

    if (types != null && types.isNotEmpty) {
      query = query.where('type', whereIn: types.map((t) => t.name).toList());
    }

    final snapshot = await query.get();
    final allQuestions = snapshot.docs
        .map((doc) => QuestionModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();

    // Mezclar y seleccionar
    allQuestions.shuffle(_random);

    // Asegurar variedad de tipos
    return _selectBalancedQuestions(allQuestions, count);
  }

  List<QuestionModel> _selectBalancedQuestions(
    List<QuestionModel> questions,
    int count,
  ) {
    final selected = <QuestionModel>[];
    final usedTypes = <QuestionType>{};

    // Primera pasada: un tipo de cada
    for (final q in questions) {
      if (!usedTypes.contains(q.type) && selected.length < count) {
        selected.add(q);
        usedTypes.add(q.type);
      }
      if (selected.length >= 7) break; // 7 tipos máximo
    }

    // Segunda pasada: completar hasta 10
    for (final q in questions) {
      if (!selected.contains(q) && selected.length < count) {
        selected.add(q);
      }
      if (selected.length >= count) break;
    }

    selected.shuffle(_random);
    return selected;
  }

  @override
  Future<QuestionModel> getQuestionById(String id) async {
    final doc = await _firestore.collection('questions').doc(id).get();
    return QuestionModel.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }
}
```

### 7.2 Question Widgets
```dart
// lib/presentation/screens/game/widgets/question_card.dart
import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int questionNumber;
  final Function(String) onAnswer;
  final int remainingTimeMs;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswer,
    required this.remainingTimeMs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con número y timer
            _buildHeader(),
            const SizedBox(height: 20),

            // Contenido específico por tipo
            Expanded(child: _buildQuestionContent()),

            const SizedBox(height: 20),

            // Opciones de respuesta
            _buildOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Pregunta $questionNumber/10',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        TimerWidget(remainingTimeMs: remainingTimeMs),
      ],
    );
  }

  Widget _buildQuestionContent() {
    switch (question.type) {
      case QuestionType.silhouette:
        return SilhouetteQuestion(imageUrl: question.imageUrl!);
      case QuestionType.flag:
        return FlagQuestion(countryCode: question.extraData!['countryCode']);
      case QuestionType.capital:
        return CapitalQuestion(questionText: question.questionText!);
      case QuestionType.population:
        return PopulationQuestion(
          countries: List<String>.from(question.extraData!['countries']),
          data: Map<String, int>.from(question.extraData!['data']),
        );
      case QuestionType.river:
        return RiverQuestion(questionText: question.questionText!);
      case QuestionType.cityPhoto:
        return CityPhotoQuestion(imageUrl: question.imageUrl!);
      case QuestionType.area:
        return AreaQuestion(
          countries: List<String>.from(question.extraData!['countries']),
        );
    }
  }

  Widget _buildOptions() {
    return Column(
      children: question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onAnswer(option),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(option),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

### 7.3 Silhouette Question Widget
```dart
// lib/presentation/screens/game/widgets/silhouette_question.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SilhouetteQuestion extends StatelessWidget {
  final String imageUrl;

  const SilhouetteQuestion({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Qué país es?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            // Aplicar filtro negro a la silueta
            color: Colors.black,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}
```

### 7.4 Flag Question Widget
```dart
// lib/presentation/screens/game/widgets/flag_question.dart
import 'package:flutter/material.dart';

class FlagQuestion extends StatelessWidget {
  final String countryCode;

  const FlagQuestion({super.key, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    // Usar flagcdn.com para banderas
    final flagUrl = 'https://flagcdn.com/w320/${countryCode.toLowerCase()}.png';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿De qué país es esta bandera?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: flagUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 7.5 Timer Widget
```dart
// lib/presentation/screens/game/widgets/timer_widget.dart
import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  final int remainingTimeMs;
  static const int totalTimeMs = 10000; // 10 segundos

  const TimerWidget({super.key, required this.remainingTimeMs});

  @override
  Widget build(BuildContext context) {
    final seconds = (remainingTimeMs / 1000).ceil();
    final progress = remainingTimeMs / totalTimeMs;

    Color timerColor;
    if (progress > 0.5) {
      timerColor = Colors.green;
    } else if (progress > 0.25) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.red;
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(timerColor),
          ),
          Center(
            child: Text(
              '$seconds',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: timerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. Lógica del Juego

### 8.1 Game Constants
```dart
// lib/core/constants/game_constants.dart
class GameConstants {
  static const int questionsPerMatch = 10;
  static const int secondsPerQuestion = 10;
  static const int millisecondsPerQuestion = 10000;
  static const int matchDurationSeconds = 100; // 10 preguntas * 10 segundos

  // Límites diarios
  static const int freeCasualGamesPerDay = 1;
  static const int freeRankedGamesPerDay = 1;
  static const int premiumRankedGamesPerDay = 5;

  // ELO
  static const int initialElo = 1000;
  static const int minElo = 100;
  static const int kFactorNew = 32;
  static const int kFactorEstablished = 16;
  static const int newPlayerThreshold = 30; // partidas
  static const int matchmakingEloRange = 200;
}
```

### 8.2 Game State Provider
```dart
// lib/presentation/providers/game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum GamePhase { loading, ready, playing, finished }

@freezed
class GameState with _$GameState {
  const factory GameState({
    required GamePhase phase,
    required List<QuestionModel> questions,
    required int currentQuestionIndex,
    required List<AnswerModel> myAnswers,
    required Map<String, List<AnswerModel>> opponentAnswers,
    required int remainingTimeMs,
    MatchModel? match,
    String? oderId,
  }) = _GameState;

  factory GameState.initial() => const GameState(
    phase: GamePhase.loading,
    questions: [],
    currentQuestionIndex: 0,
    myAnswers: [],
    opponentAnswers: {},
    remainingTimeMs: GameConstants.millisecondsPerQuestion,
  );
}

@riverpod
class GameNotifier extends _$GameNotifier {
  Timer? _questionTimer;
  StreamSubscription? _matchSubscription;

  @override
  GameState build() {
    ref.onDispose(() {
      _questionTimer?.cancel();
      _matchSubscription?.cancel();
    });
    return GameState.initial();
  }

  Future<void> initializeMatch(String matchId) async {
    state = state.copyWith(phase: GamePhase.loading);

    final matchRepo = ref.read(matchRepositoryProvider);
    final questionRepo = ref.read(questionRepositoryProvider);

    // Obtener match
    final match = await matchRepo.getMatch(matchId);

    // Obtener preguntas
    final questions = await Future.wait(
      match.questionIds.map((id) => questionRepo.getQuestionById(id)),
    );

    state = state.copyWith(
      phase: GamePhase.ready,
      match: match,
      questions: questions,
    );

    // Escuchar actualizaciones del match (para tiempo real)
    if (match.mode == MatchMode.realtime) {
      _matchSubscription = matchRepo.watchMatch(matchId).listen((updatedMatch) {
        state = state.copyWith(
          match: updatedMatch,
          opponentAnswers: updatedMatch.answers,
        );
      });
    }
  }

  void startGame() {
    state = state.copyWith(
      phase: GamePhase.playing,
      currentQuestionIndex: 0,
      remainingTimeMs: GameConstants.millisecondsPerQuestion,
    );
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        final newTime = state.remainingTimeMs - 100;

        if (newTime <= 0) {
          // Tiempo agotado - registrar como sin respuesta
          _submitAnswer(null);
        } else {
          state = state.copyWith(remainingTimeMs: newTime);
        }
      },
    );
  }

  Future<void> submitAnswer(String selectedAnswer) async {
    _questionTimer?.cancel();
    await _submitAnswer(selectedAnswer);
  }

  Future<void> _submitAnswer(String? selectedAnswer) async {
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;
    final timeSpent = GameConstants.millisecondsPerQuestion - state.remainingTimeMs;

    final answer = AnswerModel(
      questionIndex: state.currentQuestionIndex,
      selectedAnswer: selectedAnswer ?? '',
      isCorrect: isCorrect,
      timeMs: timeSpent,
      answeredAt: DateTime.now(),
    );

    // Guardar respuesta localmente
    final updatedAnswers = [...state.myAnswers, answer];
    state = state.copyWith(myAnswers: updatedAnswers);

    // Enviar a Firebase
    if (state.match != null) {
      final matchRepo = ref.read(matchRepositoryProvider);
      await matchRepo.submitAnswer(state.match!.id, answer);
    }

    // Siguiente pregunta o finalizar
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        remainingTimeMs: GameConstants.millisecondsPerQuestion,
      );
      _startQuestionTimer();
    } else {
      _finishGame();
    }
  }

  void _finishGame() {
    _questionTimer?.cancel();
    state = state.copyWith(phase: GamePhase.finished);

    // Calcular resultado (en Cloud Function para modo ranked)
    if (state.match?.mode == MatchMode.async) {
      _calculateAsyncResult();
    }
    // Para realtime, Cloud Function calcula cuando ambos terminan
  }

  void _calculateAsyncResult() {
    // Comparar con ghostRun
    // ...
  }
}
```

### 8.3 Game Screen
```dart
// lib/presentation/screens/game/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String matchId;

  const GameScreen({super.key, required this.matchId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameNotifierProvider.notifier).initializeMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: _buildContent(gameState),
      ),
    );
  }

  Widget _buildContent(GameState state) {
    switch (state.phase) {
      case GamePhase.loading:
        return const Center(child: CircularProgressIndicator());

      case GamePhase.ready:
        return _buildReadyScreen(state);

      case GamePhase.playing:
        return _buildGameScreen(state);

      case GamePhase.finished:
        return _buildFinishedScreen(state);
    }
  }

  Widget _buildReadyScreen(GameState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡Partida lista!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text('${state.questions.length} preguntas'),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              ref.read(gameNotifierProvider.notifier).startGame();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text('¡Comenzar!', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen(GameState state) {
    final currentQuestion = state.questions[state.currentQuestionIndex];

    return Column(
      children: [
        // Barra de progreso
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.questions.length,
        ),

        // Puntuaciones en tiempo real (si aplica)
        if (state.match?.mode == MatchMode.realtime)
          _buildScoreHeader(state),

        // Pregunta
        Expanded(
          child: QuestionCard(
            question: currentQuestion,
            questionNumber: state.currentQuestionIndex + 1,
            remainingTimeMs: state.remainingTimeMs,
            onAnswer: (answer) {
              ref.read(gameNotifierProvider.notifier).submitAnswer(answer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHeader(GameState state) {
    final myScore = state.myAnswers.where((a) => a.isCorrect).length;
    final opponentId = state.match!.players
        .firstWhere((id) => id != state.userId);
    final opponentAnswers = state.opponentAnswers[opponentId] ?? [];
    final opponentScore = opponentAnswers.where((a) => a.isCorrect).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Tú'),
              Text(
                '$myScore',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text('VS', style: TextStyle(fontSize: 20)),
          Column(
            children: [
              const Text('Oponente'),
              Text(
                '$opponentScore',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen(GameState state) {
    final myScore = state.myAnswers.where((a) => a.isCorrect).length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡Partida terminada!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Tu puntuación: $myScore / ${state.questions.length}',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ResultsScreen(
                    matchId: state.match!.id,
                  ),
                ),
              );
            },
            child: const Text('Ver resultados'),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. Sistema de Matchmaking

### 9.1 Matchmaking Service
```dart
// lib/services/matchmaking_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MatchmakingService {
  final FirebaseDatabase _realtimeDb;
  final FirebaseFirestore _firestore;
  StreamSubscription? _queueListener;
  Timer? _matchmakingTimer;

  MatchmakingService({
    FirebaseDatabase? realtimeDb,
    FirebaseFirestore? firestore,
  })  : _realtimeDb = realtimeDb ?? FirebaseDatabase.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Unirse a la cola de matchmaking
  Future<void> joinQueue({
    required String oderId,
    required int elo,
    required MatchMode mode,
    required MatchType type,
  }) async {
    final queueRef = _realtimeDb.ref('matchmaking/queue/$oderId');

    await queueRef.set({
      'elo': elo,
      'mode': mode.name,
      'type': type.name,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Salir de la cola
  Future<void> leaveQueue(String oderId) async {
    _queueListener?.cancel();
    _matchmakingTimer?.cancel();
    await _realtimeDb.ref('matchmaking/queue/$oderId').remove();
  }

  /// Escuchar cuando se encuentra un match
  Stream<String?> watchForMatch(String oderId) {
    return _firestore
        .collection('matches')
        .where('players', arrayContains: oderId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs.first.id;
        });
  }
}
```

### 9.2 Cloud Function - Matchmaking (functions/src/matchmaking.ts)
```typescript
// functions/src/matchmaking.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const rtdb = admin.database();

// Trigger cuando alguien entra en la cola
export const onQueueJoin = functions.database
  .ref('/matchmaking/queue/{oderId}')
  .onCreate(async (snapshot, context) => {
    const oderId = context.params.oderId;
    const playerData = snapshot.val();
    const playerElo = playerData.elo;
    const mode = playerData.mode;
    const type = playerData.type;

    // Buscar oponente en rango de ELO
    const queueRef = rtdb.ref('matchmaking/queue');
    const queueSnapshot = await queueRef.once('value');
    const queue = queueSnapshot.val() || {};

    let bestMatch: { oderId: string; elo: number } | null = null;
    let smallestEloDiff = Infinity;

    for (const [oderId, data] of Object.entries(queue)) {
      if (oderId === oderId) continue;

      const candidateData = data as any;
      if (candidateData.mode !== mode || candidateData.type !== type) continue;

      const eloDiff = Math.abs(candidateData.elo - playerElo);

      if (eloDiff <= 200 && eloDiff < smallestEloDiff) {
        smallestEloDiff = eloDiff;
        bestMatch = { oderId, elo: candidateData.elo };
      }
    }

    if (bestMatch) {
      // Crear match
      await createMatch(
        [oderId, bestMatch.oderId],
        mode as 'realtime' | 'async',
        type as 'casual' | 'ranked'
      );

      // Eliminar ambos de la cola
      await queueRef.child(oderId).remove();
      await queueRef.child(bestMatch.oderId).remove();
    }
  });

async function createMatch(
  playerIds: string[],
  mode: 'realtime' | 'async',
  type: 'casual' | 'ranked'
): Promise<string> {
  // Obtener 10 preguntas aleatorias
  const questionsSnapshot = await db.collection('questions').get();
  const allQuestions = questionsSnapshot.docs.map(doc => doc.id);
  const shuffled = allQuestions.sort(() => Math.random() - 0.5);
  const selectedQuestions = shuffled.slice(0, 10);

  // Crear documento del match
  const matchRef = await db.collection('matches').add({
    players: playerIds,
    mode,
    type,
    status: 'waiting',
    questionIds: selectedQuestions,
    answers: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return matchRef.id;
}

// Cleanup: eliminar de cola después de 60 segundos sin match
export const cleanupQueue = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const queueRef = rtdb.ref('matchmaking/queue');
    const snapshot = await queueRef.once('value');
    const queue = snapshot.val() || {};

    const now = Date.now();
    const timeout = 60000; // 60 segundos

    const updates: Record<string, null> = {};

    for (const [oderId, data] of Object.entries(queue)) {
      const playerData = data as any;
      if (now - playerData.timestamp > timeout) {
        updates[oderId] = null;
      }
    }

    if (Object.keys(updates).length > 0) {
      await queueRef.update(updates);
    }
  });
```

### 9.3 Async Matchmaking (Ghost Runs)
```dart
// lib/services/async_match_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AsyncMatchService {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  AsyncMatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Buscar un ghost run para jugar contra él
  Future<GhostRunModel?> findGhostRun({
    required String oderId,
    required int playerElo,
  }) async {
    // Buscar ghost runs en rango de ELO similar
    final minElo = playerElo - 200;
    final maxElo = playerElo + 200;

    final snapshot = await _firestore
        .collection('ghostRuns')
        .where('elo', isGreaterThanOrEqualTo: minElo)
        .where('elo', isLessThanOrEqualTo: maxElo)
        .where('userId', isNotEqualTo: oderId) // No jugar contra ti mismo
        .orderBy('elo')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    if (snapshot.docs.isEmpty) {
      // Si no hay ghost runs en rango, buscar cualquiera
      final fallbackSnapshot = await _firestore
          .collection('ghostRuns')
          .where('userId', isNotEqualTo: oderId)
          .orderBy('userId')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (fallbackSnapshot.docs.isEmpty) return null;

      final randomIndex = _random.nextInt(fallbackSnapshot.docs.length);
      return GhostRunModel.fromFirestore(fallbackSnapshot.docs[randomIndex]);
    }

    // Seleccionar uno aleatorio del rango
    final randomIndex = _random.nextInt(snapshot.docs.length);
    return GhostRunModel.fromFirestore(snapshot.docs[randomIndex]);
  }

  /// Guardar un ghost run después de jugar
  Future<void> saveGhostRun({
    required String oderId,
    required int elo,
    required List<String> questionIds,
    required List<AnswerModel> answers,
  }) async {
    final ghostAnswers = answers.map((a) => GhostAnswerModel(
      questionIndex: a.questionIndex,
      isCorrect: a.isCorrect,
      timeMs: a.timeMs,
    )).toList();

    final runId = '${oderId}_${DateTime.now().millisecondsSinceEpoch}';

    await _firestore.collection('ghostRuns').doc(runId).set({
      'userId': oderId,
      'elo': elo,
      'questionIds': questionIds,
      'answers': ghostAnswers.map((a) => a.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Limpiar ghost runs antiguos del mismo usuario (mantener últimos 5)
    final oldRuns = await _firestore
        .collection('ghostRuns')
        .where('userId', isEqualTo: oderId)
        .orderBy('createdAt', descending: true)
        .get();

    if (oldRuns.docs.length > 5) {
      final toDelete = oldRuns.docs.sublist(5);
      for (final doc in toDelete) {
        await doc.reference.delete();
      }
    }
  }

  /// Comparar resultados con ghost run
  MatchResult compareWithGhost({
    required String oderId,
    required int playerElo,
    required List<AnswerModel> playerAnswers,
    required GhostRunModel ghostRun,
  }) {
    final playerScore = playerAnswers.where((a) => a.isCorrect).length;
    final ghostScore = ghostRun.answers.where((a) => a.isCorrect).length;

    String? oderId;
    if (playerScore > ghostScore) {
      oderId = oderId;
    } else if (ghostScore > playerScore) {
      oderId = ghostRun.oderId;
    }
    // null = empate

    // Calcular cambio de ELO
    final eloCalculator = EloCalculator();
    final playerResult = playerScore / 10.0;
    final ghostResult = ghostScore / 10.0;

    final playerEloChange = eloCalculator.calculateChange(
      playerElo: playerElo,
      opponentElo: ghostRun.elo,
      score: playerResult,
      gamesPlayed: 0, // Obtener del perfil real
    );

    return MatchResult(
      winnerId: oderId,
      scores: {
        oderId: playerScore,
        ghostRun.oderId: ghostScore,
      },
      eloChanges: {
        oderId: playerEloChange,
        ghostRun.oderId: -playerEloChange, // El ghost no se actualiza
      },
      newElo: {
        oderId: playerElo + playerEloChange,
        ghostRun.oderId: ghostRun.elo, // No cambia
      },
    );
  }
}
```

---

## 10. Sistema ELO

### 10.1 ELO Calculator
```dart
// lib/core/utils/elo_calculator.dart
import '../constants/game_constants.dart';

class EloCalculator {
  /// Calcular nuevo ELO después de una partida
  ///
  /// [playerElo] - ELO actual del jugador
  /// [opponentElo] - ELO del oponente
  /// [score] - Resultado (0.0 a 1.0, donde 1.0 = todas correctas)
  /// [gamesPlayed] - Partidas totales del jugador
  int calculateNewElo({
    required int playerElo,
    required int opponentElo,
    required double score,
    required int gamesPlayed,
  }) {
    final change = calculateChange(
      playerElo: playerElo,
      opponentElo: opponentElo,
      score: score,
      gamesPlayed: gamesPlayed,
    );

    return (playerElo + change).clamp(GameConstants.minElo, 9999);
  }

  /// Calcular cambio de ELO (positivo o negativo)
  int calculateChange({
    required int playerElo,
    required int opponentElo,
    required double score,
    required int gamesPlayed,
  }) {
    // Factor K: más alto para jugadores nuevos
    final k = gamesPlayed < GameConstants.newPlayerThreshold
        ? GameConstants.kFactorNew
        : GameConstants.kFactorEstablished;

    // Probabilidad esperada de ganar
    final expected = _expectedScore(playerElo, opponentElo);

    // Cambio de ELO
    final change = k * (score - expected);

    return change.round();
  }

  /// Probabilidad esperada basada en diferencia de ELO
  double _expectedScore(int playerElo, int opponentElo) {
    return 1.0 / (1.0 + pow(10, (opponentElo - playerElo) / 400.0));
  }

  /// Determinar ganador basado en respuestas correctas y tiempo
  MatchOutcome determineWinner({
    required List<AnswerModel> player1Answers,
    required List<AnswerModel> player2Answers,
  }) {
    final p1Correct = player1Answers.where((a) => a.isCorrect).length;
    final p2Correct = player2Answers.where((a) => a.isCorrect).length;

    if (p1Correct > p2Correct) {
      return MatchOutcome.player1Wins;
    } else if (p2Correct > p1Correct) {
      return MatchOutcome.player2Wins;
    }

    // Empate en correctas - desempate por tiempo total
    final p1TotalTime = player1Answers.fold<int>(0, (sum, a) => sum + a.timeMs);
    final p2TotalTime = player2Answers.fold<int>(0, (sum, a) => sum + a.timeMs);

    if (p1TotalTime < p2TotalTime) {
      return MatchOutcome.player1Wins;
    } else if (p2TotalTime < p1TotalTime) {
      return MatchOutcome.player2Wins;
    }

    return MatchOutcome.draw;
  }
}

enum MatchOutcome { player1Wins, player2Wins, draw }
```

### 10.2 Cloud Function - Calcular ELO
```typescript
// functions/src/elo.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const K_NEW = 32;
const K_ESTABLISHED = 16;
const NEW_PLAYER_THRESHOLD = 30;

export const onMatchFinished = functions.firestore
  .document('matches/{matchId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Solo procesar cuando cambia a 'finished'
    if (before.status === 'finished' || after.status !== 'finished') {
      return;
    }

    // Solo calcular ELO para partidas ranked
    if (after.type !== 'ranked') {
      return;
    }

    const matchId = context.params.matchId;
    const [player1Id, player2Id] = after.players;

    // Obtener respuestas
    const answersSnapshot = await db
      .collection(`matches/${matchId}/answers`)
      .get();

    const answers: Record<string, any[]> = {};
    answersSnapshot.docs.forEach(doc => {
      answers[doc.id] = doc.data().answers || [];
    });

    const p1Answers = answers[player1Id] || [];
    const p2Answers = answers[player2Id] || [];

    const p1Correct = p1Answers.filter((a: any) => a.isCorrect).length;
    const p2Correct = p2Answers.filter((a: any) => a.isCorrect).length;

    // Obtener perfiles de jugadores
    const [p1Doc, p2Doc] = await Promise.all([
      db.collection('users').doc(player1Id).get(),
      db.collection('users').doc(player2Id).get(),
    ]);

    const p1Data = p1Doc.data()!;
    const p2Data = p2Doc.data()!;

    const p1Elo = p1Data.elo;
    const p2Elo = p2Data.elo;
    const p1Games = p1Data.stats.totalGames;
    const p2Games = p2Data.stats.totalGames;

    // Calcular scores (0 a 1)
    const p1Score = p1Correct / 10;
    const p2Score = p2Correct / 10;

    // Calcular cambios de ELO
    const p1EloChange = calculateEloChange(p1Elo, p2Elo, p1Score, p1Games);
    const p2EloChange = calculateEloChange(p2Elo, p1Elo, p2Score, p2Games);

    const p1NewElo = Math.max(100, p1Elo + p1EloChange);
    const p2NewElo = Math.max(100, p2Elo + p2EloChange);

    // Determinar ganador
    let oderId: string | null = null;
    if (p1Correct > p2Correct) {
      oderId = player1Id;
    } else if (p2Correct > p1Correct) {
      oderId = player2Id;
    }

    // Actualizar match con resultado
    await change.after.ref.update({
      result: {
        winnerId: oderId,
        scores: {
          [player1Id]: p1Correct,
          [player2Id]: p2Correct,
        },
        eloChanges: {
          [player1Id]: p1EloChange,
          [player2Id]: p2EloChange,
        },
        newElo: {
          [player1Id]: p1NewElo,
          [player2Id]: p2NewElo,
        },
      },
      finishedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Actualizar perfiles de jugadores
    const batch = db.batch();

    // Player 1
    batch.update(db.collection('users').doc(player1Id), {
      elo: p1NewElo,
      'stats.totalGames': admin.firestore.FieldValue.increment(1),
      'stats.wins': oderId === player1Id
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.losses': oderId === player2Id
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.draws': oderId === null
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.totalCorrectAnswers': admin.firestore.FieldValue.increment(p1Correct),
    });

    // Player 2
    batch.update(db.collection('users').doc(player2Id), {
      elo: p2NewElo,
      'stats.totalGames': admin.firestore.FieldValue.increment(1),
      'stats.wins': oderId === player2Id
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.losses': oderId === player1Id
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.draws': oderId === null
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
      'stats.totalCorrectAnswers': admin.firestore.FieldValue.increment(p2Correct),
    });

    await batch.commit();
  });

function calculateEloChange(
  playerElo: number,
  opponentElo: number,
  score: number,
  gamesPlayed: number
): number {
  const k = gamesPlayed < NEW_PLAYER_THRESHOLD ? K_NEW : K_ESTABLISHED;
  const expected = 1 / (1 + Math.pow(10, (opponentElo - playerElo) / 400));
  return Math.round(k * (score - expected));
}
```

---

## 11. Monetización y Suscripciones

### 11.1 Configurar RevenueCat
```dart
// lib/services/subscription_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const String _apiKey = 'YOUR_REVENUECAT_API_KEY';

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      configuration = PurchasesConfiguration(_apiKey);
    }

    await Purchases.configure(configuration);
  }

  Future<void> login(String oderId) async {
    await Purchases.logIn(oderId);
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.entitlements.active.containsKey('premium');
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPremium() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      return purchaserInfo.entitlements.active.containsKey('premium');
    } catch (e) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
```

### 11.2 Daily Game Limits
```dart
// lib/services/daily_limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLimitService {
  final FirebaseFirestore _firestore;

  DailyLimitService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DailyGameStatus> checkDailyLimits(String oderId) async {
    final userDoc = await _firestore.collection('users').doc(oderId).get();
    final userData = userDoc.data()!;

    final dailyGames = userData['dailyGames'] as Map<String, dynamic>;
    final lastDate = (dailyGames['date'] as Timestamp).toDate();
    final today = DateTime.now();

    // Resetear si es un nuevo día
    if (!_isSameDay(lastDate, today)) {
      await _resetDailyGames(oderId);
      return DailyGameStatus(
        casualRemaining: GameConstants.freeCasualGamesPerDay,
        rankedRemaining: _getRankedLimit(userData),
      );
    }

    final casualPlayed = dailyGames['casualPlayed'] as int;
    final rankedPlayed = dailyGames['rankedPlayed'] as int;
    final rankedLimit = _getRankedLimit(userData);

    return DailyGameStatus(
      casualRemaining: GameConstants.freeCasualGamesPerDay - casualPlayed,
      rankedRemaining: rankedLimit - rankedPlayed,
    );
  }

  int _getRankedLimit(Map<String, dynamic> userData) {
    final subscription = userData['subscription'] as Map<String, dynamic>;
    final isPremium = subscription['isActive'] == true;
    return isPremium
        ? GameConstants.premiumRankedGamesPerDay
        : GameConstants.freeRankedGamesPerDay;
  }

  Future<void> recordGamePlayed(String oderId, MatchType type) async {
    final field = type == MatchType.casual ? 'casualPlayed' : 'rankedPlayed';

    await _firestore.collection('users').doc(oderId).update({
      'dailyGames.$field': FieldValue.increment(1),
      'dailyGames.date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _resetDailyGames(String oderId) async {
    await _firestore.collection('users').doc(oderId).update({
      'dailyGames': {
        'casualPlayed': 0,
        'rankedPlayed': 0,
        'date': FieldValue.serverTimestamp(),
      },
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class DailyGameStatus {
  final int casualRemaining;
  final int rankedRemaining;

  DailyGameStatus({
    required this.casualRemaining,
    required this.rankedRemaining,
  });

  bool get canPlayCasual => casualRemaining > 0;
  bool get canPlayRanked => rankedRemaining > 0;
}
```

---

## 12. Cloud Functions - Resumen

### 12.1 Estructura del Proyecto
```
functions/
├── src/
│   ├── index.ts
│   ├── matchmaking.ts
│   ├── elo.ts
│   ├── dailyReset.ts
│   └── utils/
│       └── eloCalculator.ts
├── package.json
└── tsconfig.json
```

### 12.2 package.json
```json
{
  "name": "functions",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.5.0"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
```

### 12.3 index.ts
```typescript
// functions/src/index.ts
import * as admin from 'firebase-admin';

admin.initializeApp();

// Matchmaking
export { onQueueJoin, cleanupQueue } from './matchmaking';

// ELO
export { onMatchFinished } from './elo';

// Daily Reset
export { resetDailyLimits } from './dailyReset';
```

### 12.4 Daily Reset Function
```typescript
// functions/src/dailyReset.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Ejecutar cada día a las 00:00 UTC
export const resetDailyLimits = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const usersSnapshot = await db.collection('users').get();

    const batch = db.batch();
    const today = admin.firestore.Timestamp.now();

    usersSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        'dailyGames': {
          'casualPlayed': 0,
          'rankedPlayed': 0,
          'date': today,
        },
      });
    });

    await batch.commit();
    console.log(`Reset daily limits for ${usersSnapshot.size} users`);
  });
```

---

## 13. UI/UX Guidelines

### 13.1 Paleta de Colores
```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Secondary
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFF57C00);

  // Game
  static const Color correct = Color(0xFF4CAF50);
  static const Color incorrect = Color(0xFFF44336);
  static const Color timerNormal = Color(0xFF4CAF50);
  static const Color timerWarning = Color(0xFFFF9800);
  static const Color timerDanger = Color(0xFFF44336);

  // Ranks
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFFE5E4E2);
  static const Color rankDiamond = Color(0xFFB9F2FF);

  // Background
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
}
```

### 13.2 Tipografía
```dart
// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get timer => GoogleFonts.robotoMono(
    fontSize: 48,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get score => GoogleFonts.poppins(
    fontSize: 64,
    fontWeight: FontWeight.bold,
  );
}
```

### 13.3 Pantallas Principales
```
1. Splash Screen
   - Logo animado
   - Carga inicial

2. Login Screen
   - Logo
   - Botón "Continuar con Google"
   - Botón "Continuar con Apple"

3. Home Screen
   - Avatar y ELO del usuario
   - Botón "Partida Rápida" (casual)
   - Botón "Ranked"
   - Indicadores de partidas restantes
   - Acceso a perfil, leaderboard, ajustes

4. Matchmaking Screen
   - Animación de búsqueda
   - ELO del jugador
   - Botón cancelar

5. Game Screen
   - Barra de progreso (pregunta X/10)
   - Timer circular
   - Área de pregunta (variable según tipo)
   - 4 opciones de respuesta
   - Puntuación en vivo (modo realtime)

6. Results Screen
   - Resultado (Victoria/Derrota/Empate)
   - Puntuación final
   - Cambio de ELO (+X / -X)
   - Resumen de respuestas
   - Botones: "Jugar de nuevo" / "Volver al inicio"

7. Profile Screen
   - Avatar, nombre, ELO
   - Estadísticas (victorias, derrotas, racha)
   - Historial de partidas
   - Liga actual (Bronce, Plata, Oro, etc.)

8. Leaderboard Screen
   - Tabs: Global / Amigos
   - Lista de jugadores con ELO
   - Posición del jugador actual

9. Subscription Screen
   - Beneficios premium
   - Opciones de suscripción
   - Botón de compra
```

---

## 14. Base de Datos de Preguntas

### 14.1 Script para Generar Preguntas
```dart
// scripts/generate_questions.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final questions = <Map<String, dynamic>>[];

  // Obtener datos de REST Countries
  final response = await http.get(
    Uri.parse('https://restcountries.com/v3.1/all'),
  );
  final countries = jsonDecode(response.body) as List;

  for (final country in countries) {
    final name = country['name']['common'];
    final capital = country['capital']?[0];
    final population = country['population'];
    final area = country['area'];
    final cca2 = country['cca2'];

    // Tipo 2: Bandera
    questions.add({
      'type': 'flag',
      'difficulty': 'easy',
      'extraData': {'countryCode': cca2.toLowerCase()},
      'correctAnswer': name,
      'options': [], // Generar opciones aleatorias
    });

    // Tipo 3: Capital
    if (capital != null) {
      questions.add({
        'type': 'capital',
        'difficulty': 'medium',
        'questionText': '¿Cuál es la capital de $name?',
        'correctAnswer': capital,
        'options': [],
      });
    }
  }

  // Guardar en JSON
  final output = jsonEncode(questions);
  // ... guardar a archivo
}
```

### 14.2 Estructura de Preguntas en Firestore
```
questions/
├── silhouette_001
│   ├── type: "silhouette"
│   ├── difficulty: "medium"
│   ├── imageUrl: "gs://geoquiz-battle.appspot.com/silhouettes/spain.png"
│   ├── correctAnswer: "España"
│   └── options: ["España", "Portugal", "Italia", "Francia"]
│
├── flag_001
│   ├── type: "flag"
│   ├── difficulty: "easy"
│   ├── extraData: {countryCode: "jp"}
│   ├── correctAnswer: "Japón"
│   └── options: ["Japón", "China", "Corea del Sur", "Vietnam"]
│
├── capital_001
│   ├── type: "capital"
│   ├── difficulty: "medium"
│   ├── questionText: "¿Cuál es la capital de Australia?"
│   ├── correctAnswer: "Canberra"
│   └── options: ["Sídney", "Melbourne", "Canberra", "Brisbane"]
│
├── population_001
│   ├── type: "population"
│   ├── difficulty: "hard"
│   ├── questionText: "¿Qué país tiene más habitantes?"
│   ├── extraData: {
│   │   countries: ["Brasil", "Argentina"],
│   │   data: {Brasil: 215000000, Argentina: 45000000}
│   │ }
│   ├── correctAnswer: "Brasil"
│   └── options: ["Brasil", "Argentina"]
│
├── river_001
│   ├── type: "river"
│   ├── difficulty: "hard"
│   ├── questionText: "¿Cuál es el río más largo de España?"
│   ├── correctAnswer: "Tajo"
│   └── options: ["Ebro", "Tajo", "Duero", "Guadalquivir"]
│
├── city_001
│   ├── type: "cityPhoto"
│   ├── difficulty: "medium"
│   ├── imageUrl: "gs://geoquiz-battle.appspot.com/cities/paris_eiffel.jpg"
│   ├── correctAnswer: "París"
│   └── options: ["París", "Londres", "Roma", "Berlín"]
│
└── area_001
    ├── type: "area"
    ├── difficulty: "hard"
    ├── questionText: "¿Qué país es más extenso?"
    ├── extraData: {
    │   countries: ["Kazajistán", "Argentina"],
    │   data: {Kazajistán: 2724900, Argentina: 2780400}
    │ }
    ├── correctAnswer: "Argentina"
    └── options: ["Kazajistán", "Argentina"]
```

### 14.3 Fuentes de Assets

| Tipo | Fuente | Cantidad Recomendada |
|------|--------|---------------------|
| Siluetas | Crear SVG/PNG manualmente o comprar pack | 100+ países |
| Banderas | flagcdn.com (gratis, API) | Todos los países |
| Fotos ciudades | Unsplash/Pexels (curar manualmente) | 100+ ciudades |
| Datos países | REST Countries API | Automático |
| Datos ríos | Wikipedia / curación manual | 50+ ríos |

---

## 15. Testing

### 15.1 Unit Tests
```dart
// test/core/utils/elo_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EloCalculator', () {
    late EloCalculator calculator;

    setUp(() {
      calculator = EloCalculator();
    });

    test('should increase ELO when winning against higher rated opponent', () {
      final newElo = calculator.calculateNewElo(
        playerElo: 1000,
        opponentElo: 1200,
        score: 0.8, // 8/10 correctas
        gamesPlayed: 50,
      );

      expect(newElo, greaterThan(1000));
    });

    test('should decrease ELO when losing against lower rated opponent', () {
      final newElo = calculator.calculateNewElo(
        playerElo: 1200,
        opponentElo: 1000,
        score: 0.2, // 2/10 correctas
        gamesPlayed: 50,
      );

      expect(newElo, lessThan(1200));
    });

    test('should use higher K factor for new players', () {
      final changeNew = calculator.calculateChange(
        playerElo: 1000,
        opponentElo: 1000,
        score: 1.0,
        gamesPlayed: 10, // Nuevo
      );

      final changeEstablished = calculator.calculateChange(
        playerElo: 1000,
        opponentElo: 1000,
        score: 1.0,
        gamesPlayed: 100, // Establecido
      );

      expect(changeNew, greaterThan(changeEstablished));
    });

    test('should never go below minimum ELO', () {
      final newElo = calculator.calculateNewElo(
        playerElo: 150,
        opponentElo: 2000,
        score: 0.0,
        gamesPlayed: 50,
      );

      expect(newElo, greaterThanOrEqualTo(GameConstants.minElo));
    });
  });
}
```

### 15.2 Widget Tests
```dart
// test/presentation/widgets/timer_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerWidget', () {
    testWidgets('should show correct seconds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimerWidget(remainingTimeMs: 5000),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should show red color when time is low', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimerWidget(remainingTimeMs: 2000),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('2'));
      expect(text.style?.color, equals(Colors.red));
    });
  });
}
```

### 15.3 Integration Tests
```dart
// integration_test/game_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete game flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    // Start casual game
    await tester.tap(find.text('Partida Rápida'));
    await tester.pumpAndSettle();

    // Wait for matchmaking (mock)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Answer questions
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();
    }

    // Verify results screen
    expect(find.text('¡Partida terminada!'), findsOneWidget);
  });
}
```

---

## 16. Despliegue

### 16.1 Checklist Pre-Lanzamiento
```markdown
## Firebase
- [ ] Configurar Firebase para producción
- [ ] Habilitar App Check
- [ ] Revisar Security Rules
- [ ] Configurar backups de Firestore
- [ ] Configurar alertas de uso/costos

## App
- [ ] Cambiar a modo release
- [ ] Configurar ofuscación de código
- [ ] Optimizar assets (comprimir imágenes)
- [ ] Probar en dispositivos reales
- [ ] Configurar Firebase Crashlytics
- [ ] Configurar Firebase Analytics

## Cloud Functions
- [ ] Deploy funciones a producción
- [ ] Configurar variables de entorno
- [ ] Revisar límites de memoria/timeout

## Stores
- [ ] Preparar screenshots
- [ ] Escribir descripción
- [ ] Configurar precios de suscripción
- [ ] Crear cuenta de RevenueCat producción
- [ ] Enviar para revisión
```

### 16.2 Comandos de Deploy
```bash
# Build Flutter
flutter build appbundle --release  # Android
flutter build ios --release        # iOS

# Deploy Cloud Functions
cd functions
npm run deploy

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Deploy Storage Rules
firebase deploy --only storage
```

### 16.3 Monitoreo Post-Lanzamiento
```markdown
## Métricas a Monitorar
- DAU/MAU (Daily/Monthly Active Users)
- Retención D1, D7, D30
- Partidas por usuario
- Conversión a premium
- Errores y crashes
- Tiempos de matchmaking
- Distribución de ELO

## Herramientas
- Firebase Analytics
- Firebase Crashlytics
- RevenueCat Dashboard
- Firebase Performance Monitoring
```

---

## Apéndice A: Comandos Útiles

```bash
# Desarrollo
flutter run
flutter run --release

# Generar código (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch

# Firebase Emulators
firebase emulators:start

# Tests
flutter test
flutter test --coverage

# Análisis
flutter analyze
```

---

## Apéndice B: Recursos Adicionales

### Documentación
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Riverpod Documentation](https://riverpod.dev/)
- [RevenueCat Documentation](https://docs.revenuecat.com/docs/flutter)

### APIs
- [REST Countries](https://restcountries.com/)
- [FlagCDN](https://flagcdn.com/)

### Assets
- [Unsplash](https://unsplash.com/) - Fotos gratuitas
- [Flaticon](https://www.flaticon.com/) - Iconos

---

**Fin de la Guía**

Esta guía proporciona toda la información necesaria para desarrollar GeoQuiz Battle desde cero. Sigue las fases en orden y consulta las secciones específicas según necesites implementar cada funcionalidad.
