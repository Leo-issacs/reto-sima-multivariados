# Imputación de datos faltantes — Reto SIMA (MA2003B)
## Documento consolidado para decidir el método

**Para:** la IA que está haciendo el trabajo de imputación.
**Preparado:** 17 de octubre de 2026.
**Qué contiene:** (1) el contexto del proyecto y cómo imputa hoy; (2) cómo son los faltantes de los datos, medido; (3) lo que dice cada una de las 7 fuentes; (4) el catálogo completo de métodos; (5) las restricciones que debe respetar cualquier cambio; (6) las opciones de decisión con sus pros y contras; (7) la recomendación y un plan concreto en R; (8) las preguntas abiertas.

**Cómo leer las etiquetas:**
- **[medido]**: lo calculé sobre los CSV limpios del repositorio.
- **[fuente]**: viene de una de las fuentes revisadas.
- **[propuesta]**: es mi recomendación; no la he ejecutado.

---

## 0. Resumen en 10 líneas

1. Hoy el proyecto hace dos cosas: interpola linealmente huecos de 1 a 3 horas (`imputeTS::na_interpolation(maxgap = 3)`) y descarta los estación-días incompletos.
2. Esa interpolación mueve poco los resultados [medido]: imputó 3.2 % de las horas de PM2.5; el promedio diario cambia 0.31 µg/m³ en la mediana; 101 de 15,390 días cambian de clase; el ΔAUC queda en 0.074 sin imputar frente a 0.070 con imputación.
3. La mayoría de lo que falta son apagones largos: 54–77 % de las horas faltantes están en huecos de más de 7 días [medido]. Ningún método local los reconstruye bien.
4. La pérdida grande es de días completos [medido]: de 23,738 estación-días posibles quedan 15,390 (64.8 %). De ellos, 3,820 se pierden porque falta el PM2.5 y 4,528 porque falta alguna variable meteorológica (1,426 solo por radiación).
5. Lo que falta no es al azar (no es MCAR) [medido]: a la estación NO le falta 54 % del PM2.5 diario y a NTE2 4 %.
6. Las fuentes coinciden en que no hay un método mejor para todo [fuente]. Para huecos cortos, la interpolación, Kalman y la descomposición estacional suelen ganar. La media, LOCF y el valor aleatorio suelen perder. Para huecos largos se necesita información de otras variables o de otras estaciones.
7. El artículo COMIA (SAITS + CSDI) usa datos del SIMA, pero tiene contradicciones internas y su fuerte es reconstruir apagones largos. Aquí eso no conviene, porque inventaría la variable respuesta.
8. **Recomendación:**
   - mantener la interpolación lineal ≤ 3 h, pero demostrar con un experimento de enmascaramiento que es la mejor opción para estos huecos;
   - no imputar el PM2.5 de los huecos largos;
   - agregar una imputación múltiple (MICE) de la meteorología diaria usando las otras estaciones, como sensibilidad;
   - documentar el mecanismo de los faltantes.
9. Cualquier cambio a la muestra principal después de evaluar la prueba (2024–2025) es una decisión posterior a la prueba y debe declararse así.
10. Falta saber el comentario textual de la profesora. Cambia qué parte del plan es prioritaria (ver sección 8).

---

## 1. Contexto del proyecto

**Pregunta de investigación:** ¿en qué medida la meteorología del día mejora la clasificación retrospectiva de los estación-días con PM2.5 promedio de 24 h > 25 µg/m³, frente a un modelo que solo usa estación y temporada?

**Datos:**
- 13 estaciones del SIMA (sin NE3 ni NO3), 2021–2025.
- Datos horarios agregados a promedios diarios.

**Modelos:**
- M0 = estación + temporada.
- M1 = M0 + 8 variables meteorológicas diarias: TOUT, RH, SR, PRS, rapidez del viento, viento_u, viento_v y horas_lluvia.
- Técnica: análisis discriminante lineal (LDA); regresión logística como prueba de robustez.

**Partición:**
- Entrenamiento 2021–2023 (10,170 estación-días).
- Prueba 2024–2025 (5,220).
- La prueba ya se evaluó (4-oct-2026).

**Resultado principal:** AUC 0.722 (M0) frente a 0.792 (M1); ΔAUC = 0.070, IC 95 % [0.047, 0.094].

**Repositorio:** `Leo-issacs/reto-sima-multivariados`.
- Limpieza: `R/limpieza.R` y `scripts/03_limpiar.R`.
- Muestra: `scripts/06_explorar_etapa2.R`.
- Modelos: `scripts/07a`, `07b` y `07c`.
- Datos limpios: `data/clean/`.

### 1.1 Cómo imputa hoy (orden real del pipeline)

1. **Limpieza horaria por reglas.** Se invalidan:
   - valores fuera de rango, saturación y saltos;
   - PM2.5 > PM10;
   - lecturas inconsistentes con la red (consistencia espacial de TOUT y RH);
   - radiación solar nocturna mayor que cero (regla D15);
   - viento físicamente imposible frente a la red (regla D15).

   Estas horas quedan como NA y **nunca se imputan**.
2. **Imputación horaria.** `imputeTS::na_interpolation(x, option = "linear", maxgap = 3)` por estación y variable, sobre la serie continua 2020–2025. Solo huecos internos de ≤ 3 horas. Se imputan contaminantes, TOUT, RH, SR, PRS y viento_u/v. No se imputan la lluvia (RAINF) ni la rapidez y dirección del viento crudas (WSR, WDR).
3. **Revalidación.** Todo valor imputado que viole alguna regla del paso 1 vuelve a NA (bandera `X`). Nunca se modifica un valor original válido.
4. **Agregación diaria.** Un valor diario solo existe con **≥ 18 horas válidas**, contando las imputadas. Es la misma regla de suficiencia de la NOM-025-SSA1-2021 (75 % de las horas).
5. **Selección de la muestra (casos completos).** Se exige PM2.5 diario válido y las 8 variables meteorológicas diarias completas. Resultado: 15,390 estación-días.

**Sensibilidad que ya existe:** recalcular el PM2.5 solo con horas observadas (≥ 18 h, sin imputar).
- 101 días cambian de clase (0.66 %).
- 429 días dejan de ser evaluables.
- ΔAUC = 0.074 [0.051, 0.098] frente a 0.070 en el análisis principal.

---

## 2. Cómo son los faltantes de estos datos [medido]

Universo: 13 estaciones, 2021–2025, 569,712 estación-horas.

### 2.1 Largo de los huecos horarios (después de limpiar e imputar)

| Variable | % horas faltantes | % de esas horas en huecos de 4–6 h | 7–24 h | 1–7 días | > 7 días |
|---|---|---|---|---|---|
| PM2.5 | 14.1 % | 7.3 % | 17.1 % | 19.3 % | 53.5 % |
| TOUT | 5.8 % | 3.8 % | 14.6 % | 13.1 % | 68.2 % |
| RH | 9.5 % | 2.7 % | 10.5 % | 9.6 % | 76.6 % |
| SR | 8.5 % | 1.1 % | 13.9 % | 20.3 % | 64.6 % |
| PRS | 2.8 % | 9.7 % | 24.6 % | 28.5 % | 36.8 % |
| viento_u | 5.9 % | 5.5 % | 17.1 % | 22.1 % | 55.2 % |

Los huecos de 1–3 h ya están rellenos, por eso no aparecen. Antes de imputar, PM2.5 tenía 26.0 % de horas faltantes (dato de `data/clean/tabla_informe_limpieza.csv`, que cubre todas las estaciones de 2020 a 2025).

**Lectura:** lo que queda sin imputar son sobre todo apagones de días o semanas. Extender `maxgap` a 6 u 8 horas recuperaría poco: 4–10 % de lo faltante, según la variable.

### 2.2 Efecto de la imputación actual sobre el PM2.5 diario

- Días de la muestra con al menos una hora imputada: 6,669 de 15,390 (43 %).
- En los 6,240 de esos días que tienen ≥ 18 horas observadas, la diferencia entre el promedio con imputación y el promedio solo con horas observadas es:

| Medida | Valor |
|---|---|
| Mediana de la diferencia absoluta | 0.31 µg/m³ |
| Percentil 95 | 1.70 µg/m³ |
| Máximo | 64.84 µg/m³ |
| Diferencia media (sesgo) | −0.25 µg/m³ |

El sesgo es pequeño y negativo: con imputación, el promedio diario sale ligeramente más bajo. Es consistente con que la interpolación no reproduce picos dentro del hueco, aunque no lo verifiqué hora por hora. El máximo de 64.84 µg/m³ es un caso aislado que convendría revisar.

### 2.3 Pérdida a nivel diario

| Etapa | Estación-días |
|---|---|
| Posibles (13 estaciones × días 2021–2025) | 23,738 |
| Con PM2.5 diario válido | 19,918 |
| Con PM2.5 válido y las 8 meteorológicas completas (muestra) | **15,390** (64.8 %) |
| Con PM2.5 válido pero alguna meteorológica faltante | 4,528 |

En esos 4,528 días, la variable que falta es (un día puede tener varias): SR 1,796; RH 1,650; viento 989; TOUT 851; PRS 377; horas_lluvia 262. **En 1,426 días solo falta SR**, y SR no aporta al modelo: quitarla cambia el AUC en −0.001.

**PM2.5 diario faltante por estación:**

| Estación | % faltante |
|---|---|
| NO | 54 % |
| NE2 | 31 % |
| SUR | 22 % |
| NO2, SE | 15 % |
| CE | 14 % |
| NTE, SO | 12 % |
| SE3, SO2 | 9 % |
| NE, SE2 | 6 % |
| NTE2 | 4 % |

**Mecanismo:** como la falta depende de la estación, no es MCAR. Es razonable suponer MAR condicional a estación, temporada y año, pero no se puede probar. Exigir meteorología completa baja los días de NO2 de 1,553 a 511 y su superación de 18.2 % a 10.0 %: la selección cambia la composición de la muestra.

---

## 3. Fuentes revisadas: puntos clave

### F1. Video "Manejo de datos faltantes en series de tiempo" (Codificando Bits)
https://www.youtube.com/watch?v=w68twpX22BI

- En series de tiempo, los datos consecutivos están muy correlacionados. Los métodos para datos tabulares (eliminar, media global) no aprovechan eso.
- Clasifica los métodos en cinco grupos:
  - eliminación;
  - imputación global (media, mediana);
  - información local: hacia adelante, hacia atrás, media móvil, interpolación;
  - estacional: usar el mismo punto del ciclo en otros periodos; si hay tendencia, quitarla, imputar y volverla a sumar;
  - modelos predictivos: ARIMA, LSTM.
- La media global solo funciona si la serie es estacionaria.
- Rellenar hacia adelante o hacia atrás solo sirve para huecos cortos. Su ejemplo: en una serie de 60 minutos, un hueco de 15 minutos dejaría 25 % de la serie con el mismo valor. Tampoco sigue tendencia ni estacionalidad.
- La media móvil depende mucho del tamaño de la ventana.
- La interpolación funciona con o sin tendencia, pero es sensible a valores extremos en los bordes del hueco.
- Los modelos predictivos son "de los más recomendados", pero dependen de tener suficientes datos de calidad. Con pocos registros y muchos faltantes es difícil entrenarlos.

### F2. Video "Imputación de datos faltantes para series de tiempo — Tutorial en R"
https://www.youtube.com/watch?v=ESMIVadldR0

- **Caso:** temperatura diaria de 2020 en una estación de Boyacá, Colombia (Santa Sofía), con 44 NA en una de cuatro columnas.
- **Diagnóstico con el paquete `naniar`:** conteo y porcentaje de NA por variable, gráficas de faltantes y faltantes por estación. Es el primer paso.
- **Imputación:** `imputeTS::na_interpolation` aplicada **por mes**, con las opciones `"spline"`, `"linear"` y `"stine"`. Eligió spline porque, según él, la temperatura de un mes no sigue una sola tendencia lineal.
  - Ejemplo del video para un mismo hueco: spline 15.2, linear 15.35, stine 32. Así lo dice la transcripción; puede ser un error de transcripción.
- **Imputación climatológica:** con 30 años o más de datos, se puede imputar un día usando el mismo día del calendario en los otros años, o usando todos los eneros.
- **Validación (lo más útil):** tomar un periodo completo, insertar ~5 % de NA al azar, imputar con cada técnica y comparar contra el dato real con RMSE, el índice de Nash-Sutcliffe y un tercer índice que la transcripción escribe como "capa". Quizá sea Kling-Gupta; no está confirmado. Elegir la técnica que más se acerque.
- **Ojo:** imputar por mes por separado deja sin interpolar los huecos que cruzan el cambio de mes.

### F3. Moritz y Bartz-Beielstein (2017). imputeTS: Time Series Missing Value Imputation in R. *The R Journal* 9(1): 207–218

- **El problema de fondo:** los métodos clásicos (imputación múltiple, EM, vecino más cercano, hot deck) se basan en correlaciones **entre variables**. Para una serie univariada hay que usar las correlaciones **en el tiempo**. Paquetes multivariados en CRAN: `Amelia`, `mice`, `VIM`, `missMDA`. Otros con funciones de imputación: `zoo`, `forecast`, `spacetime`, `timeSeries`, `xts`.
- **Algoritmos de imputeTS** (en el artículo llevan punto; en versiones recientes, guion bajo):
  - `na_locf`: LOCF y NOCB.
  - `na_mean`: media, mediana o moda.
  - `na_random`, `na_replace` y `na_remove`.
  - `na_interpolation`: linear, spline o stine.
  - `na_kalman`: StructTS o auto.arima, con suavizado de Kalman.
  - `na_ma`: media móvil simple, lineal o exponencial.
  - `na_seadec`: descomposición estacional.
  - `na_seasplit`: división por estación.
- **Conclusiones del artículo:**
  - "no single overall best method": el desempeño depende de las características de la serie;
  - con estacionalidad fuerte, suelen ganar `na_kalman` y `na_seadec`/`na_seasplit`;
  - en general, para la mayoría de las series gana alguno de `na_kalman`, `na_interpolation` o `na_seadec`;
  - `na_random`, `na_mean` y `na_locf` suelen quedar al fondo en exactitud;
  - `na_remove` puede corromper la información de tiempo de la serie.
- **Diagnóstico:** `statsNA`, `plotNA.distribution`, `plotNA.distributionBar`, `plotNA.gapsize` (frecuencia de cada largo de hueco) y `plotNA.imputations`.
- **Validación:** usan series de referencia con y sin NA, y miden RMSE o MAPE. Un benchmark completo debería variar el porcentaje de faltantes, los datasets y las semillas.

### F4. Fang y Wang (2020). Time Series Data Imputation: A Survey on Deep Learning Approaches. arXiv:2011.11347

- **Ocho familias de métodos:**
  - **eliminación** (por lista, por pares): sirve si falta poco; citan un umbral de cerca de 5 %;
  - **vecinos** (KNN, DBSCAN, último valor válido, SRKN);
  - **restricciones** (reglas de similitud, SCREEN con límites de velocidad);
  - **regresión** (LOESS, ARX, ARIMA, IMR, que además repara anomalías);
  - **estadísticos** (media o mediana, DPC, IIM con modelos individuales; usan pasado y futuro);
  - **factorización de matrices** (TRMF, NMF);
  - **EM** (EM, EM-GMM);
  - **MLP**;
  - **deep learning** (GRU-D, GRUI-GAN, E2GAN, BRITS, NAOMI).
- **Conceptos clave:** matriz de máscara (1 = observado, 0 = faltante) y "time lag" (tiempo desde la última observación).
- **GRU-D:** decaimiento aprendido hacia la media cuando la última observación es lejana.
- **BRITS:** red recurrente bidireccional con pérdida de consistencia entre los dos sentidos.
- **GRUI-GAN:** red adversaria a partir de ruido; inestable.
- **E2GAN:** red adversaria con autoencoder; la mejor según el survey (2020).
- **NAOMI:** bidireccional; imputa primero los puntos medios; ignora los intervalos de tiempo.
- **Futuro:** atención y Transformers; imputar timestamps faltantes.

### F5. RPubs, W. Sandoval, "Imputación Series de Tiempo"
https://rpubs.com/wilsonsr/804544

- **Datos:** AirPassengers con NA puestos a mano. Compara los métodos solo con gráficas, sin métricas de error, y no concluye cuál es mejor. No habla de MCAR, MAR ni MNAR.
- **Métodos simples:**
  - media: `na_mean`;
  - regresión;
  - regresión estocástica (predicción + error aleatorio para recuperar varianza);
  - medias móviles: `na_ma(serie, k, weighting = "exponential")`;
  - LOCF/NOCB: `na_locf(option = "locf"/"nocb")` o `zoo::na.locf(fromLast = TRUE)`;
  - interpolación: `na_interpolation(option = "linear"/"spline"/"stine")`, `zoo::na.approx`, `forecast::na.interp`.
- **Basados en máxima verosimilitud:**
  - imputación múltiple, en tres fases: imputar, analizar y combinar;
  - algoritmo EM.
- **Machine learning:** KNN; K-means y SVM, que solo menciona.
- **Para series univariadas:**
  - convertir rezagos y adelantos en variables para poder usar métodos multivariados;
  - Kalman sobre ARIMA en espacio de estados: `na_kalman(model = "auto.arima" o "StructTS", smooth = TRUE)`.

### F6. Editverse, "Manejo de datos faltantes: estrategias y consejos"
https://editverse.com/es/lidiar-con-consejos-de-estrategias-de-datos-faltantes/

- **Advertencia:** es el blog de una empresa que vende servicios de análisis. Es contenido de divulgación, sin referencias académicas, y tiene contradicciones: dice que la eliminación por lista "preserva el tamaño de la muestra". No sirve como cita en el informe.
- **Tipos de faltantes:**
  - MCAR: no relacionado con nada;
  - MAR: relacionado con variables observadas;
  - MNAR: relacionado con lo no observado; el más difícil.
- **Imputación única:** media, mediana (robusta a atípicos) y moda (para variables categóricas).
- **Series de tiempo:** LOCF, interpolación lineal y descomposición estacional.
- **Imputación múltiple:** bootstrap, EM y bayesiana. Ojo: el EM no es imputación múltiple en sentido estricto; da una sola estimación.
- **Eliminación:** por lista y por pares.
- **En machine learning:** imputar, eliminar o **usar la falta como variable** (un indicador de "faltó").
- **Prevención:** validar datos, monitorear su calidad, respaldos.

### F7. Gómez Santos et al. (2026), COMIA, y reporte del curso "MIMA-v1" (mismo equipo; MA2003B, prof. Raúl Gómez Muñoz y Blanca Rosa Ruiz Hernández)

- **Datos:** SIMA, 9 estaciones (SE, CE, SO2, SO, NTE2, NO, NO2, NTE, NE), 15 variables horarias, 2021 a junio de 2025. El artículo dice 2023–2025: hay inconsistencia entre los dos documentos.
- **Diagnóstico:**
  - PM2.5 con 29.9 % de horas faltantes;
  - los huecos son apagones contiguos, no al azar;
  - hay valores imposibles, como PM10 > 1000 µg/m³ y ozono negativo.
- **Fase 1 (clásicos):**

  | Método | MAE | R² |
  |---|---|---|
  | Interpolación lineal | 4.01 | 0.85 |
  | ARIMA | 5.06 | 0.80 |
  | SARIMA | 5.02 | 0.80 |
  | Holt-Winters | 5.05 | 0.79 |

  **La interpolación lineal tuvo el menor error.** La descartaron porque suaviza los picos y regresa a la media, lo que afecta los cálculos de riesgo (VaR), no porque fallara en el error.
- **Fase 2: SAITS + CSDI + LoRA.**
  - SAITS: Transformer con atención diagonal enmascarada; da una imputación determinista que sirve de guía.
  - CSDI: difusión condicionada a lo observado y a la guía de SAITS; genera varias trayectorias, que dan media e intervalo.
  - LoRA: adapta el modelo a cada estación; no es un método de imputación.
  - Ventana de 168 horas; descartan ventanas con < 20 % observado; imputan "en cadena" (rolling) los huecos más largos que la ventana, usando sus propias predicciones como datos.
  - Métricas: MAE, RMSE, CRPS, pérdida por cuantil 95 %, distancia de Wasserstein, PM2.5 ≤ PM10, correlación NOx–O3, análisis espectral.
- **Limitaciones que ellos mismos reconocen:**
  - validaron borrando datos al azar, lo que no imita los apagones reales;
  - el modelo puede aprender los errores de calibración de los sensores;
  - genera ruido cerca de cero;
  - necesita GPU.
- **Contradicciones internas** (las detecté yo; no las pude verificar con sus datos):
  1. Reportan R² = 0.9932 y también una correlación real-imputado de 0.622. Si la correlación es 0.622, el R² de una relación lineal anda por 0.39; las dos cifras no cuadran.
  2. La violación de PM2.5 ≤ PM10 aparece como 13.32 % en una parte y como 0.52 % en otra. Además, todas las estaciones tienen entre 1.55 % y 6.59 %, así que el promedio no puede ser 0.52 %.
  3. En la Tabla 2 del artículo, el CRPS, la pérdida por cuantil y la distancia de Wasserstein de los modelos de comparación son idénticos a su MAE. Parece que no se calcularon.
  4. El MAE del reporte aparece como 9.86 y como 4.45 µg/m³ en distintas secciones.

  **Conclusión:** sirve como antecedente de que el SIMA tiene este problema, no como método validado que copiar.

---

## 4. Catálogo completo de métodos

Columnas: qué es, cuándo sirve, su problema principal, si encaja en este proyecto y en qué fuentes aparece.

### A. No imputar

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| Eliminación por lista (casos completos) | Quita la fila si falta algo | Pocos faltantes y MCAR | Pierde datos; sesga si no es MCAR | Es lo que hacen hoy a nivel diario; pierde 35 % de los días | F1, F3, F4, F6 |
| Eliminación por pares | Cada cálculo usa los pares disponibles | Correlaciones | Distintos n por cálculo | No sirve para ajustar un LDA | F4, F6 |
| Indicador de faltante | Agrega una variable "faltó X" | Machine learning | Complica la interpretación | Posible como sensibilidad; poco usual en LDA | F6 |

### B. Valor global

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| Media, mediana o moda | Un solo valor para todos los faltantes | Series sin tendencia ni ciclo | Reduce la varianza; borra el ciclo diario | No | F1, F3, F5, F6 |
| Valor fijo | Un valor elegido por el analista | Faltante con significado (por ejemplo, 0 lluvia) | Solo con justificación física | Solo para casos específicos | F3 |
| Muestra aleatoria | Valor al azar de los observados | Conservar la distribución | Ignora el tiempo | No | F3 |

### C. Locales (vecinos en el tiempo)

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| LOCF y NOCB | Repite el último o el siguiente valor | Huecos muy cortos | Escalones; ignora la tendencia | Peor que la interpolación | F1, F3, F5, F6 |
| Media móvil (simple, lineal, exponencial) | Promedio ponderado de una ventana | Huecos cortos y medianos | Depende de la ventana | Candidato para comparar | F1, F3, F5 |
| Interpolación lineal | Recta entre los bordes del hueco | Huecos cortos | Suaviza; sensible a los bordes | **Método actual (≤ 3 h)** | Todas |
| Spline / Stineman | Curva entre los bordes | Series suaves | Spline puede pasarse del rango real | Candidatos para comparar | F2, F3, F5 |

### D. Estacionales

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| Imputación estacional o climatológica | Mismo punto del ciclo en otros periodos | Ciclos estables, muchos años | Ignora lo que pasó ese día | Débil: solo hay 5 años | F1, F2 |
| `na_seadec` | Quita la estacionalidad, imputa y la regresa | Ciclo diario fuerte (frecuencia 24) | Requiere definir la frecuencia | **Candidato fuerte para horas** | F3, F6 |
| `na_seasplit` | Imputa por separado cada fase del ciclo | Estacionalidad fuerte | Necesita muchos ciclos | Candidato | F3 |

### E. Modelos de series de tiempo y estadísticos

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| Regresión | Predice con otras variables | Variables muy correlacionadas | Subestima la varianza | Sí, a nivel diario con la red de estaciones | F4, F5 |
| Regresión estocástica | Regresión + error aleatorio | Conservar la varianza | Necesita modelar el error | **Sí, opción simple para la meteorología** | F5 |
| LOESS | Regresión local | Relaciones no lineales | Costoso | Posible | F4 |
| ARIMA / ARX | Predice desde el pasado | Autocorrelación | Regresa a la media en huecos largos | Peor que Kalman | F1, F4, F7 |
| SARIMA | ARIMA con ciclo de 24 h | Ciclo diario | Igual que ARIMA | Peor que la interpolación según F7 | F7 |
| Holt-Winters | Suavizado de nivel, tendencia y estación | Tendencia y ciclo | Suaviza los picos | Peor que la interpolación según F7 | F7 |
| Kalman (StructTS / auto.arima) | Espacio de estados, usa pasado y futuro | De los mejores en series univariadas | Lento en series largas | **Candidato fuerte para horas** | F3, F5 |
| DPC / IIM / IMR | Limpieza estadística y reparación de anomalías | Sensores ruidosos | Poco software en R | No | F4 |

### F. Multivariados clásicos

| Método | Qué hace | Cuándo sirve | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|---|
| KNN | Promedia los casos más parecidos | Variables relacionadas | Escalar; elegir k | Posible para la meteorología diaria | F4, F5 |
| K-means | Imputa con el centro del grupo | Datos agrupados | Poco detalle en la fuente | No | F5 |
| Hot deck | Copia el valor de un caso similar | Encuestas | Ignora el tiempo | No | F3 |
| EM / EM-GMM | Alterna entre estimar faltantes y parámetros | Datos aproximadamente normales | Da una sola imputación | Posible (Junger y Ponce de Leon, 2015, para contaminantes; citado en F7) | F4, F5, F6, F7 |
| Imputación múltiple / MICE | Crea varias bases, analiza y combina | Reflejar la incertidumbre de imputar; MAR | Más trabajo | **Sí, para la meteorología diaria** | F3, F5, F6, F7 |
| Bootstrap o bayesiana | Variantes de imputación múltiple | Incertidumbre | Más trabajo | Variante de MICE | F6 |
| Factorización de matrices (TRMF, NMF) | Reconstruye la matriz estación × tiempo | Muchas series parecidas | Complejo | Posible, pero innecesario | F4 |
| Rezagos como variables | Pasado y futuro como columnas | Series univariadas | Más columnas | Se puede incluir dentro de MICE | F5 |
| Restricciones | Reglas físicas | Datos con reglas claras | Rígido | Ya se usan para limpiar, no para imputar | F4 |

### G. Machine learning y deep learning

| Método | Qué hace | Problema | ¿Encaja aquí? | Fuentes |
|---|---|---|---|---|
| MLP, SVM, Random Forest | Aprenden a predecir el faltante | Ignoran el tiempo (MLP); poco detalle | Random Forest (`missForest`) sería alternativa a MICE | F4, F5, F7 |
| GRU-D, BRITS | Redes recurrentes con máscara y decaimiento | Regresan a la media en apagones largos | No | F4, F7 |
| GRUI-GAN, E2GAN, FCGAI | Redes adversarias | Inestables | No | F4, F7 |
| NAOMI | Bidireccional, multirresolución | Ignora los intervalos de tiempo | No | F4 |
| SAITS | Transformer | Determinista, suaviza | No | F7 |
| CSDI | Difusión condicionada, probabilística | GPU, costo, ruido cerca de 0 | No | F7 |
| SAITS + CSDI + LoRA | Híbrido de F7 | Contradicciones; costo; inventaría el PM2.5 | **No** (sección 6, opción D) | F7 |

### H. Diagnóstico y validación (antes y después de imputar)

- **Diagnóstico:** `imputeTS::statsNA`, `ggplot_na_distribution` y `ggplot_na_gapsize` (las versiones recientes renombraron las funciones `plotNA.*`; verificar en la documentación de la versión instalada), y `naniar` (`n_miss`, `pct_miss`, `vis_miss`, `gg_miss_var`).
- **Validación por enmascaramiento:** borrar datos conocidos, imputarlos y comparar con métricas (RMSE, MAE, Nash-Sutcliffe). Lo recomiendan F2, F3 y F7. Es la única forma de elegir con evidencia.

---

## 5. Restricciones que debe respetar cualquier decisión

1. **No imputar la variable respuesta en huecos largos.** `supera_25` sale del PM2.5 diario. Rellenar días u horas de apagón con un modelo sería clasificar superaciones que nadie midió. La regla de ≥ 18 horas válidas es la de la NOM-025-SSA1-2021 y conviene mantenerla.
2. **Sin fuga de información hacia la prueba.**
   - Todo método que aprenda parámetros (MICE, Kalman con modelo ajustado, KNN, deep learning) se ajusta solo con 2021–2023, o se aplica de forma que la prueba no informe al entrenamiento.
   - La interpolación ≤ 3 h es local y apenas cruza la frontera del 31-dic-2023 (como mucho 3 horas); no es fuga relevante, pero conviene mencionarlo.
3. **No imputar lo que la limpieza invalidó.** Las horas marcadas E, L o M por las reglas físicas no se imputan (decisión documentada en `data/clean/README.md`, regla 11).
4. **Revalidar después de imputar.** Los valores imputados deben cumplir las mismas reglas físicas. El código ya lo hace (bandera X).
5. **La prueba ya se abrió.** Cambiar la muestra principal ahora es una decisión posterior a la prueba y debe declararse así. Lo más defendible es presentar los cambios como **sensibilidades**, sin reemplazar el análisis principal, salvo que la profesora pida otra cosa explícitamente.
6. **Reproducibilidad.** Semilla fija; scripts en el repositorio. El pipeline completo se reejecuta en orden: `03_limpiar.R` → `06_explorar_etapa2.R` → `07a` → `07b` (requiere `MOTIVO_RECORRIDA`) → `07c`.

---

## 6. Opciones de decisión

### Opción A — Dejar todo como está y justificarlo mejor
- **Qué:** sin cambios de código. Agregar al informe la tabla de largos de huecos, el mecanismo de los faltantes y la sensibilidad que ya existe.
- **A favor:** costo casi nulo. La evidencia muestra que la imputación casi no cambia los resultados (0.31 µg/m³; 101 días; ΔAUC 0.074 frente a 0.070).
- **En contra:** no demuestra que la lineal sea la mejor elección para estos huecos. No ataca la pérdida de 35 % de los días.
- **Costo:** 1–2 horas.

### Opción B — Elegir el método horario con evidencia (enmascaramiento)
- **Qué:** sobre tramos completamente observados, borrar al azar bloques de 1, 2 y 3 horas (y quizá 4–6 h). Imputar con lineal, spline, Stineman, media móvil exponencial, Kalman (auto.arima y StructTS) y `na_seadec`. Comparar RMSE y MAE por variable. Quedarse con el ganador.
- **A favor:**
  - es lo que recomiendan F2, F3 y F7;
  - responde directamente a "¿por qué interpolación lineal?";
  - si gana la lineal (como en F7), no hay que cambiar nada más;
  - si gana otro, es una línea de código.
- **En contra:** si cambia el método, hay que reejecutar el pipeline completo. El efecto en los resultados será muy pequeño (sección 2.2).
- **Costo:** medio día.

### Opción C — Imputación múltiple de la meteorología diaria (MICE)
- **Qué:** imputar las variables meteorológicas diarias faltantes en días que sí tienen PM2.5 válido. Usar `mice` con `pmm`, con estos predictores:
  - la mediana de la red ese mismo día para esa variable (la meteorología es casi común en la ciudad: la presión de cada estación tiene correlación de 0.96 a 0.99 con la red);
  - las demás variables meteorológicas;
  - estación, temporada y año.

  Generar m ≈ 10 bases. Ajustar M0 y M1 en cada una y combinar las métricas (promedio del ΔAUC; la variabilidad entre imputaciones se suma a la del bootstrap).
- **A favor:**
  - recupera hasta 4,528 días (de 15,390 a ~19,900);
  - reduce el sesgo de selección (NO2 podría pasar de 511 a hasta 1,553 días);
  - usa la relación entre variables, que es lo que F3 dice que los métodos univariados no aprovechan;
  - es una técnica estándar y explicable en un curso de multivariado (F5, F6).
- **En contra:**
  - supone MAR;
  - hay que cuidar que el modelo de imputación se ajuste sin la prueba;
  - más complejo de reportar;
  - es decisión posterior a la prueba, así que conviene presentarla como sensibilidad.
- **Costo:** 1–2 días.
- **Alternativa más simple:** regresión estocástica por estación y variable sobre la mediana de la red (F5). Es más fácil de explicar, pero da una sola imputación.

### Opción C' — Quitar SR del modelo
- **Qué:** quitar la radiación de M1. No es imputación, sino selección de variables.
- **A favor:** recupera 1,426 días sin imputar nada. SR no aporta al AUC (−0.001).
- **En contra:** cambia el modelo después de abrir la prueba. Solo como sensibilidad declarada.

### Opción D — Deep learning (SAITS + CSDI, BRITS, etc.)
- **A favor:** estado del arte. Hay un antecedente con datos del SIMA en el mismo curso (F7).
- **En contra:**
  - necesita GPU y semanas de trabajo;
  - es difícil de explicar en un curso de multivariado;
  - la evidencia de F7 tiene contradicciones internas;
  - su ventaja es reconstruir apagones largos, que aquí no conviene, porque inventaría el PM2.5 (restricción 1);
  - las fuentes advierten que con pocos datos limpios es difícil entrenar estos modelos (F1).
- **Costo:** alto. **No recomendado.**

---

## 7. Recomendación [propuesta]

**Hacer A + B + C, y no D.** En orden de prioridad:

1. **Opción B, experimento de enmascaramiento horario.** Es la evidencia que más directo responde a una crítica sobre el método. Diseño sugerido:
   - **Variables:** PM2.5, TOUT, RH, PRS, SR, viento_u y viento_v.
   - **Datos:** tramos de 2021–2023 (entrenamiento) sin NA en ventanas de ±24 h.
   - **Bloques a borrar:** largos de 1, 2 y 3 horas (opcional 4–6). Borrar ~5 % de las horas en bloques, no puntos sueltos, para imitar los huecos reales. Varias semillas (por ejemplo, 5).
   - **Métodos:**
     - `na_interpolation(option = "linear" | "spline" | "stine")`;
     - `na_ma(k = 4, weighting = "exponential")`;
     - `na_kalman(model = "StructTS" | "auto.arima")`;
     - `na_seadec` sobre un objeto `ts` con `frequency = 24`;
     - `na_locf` como piso de referencia.

     Todos con `maxgap` cuando aplique. Verificar los argumentos exactos en la documentación de la versión instalada de imputeTS; los nombres cambiaron entre versiones.
   - **Métricas:** RMSE y MAE por variable y largo de hueco; sesgo medio; error en el promedio diario resultante.
   - **Regla de decisión, fijada de antemano:** cambiar de método solo si otro reduce el RMSE de PM2.5 en más de ~10 % y no empeora el promedio diario. Si no, quedarse con la lineal, que es la más simple y transparente.

2. **Opción A, documentar.** En el informe:
   - tabla de largos de huecos (sección 2.1);
   - % faltante por estación (sección 2.3);
   - mecanismo: no es MCAR; se supone MAR condicional a estación, temporada y año;
   - efecto medido de la imputación (sección 2.2);
   - sensibilidad sin imputación (que ya existe).

3. **Opción C, MICE de la meteorología diaria, como sensibilidad.**
   - No imputar PM2.5.
   - Ajustar el modelo de imputación solo con 2021–2023. Para 2024–2025, usar los mismos parámetros, o imputar entrenamiento y prueba por separado.
   - Reportar el ΔAUC combinado frente al principal.
   - Si da un valor parecido (0.06–0.08), refuerza que la selección de casos completos no infla el resultado. Un análisis exploratorio previo (quitando SR en lugar de imputar) dio 0.078 en la muestra ampliada frente a 0.072 en la principal, lo que sugiere que no lo infla.

4. **No usar deep learning.** Mencionar SAITS + CSDI (F7) solo como antecedente y explicar por qué no aplica: la variable respuesta, el costo y la evidencia.

**Frases útiles para el informe:**
- "Los huecos cortos (≤ 3 h) se imputaron por interpolación lineal, que en una validación por enmascaramiento obtuvo [RESULTADO] frente a spline, Kalman y descomposición estacional."
- "Los huecos largos no se imputaron, porque corresponden a apagones de días o semanas y rellenarlos inventaría la variable respuesta."
- "La imputación afecta el PM2.5 diario en 0.31 µg/m³ (mediana) y cambia la clase de 101 de 15,390 estación-días."

---

## 8. Preguntas abiertas

1. **¿Qué dijo exactamente la profesora?** Esto cambia la prioridad:
   - "la interpolación lineal suaviza" o "por qué ese método" → la prioridad es la **opción B**;
   - "perdieron muchos datos" o "casos completos sesgan" → la prioridad es la **opción C**;
   - "no justificaron ni documentaron" → basta con la **opción A** más la B;
   - "usen métodos multivariados del curso" → la **opción C** (MICE) es la que encaja.
2. ¿Hay tiempo para reejecutar el pipeline completo antes de la entrega?
3. ¿La profesora acepta cambios de muestra después de la prueba si se declaran como sensibilidad?

---

## 9. Apéndice: cómo se midieron las cifras de la sección 2

Python sobre `data/clean/` (13 estaciones de `muestra_pm25_2021_2025.csv`, años 2021–2025).

```python
# Largos de huecos horarios por variable
import pandas as pd, numpy as np
D = "data/clean/"
EST = sorted(pd.read_csv(D+"muestra_pm25_2021_2025.csv").estacion.unique())
V = ["PM2.5","TOUT","RH","SR","PRS","viento_u"]
h = pd.concat([pd.read_csv(D+f"sima_horario_limpio_{y}.csv",
               usecols=["estacion","fecha_hora"]+V+["f_PM2.5"]) for y in range(2021,2026)])
h = h[h.estacion.isin(EST)].sort_values(["estacion","fecha_hora"])
for v in V:
    lens=[]
    for _, g in h.groupby("estacion"):
        na = g[v].isna().values.astype(int)
        d = np.diff(np.r_[0,na,0]); s=np.where(d==1)[0]; t=np.where(d==-1)[0]
        lens += list(t-s)
    L=np.array(lens); tot=L.sum()
    print(v, round(100*h[v].isna().mean(),1),
          [round(100*L[(L>=a)&(L<=b)].sum()/tot,1) for a,b in [(4,6),(7,24),(25,168),(169,10**9)]])

# Efecto de la imputación en el PM2.5 diario:
# promedio con imputación (columna PM2.5 de la muestra) vs. promedio de horas con
# bandera f_PM2.5 en {"V","C"}, en días con >= 1 hora "I" y >= 18 h observadas.
```

Pérdida diaria: `data/clean/sima_diario_2020_2025.csv`, años ≥ 2021 y las 13 estaciones. Se cuentan los días con PM2.5 no nulo y luego los que además tienen completas TOUT, RH, SR, PRS, viento_u, viento_v, viento_rapidez_ms y horas_lluvia.

---

## 10. Fuentes

- F1. Video "Manejo de DATOS FALTANTES en series de tiempo": https://www.youtube.com/watch?v=w68twpX22BI (transcript)
- F2. Video "Imputación de datos faltantes para series de tiempo — Tutorial en R #RStudio": https://www.youtube.com/watch?v=ESMIVadldR0 (transcript)
- F3. Moritz, S. y Bartz-Beielstein, T. (2017). imputeTS: Time Series Missing Value Imputation in R. *The R Journal*, 9(1), 207–218.
- F4. Fang, C. y Wang, C. (2020). Time Series Data Imputation: A Survey on Deep Learning Approaches. arXiv:2011.11347.
- F5. Sandoval, W. "Imputación Series de Tiempo". RPubs: https://rpubs.com/wilsonsr/804544
- F6. Editverse. "Manejo de datos faltantes: estrategias y consejos": https://editverse.com/es/lidiar-con-consejos-de-estrategias-de-datos-faltantes/ (blog comercial; no citar como fuente académica)
- F7. Gómez Santos, J. E., Sánchez Rodríguez, M., Medina García, J. E., Pérez Almazán, S., Montibeller González, J. L., Ruiz Hernández, B. R. y Gómez Muñoz, R. (2026). A hybrid transformer-diffusion architecture for multivariate air quality data imputation. XVIII Congreso Mexicano de Inteligencia Artificial (COMIA 2026), Cuernavaca. Y el reporte del curso "MIMA-v1: Modelo de Imputación para Monitoreo Ambiental" (MA2003B, 6-dic-2025).
- Mencionada en F7 y útil para el informe (verificar antes de citar): Junger, W. L. y Ponce de Leon, A. (2015). Imputation of missing data in time series for air pollutants. *Atmospheric Environment*, 102, 96–104.
- Datos y código: repositorio `Leo-issacs/reto-sima-multivariados` (`R/limpieza.R`, `data/clean/README.md`, `data/clean/*.csv`, `output/etapa2/sensibilidad_imputacion_*.csv`).
