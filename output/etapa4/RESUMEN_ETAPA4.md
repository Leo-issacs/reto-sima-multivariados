# Etapa 4 · Resumen de las fases A, B y C

Rama `analisis/etapa4`. Decisiones en `docs/etapa4/decisiones_etapa4.md`, con su registro de cambios. Etiqueta de cierre de decisiones: `etapa4-decisiones-cerradas` (commit `8a56cc4`). Evaluación única de la prueba con la base v2: commit del código `7ac7011`, registrada en `output/etapa4/registro_prueba_v2.txt`. Todas las cifras salen de los CSV de `output/etapa4/`. **Fase D** (errores, supuestos, sensibilidades posteriores, viento, PM2.5/PM10 y NO2): `RESUMEN_FASE_D.md`.

## 1. Fase A (detalle en `imputacion/RESUMEN_FASE_A.md`)

- **D18:** la respuesta (PM2.5 diario) se calcula solo con horas **observadas** (≥ 18 h).
- **D19:** imputación horaria elegida por enmascaramiento en 2021–2023, con la regla del registro de cambios:
  - TOUT: `seadec` ≤ 12 h;
  - RH: Kalman ≤ 6 h;
  - SR: Stineman ≤ 2 h;
  - PRS: `seadec` ≤ 12 h;
  - viento u y v: lineal ≤ 3 h.
- **D20:** imputación diaria de los días con 1 a 4 meteorológicas faltantes con la **mediana de la red ajustada**. Ganó a MICE con el error de cada base imputada (RMSE relativo medio 0.450 frente a 0.593). MICE (m = 20) queda como sensibilidad.
- **D23:** el entrenamiento excluye los días previos a la reubicación (`sitio_valido` = 0).

## 2. Fase B · Evaluación única de la prueba (2024–2025) con la base v2

### 2.1 Tabla puente

Cada paso cambia una sola cosa respecto del anterior. El paso 0 reproduce exactamente la etapa 3 (comprobado contra `output/etapa3/prueba_sensibilidades.csv`).

| Paso | Cambio | n entrenamiento | n prueba | % superación (prueba) | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|---|---|
| 0 | datos-v1.2 (etapa 3) | 10,170 | 5,220 | 27.2 | 0.722 | 0.792 | 0.070 [0.047, 0.094] |
| 1 | + respuesta solo con horas observadas (D18) | 9,983 | 4,978 | 28.3 | 0.716 | 0.790 | 0.074 [0.051, 0.098] |
| 2 | + imputación horaria D19 (casos completos v2) | 10,024 | 4,987 | 28.4 | 0.717 | 0.790 | 0.074 [0.050, 0.098] |
| 3 | + imputación diaria con mediana de la red ajustada (D20) | 12,340 | 6,863 | 26.2 | 0.709 | 0.791 | 0.081 [0.055, 0.109] |
| 4 | + entrenamiento sin días previos a la reubicación (D23) = análisis final | 10,965 | 6,863 | 26.2 | 0.713 | 0.792 | 0.079 [0.054, 0.104] |

- **Paso 1 (respuesta sin imputar):** +0.004, y coincide con la sensibilidad de la etapa 3 (0.074 [0.051, 0.098]).
- **Paso 2 (imputación horaria D19):** no cambia la ΔAUC; agrega 41 días de entrenamiento y 9 de prueba.
- **Paso 3 (imputación diaria):** recupera 2,316 días de entrenamiento y 1,876 de prueba. El AUC de M0 baja (0.717 → 0.709) y el de M1 se mantiene, así que la ΔAUC sube a 0.081.
- **Paso 4 (D23):** quita 1,375 días de entrenamiento previos a la reubicación y casi no cambia nada (0.079).

**El resultado de la etapa 3 se sostiene y queda algo mayor:** 0.070 → **0.079 [0.054, 0.104]**.

### 2.2 Análisis final (paso 4)

| Métrica | M0 | M1 | M1 − M0 | IC 95 % |
|---|---|---|---|---|
| AUC | 0.713 | 0.792 | 0.079 | [0.054, 0.104] |
| Exactitud balanceada | 0.634 | 0.711 | 0.077 | [0.051, 0.100] |
| Sensibilidad | 0.565 | 0.742 | 0.177 | — |
| Especificidad | 0.703 | 0.680 | -0.023 | — |
| Brier | 0.172 | 0.154 | -0.018 | — |

**ΔAUC por temporada** (descriptivo, como en la etapa 3):

| Temporada | n | % superación | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| calida_humeda | 2,798 | 9.7 | 0.667 | 0.706 | 0.039 [-0.018, 0.104] |
| seca_calida | 1,693 | 40.2 | 0.580 | 0.731 | 0.151 [0.102, 0.193] |
| seca_fria | 2,372 | 35.7 | 0.680 | 0.748 | 0.069 [0.037, 0.100] |

**ΔAUC por año de la prueba:**

| Año | n | % superación | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| 2024 | 3,639 | 27.9 | 0.723 | 0.792 | 0.069 [0.032, 0.106] |
| 2025 | 3,224 | 24.3 | 0.702 | 0.790 | 0.088 [0.061, 0.124] |

### 2.3 Robustez y sensibilidades

| Análisis | n entrenamiento | n prueba | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| Análisis final: LDA, bloques de 14 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.104] |
| Robustez: logística | 10,965 | 6,863 | 0.721 | 0.792 | 0.071 [0.047, 0.095] |
| Bloques de 7 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.103] |
| Bloques de 28 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.045, 0.110] |
| MICE (pmm, m = 20; 4000 réplicas combinadas) | 10,965 | 6,863 | 0.713 | 0.791 | 0.078 [0.055, 0.103] |
| Límite de ≤ 2 faltantes | 10,408 | 6,801 | 0.713 | 0.789 | 0.077 [0.052, 0.102] |
| Respuesta con PM2.5 interpolado ≤ 3 h | 11,180 | 7,160 | 0.714 | 0.793 | 0.079 [0.053, 0.105] |
| Casos completos v2 sin imputación diaria | 8,995 | 4,987 | 0.720 | 0.791 | 0.071 [0.047, 0.096] |

- **Todas las variantes dan una mejora entre 0.071 y 0.079**, con intervalos que no incluyen el cero.
- **MICE** (promedio de 20 bases, 4,000 réplicas combinadas) da prácticamente lo mismo que la mediana de la red ajustada (0.078).
- **Logística y casos completos** dan 0.071: la meteorología mejora la clasificación en todos los casos.

### 2.4 Días y superación por estación (para el área de estudio)

v1.2 = muestra de la etapa 3; v2 = análisis final (entrenamiento con D23 + prueba).

| Estación | Días v1.2 | Días v2 | Diferencia | % superación v1.2 | % superación v2 | % superación v2 (prueba) |
|---|---|---|---|---|---|---|
| CE | 1,461 | 1,555 | 94 | 33.9 | 35.3 | 30.9 |
| NE | 1,141 | 1,282 | 141 | 29.4 | 29.1 | 30.7 |
| NE2 | 1,007 | 1,215 | 208 | 31.7 | 31.2 | 37.2 |
| NO | 700 | 631 | -69 | 33.0 | 32.5 | 49.0 |
| NO2 | 511 | 1,532 | 1,021 | 10.0 | 18.4 | 11.2 |
| NTE | 597 | 1,373 | 776 | 19.1 | 14.8 | 16.6 |
| NTE2 | 1,743 | 1,696 | -47 | 22.4 | 23.2 | 27.3 |
| SE | 1,359 | 1,287 | -72 | 15.2 | 15.3 | 16.5 |
| SE2 | 1,488 | 1,680 | 192 | 47.8 | 46.1 | 42.8 |
| SE3 | 1,314 | 1,574 | 260 | 15.5 | 19.1 | 25.1 |
| SO | 1,268 | 1,284 | 16 | 46.6 | 43.8 | 39.3 |
| SO2 | 1,483 | 1,564 | 81 | 18.4 | 18.9 | 26.5 |
| SUR | 1,318 | 1,155 | -163 | 9.3 | 10.6 | 11.0 |
| Total | 15,390 | 17,828 | 2,438 | 26.3 | 26.0 | 26.2 |

## 3. Fase C1 · Validación e interpretación del LDA (D21)

### 3.1 Estabilidad de los coeficientes (bootstrap por bloques de 14 días en el entrenamiento, 1,000 réplicas)

Solo se interpretan los predictores con signo estable (≥ 95 % de las réplicas con el mismo signo que el modelo completo). Figura: `lda/coeficientes_ic.png`.

| Predictor | Tipo | Coef. estandarizado | IC 95 % | % mismo signo | Corr. de estructura [IC 95 %] |
|---|---|---|---|---|---|
| estNTE | estación | -0.416 | [-0.544, -0.286] | 100.0 | -0.157 [-0.204, -0.104] |
| estSUR | estación | -0.377 | [-0.446, -0.307] | 100.0 | -0.176 [-0.213, -0.135] |
| estSE3 | estación | -0.353 | [-0.429, -0.271] | 100.0 | -0.152 [-0.189, -0.112] |
| estNTE2 | estación | -0.303 | [-0.399, -0.204] | 100.0 | -0.080 [-0.115, -0.045] |
| estSE | estación | -0.242 | [-0.331, -0.160] | 100.0 | -0.142 [-0.178, -0.102] |
| estSO2 | estación | -0.213 | [-0.303, -0.122] | 100.0 | -0.167 [-0.197, -0.134] |
| estNO2 | estación | -0.209 | [-0.360, -0.043] | 99.4 | -0.052 [-0.107, 0.003] |
| estSO | estación | 0.128 | [0.044, 0.221] | 99.8 | 0.267 [0.201, 0.328] |
| estNE2 | estación | -0.097 | [-0.186, -0.005] | 97.8 | 0.059 [0.019, 0.101] |
| estNE | estación | -0.091 | [-0.173, -0.006] | 98.1 | 0.017 [-0.037, 0.069] |
| viento_rapidez_ms | meteorología | -0.501 | [-0.631, -0.347] | 100.0 | -0.533 [-0.615, -0.433] |
| PRS | meteorología | -0.460 | [-0.574, -0.303] | 100.0 | -0.367 [-0.464, -0.246] |
| TOUT | meteorología | 0.435 | [0.162, 0.701] | 99.9 | -0.067 [-0.210, 0.096] |
| SR | meteorología | -0.170 | [-0.312, -0.019] | 98.6 | -0.032 [-0.132, 0.080] |
| horas_lluvia | meteorología | -0.066 | [-0.101, -0.024] | 99.8 | -0.159 [-0.191, -0.123] |
| temseca_fria | temporada | 0.875 | [0.637, 1.125] | 100.0 | 0.389 [0.225, 0.529] |
| temseca_calida | temporada | 0.483 | [0.293, 0.680] | 100.0 | 0.156 [-0.022, 0.323] |

**Signo no estable (no se interpretan):**

| Predictor | Tipo | Coef. estandarizado | IC 95 % | % mismo signo |
|---|---|---|---|---|
| estNO | estación | -0.056 | [-0.133, 0.028] | 92.2 |
| estSE2 | estación | 0.008 | [-0.104, 0.118] | 56.0 |
| RH | meteorología | -0.082 | [-0.222, 0.065] | 84.3 |
| viento_u | meteorología | -0.032 | [-0.169, 0.084] | 69.2 |
| viento_v | meteorología | 0.004 | [-0.067, 0.065] | 53.0 |

**Lectura (con el alcance de D21):**
- **Lo que sí se puede interpretar.** Rapidez del viento (−), presión como anomalía de su estación (−), temperatura (+), radiación (−) y horas de lluvia (−) tienen signo estable. Condicional a las demás variables, menos viento, presión más baja de lo normal y más temperatura se asocian con superación.
- **La temperatura se lee solo de forma condicional.** Su correlación de estructura es casi nula (−0.07 [−0.21, 0.10]): por sí sola no separa las clases, pero condicionada a la temporada sí (el patrón de tipo Simpson de las etapas 2 y 3).
- **SR y horas de lluvia** tienen coeficientes pequeños: su dirección es estable, pero su peso es bajo.
- **RH y las componentes u y v no tienen signo estable**, así que no se interpretan.
- **Nada de esto es causal ni ordena importancias** (D21).

### 3.2 LDA frente a logística (predictores estandarizados)

| Predictor | LDA | Logística | LDA (÷ máx.) | Logística (÷ máx.) | Marca |
|---|---|---|---|---|---|
| estSE2 | 0.008 | -0.053 | 0.009 | -0.050 | SIGNO DISTINTO |
| TOUT | 0.435 | 0.575 | 0.498 | 0.547 |  |
| RH | -0.082 | -0.070 | -0.093 | -0.066 |  |
| SR | -0.170 | -0.195 | -0.194 | -0.185 |  |
| PRS | -0.460 | -0.552 | -0.526 | -0.524 |  |
| viento_rapidez_ms | -0.501 | -0.714 | -0.573 | -0.679 |  |
| viento_u | -0.032 | -0.058 | -0.036 | -0.055 |  |
| viento_v | 0.004 | 0.006 | 0.005 | 0.006 |  |
| horas_lluvia | -0.066 | -0.211 | -0.076 | -0.200 |  |

Las 8 meteorológicas tienen el mismo signo en las dos técnicas. La única discrepancia es la indicadora de SE2, con coeficiente cercano a cero en ambas (signo no estable en el bootstrap).

### 3.3 Consistencia entre pliegues

| Predictor | Valida 2022 (entrena 2021) | Valida 2023 (entrena 2021–2022) | Final (2021–2023) | Mismo signo en los tres |
|---|---|---|---|---|
| temseca_calida | 0.288 | 0.472 | 0.483 | sí |
| temseca_fria | 0.737 | 0.894 | 0.875 | sí |
| TOUT | 0.382 | 0.425 | 0.435 | sí |
| RH | -0.015 | -0.092 | -0.082 | sí |
| SR | -0.306 | -0.261 | -0.170 | sí |
| PRS | -0.469 | -0.477 | -0.460 | sí |
| viento_rapidez_ms | -0.543 | -0.430 | -0.501 | sí |
| viento_u | -0.051 | -0.029 | -0.032 | sí |
| viento_v | -0.039 | 0.013 | 0.004 | no |
| horas_lluvia | -0.143 | -0.099 | -0.066 | sí |

| Pliegue | Estaciones | n entrenamiento | n validación | AUC M0 | AUC M1 | ΔAUC |
|---|---|---|---|---|---|---|
| valida_2022 | 12 | 2,729 | 3,925 | 0.700 | 0.775 | 0.074 |
| valida_2023 | 13 | 6,947 | 4,018 | 0.733 | 0.816 | 0.083 |

- Todos los coeficientes de temporada y meteorología conservan el signo en los tres ajustes, salvo viento_v (cercano a cero).
- El pliegue que valida 2022 se entrena con 2021 sin NE, porque con D23 todo el 2021 de NE es previo a su reubicación; por eso tiene 12 estaciones.

### 3.4 QDA como técnica no exitosa

| Modelo | Predictores | AUC en la prueba | gamma | lambda | Referencia Python (Opus, no oficial) |
|---|---|---|---|---|---|
| LDA (M1, análisis final) | indicadoras + 8 meteorológicas | 0.792 | — | — | 0.792 |
| QDA regularizada (klaR::rda) | indicadoras + 8 meteorológicas | 0.788 | 0.001 | 0.966 | 0.728–0.742 |
| LDA | solo 8 meteorológicas | 0.718 | — | — | 0.718 |
| QDA (MASS::qda) | solo 8 meteorológicas | 0.704 | — | — | 0.709 |
| QDA regularizada (klaR::rda) | solo 8 meteorológicas | 0.712 | 0.735 | 0.768 | 0.709 |

- **La QDA no mejora al LDA.** Aunque se ajusta al rechazo de covarianzas iguales (M de Box), la regularizada con todos los predictores queda en 0.788 frente a 0.792. Con solo meteorología, 0.704 (sin regularizar) y 0.712 (regularizada), frente a 0.718.
- **La regularización elegida la acerca al LDA:** con todos los predictores, `lambda` = 0.97 (casi la covarianza común).
- **Frente a la referencia de Python de Opus**, la QDA regularizada de R da un AUC mayor (0.788 contra 0.728–0.742), pero la conclusión es la misma: ganar en supuestos no se traduce en mejor clasificación.

### 3.5 Calibración de M1 en la prueba

| Modelo | Intercepto | Pendiente |
|---|---|---|
| M0 | -0.135 | 0.816 |
| M1 | -0.249 | 0.822 |

- **Las probabilidades siguen sin estar calibradas:** la pendiente es 0.82 (ideal 1; en la etapa 3 fue 0.76).
- **Por eso se habla de «puntaje» o «probabilidad estimada por el modelo»** (D21), y la recalibración queda como recomendación.
- Deciles en `lda/calibracion_deciles.csv`; figura `lda/calibracion_v2.png`.

## 4. Fase C2 · Área de estudio y reubicaciones (D22, D23)

### 4.1 Superación por estación y año

Base v2, todos los días con respuesta válida (PM2.5 con ≥ 18 h observadas). Cada celda: % de días con superación (días). Figura: `area_estudio/superacion_por_estacion_anio.png`.

| estacion | 2021 | 2022 | 2023 | 2024 | 2025 |
|---|---|---|---|---|---|
| CE | 35.3 (329) | 40.1 (324) | 38.6 (311) | 32.4 (293) | 29.2 (301) |
| NE | 27.0 (359) | 32.9 (347) | 22.9 (332) | 32.0 (331) | 29.1 (333) |
| NE2 | 28.6 (329) | 28.0 (347) | 33.2 (322) | 38.0 (205) | 20.0 (15) |
| NO | 29.7 (310) | 27.4 (270) | 39.6 (149) | 64.1 (39) | 0.0 (12) |
| NO2 | 11.5 (348) | 37.7 (334) | 17.7 (316) | 0.0 (243) | 20.3 (296) |
| NTE | 39.7 (295) | 16.3 (306) | 9.1 (329) | 17.2 (355) | 16.0 (307) |
| NTE2 | 18.0 (344) | 20.8 (355) | 22.9 (327) | 32.7 (333) | 21.8 (339) |
| SE | 26.9 (335) | 12.4 (347) | 12.4 (282) | 14.6 (267) | 18.1 (310) |
| SE2 | 46.1 (310) | 53.6 (321) | 46.3 (348) | 50.4 (353) | 35.6 (354) |
| SE3 | 19.5 (308) | 12.9 (350) | 14.7 (339) | 24.3 (329) | 25.9 (251) |
| SO | 55.2 (346) | 40.2 (338) | 45.0 (340) | 47.8 (289) | 25.2 (266) |
| SO2 | 15.3 (301) | 14.2 (358) | 14.2 (339) | 22.6 (323) | 31.6 (244) |
| SUR | 3.0 (235) | 11.8 (280) | 10.1 (286) | 12.1 (280) | 10.4 (278) |

**SE2, SO y SUR** (con la mediana del PM2.5 y la superación con el PM2.5 de la etapa 1):

| Estación | Año | Días (v2) | % superación (v2) | Mediana PM2.5 (µg/m³) | % superación (PM2.5 de la etapa 1) |
|---|---|---|---|---|---|
| SE2 | 2021 | 310 | 46.1 | 24.0 | 46.0 |
| SE2 | 2022 | 321 | 53.6 | 27.0 | 53.2 |
| SE2 | 2023 | 348 | 46.3 | 23.8 | 45.3 |
| SE2 | 2024 | 353 | 50.4 | 25.2 | 49.9 |
| SE2 | 2025 | 354 | 35.6 | 20.5 | 34.4 |
| SO | 2021 | 346 | 55.2 | 26.3 | 55.2 |
| SO | 2022 | 338 | 40.2 | 22.0 | 40.3 |
| SO | 2023 | 340 | 45.0 | 23.1 | 44.5 |
| SO | 2024 | 289 | 47.8 | 24.6 | 47.9 |
| SO | 2025 | 266 | 25.2 | 17.8 | 23.0 |
| SUR | 2021 | 235 | 3.0 | 11.2 | 2.9 |
| SUR | 2022 | 280 | 11.8 | 16.8 | 11.0 |
| SUR | 2023 | 286 | 10.1 | 15.0 | 9.9 |
| SUR | 2024 | 280 | 12.1 | 15.4 | 12.1 |
| SUR | 2025 | 278 | 10.4 | 15.8 | 10.2 |

- **SE2 (Juárez):**
  - Es alta todo el periodo (46–54 % en 2021–2024) y no tiene una tendencia creciente.
  - Baja en 2025 (35.6 %), el año de su equipo nuevo de PM2.5.
  - Es consistente con D22: el crecimiento urbano puede explicar el nivel alto, pero no se puede atribuir con este diseño.
- **SO (Santa Catarina):**
  - Es alta y variable en 2021–2024 (40–55 %), pero en 2025 baja a 25.2 % (266 días).
  - D22 citaba 54.3 % en 2025 porque usaba la muestra de casos completos de la etapa 3, que en 2025 solo tenía 70 días de SO (sección 5).
- **SUR:**
  - Pasa de 3.0 % en 2021 a 10–12 % desde 2022.
  - En abril–junio, de 1.4 % (mediana 10.2 µg/m³) en 2021 a 15.1 % (18.6 µg/m³) en 2022:

| Abril–junio | Días | % superación | Mediana PM2.5 (µg/m³) |
|---|---|---|---|
| 2021 | 73 | 1.4 | 10.2 |
| 2022 | 86 | 15.1 | 18.6 |

### 4.2 Presión frente a la red alrededor de las reubicaciones

Mediana de PRS − mediana diaria de la red, 6 meses antes y 6 meses después de la fecha del PIGECA (datos-v1.2). Figura mensual: `area_estudio/prs_relativa_reubicaciones.png`.

| Estación | Reubicación | 6 meses antes | 6 meses después | Cambio |
|---|---|---|---|---|
| NO | 2021-07-01 | -1.31 | -1.80 | -0.48 |
| SE | 2021-10-01 | 8.83 | 8.03 | -0.80 |
| SO | 2021-10-01 | -12.98 | -13.07 | -0.09 |
| NTE | 2021-10-01 | 0.22 | 1.84 | +1.62 |
| SUR | 2021-10-01 | -7.60 | -1.92 | +5.68 |
| NE | 2022-03-01 | 4.66 | 4.36 | -0.30 |
| CE (control, corte 2021-10-01) | 2021-10-01 | -2.53 | -3.02 | -0.49 |

- **SUR** cambia de nivel con claridad (+5.7 mm Hg).
- **NTE** cambia algo (+1.6 mm Hg).
- **NO, SE, SO y NE** cambian menos de 1 mm Hg, del orden del control CE (−0.5 mm Hg). Su reubicación no deja huella clara en la presión; D23 se apoya en las fechas del PIGECA.

### 4.3 Altitud y superación

Mapa: `area_estudio/mapa_estaciones_altitud.png` (altitud de `data/metadata/estaciones.csv`).

| Estación | Nombre | Altitud (m) | % superación (v2) |
|---|---|---|---|
| NO2 | García | 702 | 18.4 |
| SO | Santa Catarina | 674 | 43.8 |
| SO2 | San Pedro | 636 | 18.9 |
| NO | San Bernabé | 568 | 32.5 |
| CE | Obispado | 562 | 35.3 |
| SUR | Pueblo Serena | 555 | 10.6 |
| NTE2 | Universidad | 520 | 23.2 |
| NTE | Escobedo | 503 | 14.8 |
| SE | La Pastora | 500 | 15.3 |
| NE | San Nicolás | 474 | 29.1 |
| NE2 | Apodaca | 432 | 31.2 |
| SE2 | Juárez | 387 | 46.1 |
| SE3 | Cadereyta | 334 | 19.1 |

No hay una relación simple con la altitud. SO (674 m, en el oeste encajonado) y SE2 (387 m, en el este) tienen las superaciones más altas, mientras que NO2 (702 m) y SE3 (334 m) están bajas.

## 5. Lo que no cuadra

1. **SO en 2025: las cifras de D22 venían de la muestra de casos completos.** Con todos los días válidos, SO 2025 tiene 25.2 % de superación (266 días), no 54.3 % (70 días de la muestra de la etapa 3). La frase de D22 «SO es alta y variable» vale para 2021–2024. Las cifras de SE2 también cambian un poco (46.1, 53.6, 46.3, 50.4 y 35.6 frente a 49.8, 53.3, 48.2, 49.9 y 36.6), sin cambiar la lectura.
2. **NO2 (García) tiene un cambio de nivel del PM2.5.** Desde mediados de 2023 (ya en agosto) y hasta enero de 2025, su PM2.5 diario no pasa de 25 µg/m³ (máximo 24.9 en 2024; 0 superaciones en 243 días), y en febrero de 2025 vuelve a su nivel anterior. NO2 no está en la lista de equipos nuevos de 2025. Conviene preguntar a SIMA; afecta a días de la prueba, aunque no cambia la evaluación ya hecha.
3. **La presión solo confirma la reubicación de SUR (y algo la de NTE).** NO, SE, SO y NE no muestran cambio de nivel en la fecha del PIGECA.
4. **Los sensores de radiación de NO2 y NTE leen muy bajo** (media de SR 0.015 y 0.041 kW/m², contra 0.12–0.18 en las demás). Por eso la imputación diaria les da 398 valores de SR negativos (sin recortar; ver el registro de cambios, punto 4).
5. **MICE con `ignore` no puede estimar el efecto de 2024 y 2025** (esas filas se imputan como 2021). Afecta solo a la sensibilidad, que de todos modos da 0.078.
6. **NO tiene muy pocos días con respuesta válida en 2024–2025** (39 y 12). Su 64.1 % de 2024 y su 0 % de 2025 no son interpretables.
7. **La temperatura no separa las clases por sí sola** (correlación de estructura ≈ 0): su coeficiente positivo es condicional a la temporada.

## 6. Reproducibilidad

- **Prueba desde un clon limpio** del commit `61c4ddf`, con `renv::restore()` y sin los Excel (`SIMA_DATA_DIR` sin definir). Corrieron sin errores 06, 06b, 07a, 07b, 07c, 08a, 08b, 08c, 08d, 09a, 09b y 09c. 08a tardó 9 min; cada uno de los demás, menos de 2 min.
- **Resultado:** ignorando los finales de línea, **todas las salidas versionadas quedaron idénticas**. Las excepciones son:
  - las líneas con la fecha de generación de los `RESUMEN`;
  - `modelo_final.rds`, que guarda su fecha de creación;
  - los tiempos de 08a;
  - los registros de 07b y 09a, a los que la verificación agregó su corrida (con `MOTIVO_RECORRIDA`).
- **El candado de 09a funcionó como debe.** 09a exige que no haya cambios sin commit en `R/`, `scripts/` y `data/clean/v2/`, y se activó porque 08b y 08d regeneran sus CSV con otro final de línea. Se restauraron desde el commit (mismo contenido) y 09a reprodujo la evaluación exactamente.

## 7. Archivos

- **Fase A:** `output/etapa4/imputacion/` (`RESUMEN_FASE_A.md`) y `data/clean/v2/`.
- **Fase B:** `output/etapa4/` (`RESUMEN.md`, `tabla_puente.csv`, `prueba_v2_*.csv`, `dias_superacion_por_estacion.csv`, `registro_prueba_v2.txt`, `figuras/`) y `output/etapa4/ensayo/` (prueba del código sin 2024–2025).
- **Fase C:** `output/etapa4/lda/` (`estabilidad_coeficientes.csv`, `lda_vs_logistica.csv`, `coeficientes_por_pliegue.csv`, `pliegues_auc_validacion.csv`, `qda_vs_lda.csv`, calibración, `coeficientes_ic.png`) y `output/etapa4/area_estudio/`.
- **Código:** `scripts/08a`–`08d`, `09a`–`09c`, `R/imputacion.R` y `R/modelo_etapa4.R` (funciones de 07b sin cambios).
