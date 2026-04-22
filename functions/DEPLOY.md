# GeoC Cloud Functions - Despliegue Local

## 🚀 Instrucciones de despliegue

### 1. Instalar dependencias
```bash
cd functions
npm install
```

### 2. Compilar y desplegar
```bash
npm run deploy
```

Este comando:
1. Compila TypeScript a JavaScript
2. Despliega las funciones a Firebase

---

## ✅ Qué hace esta función

**`onUpdateMatchResult`** - Se activa cuando un match termina:
- ✅ Actualiza ELO de ambos jugadores
- ✅ Actualiza estadísticas (wins/losses/draws)
- ✅ Sincroniza datos entre ambos usuarios

---

## 📖 Documentación completa

Ver `functions/README.md` para detalles completos.
