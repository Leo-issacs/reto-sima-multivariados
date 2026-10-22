# Etapa 4 · Fase F: análisis posteriores a la retroalimentación final

Generado por `scripts/10_analisis_retro_final.R` el 2026-10-22 16:09. **Todo es posterior a la evaluación de la prueba (09a)**; no cambia el modelo principal (LDA: ΔAUC 0.079 [0.054, 0.104]; logística: 0.071 [0.047, 0.095]). Reglas en `docs/etapa4/decisiones_etapa4.md` (fase F). Bootstrap por bloques de 14 días, 1000 réplicas, semilla 2026.

## Decisiones tomadas con el entrenamiento (antes de la prueba)

| decision | resultado | base |
|---|---|---|
| A2: splines como tratamiento de la no linealidad | sí | Diferencia de AUC de validación (splines − lineal): 0.0056 y 0.0214; regla ≥ 0.005 en los dos pliegues |
| B: escala del PM2.5 del día anterior | original | Diferencia de AUC de validación de MP logístico (log − original): 0.0030 y -0.0002; regla > 0 en los dos pliegues |
| C: corte de vigilancia (lda) | 0.1822 | Predicciones de M1 en 2022 y 2023 (pliegues de la validación progresiva) |
| C: corte de vigilancia (logistica) | 0.1924 | Predicciones de M1 en 2022 y 2023 (pliegues de la validación progresiva) |
| C: corte de equilibrio (lda) | 0.2625 | Predicciones de M1 en 2022 y 2023 (pliegues de la validación progresiva) |
| C: corte de equilibrio (logistica) | 0.2671 | Predicciones de M1 en 2022 y 2023 (pliegues de la validación progresiva) |
| C: corte actual | 0.2589 | Prevalencia del entrenamiento |

## A1. Regresión logística: variables relevantes

M1 logístico con los 22 predictores estandarizados del LDA; IC por bootstrap por bloques de 14 días en el entrenamiento (1000 réplicas válidas). Importancia: caída media del AUC en la prueba al permutar la variable (200 permutaciones). Sin valores p (la dependencia los invalida).

| Variable | 1 DE | OR por 1 DE [IC 95 %] | % mismo signo | Signo estable | Coincide con el LDA | Caída del AUC (permutación) |
|---|---|---|---|---|---|---|
| Temperatura | 6.25 °C | 1.78 [1.24, 2.71] | 99.9 | sí | sí | 0.0318 |
| Humedad relativa | 14.96 % | 0.93 [0.79, 1.12] | 75.3 | no | sí | 0.0003 |
| Radiación solar | 0.08 kW/m² | 0.82 [0.67, 1.00] | 97.3 | sí | sí | 0.0006 |
| Presión (anomalía) | 3.48 mm Hg | 0.58 [0.49, 0.70] | 100.0 | sí | sí | 0.0509 |
| Rapidez del viento | 0.85 m/s | 0.49 [0.39, 0.62] | 100.0 | sí | sí | 0.0384 |
| Viento u (este-oeste) | 1.17 m/s | 0.94 [0.78, 1.11] | 74.4 | no | sí | -0.0011 |
| Viento v (norte-sur) | 1.07 m/s | 1.01 [0.89, 1.12] | 52.7 | no | sí | 0.0001 |
| Horas con lluvia | 1.10 h | 0.81 [0.64, 0.93] | 99.9 | sí | sí | 0.0084 |

**Importancia por permutación (todos los grupos):**

| Grupo | Clasificador | Caída del AUC | Rango 95 % de las permutaciones |
|---|---|---|---|
| Estación | Logística | 0.0665 | [0.0599, 0.0739] |
| Estación | LDA | 0.0687 | [0.0617, 0.0758] |
| Temporada | Logística | 0.1382 | [0.1293, 0.1473] |
| Temporada | LDA | 0.1420 | [0.1329, 0.1513] |
| Viento (u, v y rapidez) | Logística | 0.0341 | [0.0280, 0.0396] |
| Viento (u, v y rapidez) | LDA | 0.0258 | [0.0205, 0.0307] |
| Temperatura | Logística | 0.0318 | [0.0278, 0.0361] |
| Temperatura | LDA | 0.0318 | [0.0281, 0.0359] |
| Humedad relativa | Logística | 0.0003 | [-0.0005, 0.0009] |
| Humedad relativa | LDA | 0.0011 | [-0.0001, 0.0021] |
| Radiación solar | Logística | 0.0006 | [-0.0010, 0.0023] |
| Radiación solar | LDA | 0.0008 | [-0.0010, 0.0026] |
| Presión (anomalía) | Logística | 0.0509 | [0.0458, 0.0565] |
| Presión (anomalía) | LDA | 0.0573 | [0.0523, 0.0632] |
| Rapidez del viento | Logística | 0.0384 | [0.0325, 0.0439] |
| Rapidez del viento | LDA | 0.0284 | [0.0233, 0.0334] |
| Viento u (este-oeste) | Logística | -0.0011 | [-0.0016, -0.0005] |
| Viento u (este-oeste) | LDA | -0.0006 | [-0.0010, -0.0002] |
| Viento v (norte-sur) | Logística | 0.0001 | [-0.0000, 0.0001] |
| Viento v (norte-sur) | LDA | 0.0001 | [0.0000, 0.0001] |
| Horas con lluvia | Logística | 0.0084 | [0.0058, 0.0121] |
| Horas con lluvia | LDA | 0.0028 | [0.0014, 0.0043] |

## A2. Linealidad en la escala logit

**Grados de libertad efectivos del GAM (entrenamiento; 1 = recta):**

| Variable | edf |
|---|---|
| Temperatura | 8.40 |
| Humedad relativa | 5.35 |
| Radiación solar | 6.58 |
| Presión (anomalía) | 5.60 |
| Rapidez del viento | 6.27 |
| Viento u (este-oeste) | 6.55 |
| Viento v (norte-sur) | 5.91 |
| Horas con lluvia | 1.59 |

**A2c. AUC de M1 logístico lineal, con splines y con «llovió»:**

| Conjunto | n | AUC M1 lineal | AUC M1 splines | Splines − lineal | AUC M1 + llovió | Llovió − lineal |
|---|---|---|---|---|---|---|
| valida_2022 | 3 925 | 0.774 | 0.780 | +0.0056 | 0.775 | +0.0002 |
| valida_2023 | 4 018 | 0.817 | 0.838 | +0.0214 | 0.817 | -0.0000 |
| prueba | 6 863 | 0.792 | 0.811 | +0.0188 | 0.792 | -0.0004 |

Regla: splines si suben el AUC de validación ≥ 0.005 en los dos pliegues → **se adoptan como tratamiento**.
ΔAUC en la prueba de M1 con splines sobre M0 logístico: 0.090 [0.060, 0.120] (lineal: 0.071 [0.047, 0.095]).

## B. Persistencia (PM2.5 del día anterior)

| parte | n_total | n_con_persistencia | pct_superacion_total | pct_superacion_con_persistencia | escala | edf_spline_entrenamiento | cor_spearman_pm_ayer_pm |
|---|---|---|---|---|---|---|---|
| entrenamiento | 10965 | 10345 | 25.9 | 26.3 | original | 5.77 | 0.65 |
| prueba |  6863 |  6280 | 26.2 | 26.3 | original | 5.77 | 0.70 |

**AUC en la prueba (submuestra con persistencia):**

| Modelo | AUC LDA | AUC logística |
|---|---|---|
| M0 | 0.712 | 0.720 |
| M1 | 0.792 | 0.792 |
| MP | 0.872 | 0.872 |
| MP1 | 0.887 | 0.888 |

**Diferencias de AUC con IC 95 %:**

| Comparación | LDA | Logística |
|---|---|---|
| M1 − M0 | 0.079 [0.054, 0.106] | 0.072 [0.048, 0.098] |
| M1 − MP | -0.080 [-0.103, -0.055] | -0.079 [-0.101, -0.057] |
| MP − M0 | 0.159 [0.126, 0.192] | 0.152 [0.120, 0.183] |
| MP1 − M1 | 0.096 [0.076, 0.115] | 0.095 [0.077, 0.113] |
| MP1 − MP | 0.016 [0.008, 0.025] | 0.016 [0.007, 0.025] |

El PM2.5 del día anterior estaría disponible antes del día evaluado; la meteorología observada del mismo día no. La comparación es retrospectiva y no es una prueba de pronóstico.

## C. Umbral de clasificación

**Cortes elegidos con los pliegues (2022 y 2023) y su desempeño en esos pliegues:**

| Clasificador | Objetivo | Corte | Sensibilidad | Especificidad | VPP | Exactitud balanceada |
|---|---|---|---|---|---|---|
| LDA | vigilancia | 0.182 | 0.800 | 0.603 | 0.409 | 0.701 |
| LDA | equilibrio | 0.262 | 0.713 | 0.712 | 0.459 | 0.713 |
| LDA | actual | 0.259 | 0.717 | 0.707 | 0.457 | 0.712 |
| Logística | vigilancia | 0.192 | 0.800 | 0.603 | 0.409 | 0.701 |
| Logística | equilibrio | 0.267 | 0.716 | 0.710 | 0.458 | 0.713 |
| Logística | actual | 0.259 | 0.723 | 0.697 | 0.450 | 0.710 |

**C3. Los mismos cortes en la prueba (M1 del análisis final):**

| Clasificador | Objetivo | Corte | Sensibilidad | Especificidad | VPP | Falsas alarmas por detección | Exactitud balanceada | % días marcados |
|---|---|---|---|---|---|---|---|---|
| LDA | vigilancia | 0.182 | 0.839 | 0.566 | 0.407 | 1.46 | 0.702 | 54.0 |
| LDA | equilibrio | 0.262 | 0.738 | 0.684 | 0.454 | 1.20 | 0.711 | 42.6 |
| LDA | actual | 0.259 | 0.742 | 0.680 | 0.451 | 1.22 | 0.711 | 43.1 |
| Logística | vigilancia | 0.192 | 0.826 | 0.585 | 0.414 | 1.41 | 0.705 | 52.3 |
| Logística | equilibrio | 0.267 | 0.727 | 0.695 | 0.459 | 1.18 | 0.711 | 41.5 |
| Logística | actual | 0.259 | 0.739 | 0.684 | 0.454 | 1.20 | 0.711 | 42.7 |

**C4. Métricas en la prueba según el corte (sensibilidad / especificidad / VPP):**

| Corte | LDA (sens. / espec. / VPP) | Logística (sens. / espec. / VPP) |
|---|---|---|
| 0.10 | 0.93 / 0.39 / 0.35 | 0.93 / 0.38 / 0.35 |
| 0.15 | 0.88 / 0.51 / 0.39 | 0.88 / 0.50 / 0.38 |
| 0.20 | 0.82 / 0.59 / 0.42 | 0.82 / 0.60 / 0.42 |
| 0.25 | 0.75 / 0.67 / 0.44 | 0.75 / 0.67 / 0.45 |
| 0.30 | 0.69 / 0.74 / 0.49 | 0.68 / 0.74 / 0.49 |
| 0.35 | 0.63 / 0.79 / 0.52 | 0.63 / 0.80 / 0.53 |
| 0.40 | 0.57 / 0.83 / 0.55 | 0.57 / 0.84 / 0.55 |
| 0.45 | 0.51 / 0.86 / 0.57 | 0.51 / 0.87 / 0.58 |
| 0.50 | 0.45 / 0.89 / 0.60 | 0.45 / 0.90 / 0.61 |
| 0.55 | 0.39 / 0.92 / 0.63 | 0.39 / 0.92 / 0.64 |
| 0.60 | 0.34 / 0.94 / 0.65 | 0.33 / 0.94 / 0.67 |

Las probabilidades no están calibradas (pendiente de recalibración 0.82); los cortes se eligieron sin usar la prueba.

## D. Bootstrap estratificado por temporada

| Clasificador | ΔAUC | IC actual (bloques de 14 días) | IC estratificado por temporada | Bloques por temporada |
|---|---|---|---|---|
| LDA | 0.079 | [0.054, 0.104] | [0.056, 0.101] | calida_humeda: 22; seca_calida: 14; seca_fria: 17 |
| Logística | 0.071 | [0.047, 0.095] | [0.050, 0.091] | calida_humeda: 22; seca_calida: 14; seca_fria: 17 |

## E. Episodios frente a días-estación (prueba, corte actual)

| Rachas | Días-estación | Episodios | Duración mediana | Duración máxima | % de un día | % detectados M0 / M1 | % primer día M0 / M1 |
|---|---|---|---|---|---|---|---|
| PM2.5 > 25 | 1 799 | 733 | 2.0 | 16 | 47.1 | 49.0 / 72.4 | 49.0 / 65.6 |
| PM2.5 > 40 |   349 | 219 | 1.0 |  8 | 64.8 | 77.2 / 90.0 | 77.2 / 87.7 |

## F. Exclusiones y posible sesgo

**F1. Causas (las causas (a)–(d) suman 23 738; (e) es parte de (b) y (c)):**

| Causa | Estación-días | % |
|---|---|---|
| (a) Sin PM2.5 suficiente (< 18 h observadas) |  4 346 | 18.3 |
| (b) PM2.5 y meteorología completa | 15 011 | 63.2 |
| (c) PM2.5 y 1–4 meteorológicas imputadas (incluidos) |  4 192 | 17.7 |
| (d) PM2.5 y 5–8 meteorológicas faltantes (excluidos) |    189 | 0.8 |
| (e) De (b) o (c), previos a una reubicación (fuera del entrenamiento) |  1 375 | 5.8 |

**F2. Respuesta por grupo:**

| Grupo | n | % superación | Mediana PM2.5 | % PM2.5 > 40 |
|---|---|---|---|---|
| (b) PM2.5 y meteorología completa | 15 011 | 27.0 | 18.5 | 5.5 |
| (c) PM2.5 y 1–4 meteorológicas imputadas (incluidos) |  4 192 | 23.5 | 17.7 | 3.7 |
| (d) PM2.5 y 5–8 meteorológicas faltantes (excluidos) |    189 | 33.3 | 18.7 | 5.8 |
| (e) De (b) o (c), previos a una reubicación (fuera del entrenamiento) |  1 375 | 29.5 | 19.2 | 4.3 |

**F2 por temporada:**

| Temporada | Grupo | n | % superación | Mediana PM2.5 | % > 40 |
|---|---|---|---|---|---|
| calida_humeda | b | 6 307 | 12.8 | 15.6 | 1.2 |
| calida_humeda | c | 1 667 | 10.0 | 14.9 | 0.3 |
| calida_humeda | d |    20 | 0.0 | 11.3 | 0.0 |
| calida_humeda | e |   594 | 18.2 | 15.9 | 1.2 |
| seca_calida | b | 3 837 | 36.1 | 21.4 | 6.3 |
| seca_calida | c | 1 037 | 29.0 | 19.2 | 3.4 |
| seca_calida | d |    78 | 28.2 | 16.6 | 2.6 |
| seca_calida | e |   462 | 31.0 | 19.8 | 4.3 |
| seca_fria | b | 4 867 | 38.3 | 21.2 | 10.5 |
| seca_fria | c | 1 488 | 34.8 | 20.7 | 7.9 |
| seca_fria | d |    91 | 45.1 | 22.9 | 9.9 |
| seca_fria | e |   319 | 48.3 | 24.6 | 10.0 |

**F2 por estación (n y % de superación):**

| estacion | n_b | n_c | n_d | n_e | pct_superacion_b | pct_superacion_c | pct_superacion_d | pct_superacion_e |
|---|---|---|---|---|---|---|---|---|
| CE | 1455 |  100 |  3 | NA | 33.7 | 58.0 | 0.0 | — |
| NE | 1145 |  550 |  7 | 413 | 29.3 | 27.8 | 14.3 | 28.1 |
| NE2 |  975 |  240 |  3 | NA | 33.5 | 21.7 | 0.0 | — |
| NO |  650 |  128 |  2 | 147 | 34.8 | 18.8 | 0.0 | 30.6 |
| NO2 |  509 | 1023 |  5 | NA | 9.8 | 22.7 | 0.0 | — |
| NTE |  589 |  925 | 78 | 141 | 18.7 | 16.6 | 55.1 | 43.3 |
| NTE2 | 1689 |    7 |  2 | NA | 23.3 | 14.3 | 0.0 | — |
| SE | 1371 |  148 | 22 | 232 | 15.4 | 28.4 | 45.5 | 24.1 |
| SE2 | 1474 |  206 |  6 | NA | 48.4 | 29.6 | 83.3 | — |
| SE3 | 1237 |  337 |  3 | NA | 16.9 | 27.0 | 0.0 | — |
| SO | 1266 |  277 | 36 | 259 | 46.8 | 33.6 | 0.0 | 47.1 |
| SO2 | 1395 |  169 |  1 | NA | 20.0 | 9.5 | 0.0 | — |
| SUR | 1256 |   82 | 21 | 183 | 9.6 | 9.8 | 19.0 | 2.7 |

**Etapa 3 → etapa 4 (% de superación por estación):**

| estacion | dias_v12 | pct_v12 | dias_v2 | pct_v2 |
|---|---|---|---|---|
| CE |  1461 | 33.9 |  1555 | 35.3 |
| NE |  1141 | 29.4 |  1282 | 29.1 |
| NE2 |  1007 | 31.7 |  1215 | 31.2 |
| NO |   700 | 33.0 |   631 | 32.5 |
| NO2 |   511 | 10.0 |  1532 | 18.4 |
| NTE |   597 | 19.1 |  1373 | 14.8 |
| NTE2 |  1743 | 22.4 |  1696 | 23.2 |
| SE |  1359 | 15.2 |  1287 | 15.3 |
| SE2 |  1488 | 47.8 |  1680 | 46.1 |
| SE3 |  1314 | 15.5 |  1574 | 19.1 |
| SO |  1268 | 46.6 |  1284 | 43.8 |
| SO2 |  1483 | 18.4 |  1564 | 18.9 |
| SUR |  1318 | 9.3 |  1155 | 10.6 |
| Total | 15390 | 26.3 | 17828 | 26.0 |

**F3. Días sin PM2.5 suficiente (a):**

| dias_a | rachas | racha_mediana | racha_maxima | pct_dias_en_rachas_mayores_7 | pct_dias_en_rachas_mayores_30 |
|---|---|---|---|---|---|
| 4346.0 | 1275.0 | 1.0 | 532.0 | 50.2 | 30.8 |

| Estación | Días (a) | % con PM10 | PM10 mediana (a) | PM10 mediana (con respuesta) |
|---|---|---|---|---|
| NO | 1 046 | 88.1 | 36.6 | 50.1 |
| NE2 |   608 | 90.1 | 50.9 | 66.0 |
| SUR |   467 | 93.8 | 42.0 | 43.5 |
| NO2 |   289 | 90.0 | 54.6 | 56.1 |
| SE |   285 | 86.3 | 44.1 | 47.1 |
| CE |   268 | 85.4 | 54.8 | 54.5 |
| SO2 |   261 | 89.3 | 40.4 | 57.4 |
| SE3 |   249 | 83.1 | 34.0 | 59.8 |
| SO |   247 | 83.8 | 39.6 | 59.3 |
| NTE |   234 | 76.5 | 47.4 | 56.2 |
| SE2 |   140 | 56.4 | 62.8 | 58.3 |
| NTE2 |   128 | 85.2 | 45.7 | 61.1 |
| NE |   124 | 68.5 | 46.6 | 54.3 |
| Total | 4 346 | 86.1 | 43.8 | 55.6 |

Dentro de cada estación y temporada, la mediana del PM10 de los días (a) es menor que la de los días con respuesta en 31 de 39 combinaciones (mediana de la diferencia: -6.1 µg/m³).

**Días (a) por año:**

| Año | Días (a) | % |
|---|---|---|
| 2021 |   596 | 12.6 |
| 2022 |   468 | 9.9 |
| 2023 |   725 | 15.3 |
| 2024 | 1 118 | 23.5 |
| 2025 | 1 439 | 30.3 |

## Figuras

`coef_lda_logistica_informe.png`, `linealidad_logit_informe.png`, `metricas_por_corte_informe.png`.
