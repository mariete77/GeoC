# Protocolo de Revisión de Calidad de Preguntas (GeoC)

Este documento detalla el procedimiento para identificar y corregir preguntas con respuestas sin sentido o formatos incorrectos.

## 1. Identificación de Problemas
Las preguntas "sin sentido" suelen manifestarse por:
- **Opciones vacías o insuficientes:** Menos de 2 opciones disponibles.
- **Respuesta correcta ausente:** La `correctAnswer` no está en el array `options`.
- **Texto en idiomas incorrectos:** Mezcla de español/inglés en las opciones.
- **Nombres genéricos:** Opciones como "Opción A", "Opción B".

## 2. Herramientas de Auditoría
Utiliza los scripts ubicados en `scripts/`:
- `scripts/analyze_nonsense.py`: Identifica preguntas con menos de 2 opciones, opciones duplicadas o donde la respuesta correcta no está presente.
- `scripts/analyze_questions.py`: Realiza un análisis general de calidad (idiomas, formatos, duplicados).

## 3. Flujo de Corrección
1. **Auditoría:** Ejecuta `python scripts/analyze_nonsense.py` para listar las preguntas problemáticas.
2. **Corrección Automática:**
   - Para rellenar opciones vacías: `python scripts/fix_missing_options.py`.
   - Para limpiar idiomas y duplicados: `python scripts/fix_and_clean_questions.py`.
3. **Validación:** Verifica los cambios abriendo `scripts/questions_fixed_options.json` y buscando los IDs detectados anteriormente.
4. **Despliegue:** Una vez validado, ejecuta el importador mejorado:
   `python scripts/import_improved.py --file=scripts/questions_fixed_options.json`

## 4. Reporte de Incidencias
Si encuentras una pregunta que, tras la corrección automática, sigue siendo incorrecta:
- Anota el `ID` de la pregunta.
- Comprueba si el `extraData.countryName` es correcto.
- Corrige manualmente en el archivo JSON y notifica al equipo de QA.
