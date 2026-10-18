# Etapa 4: decisiones tras la retroalimentación (borrador de Opus, 17 oct 2026)

**Estado:** definitiva desde la etiqueta `etapa4-decisiones-cerradas` (cierre de la fase A, validaciones solo con 2021–2023), **antes** de evaluar la prueba con la base nueva. D19, D20 y el plan de la fase B tienen cambios decididos con los resultados de la fase A; están en el «Registro de cambios de la fase A (antes de la etiqueta)», al final.

**Declaración obligatoria.** Todo lo de este documento es **posterior** a la evaluación de la prueba de la etapa 3 (4 de octubre). Lo motivan la retroalimentación de profesores y socio formador (15–16 de octubre). El informe final mostrará siempre el resultado de la etapa 3 (ΔAUC = 0.070) junto al nuevo, con una tabla puente que explique cada cambio.

---

## 1. Retroalimentación recibida y respuesta

| # | Retroalimentación | Respuesta | Decisión |
|---|---|---|---|
| R1 | Los métodos de imputación no son los más adecuados; usar los recomendados por la clase o justificar otros | Elegir el método con evidencia (validación por enmascaramiento), no imputar la respuesta y recuperar días con imputación multivariada de la meteorología | D18, D19, D20 |
| R2 | Cuidado con las interpretaciones del LDA: entender qué puede y qué no puede decir y con qué sustento | Validar la estabilidad de los coeficientes, contrastar con la logística y la QDA, y escribir una tabla de alcance | D21 |
| R3 | Las fuentes de Juárez y de Santa Catarina son distintas: crecimiento urbano e industrial reciente en Juárez; industria histórica y receptor de la contaminación regional en Santa Catarina por su posición geográfica | Nueva sección de área de estudio, citada como comunicación personal y contrastada con nuestros datos | D22 |
| R4 | Cambios de ubicación en NE3, SUR, SE y NE (nota del equipo) | Unir con el PIGECA y tratar «sitio» en lugar de «estación» en el entrenamiento | D23 |

---

## 2. Imputación

### Diagnóstico (ya medido; ver `imputacion_reto_sima_consolidado.md`)

- **Lo que falta son sobre todo apagones largos.** El 54–77 % de las horas faltantes está en huecos de más de 7 días.
- **La pérdida grande es de días completos.** Quedan 15 390 de 23 738 estación-días (64.8 %).
  - 4 528 días tienen PM2.5 válido pero les falta alguna meteorológica.
  - En 1 426 de ellos solo falta la radiación.
- **Lo que falta no es MCAR.** Depende de la estación: a NO le falta el 54 % de su PM2.5 diario y a NTE2 el 4 %. Exigir casos completos cambia la composición de la muestra (NO2 baja de 1 553 a 511 días).
- **La interpolación actual (≤ 3 h) casi no mueve el PM2.5 diario.** Mediana 0.31 µg/m³; 101 días cambian de clase.
  - **El problema no es ese número.** Es que:
    1. imputamos la variable respuesta;
    2. el método no se eligió con evidencia;
    3. la mayor pérdida (casos completos) no se atendió.

### D18. La respuesta no se imputa

- **Regla:** el PM2.5 diario se calcula solo con horas **observadas** y exige ≥ 18 h. Es el criterio de suficiencia de la NOM-025-SSA1-2021, que cuenta horas medidas.
- **Por qué:** `supera_25` es lo que se clasifica. Rellenarlo con un modelo sería etiquetar superaciones que nadie midió.
- **Costo conocido:** 429 días dejan de ser evaluables. En la etapa 3, esta variante dio ΔAUC = 0.074 [0.051, 0.098].
- La variante con PM2.5 interpolado ≤ 3 h queda como **sensibilidad**.

### D19. Imputación horaria de la meteorología: elegida por enmascaramiento

> **Regla modificada antes de la etiqueta:** ver el «Registro de cambios de la fase A», punto 1.

- **Datos:** solo 2021–2023 (entrenamiento), en tramos sin faltantes.
- **Enmascaramiento:** se borran bloques de **1, 2, 3, 6, 12 y 24 h**. Son bloques, no puntos sueltos, para imitar los huecos reales. Se usan 5 semillas.
- **Variables:** TOUT, RH, SR, PRS, viento_u y viento_v. También PM2.5, solo como diagnóstico: sirve para mostrar si la interpolación suaviza picos, que fue la crítica del curso. Ya no se usa en la respuesta.
- **Métodos comparados** (los recomendados por las fuentes de la clase: Moritz & Bartz-Beielstein, 2017, y los videos del curso):
  - interpolación lineal, spline y Stineman;
  - media móvil exponencial;
  - Kalman (StructTS);
  - descomposición estacional (`na_seadec`, frecuencia 24);
  - LOCF, como piso de referencia.
- **Métricas:** RMSE, MAE y sesgo por hora, y error del **promedio diario** resultante, que es lo que entra al modelo.
- **Regla fijada antes de ver resultados:**
  1. Para cada variable gana el método con menor RMSE del promedio diario, promediado sobre los largos de hueco.
  2. Si la lineal queda a menos de 5 % del ganador, se conserva la lineal por simplicidad.
  3. El `maxgap` se extiende hasta el largo de hueco más grande en el que el ganador mantiene un RMSE diario ≤ 0.10 × la DE diaria de la variable en el entrenamiento.
- **Se conservan:** nunca se imputan las horas invalidadas por las reglas físicas (E, L, M), y todo valor imputado se revalida (bandera X).
- **No se imputan** WSR, WDR ni la lluvia. Se imputan u y v; la rapidez sale de ellos o de la media diaria.

### D20. Imputación diaria multivariada de la meteorología (MICE)

> **Resuelta antes de la etiqueta:** MICE no ganó; el método principal es la mediana de la red ajustada y MICE queda como sensibilidad. Ver el «Registro de cambios de la fase A», puntos 2 y 3.

- **Para qué:** recuperar los estación-días que tienen PM2.5 válido (según D18) pero les falta alguna de las 8 meteorológicas.
- **Método:** `mice` con predictive mean matching (van Buuren & Groothuis-Oudshoorn, 2011), m = 20 imputaciones.
- **Predictores de la imputación:**
  - la mediana de la red ese mismo día para cada variable (la meteorología es casi común en la ciudad; la presión de cada estación correlaciona 0.96–0.99 con la red);
  - las otras meteorológicas de la estación;
  - estación, temporada y año.
- **Sin fuga hacia la prueba:**
  - los modelos de imputación se ajustan solo con 2021–2023 (argumento `ignore` de `mice` para los días de 2024–2025, que sí se imputan);
  - **el PM2.5 y `supera_25` no entran al modelo de imputación.** Usar la respuesta mejora el ajuste (Moons et al., 2006), pero en la prueba introduciría la respuesta en los predictores, y en el uso real la respuesta no se conoce al imputar (Mercaldo & Blume, 2020). Es una elección conservadora: si acaso, atenúa la ΔAUC.
- **Validación previa (fase A):** enmascaramiento a nivel diario en 2021–2023. Se borran valores observados con el mismo patrón por variable que los faltantes reales y se compara MICE (pmm) con dos referencias simples: la mediana de la red ajustada por la diferencia media de la estación, y la media de la estación × temporada. Si MICE no gana, se usa la referencia que gane, con una sola imputación.
- **Análisis con m bases:**
  - se ajustan M0 y M1 en cada base;
  - la ΔAUC se promedia (regla de Rubin para la estimación puntual);
  - el IC sale de los percentiles de las réplicas del bootstrap por bloques combinadas de todas las bases: 20 × 200 = 4 000 réplicas (Schomaker & Heumann, 2018 [verificar]).
- **Límites:**
  - supone MAR condicional a estación, temporada, año y la red;
  - no se imputa un estación-día al que le falten más de 4 de las 8 variables (casi sin información propia). Como sensibilidad, se reporta el límite de ≤ 2 variables faltantes.

### Lo que se descarta y por qué (va como técnica no adoptada en el anexo)

- **Media global, valor aleatorio y LOCF:** las fuentes los ubican al fondo en exactitud y borran el ciclo diario (Moritz & Bartz-Beielstein, 2017). LOCF solo entra como piso de referencia en D19.
- **Rellenar apagones largos de PM2.5 (días o semanas):** inventa la variable respuesta (D18).
- **Aprendizaje profundo (SAITS + CSDI, BRITS):** su fuerza es reconstruir apagones largos, que aquí implicaría inventar la respuesta. Además requiere GPU y semanas de trabajo, y no es una técnica del curso. Se menciona con respeto como antecedente con datos del SIMA (Gómez Santos et al., 2026).
  - **Ojo:** ese trabajo es de profesores del curso. En el informe no se le señalan contradicciones; solo se explica por qué no aplica a nuestra pregunta.
- **Antecedentes que respaldan la decisión:**
  - Quinteros et al. (2019): con datos de PM2.5 de Temuco, la imputación múltiple y KNN fueron los mejores, y mejoran con covariables de una segunda estación.
  - Belachsen y Broday (2022): en una red, los métodos que usan estaciones vecinas funcionan bien en huecos cortos y largos.
  - Hadeed et al. (2020): en monitoreo de 24 h, métodos univariados simples bastan para promedios diarios.
  - Juntos sugieren dos ideas: para huecos cortos, métodos temporales; para recuperar días, información de la red.

---

## 3. LDA: validación e interpretación (D21)

### 3.1 Qué puede decir el LDA y qué no

| Puede decir (con este sustento) | No puede decir (y por qué) |
|---|---|
| Si una combinación lineal de los predictores separa los días con y sin superación **fuera de muestra**. Sustento: AUC en años posteriores y bootstrap por bloques | **Causas.** Es un estudio observacional y el modelo solo encuentra asociaciones |
| Cuánto agrega la meteorología sobre estación y temporada (ΔAUC). Sustento: misma partición y mismas observaciones para M0 y M1 | **Qué variable es «más importante»** a partir del coeficiente más grande. Con predictores correlacionados los coeficientes se compensan (supresión; caso de la presión cruda en D17) |
| La dirección de la asociación **condicional** a las demás variables (signo del coeficiente estandarizado), **si es estable** en el bootstrap y coincide con la logística | **Significancia de cada coeficiente.** Los días y estaciones son dependientes (autocorrelación 0.44 a 1 día), así que los errores estándar usuales no valen |
| La asociación **marginal** de cada variable con la función (correlación de estructura). Sirve para leer el eje, no para ordenar importancias (Rencher, 1992) | **Probabilidades confiables.** La posterior es correcta solo con normalidad y covarianzas iguales, y ninguna se cumple. La pendiente de calibración es 0.76: son puntajes, no probabilidades exactas |
| Una regla de clasificación con un corte fijado antes de ver la prueba | **Efectos no lineales ni interacciones** que no se especificaron |
| | **Capacidad de pronóstico.** Usa clima observado del mismo día |

**Por qué el LDA sigue siendo defendible aunque fallen los supuestos:**
- El criterio de Fisher (maximizar la separación entre medias relativa a la dispersión) no necesita normalidad. La normalidad se necesita para que las probabilidades y la regla sean óptimas.
- Bajo normalidad, el LDA es más eficiente que la logística; fuera de ella, la logística es más robusta (Efron, 1975). Como las dos dan el mismo AUC (0.792 frente a 0.794), la violación no está cambiando la conclusión.

### 3.2 Validaciones nuevas (fase C; no cambian el modelo)

1. **Estabilidad de la interpretación.** Bootstrap por bloques de 14 días **en el entrenamiento** (1 000 réplicas). Para cada predictor se reportan el IC del coeficiente estandarizado y de la correlación de estructura, y el **% de réplicas con el mismo signo**. Solo se interpretan las variables con signo estable (≥ 95 %).
2. **Concordancia con la logística.** Tabla lado a lado de los coeficientes estandarizados del LDA y de la logística. Se marcan los signos que no coinciden.
3. **Consistencia entre pliegues.** Coeficientes del pliegue que valida 2022, del que valida 2023 y del final, para ver si la interpretación se sostiene en el tiempo.
4. **QDA como técnica no exitosa.** Es la alternativa natural cuando la M de Box rechaza covarianzas iguales.
   - Prueba previa de Opus (Python, sin cifras oficiales): la QDA regularizada da un AUC de 0.728–0.742 contra 0.792 del LDA; con solo meteorología, 0.709 contra 0.718.
   - Ganar en supuestos no se tradujo en mejor clasificación: la QDA estima muchos más parámetros y sobreajusta.
   - Claude Code la reproduce en R y la reporta en el anexo de técnicas no exitosas.
5. **Calibración.** Se declara que las probabilidades no están calibradas. La app y el informe hablan de «puntaje» o «probabilidad estimada por el modelo». La recalibración queda como recomendación.

---

## 4. Área de estudio y fuentes (D22)

**La rúbrica pide describir las estaciones y los factores geográficos.** Contenido mínimo de la sección:
- **Geografía:**
  - la ZMM está en un valle rodeado por la Sierra Madre Oriental (sur y oeste), el Cerro de la Silla y otras sierras;
  - las 13 estaciones van de 334 a 702 m de altitud;
  - el oeste (Santa Catarina, García, San Pedro) es más alto y más encajonado.
- **Mapa** con las estaciones y la superación (ya existe).
- **Comentarios del socio formador** (comunicación personal, 15 de octubre de 2026):
  - **Juárez (SE2):** crecimiento urbano acelerado, con nuevas viviendas, maquiladoras y vialidades.
  - **Santa Catarina (SO):** zona industrial histórica que, por su posición geográfica, recibiría una parte de la contaminación del resto del área metropolitana. El socio lo consideró probable, pero no lo pudo confirmar.
- **Lo que muestran nuestros datos** (para no exagerar):
  - **SE2** está alta todo el periodo (% de días con superación: 49.8, 53.3, 48.2, 49.9 y 36.6 en 2021–2025). **No hay una tendencia creciente dentro de 2021–2025**, y la caída de 2025 coincide con su equipo nuevo de PM2.5. El crecimiento urbano puede explicar el nivel alto, pero no lo podemos atribuir con este diseño.
  - **SO** es alta y variable (56.4, 40.4, 42.8, 46.4, 54.3), coherente con una fuente persistente.
- **Frase guía para el informe:** «Son explicaciones de contexto, consistentes con nuestros datos, que no se pueden atribuir sin inventarios de emisiones ni datos de transporte».

---

## 5. Reubicaciones (D23)

**Fuentes:**
- **PIGECA (p. 91):** NO (junio de 2021); SE, SO, NTE y SUR (septiembre de 2021); NE (febrero de 2022).
- **Socio formador (nota del equipo, por confirmar):** NE3, SUR, SE y NE. Coinciden en SUR, SE y NE. NE3 está fuera de la muestra.

**Evidencia en los datos:**
- SUR tenía 1 % de superación y una mediana de 9.9 µg/m³ en abril–junio de 2021, contra 17 % y 18.3 µg/m³ en abril–junio de 2022.
- La presión de SUR (−7.8 → −1.9 mm Hg frente a la red) y la de NTE (0.0 → +1.7) cambian de nivel en octubre de 2021.

**Decisión:**
- En el entrenamiento se quitan los días previos a la reubicación de NO, SE, SO, NTE, SUR y NE, porque son otro sitio: 1 012 días en la base de la etapa 3.
- La media de presión de D17 se calcula solo con días posteriores a la reubicación.
- La prueba (2024–2025) no cambia, porque es toda posterior.
- Antecedente: ΔAUC = 0.069 [0.046, 0.093] con la base de la etapa 3 (Python; Claude Code lo reproduce en R).

---

## 6. Plan de ejecución (lo hace Claude Code)

| Fase | Qué | Usa la prueba | Cierra con |
|---|---|---|---|
| A | Enmascaramiento horario (D19) y diario (D20), elección de métodos, nueva base `datos-v2.0` | No | Commit con etiqueta `etapa4-decisiones-cerradas` |
| B | Evaluación única de la prueba con la base nueva y tabla puente | Sí, una vez | `registro_prueba.txt` |
| C | Validaciones del LDA (D21), QDA, reubicaciones, figuras | Solo diagnósticos | `RESUMEN_ETAPA4.md` |
| D | Informe final (Opus redacta; Leo edita en Word) | — | PDF |

**Tabla puente** (resultado esperado; cada fila cambia una sola cosa respecto de la anterior):

| Paso | Cambio | ΔAUC [IC] |
|---|---|---|
| 0 | Etapa 3 (`datos-v1.2`) | 0.070 [0.047, 0.094] |
| 1 | + respuesta sin imputar (D18) | … |
| 2 | + imputación horaria elegida (D19) | … |
| 3 | + imputación diaria con mediana de la red ajustada (D20; registro de cambios, punto 3) | … |
| 4 | + entrenamiento sin días previos a la reubicación (D23) = **análisis final** | … |

---

## 7. Informe final: estructura y presupuesto de páginas (≤ 15, de introducción a conclusiones)

| Sección | Páginas | Qué responde de la rúbrica |
|---|---|---|
| Carátula (equipo, nombres, matrículas, título ligado al objetivo) | — | Identificación |
| Resumen (una página) | — | Resumen claro y completo |
| 1. Introducción y justificación | 1.5 | Contexto, salud, norma |
| 2. Problemática y objetivo | 0.5 | Pregunta y objetivos |
| 3. Área de estudio: estaciones y geografía | 1.5 | Descripción de la estación y factores geográficos |
| 4. Preparación de la base: limpieza, imputación validada, transformaciones | 3 | Limpieza, imputación y justificación |
| 5. Modelación y validación: PCA, LDA, logística, supuestos y alcance del LDA | 3 | Dos técnicas, aplicación y validación |
| 6. Resultados | 3 | Solidez de los hallazgos; figuras numeradas e interpretadas |
| 7. Discusión, conclusiones, recomendaciones y nuevas preguntas | 2 | Resultados, recomendaciones y preguntas |
| Referencias (APA) y liga al código | — | Referencias y código |
| Anexos: técnicas no exitosas (conglomerados de la etapa 1, PCA como predictor, interacción, QDA, métodos de imputación descartados), diagnósticos, declaratoria de IA | libre | Técnicas no exitosas |

**Uso de lenguajes, para el informe y el README:**
- **R:** todo el pipeline: limpieza, modelos, app.
- **Python:** solo la prueba de viabilidad del 4 de octubre (`docs/etapa2/prueba_viabilidad_2026-10-04.py`) y verificaciones cruzadas. Ningún resultado del informe depende de Python.

---

## Referencias nuevas (verificar antes del informe)

- Belachsen, I., & Broday, D. M. (2022). Imputation of missing PM2.5 observations in a network of air quality monitoring stations by a new kNN method. *Atmosphere, 13*(11), 1934. https://doi.org/10.3390/atmos13111934
- Efron, B. (1975). The efficiency of logistic regression compared to normal discriminant analysis. *Journal of the American Statistical Association, 70*(352), 892–898. [verificar DOI]
- Hadeed, S. J., O'Rourke, M. K., Burgess, J. L., Harris, R. B., & Canales, R. A. (2020). Imputation methods for addressing missing data in short-term monitoring of air pollutants. *Science of the Total Environment, 730*, 139140. https://doi.org/10.1016/j.scitotenv.2020.139140
- Junger, W. L., & Ponce de Leon, A. (2015). Imputation of missing data in time series for air pollutants. *Atmospheric Environment, 102*, 96–104. [verificar DOI]
- Mercaldo, S. F., & Blume, J. D. (2020). Missing data and prediction: The pattern submodel. *Biostatistics, 21*(2), 236–252. [verificar]
- Moons, K. G. M., Donders, A. R. T., Stijnen, T., & Harrell, F. E. (2006). Using the outcome for imputation of missing predictor values was preferred. *Journal of Clinical Epidemiology, 59*(10), 1092–1101.
- Quinteros, M. E., Lu, S., Blazquez, C., Cárdenas-R, J. P., Ossa, X., Delgado-Saborit, J. M., Harrison, R. M., & Ruiz-Rudolph, P. (2019). Use of data imputation tools to reconstruct incomplete air quality datasets: A case-study in Temuco, Chile. *Atmospheric Environment, 200*, 40–49. https://doi.org/10.1016/j.atmosenv.2018.11.053
- Rencher, A. C. (1992). Interpretation of canonical discriminant functions, canonical variates, and principal components. *The American Statistician, 46*(3), 217–225. [verificar]
- Schomaker, M., & Heumann, C. (2018). Bootstrap inference when using multiple imputation. *Statistics in Medicine, 37*(14), 2252–2266. [verificar]
- van Buuren, S., & Groothuis-Oudshoorn, K. (2011). mice: Multivariate imputation by chained equations in R. *Journal of Statistical Software, 45*(3), 1–67. https://doi.org/10.18637/jss.v045.i03

---

## Registro de cambios de la fase A (antes de la etiqueta)

**17 de octubre de 2026.** Los cambios se decidieron al revisar los resultados de la fase A, que usan **solo 2021–2023**: ninguno usa la prueba (2024–2025). Se registran **antes** de crear la etiqueta `etapa4-decisiones-cerradas`. Resultados y tablas: `output/etapa4/imputacion/RESUMEN_FASE_A.md`.

### 1. D19: nueva regla para elegir el método horario y su `maxgap`

Reemplaza los pasos 1–3 de «Regla fijada antes de ver resultados». Por variable, en este orden:

1. **Descalificación.** Se descalifica todo método cuyas imputaciones revierta la revalidación (bandera X) en más de 5 %. El porcentaje se mide en el mismo enmascaramiento, con las mismas reglas que la base v2 (`revalidar_imputados()` de `R/limpieza.R`), sobre todas las horas borradas de todos los largos. Se reporta el % de reversión de cada método.
2. **Umbral.** Para cada largo de hueco L: RMSE del promedio diario ≤ 0.10 × la DE diaria de la **anomalía**, es decir, la variable menos la media de su estación en el entrenamiento. Aplica a todas las variables.
3. **`maxgap` iterativo.**
   - El `maxgap` inicial es el mayor L en el que el mejor método no descalificado cumple el umbral.
   - El ganador es el método con menor RMSE diario promedio **solo** en los largos ≤ `maxgap`.
   - Se recalcula el `maxgap` con ese ganador y se repite hasta que no cambie.
4. **Simplicidad.** Si la lineal queda a menos de 5 % del ganador en los largos ≤ `maxgap`, se usa la lineal.

**Razones:**
- La regla original promediaba el error sobre los seis largos, incluidos los que no se imputan. En SR, u y v ganaba `seadec` por los huecos de 6–24 h, aunque su `maxgap` era de 3 h y en 1–3 h tenía más error que la lineal.
- `seadec` suma un ciclo diario que en la madrugada da SR negativos: la revalidación revertía el 32 % de sus imputaciones de SR, y el enmascaramiento medía valores que después se descartan.
- La DE diaria cruda incluye las diferencias entre estaciones (en la presión, sobre todo la altitud: medias de 701 a 731 mm Hg), que M1 no usa: la PRS entra como anomalía (D17) y la estación como indicadora. La DE de la anomalía es la escala de lo que el modelo distingue.

**Detalles de implementación:**
- «Cumple hasta L» exige que se cumpla en L y en todos los largos menores. Como el RMSE crece con el largo, da lo mismo que tomar el mayor L que cumple; el script lo comprueba.
- El error se mide sobre los valores imputados antes de revalidar; la reversión solo descalifica.

### 2. D20: lectura de «si MICE no gana»

**«Gana» se mide con el error de cada base imputada:** RMSE relativo (RMSE / DE de la variable) promediado en las 8 variables, y para MICE el promedio del RMSE de sus m bases.

**Razones:**
- Es el error de los valores con que se ajusta cada modelo.
- El promedio de las m imputaciones no es una base que se use.
- Con la otra lectura, la ventaja de MICE venía solo de `horas_lluvia`, con 75 celdas borradas.

**Resultado:** gana la **mediana de la red ajustada**. Es el método principal de imputación diaria, con una sola imputación. Se comprobó que también gana o empata en TOUT y RH, las variables que más faltan en 2024–2025.

**MICE pasa a sensibilidad de la fase B:**
- pmm, m = 20, `ignore` para 2024–2025, sin PM2.5 ni `supera_25`;
- ΔAUC promedio de las 20 bases e IC con las réplicas combinadas.

**Ajuste técnico:** mice se corre con `maxcor = 0.9999`. Con el valor por defecto (0.99) descarta la mediana de la red de TOUT como predictor de TOUT (correlación 0.994), que es justo el predictor que pide D20.

### 3. Fase B: análisis principal con la mediana de la red ajustada

- **Análisis principal:** base imputada con la mediana de la red ajustada, una sola base, bootstrap pareado por bloques de 14 días con 1 000 réplicas, como en `07b`.
- **Sensibilidad con MICE (m = 20):** 200 réplicas por base, combinadas (4 000). Es una fila más de la tabla de sensibilidades, junto con ≤ 2 faltantes, PM2.5 interpolado ≤ 3 h y casos completos v2.
- **Tabla puente:** queda igual. El paso 3 es «+ imputación diaria con mediana de la red ajustada (D20)».

### 4. Implementación de la fase B (registrada antes de abrir la prueba con v2)

Se anotó después de la etiqueta, pero **antes** de la evaluación de 2024–2025 (commit del código registrado en `output/etapa4/registro_prueba_v2.txt`). No cambia ninguna decisión; precisa cómo se aplicaron.

- **Diferencia por sitio en la mediana de la red ajustada (`08d_imputar_diario.R`).** La diferencia media de cada estación respecto de la mediana de la red se calcula **por sitio** (estación × `sitio_valido`) con 2021–2023. Si se mezclaran los periodos antes y después de una reubicación, se repetiría el problema que corrige D23; por ejemplo, la PRS de SUR cambia de nivel al reubicarse. Los días de prueba (todos posteriores) usan la diferencia del sitio actual.
- **Sin recorte de valores imputados.** La imputación diaria no se recorta al rango físico, porque es el método validado en 08c. Quedan 398 valores de SR diaria por debajo de 0 (de −0.13 a −0.001 kW/m²), casi todos en NO2 y NTE. Sus sensores de radiación leen muy bajo (media observada de 0.015 y 0.041 kW/m², contra 0.12–0.18 en las demás estaciones): se reporta como posible falla de sensor para consultar con SIMA. También quedan 3 `horas_lluvia` de −0.004 a −0.002.
- **Año en MICE con `ignore`.** Las indicadoras de 2024 y 2025 valen 0 en todas las filas de ajuste, así que mice las descarta (1,600 eventos registrados) y esos años se imputan como el año de referencia (2021). Afecta solo a la sensibilidad con MICE. MICE se corrió con 10 iteraciones por cadena.
- **Modo ensayo.** `09a_evaluar_prueba_v2.R` se probó en modo ensayo (entrena 2021–2022, «prueba» 2023, sin leer 2024–2025; `output/etapa4/ensayo/`). El paso 0 del ensayo reproduce el pliegue 2023 de la validación progresiva de la etapa 3 (AUC M0 0.749, M1 0.829).
