# Etapa 2 · Exploración descriptiva de la muestra (sin PCA ni modelos)

Generado por `scripts/06_explorar_etapa2.R` el 2026-10-04, sobre `docs/etapa2/protocolo.md` (v2). Solo describe la muestra que define el protocolo; el modelado (PCA, discriminante, logística) es la etapa 3.

## 1. Muestra

Universo: 13 estaciones (excluye NE3 y NO3) × 2021–2025 = **23,738 estación-días**. Muestra final (`data/clean/muestra_pm25_2021_2025.csv`): **16,461 estación-días** (69.3 % del universo), con PM2.5 diario válido (≥ 18 h) y los ocho predictores de M1 completos (TOUT, RH, SR, PRS, viento_u, viento_v, viento_rapidez_ms, horas_lluvia). Superación (PM2.5 > 25 µg/m³): **26.6 %** de la muestra.

## 2. Pérdidas de la muestra

De 23,738 estación-días posibles: 3,820 (16.1 %) pierden por PM2.5 sin 18 h válidas y 4,638 (19.5 %) por faltar al menos un predictor meteorológico (1,181 de ellos pierden por ambos motivos a la vez). Detalle en `output/etapa2/perdidas_muestra.csv`.

Retención por estación (`output/etapa2/retencion_por_estacion.csv`): de 32.7 % (NTE) a 95.5 % (NTE2). Por temporada (`..._por_temporada.csv`): de 67.9 % a 71.4 %.

## 3. Sensibilidad: PM2.5 recalculado solo con horas observadas

Exigiendo ≥ 18 h **observadas** (sin imputar) para el PM2.5 diario: 443 de los 16,461 días de la muestra (2.7 %) dejan de ser evaluables por cobertura insuficiente (`sensibilidad_imputacion_no_evaluables.csv`). De los 16,018 días que siguen siendo comparables, **103 (0.6 %) cambian de clase** en `supera_25` (`sensibilidad_imputacion_cambios_clase.csv`); resumen en `sensibilidad_imputacion_resumen.csv`.

## 4. Descriptivos y SMD

`output/etapa2/descriptivos_pm25_meteo.csv`: n, media, DE, mediana, Q1, Q3, mínimo, máximo, asimetría y extremos (> Q3 + 3·IQR) de PM2.5 y de los ocho predictores de M1. PM2.5: media 20.639, mediana 18.25, asimetría 1.922, 102 extremos.

SMD global entre días con y sin superación (`smd_meteo_global.csv`; por temporada en `smd_meteo_temporada.csv`): mayor en viento_rapidez_ms (SMD = -0.41), menor en SR (SMD = -0.04).

## 5. Figuras

`output/etapa2/figuras/`: Fig. 1 PM2.5 diario por estación (boxplot, eje log, líneas en 15 y 25); Fig. 2 heatmap de % de superación por estación × temporada; Fig. 3 meteorología según superación (facetas). Anexos: matriz de Spearman y % mensual de superación por año.

Mayor % de superación: SO en seca_fria (75 %, n=441). Menor: SE en calida_humeda (3 %, n=592).

## Alcance

Este documento describe la muestra seleccionada (13 estaciones, 2021–2025), no la calidad del aire de toda la ZMM. `supera_25` es una referencia fija de comparación, no una evaluación del cumplimiento normativo (ver `docs/etapa2/protocolo.md`, sección 3).
