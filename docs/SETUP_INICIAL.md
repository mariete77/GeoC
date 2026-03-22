# Setup Inicial - GeoQuiz Battle

Este documento guía los primeros pasos para configurar el proyecto desde cero.

## 📋 Checklist Pre-Inicial

- [ ] Flutter SDK 3.16+ instalado
- [ ] Firebase CLI instalado (`npm install -g firebase-tools`)
- [ ] Cuenta de Firebase creada
- [ ] FlutterFire CLI instalado (`dart pub global activate flutterfire_cli`)

## 🚀 Paso 1: Instalar Dependencias

```bash
# Desde la raíz del proyecto
flutter pub get

# Esto instalará todas las dependencias especificadas en pubspec.yaml
```

## 🔥 Paso 2: Configurar Firebase

### 2.1 Crear Proyecto Firebase

1. Ir a https://console.firebase.google.com
2. Click en "Add project"
3. Nombre: `geoquiz-battle`
4. Habilitar Google Analytics (opcional pero recomendado)

### 2.2 Configurar FlutterFire

```bash
# Desde la raíz del proyecto
flutterfire configure --project=geoquiz-battle
```

Esto creará el archivo `lib/firebase_options.dart` automáticamente.

### 2.3 Habilitar Servicios Firebase

En Firebase Console, habilita los siguientes servicios:

**Authentication:**
- Enable: Google Sign-in
- Enable: Apple Sign-in (para iOS)

**Firestore Database:**
- Create database
- Choose location (ej: europe-west3)
- Start in Test Mode

**Realtime Database:**
- Create database
- Start in Test Mode

**Storage:**
- Start in Test Mode
- Reglas por ahora en modo test

### 2.4 Descomentar Firebase en main.dart

En `lib/main.dart`, descomenta las líneas:

```dart
// Import
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// En main()
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 📦 Paso 3: Generar Código (Build Runner)

El proyecto usa Freezed y json_serializable para generar código de modelos.

```bash
# Generar código una vez
dart run build_runner build --delete-conflicting-outputs

# O en modo watch (se regenera automáticamente cuando cambias archivos)
dart run build_runner watch
```

## 🏗️ Paso 4: Estructura del Proyecto

El proyecto está organizado en capas:

```
lib/
├── core/              # Constantes, errores, utils, tema
├── data/              # Models, repositories, datasources
├── domain/            # Entidades, use cases
├── presentation/      # Screens, widgets, providers
└── services/          # Firebase, audio, notifications
```

## 🎨 Paso 5: Configurar Assets

Los assets se cargan desde la carpeta `assets/`:

```
assets/
├── images/            # Imágenes generales
├── silhouettes/       # Siluetas de países
├── audio/              # Sonidos del juego
└── lottie/             # Animaciones Lottie
```

Añade tus assets en estas carpetas y asegúrate de que están listados en `pubspec.yaml`.

## 🧪 Paso 6: Ejecutar el Proyecto

```bash
# Modo debug
flutter run

# Modo release
flutter run --release

# En dispositivo específico
flutter run -d chrome          # Web
flutter run -d macos           # macOS
flutter run -d windows         # Windows
flutter devices                # Ver dispositivos disponibles
```

## 🔧 Paso 7: Probar Funcionalidades Básicas

1. **Splash Screen**: Deberías ver la pantalla de carga inicial
2. **Firebase Initialization**: Revisa la consola para ver errores de Firebase
3. **Routing**: Las pantallas básicas deberían funcionar

## 📝 Paso 8: Configurar Firebase Rules (Provisional)

Mientras desarrollas, usa reglas permissivas:

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Realtime Database Rules
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Importante**: Estas reglas son solo para desarrollo. Para producción, implementa las reglas de seguridad adecuadas.

## 🎯 Siguientes Pasos

Una vez completado el setup inicial:

1. **Autenticación**: Implementa login con Google/Apple
2. **Preguntas**: Carga la base de datos de preguntas
3. **UI**: Construye las pantallas principales (Home, Game, Results)
4. **Matchmaking**: Implementa el sistema de emparejamiento
5. **Cloud Functions**: Despliega las funciones de backend

## 🐛 Solución de Problemas

### Error: "Firebase not initialized"
- Asegúrate de haber ejecutado `flutterfire configure`
- Verifica que `firebase_options.dart` existe en `lib/`
- Descomenta las líneas de inicialización en `main.dart`

### Error: "Build runner not working"
- Asegúrate de tener las dependencias dev instaladas: `flutter pub get`
- Borra la carpeta `.dart_tool/` y ejecuta `flutter pub get` de nuevo
- Ejecuta: `dart run build_runner build --delete-conflicting-outputs`

### Error: "Firebase Authentication not enabled"
- Ve a Firebase Console → Authentication → Sign-in method
- Habilita Google Sign-in y/o Apple Sign-in

## 📚 Recursos Útiles

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Riverpod Documentation](https://riverpod.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)

## 💡 Tips

- Usa `flutter analyze` para detectar problemas en el código
- Usa `flutter test` para ejecutar tests unitarios
- Usa `flutter pub upgrade` para actualizar dependencias
- Revisa el archivo `pubspec.yaml` para ver todas las dependencias disponibles

---

¿Listo para empezar a construir GeoQuiz Battle? 🚀🌍
