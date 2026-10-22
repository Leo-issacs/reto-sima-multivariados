# ENSAYO (entrena 2021–2022, «prueba» 2023): no es la evaluación oficial

Generado por `scripts/09a_evaluar_prueba_v2.R` el 2026-10-17 23:30. Decisiones cerradas en la etiqueta `etapa4-decisiones-cerradas` (commit `8a56cc4`); código al correr: `8a56cc4`. Mismo procedimiento que la etapa 3 (07b): LDA con prior y corte = prevalencia de entrenamiento, PRS como anomalía de su estación con medias de entrenamiento, sin transformaciones; bootstrap pareado por bloques de 14 días (1000 réplicas, semilla 2026) con predicciones fijas.

## 1. Tabla puente

Cada paso cambia una sola cosa respecto del anterior.

| Paso | Cambio | n entrenamiento | n prueba | % superación (prueba) | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|---|---|
| 0 | datos-v1.2 (etapa 3) | 6,665 | 3,505 | 24.7 | 0.749 | 0.829 | 0.080 [0.043, 0.120] |
| 1 | + respuesta solo con horas observadas (D18) | 6,578 | 3,405 | 25.8 | 0.744 | 0.825 | 0.082 [0.043, 0.122] |
| 2 | + imputación horaria D19 (casos completos v2) | 6,610 | 3,414 | 25.7 | 0.744 | 0.825 | 0.082 [0.044, 0.123] |
| 3 | + imputación diaria con mediana de la red ajustada (D20) | 8,322 | 4,018 | 24.9 | 0.727 | 0.815 | 0.088 [0.046, 0.133] |
| 4 | + entrenamiento sin días previos a la reubicación (D23) = análisis final | 6,947 | 4,018 | 24.9 | 0.733 | 0.816 | 0.083 [0.044, 0.125] |



## 2. Análisis final (paso 4)

Entrenamiento 2021–2022 (n = 6,947, solo `sitio_valido` = 1; prevalencia 0.265 = corte), prueba 2023–2023 (n = 4,018, 24.9 % de superación).

| Métrica | M0 | M1 | M1 − M0 | IC 95 % |
|---|---|---|---|---|
| AUC | 0.733 | 0.816 | 0.083 | [0.044, 0.125] |
| Exactitud balanceada | 0.673 | 0.726 | 0.052 | [0.024, 0.080] |
| Sensibilidad | 0.677 | 0.808 | 0.131 | — |
| Especificidad | 0.670 | 0.644 | -0.026 | — |
| Brier | 0.161 | 0.143 | -0.017 | — |

**ΔAUC por temporada** (descriptivo):

| Temporada | n | % superación | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| calida_humeda | 1,641 | 13.3 | 0.630 | 0.771 | 0.141 [0.020, 0.198] |
| seca_calida | 1,006 | 29.9 | 0.694 | 0.807 | 0.113 [0.077, 0.140] |
| seca_fria | 1,371 | 35.0 | 0.735 | 0.800 | 0.065 [0.021, 0.108] |

**ΔAUC por año de la prueba:**

| Año | n | % superación | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| 2023 | 4,018 | 24.9 | 0.733 | 0.816 | 0.083 [0.044, 0.125] |

## 3. Robustez y sensibilidades

Todas con el entrenamiento del análisis final (D23); la de MICE promedia 20 bases y combina 20 × 200 réplicas.

| Análisis | n entrenamiento | n prueba | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| Análisis final: LDA, bloques de 14 días | 6,947 | 4,018 | 0.733 | 0.816 | 0.083 [0.044, 0.125] |
| Robustez: logística | 6,947 | 4,018 | 0.735 | 0.817 | 0.081 [0.041, 0.126] |
| Bloques de 7 días | 6,947 | 4,018 | 0.733 | 0.816 | 0.083 [0.045, 0.126] |
| Bloques de 28 días | 6,947 | 4,018 | 0.733 | 0.816 | 0.083 [0.044, 0.127] |
| MICE (pmm, m = 20; 4000 réplicas combinadas) | 6,947 | 4,018 | 0.733 | 0.816 | 0.083 [0.045, 0.124] |
| Límite de ≤ 2 faltantes | 6,454 | 3,954 | 0.736 | 0.818 | 0.082 [0.043, 0.126] |
| Respuesta con PM2.5 interpolado ≤ 3 h | 7,049 | 4,131 | 0.734 | 0.819 | 0.084 [0.045, 0.126] |
| Casos completos v2 sin imputación diaria | 5,581 | 3,414 | 0.746 | 0.826 | 0.080 [0.045, 0.119] |

## 4. Días y superación por estación (v1.2 frente a v2)

v1.2 = muestra de la etapa 3 (2021–2025); v2 = análisis final (entrenamiento con D23 + prueba).

| Estación | Días v1.2 | Días v2 | Diferencia | % superación v1.2 | % superación v2 | % superación v2 (prueba) |
|---|---|---|---|---|---|---|
| CE |    874 |    963 |   89 | 35.7 | 38.0 | 38.6 |
| NE |    936 |    625 | -311 | 27.6 | 27.4 | 22.9 |
| NE2 |    783 |    997 |  214 | 30.0 | 29.9 | 33.2 |
| NO |    637 |    580 |  -57 | 31.9 | 31.0 | 39.6 |
| NO2 |    210 |    994 |  784 | 3.8 | 22.3 | 17.7 |
| NTE |    581 |    711 |  130 | 18.9 | 13.1 | 9.2 |
| NTE2 |  1,049 |  1,026 |  -23 | 19.7 | 20.6 | 22.9 |
| SE |    788 |    718 |  -70 | 14.2 | 14.3 | 12.4 |
| SE2 |    868 |    975 |  107 | 50.5 | 48.5 | 46.3 |
| SE3 |    847 |    997 |  150 | 13.3 | 15.5 | 14.7 |
| SO |    946 |    763 | -183 | 46.1 | 46.9 | 45.0 |
| SO2 |    846 |    998 |  152 | 15.5 | 14.5 | 14.2 |
| SUR |    805 |    618 | -187 | 8.0 | 10.4 | 10.1 |
| Total | 10,170 | 10,965 |  795 | 25.8 | 25.9 | 24.9 |

## 5. Figuras

`figuras/tabla_puente.png`, `figuras/roc_m0_m1_prueba_v2.png`, `figuras/dauc_temporada_v2.png`, `figuras/bootstrap_dauc_v2.png`.
