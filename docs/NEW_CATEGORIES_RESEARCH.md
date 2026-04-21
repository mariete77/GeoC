# GeoC — Investigación de Nuevas Categorías de Preguntas

## Categorías Actuales (13 tipos, 2,640 preguntas)
flag(634), capital(374), region(367), population(211), language(211), currency(207),
area(200), silhouette(194), city(72), river(61), mountain(60), lake(47), border(2)

---

## 🟢 CATEGORÍAS NUEVAS — Alta Viabilidad

### 1. 🏝️ ISLAND / ARCHIPIÉLAGO
**Ejemplo:** "¿A qué país pertenece la isla de Bali?" / "¿Cuál es el archipiélago más grande del mundo?"
- **Por qué mola:** Las islas son icónicas y muy reconocibles. Seterra tiene un modo entero de islas.
- **Datos:** REST Countries (capitalInfo), Wikipedia, CIA World Factbook
- **Preguntas estimadas:** 150+
- **Formato:** Multiple choice + type-answer
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - ¿A qué país pertenece esta isla? (80+)
  - ¿Cuál es la isla más grande de...? (30+)
  - Nombrar islas de un archipiélago (Canarias, Hawái, Maldivas...) (40+)

### 2. 🗺️ COORDENADAS / GPS
**Ejemplo:** "¿Qué capital está en las coordenadas 48.8°N, 2.3°E?" → París
- **Por qué mola:** Muy popular en GeoGuessr. Combina conocimiento espacial con lógica.
- **Datos:** OpenStreetMap, REST Countries (latlng)
- **Preguntas estimadas:** 100+
- **Formato:** Multiple choice (4 ciudades, ¿cuál está más cerca de estas coords?)
- **Dificultad implementación:** MEDIA
- **Subtipos:**
  - ¿Qué ciudad está en estas coordenadas? (50+)
  - ¿Qué país está entre X° y Y° de latitud? (30+)
  - ¿Cuál está más al norte/sur? (20+)

### 3. 🌡️ CLIMA / BIOMA
**Ejemplo:** "¿Qué país tiene un clima predominantemente tropical seco?" / "¿En qué bioma se encuentra el Sahel?"
- **Por qué mola:** Toca geografía física real, muy educativo y visualizable.
- **Datos:** Köppen climate classification datasets, World Bank
- **Preguntas estimadas:** 80+
- **Formato:** Multiple choice
- **Dificultad implementación:** MEDIA
- **Subtipos:**
  - ¿Qué clima tiene [país]? (40+)
  - ¿Qué bioma es characteristic de...? (20+)
  - ¿País con clima [tipo]? (20+)

### 4. 🕐 ZONA HORARIA (timezone)
**Ejemplo:** "Si son las 12:00 en Madrid, ¿qué hora es en Tokio?" / "¿Cuántas zonas horarias tiene Rusia?"
- **Por qué mola:** Muy práctica, la gente la usa al viajar. Diferenciador único.
- **Datos:** REST Countries (timezones), IANA timezone database
- **Preguntas estimadas:** 80+
- **Formato:** Multiple choice
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - Diferencia horaria entre capitales (30+)
  - ¿Qué país tiene más zonas horarias? (20+)
  - ¿Qué hora es en X si en Y son las Z? (30+)

### 5. 🏛️ PATRIMONIO DE LA HUMANIDAD (unesco)
**Ejemplo:** "¿En qué país se encuentra Machu Picchu?" / "¿Qué monumento es Patrimonio de la Humanidad en Francia?"
- **Por qué mola:** Conexión cultura-geografía, muy visual. +1,100 sitios UNESCO.
- **Datos:** UNESCO World Heritage List API (whc.unesco.org)
- **Preguntas estimadas:** 200+
- **Formato:** Multiple choice + type-answer
- **Dificultad implementación:** MEDIA
- **Subtipos:**
  - ¿En qué país está [sitio UNESCO]? (120+)
  - ¿Qué sitio UNESCO está en [país]? (50+)
  - ¿Cuántos sitios UNESCO tiene [país]? (30+)

### 6. 🚩 HIMNO NACIONAL (anthem)
**Ejemplo:** Reproducir fragmento del himno → "¿De qué país es este himno?"
- **Por qué mola:** AUDIO quiz — diferenciador enorme. Muy viral en TikTok/Reels.
- **Datos:** Himnos disponibles como audio público (CIA World Factbook links)
- **Preguntas estimadas:** 100+ (193 países)
- **Formato:** Multiple choice (con audio)
- **Dificultad implementación:** ALTA (necesita assets de audio)
- **Nota:** Se necesitaría añadir reproductor de audio al widget de pregunta

### 7. 🏳️ COLORES DE BANDERA (flagColors)
**Ejemplo:** "¿Qué bandera tiene rayas horizontales verde, amarillo y rojo?" / "¿Cuántas banderas tienen la luna creciente?"
- **Por qué mola:** Complemento a "flag" — en lugar de reconocer la bandera, identificarla por descripción. Más desafiante.
- **Datos:** Flag descriptions from CIA World Factbook (ya procesable)
- **Preguntas estimadas:** 120+
- **Formato:** Multiple choice
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - ¿Qué bandera tiene estos colores? (40+)
  - ¿Cuántas banderas tienen [elemento]? (30+)
  - ¿Qué bandera NO tiene el color rojo? (25+)
  - ¿Qué bandera es la más similar a [país]? (25+)

### 8. 📏 FRONTERAS — EXPANDIDO (neighbors)
**Ejemplo:** "¿Cuántos países vecinos tiene Alemania?" / "¿Cuál de estos países NO fronteriza con Francia?"
- **Por qué mola:** La categoría "border" actual solo tiene 2 preguntas. Es un concepto genial, necesita expansión masiva.
- **Datos:** REST Countries (borders), Natural Earth
- **Preguntas estimadas:** 200+
- **Formato:** Multiple choice
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - ¿Cuántos vecinos tiene [país]? (50+)
  - ¿Cuáles son los vecinos de [país]? (50+)
  - ¿Qué país NO es vecino de [país]? (50+)
  - ¿Qué dos países comparten la frontera más larga? (30+)
  - ¿Qué país es el único vecino de [país]? (20+)

### 9. 🌊 MAR / OCÉANO / GOLFO (sea)
**Ejemplo:** "¿Qué país tiene costa en el Mar Mediterráneo?" / "¿Cuál es el océano más grande?"
- **Por qué mola:** Complementa ríos y lagos. Muy natural para geografía.
- **Datos:** Natural Earth (marine polygons), Wikipedia
- **Preguntas estimadas:** 80+
- **Formato:** Multiple choice
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - ¿Qué océano baña las costas de [país]? (30+)
  - ¿Qué países tienen costa en [mar/golfo]? (30+)
  - ¿Cuál es el mar/golfo más grande? (20+)

### 10. 🌋 VOLCÁN / DESIERTO (volcano / desert)
**Ejemplo:** "¿Cuál es el volcán más alto del mundo?" / "¿En qué país está el desierto de Atacama?"
- **Por qué mola:** Geografía física espectacular. Complementa montañas y ríos.
- **Datos:** Smithsonian Global Volcanism Program, Wikipedia
- **Preguntas estimadas:** 60+
- **Formato:** Multiple choice + type-answer
- **Dificultad implementación:** FÁCIL
- **Subtipos:**
  - ¿Dónde está [volcán/desierto]? (30+)
  - ¿Cuál es el volcán/desierto más [grande/alto]? (15+)
  - ¿Qué país tiene más volcanes? (15+)

---

## 🟡 CATEGORÍAS — Viabilidad Media

### 11. 🏙️ CIUDAD POR POBLACIÓN (cityPopulation)
**Ejemplo:** "¿Cuál es la ciudad más poblada de África?" / "Ordena por población: Tokio, Delhi, Shanghai"
- **Por qué mola:** Datos concretos y actualizables. Buen formato de ordenación.
- **Datos:** UN World Urbanization Prospects, Worldometer
- **Preguntas estimadas:** 60+
- **Dificultad:** FÁCIL

### 12. 📞 CÓDIGO DE LLAMADA (callingCode)
**Ejemplo:** "¿Qué país tiene el código de llamada +54?" → Argentina
- **Por qué mola:** Trivial pero adictivo. La gente los conoce parcialmente.
- **Datos:** REST Countries (callingCodes)
- **Preguntas estimadas:** 80+
- **Dificultad:** FÁCIL

### 13. 🌐 DOMINIO DE INTERNET (tld)
**Ejemplo:** "¿Qué país usa el dominio .br?" → Brasil
- **Por qué mola:** Curioso, mezcla tech con geografía.
- **Datos:** REST Countries (tld)
- **Preguntas estimadas:** 80+
- **Dificultad:** FÁCIL

### 14. 🚗 LADO DE CONDUCCIÓN (drivingSide)
**Ejemplo:** "¿En qué países se conduce por la izquierda?"
- **Por qué mola:** Curioso y útil al viajar. ~65 países con izquierda.
- **Datos:** Wikipedia
- **Preguntas estimadas:** 40+
- **Dificultad:** FÁCIL

### 15. 🏝️ MAPA MUDO — ¿DÓNDE ESTÁ? (pinpoint)
**Ejemplo:** Mostrar mapa con un punto → "¿Qué país es este?"
- **Por qué mola:** Visual e interactivo. Competencia directa con Seterra.
- **Datos:** Natural Earth GeoJSON (ya lo tenemos para siluetas)
- **Preguntas estimadas:** 100+
- **Dificultad:** ALTA (necesita widget de mapa interactivo)

### 16. 🗽 MONUMENTO FAMOSO (landmark)
**Ejemplo:** Mostrar foto → "¿En qué ciudad está este monumento?"
- **Por qué mola:** MUY visual y viral. Similar a flags pero con fotos.
- **Datos:** Unsplash/Wikipedia Commons (imágenes libres)
- **Preguntas estimadas:** 100+
- **Dificultad:** MEDIA (necesita curación de imágenes)

### 17. 🍽️ COMIDA TÍPICA (dish)
**Ejemplo:** "El ceviche es un plato típico de qué país?" / "¿De qué país es el sushi?"
- **Por qué mola:** Altamente compartible en redes. Conecta cultura con geografía.
- **Datos:** Manual (fácil de investigar)
- **Preguntas estimadas:** 80+
- **Dificultad:** FÁCIL (pero manual)

### 18. 🏟️ ESTADIO / EVENTO DEPORTIVO (stadium)
**Ejemplo:** "¿En qué ciudad está el estadio Maracaná?" / "¿Qué país acogió los Juegos Olímpicos de 1992?"
- **Por qué mola:** Muy atractivo para público deportivo.
- **Datos:** Wikipedia, Olympics API
- **Preguntas estimadas:** 60+
- **Dificultad:** FÁCIL

---

## 🔵 CATEGORÍAS CREATIVAS — Únicas

### 19. 🔀 COMPARACIÓN (comparison)
**Ejemplo:** "¿Qué es más grande: España o Tailandia?" / "¿Qué país tiene más habitantes: Nigeria o Brasil?"
- **Por qué mola:** Formato "esto o aquello" — muy popular en quiz apps (Higher Lower Game).
- **Datos:** Reutiliza population, area, etc.
- **Preguntas estimadas:** 200+ (combinaciones infinitas)
- **Dificultad:** FÁCIL (se genera automáticamente)

### 20. 📍 CAPITAL → PAÍS INVERSO (capitalToCountry)
**Ejemplo:** "La capital Tallin pertenece a qué país?" → Estonia
- **Por qué mola:** Es el reverso de "capital" — pregunta por país dada la capital. Parecido pero diferente skill mental.
- **Datos:** Reutiliza datos de capital
- **Preguntas estimadas:** 193+
- **Dificultad:** TRIVIAL (transformar preguntas existentes)

### 21. 🎵 ACENTO / IDIOMA EN AUDIO (accent)
**Ejemplo:** Reproducir audio → "¿En qué país se habla con este acento?"
- **Por qué mola:** Muy original, contenido viral.
- **Dificultad:** ALTA (necesita grabaciones)
- **Preguntas:** 50+

### 22. 🌍 PAÍS INDEPENDENCIA (independence)
**Ejemplo:** "¿Qué país obtuvo su independencia en 1821?" / "¿De qué país se independizó Argelia?"
- **Por qué mola:** Histórico-geográfico, muy educativo.
- **Datos:** CIA World Factbook (Independence field)
- **Preguntas estimadas:** 150+
- **Dificultad:** FÁCIL

### 23. 🗳️ CAPITAL DEL ESTADO / PROVINCIA (stateCapital)
**Ejemplo:** "¿Cuál es la capital de Texas?" / "¿Cuál es la capital de Baviera?"
- **Por qué mola:** Nivel de detalle sub-nacional. Para experts.
- **Datos:** Wikipedia, GeoNames
- **Preguntas estimadas:** 200+ (50 US states + 16 DE states + 32 MX states + ...)
- **Dificultad:** MEDIA

---

## 📊 RESUMEN — TOP 10 RECOMENDADAS

| # | Categoría | Preguntas | Dificultad | Impacto |
|---|-----------|-----------|------------|---------|
| 1 | 🏝️ Island/Archipiélago | 150+ | Fácil | Alto |
| 2 | 🗺️ Coordenadas/GPS | 100+ | Media | Muy alto |
| 3 | 🕐 Zona Horaria | 80+ | Fácil | Alto |
| 4 | 🏛️ UNESCO Heritage | 200+ | Media | Muy alto |
| 5 | 🏳️ Colores de Bandera | 120+ | Fácil | Alto |
| 6 | 📏 Fronteras (expandido) | 200+ | Fácil | Alto |
| 7 | 🌊 Mar/Océano/Golfo | 80+ | Fácil | Medio |
| 8 | 🔀 Comparación | 200+ | Fácil | Muy alto |
| 9 | 🌋 Volcán/Desierto | 60+ | Fácil | Medio |
| 10 | 🍽️ Comida Típica | 80+ | Fácil | Alto |

**Total potencial: ~1,270+ preguntas nuevas**

---

## 🎯 ESTRATEGIA DE IMPLEMENTACIÓN SUGERIDA

### Fase 1 — Rápido (datos de REST Countries, 1-2 días)
- Zona horaria (timezone) — datos ya en API
- Dominio internet (tld) — datos ya en API
- Código llamada (callingCode) — datos ya en API
- Lado de conducción (drivingSide) — Wikipedia
- Fronteras expandido (neighbors) — REST Countries
→ **+440 preguntas con mínimo esfuerzo**

### Fase 2 — Medio (datasets públicos, 3-5 días)
- Island/Archipiélago — REST Countries + Wikipedia
- Mar/Océano/Golfo — Natural Earth + manual
- Volcán/Desierto — Smithsonian + Wikipedia
- Comparación (comparison) — auto-generado
- Colores de bandera — CIA Factbook
→ **+610 preguntas**

### Fase 3 — Ambicioso (curación, 1-2 semanas)
- UNESCO Heritage — UNESCO API
- Coordenadas/GPS — REST Countries
- Comida Típica — manual
- Monumento Famoso — imágenes
→ **+400+ preguntas**

### Fase 4 — Premium (audio/interactivo)
- Himno Nacional — audio assets
- Mapa Mudo — widget interactivo
- Acento/Idioma — audio grabaciones
