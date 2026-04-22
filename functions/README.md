# Cloud Functions - GeoC

Este directorio contiene las Cloud Functions para Firebase que manejan el sistema ELO multijugador.

## 🎯 Funciones implementadas

### 1. `onUpdateMatchResult`
Se activa automáticamente cuando el campo `result` de un match es creado/actualizado en Firestore.

**Qué hace:**
- Actualiza el ELO de ambos jugadores en sus documentos de usuario (`/users/{userId}/elo`)
- Actualiza las estadísticas (wins/losses/draws/totalGames)
- Usa los valores calculados en el cliente Flutter

**Trigger:** `firestore.document('matches/{matchId}')`

---

### 2. `onCreateUser` (opcional)
Inicializa valores por defecto cuando se crea un nuevo usuario.

**Qué hace:**
- Establece ELO = 1000 si no existe
- Inicializa `stats` con ceros si no existen

**Trigger:** `firestore.document('users/{userId}')`

---

## 🚀 Despliegue

### Requisitos previos

```bash
# Instalar Node.js 18 o superior
node --version  # Debe ser >= 18

# Instalar Firebase CLI globalmente
npm install -g firebase-tools

# Autenticarse con Firebase (solo la primera vez)
firebase login
```

### Paso 1: Instalar dependencias

```bash
cd functions
npm install
```

### Paso 2: Probar localmente (opcional pero recomendado)

```bash
# Ejecutar emuladores
npm run serve

# En otra terminal, probar la función
# (requiere tener la app Flutter conectada al emulador)
```

### Paso 3: Compilar TypeScript

```bash
npm run build
```

### Paso 4: Desplegar a Firebase

```bash
npm run deploy
```

Este comando compila el TypeScript y despliega solo las funciones a Firebase.

---

## 📋 Estructura del documento de match

La función espera esta estructura en Firestore:

```json
{
  "players": ["userId1", "userId2"],
  "result": {
    "winnerId": "userId1",  // o null si empate
    "scores": {
      "userId1": 15,
      "userId2": 12
    },
    "eloChanges": {
      "userId1": 16,
      "userId2": -16
    },
    "newElo": {
      "userId1": 1016,
      "userId2": 984
    }
  }
}
```

**Nota:** La app Flutter ya genera esta estructura en `MultiplayerNotifier._finishMatch()`.

---

## 🔧 Estructura del documento de usuario (esperado)

```json
{
  "displayName": "Mario",
  "elo": 1016,
  "stats": {
    "totalGames": 25,
    "wins": 15,
    "losses": 9,
    "draws": 1,
    "totalCorrectAnswers": 300,
    "currentWinStreak": 3,
    "bestWinStreak": 5
  },
  "createdAt": "...",
  "lastLoginAt": "..."
}
```

---

## 🐛 Debugging

### Ver logs de las funciones

```bash
# Ver todos los logs
firebase functions:log

# Ver logs de una función específica
firebase functions:log --only onUpdateMatchResult

# Ver logs en tiempo real (watch)
firebase functions:log --only onUpdateMatchResult --watch
```

### Comprobar logs en la consola de Firebase

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto
3. En el menú izquierdo, ir a **Functions** → **Logs**

---

## ⚠️ Importante

### Permisos de Firebase Admin

Las Cloud Functions usan `firebase-admin` que tiene permisos completos para leer/escribir en Firestore. Esto permite actualizar el perfil del oponente sin restricciones.

### Costos

- **Plan Blaze (pago por uso) obligatorio:** Las Cloud Functions solo funcionan en el plan Blaze.
- **Invocaciones gratis:** 125,000/mes (incluidas en Blaze)
- **GB-s de CPU gratis:** 40,000/mes
- **GB de red saliente:** 10 GB/mes

Con el uso actual de GeoC, deberías estar dentro de los límites gratuitos.

---

## 📝 Resumen del flujo

```
1. Flutter: MultiplayerNotifier._finishMatch()
   ↓
2. Firestore: /matches/{matchId}/result se guarda
   ↓
3. Cloud Function: onUpdateMatchResult se activa
   ↓
4. Firebase Admin: Actualiza ambos /users/{userId}/elo
   ↓
5. ✓ ELOs sincronizados para ambos jugadores
```

---

## ❓ Preguntas frecuentes

**¿Por qué no calcular el ELO en la Cloud Function?**

- El cálculo es matemáticamente complejo y la lógica ya existe en Flutter (`elo_calculator.dart`)
- Mantenerlo en el cliente evita duplicación de código
- La función solo necesita persistir los resultados

**¿Qué pasa si la función falla?**

- La función se reintentará automáticamente (hasta 1 vez por defecto)
- Los ELOs ya están guardados en el match document como respaldo
- El cliente puede leer de ahí hasta que se actualice el usuario

**¿Puedo desactivar las funciones?**

- Sí, puedes eliminarlas desde Firebase Console
- Sin ellas, el ELO solo se actualizará cuando cada jugador termine su partida

---

## 📚 Referencias

- [Firebase Functions docs](https://firebase.google.com/docs/functions)
- [Firestore triggers](https://firebase.google.com/docs/functions/firestore-events)
- [TypeScript en Functions](https://firebase.google.com/docs/functions/typescript)
