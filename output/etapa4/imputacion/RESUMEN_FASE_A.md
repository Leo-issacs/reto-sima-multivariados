# Etapa 4 · Fase A: elección de los métodos de imputación (solo 2021–2023)

Scripts: `scripts/08a_enmascaramiento_horario.R` (D19), `scripts/08b_construir_base_v2.R` (D18, D19, D23) y `scripts/08c_enmascaramiento_diario.R` (D20). Contrato: `docs/etapa4/decisiones_etapa4.md`, con su «Registro de cambios de la fase A (antes de la etiqueta)», que cambia la regla de D19, fija la lectura de D20 y ajusta el plan de la fase B. Semilla 2026 en todo lo aleatorio.

**Estado: cerrada con la etiqueta `etapa4-decisiones-cerradas`.** Nada de esta fase usó 2024–2025 para decidir: 08a y 08c se detienen si encuentran esos años, y 08b solo los cuenta (días por año) e imputa la meteorología de la prueba por separado.

## 1. Garantías de que se partió de la serie correcta

- **La refactorización de `R/limpieza.R` no cambia `datos-v1.2`.**
  - La imputación con revalidación (bandera X) y las reglas por hora salieron de `limpiar_hoja()` a funciones propias: `reglas_hoja()`, `imputar_serie()`, `imputar_y_revalidar()` y `revalidar_imputados()`. Las comparten 03, 08a y 08b.
  - Con los Excel, `03_limpiar.R` corrido en una copia aparte reproduce **byte por byte** los 9 CSV de `data/clean/`. Se comprobó después de cada cambio a `R/limpieza.R`.
  - También pasan `04_validar_limpios.R` y `05_probar_limpieza.R`.
- **Serie previa a imputar.** Se reconstruye de los CSV regresando a NA las horas con bandera I. Con los Excel (`SIMA_DATA_DIR`), 08a comprobó que coincide valor por valor y en las posiciones de los NA con la serie limpia antes de imputar de la etapa 1 (`verificacion_serie_previa.csv`: 0 diferencias). Así 08a y 08b corren sin los Excel y dan lo mismo.
- **La red para revalidar** (medianas por hora de TOUT, RH y WSR) se reconstruye de los CSV. Con el método de la etapa 1, `imputar_y_revalidar()` reproduce lo publicado: na distintos 0; valores distintos 3027 (todos en horas I; diferencia máxima 0.001); banderas I/X distintas 0. La diferencia es solo el último decimal, porque se interpola entre extremos ya redondeados a 3 decimales (`comprobacion_reproduce_v12.csv`).

## 2. A1 · Imputación horaria (D19)

**Enmascaramiento:**
- tramos completos de ≥ 72 h de 2021–2023, en las 13 estaciones;
- bloques de 1, 2, 3, 6, 12 y 24 h (≈ 5 % de las horas de cada tramo);
- 5 semillas (2026–2030): 2,730 series × 7 métodos, sin fallos.

Cada imputación se revalida con las mismas reglas que la base v2, para medir cuánto revierte cada método. Kalman (StructTS) tardó 1 s por serie completa de 2021–2023 y no hizo falta usar ventanas mensuales. La corrida completa tarda unos 21 min con 12 procesos (`tiempos_enmascaramiento_horario.csv`).

**Regla** (registro de cambios, punto 1). Por variable, en este orden:
1. Se descalifica todo método que la revalidación revierte en más de 5 %.
2. El umbral es RMSE del promedio diario ≤ 0.10 × DE diaria de la **anomalía** (la variable menos la media de su estación en el entrenamiento).
3. El `maxgap` se calcula de forma iterativa con el mejor método no descalificado, y gana el método con menor error en los largos ≤ `maxgap`.
4. Si la lineal queda a menos de 5 % del ganador, se usa la lineal.

**Tabla final** (`eleccion_metodo_horario.csv`):

| Variable | Ganador (largos ≤ maxgap) | Método elegido | maxgap (h) | Lineal frente al ganador | Reversión del elegido | Descalificados (> 5 % de reversión) | Umbral (0.10 × DE de la anomalía) | Iteraciones del maxgap |
|---|---|---|---|---|---|---|---|---|
| TOUT | seadec | seadec | 12 | +84.9 % | 0.06 % | — | 0.6123 | 12 |
| RH | kalman | kalman |  6 | +23.1 % | 2.51 % | — | 1.4490 |  6 |
| SR | stine | stine |  2 | +6.8 % | 3.66 % | spline, kalman, seadec | 0.0062 |  2 |
| PRS | seadec | seadec | 12 | +88.6 % | 0.00 % | — | 0.3521 | 12 |
| viento_u | stine | linear |  3 | +0.4 % | 0.00 % | — | 0.1058 |  3 |
| viento_v | linear | linear |  3 | +0.0 % | 0.00 % | — | 0.0998 |  3 |

- No hubo ciclos; el `maxgap` se estabiliza en la primera iteración.
- La lectura «cumple en L y en todos los menores» coincide con «el mayor L que cumple».
- En u y v se eligió la lineal, y la lineal cumple el umbral hasta su `maxgap`.

**% de reversión de cada método** (horas borradas que la revalidación regresaría a NA; en negritas, > 5 %; `reversion_por_metodo.csv`):

| variable | linear | spline | stine | ma_exp | kalman | seadec | locf |
|---|---|---|---|---|---|---|---|
| TOUT | 1.02 | 3.53 | 1.07 | 1.42 | 2.07 | 0.06 | 2.97 |
| RH | 0.86 | 4.23 | 1.00 | 1.21 | 2.51 | 0.23 | 2.32 |
| SR | 4.20 | **29.94** | 3.66 | 2.79 | **44.82** | **25.93** | 2.86 |
| PRS | 0.00 | 0.45 | 0.00 | 0.00 | 0.00 | 0.00 | 0.01 |
| viento_u | 0.00 | 0.53 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| viento_v | 0.00 | 0.54 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| PM2.5 | 0.61 | **6.03** | 0.68 | 0.75 | 0.60 | 0.68 | 1.11 |

En SR se descalifican spline, Kalman y `seadec`. En `seadec` se verificó la causa en la base real: casi todas sus reversiones son SR negativos de madrugada, porque suma un ciclo diario que baja de cero. En spline y Kalman no se revisó la causa. PM2.5 es solo diagnóstico.

**Horas imputadas, v1.2 frente a v2** (13 estaciones, 2021–2025; `imputacion_horaria_v12_v2.csv`):

| Variable | Método v2 | Horas faltantes antes de imputar | Imputadas v1.2 | Imputadas v2 | Revertidas (X) v1.2 | Revertidas (X) v2 |
|---|---|---|---|---|---|---|
| TOUT | seadec, ≤ 12 h | 36,067 | 3,149 | 5,800 | 0 | 5 |
| RH | kalman, ≤ 6 h | 57,672 | 3,345 | 4,398 | 4 | 191 |
| SR | stine, ≤ 2 h | 49,887 | 1,711 | 1,473 | 0 | 6 |
| PRS | seadec, ≤ 12 h | 20,941 | 4,742 | 7,629 | 54 | 54 |
| viento_u | linear, ≤ 3 h | 38,200 | 4,793 | 4,790 | 0 | 0 |
| viento_v | linear, ≤ 3 h | 38,200 | 4,793 | 4,790 | 0 | 0 |

- En RH, la revalidación revirtió en la base real el 4.2 % de las imputaciones de Kalman (191 de 4,589), más que el 2.5 % del enmascaramiento pero bajo el 5 %.
- SR imputa menos horas que en v1.2 porque su `maxgap` baja de 3 a 2 h.

**Mejor método por largo de hueco** (RMSE del promedio diario; entre paréntesis el del mejor, luego el de la lineal y el de `seadec`; incluye los métodos descalificados):

| variable | 1 h | 2 h | 3 h | 6 h | 12 h | 24 h |
|---|---|---|---|---|---|---|
| TOUT | kalman (0.0211); lin 0.0236; seadec 0.0256 | kalman (0.0444); lin 0.0531; seadec 0.0509 | kalman (0.0782); lin 0.0972; seadec 0.0839 | seadec (0.206); lin 0.315; seadec 0.206 | seadec (0.521); lin 1.15; seadec 0.521 | seadec (1.04); lin 2.39; seadec 1.04 |
| RH | kalman (0.107); lin 0.114; seadec 0.13 | kalman (0.223); lin 0.248; seadec 0.255 | kalman (0.376); lin 0.432; seadec 0.41 | seadec (0.956); lin 1.28; seadec 0.956 | seadec (2.33); lin 4.47; seadec 2.33 | seadec (4.36); lin 9.21; seadec 4.36 |
| SR | kalman (0.00221); lin 0.0023; seadec 0.00302 | kalman (0.00408); lin 0.00453; seadec 0.00495 | kalman (0.00649); lin 0.00778; seadec 0.0069 | seadec (0.014); lin 0.0249; seadec 0.014 | seadec (0.0276); lin 0.0682; seadec 0.0276 | seadec (0.0422); lin 0.122; seadec 0.0422 |
| PRS | kalman (0.00661); lin 0.00798; seadec 0.00783 | kalman (0.0133); lin 0.0189; seadec 0.015 | kalman (0.0239); lin 0.0372; seadec 0.0245 | seadec (0.0616); lin 0.135; seadec 0.0616 | seadec (0.168); lin 0.324; seadec 0.168 | seadec (0.453); lin 0.627; seadec 0.453 |
| viento_u | stine (0.031); lin 0.0311; seadec 0.034 | stine (0.0562); lin 0.0565; seadec 0.0597 | stine (0.0824); lin 0.0826; seadec 0.085 | seadec (0.165); lin 0.176; seadec 0.165 | seadec (0.328); lin 0.417; seadec 0.328 | seadec (0.543); lin 0.781; seadec 0.543 |
| viento_v | stine (0.0325); lin 0.0325; seadec 0.0356 | stine (0.0564); lin 0.0565; seadec 0.0602 | kalman (0.0839); lin 0.0839; seadec 0.0869 | seadec (0.166); lin 0.171; seadec 0.166 | seadec (0.306); lin 0.365; seadec 0.306 | seadec (0.502); lin 0.667; seadec 0.502 |

**Diagnóstico de picos de PM2.5** (solo diagnóstico; el PM2.5 no se imputa, D18). Error en el máximo horario de cada bloque borrado (negativo = el método aplana el pico):

| Método | Largo (h) | Bloques | Error medio en el máximo del bloque (µg/m³) | % de bloques con máximo subestimado | Sesgo horario (µg/m³) | RMSE del promedio diario |
|---|---|---|---|---|---|---|
| linear |  1 | 38,615 | 0.02 | 45.4 | 0.02 | 0.24 |
| linear |  2 | 19,307 | -0.86 | 53.9 | -0.04 | 0.44 |
| linear |  3 | 12,865 | -1.55 | 58.9 | -0.05 | 0.65 |
| linear |  6 | 6,445 | -3.55 | 68.7 | -0.04 | 1.37 |
| linear | 12 | 3,313 | -7.80 | 78.4 | -0.35 | 2.77 |
| linear | 24 | 1,584 | -13.47 | 89.3 | -0.13 | 5.19 |
| seadec |  1 | 38,615 | 0.07 | 47.6 | 0.07 | 0.27 |
| seadec |  2 | 19,307 | -0.55 | 52.8 | 0.02 | 0.47 |
| seadec |  3 | 12,865 | -1.06 | 56.0 | 0.01 | 0.68 |
| seadec |  6 | 6,445 | -2.51 | 63.0 | 0.04 | 1.36 |
| seadec | 12 | 3,313 | -5.67 | 71.2 | -0.31 | 2.64 |
| seadec | 24 | 1,584 | -9.26 | 78.2 | -0.07 | 4.77 |

La interpolación sí aplana los picos, y más mientras más largo es el hueco: en 2–3 h subestima el máximo en 0.9–1.6 µg/m³ en promedio, y en más de la mitad de los bloques. Aun así, el promedio diario casi no se mueve (RMSE de 0.24–0.65 µg/m³ en 1–3 h; sesgo horario ≈ 0). Esto respalda D18: el efecto sobre el promedio diario es pequeño, pero no imputar la respuesta lo elimina.

## 3. A2 · Base `datos-v2.0` (D18, D19, D23)

**Archivo:** `data/clean/v2/diario_v2_2021_2025.csv` (23,738 estación-días; columnas en `data/clean/v2/README.md`).
- PM2.5 solo con horas observadas.
- Meteorología con los métodos de la sección 2, imputada por separado en 2021–2023 y en 2024–2025 y revalidada con las mismas reglas.
- `sitio_valido` según D23.

**Pérdidas, `datos-v1.2` frente a v2** (`perdidas_v12_v2.csv`; «tras MICE» se refiere a los días que entran a la imputación diaria, sea cual sea el método):

| Requisito | v1.2 | % v1.2 | v2 | % v2 | Diferencia |
|---|---|---|---|---|---|
| Universo (13 estaciones x 2021-2025) | 23,738 | 100.0 | 23,738 | 100.0 | 0 |
| Con respuesta válida (PM2.5 diario con >= 18 h; v1.2 cuenta horas imputadas, v2 solo observadas) | 19,918 | 83.9 | 19,392 | 81.7 | -526 |
| Pierde por PM2.5 | 3,820 | 16.1 | 4,346 | 18.3 | 526 |
| Respuesta válida y las 8 meteorológicas completas (casos completos) | 15,390 | 64.8 | 15,011 | 63.2 | -379 |
| Respuesta válida y 1 a 4 meteorológicas faltantes (candidatos a MICE) | 4,330 | 18.2 | 4,192 | 17.7 | -138 |
| Respuesta válida y 5 a 8 faltantes (no se imputan) | 198 | 0.8 | 189 | 0.8 | -9 |
| Disponibles tras MICE (casos completos + 1 a 4 faltantes) | 19,720 | 83.1 | 19,203 | 80.9 | -517 |
|   de ellos en entrenamiento (2021-2023) | 12,560 | 52.9 | 12,340 | 52.0 | -220 |
|     previos a la reubicación (sitio_valido = 0; D23, se quitan del entrenamiento) | 1,380 | 5.8 | 1,375 | 5.8 | -5 |
|     entrenamiento final (sitio_valido = 1) | 11,180 | 47.1 | 10,965 | 46.2 | -215 |
|   de ellos en prueba (2024-2025) | 7,160 | 30.2 | 6,863 | 28.9 | -297 |

Los días previos a la reubicación en la muestra de la etapa 3 son **1,012**, la cifra de D23.

**Faltantes por variable entre los candidatos a la imputación diaria** (respuesta válida y 1–4 faltantes; un día puede faltar en varias; `faltantes_por_variable_candidatos_mice.csv`). 08c imita el patrón de 2021–2023:

| Variable | 2021–2023 | 2024–2025 | 2021–2025 |
|---|---|---|---|
| PRS | 78 (3.4 %) | 62 (3.3 %) | 140 (3.3 %) |
| RH | 456 (19.7 %) | 974 (51.9 %) | 1,430 (34.1 %) |
| SR | 1,128 (48.7 %) | 606 (32.3 %) | 1,734 (41.4 %) |
| TOUT | 121 (5.2 %) | 493 (26.3 %) | 614 (14.6 %) |
| horas_lluvia | 82 (3.5 %) | 7 (0.4 %) | 89 (2.1 %) |
| viento_rapidez_ms | 764 (33.0 %) | 17 (0.9 %) | 781 (18.6 %) |
| viento_u | 764 (33.0 %) | 17 (0.9 %) | 781 (18.6 %) |
| viento_v | 764 (33.0 %) | 17 (0.9 %) | 781 (18.6 %) |

## 4. A3 · Imputación diaria (D20)

**Enmascaramiento:**
- base: los 11,175 días de 2021–2023 con las 8 meteorológicas completas;
- se borró la misma fracción de días que tiene faltantes entre los de respuesta válida (18.8 %, 2,097 días);
- a cada día se le asignó un **patrón real** de 2021–2023 (qué variables faltan juntas), sorteado con su frecuencia (`patrones_faltantes_2021_2023.csv`);
- la mediana de la red de cada día excluye a la propia estación.

| Variable | Celdas borradas | % de los días completos | Correlación con la mediana de la red (cruda) | Dentro de la estación |
|---|---|---|---|---|
| TOUT | 111 | 0.99 | 0.994 | 0.998 |
| RH | 382 | 3.42 | 0.954 | 0.973 |
| SR | 1,014 | 9.07 | 0.658 | 0.852 |
| PRS | 56 | 0.50 | 0.286 | 0.911 |
| viento_u | 731 | 6.54 | 0.702 | 0.782 |
| viento_v | 731 | 6.54 | 0.300 | 0.377 |
| viento_rapidez_ms | 731 | 6.54 | 0.709 | 0.822 |
| horas_lluvia | 75 | 0.67 | 0.056 | 0.067 |

**Regla** (registro de cambios, punto 2): gana el método con menor RMSE relativo (RMSE / DE de la variable) promediado en las 8 variables. Para MICE cuenta el error de **cada base imputada**.

| Regla | Método elegido | RMSE rel. medio: mediana ajustada | MICE (cada base) | Media est. × temp. | Variables donde gana MICE |
|---|---|---|---|---|---|
| error de cada base imputada (MICE por imputacion) | red_ajustada | 0.450 | 0.593 | 0.736 | 0 |

**RMSE relativo por variable** (`enmascaramiento_diario_rmse_relativo.csv`). La penúltima columna compara la mediana ajustada con el mejor de los otros dos métodos (negativo = la mediana ajustada tiene menos error):

| Variable | Mediana de la red ajustada | MICE (cada base) | Media estación × temporada | Mediana ajustada frente al mejor de los otros dos | MICE, promedio de las 5 (solo referencia) |
|---|---|---|---|---|---|
| TOUT | 0.071 | 0.093 | 0.590 | -23.6 % | 0.072 |
| RH | 0.229 | 0.298 | 1.017 | -23.1 % | 0.236 |
| SR | 0.426 | 0.535 | 0.724 | -20.4 % | 0.414 |
| PRS | 0.168 | 0.257 | 0.340 | -34.7 % | 0.192 |
| viento_u | 0.570 | 0.775 | 0.796 | -26.5 % | 0.596 |
| viento_v | 0.817 | 1.127 | 0.808 | +1.0 % | 0.861 |
| viento_rapidez_ms | 0.490 | 0.671 | 0.792 | -26.9 % | 0.509 |
| horas_lluvia | 0.829 | 0.990 | 0.820 | +1.1 % | 0.607 |
| **Promedio (criterio de D20)** | **0.450** | 0.593 | 0.736 |  | 0.436 |

- **La mediana de la red ajustada gana con claridad en TOUT (−23.6 %) y en RH (−23.1 %)**, las dos variables que más faltan en 2024–2025.
- Gana también en SR, PRS, viento_u y la rapidez del viento.
- En viento_v y `horas_lluvia` empata con la media estación × temporada (+1.0 % y +1.1 %); en ambas, MICE tiene más error.
- **Método principal de imputación diaria: mediana de la red ajustada, una sola imputación.** MICE (pmm, m = 20) queda como sensibilidad de la fase B.

RMSE en unidades de cada variable (`enmascaramiento_diario.csv`; MAE en el mismo archivo):

| Variable | Celdas borradas | DE | Mediana de la red ajustada | MICE (cada base) | Media estación × temporada |
|---|---|---|---|---|---|
| TOUT | 111 |  6.2200 | 0.4400 | 0.5760 |  3.6700 |
| RH | 382 | 14.9000 | 3.4100 | 4.4400 | 15.1000 |
| SR | 1,014 |  0.0744 | 0.0317 | 0.0398 |  0.0539 |
| PRS | 56 |  8.3400 | 1.4000 | 2.1500 |  2.8300 |
| viento_u | 731 |  1.1400 | 0.6530 | 0.8880 |  0.9110 |
| viento_v | 731 |  1.1200 | 0.9180 | 1.2700 |  0.9080 |
| viento_rapidez_ms | 731 |  0.8430 | 0.4140 | 0.5660 |  0.6680 |
| horas_lluvia | 75 |  1.2000 | 0.9980 | 1.1900 |  0.9870 |

**Ajuste técnico de MICE.** Con el valor por defecto (`maxcor = 0.99`), mice quita en cada iteración la mediana de la red de TOUT como predictor de TOUT, porque su correlación con TOUT es 0.994. Ese es justo el predictor que pide D20. Se usa `maxcor = 0.9999` (0 eventos registrados).

## 5. Días de la base v2 por estación y año

Cada celda: muestra de la etapa 3 (`datos-v1.2`) → **análisis final v2**:
- respuesta sin imputar;
- meteorología con D19;
- imputación diaria de los días con 1–4 faltantes;
- en el entrenamiento, solo `sitio_valido` = 1.

Detalle: `dias_por_estacion_anio_v12_v2.csv`.

| estacion | 2021 | 2022 | 2023 | 2024 | 2025 | Total | v2 casos completos | v2 con imputación diaria (todos los años) |
|---|---|---|---|---|---|---|---|---|
| CE | 238 → 329 | 322 → 323 | 314 → 311 | 290 → 293 | 297 → 299 | 1,461 → 1,555 | 1,455 | 1,555 |
| NE | 271 → 0 | 343 → 293 | 322 → 332 | 183 → 331 | 22 → 326 | 1,141 → 1,282 | 1,145 | 1,695 |
| NE2 | 230 → 328 | 247 → 347 | 306 → 322 | 211 → 205 | 13 → 13 | 1,007 → 1,215 | 975 | 1,215 |
| NO | 192 → 163 | 278 → 268 | 167 → 149 | 51 → 39 | 12 → 12 | 700 → 631 | 650 | 778 |
| NO2 | 99 → 345 | 2 → 333 | 109 → 316 | 120 → 243 | 181 → 295 | 511 → 1,532 | 509 | 1,532 |
| NTE | 196 → 78 | 257 → 306 | 128 → 327 | 16 → 355 | 0 → 307 | 597 → 1,373 | 589 | 1,514 |
| NTE2 | 351 → 344 | 356 → 355 | 342 → 327 | 348 → 333 | 346 → 337 | 1,743 → 1,696 | 1,689 | 1,696 |
| SE | 154 → 89 | 350 → 347 | 284 → 282 | 267 → 267 | 304 → 302 | 1,359 → 1,287 | 1,371 | 1,519 |
| SE2 | 219 → 306 | 321 → 321 | 328 → 348 | 355 → 353 | 265 → 352 | 1,488 → 1,680 | 1,474 | 1,680 |
| SE3 | 239 → 308 | 349 → 350 | 259 → 339 | 190 → 329 | 277 → 248 | 1,314 → 1,574 | 1,237 | 1,574 |
| SO | 289 → 86 | 337 → 337 | 320 → 340 | 252 → 288 | 70 → 233 | 1,268 → 1,284 | 1,266 | 1,543 |
| SO2 | 169 → 301 | 331 → 358 | 346 → 339 | 343 → 323 | 294 → 243 | 1,483 → 1,564 | 1,395 | 1,564 |
| SUR | 216 → 52 | 309 → 280 | 280 → 286 | 268 → 280 | 245 → 257 | 1,318 → 1,155 | 1,256 | 1,338 |
| **Total** | 2,863 → 2,729 | 3,802 → 4,218 | 3,505 → 4,018 | 2,894 → 3,639 | 2,326 → 3,224 | 15,390 → 17,828 | 15,011 | 19,203 |

- **Total:** 15,390 → 17,828 (+2,438).
- **2021 baja (−134)** porque D23 quita los días previos a la reubicación: NE todo 2021; SO, SUR, SE y NTE hasta septiembre; NO hasta junio.
- **Más recuperación:** NO2 (511 → 1,532), donde casi siempre faltaba la radiación, y NTE (597 → 1,373).
- **Pierden días:** NO, SE, SUR y NTE2, por D23 y porque el PM2.5 sin imputar deja algunos días por debajo de 18 h.

## 6. Observaciones (no cambian las decisiones)

1. **SR imputa menos horas que en v1.2** (1,473 contra 1,711). Con la DE de la anomalía el umbral es más estricto y el `maxgap` de SR baja a 2 h. La lineal de SR tiene 4.2 % de reversión: no se descalifica, pero queda cerca del límite.
2. **`horas_lluvia` es muy ruidosa en el enmascaramiento diario** (75 celdas). Al cambiar la base v2 cambiaron los días borrados, y su RMSE relativo pasó de 2.07 a 0.83 para la mediana ajustada. Por eso no conviene leer diferencias pequeñas en esa variable.
3. **La otra lectura de D20 cambió de signo, aunque ya no aplica.** Con el error del promedio de las 5 imputaciones de MICE, que ya no es la regla y se muestra solo como referencia, MICE quedaría por delante (0.436 contra 0.450). La lectura fijada es la de cada base imputada.
4. **El patrón de faltantes de la prueba es distinto al del entrenamiento.** En 2021–2023 faltan sobre todo SR y viento; en 2024–2025, RH y TOUT. La validación imita 2021–2023, pero en RH y TOUT la mediana ajustada gana con claridad, así que la elección se sostiene.
5. **La correlación de la presión con la red es menor que la que cita D20.** Dentro de cada estación, la de los promedios diarios es 0.91 (D20 dice 0.96–0.99); la cruda es 0.29, por la altitud. No cambia el procedimiento.

## 7. Decisiones de implementación (no estaban escritas en D19–D20)

- **Bloques de enmascaramiento.**
  - El número de bloques por tramo es 5 % × horas / largo, con redondeo aleatorio, para que en promedio se borre el 5 % también en tramos cortos con bloques de 24 h.
  - Los bloques no tocan los bordes del tramo y quedan separados por ≥ 1 hora observada.
- **Métodos en el enmascaramiento.**
  - Cada método imputa la serie completa 2021–2023 de la estación, pero solo se evalúa en las horas borradas.
  - `na_ma` se calcula en ventanas de ±48 h alrededor de los bloques. Es exactamente equivalente (se comprueba en el script) y mucho más rápido.
- **Reversión.** Los imputados se ponen en la matriz completa de la estación, con las demás variables observadas, y se revalidan con `revalidar_imputados()`. El % se mide sobre todas las horas borradas de todos los largos. El error se mide sobre los valores antes de revalidar.
- **Error diario.** Se mide en cada día que contiene horas borradas, con las mismas horas observadas, y exige ≥ 18 h.
- **«Cumple hasta L»** significa en L y en todos los largos menores. La DE de la anomalía sale de la muestra de entrenamiento de la etapa 3 (2021–2023, n = 10,170).
- **Imputación horaria de v2 por periodo.** Se hace por separado en 2021–2023 y 2024–2025, para que la prueba no informe la imputación del entrenamiento. La revalidación usa la red de las 15 estaciones, igual que la etapa 1.
- **Imputación diaria.**
  - La «red» son las 13 estaciones de la muestra, y la mediana de cada día excluye a la propia estación.
  - Las tres técnicas se ajustan con los mismos datos: los días completos ya enmascarados.
  - MICE usa `maxit` = 5 (valor por defecto) y `maxcor` = 0.9999.
- **Criterio de D20.** Cada variable pesa igual en el promedio. «Gana o empata» en la tabla por variable = la mediana ajustada queda a menos de 5 % del mejor de los otros dos.

## 8. Archivos

- `output/etapa4/imputacion/`:
  - A1: `enmascaramiento_horario.csv` (incluye la reversión por largo), `enmascaramiento_horario_por_estacion.csv`, `eleccion_metodo_horario.csv`, `reversion_por_metodo.csv`, `rmse_por_metodo_y_hueco.png`, `rmse_horario_por_metodo_y_hueco.png`, `tramos_completos_2021_2023.csv`, `tiempos_enmascaramiento_horario.csv` y `verificacion_serie_previa.csv`.
  - A2: `comprobacion_reproduce_v12.csv`, `perdidas_v12_v2.csv`, `imputacion_horaria_v12_v2.csv`, `faltantes_por_variable_candidatos_mice.csv`, `patrones_faltantes_2021_2023.csv` y `dias_por_estacion_anio_v12_v2.csv`.
  - A3: `enmascaramiento_diario.csv`, `enmascaramiento_diario_rmse_relativo.csv`, `enmascaramiento_diario_por_imputacion.csv`, `enmascaramiento_diario_mascara.csv`, `enmascaramiento_diario_ganador_por_variable.csv` y `eleccion_metodo_diario.csv`.
- `data/clean/v2/`: `diario_v2_2021_2025.csv` y `README.md`.
- **Código:**
  - `R/imputacion.R`: lectura de la serie sin imputar, la red y la comprobación con los Excel.
  - `R/limpieza.R` (refactorizado, sin cambio de resultados).
  - `renv.lock`: agrega `mice` 3.19.0 y sus dependencias.
