# Base diaria `datos-v2.0` (etapa 4)

**Se reproduce con:** `Rscript scripts/08a_enmascaramiento_horario.R` → `08b_construir_base_v2.R` → `08c_enmascaramiento_diario.R` → `08d_imputar_diario.R` (no necesitan los Excel; 08a los usa solo para una comprobación opcional con `SIMA_DATA_DIR`).
**Decisiones:** D18, D19 y D23 de `docs/etapa4/decisiones_etapa4.md`. Resumen de la fase A: `output/etapa4/imputacion/RESUMEN_FASE_A.md`.
**No reemplaza** a `datos-v1.2` (`data/clean/*.csv`), que sigue reproduciendo la etapa 3.

## Archivo

`diario_v2_2021_2025.csv`: una fila por estación-día de las 13 estaciones de la muestra (sin NE3 ni NO3), 2021–2025 (23 738 filas), con o sin datos.

`diario_v2_imputado_2021_2025.csv` (`scripts/08d_imputar_diario.R`): el mismo archivo con la imputación diaria del método principal (D20, registro de cambios): en los días con 1 a 4 meteorológicas faltantes, cada celda faltante = mediana de las otras estaciones ese día + la diferencia media del sitio (estación × `sitio_valido`) respecto de esa mediana en 2021–2023. Columnas extra: `imp_<variable>` (1 = imputada), `n_met_faltantes_tras_imputar` y `met_completa_tras_imputar`. Es la base del análisis final de la etapa 4.

`muestra_v2_mice_m20.csv.gz`: sensibilidad con MICE (pmm, m = 20, modelos ajustados solo con 2021–2023), en formato largo (`.imp` = número de base; estación, fecha y las 8 meteorológicas) para los días con respuesta válida y ≤ 4 faltantes.

## Qué cambia respecto de `datos-v1.2`

| | `datos-v1.2` (etapa 3) | `datos-v2.0` (etapa 4) |
|---|---|---|
| PM2.5 diario (respuesta) | ≥ 18 h válidas, **incluidas** las imputadas (lineal ≤ 3 h) | ≥ 18 h **observadas**; el PM2.5 no se imputa (D18) |
| Meteorología horaria | Interpolación lineal, huecos ≤ 3 h | Método y `maxgap` por variable, elegidos por enmascaramiento en 2021–2023 (D19; `output/etapa4/imputacion/eleccion_metodo_horario.csv`) |
| Periodo de imputación | Serie continua 2020–2025 | 2021–2023 y 2024–2025 por separado (la prueba no informa la imputación del entrenamiento) |
| Reglas | E, L y M nunca se imputan; todo imputado se revalida (X) | Las mismas, con las mismas funciones (`R/limpieza.R`) |
| Reubicaciones | — | Columna `sitio_valido` (D23) |

El agregado diario es el mismo de la etapa 1 (`agregar_diario()`): media con ≥ 18 h válidas por variable; la rapidez del viento sale de *u* y *v* horarios; `horas_lluvia` no se imputa.

## Columnas

| Columna | Contenido |
|---|---|
| `estacion`, `fecha`, `anio`, `temporada` | Clave y temporada (seca_fria nov–feb, seca_calida mar–may, calida_humeda jun–oct) |
| `PM2.5`, `n_horas_PM2.5` | Media diaria de PM2.5 (µg/m³) con ≥ 18 h **observadas**, y horas observadas |
| `supera_25`, `supera_15` | 1 si PM2.5 > 25 (referencia fija, no evaluación normativa) / > 15 µg/m³; vacío si no hay respuesta válida |
| `TOUT`, `RH`, `SR`, `PRS`, `viento_u`, `viento_v`, `viento_rapidez_ms`, `horas_lluvia`, `llovio` | Meteorología diaria (≥ 18 h válidas, incluidas las imputadas por hora según D19) |
| `n_horas_TOUT` … `n_horas_RAINF` | Horas válidas usadas en cada media diaria (`n_horas_viento` vale para u, v y rapidez) |
| `n_imputadas_TOUT` … `n_imputadas_viento_v` | Horas de ese día imputadas por D19 (tras revalidar) |
| `n_met_faltantes` | Cuántas de las 8 meteorológicas de M1 faltan ese día (0–8) |
| `respuesta_valida` | 1 si hay PM2.5 diario válido |
| `met_completa` | 1 si están las 8 meteorológicas |
| `candidato_mice` | 1 si hay respuesta válida y faltan de 1 a 4 meteorológicas (D20; la imputación es la fase B) |
| `sitio_valido` | 0 en los días previos a la reubicación (PIGECA, p. 91): NO antes del 2021-07-01; SE, SO, NTE y SUR antes del 2021-10-01; NE antes del 2022-03-01. 1 en los demás (D23) |
