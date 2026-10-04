# Etapa 2 · Exploración descriptiva de la muestra (sin PCA ni modelos)

Generado por `scripts/06_explorar_etapa2.R` el 2026-10-04, sobre `docs/etapa2/protocolo.md` y la base `datos-v1.2` (con la regla D15). Solo describe la muestra que define el protocolo; el modelado (PCA, discriminante, logística) es la etapa 3.

## 1. Muestra

Universo: 13 estaciones (excluye NE3 y NO3) × 2021–2025 = **23,738 estación-días**. Muestra final (`data/clean/muestra_pm25_2021_2025.csv`): **15,390 estación-días** (64.8 % del universo), con PM2.5 diario válido (≥ 18 h) y los ocho predictores de M1 completos. Superación (PM2.5 > 25 µg/m³): **26.3 %** de la muestra (4,045 días).

## 2. Pérdidas de la muestra

De 23,738 estación-días posibles: 3,820 (16.1 %) pierden por PM2.5 sin 18 h válidas y 5,763 (24.3 %) por faltar al menos un predictor meteorológico; 1,235 pierden por ambos motivos y se cuentan en los dos grupos. De las pérdidas meteorológicas, **1,070 días se retiran por la regla D15** (930 por SR nocturna y 141 por viento contra la red; un día puede caer en ambas). Detalle en `perdidas_muestra.csv` y por estación en `anexo_d15_por_estacion.csv`.

Retención por estación (`retencion_por_estacion.csv`): de 28 % (NO2, 511 días) a 95.5 % (NTE2, 1,743 días). Por temporada (`retencion_por_temporada.csv`): de 63.7 % a 65.6 %.

## 3. Sensibilidad: PM2.5 recalculado solo con horas observadas

Exigiendo ≥ 18 h **observadas** (sin imputar): 429 de los 15,390 días (2.8 %) dejan de ser evaluables (`sensibilidad_imputacion_no_evaluables.csv`). De los 14,961 días comparables, **101 (0.7 %) cambian de clase** en `supera_25` (`sensibilidad_imputacion_cambios_clase.csv`).

## 4. Distribución de las superaciones

PM2.5 diario: media 20.6, mediana 18.2, asimetría 1.97, máximo 165.7 µg/m³, 98 extremos (> Q3 + 3·IQR); `descriptivos_pm25_meteo.csv`.

Por temporada: seca_calida 35.5 % (n=3,892); calida_humeda 12.4 % (n=6,524); seca_fria 37.2 % (n=4,974). Por año: 2021 27.3 %, 2022 25.7 %, 2023 24.7 %, 2024 29.7 %, 2025 24.0 % (rango 24.0–29.7 %). Mayor % por estación × temporada: SO en seca_fria (75 %, n=430); menor: SE en calida_humeda (3 %, n=592).

## 5. Meteorología según superación (SMD)

SMD = (media con superación − media sin superación) / DE combinada. Global (`smd_meteo_global.csv`), dentro de cada temporada (`smd_meteo_temporada.csv`) y como anomalía respecto de la media de su estación × temporada (`smd_meteo_anomalia.csv`):

| variable | global | seca_fria | seca_calida | calida_humeda | anomalía estación × temporada |
|---|---|---|---|---|---|
| PRS (mm Hg) | -0.30 | -0.43 | -0.28 | -0.32 | -0.59 |
| RH (%) | -0.08 | 0.05 | -0.09 | -0.25 | -0.05 |
| SR (kW/m²) | -0.03 | 0.25 | 0.21 | 0.12 | 0.14 |
| TOUT (°C) | -0.04 | 0.41 | 0.84 | 0.23 | 0.50 |
| horas_lluvia (h) | -0.26 | -0.22 | -0.25 | -0.28 | -0.16 |
| rapidez viento (m/s) | -0.55 | -0.75 | -0.39 | -0.29 | -0.35 |
| viento_u (m/s) | 0.32 | 0.29 | 0.18 | 0.10 | 0.18 |
| viento_v (m/s) | -0.08 | -0.00 | 0.04 | 0.01 | 0.08 |

Spearman con PM2.5 (`anexo_matriz_spearman.csv`): máximo |ρ| = 0.27 (viento_rapidez_ms). Días con `horas_lluvia` = 0: **92.2 %**.

Viento diario máximo tras D15: 7.53 m/s en la base diaria completa (SO, 2020-02-26) y 7.25 m/s en la muestra (SO, 2021-03-18).

## 6. Figuras

`output/etapa2/figuras/`: `fig1_pm25_boxplot_estacion.png` (PM2.5 por estación, eje log, líneas en 15 y 25), `fig2_heatmap_superacion_estacion_temporada.png` (% de superación por estación × temporada con n) y `fig3_smd_meteo.png` (SMD en cinco versiones, líneas en ±0.2). Anexos: `anexo_meteo_facetas_superacion.png`, `anexo_matriz_spearman.png` y `anexo_superacion_mensual_por_anio.png`.

## Alcance

Este documento describe la muestra seleccionada (13 estaciones, 2021–2025), no la calidad del aire de toda la ZMM. `supera_25` es una referencia fija de comparación, no una evaluación del cumplimiento normativo (ver `docs/etapa2/protocolo.md`, sección 3).
