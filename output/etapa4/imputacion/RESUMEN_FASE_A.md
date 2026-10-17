# Etapa 4 · Fase A: elección de los métodos de imputación (solo 2021–2023)

Scripts: `scripts/08a_enmascaramiento_horario.R` (D19), `scripts/08b_construir_base_v2.R` (D18, D19, D23) y `scripts/08c_enmascaramiento_diario.R` (D20). Contrato: `docs/etapa4/decisiones_etapa4.md`. Semilla 2026 en todo lo aleatorio.

**Estado: la fase A está completa salvo una decisión.** La regla de D20 (imputación diaria) da resultados distintos según cómo se lea «si MICE no gana» (sección 4). Por eso **no se creó todavía la etiqueta `etapa4-decisiones-cerradas`**: se crea cuando el equipo fije esa lectura. Nada de esta fase usó 2024–2025 para decidir: 08a y 08c se detienen si encuentran esos años, y 08b solo los cuenta (días por año) e imputa la meteorología de la prueba por separado.

## 1. Garantías de que se partió de la serie correcta

- **La refactorización de `R/limpieza.R` no cambia `datos-v1.2`.** Las reglas por hora y la imputación con revalidación (bandera X) pasaron de estar dentro de `limpiar_hoja()` a funciones propias (`reglas_hoja()`, `imputar_serie()`, `imputar_y_revalidar()`), que ahora comparten 03 y 08b. Con los Excel, `03_limpiar.R` corrido en una copia aparte reproduce **byte por byte** los 9 CSV de `data/clean/`; también pasan `04_validar_limpios.R` y las pruebas de `05_probar_limpieza.R`.
- **Serie previa a imputar.** Se reconstruye de los CSV regresando a NA las horas con bandera I. Con los Excel (`SIMA_DATA_DIR`), 08a comprobó que coincide valor por valor y en las posiciones de los NA con la serie limpia antes de imputar de la etapa 1 (`verificacion_serie_previa.csv`: 0 diferencias). Así 08a y 08b corren sin los Excel y dan lo mismo.
- **La red para revalidar** (medianas por hora de TOUT, RH y WSR) se reconstruye de los CSV. Con el método de la etapa 1, `imputar_y_revalidar()` reproduce lo publicado: na distintos 0; valores distintos 3027 (todos en horas I; diferencia máxima 0.001); banderas I/X distintas 0. La única diferencia es el último decimal, porque se interpola entre extremos ya redondeados a 3 decimales (`comprobacion_reproduce_v12.csv`).

## 2. A1 · Imputación horaria (D19)

Enmascaramiento en tramos completos de ≥ 72 h de 2021–2023, 13 estaciones, bloques de 1, 2, 3, 6, 12 y 24 h (≈ 5 % de las horas de cada tramo), 5 semillas (2026–2030): 2,730 series × 7 métodos, sin fallos. Kalman (StructTS) tardó 1.0 s por serie completa de 2021–2023 y no hizo falta usar ventanas mensuales (`tiempos_enmascaramiento_horario.csv`). Detalle: `enmascaramiento_horario.csv` (por variable × método × largo), `_por_estacion.csv` y la figura `rmse_por_metodo_y_hueco.png`.

**Métodos ganadores y `maxgap` (regla de D19 aplicada tal cual):**

| Variable | Menor RMSE diario medio | RMSE diario medio (ganador) | RMSE diario medio (lineal) | Lineal sobre ganador | Método elegido | Umbral (0.10 × DE diaria) | maxgap (h) | RMSE diario en maxgap | Siguiente largo: RMSE |
|---|---|---|---|---|---|---|---|---|---|
| TOUT | seadec | 0.3218 | 0.6712 | 108.6 % | seadec | 0.6157 | 12 | 0.5209 | 24 h: 1.0438 |
| RH | seadec | 1.4063 | 2.6247 | 86.6 % | seadec | 1.4781 |  6 | 0.9560 | 12 h: 2.3277 |
| SR | seadec | 0.0164 | 0.0382 | 132.8 % | seadec | 0.0074 |  3 | 0.0069 | 6 h: 0.0140 |
| PRS | seadec | 0.1217 | 0.1916 | 57.4 % | seadec | 0.8457 | 24 | 0.4530 | — |
| viento_u | seadec | 0.2025 | 0.2575 | 27.1 % | seadec | 0.1149 |  3 | 0.0850 | 6 h: 0.1653 |
| viento_v | seadec | 0.1929 | 0.2295 | 19.0 % | seadec | 0.1129 |  3 | 0.0869 | 6 h: 0.1664 |

La descomposición estacional (`na_seadec`, ciclo de 24 h) gana en las seis variables y la lineal queda lejos (19 % a 133 % más error). Pero **la ventaja viene de los huecos largos**. En huecos de 1–3 h el mejor método es Kalman o Stineman, y, en promedio sobre 1–3 h, `seadec` tiene más error que la lineal en u (+5.0 %), v (+5.7 %) y SR (+1.7 %) (sección 6, punto 1). Mejor método por largo de hueco (RMSE del promedio diario; entre paréntesis el del mejor, después el de la lineal y el de `seadec`):

| variable | 1 h | 2 h | 3 h | 6 h | 12 h | 24 h |
|---|---|---|---|---|---|---|
| TOUT | kalman (0.0211); lin 0.0236; seadec 0.0256 | kalman (0.0444); lin 0.0531; seadec 0.0509 | kalman (0.0782); lin 0.0972; seadec 0.0839 | seadec (0.206); lin 0.315; seadec 0.206 | seadec (0.521); lin 1.15; seadec 0.521 | seadec (1.04); lin 2.39; seadec 1.04 |
| RH | kalman (0.107); lin 0.114; seadec 0.13 | kalman (0.223); lin 0.248; seadec 0.255 | kalman (0.376); lin 0.432; seadec 0.41 | seadec (0.956); lin 1.28; seadec 0.956 | seadec (2.33); lin 4.47; seadec 2.33 | seadec (4.36); lin 9.21; seadec 4.36 |
| SR | kalman (0.00221); lin 0.0023; seadec 0.00302 | kalman (0.00408); lin 0.00453; seadec 0.00495 | kalman (0.00649); lin 0.00778; seadec 0.0069 | seadec (0.014); lin 0.0249; seadec 0.014 | seadec (0.0276); lin 0.0682; seadec 0.0276 | seadec (0.0422); lin 0.122; seadec 0.0422 |
| PRS | kalman (0.00661); lin 0.00798; seadec 0.00783 | kalman (0.0133); lin 0.0189; seadec 0.015 | kalman (0.0239); lin 0.0372; seadec 0.0245 | seadec (0.0616); lin 0.135; seadec 0.0616 | seadec (0.168); lin 0.324; seadec 0.168 | seadec (0.453); lin 0.627; seadec 0.453 |
| viento_u | stine (0.031); lin 0.0311; seadec 0.034 | stine (0.0562); lin 0.0565; seadec 0.0597 | stine (0.0824); lin 0.0826; seadec 0.085 | seadec (0.165); lin 0.176; seadec 0.165 | seadec (0.328); lin 0.417; seadec 0.328 | seadec (0.543); lin 0.781; seadec 0.543 |
| viento_v | stine (0.0325); lin 0.0325; seadec 0.0356 | stine (0.0564); lin 0.0565; seadec 0.0602 | kalman (0.0839); lin 0.0839; seadec 0.0869 | seadec (0.166); lin 0.171; seadec 0.166 | seadec (0.306); lin 0.365; seadec 0.306 | seadec (0.502); lin 0.667; seadec 0.502 |

**Diagnóstico de picos de PM2.5** (solo diagnóstico; el PM2.5 ya no se imputa, D18). Error en el máximo horario de cada bloque borrado (negativo = el método aplana el pico):

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

La interpolación sí aplana los picos, y más mientras más largo es el hueco: en 2–3 h subestima el máximo en 0.9–1.6 µg/m³ en promedio, y en más de la mitad de los bloques. Aun así, el promedio diario casi no se mueve (RMSE de 0.24–0.65 µg/m³ en 1–3 h; sesgo horario ≈ 0). Esto confirma la crítica del curso y respalda D18: el efecto sobre el promedio diario es pequeño, pero no imputar la respuesta lo elimina. `seadec` aplana algo menos en huecos largos (−9.3 frente a −13.5 µg/m³ en 24 h).

## 3. A2 · Base `datos-v2.0` (D18, D19, D23)

`data/clean/v2/diario_v2_2021_2025.csv` (23,738 estación-días; columnas en `data/clean/v2/README.md`). PM2.5 solo con horas observadas; meteorología con los métodos de la sección 2, imputada por separado en 2021–2023 y en 2024–2025 y revalidada con las mismas reglas; `sitio_valido` según D23.

**Pérdidas, `datos-v1.2` frente a v2** (`perdidas_v12_v2.csv`):

| Requisito | v1.2 | % v1.2 | v2 | % v2 | Diferencia |
|---|---|---|---|---|---|
| Universo (13 estaciones x 2021-2025) | 23,738 | 100.0 | 23,738 | 100.0 | 0 |
| Con respuesta válida (PM2.5 diario con >= 18 h; v1.2 cuenta horas imputadas, v2 solo observadas) | 19,918 | 83.9 | 19,392 | 81.7 | -526 |
| Pierde por PM2.5 | 3,820 | 16.1 | 4,346 | 18.3 | 526 |
| Respuesta válida y las 8 meteorológicas completas (casos completos) | 15,390 | 64.8 | 15,022 | 63.3 | -368 |
| Respuesta válida y 1 a 4 meteorológicas faltantes (candidatos a MICE) | 4,330 | 18.2 | 4,183 | 17.6 | -147 |
| Respuesta válida y 5 a 8 faltantes (no se imputan) | 198 | 0.8 | 187 | 0.8 | -11 |
| Disponibles tras MICE (casos completos + 1 a 4 faltantes) | 19,720 | 83.1 | 19,205 | 80.9 | -515 |
|   de ellos en entrenamiento (2021-2023) | 12,560 | 52.9 | 12,342 | 52.0 | -218 |
|     previos a la reubicación (sitio_valido = 0; D23, se quitan del entrenamiento) | 1,380 | 5.8 | 1,376 | 5.8 | -4 |
|     entrenamiento final (sitio_valido = 1) | 11,180 | 47.1 | 10,966 | 46.2 | -214 |
|   de ellos en prueba (2024-2025) | 7,160 | 30.2 | 6,863 | 28.9 | -297 |

Los días previos a la reubicación en la muestra de la etapa 3 son **1,012**, la cifra de D23.

**Horas imputadas** (13 estaciones, 2021–2025; `imputacion_horaria_v12_v2.csv`):

| Variable | Método v2 | Horas faltantes antes de imputar | Imputadas v1.2 | Imputadas v2 | Revertidas (X) v1.2 | Revertidas (X) v2 |
|---|---|---|---|---|---|---|
| TOUT | seadec, ≤ 12 h | 36,067 | 3,149 | 5,800 | 0 | 5 |
| RH | seadec, ≤ 6 h | 57,672 | 3,345 | 4,470 | 4 | 119 |
| SR | seadec, ≤ 3 h | 49,887 | 1,711 | 1,169 | 0 | 541 |
| PRS | seadec, ≤ 24 h | 20,941 | 4,742 | 10,283 | 54 | 54 |
| viento_u | seadec, ≤ 3 h | 38,200 | 4,793 | 4,790 | 0 | 0 |
| viento_v | seadec, ≤ 3 h | 38,200 | 4,793 | 4,790 | 0 | 0 |

**Faltantes por variable entre los candidatos a MICE** (respuesta válida y 1–4 faltantes; un día puede faltar en varias; `faltantes_por_variable_candidatos_mice.csv`). 08c imita el patrón de 2021–2023:

| Variable | 2021–2023 | 2024–2025 | 2021–2025 |
|---|---|---|---|
| PRS | 70 (3.0 %) | 46 (2.5 %) | 116 (2.8 %) |
| RH | 458 (19.8 %) | 974 (52.1 %) | 1,432 (34.2 %) |
| SR | 1,129 (48.8 %) | 606 (32.4 %) | 1,735 (41.5 %) |
| TOUT | 122 (5.3 %) | 493 (26.4 %) | 615 (14.7 %) |
| horas_lluvia | 82 (3.5 %) | 7 (0.4 %) | 89 (2.1 %) |
| viento_rapidez_ms | 766 (33.1 %) | 17 (0.9 %) | 783 (18.7 %) |
| viento_u | 766 (33.1 %) | 17 (0.9 %) | 783 (18.7 %) |
| viento_v | 766 (33.1 %) | 17 (0.9 %) | 783 (18.7 %) |

## 4. A3 · Imputación diaria (D20)

En los 11,181 días de 2021–2023 con las 8 meteorológicas completas se borró la misma fracción de días que tiene faltantes entre los de respuesta válida (18.7 %, 2,095 días). A cada día se le asignó un **patrón real** de 2021–2023 (qué variables faltan juntas), sorteado con su frecuencia (`patrones_faltantes_2021_2023.csv`). La mediana de la red de cada día excluye a la propia estación.

| Variable | Celdas borradas | % de los días completos | Correlación con la mediana de la red (cruda) | Dentro de la estación |
|---|---|---|---|---|
| TOUT | 110 | 0.98 | 0.994 | 0.997 |
| RH | 387 | 3.46 | 0.955 | 0.973 |
| SR | 1,015 | 9.08 | 0.657 | 0.852 |
| PRS | 46 | 0.41 | 0.287 | 0.911 |
| viento_u | 736 | 6.58 | 0.698 | 0.779 |
| viento_v | 736 | 6.58 | 0.293 | 0.370 |
| viento_rapidez_ms | 736 | 6.58 | 0.711 | 0.823 |
| horas_lluvia | 75 | 0.67 | 0.047 | 0.059 |

**RMSE en las celdas borradas** (`enmascaramiento_diario.csv`; MAE en el mismo archivo):

| Variable | Celdas borradas | DE | MICE, cada base | MICE, promedio de las 5 | Mediana de la red ajustada | Media estación × temporada |
|---|---|---|---|---|---|---|
| TOUT | 110 |  6.2200 | 0.5910 | 0.4600 | 0.4390 |  4.3700 |
| RH | 387 | 14.9000 | 4.6000 | 3.6100 | 3.5700 | 14.4000 |
| SR | 1,015 |  0.0745 | 0.0406 | 0.0304 | 0.0319 |  0.0516 |
| PRS | 46 |  8.3500 | 1.8100 | 1.4000 | 1.2600 |  2.7300 |
| viento_u | 736 |  1.1400 | 0.8950 | 0.7110 | 0.6750 |  0.9740 |
| viento_v | 736 |  1.1200 | 1.2700 | 0.9780 | 0.9370 |  1.0100 |
| viento_rapidez_ms | 736 |  0.8430 | 0.5970 | 0.4680 | 0.4340 |  0.6740 |
| horas_lluvia | 75 |  1.2000 | 2.2000 | 2.0200 | 2.4900 |  2.4900 |

**Corrección necesaria en MICE.** En la primera corrida, mice quitó en todas las iteraciones la mediana de la red de TOUT como predictor de TOUT (25 eventos en `loggedEvents`). Su protección contra colinealidad (`remove.lindep`, `maxcor = 0.99`) descarta todo predictor con correlación > 0.99 con la variable que imputa, y TOUT correlaciona 0.994 con su mediana de la red. Con eso el RMSE de TOUT era 3.67 °C. Se subió `maxcor` a 0.9999 para que mice use los predictores que pide D20 (0 eventos; RMSE 0.59 °C). Está documentado en el bloque 4 de 08c.

**Regla de D20: el resultado depende de la lectura.** RMSE relativo (RMSE / DE de la variable) promediado en las 8 variables:

| Lectura | Gana | MICE | Red ajustada | Media est. × temp. | Variables donde gana MICE |
|---|---|---|---|---|---|
| MICE por imputacion | red_ajustada | 0.702 | 0.612 | 0.914 | 1 |
| MICE promedio de las m | mice | 0.578 | 0.612 | 0.914 | 2 |

| Método | RMSE relativo medio (8 variables) | Sin horas_lluvia (7) |
|---|---|---|
| media_estacion_temporada | 0.914 | 0.749 |
| mice_por_imputacion | 0.702 | 0.541 |
| mice_promedio_m | 0.578 | 0.420 |
| red_ajustada | 0.612 | 0.404 |

- Con el **error de cada base imputada** (lo que ve cada modelo que se ajustaría), gana la **mediana de la red ajustada**.
- Con el **error del promedio de las 5 imputaciones**, gana **MICE**. Pero toda la ventaja viene de `horas_lluvia`: solo 75 celdas borradas, con un RMSE de MICE que varía de 1.47 a 2.77 entre imputaciones. Sin esa variable, la mediana ajustada gana con las dos lecturas (0.404 frente a 0.420).
- La mediana ajustada tiene menor RMSE que MICE (promedio de las 5) en 6 de las 8 variables. MICE gana en SR (0.0304 frente a 0.0319) y en `horas_lluvia`.

`eleccion_metodo_diario.csv` lo marca como **«pendiente: las dos lecturas no coinciden»**. El equipo debe decidir la lectura antes de la fase B (sección 6, punto 4).

## 5. Días de la base v2 por estación y año

Cada celda: muestra de la etapa 3 (`datos-v1.2`) → **análisis final v2** (respuesta sin imputar, meteorología con D19, imputación diaria de los días con 1–4 faltantes y, en el entrenamiento, solo `sitio_valido` = 1). El número de días no depende de cuál método diario se elija: cualquiera imputa los mismos días candidatos. Detalle: `dias_por_estacion_anio_v12_v2.csv`.

| estacion | 2021 | 2022 | 2023 | 2024 | 2025 | Total | v2 casos completos | v2 con imputación diaria (todos los años) |
|---|---|---|---|---|---|---|---|---|
| CE | 238 → 329 | 322 → 323 | 314 → 311 | 290 → 293 | 297 → 299 | 1,461 → 1,555 | 1,455 | 1,555 |
| NE | 271 → 0 | 343 → 293 | 322 → 332 | 183 → 331 | 22 → 326 | 1,141 → 1,282 | 1,147 | 1,695 |
| NE2 | 230 → 328 | 247 → 347 | 306 → 322 | 211 → 205 | 13 → 13 | 1,007 → 1,215 | 976 | 1,215 |
| NO | 192 → 163 | 278 → 269 | 167 → 149 | 51 → 39 | 12 → 12 | 700 → 632 | 650 | 779 |
| NO2 | 99 → 345 | 2 → 333 | 109 → 316 | 120 → 243 | 181 → 295 | 511 → 1,532 | 512 | 1,532 |
| NTE | 196 → 78 | 257 → 306 | 128 → 327 | 16 → 355 | 0 → 307 | 597 → 1,373 | 589 | 1,514 |
| NTE2 | 351 → 344 | 356 → 355 | 342 → 327 | 348 → 333 | 346 → 337 | 1,743 → 1,696 | 1,689 | 1,696 |
| SE | 154 → 89 | 350 → 347 | 284 → 282 | 267 → 267 | 304 → 302 | 1,359 → 1,287 | 1,372 | 1,520 |
| SE2 | 219 → 306 | 321 → 321 | 328 → 348 | 355 → 353 | 265 → 352 | 1,488 → 1,680 | 1,474 | 1,680 |
| SE3 | 239 → 308 | 349 → 350 | 259 → 339 | 190 → 329 | 277 → 248 | 1,314 → 1,574 | 1,237 | 1,574 |
| SO | 289 → 86 | 337 → 337 | 320 → 340 | 252 → 288 | 70 → 233 | 1,268 → 1,284 | 1,270 | 1,543 |
| SO2 | 169 → 301 | 331 → 358 | 346 → 339 | 343 → 323 | 294 → 243 | 1,483 → 1,564 | 1,395 | 1,564 |
| SUR | 216 → 52 | 309 → 280 | 280 → 286 | 268 → 280 | 245 → 257 | 1,318 → 1,155 | 1,256 | 1,338 |
| **Total** | 2,863 → 2,729 | 3,802 → 4,219 | 3,505 → 4,018 | 2,894 → 3,639 | 2,326 → 3,224 | 15,390 → 17,829 | 15,022 | 19,205 |

- **Total:** 15,390 → 17,829 (+2,439). En 2021 hay menos días (−134) porque D23 quita los días previos a la reubicación (NE completo en 2021; SO, SUR, SE, NTE hasta septiembre; NO hasta junio).
- **Más recuperación:** NO2 (511 → 1,532), donde casi siempre faltaba la radiación, y NTE (597 → 1,373).
- **Pérdidas en entrenamiento:** NO, SE, SUR y NTE2 pierden días: por D23 y porque el PM2.5 sin imputar deja algunos días por debajo de 18 h.

## 6. Lo que no cuadra (para decidir antes de la fase B)

1. **D19 elige `seadec` para SR, u y v con `maxgap` = 3 h, pero en huecos de 1–3 h `seadec` es peor que la lineal.** La regla promedia el RMSE diario sobre los seis largos (1–24 h) y después limita `maxgap` a los largos que cumplen el umbral. En SR, u y v gana por los huecos de 6–24 h, que nunca se imputarán. En los que sí se imputan, `seadec` tiene, en promedio sobre 1–3 h, más error que la lineal: u +5.0 %, v +5.7 % y SR +1.7 % (en 1 h, SR 0.0030 frente a 0.0023 y u 0.0340 frente a 0.0311).

   Como referencia (no aplicada; sería una regla nueva, aunque solo usa 2021–2023): si se eligiera el ganador promediando solo los largos ≤ `maxgap`, quedarían Kalman para SR (la lineal, +14 %) y RH (+23 %), la lineal para u y v (en u Stineman gana por 0.4 %; en v la lineal es la mejor), y `seadec` para TOUT y PRS. Los `maxgap` no cambian.
2. **`seadec` produce SR negativos.** Suma un ciclo diario que en la madrugada baja de cero. La revalidación (rango 0–1.4 kW/m²) revierte 541 de 1,710 imputaciones de SR (32 %; 535 son negativas), y v2 imputa menos horas de SR que la lineal de v1.2 (1,169 frente a 1,711). El enmascaramiento midió los valores crudos, antes de revalidar.
3. **El `maxgap` de 24 h de PRS sale de una DE «diaria» de 8.46 mm Hg** (muestra de entrenamiento). Esa DE incluye las diferencias de altitud entre estaciones (medias de 701 a 731 mm Hg). M1 usa la PRS como anomalía de su estación (D17). Con la DE de esa anomalía, el `maxgap` sería **12 h** (`maxgap_h_con_de_anomalia`). Se aplicó D19 tal cual (24 h).
4. **D20 no define «gana»** (sección 4): con una lectura gana la mediana de la red ajustada; con la otra, MICE, y solo por `horas_lluvia`. Es un caso conocido: el RMSE premia a los métodos deterministas frente a la imputación múltiple, porque pmm agrega ruido a propósito para reflejar la incertidumbre de imputar. Opciones:
   - (a) fijar la lectura «cada base» → mediana ajustada, una sola imputación;
   - (b) fijar la lectura «promedio de las m» → MICE;
   - (c) quitar `horas_lluvia` del criterio o repetir el enmascaramiento con varias semillas → con los datos actuales, mediana ajustada.

   Mi recomendación: (a) o (c). Con los datos actuales, la evidencia no muestra que MICE impute mejor.
5. **El patrón de faltantes de la prueba es distinto al del entrenamiento.** En 2021–2023, los candidatos a MICE pierden sobre todo SR (49 %) y viento (33 %). En 2024–2025, RH (52 %) y TOUT (26 %), y casi nunca viento (1 %). La validación diaria, que imita 2021–2023, mide poco a RH y TOUT. Para esas dos variables la mediana ajustada y MICE andan muy parejos (RH 3.57 frente a 3.61; TOUT 0.44 frente a 0.46), así que no cambia la conclusión, pero conviene saberlo.
6. **La correlación de la presión con la red es menor que la que cita D20.** Dentro de cada estación, la de los promedios diarios es 0.91 (D20 dice 0.96–0.99); la cruda es 0.29, por la altitud. No cambia nada del procedimiento.

## 7. Decisiones de implementación (no estaban escritas en D19–D20)

- **Bloques de enmascaramiento.**
  - El número de bloques por tramo es 5 % × horas / largo, con redondeo aleatorio, para que en promedio se borre el 5 % también en tramos cortos con bloques de 24 h.
  - Los bloques no tocan los bordes del tramo y quedan separados por ≥ 1 hora observada.
- **Métodos en el enmascaramiento.**
  - Cada método imputa la serie completa 2021–2023 de la estación, pero solo se evalúa en las horas borradas.
  - `na_ma` se calcula en ventanas de ±48 h alrededor de los bloques. Es exactamente equivalente (se comprueba en el script) y mucho más rápido.
- **Error diario.** Se mide en cada día que contiene horas borradas, con las mismas horas observadas, y exige ≥ 18 h.
- **«Mantiene» el umbral** (regla 3 de D19): se cumple en ese largo y en todos los menores.
- **La DE diaria del umbral** es la de la muestra de entrenamiento de la etapa 3 (2021–2023, n = 10,170).
- **Imputación horaria de v2 por periodo.** Se hace por separado en 2021–2023 y 2024–2025, para que la prueba no informe la imputación del entrenamiento. La revalidación usa la red de las 15 estaciones, igual que la etapa 1.
- **Imputación diaria.**
  - La «red» son las 13 estaciones de la muestra, y la mediana de cada día excluye a la propia estación.
  - Las tres técnicas se ajustan con los mismos datos: los días completos ya enmascarados.
  - MICE usa `maxit` = 5 (valor por defecto) y `maxcor` = 0.9999 (sección 4).
- **Criterio global de D20.** RMSE relativo promediado en las 8 variables, con cada variable pesando igual; también se reporta el ganador por variable.

## 8. Archivos

- `output/etapa4/imputacion/`:
  - A1: `enmascaramiento_horario.csv`, `enmascaramiento_horario_por_estacion.csv`, `eleccion_metodo_horario.csv`, `rmse_por_metodo_y_hueco.png`, `rmse_horario_por_metodo_y_hueco.png`, `tramos_completos_2021_2023.csv`, `tiempos_enmascaramiento_horario.csv` y `verificacion_serie_previa.csv`.
  - A2: `comprobacion_reproduce_v12.csv`, `perdidas_v12_v2.csv`, `imputacion_horaria_v12_v2.csv`, `faltantes_por_variable_candidatos_mice.csv`, `patrones_faltantes_2021_2023.csv` y `dias_por_estacion_anio_v12_v2.csv`.
  - A3: `enmascaramiento_diario.csv`, `enmascaramiento_diario_por_imputacion.csv`, `enmascaramiento_diario_mascara.csv`, `enmascaramiento_diario_ganador_por_variable.csv` y `eleccion_metodo_diario.csv`.
- `data/clean/v2/`: `diario_v2_2021_2025.csv` y `README.md`.
- **Código:**
  - `R/imputacion.R` (nuevo): lectura de la serie sin imputar, la red y la comprobación con los Excel.
  - `R/limpieza.R` (refactorizado, sin cambio de resultados).
  - `renv.lock`: agrega `mice` 3.19.0 y sus dependencias.
