# FASE 1: Fundamentos Backend - Instrucciones Completas

## 📋 Resumen

Esta fase establece la base del backend: modelos de datos, repositorios y configuración de Firebase.

## ✅ Estado Actual

**Completado:**
- ✅ Todos los modelos de datos (User, Question, Match, GhostRun)
- ✅ Interfaces de repositorios (domain layer)
- ✅ Implementaciones de repositorios (data layer)
- ✅ AuthRemoteDataSource para autenticación con Google/Apple
- ✅ Conversión entre entidades y modelos
- ✅ Manejo de errores con dartz Either

**Pendiente:**
- ⏳ Configurar proyecto en Firebase Console
- ⏳ Ejecutar `flutterfire configure`
- ⏳ Generar código con build_runner
- ⏳ Probar la conexión con Firebase

---

## 🔥 Paso 1: Configurar Firebase

### 1.1 Crear Proyecto en Firebase Console

1. Ve a: https://console.firebase.google.com
2. Click en **"Add project"**
3. **Nombre del proyecto**: `geoquiz-battle`
4. (Opcional) Habilitar Google Analytics
5. Click en **"Create project"** y espera

### 1.2 Habilitar Servicios

#### Authentication
1. Ve a **Authentication** → **Sign-in method**
2. Habilita **Google**
   - Necesitas un proyecto en Google Cloud Console
   - Sigue las instrucciones para configurar OAuth consent
3. Habilita **Apple** (solo si tienes Mac, opcional para Android)

#### Firestore Database
1. Ve a **Firestore Database**
2. Click en **"Create database"**
3. Elige ubicación (ej: `europe-west3` o `nam5 (us-central)`)
4. Selecciona **"Start in Test mode"** (por ahora)
5. La base de datos está lista

#### Realtime Database
1. Ve a **Realtime Database**
2. Click en **"Create database"**
3. Selecciona la misma ubicación que Firestore
4. Selecciona **"Start in Test mode"**

#### Storage
1. Ve a **Storage**
2. Click en **"Get started"**
3. Selecciona **"Start in Test mode"**
4. Asegúrate de usar las reglas de modo test por ahora

### 1.3 Configurar FlutterFire

```bash
# Desde la raíz del proyecto
cd /ruta/a/tu/workspace/GeoC

# Ejecutar FlutterFire configure
flutterfire configure --project=geoquiz-battle
```

Esto creará el archivo `lib/firebase_options.dart` automáticamente.

### 1.4 Actualizar main.dart

En `lib/main.dart`, descomenta las líneas de Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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

---

## 🏗️ Paso 2: Generar Código con Build Runner

El proyecto usa **freezed** para modelos inmutables y **json_serializable** para serialización.

```bash
# Desde la raíz del proyecto
cd /ruta/a/tu/workspace/GeoC

# Generar código
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Esto generará archivos con extensión `.freezed.dart` y `.g.dart` para cada modelo.

**Archivos generados:**
- `lib/data/models/user_model.freezed.dart`
- `lib/data/models/user_model.g.dart`
- `lib/data/models/question_model.freezed.dart`
- `lib/data/models/question_model.g.dart`
- `lib/data/models/match_model.freezed.dart`
- `lib/data/models/match_model.g.dart`
- `lib/data/models/ghost_run_model.freezed.dart`
- `lib/data/models/ghost_run_model.g.dart`

---

## 📊 Paso 3: Entender la Estructura

### Dominio (domain/)
Define qué hace el negocio, sin saber cómo se implementa.

```dart
// domain/entities/
├── user.dart        // Entidad User
├── question.dart    // Entidad Question
└── match.dart       // Entidad Match, Answer, GhostRun

// domain/repositories/
├── auth_repository.dart         // Interfaz de autenticación
├── user_repository.dart         // Interfaz de usuarios
├── question_repository.dart     // Interfaz de preguntas
├── match_repository.dart        // Interfaz de partidas
└── ghost_run_repository.dart    // Interfaz de ghost runs
```

### Datos (data/)
Implementa cómo se hacen las cosas con Firebase.

```dart
// data/models/
├── user_model.dart         // Modelo Firebase + conversión a entidad
├── question_model.dart     // Modelo Firebase + conversión a entidad
├── match_model.dart        // Modelo Firebase + conversión a entidad
└── ghost_run_model.dart    // Modelo Firebase + conversión a entidad

// data/repositories/
├── auth_repository_impl.dart         // Implementación con Firebase Auth
├── user_repository_impl.dart         // Implementación con Firestore
├── question_repository_impl.dart     // Implementación con Firestore
├── match_repository_impl.dart        // Implementación con Firestore
└── ghost_run_repository_impl.dart    // Implementación con Firestore

// data/datasources/
└── remote/
    └── auth_remote_datasource.dart   // Firebase Auth específico
```

### Patrón: Either<Failure, T>
Usamos `dartz` para manejar errores de forma funcional:

```dart
// Repository devuelve Either<Error, Success>
Future<Either<Failure, User>> getUserProfile(String userId)

// Uso:
final result = await userRepository.getUserProfile(userId);
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('Usuario: ${user.displayName}'),
);
```

---

## 🧪 Paso 4: Probar la Conexión

Crea un archivo de prueba temporal `lib/test_firebase.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Test Firestore connection
    final snapshot = await FirebaseFirestore.instance.collection('test').limit(1).get();
    print('✅ Firestore connection successful');

    runApp(const TestApp());
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('✅ Firebase está conectado'),
              SizedBox(height: 16),
              Text('Prueba completada'),
            ],
          ),
        ),
      ),
    );
  }
}
```

Ejecuta la prueba:
```bash
flutter run lib/test_firebase.dart
```

Si ves "✅ Firebase está conectado", todo está bien.

---

## 🔐 Paso 5: Configurar Firestore Rules (Modo Test)

Mientras desarrollas, usa reglas permissivas.

### Firestore Rules
Ve a Firebase Console → Firestore → **Rules** y pega:

```javascript
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

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
    }

    // Matches
    match /matches/{matchId} {
      allow read: if isAuthenticated();
      allow create: if true; // Temporal
      allow update: if true; // Temporal
    }

    // Questions - Solo lectura para todos
    match /questions/{questionId} {
      allow read: if true;
      allow write: if false;
    }

    // Ghost Runs
    match /ghostRuns/{ghostRunId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
    }
  }
}
```

### Realtime Database Rules
Ve a Realtime Database → **Rules** y pega:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "matchmaking": {
      "queue": {
        "$userId": {
          ".read": "auth != null && auth.uid == $userId",
          ".write": "auth != null && auth.uid == $userId"
        }
      }
    }
  }
}
```

### Storage Rules
Ve a Storage → **Rules** y pega:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

⚠️ **Importante**: Estas reglas son SOLO para desarrollo. Para producción, implementa reglas de seguridad adecuadas.

---

## 🚀 Paso 6: Commit y Push

```bash
# Ver cambios
git status

# Añadir archivos
git add .

# Commit
git commit -m "feat: complete FASE 1 - backend fundamentals

- Add all data models (User, Question, Match, GhostRun)
- Add domain repositories interfaces
- Add repository implementations with Firebase
- Add AuthRemoteDataSource for Google/Apple sign-in
- Add error handling with dartz Either
- Add model<->entity conversion methods
- Add Firebase setup instructions"

# Push
git push origin main
```

---

## 📝 Resumen de Archivos Creados

### Models (4 archivos)
- `lib/data/models/user_model.dart` (4508 bytes)
- `lib/data/models/question_model.dart` (1486 bytes)
- `lib/data/models/match_model.dart` (4327 bytes)
- `lib/data/models/ghost_run_model.dart` (2550 bytes)

### Repository Interfaces (5 archivos)
- `lib/domain/repositories/auth_repository.dart`
- `lib/domain/repositories/user_repository.dart`
- `lib/domain/repositories/question_repository.dart`
- `lib/domain/repositories/match_repository.dart`
- `lib/domain/repositories/ghost_run_repository.dart`

### Repository Implementations (5 archivos)
- `lib/data/repositories/auth_repository_impl.dart` (4235 bytes)
- `lib/data/repositories/user_repository_impl.dart` (5337 bytes)
- `lib/data/repositories/question_repository_impl.dart` (5255 bytes)
- `lib/data/repositories/match_repository_impl.dart` (5110 bytes)
- `lib/data/repositories/ghost_run_repository_impl.dart` (5516 bytes)

### Data Sources (1 archivo)
- `lib/data/datasources/remote/auth_remote_datasource.dart` (2393 bytes)

**Total**: ~31KB de código backend funcional.

---

## 🎯 ¿Qué sigue después de FASE 1?

**FASE 2: Autenticación y Home**
1. Crear AuthProvider (Riverpod)
2. Crear LoginScreen
3. Crear HomeScreen
4. Configurar routing con Go Router

---

## 🐛 Solución de Problemas

### Error: "Firebase not initialized"
- Ejecuta `flutterfire configure --project=geoquiz-battle`
- Verifica que `lib/firebase_options.dart` existe
- Descomenta las líneas de inicialización en `main.dart`

### Error: "Build runner failed"
- Ejecuta `flutter pub get`
- Limpia: `rm -rf .dart_tool`
- Ejecuta: `flutter pub get` de nuevo
- Ejecuta: `dart run build_runner build --delete-conflicting-outputs`

### Error: "Authentication not enabled"
- Ve a Firebase Console → Authentication → Sign-in method
- Habilita Google y/o Apple

---

**¡FASE 1 completada! 🎉** Ahora tienes toda la base del backend lista para construir la UI.
