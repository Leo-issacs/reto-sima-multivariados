# Etapa 3 · Evaluación de la prueba (2024–2025)

Generado por `scripts/07b_evaluar_prueba.R` el 2026-10-04 18:48. Decisiones cerradas en el commit `eb1946e` (fase A); código al correr: `033ccf3`. Entrenamiento 2021–2023 (n = 10,170), prueba 2024–2025 (n = 5,220, 27.2 % de superación). LDA con prior = prevalencia de entrenamiento (0.258), corte en esa misma prevalencia; PRS como anomalía de su estación (D17); sin transformaciones (D16). Bootstrap pareado por bloques de 14 días (53 bloques, 1000 réplicas, semilla 2026), con predicciones fijas.

## 1. Resultado principal (LDA)

| Métrica | M0 | M1 | M1 − M0 | IC 95 % |
|---|---|---|---|---|
| AUC | 0.722 | 0.792 | 0.070 | [0.047, 0.094] |
| Exactitud balanceada | 0.654 | 0.715 | 0.061 | [0.033, 0.086] |
| Sensibilidad | 0.579 | 0.730 | 0.151 | — |
| Especificidad | 0.729 | 0.700 | -0.029 | — |
| Brier | 0.175 | 0.156 | -0.019 | — |

ΔAUC = 0.070 (IC 95 % [0.047, 0.094]). Un AUC no es un porcentaje de aciertos ni implica probabilidades calibradas; el Brier sí mide calibración.

## 2. ΔAUC por temporada (descriptivo)

| Temporada | n | % superación | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|---|
| calida_humeda | 2070 | 10.4 | 0.668 | 0.691 | 0.023 | [-0.028, 0.076] |
| seca_calida | 1333 | 42.1 | 0.601 | 0.738 | 0.137 | [0.102, 0.179] |
| seca_fria | 1817 | 35.3 | 0.710 | 0.766 | 0.056 | [0.027, 0.088] |

## 3. Robustez y sensibilidades

Cada fila reajusta los modelos con entrenamiento y evalúa la prueba una vez; los IC son por bootstrap de bloques (14 días salvo que se indique).

| Análisis | n | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|
| Principal: LDA, bloques de 14 dias | 5220 | 0.722 | 0.792 | 0.070 | [0.047, 0.094] |
| Robustez: logistica | 5220 | 0.734 | 0.794 | 0.060 | [0.039, 0.082] |
| a) bloques de 7 dias | 5220 | 0.722 | 0.792 | 0.070 | [0.047, 0.093] |
| a) bloques de 28 dias | 5220 | 0.722 | 0.792 | 0.070 | [0.041, 0.100] |
| b) umbral 15 ug/m3 | 5220 | 0.681 | 0.774 | 0.093 | [0.069, 0.118] |
| c) PM2.5 solo con horas observadas | 4978 | 0.716 | 0.790 | 0.074 | [0.051, 0.098] |
| d) M1 con PC1-PC3 | 5220 | 0.722 | 0.786 | 0.064 | [0.039, 0.090] |
| e) interaccion estacion x temporada | 5220 | 0.741 | 0.797 | 0.056 | [0.036, 0.076] |
| f) log de la rapidez del viento | 5220 | 0.722 | 0.795 | 0.074 | [0.048, 0.099] |
| g) solo M0 en la muestra con solo PM2.5 valido | 7250 | 0.706 | — | — | — |

g) M0 en la muestra con solo PM2.5 válido: entrenamiento n = 12,668, prueba n = 7,250; AUC 0.706 (IC 95 % [0.669, 0.741]) frente a 0.722 de M0 en la muestra principal.

## 4. Interpretación de M1

Coeficientes estandarizados (divididos entre el máximo absoluto) y correlaciones de estructura; se interpretan en conjunto. Los 10 de mayor magnitud:

| Predictor | Coef. estandarizado | Corr. de estructura |
|---|---|---|
| temseca_fria | 1.000 | 0.375 |
| viento_rapidez_ms | -0.597 | -0.519 |
| PRS | -0.593 | -0.361 |
| temseca_calida | 0.535 | 0.164 |
| estSUR | -0.465 | -0.235 |
| TOUT | 0.436 | -0.062 |
| estSE3 | -0.382 | -0.169 |
| estNTE2 | -0.337 | -0.093 |
| estSE | -0.275 | -0.151 |
| estSO2 | -0.238 | -0.140 |

PCA (anomalía por estación, entrenamiento): valores propios 2.92, 1.36, 1.04, 0.97; k = 3 por Kaiser. Cargas en `pca_cargas_anomalia.csv`.

## 5. Figuras

`figuras/roc_m0_m1_prueba.png`, `figuras/bootstrap_dauc.png`, `figuras/coeficientes_m1.png`, `figuras/pca_cargas.png`.
