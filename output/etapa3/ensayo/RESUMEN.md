# ENSAYO (entrena 2021–2022, «prueba» 2023): no es la evaluación oficial

Generado por `scripts/07b_evaluar_prueba.R` el 2026-10-04 18:46. Decisiones cerradas en el commit `eb1946e` (fase A); código al correr: `eb1946e`. Entrenamiento 2021–2022 (n = 6,665), prueba 2023–2023 (n = 3,505, 24.7 % de superación). LDA con prior = prevalencia de entrenamiento (0.264), corte en esa misma prevalencia; PRS como anomalía de su estación (D17); sin transformaciones (D16). Bootstrap pareado por bloques de 14 días (27 bloques, 1000 réplicas, semilla 2026), con predicciones fijas.

## 1. Resultado principal (LDA)

| Métrica | M0 | M1 | M1 − M0 | IC 95 % |
|---|---|---|---|---|
| AUC | 0.749 | 0.829 | 0.080 | [0.043, 0.120] |
| Exactitud balanceada | 0.689 | 0.734 | 0.045 | [0.017, 0.074] |
| Sensibilidad | 0.694 | 0.812 | 0.118 | — |
| Especificidad | 0.684 | 0.657 | -0.027 | — |
| Brier | 0.157 | 0.140 | -0.017 | — |

ΔAUC = 0.080 (IC 95 % [0.043, 0.120]). Un AUC no es un porcentaje de aciertos ni implica probabilidades calibradas; el Brier sí mide calibración.

## 2. ΔAUC por temporada (descriptivo)

| Temporada | n | % superación | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|---|
| calida_humeda | 1489 | 12.2 | 0.656 | 0.776 | 0.120 | [0.027, 0.173] |
| seca_calida |  861 | 31.2 | 0.682 | 0.801 | 0.119 | [0.075, 0.149] |
| seca_fria | 1155 | 35.9 | 0.742 | 0.818 | 0.076 | [0.029, 0.123] |

## 3. Robustez y sensibilidades

Cada fila reajusta los modelos con entrenamiento y evalúa la prueba una vez; los IC son por bootstrap de bloques (14 días salvo que se indique).

| Análisis | n | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|
| Principal: LDA, bloques de 14 dias | 3505 | 0.749 | 0.829 | 0.080 | [0.043, 0.120] |
| Robustez: logistica | 3505 | 0.752 | 0.828 | 0.076 | [0.035, 0.121] |
| a) bloques de 7 dias | 3505 | 0.749 | 0.829 | 0.080 | [0.045, 0.120] |
| a) bloques de 28 dias | 3505 | 0.749 | 0.829 | 0.080 | [0.041, 0.124] |
| b) umbral 15 ug/m3 | 3505 | 0.717 | 0.823 | 0.107 | [0.072, 0.148] |
| c) PM2.5 solo con horas observadas | 3405 | 0.744 | 0.825 | 0.082 | [0.043, 0.122] |
| d) M1 con PC1-PC3 | 3505 | 0.749 | 0.819 | 0.070 | [0.034, 0.109] |
| e) interaccion estacion x temporada | 3505 | 0.752 | 0.835 | 0.083 | [0.046, 0.125] |
| f) log de la rapidez del viento | 3505 | 0.749 | 0.836 | 0.087 | [0.050, 0.127] |
| g) solo M0 en la muestra con solo PM2.5 valido | 4133 | 0.724 | — | — | — |

g) M0 en la muestra con solo PM2.5 válido: entrenamiento n = 8,535, prueba n = 4,133; AUC 0.724 (IC 95 % [0.654, 0.788]) frente a 0.749 de M0 en la muestra principal.

## 4. Interpretación de M1

Coeficientes estandarizados (divididos entre el máximo absoluto) y correlaciones de estructura; se interpretan en conjunto. Los 10 de mayor magnitud:

| Predictor | Coef. estandarizado | Corr. de estructura |
|---|---|---|
| temseca_fria | 1.000 | 0.382 |
| PRS | -0.615 | -0.360 |
| viento_rapidez_ms | -0.516 | -0.454 |
| temseca_calida | 0.506 | 0.158 |
| estSUR | -0.459 | -0.249 |
| TOUT | 0.455 | -0.040 |
| estSE3 | -0.376 | -0.183 |
| estNTE2 | -0.330 | -0.115 |
| estSO | 0.288 | 0.303 |
| estNTE | -0.262 | -0.041 |

PCA (anomalía por estación, entrenamiento): valores propios 2.93, 1.40, 1.05, 0.98; k = 3 por Kaiser. Cargas en `pca_cargas_anomalia.csv`.

## 5. Figuras

`figuras/roc_m0_m1_prueba.png`, `figuras/bootstrap_dauc.png`, `figuras/coeficientes_m1.png`, `figuras/pca_cargas.png`.
