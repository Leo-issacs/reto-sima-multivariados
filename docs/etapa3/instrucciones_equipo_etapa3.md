# Reto SIMA · Etapa 3 — Instrucciones para el equipo

**Entrega:** jueves 15 de octubre (informe de ≤ 10 páginas y liga a la presentación).
**Fecha límite de las tareas de esta guía:** martes 13 de octubre, 20:00.
**Ensayo:** miércoles 14 de octubre (15 minutos, todos).

---

## 0. El proyecto en un minuto (todos deben poder explicarlo)

- **Qué queremos saber:** cuánto mejora la meteorología del día la identificación de los días en que una estación supera 25 µg/m³ de PM2.5 (promedio de 24 h), frente a un modelo que solo sabe *qué estación es* y *en qué temporada estamos*.
- **Por qué importa:** el PM2.5 tiene evidencia sólida de asociación con mortalidad por exposición de pocos días. SIMA comunica alertas, y saber cuándo pesa el clima ayuda a vigilar mejor.
- **Datos:** 13 estaciones de SIMA, de 2021 a 2025. La unidad es el «estación-día». Usamos PM2.5 y 8 variables meteorológicas: temperatura, humedad, radiación solar, presión, viento (rapidez y dirección como componentes u y v) y horas con lluvia. Quedaron **15 390 estación-días**.
- **Limpieza:**
  - 12.3 % de las horas faltaba en los archivos originales; en PM2.5, 26 %.
  - Invalidamos 0.7 % por lecturas inconsistentes: radiación solar de noche, viento muy distinto al del resto de la red, valores idénticos durante 24 h, saltos bruscos y valores fuera de rango.
  - Imputamos 1.0 %, solo huecos de hasta 3 horas.
- **Técnicas:**
  - **PCA** (interdependencia) para ver cómo se agrupan las variables meteorológicas. Salen 3 ejes: «día cálido, soleado y ventilado», «día húmedo y lluvioso» y «presión baja y poco viento».
  - **Análisis discriminante lineal (LDA)** (dependencia) para clasificar los días. Comparamos M0 (estación + temporada) contra M1 (M0 + meteorología).
- **Cómo validamos:** entrenamos con 2021–2023 y probamos **una sola vez** con 2024–2025, años que el modelo no vio.
- **Resultado principal:**
  - El AUC sube de **0.72 a 0.79** (+0.07; intervalo de confianza del 95 %: 0.05 a 0.09).
  - M1 detecta el **73 %** de los días con superación; M0 solo el **58 %**.
- **Dónde ayuda más:** en la temporada **seca-cálida (marzo–mayo)**, con +0.14. En la temporada de lluvias casi no ayuda.
- **Qué variables pesan:** los días con superación tienen **menos viento**, **presión más baja de lo normal** y **más temperatura**.
- **Problemas que encontramos:**
  - Sensores con lecturas sospechosas: viento en SO2 y NE2 en 2021; radiación solar de noche en NO2, SE3 y CE. Agregamos una regla de limpieza para ellos.
  - Algunas estaciones conservan pocos días; NO2, solo el 28 %.
- **Qué sigue:** una interfaz para usar el modelo, probarlo con meteorología *pronosticada* (para que sirva como alerta real) y el informe final.
- **Lo que nos dijo SIMA el viernes 9 de octubre (pregunta del equipo 5) y por qué nos importa:**
  - **2021:** se renovaron los sensores de **viento** (WSR y WDR) en todas las estaciones, y los analizadores de O3, NO2, SO2 y CO (excepto en SE2, SO2 y NTE2). En nuestros datos el viento cambia de nivel justo entre marzo y abril de 2021. Eso confirma que fue buena idea **no modelar 2020**, y las lecturas raras de viento de SO2 en junio–octubre de 2021 ocurrieron poco después de la instalación.
  - **2025:** se compraron 5 equipos nuevos de **PM2.5** (Thermo 5014i) para SE2, NTE2, SUR, SO2 y NO; se completó CO en SE2, SO2 y NTE2; y se cambiaron las bombas de los equipos de PM10 (BAM). El cambio de equipo de PM2.5 cae **dentro de nuestro año de prueba (2025)**, así que lo vamos a revisar por separado y le preguntaremos a SIMA las fechas de instalación.

**Vocabulario mínimo**
- **AUC:** probabilidad de que el modelo asigne un puntaje más alto a un día con superación que a uno sin superación. 0.5 equivale al azar y 1.0 es perfecto. No es un porcentaje de aciertos.
- **Sensibilidad:** de los días que de verdad superaron, qué porcentaje detecta el modelo.
- **Bootstrap por bloques:** repetimos el cálculo 1 000 veces remuestreando bloques de 14 días, para saber qué tan seguro es el resultado.

---

## 1. Reparto de tareas (por herramienta)

Leonardo asigna cada rol a una persona según la IA que tenga.

| Rol | Quién (lo llena Leo) | Tarea | Entrega |
|---|---|---|---|
| **Expositor e integración** | Leonardo | Expone; integra el informe con Claude, Claude Code y Codex | Informe final y ensayo |
| **A. Tiene ChatGPT** | ________ | Contexto ambiental de las estaciones y preguntas para SIMA (necesita búsqueda web con fuentes) | 1 página, martes 20:00 |
| **B. Tiene Claude** | ________ | Banco de 15 preguntas y respuestas, y revisión de coherencia del guion | 1–2 páginas, martes 20:00 |
| **C. No usa IA** | ________ | Diapositivas en Google Slides, prueba de la interfaz y cronómetro del ensayo | Liga + capturas, martes 20:00 |

En la exposición presenta **una sola persona**, pero **las preguntas las contestamos todos**: cada quien contesta las de su tema. La rúbrica evalúa que otros integrantes participen al responder.

---

## 2. Rol A (ChatGPT) — Contexto ambiental de las estaciones

La exposición pide hablar de las «causas posibles de contexto ambiental (qué hay en la zona que puede influir)». Necesitamos una tabla breve **con fuentes verificables**. Usa ChatGPT **con búsqueda web activada**.

**Qué hacer**
1. Para cada estación de la tabla de abajo, buscar qué hay alrededor (unos 3 km) que pueda emitir partículas: zonas industriales, pedreras o caleras, vialidades de mucho tráfico pesado, la refinería de Cadereyta, el aeropuerto, cementeras, etc.
2. Concentrarte en las estaciones con **más** superaciones (SE2 Juárez, SO Santa Catarina, CE Obispado, NO San Bernabé, NE San Nicolás) y en las que tienen **menos** (SUR Pueblo Serena, SE La Pastora).
3. Fuentes válidas:
   - el PIGECA 2023–2033 (Plan de calidad del aire de Nuevo León, en aire.nl.gob.mx);
   - artículos científicos;
   - documentos de gobierno;
   - Google Maps / Earth, solo para ubicar.
   **Cada afirmación lleva su liga.** Lo que no puedas confirmar se marca como «no confirmado».
4. Escribir **3 preguntas para SIMA** sobre el contexto. Ejemplo: «¿Qué fuentes cercanas explican que SE2 supere en casi la mitad de sus días?».
5. **Abre y revisa tú cada liga** antes de entregar. Las IA a veces inventan fuentes, y si SIMA pregunta, tú respondes estas preguntas en la exposición.

| Estación | Nombre | Municipio | Lat | Lon | % de días con PM2.5 > 25 |
|---|---|---|---|---|---|
| SE2 | Juárez | Juárez | 25.646 | −100.095 | 47.8 |
| SO | Santa Catarina | Santa Catarina | 25.676 | −100.458 | 46.6 |
| CE | Obispado | Monterrey | 25.676 | −100.338 | 33.9 |
| NO | San Bernabé | Monterrey | 25.763 | −100.369 | 33.0 |
| NE2 | Apodaca | Apodaca | 25.777 | −100.188 | 31.7 |
| NE | San Nicolás | San Nicolás | 25.745 | −100.253 | 29.4 |
| NTE2 | Universidad | por confirmar | 25.730 | −100.310 | 22.4 |
| NTE | Escobedo | Escobedo | 25.799 | −100.327 | 19.1 |
| SO2 | San Pedro | San Pedro | 25.665 | −100.413 | 18.4 |
| SE3 | Cadereyta | por confirmar | 25.601 | −99.999 | 15.5 |
| SE | La Pastora | Guadalupe | 25.665 | −100.244 | 15.2 |
| NO2 | García | García | 25.800 | −100.584 | 10.0 |
| SUR | Pueblo Serena | por confirmar | 25.617 | −100.274 | 9.3 |

**Prompt para ChatGPT** (con búsqueda web):
```text
Estoy investigando qué fuentes de partículas finas (PM2.5) hay cerca de estaciones de monitoreo de calidad del aire de la Zona Metropolitana de Monterrey (SIMA). Para cada estación de esta tabla, busca qué hay en un radio aproximado de 3 km que pueda emitir partículas (zonas industriales, pedreras/caleras, cementeras, vialidades con mucho tráfico pesado, refinería, aeropuerto, etc.).
REGLAS:
1) Cada afirmación debe tener una liga a una fuente verificable (gobierno, PIGECA 2023-2033, artículos científicos, empresas). Si no encuentras fuente, escribe "no confirmado".
2) No inventes nombres de empresas ni distancias.
3) Distingue entre "está cerca" (con fuente) y "podría influir" (hipótesis).
Entrega: una tabla (estación | qué hay cerca | fuente | confirmado sí/no) y un párrafo de 3 líneas para las estaciones con más superaciones (SE2, SO) y con menos (SUR, SE). Al final, 3 preguntas que le haríamos a SIMA sobre este contexto.
[pega aquí la tabla de estaciones]
```

---

## 3. Rol B (Claude) — Banco de preguntas y respuestas

1. Lee la sección 0 de este documento.
2. Con Claude, prepara **15 preguntas** que podría hacer SIMA o el profesor, con una respuesta de máximo 3 líneas cada una, y asigna quién la contesta (Leo, A, B o C). Incluye al menos estas:
   - ¿Por qué un LDA y no un modelo de *machine learning* como *random forest*?
   - ¿Por qué el umbral de 25 µg/m³?
   - ¿Esto es un pronóstico?
   - ¿Qué significa un AUC de 0.79?
   - ¿Cómo trataron los datos faltantes?
   - ¿Por qué quitaron NE3 y NO3?
   - ¿Por qué la estación importa tanto?
   - ¿Cómo lo usaría SIMA?
   - ¿Qué pasa con los días que descartaron?
   - ¿Por qué en temporada de lluvias el clima casi no ayuda?
   - ¿Cómo afectan los cambios de equipos de 2021 y 2025 a sus resultados?
3. Cuando Leonardo te pase el guion de 5 minutos, revisa con Claude que no contradiga la sección 0 ni el banco de preguntas.

**Prompt para Claude:**
```text
Te paso el resumen de un proyecto escolar de análisis multivariado con datos de calidad del aire de SIMA (Monterrey). Prepárame un banco de 15 preguntas que nos podría hacer el socio formador (expertos en monitoreo ambiental) o el profesor en una exposición de 5 minutos, con respuestas de máximo 3 líneas.
REGLAS: usa SOLO la información del resumen; si una respuesta requiere algo que no está ahí, escribe "PREGUNTAR A LEO" en lugar de inventar. Lenguaje claro, sin tecnicismos innecesarios. Marca las 5 preguntas más probables.
[pega la sección 0 de este documento]
```
Revisa tú que ninguna respuesta contradiga la sección 0. En la exposición contestas las preguntas «de método» que te asignes.

---

## 4. Rol C (sin IA) — Diapositivas, prueba de la interfaz y cronómetro

**Parte A. Diapositivas (Google Slides)**
1. Portada + 3 diapositivas de contenido, con la plantilla del Tec. El contenido exacto está en la sección 5: **cópialo, no lo cambies**.
2. Letra de 20 pt como mínimo en el texto y de 28 pt en los títulos. Como máximo 5 viñetas por diapositiva y una figura grande por diapositiva.
3. Figuras: descárgalas del repositorio, carpeta `output/etapa3/figuras/` (en GitHub, abre la imagen y usa «Download raw file»). Leonardo te pasa las que falten, como el mapa.
4. Compartir como «Cualquier persona con el enlace puede ver» y mandar la liga.
5. **No cambiar ninguna cifra.** Si algo no cabe, se acorta el texto, no los números.

**Parte B. Prueba de la interfaz** (cuando Leo te diga que está lista)
1. Abre la aplicación (Leo te pasa cómo).
2. Prueba 5 casos: SE2 en seca-fría con poco viento; SUR en temporada de lluvias; valores extremos de cada deslizador; cambiar de estación sin cambiar el clima; la pestaña de desempeño 2024–2025.
3. Anota qué hace la aplicación, si algo no tiene sentido (por ejemplo, que la probabilidad no cambie al mover algo) y si algún texto es confuso.
4. Toma 3 capturas limpias para el informe y la presentación.

**Parte C. Ensayo:** cronometra a Leo y avisa en el minuto 4. El límite son 5 minutos.

---

## 5. Contenido de las diapositivas (para el rol C)

**Portada**
- Título provisional: **«¿Cuánto ayuda el clima a identificar los días de PM2.5 alto en Monterrey?»**
- Subtítulo: Reto SIMA · Análisis multivariado (MA2003B) · Grupo 201 · Equipo 1
- Nombres y matrículas de los cuatro integrantes; fecha.

**Diapositiva 1 — Qué queremos hacer y con qué datos**
- Objetivo: medir cuánto mejora la meteorología del día la identificación de días con PM2.5 > 25 µg/m³ (24 h), frente a solo conocer estación y temporada.
- Por qué: el PM2.5 se asocia con mortalidad por exposición de corto plazo; ayuda a orientar la vigilancia y la comunicación de SIMA.
- Datos: 13 estaciones · 2021–2025 · PM2.5 + 8 variables meteorológicas · 15 390 estación-días.
- Limpieza: 12.3 % de horas faltantes de origen (26 % en PM2.5); 0.7 % invalidadas por lecturas inconsistentes; 1.0 % imputadas (huecos ≤ 3 h).
- Figura: mapa de estaciones coloreado por % de días con superación (lo genera Claude Code), o el mapa de calor estación × temporada de la etapa 2.

**Diapositiva 2 — Cómo lo analizamos y qué encontramos**
- PCA: la meteorología se resume en 3 ejes (cálido-soleado-ventilado; húmedo-lluvioso; presión baja-poco viento).
- LDA: M0 (estación + temporada) frente a M1 (+ meteorología); entrenamos con 2021–2023 y probamos con 2024–2025.
- Resultado: AUC de 0.72 → 0.79 (+0.07; IC 95 %: 0.05–0.09). Se detecta el 73 % de los días con superación, contra 58 %.
- Más útil en marzo–mayo (+0.14); casi nada en temporada de lluvias.
- Las superaciones se asocian a menos viento, presión más baja de lo normal y más temperatura.
- Figura: curvas ROC (`roc_m0_m1_prueba.png`) o la gráfica de ΔAUC por temporada.

**Diapositiva 3 — Problemas, qué sigue y preguntas para SIMA**
- Problemas: lecturas sospechosas de viento (SO2 y NE2, 2021, poco después de la renovación de sensores) y radiación nocturna (NO2, SE3, CE), que corregimos con una regla nueva; retención desigual entre estaciones (NO2: 28 %); cambio de equipos de PM2.5 en 2025 dentro de nuestro año de prueba.
- Sigue:
  - interfaz para usar el modelo;
  - probar con meteorología pronosticada (alerta real);
  - agregar el PM2.5 del día anterior;
  - informe final.
- Preguntas para SIMA:
  - ¿las horas están en tiempo local?
  - ¿en qué unidad está la lluvia?
  - ¿conocían esas fallas de sensores?
  - ¿en qué fechas se instalaron los sensores de viento (2021) y los 5014i de PM2.5 (2025)?
  - ¿qué fuentes cercanas explican SE2 y SO? (del rol A)
  - ¿les serviría una alerta con pronóstico?

---

## 6. Reglas para usar IA (todos)

1. La IA ayuda a redactar, diseñar o buscar; **las cifras salen solo de este documento o del repositorio**.
2. Toda fuente que entregues la abriste y la leíste tú.
3. Anota qué herramienta usaste y para qué. Va en la declaratoria de IA del informe, y debe ser verdad.
