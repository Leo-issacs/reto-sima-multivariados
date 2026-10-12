# Etapa 3 · Diagnósticos posteriores del modelo final

Generado por `scripts/07c_diagnostico_errores.R` el 2026-10-11 23:36. **No cambia ningún modelo ni métrica de 07b**: reconstruye M0 y M1 (LDA, entrenamiento 2021–2023, PRS como anomalía de su estación, sin transformaciones, corte 0.258) y describe sus errores en la prueba 2024–2025 (n = 5,220).

## 0. Verificación de la reconstrucción

| Modelo | AUC 07b | AUC 07c | Diferencia |
|---|---|---|---|
| M0 | 0.721804888526 | 0.721804888526 | 0.0e+00 |
| M1 | 0.792061783235 | 0.792061783235 | -1.1e-16 |

El modelo quedó en `output/etapa3/modelo_final.rds` (objetos LDA, escalado, medias de PRS por estación, niveles, corte y predicciones de la prueba).

## 1. Matrices de confusión (prueba)

| Modelo | VP | FN | FP | VN | Sensibilidad | Especificidad | Tasa FN | Tasa FP |
|---|---|---|---|---|---|---|---|---|
| M0 |  821 | 597 | 1029 | 2773 | 0.579 | 0.729 | 0.421 | 0.271 |
| M1 | 1035 | 383 | 1139 | 2663 | 0.730 | 0.700 | 0.270 | 0.300 |

## 2. Errores por temporada y por estación

| Temporada | Modelo | n | % sup. | Sens. | Espec. | Tasa FN | Tasa FP |
|---|---|---|---|---|---|---|---|
| calida_humeda | M0 | 2070 | 10.4 | 0.352 | 0.855 | 0.648 | 0.145 |
| calida_humeda | M1 | 2070 | 10.4 | 0.315 | 0.882 | 0.685 | 0.118 |
| seca_calida | M0 | 1333 | 42.1 | 0.510 | 0.635 | 0.490 | 0.365 |
| seca_calida | M1 | 1333 | 42.1 | 0.745 | 0.592 | 0.255 | 0.408 |
| seca_fria | M0 | 1817 | 35.3 | 0.716 | 0.594 | 0.284 | 0.406 |
| seca_fria | M1 | 1817 | 35.3 | 0.856 | 0.486 | 0.144 | 0.514 |

| Estación | Modelo | n | % sup. | Sens. | Espec. | Tasa FN | Tasa FP |
|---|---|---|---|---|---|---|---|
| CE | M0 | 587 | 31.2 | 0.869 | 0.567 | 0.131 | 0.433 |
| CE | M1 | 587 | 31.2 | 0.820 | 0.592 | 0.180 | 0.408 |
| NE | M0 | 205 | 38.0 | 0.821 | 0.394 | 0.179 | 0.606 |
| NE | M1 | 205 | 38.0 | 0.808 | 0.661 | 0.192 | 0.339 |
| NE2 | M0 | 224 | 37.5 | 0.786 | 0.371 | 0.214 | 0.629 |
| NE2 | M1 | 224 | 37.5 | 0.774 | 0.600 | 0.226 | 0.400 |
| NO | M0 |  63 | 44.4 | 1.000 | 0.343 | 0.000 | 0.657 |
| NO | M1 |  63 | 44.4 | 0.821 | 0.514 | 0.179 | 0.486 |
| NO2 | M0 | 301 | 14.3 | 0.000 | 1.000 | 1.000 | 0.000 |
| NO2 | M1 | 301 | 14.3 | 0.233 | 0.845 | 0.767 | 0.155 |
| NTE | M0 |  16 | 25.0 | 0.500 | 0.833 | 0.500 | 0.167 |
| NTE | M1 |  16 | 25.0 | 0.750 | 0.917 | 0.250 | 0.083 |
| NTE2 | M0 | 694 | 26.4 | 0.399 | 0.705 | 0.601 | 0.295 |
| NTE2 | M1 | 694 | 26.4 | 0.683 | 0.822 | 0.317 | 0.178 |
| SE | M0 | 571 | 16.5 | 0.000 | 1.000 | 1.000 | 0.000 |
| SE | M1 | 571 | 16.5 | 0.606 | 0.839 | 0.394 | 0.161 |
| SE2 | M0 | 620 | 44.2 | 1.000 | 0.000 | 0.000 | 1.000 |
| SE2 | M1 | 620 | 44.2 | 0.964 | 0.208 | 0.036 | 0.792 |
| SE3 | M0 | 467 | 19.5 | 0.000 | 1.000 | 1.000 | 0.000 |
| SE3 | M1 | 467 | 19.5 | 0.637 | 0.676 | 0.363 | 0.324 |
| SO | M0 | 322 | 48.1 | 1.000 | 0.000 | 0.000 | 1.000 |
| SO | M1 | 322 | 48.1 | 0.942 | 0.335 | 0.058 | 0.665 |
| SO2 | M0 | 637 | 22.3 | 0.000 | 1.000 | 1.000 | 0.000 |
| SO2 | M1 | 637 | 22.3 | 0.387 | 0.790 | 0.613 | 0.210 |
| SUR | M0 | 513 | 11.5 | 0.000 | 1.000 | 1.000 | 0.000 |
| SUR | M1 | 513 | 11.5 | 0.271 | 0.916 | 0.729 | 0.084 |

## 3. Errores según la magnitud del PM2.5

| PM2.5 (µg/m³) | n | % clasificado superación M0 | % clasificado superación M1 |
|---|---|---|---|
| [0,15) | 1794 | 22.4 | 18.5 |
| [15,20) | 1151 | 28.5 | 34.1 |
| [20,25] |  857 | 34.9 | 48.4 |
| (25,30] |  533 | 45.2 | 61.9 |
| (30,40] |  583 | 57.1 | 74.6 |
| >40 |  302 | 81.8 | 89.4 |

En [0,15), [15,20) y [20,25] el porcentaje clasificado como superación es la tasa de falsos positivos de ese intervalo; en (25,30], (30,40] y >40 es la sensibilidad.

## 4. Calibración

| Decil | p media M0 | p media M1 | Frecuencia obs. M0 | Frecuencia obs. M1 |
|---|---|---|---|---|
|  1 | 0.049 | 0.019 | 0.056 | 0.021 |
|  2 | 0.059 | 0.039 | 0.061 | 0.075 |
|  3 | 0.100 | 0.066 | 0.165 | 0.096 |
|  4 | 0.154 | 0.106 | 0.308 | 0.138 |
|  5 | 0.189 | 0.161 | 0.132 | 0.224 |
|  6 | 0.217 | 0.232 | 0.326 | 0.222 |
|  7 | 0.259 | 0.316 | 0.261 | 0.276 |
|  8 | 0.354 | 0.430 | 0.341 | 0.421 |
|  9 | 0.490 | 0.595 | 0.437 | 0.521 |
| 10 | 0.691 | 0.806 | 0.630 | 0.722 |

| Modelo | Intercepto | Pendiente |
|---|---|---|
| M0 | -0.125 | 0.760 |
| M1 | -0.205 | 0.763 |

Recalibración: logística de la superación observada sobre logit(p). Intercepto 0 y pendiente 1 indicarían calibración perfecta.

## 5. Importancia por permutación (prueba, 200 permutaciones, semilla 2026)

| Modelo | Variable | Caída media del AUC | P2.5 | P97.5 |
|---|---|---|---|---|
| M1 | temporada | 0.125 | 0.115 | 0.135 |
| M1 | estacion | 0.066 | 0.058 | 0.074 |
| M1 | PRS | 0.058 | 0.051 | 0.065 |
| M1 | TOUT | 0.027 | 0.022 | 0.032 |
| M1 | viento_rapidez_ms | 0.025 | 0.019 | 0.030 |
| M1 | viento | 0.020 | 0.014 | 0.024 |
| M1 | horas_lluvia | 0.004 | 0.002 | 0.006 |
| M1 | viento_v | 0.000 | -0.000 | 0.001 |
| M1 | RH | 0.000 | -0.000 | 0.001 |
| M1 | SR | -0.000 | -0.002 | 0.001 |
| M1 | viento_u | -0.001 | -0.001 | -0.000 |
| M0 | estacion | 0.114 | 0.102 | 0.125 |
| M0 | temporada | 0.100 | 0.091 | 0.110 |

## 6. Supuestos (entrenamiento 2021–2023)

**a) Multicolinealidad** (PRS como anomalía):

| Variable | VIF |
|---|---|
| TOUT | 2.14 |
| RH | 1.33 |
| SR | 1.60 |
| PRS | 1.71 |
| viento_rapidez_ms | 1.90 |
| viento_u | 2.00 |
| viento_v | 1.18 |
| horas_lluvia | 1.06 |

Número de condición de la matriz de correlación: 3.03 (razón de valores propios 9.2).

**b) Dependencia de los residuos de M1 en la prueba** (r = supera_25 − p_M1):

| Rezago | ACF promedio | Mínimo | Máximo |
|---|---|---|---|
|  1 | 0.444 | 0.315 | 0.627 |
|  2 | 0.274 | 0.172 | 0.420 |
|  3 | 0.216 | -0.060 | 0.401 |
|  4 | 0.193 | 0.009 | 0.271 |
|  5 | 0.165 | 0.010 | 0.254 |
|  6 | 0.170 | -0.053 | 0.277 |
|  7 | 0.149 | -0.110 | 0.397 |
|  8 | 0.172 | -0.064 | 0.298 |
|  9 | 0.148 | -0.078 | 0.299 |
| 10 | 0.182 | 0.093 | 0.404 |
| 11 | 0.182 | -0.002 | 0.379 |
| 12 | 0.168 | 0.049 | 0.366 |
| 13 | 0.116 | -0.250 | 0.308 |
| 14 | 0.099 | -0.166 | 0.325 |

Correlación promedio entre pares de estaciones el mismo día: 0.384 (de -0.168 a 0.829; 63 pares). Junto con la autocorrelación, justifica el bootstrap por bloques de fechas que lleva todas las estaciones.

**c) Normalidad multivariada por clase** (Mardia, 8 continuas; calculada en el script, sin el paquete MVN):

| Clase | n | Asimetría (χ²) | gl | p | Curtosis (z) | p  |
|---|---|---|---|---|---|---|
| 0 | 7543 | 85936.0 | 120 | <2e-16 | 297.0 | <2e-16 |
| 1 | 2627 | 206313.2 | 120 | <2e-16 | 1321.3 | <2e-16 |

Con este tamaño de muestra la prueba rechaza; se documenta como limitación de la LDA (la logística de 07b es la robustez).

## 7. Mapa

`figuras/mapa_estaciones.png` (datos en `diagnostico/mapa_estaciones.csv`).

## 8. Cambios de instrumentos (diagnósticos posteriores)

Información del socio formador recibida el 9-oct-2026: en 2021 SIMA renovó los sensores de viento de todas las estaciones y los analizadores de O3, NO2, SO2 y CO (excepto SE2, SO2 y NTE2); en 2025 instaló equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO, completó CO en SE2, SO2 y NTE2 y cambió las bombas de los BAM de PM10. Estos diagnósticos son posteriores a la evaluación de la prueba; el modelo principal no cambia.

**Mes de cambio del viento en 2021** (primer mes de 2021 cuya mediana difiere más de 30 % de la mediana de 2020; descriptivo):

| Estación | Mediana 2020 (m/s) | Mes de cambio | Mediana ese mes |
|---|---|---|---|
| CE | 1.641 | 2021-04 | 2.362 |
| NE | 1.786 | 2021-04 | 2.852 |
| NE2 | 1.548 | 2021-04 | 2.856 |
| NO | 2.022 | 2021-01 | 1.316 |
| NO2 | 2.317 | 2021-01 | 1.524 |
| NTE | 1.010 | 2021-03 | 2.682 |
| NTE2 | 1.997 | 2021-05 | 2.609 |
| SE | 3.307 | 2021-07 | 2.171 |
| SE2 | 1.582 | 2021-03 | 2.115 |
| SE3 | 0.738 | 2021-04 | 2.740 |
| SO | 4.083 | 2021-01 | 2.514 |
| SO2 | 0.410 | 2021-03 | 3.036 |
| SUR | 0.631 | 2021-04 | 2.934 |

**Desempeño por año de la prueba:**

| Análisis | n | Superaciones | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|---|
| Año 2024 | 2894 | 859 | 0.735 | 0.801 | 0.066 | [0.033, 0.097] |
| Año 2025 | 2326 | 559 | 0.699 | 0.777 | 0.078 | [0.045, 0.124] |

**Por grupo de estaciones y año** (5 con PM2.5 nuevo en 2025: SE2, NTE2, SUR, SO2, NO):

| Análisis | n | Superaciones | AUC M0 | AUC M1 | ΔAUC | IC 95 % | Nota |
|---|---|---|---|---|---|---|---|
| otras 8 2024 | 1529 | 441 | 0.756 | 0.814 | 0.058 | [0.025, 0.097] |  |
| 5 con PM2.5 nuevo en 2025 2024 | 1365 | 418 | 0.718 | 0.792 | 0.074 | [0.036, 0.110] |  |
| otras 8 2025 | 1164 | 291 | 0.673 | 0.746 | 0.073 | [0.028, 0.140] |  |
| 5 con PM2.5 nuevo en 2025 2025 | 1162 | 268 | 0.711 | 0.809 | 0.098 | [0.063, 0.143] |  |

**Nivel relativo del PM2.5** (mediana mensual de PM2.5 / mediana de la red): `figuras/pm25_relativo_2024_2025.png`, datos en `diagnostico/pm25_relativo_2024_2025.csv`. Mediana del cociente por estación y año:

| Estación | 2024 | 2025 |
|---|---|---|
| NO | 1.140 | 0.903 |
| NTE2 | 1.061 | 0.995 |
| SE2 | 1.343 | 1.093 |
| SO2 | 0.954 | 1.059 |
| SUR | 0.895 | 0.908 |

**Sensibilidad posterior: entrenar solo desde 2021-04-01** (después de la renovación del viento):

| n entrenamiento | Corte | Análisis | n | Superaciones | AUC M0 | AUC M1 | ΔAUC | IC 95 % |
|---|---|---|---|---|---|---|---|---|
| 10,170 | 0.258 | Principal (entrenamiento 2021-2023) | 5220 | 1418 | 0.722 | 0.792 | 0.070 | [0.047, 0.094] |
|  9,950 | 0.256 | Entrenamiento desde 2021-04-01 | 5220 | 1418 | 0.725 | 0.792 | 0.067 | [0.045, 0.091] |

## 9. Figuras

`figuras/errores_temporada_estacion.png`, `figuras/errores_magnitud_pm25.png`, `figuras/calibracion.png`, `figuras/importancia_permutacion.png`, `figuras/acf_residuos.png`, `figuras/dauc_temporada.png`, `figuras/mapa_estaciones.png`, `figuras/viento_mensual_2020_2025.png`, `figuras/pm25_relativo_2024_2025.png`
