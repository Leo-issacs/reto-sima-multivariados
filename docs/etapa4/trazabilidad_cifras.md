# Trazabilidad de las cifras del informe final

Cada cifra de `quarto/etapa4_informe_final.qmd` y el archivo de donde sale. Las tablas del informe se leen directamente de estos CSV al renderizar (no hay cifras copiadas a mano en las tablas, salvo las indicadas). Rutas relativas a la raíz del repositorio; `E4` = `output/etapa4/`.

Convenciones: «análisis final» = paso 4 de la tabla puente (base v2, entrenamiento sin días previos a la reubicación). Las cifras se redondean a 3 decimales (AUC, ΔAUC) o a 1 decimal (porcentajes).

## Resumen y sección 1

| Cifra | Valor en el informe | Fuente |
|---|---|---|
| Valores invalidados por la limpieza | 0.7 % | `data/clean/tabla_informe_limpieza.csv` (suma de `invalidada_*_n` / `horas_esperadas`, 15 variables, sin `viento_uv`: 0.715 %) |
| Horas mínimas para el PM2.5 diario | 18 h | D18 en `docs/etapa4/decisiones_etapa4.md`; NOM-025-SSA1-2021 |
| Estación-días del análisis final | 17 828 | `E4/tabla_puente.csv`, paso 4 (`n_entrena` 10 965 + `n_prueba` 6 863) |
| AUC M0 → M1 | 0.713 → 0.792 | `E4/prueba_v2_metricas_m0_m1.csv` |
| ΔAUC e IC 95 % | 0.079 [0.054, 0.104] | `E4/prueba_v2_sensibilidades.csv`, fila 1 |
| Sensibilidad M0 / M1 | 56 % / 74 % (0.565 / 0.742) | `E4/prueba_v2_metricas_m0_m1.csv` |
| Especificidad M0 / M1 | 0.70 / 0.68 (0.703 / 0.680) | `E4/prueba_v2_metricas_m0_m1.csv` |
| Días > 40 µg/m³ marcados | M1 90 %, M0 81 % | `E4/errores/errores_por_magnitud_pm25.csv` (89.7 y 81.1) |
| ΔAUC seca-cálida | 0.151 | `E4/prueba_v2_dauc_por_temporada.csv` |
| Rango de ΔAUC en las variantes | 0.071 a 0.082 | `E4/prueba_v2_sensibilidades.csv` (mín. 0.071, logística y casos completos) y `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` (máx. 0.082, sin NO2) |
| SIMA desde 1992, 15 estaciones | — | SIMA (2026), presentación; `docs/etapa1/texto_etapa1_final.md` |
| Metaanálisis de 196 artículos | — | Orellano et al. (2020); `docs/etapa1/texto_etapa1_final.md` |
| Guía OMS 15 µg/m³; límite 25 µg/m³ | — | WHO (2021); Secretaría de Salud (2021) |

## Sección 3. Área de estudio

| Cifra | Valor | Fuente |
|---|---|---|
| Altitud de 334 m (SE3) a 702 m (NO2) | — | `E4/area_estudio/mapa_estaciones_altitud.csv` |
| Tabla 1 (código, nombre, municipio, altitud, días, % superación) | — | `E4/area_estudio/mapa_estaciones_altitud.csv` (se lee al renderizar). Municipio de NTE2, SE3 y SUR completado a mano (vacío en el CSV), marcado con * |
| u < 0 en 80 % a 98 % de los días en 11 estaciones; NE2 62 %, SO2 68 % | 80.3–98.1; 62.3; 68.4 | `E4/descriptivos/viento_por_estacion.csv` (`pct_dias_flujo_del_este`) |
| Dirección resultante 68° a 140° | 68.4–139.7 | `E4/descriptivos/viento_por_estacion.csv` (`direccion_resultante_grados`, las 11 estaciones) |
| SE2: viento más débil (1.55 m/s) | 1.550 | `E4/descriptivos/viento_por_estacion.csv` (`rapidez_media`) |
| SE2: Spearman PM2.5–PM10 0.82; cociente 0.40 | 0.816; 0.396 | `E4/descriptivos/cociente_pm25_pm10_por_estacion.csv` |
| Enero: SE2 33.1 → 43.1 µg/m³; SE3 22.4 | 33.11 → 43.12; 22.36 / 22.36 | `E4/descriptivos/boletin_enero_2023_2024.csv` |
| SO: SMD de la rapidez −0.76; u −1.16 frente a −2.01 m/s | −0.762; −1.160 / −2.008 | `E4/descriptivos/viento_por_estacion.csv` |
| SUR: 3.0 % en 2021; 10–12 % desde 2022 | 2.98; 10.1–12.1 | `E4/area_estudio/superacion_por_estacion_anio.csv` |
| Cambio de presión frente a la red: SUR +5.7, NTE +1.6 mm Hg | 5.68; 1.62 | `E4/area_estudio/prs_antes_despues_reubicacion.csv` |
| Tabla 2: ΔAUC con reubicaciones de SIMA 0.081; sin NO2 0.082; SR ≥ 0 0.079 | 0.0807; 0.0820; 0.0790 | `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` |
| Tabla 2: mejora por año 0.069 (2024) y 0.088 (2025) | — | `E4/prueba_v2_dauc_por_anio.csv` |
| Tabla 2: nivel del viento cambia entre marzo y abril de 2021 | — | `output/etapa3/diagnostico/viento_mes_de_cambio_2021.csv`; `docs/etapa3/texto_etapa3_borrador.md` |
| Tabla 2: PM2.5 de NO2 a la mitad con PM10 normal (enero–mayo de 2021; julio de 2023–enero de 2025) | — | `E4/descriptivos/periodos_pm25_bajo_con_pm10_normal.csv`, `E4/descriptivos/pm25_pm10_relativo_mensual.csv` |
| Tabla 2: SR media NO2 0.015 y NTE 0.041 kW/m²; demás 0.12–0.18 | 0.0149; 0.0413; 0.117–0.178 | `E4/descriptivos/sr_media_por_estacion.csv` (09g, bloque 7) |
| Tabla 2: reubicaciones y fechas del PIGECA | — | SMA y CAI (2024), p. 91; fechas de corte en `scripts/08b_construir_base_v2.R` (`REUBICACION`) y `E4/area_estudio/prs_antes_despues_reubicacion.csv` |
| Tabla 2: reubicaciones y equipos según SIMA | — | `docs/etapa4/retroalimentacion_final.md` (R2, R3) |

## Sección 4. Preparación

| Cifra | Valor | Fuente |
|---|---|---|
| 6 libros, 87 hojas estación-año, 15 estaciones, 15 variables | — | `docs/etapa1/texto_etapa1_final.md`; `scripts/02_importar_diagnosticar.R` |
| Faltante original 12.3 %; PM2.5 26.0 % | 12.34; 26.03 | `data/clean/tabla_informe_limpieza.csv` (`faltante_original_n` / `horas_esperadas`) |
| Tabla 3 (largo de los huecos) y «51 % a 82 % en huecos de más de un día» | PRS 50.6 … SR 82.0 | `E4/errores/largo_huecos_horarios.csv` (09g, bloque 4; suma de «1-7 días» y «> 7 días») |
| Tabla 4: horas anuladas por regla | — | `data/clean/tabla_informe_limpieza.csv` (se lee al renderizar); E de TOUT/RH (450 y 4 120) y E de WSR (4 426), de `data/clean/README.md` y de la misma tabla |
| Pérdida por no imputar la respuesta | 526 | `E4/imputacion/perdidas_v12_v2.csv` |
| Figura 2: 5 repeticiones, 2 730 series por método | — | `E4/imputacion/RESUMEN_FASE_A.md`; `E4/imputacion/enmascaramiento_horario.csv` |
| Subestimación del máximo en huecos de 2–3 h: 0.9 a 1.6 µg/m³ | — | `E4/imputacion/RESUMEN_FASE_A.md` (diagnóstico de picos; columna `pico_sesgo` de `enmascaramiento_horario.csv`) |
| Regla de descalificación (> 5 % de reversión) y umbral (0.10 × DE de la anomalía) | — | D19 en `docs/etapa4/decisiones_etapa4.md` (registro de cambios de la fase A) |
| Tabla 5 (método, maxgap, lineal frente al ganador, % revertido, horas imputadas) | — | `E4/imputacion/eleccion_metodo_horario.csv` y `E4/imputacion/imputacion_horaria_v12_v2.csv` (se leen al renderizar) |
| D20: RMSE relativo 0.450 / 0.593 / 0.736 | 0.4500; 0.5932; 0.7358 | `E4/imputacion/eleccion_metodo_diario.csv` |
| D20: gana también en temperatura y humedad | — | `E4/imputacion/enmascaramiento_diario_ganador_por_variable.csv`; `E4/imputacion/RESUMEN_FASE_A.md` |
| MICE con m = 20 | — | `scripts/08d_imputar_diario.R`; D20 en `docs/etapa4/decisiones_etapa4.md` |
| Celdas imputadas a nivel diario (sobre todo SR y RH) | SR 1 970, RH 1 870 | `E4/imputacion/imputacion_diaria_conteo.csv` |
| MIMA-v1: 9 estaciones, hasta junio de 2025, sin SE2/SE3/SUR/NE2; MAE 4.01 de la lineal | — | Gómez et al. (2025), reporte del proyecto; `docs/etapa4/prompt_claude_code_fase_E_mima.md`; `docs/etapa4/imputacion_reto_sima_consolidado.md` |
| Presión media por sitio de 701 a 731 mm Hg | 700.8–731.5 | `data/clean/v2/diario_v2_imputado_2021_2025.csv` (entrenamiento del análisis final); `docs/etapa3/texto_etapa3_borrador.md` |
| Logaritmos: AUC +0.003 y +0.007 | 0.0035; 0.0069 | `output/etapa3/validacion/seccion2_transformaciones.csv` |
| Asimetría del viento +0.37 → −0.98 | 0.372; −0.984 | `output/etapa3/validacion/seccion4_supuestos.csv` |
| Muestra: 23 738; 19 392; 15 011; 4 192; 189; 1 375 | — | `E4/imputacion/perdidas_v12_v2.csv` |
| Entrenamiento 10 965 (25.9 %); prueba 6 863 (26.2 %) | 0.2589; 0.2621 | `E4/prueba_v2_sensibilidades.csv` (`n_entrena`, `prevalencia_entrena`, `n`, `prevalencia`) |
| 2 438 días más que la etapa 3 | 17 828 − 15 390 | `E4/imputacion/perdidas_v12_v2.csv` (15 390 casos completos v1.2) |
| NO2 511 → 1 532; NTE 597 → 1 373; qué faltaba | — | `E4/imputacion/dias_por_estacion_anio_v12_v2.csv`; columnas `imp_SR` e `imp_RH` de `data/clean/v2/diario_v2_imputado_2021_2025.csv` (NO2: 925 días con SR imputada; NTE: 864 con RH imputada) |

## Sección 5. Modelación y validación

| Cifra | Valor | Fuente |
|---|---|---|
| KMO 0.64; Bartlett χ² 26 503, gl 28; 3 valores propios > 1; 66.5 % | 0.635; 26 503; 28; 3; 66.5 | `E4/pca/pca_v2_resumen.csv` (09g, bloque 1) |
| PCs como predictores (etapa 3) | 0.064 | `output/etapa3/prueba_sensibilidades.csv` |
| Categorías de referencia CE y cálida-húmeda; 14 indicadoras; 22 predictores | — | `E4/lda/estabilidad_coeficientes.csv` (lista de predictores); `R/modelo_etapa4.R` |
| Prior y corte | 0.259 | `E4/prueba_v2_sensibilidades.csv` (`prevalencia_entrena` 0.2589) |
| Tabla 7, Mardia: asimetría χ² 99 015 y 198 072, gl 120 | — | `E4/errores/supuestos_normalidad_mardia.csv` |
| Tabla 7: asimetría de la lluvia 7.6 y 19.9; razón DE lluvia 0.40, v 0.78, demás 0.85–1.05 | — | `E4/errores/supuestos_razon_de_y_asimetria.csv` |
| Tabla 7: M de Box χ² 3 213, gl 36 | — | `E4/errores/supuestos_box_m.csv` |
| Tabla 7 y 5.5: ACF a 1 día 0.50 (respuesta), 0.44 (M0), 0.42 (M1); a 14 días 0.12 (M1) | 0.495; 0.443; 0.422; 0.120 | `E4/errores/acf_promedio_y_residuos.csv` |
| Correlación entre estaciones el mismo día 0.48 → 0.36 | 0.477; 0.417; 0.356 | `E4/errores/correlacion_mismo_dia_y_residuos.csv` |
| VIF máximo 2.28; número de condición 2.97 | 2.276; 2.975 | `E4/errores/supuestos_vif.csv`, `E4/errores/supuestos_numero_condicion.csv` |
| Varianza del residuo de M1: 0.086 (lluvias) a 0.205 (seca-cálida); F = 503 | — | `E4/errores/residuos_varianza_por_temporada.csv`, `E4/errores/residuos_brown_forsythe.csv` (09g, bloque 2) |
| Error 1.34 veces el esperado en el decil 10 | 1.341 | `E4/errores/heterogeneidad_por_decil.csv` |
| Logística 0.071 | 0.0711 | `E4/prueba_v2_sensibilidades.csv` |
| QDA 0.788 frente a 0.792; solo meteorología 0.704–0.712 frente a 0.718 | — | `E4/lda/qda_vs_lda.csv` |
| Pendiente de recalibración 0.82; por temporada 0.69–0.76 | 0.822; 0.691–0.757 | `E4/lda/calibracion_recalibracion.csv`; `E4/errores/calibracion_m1_por_temporada.csv` (09g, bloque 3) |
| Validación progresiva: 0.074 (2022) y 0.083 (2023) | 0.0744; 0.0830 | `E4/lda/pliegues_auc_validacion.csv` |
| 1 000 réplicas, bloques de 14 días | — | `E4/registro_prueba_v2.txt`; `scripts/09a_evaluar_prueba_v2.R` |
| Tabla 8 (puente) | — | `E4/tabla_puente.csv` (se lee al renderizar) |
| 5.7: interacción 0.056; MICE 0.078 | — | `output/etapa3/prueba_sensibilidades.csv`; `E4/prueba_v2_sensibilidades.csv` |

## Sección 6. Resultados

| Cifra | Valor | Fuente |
|---|---|---|
| Tabla 9 (métricas e IC) | — | `E4/prueba_v2_metricas_m0_m1.csv`, `E4/prueba_v2_sensibilidades.csv` (se leen al renderizar) |
| Figura 4a (ROC) | — | `E4/prueba_v2_predicciones.csv` (09g, bloque 6) |
| Figura 4b y texto: seca-cálida 0.151 [0.102, 0.193]; seca-fría 0.069 [0.037, 0.100]; lluvias 0.039 [−0.018, 0.104]; superación en lluvias 9.7 % | — | `E4/prueba_v2_dauc_por_temporada.csv` |
| 2024: 0.069 [0.032, 0.106]; 2025: 0.088 [0.061, 0.124] | — | `E4/prueba_v2_dauc_por_anio.csv` |
| Figura 5 y texto: > 40 µg/m³ 90 % / 81 %; < 15 µg/m³ 21 % / 27 % | 89.7 / 81.1; 21.3 / 26.5 | `E4/errores/errores_por_magnitud_pm25.csv` |
| PCA: 36 %, 17 %, 13 %; cargas | 35.8; 17.5; 13.2 | `E4/pca/pca_v2_valores_propios.csv`, `E4/pca/pca_v2_cargas.csv` |
| Coeficientes: rapidez −0.50 [−0.63, −0.35]; PRS −0.46 [−0.57, −0.30]; TOUT 0.44 [0.16, 0.70]; correlación de estructura de TOUT −0.07 | — | `E4/lda/estabilidad_coeficientes.csv` |
| Mismo signo LDA y logística en las 8 meteorológicas | — | `E4/lda/lda_vs_logistica.csv` |
| Signo de las 5 estables en los pliegues 2022 y 2023 | — | `E4/lda/coeficientes_por_pliegue.csv` |
| Tabla 10 (robustez) | — | `E4/prueba_v2_sensibilidades.csv` y `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` (se leen al renderizar) |

## Sección 7 y anexos

| Cifra | Valor | Fuente |
|---|---|---|
| Hallazgos y Tabla 11 | Repiten cifras ya trazadas arriba | — |
| Anexo A (Tabla 13): 0.064 [0.039, 0.090]; 0.056 [0.036, 0.076]; frente a 0.070 | — | `output/etapa3/prueba_sensibilidades.csv` |
| Anexo A: QDA, MICE, logaritmos | — | `E4/lda/qda_vs_lda.csv`; `E4/imputacion/eleccion_metodo_diario.csv`; `output/etapa3/validacion/seccion2_transformaciones.csv` |
| Anexo B (Tabla 14) | Diccionario | `data/clean/v2/diario_v2_imputado_2021_2025.csv` (columnas) |
| Anexo C, Tabla 15 (errores por estación) | — | `E4/errores/errores_por_estacion.csv`, `E4/errores/heterogeneidad_por_estacion.csv` |
| Anexo C, Tabla 16 (deciles) | — | `E4/lda/calibracion_deciles.csv` |
| Anexo C, Tabla 17 (recalibración por temporada) | — | `E4/errores/calibracion_m1_por_temporada.csv` |
| Anexo C, Tabla 18 (días por año) | — | `E4/imputacion/dias_por_estacion_anio_v12_v2.csv` |
| Anexo C: SO única estación con efecto estable mayor que CE; SE2 no se distingue | estSO 0.128, 99.8 %; estSE2 0.008, 56 % | `E4/lda/estabilidad_coeficientes.csv` |
| Figura 8 (NO2) y Figura 9 (coeficientes con estaciones) | — | `E4/descriptivos/no2_pm25_pm10_relativo.png` (09f); `E4/lda/coeficientes_ic.png` (09b) |

## Figuras del cuerpo

| Figura | Archivo | Script |
|---|---|---|
| 1. Mapa de estaciones | `E4/area_estudio/mapa_estaciones_altitud.png` | 09c |
| 2. RMSE por método y hueco | `E4/imputacion/rmse_por_metodo_y_hueco.png` | 08a |
| 3. ACF de la respuesta y de los residuos | `E4/errores/acf_respuesta_y_residuos.png` | 09d |
| 4. ROC y ΔAUC por temporada y año | `E4/figuras/roc_y_dauc_informe.png` | 09g (bloque 6) |
| 5. Clasificación según la magnitud del PM2.5 | `E4/errores/errores_magnitud_pm25.png` | 09d |
| 6. Cargas del PCA | `E4/pca/pca_v2_cargas.png` | 09g (bloque 1) |
| 7. Coeficientes de la meteorología | `E4/lda/coeficientes_ic_meteorologia.png` | 09g (bloque 5) |
