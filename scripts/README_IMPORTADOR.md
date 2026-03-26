# 📊 Importador de Preguntas - GeoQuiz Battle

Herramientas para crear y gestionar preguntas de forma fácil.

## 🎯 Opciones Disponibles

### 1. **Script de Importación CSV Avanzado** (`question_csv_importer.dart`)
Importa preguntas desde CSV, Excel o Google Sheets.

### 2. **Panel Web de Administración** (en desarrollo)
Interfaz visual para gestionar preguntas.

---

## 📁 Script CSV Avanzado

### 🚀 Uso Rápido

```bash
# 1. Crear archivo CSV con preguntas (ver ejemplo)
# 2. Importar a JSON
dart scripts/question_csv_importer.dart --input=mis_preguntas.csv

# 3. Importar a Firestore (cuando tengas Firebase configurado)
dart scripts/import_questions_firestore.dart
```

### 📝 Formato CSV

| Columna | Requerido | Descripción | Ejemplo |
|---------|-----------|-------------|---------|
| `type` | ✅ | Tipo de pregunta | `flag`, `capital`, `population`, `area`, `river`, `silhouette`, `city_photo` |
| `question` | ❌ | Texto de la pregunta | `¿De qué país es esta bandera?` |
| `correct` | ✅ | Respuesta correcta | `España` |
| `option1` | ❌ | Opción incorrecta 1 | `Francia` |
| `option2` | ❌ | Opción incorrecta 2 | `Italia` |
| `option3` | ❌ | Opción incorrecta 3 | `Portugal` |
| `difficulty` | ❌ | Dificultad (default: medium) | `easy`, `medium`, `hard` |
| `imageUrl` | ❌ | URL de imagen | `https://flagcdn.com/es.svg` |
| `extraData` | ❌ | Datos extra en JSON | `{"countryCode": "es"}` |

### 🎯 Tipos de Preguntas

1. **`flag`** - Banderas
   - `question`: Opcional (se genera automáticamente)
   - `imageUrl`: URL de bandera (ej: `https://flagcdn.com/w320/es.png`)
   - `extraData`: `{"countryCode": "es"}`

2. **`capital`** - Capitales
   - `question`: `¿Cuál es la capital de X?`
   - `correct`: Capital correcta
   - `option1-3`: Capitales incorrectas

3. **`population`** - Población comparativa
   - `question`: `¿Qué país tiene más/menos población?`
   - `correct`: País correcto
   - `option1-3`: Países incorrectos

4. **`area`** - Extensión territorial
   - `question`: `¿Qué país es más grande/pequeño?`
   - `correct`: País correcto
   - `option1-3`: Países incorrectos

5. **`river`** - Ríos
   - `question`: Texto de la pregunta
   - `correct`: Río correcto
   - `option1-3`: Ríos incorrectos

6. **`silhouette`** - Siluetas de países
   - `question`: `¿De qué país es esta silueta?`
   - `imageUrl`: URL de silueta
   - `correct`: País correcto
   - `option1-3`: Países incorrectos

7. **`city_photo`** - Fotos de ciudades
   - `question`: `¿En qué ciudad se encuentra...?`
   - `imageUrl`: URL de foto
   - `correct`: Ciudad correcta
   - `option1-3`: Ciudades incorrectas

### 📋 Ejemplos

#### Banderas
```csv
type,correct,option1,option2,option3,difficulty,imageUrl,extraData
flag,España,Francia,Italia,Portugal,easy,https://flagcdn.com/w320/es.png,{"countryCode":"es"}
flag,Francia,España,Italia,Alemania,easy,https://flagcdn.com/w320/fr.png,{"countryCode":"fr"}
```

#### Capitales
```csv
type,question,correct,option1,option2,option3,difficulty
capital,¿Cuál es la capital de Francia?,París,Londres,Berlín,Madrid,medium
capital,¿Cuál es la capital de España?,Madrid,Barcelona,Valencia,Sevilla,medium
```

#### Ríos
```csv
type,question,correct,option1,option2,option3,difficulty
river,¿Cuál es el río más largo de España?,Tajo,Ebro,Duero,Guadalquivir,medium
river,¿Cuál es el río más largo del mundo?,Amazonas,Nilo,Yangtsé,Misisipi,easy
```

### 🛠️ Opciones del Script

```bash
# Importar archivo específico
dart scripts/question_csv_importer.dart --input=mis_preguntas.csv

# Especificar formato
dart scripts/question_csv_importer.dart --input=datos.xlsx --format=excel

# Cambiar delimitador (para CSV con ;)
dart scripts/question_csv_importer.dart --input=datos.csv --delimiter=;

# Sin encabezado
dart scripts/question_csv_importer.dart --input=datos.csv --no-header

# Especificar salida
dart scripts/question_csv_importer.dart --input=datos.csv --output=preguntas_nuevas.json

# Ayuda
dart scripts/question_csv_importer.dart --help
```

### 🔄 Flujo de Trabajo

1. **Crear CSV** en Google Sheets/Excel
2. **Exportar** como CSV
3. **Importar** a JSON:
   ```bash
   dart scripts/question_csv_importer.dart --input=exportado.csv
   ```
4. **Validar** el JSON generado
5. **Importar** a Firestore:
   ```bash
   dart scripts/import_questions_firestore.dart
   ```

---

## 🌐 Panel Web de Administración (Próximamente)

### Características Planificadas
- ✅ Autenticación con Firebase
- 📝 CRUD completo de preguntas
- 🖼️ Subida de imágenes a Firebase Storage
- 👁️ Vista previa en tiempo real
- 📤 Exportación/Importación CSV/JSON
- 🔍 Búsqueda y filtrado
- 📊 Estadísticas

### Tecnología
- Flutter Web
- Firebase Auth + Firestore + Storage
- Riverpod para estado

---

## 🎯 Generación Automática

### Scripts Existentes

| Script | Descripción |
|--------|-------------|
| `generate_questions.dart` | Genera 4 tipos desde REST Countries API |
| `generate_questions_with_manual.dart` | Genera 5 tipos (incluye ríos) |
| `rivers_manual.dart` | Datos manuales de 25 ríos |

### Uso
```bash
# Generar preguntas automáticas
dart scripts/generate_questions_with_manual.dart

# Verificar preguntas generadas
cat scripts/questions.json | head -5

# Importar a Firestore
dart scripts/import_questions_firestore.dart
```

---

## 💡 Consejos para Crear Preguntas

### 1. **Variedad de Dificultad**
- **Fácil**: Países grandes, capitales conocidas
- **Medio**: Países medianos, capitales europeas
- **Difícil**: Países pequeños, capitales poco conocidas

### 2. **Opciones Incorrectas**
- Usar países/ciudades de la misma región
- Evitar opciones demasiado obvias
- Mezclar niveles de dificultad

### 3. **Imágenes**
- **Banderas**: `https://flagcdn.com/w320/{code}.png`
- **Siluetas**: Crear imágenes SVG/PNG transparentes
- **Ciudades**: Usar fotos CC0 de Unsplash/Pexels

### 4. **Datos Extra**
```json
{
  "countryCode": "es",
  "region": "Europe",
  "hint": "País en el sur de Europa"
}
```

---

## 🚨 Solución de Problemas

### ❌ "Archivo no encontrado"
```bash
# Verificar que el archivo existe
ls -la mis_preguntas.csv

# Usar ruta completa
dart scripts/question_csv_importer.dart --input=/ruta/completa/mis_preguntas.csv
```

### ❌ "Error de formato CSV"
```bash
# Verificar delimitador
cat mis_preguntas.csv | head -1

# Especificar delimitador correcto
dart scripts/question_csv_importer.dart --input=mis_preguntas.csv --delimiter=;
```

### ❌ "Firebase no inicializado"
```bash
# Configurar Firebase primero
flutterfire configure

# Generar firebase_options.dart
dart run build_runner build --delete-conflicting-outputs
```

---

## 📈 Estadísticas Objetivo

| Tipo | Cantidad Objetivo | Actual | Estado |
|------|------------------|--------|--------|
| Banderas | 100 | ~100 | ✅ |
| Capitales | 100 | ~100 | ✅ |
| Población | 50 | 50 | ✅ |
| Extensión | 50 | 50 | ✅ |
| Ríos | 25 | 25 | ✅ |
| Siluetas | 100 | 0 | ⏳ |
| Fotos de ciudades | 50 | 0 | ⏳ |
| **Total** | **425** | **~325** | **76%** |

---

## 🔄 Integración con Google Sheets

### Método 1: Exportar como CSV
1. Crear hoja con columnas del formato CSV
2. `Archivo → Descargar → Valores separados por comas (.csv)`
3. Usar script de importación

### Método 2: API de Google Sheets (Futuro)
```dart
// En desarrollo - permitirá importar directamente desde Sheets
```

---

## 📞 Soporte

### Problemas Comunes
1. **Encoding incorrecto**: Guardar CSV como UTF-8
2. **Comillas en valores**: Usar `"valor con, coma"`
3. **Delimitador incorrecto**: Especificar con `--delimiter`

### Recursos
- [Plantilla CSV](ejemplo_preguntas.csv)
- [Documentación Firestore](https://firebase.google.com/docs/firestore)
- [API REST Countries](https://restcountries.com/)

---

**✨ Con estas herramientas puedes crear cientos de preguntas en minutos.**