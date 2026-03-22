# GeoQuiz Battle 🌍🎮

Juego móvil de preguntas 1v1 sobre geografía con partidas de 1 minuto.

## 📋 Descripción

GeoQuiz Battle es un juego competitivo de geografía donde dos jugadores comparten respondiendo preguntas en tiempo real. Cada partida dura 1 minuto con 10 preguntas de 10 segundos cada una.

### 🎯 Características Principales

- **Modos de juego**: Partida rápida (casual) y Ranked
- **Matchmaking**: Tiempo real y asíncrono (ghostRun)
- **7 tipos de preguntas**:
  - Siluetas de países
  - Banderas
  - Capitales
  - Población comparativa
  - Ríos
  - Fotos de ciudades
  - Extensión territorial
- **Sistema ELO**: Ranking competitivo basado en rendimiento
- **Modelo Freemium**: 1 casual + 1 ranked gratis/día, suscripción para 5 ranked/día

## 🛠️ Stack Tecnológico

- **Frontend**: Flutter 3.x (Dart)
- **State Management**: Riverpod 2.x
- **Backend**: Firebase (Auth, Firestore, Functions, Storage)
- **Payments**: RevenueCat
- **Analytics**: Firebase Analytics

## 📱 Estructura del Proyecto

```
GeoC/
├── lib/                    # Código fuente Flutter
│   ├── core/              # Constantes, errores, utils, tema
│   ├── data/              # Models, repositories, datasources
│   ├── domain/            # Entidades, use cases
│   ├── presentation/      # Screens, widgets, providers
│   └── services/          # Firebase, audio, notifications
├── functions/             # Cloud Functions (TypeScript)
├── test/                  # Tests
├── docs/                  # Documentación adicional
└── scripts/               # Scripts útiles
```

## 🚀 Primeros Pasos

### Requisitos Previos

```bash
# Flutter SDK (3.16+)
flutter --version

# Firebase CLI
npm install -g firebase-tools
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Instalación

```bash
# Obtener dependencias
flutter pub get

# Generar código (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Iniciar proyecto
flutter run
```

### Configuración de Firebase

1. Crear proyecto en Firebase Console: https://console.firebase.google.com
2. Ejecutar: `flutterfire configure --project=geoquiz-battle`
3. Habilitar servicios: Auth, Firestore, Functions, Storage, Realtime Database

## 🎮 Modos de Juego

### Casual (Partida Rápida)
- Sin afectar ELO
- 1 partida gratis/día (free users)
- Matchmaking casual

### Ranked
- Afecta tu ELO
- 1 partida gratis/día (free users), 5/día (premium)
- Matchmaking por rango de ELO
- Sistema de ligas: Bronce → Plata → Oro → Platino → Diamante

## 💰 Monetización

| Característica | Gratis | Premium |
|---------------|--------|---------|
| Partidas casual/día | 1 | Ilimitadas |
| Partidas ranked/día | 1 | 5 |
| Sin anuncios | ❌ | ✅ |
| Estadísticas avanzadas | ❌ | ✅ |

## 🏆 Sistema ELO

- **ELO inicial**: 1000
- **ELO mínimo**: 100
- **K-factor (nuevos)**: 32 (<30 partidas)
- **K-factor (establecidos)**: 16 (≥30 partidas)
- **Rango de matchmaking**: ±200 ELO

## 📖 Documentación Completa

Consulta la [GUIA_COMPLETA.md](docs/GUIA_COMPLETA.md) para detalles detallados de:
- Estructura de modelos de datos
- Sistema de autenticación
- Implementación de cada tipo de pregunta
- Sistema de matchmaking
- Cálculo de ELO
- Cloud Functions
- Testing
- Despliegue

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Con cobertura
flutter test --coverage
```

## 🚀 Despliegue

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release

# Cloud Functions
cd functions
npm run deploy

# Firebase Rules
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## 📊 Progreso del Desarrollo

### ✅ FASE 1: Fundamentos Backend (Completada)
- Modelos de datos (User, Question, Match, GhostRun)
- Repositorios del dominio
- Implementaciones con Firebase
- AuthRemoteDataSource (Google/Apple)
- Manejo de errores con dartz

### 🔄 FASE 2: Autenticación y Home (En desarrollo)
- LoginScreen
- HomeScreen
- AuthProvider
- Routing

### ⏳ Fases Pendientes
- FASE 3: Base de Datos de Preguntas
- FASE 4: Core del Juego
- FASE 5: Matchmaking Multiplayer
- FASE 6: Ghost Runs (Async)
- FASE 7: Monetización
- FASE 8: Polish y Despliegue

## 📊 Arquitectura

El proyecto sigue una **arquitectura limpia** con separación de capas:

```
Presentation (UI) → Domain (Lógica de negocio) → Data (Persistencia)
                    ↓
                Services (Firebase, Audio, etc.)
```

## 🤝 Contribución

Este proyecto está en desarrollo activo. Para contribuir:

1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Añadir nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Pull Request

## 📝 License

[Indicar licencia]

## 👥 Autores

- [@mariete77](https://github.com/mariete77) - Desarrollo principal

## 🙏 Agradecimientos

- Flutter Team
- Firebase
- Riverpod
- REST Countries API
- FlagCDN

---

**¡Prepárate para demostrar tus conocimientos de geografía! 🌍**
