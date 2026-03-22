# FASE 2: Autenticación y Home - Instrucciones Completas

## 📋 Resumen

Esta fase implementa las pantallas principales: Splash, Login y Home, junto con los providers de Riverpod para state management.

## ✅ Estado Actual

**Completado:**
- ✅ AuthProvider (Google/Apple sign-in)
- ✅ UserProvider (perfil, stats, juegos diarios)
- ✅ SplashScreen (animada con transición)
- ✅ LoginScreen (Google + Apple buttons)
- ✅ HomeScreen (dashboard completo)
- ✅ Routing con Go Router
- ✅ Widgets comunes (Loading, Error, Button)

**Pendiente:**
- ⏳ Configurar Firebase (si no se hizo en FASE 1)
- ⏳ Generar código con build_runner
- ⏳ Probar el flujo completo

---

## 🎨 Lo que hemos creado

### 1. Providers (Riverpod 2.x)

#### AuthProvider (`lib/presentation/providers/auth_provider.dart`)
Maneja la autenticación del usuario:

- **signInWithGoogle()** - Login con Google
- **signInWithApple()** - Login con Apple
- **signOut()** - Cerrar sesión
- **authStateChanges** - Stream de cambios de auth
- **currentUser** - Usuario actual
- **isAuthenticated** - ¿Está logueado?

#### UserProvider (`lib/presentation/providers/user_provider.dart`)
Maneja el perfil y datos del usuario:

- **getUserProfile()** - Obtener perfil
- **updateUserProfile()** - Actualizar perfil
- **recordGamePlayed()** - Registrar partida jugada
- **getDailyGames()** - Obtener juegos diarios
- **dailyGamesStatus** - Estado de juegos restantes

### 2. Pantallas

#### SplashScreen (`lib/presentation/screens/splash/splash_screen.dart`)
Pantalla inicial con animaciones:
- Logo animado (fade + scale)
- Verifica estado de autenticación
- Redirige a Login o Home automáticamente
- 2 segundos de duración

#### LoginScreen (`lib/presentation/screens/auth/login_screen.dart`)
Pantalla de inicio de sesión:
- Logo/Icono del app
- Botón "Continuar con Google"
- Botón "Continuar con Apple"
- Mensaje de error si falla
- Términos y política de privacidad

#### HomeScreen (`lib/presentation/screens/home/home_screen.dart`)
Dashboard principal del usuario:
- **Header**: Avatar, nombre, ELO, rango
- **Stats**: Partidas, victorias, racha
- **Modos de juego**:
  - Partida Rápida (Casual)
  - Ranked (con ELO)
  - Indicadores de juegos restantes
- **Accesos rápidos**: Perfil, Leaderboard, Suscripción
- **Partidas recientes**: Historial vacío al inicio

### 3. Routing

#### Go Router (`lib/app.dart`)
Configuración de rutas:
- `/` → Splash (inicial)
- `/login` → Login
- `/home` → Home (protegida)
- Protección automática de rutas
- Redirección basada en auth state

### 4. Widgets Comunes

#### LoadingWidget
Indicador de carga con mensaje opcional.

#### CustomErrorWidget
Widget de error con opción de retry.

#### CustomButton
Botón personalizado reutilizable:
- Variante: Elevated o Outlined
- Soporte para iconos
- Estado de carga
- Colores personalizables

---

## 🚀 Cómo Probar

### 1. Generar Código
```bash
cd /ruta/a/tu/workspace/GeoC
dart run build_runner build --delete-conflicting-outputs
```

### 2. Ejecutar App
```bash
flutter run
```

### 3. Flujo Completo

#### a) Primer lanzamiento (sin usuario logueado)
1. Aparece **SplashScreen** con animación
2. Después de 2s, redirige a **LoginScreen**
3. Click en "Continuar con Google"
4. Se abre Google Sign-In
5. Si es la primera vez, se crea usuario en Firestore
6. Redirige a **HomeScreen**

#### b) Usuario ya logueado
1. Splash detecta usuario existente
2. Redirige directamente a Home
3. Carga perfil del usuario
4. Muestra datos: ELO, stats, rango

#### c) Cerrar sesión
1. En Home, click en settings (ícono)
2. Click en "Cerrar sesión"
3. Redirige a Login

---

## 📊 Estructura del Routing

```
/ (Splash)
  ↓ [no usuario]
/login
  ↓ [login exitoso]
/home (protegida)
  ↓ [matchmaking]
/matchmaking
  ↓ [match encontrado]
/game/:matchId
  ↓ [partida terminada]
/results/:matchId
```

---

## 🎨 Diseño UI

### Colores Principales
- **Primary**: Blue (#2196F3)
- **Secondary**: Orange (#FF9800)
- **Correct**: Green (#4CAF50)
- **Error**: Red (#F44336)
- **Background**: Light Gray (#F5F5F5)

### Tipografía
- **H1**: 32px, Bold
- **H2**: 24px, Semi-bold
- **H3**: 20px, Semi-bold
- **Body**: 16px, Regular
- **Button**: 16px, Semi-bold
- **Timer**: 48px, Bold (mono)

### Componentes Reutilizables
- Cards con shadow
- Botones con border-radius 12px
- Avatares circulares
- Badges con semitransparencia

---

## 🔧 Configuración Adicional

### 1. Añadir Logo de Google

Crea o descarga el logo de Google:
```bash
mkdir -p assets/images
# Descarga: https://developers.google.com/identity/images/g-logo.png
# Guárdalo como: assets/images/google_logo.png
```

Asegúrate de que está en `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
```

### 2. Configurar Google Sign-In

Sigue las instrucciones de Google: https://firebase.google.com/docs/auth/android/google-signin

Para Android:
1. Añade SHA-1 en Google Cloud Console
2. Configura OAuth consent

Para iOS:
1. Añade URL Scheme en `ios/Runner/Info.plist`
2. Configura Sign-In con Apple en Xcode

### 3. Configurar Apple Sign-In (iOS solo)

En `ios/Runner/Info.plist`, añade:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## 🐛 Solución de Problemas

### Error: "UserProvider not found"
- Ejecuta `dart run build_runner build`
- Verifica que `user_provider.g.dart` existe

### Error: "No route found"
- Verifica que `routerProvider` está en `app.dart`
- Revisa que las rutas estén bien definidas

### Error: "Google Sign-In failed"
- Verifica que Google Sign-In está habilitado en Firebase Console
- Añade SHA-1 en Google Cloud Console
- Verifica `google-services.json` en `android/app/`

### Splash se queda en loading infinito
- Verifica que `authStateChangesProvider` está funcionando
- Revisa console de Firebase para errores de Auth

---

## 📝 Próximos Pasos

Después de probar FASE 2:

**FASE 3: Base de Datos de Preguntas**
1. Script generador desde REST Countries API
2. 7 tipos de preguntas
3. Cargar en Firestore

**FASE 4: Core del Juego**
1. GameScreen
2. Question widgets (silueta, bandera, etc.)
3. Timer circular
4. GameProvider

---

## 📊 Archivos Creados

### Providers (2 archivos)
- `lib/presentation/providers/auth_provider.dart` (2411 bytes)
- `lib/presentation/providers/user_provider.dart` (3849 bytes)

### Screens (3 archivos)
- `lib/presentation/screens/splash/splash_screen.dart` (5148 bytes)
- `lib/presentation/screens/auth/login_screen.dart` (6233 bytes)
- `lib/presentation/screens/home/home_screen.dart` (17596 bytes)

### App (1 archivo)
- `lib/app.dart` (2826 bytes)

### Widgets Comunes (3 archivos)
- `lib/presentation/widgets/common/loading_widget.dart` (1103 bytes)
- `lib/presentation/widgets/common/error_widget.dart` (1428 bytes)
- `lib/presentation/widgets/common/custom_button.dart` (2808 bytes)

**Total**: ~42KB de código UI funcional.

---

## 🚀 Commit y Push

```bash
# Ver cambios
git status

# Añadir archivos
git add .

# Commit
git commit -m "feat: complete FASE 2 - authentication and home screens

- Add AuthProvider for Google/Apple sign-in
- Add UserProvider for profile and stats
- Add SplashScreen with animations
- Add LoginScreen with social login buttons
- Add HomeScreen with full dashboard
- Add Go Router configuration
- Add common widgets (Loading, Error, Button)

Features:
- Animated splash screen
- Google + Apple sign-in
- User profile management
- Daily games tracking
- Game mode cards (casual/ranked)
- Protected routes with auth

Files created:
- lib/presentation/providers/ (2 files)
- lib/presentation/screens/ (3 screens)
- lib/presentation/widgets/common/ (3 widgets)
- lib/app.dart (routing)"

# Push
git push origin main
```

---

**¡FASE 2 completada! 🎉** Ahora tienes un flujo completo de autenticación y una home screen funcional.
