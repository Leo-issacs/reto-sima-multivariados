# Etapa 4 · Evaluación única de la prueba (2024–2025) con la base v2

Generado por `scripts/09a_evaluar_prueba_v2.R` el 2026-10-17 23:33. Decisiones cerradas en la etiqueta `etapa4-decisiones-cerradas` (commit `8a56cc4`); código al correr: `7ac7011`. Mismo procedimiento que la etapa 3 (07b): LDA con prior y corte = prevalencia de entrenamiento, PRS como anomalía de su estación con medias de entrenamiento, sin transformaciones; bootstrap pareado por bloques de 14 días (1000 réplicas, semilla 2026) con predicciones fijas.

## 1. Tabla puente

Cada paso cambia una sola cosa respecto del anterior.

| Paso | Cambio | n entrenamiento | n prueba | % superación (prueba) | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|---|---|
| 0 | datos-v1.2 (etapa 3) | 10,170 | 5,220 | 27.2 | 0.722 | 0.792 | 0.070 [0.047, 0.094] |
| 1 | + respuesta solo con horas observadas (D18) |  9,983 | 4,978 | 28.3 | 0.716 | 0.790 | 0.074 [0.051, 0.098] |
| 2 | + imputación horaria D19 (casos completos v2) | 10,024 | 4,987 | 28.4 | 0.717 | 0.790 | 0.074 [0.050, 0.098] |
| 3 | + imputación diaria con mediana de la red ajustada (D20) | 12,340 | 6,863 | 26.2 | 0.709 | 0.791 | 0.081 [0.055, 0.109] |
| 4 | + entrenamiento sin días previos a la reubicación (D23) = análisis final | 10,965 | 6,863 | 26.2 | 0.713 | 0.792 | 0.079 [0.054, 0.104] |

El paso 0 reproduce exactamente la etapa 3 (comprobado contra `output/etapa3/prueba_sensibilidades.csv`).

## 2. Análisis final (paso 4)

Entrenamiento 2021–2023 (n = 10,965, solo `sitio_valido` = 1; prevalencia 0.259 = corte), prueba 2024–2025 (n = 6,863, 26.2 % de superación).

| Métrica | M0 | M1 | M1 − M0 | IC 95 % |
|---|---|---|---|---|
| AUC | 0.713 | 0.792 | 0.079 | [0.054, 0.104] |
| Exactitud balanceada | 0.634 | 0.711 | 0.077 | [0.051, 0.100] |
| Sensibilidad | 0.565 | 0.742 | 0.177 | — |
| Especificidad | 0.703 | 0.680 | -0.023 | — |
| Brier | 0.172 | 0.154 | -0.018 | — |

**ΔAUC por temporada** (descriptivo):

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

## 3. Robustez y sensibilidades

Todas con el entrenamiento del análisis final (D23); la de MICE promedia 20 bases y combina 20 × 200 réplicas.

| Análisis | n entrenamiento | n prueba | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| Análisis final: LDA, bloques de 14 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.104] |
| Robustez: logística | 10,965 | 6,863 | 0.721 | 0.792 | 0.071 [0.047, 0.095] |
| Bloques de 7 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.103] |
| Bloques de 28 días | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.045, 0.110] |
| MICE (pmm, m = 20; 4000 réplicas combinadas) | 10,965 | 6,863 | 0.713 | 0.791 | 0.078 [0.055, 0.103] |
| Límite de ≤ 2 faltantes | 10,408 | 6,801 | 0.713 | 0.789 | 0.077 [0.052, 0.102] |
| Respuesta con PM2.5 interpolado ≤ 3 h | 11,180 | 7,160 | 0.714 | 0.793 | 0.079 [0.053, 0.105] |
| Casos completos v2 sin imputación diaria |  8,995 | 4,987 | 0.720 | 0.791 | 0.071 [0.047, 0.096] |

## 4. Días y superación por estación (v1.2 frente a v2)

v1.2 = muestra de la etapa 3 (2021–2025); v2 = análisis final (entrenamiento con D23 + prueba).

| Estación | Días v1.2 | Días v2 | Diferencia | % superación v1.2 | % superación v2 | % superación v2 (prueba) |
|---|---|---|---|---|---|---|
| CE |  1,461 |  1,555 |    94 | 33.9 | 35.3 | 30.9 |
| NE |  1,141 |  1,282 |   141 | 29.4 | 29.1 | 30.7 |
| NE2 |  1,007 |  1,215 |   208 | 31.7 | 31.2 | 37.2 |
| NO |    700 |    631 |   -69 | 33.0 | 32.5 | 49.0 |
| NO2 |    511 |  1,532 | 1,021 | 10.0 | 18.4 | 11.2 |
| NTE |    597 |  1,373 |   776 | 19.1 | 14.8 | 16.6 |
| NTE2 |  1,743 |  1,696 |   -47 | 22.4 | 23.2 | 27.3 |
| SE |  1,359 |  1,287 |   -72 | 15.2 | 15.3 | 16.5 |
| SE2 |  1,488 |  1,680 |   192 | 47.8 | 46.1 | 42.8 |
| SE3 |  1,314 |  1,574 |   260 | 15.5 | 19.1 | 25.1 |
| SO |  1,268 |  1,284 |    16 | 46.6 | 43.8 | 39.3 |
| SO2 |  1,483 |  1,564 |    81 | 18.4 | 18.9 | 26.5 |
| SUR |  1,318 |  1,155 |  -163 | 9.3 | 10.6 | 11.0 |
| Total | 15,390 | 17,828 | 2,438 | 26.3 | 26.0 | 26.2 |

## 5. Figuras

`figuras/tabla_puente.png`, `figuras/roc_m0_m1_prueba_v2.png`, `figuras/dauc_temporada_v2.png`, `figuras/bootstrap_dauc_v2.png`.
