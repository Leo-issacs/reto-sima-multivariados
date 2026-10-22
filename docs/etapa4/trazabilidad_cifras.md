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
| SIMA desde 1992, 15 estaciones | — | Sistema Integral de Monitoreo Ambiental [SIMA] (2026), presentación; `docs/etapa1/texto_etapa1_final.md` |
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
| Enero: SE2 33.1 → 43.1 µg/m³; SE3 22.4 | 33.11 → 43.12; 22.36 / 22.36 | `E4/descriptivos/boletin_enero_2023_2024.csv`. El boletín estatal (Gobierno del Estado de Nuevo León, 2024) da otras cifras; el informe solo dice que el cambio va en la misma dirección |
| SO: SMD de la rapidez −0.76; u −1.16 frente a −2.01 m/s | −0.762; −1.160 / −2.008 | `E4/descriptivos/viento_por_estacion.csv` |
| SUR: 3.0 % en 2021; 10–12 % desde 2022 | 2.98; 10.1–12.1 | `E4/area_estudio/superacion_por_estacion_anio.csv` |
| Cambio de presión frente a la red: SUR +5.7, NTE +1.6 mm Hg | 5.68; 1.62 | `E4/area_estudio/prs_antes_despues_reubicacion.csv` |
| Tabla 12: ΔAUC con reubicaciones de SIMA 0.081; sin NO2 0.082; SR ≥ 0 0.079 | 0.0807; 0.0820; 0.0790 | `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` |
| Tabla 12: mejora por año 0.069 (2024) y 0.088 (2025) | — | `E4/prueba_v2_dauc_por_anio.csv` |
| Tabla 12: nivel del viento cambia entre marzo y abril de 2021 | — | `output/etapa3/diagnostico/viento_mes_de_cambio_2021.csv`; `docs/etapa3/texto_etapa3_borrador.md` |
| Tabla 12: PM2.5 de NO2 a cerca de la mitad del nivel de la red con PM10 normal (enero–mayo de 2021; julio de 2023–enero de 2025) | mediana del PM2.5 relativo 0.55–0.61; PM10 0.93–1.11 | `E4/descriptivos/periodos_pm25_bajo_con_pm10_normal.csv`, `E4/descriptivos/pm25_pm10_relativo_mensual.csv` |
| Tabla 12: SR media NO2 0.015 y NTE 0.041 kW/m²; demás 0.12–0.18 | 0.0149; 0.0413; 0.117–0.178 | `E4/descriptivos/sr_media_por_estacion.csv` (09g, bloque 7) |
| Tabla 12: reubicaciones y fechas del PIGECA | — | SMA y CAI (2024), p. 91; fechas de corte en `scripts/08b_construir_base_v2.R` (`REUBICACION`) y `E4/area_estudio/prs_antes_despues_reubicacion.csv` |
| Tabla 12: reubicaciones y equipos según SIMA | — | `docs/etapa4/retroalimentacion_final.md` (R2, R3) |

## Sección 4. Preparación

| Cifra | Valor | Fuente |
|---|---|---|
| 6 libros, 87 hojas estación-año, 15 estaciones, 15 variables | — | `docs/etapa1/texto_etapa1_final.md`; `scripts/02_importar_diagnosticar.R` |
| Faltante original 12.3 %; PM2.5 26.0 % | 12.34; 26.03 | `data/clean/tabla_informe_limpieza.csv` (`faltante_original_n` / `horas_esperadas`) |
| Tabla 13 (largo de los huecos) y «51 % a 82 % en huecos de más de un día» | PRS 50.6 … SR 82.0 | `E4/errores/largo_huecos_horarios.csv` (09g, bloque 4; suma de «1-7 días» y «> 7 días») |
| Tabla 15: horas anuladas por regla | — | `data/clean/tabla_informe_limpieza.csv` (se lee al renderizar); E de TOUT/RH (450 y 4 120) y E de WSR (4 426), de `data/clean/README.md` y de la misma tabla |
| Pérdida por no imputar la respuesta | 526 | `E4/imputacion/perdidas_v12_v2.csv` |
| Figura 6: 5 repeticiones, 2 730 series por método | — | `E4/imputacion/RESUMEN_FASE_A.md`; `E4/imputacion/enmascaramiento_horario.csv` |
| Subestimación del máximo en huecos de 2–3 h: 0.9 a 1.6 µg/m³ | — | `E4/imputacion/RESUMEN_FASE_A.md` (diagnóstico de picos; columna `pico_sesgo` de `enmascaramiento_horario.csv`) |
| Regla de descalificación (> 5 % de reversión) y umbral (0.10 × DE de la anomalía) | — | D19 en `docs/etapa4/decisiones_etapa4.md` (registro de cambios de la fase A) |
| Tabla 2 (método, maxgap, lineal frente al ganador, % revertido, horas imputadas) | — | `E4/imputacion/eleccion_metodo_horario.csv` y `E4/imputacion/imputacion_horaria_v12_v2.csv` (se leen al renderizar) |
| D20: RMSE relativo 0.450 / 0.593 / 0.736 | 0.4500; 0.5932; 0.7358 | `E4/imputacion/eleccion_metodo_diario.csv` |
| D20: MICE con el promedio de las cinco imputaciones del experimento de selección, 0.436 (referencia; la regla registrada compara cada base imputada) | 0.4359 | `E4/imputacion/eleccion_metodo_diario.csv` (`referencia_rmse_rel_medio_mice_promedio_m`); m = 5 en `scripts/08c_enmascaramiento_diario.R` (`M_VALIDACION`) |
| D20: sensibilidad posterior del clasificador con 20 bases imputadas de MICE, ΔAUC 0.078 | 0.0784 | `E4/prueba_v2_sensibilidades.csv` (fila «MICE») |
| D20: gana también en temperatura y humedad | — | `E4/imputacion/enmascaramiento_diario_ganador_por_variable.csv`; `E4/imputacion/RESUMEN_FASE_A.md` |
| MICE con m = 20 (sensibilidad) y m = 5 (selección del método) | — | `scripts/08d_imputar_diario.R`; `scripts/08c_enmascaramiento_diario.R`; D20 en `docs/etapa4/decisiones_etapa4.md` |
| Celdas imputadas a nivel diario (sobre todo SR y RH) | SR 1 970, RH 1 870 | `E4/imputacion/imputacion_diaria_conteo.csv` |
| MIMA-v1: 9 estaciones (SE, CE, SO2, SO, NTE2, NO, NO2, NTE, NE), de enero de 2021 a junio de 2025, sin SE2/SE3/SUR/NE2; MAE 4.01 de la lineal; licencia del código «MIT modificada», que exige autorización escrita para modificaciones o distribución derivada | — | Gómez et al. (2025), reporte del proyecto (cifras verificadas por Opus contra los originales que dio Leo); `docs/etapa4/imputacion_reto_sima_consolidado.md`. SAITS + CSDI: Gómez Santos et al. (2027), capítulo de Springer (CCIS 3097, pp. 728–739) |
| Presión media por sitio de 700.8 a 731.5 mm Hg | 700.788 (NO2) – 731.500 (SE3) | `data/clean/v2/diario_v2_imputado_2021_2025.csv`: media de PRS por estación en el entrenamiento del análisis final (2021–2023, `sitio_valido` = 1, respuesta válida y las 8 meteorológicas; n = 10 965), la misma que resta `prs_anomalia()` en `R/modelo_etapa4.R` |
| Logaritmos: AUC +0.003 y +0.007 | 0.0035; 0.0069 | `output/etapa3/validacion/seccion2_transformaciones.csv` |
| Asimetría del viento +0.37 → −0.98 | 0.372; −0.984 | `output/etapa3/validacion/seccion4_supuestos.csv` |
| Muestra: 23 738; 19 392 con respuesta válida; de ellos, 15 011 con las 8 meteorológicas; 4 192; 189; 1 375 | — | `E4/imputacion/perdidas_v12_v2.csv`. Los 15 011 son la intersección (respuesta válida y 8 meteorológicas); sin condicionar a la respuesta hay 18 041 días con las 8 meteorológicas |
| Entrenamiento 10 965 (25.9 %); prueba 6 863 (26.2 %) | 0.2589; 0.2621 | `E4/prueba_v2_sensibilidades.csv` (`n_entrena`, `prevalencia_entrena`, `n`, `prevalencia`) |
| 2 438 días más que la etapa 3 | 17 828 − 15 390 | `E4/imputacion/perdidas_v12_v2.csv` (15 390 casos completos v1.2) |
| NO2 511 → 1 532; NTE 597 → 1 373; qué faltaba | — | `E4/imputacion/dias_por_estacion_anio_v12_v2.csv`; columnas `imp_SR` e `imp_RH` de `data/clean/v2/diario_v2_imputado_2021_2025.csv` (en la muestra final: NO2, 925 días con SR imputada; NTE, 855 días con RH imputada, 864 antes de excluir los 9 días previos a la reubicación) |

## Sección 5. Modelación y validación

| Cifra | Valor | Fuente |
|---|---|---|
| KMO 0.64 («mediocre» según Kaiser y Rice, 1974); Bartlett χ² 26 503, gl 28; 3 valores propios > 1; 66.5 % | 0.635; 26 503; 28; 3; 66.5 | `E4/pca/pca_v2_resumen.csv` (09g, bloque 1) |
| PCs como predictores (etapa 3) | 0.064 | `output/etapa3/prueba_sensibilidades.csv` |
| Categorías de referencia CE y cálida-húmeda; 14 indicadoras; 22 predictores | — | `E4/lda/estabilidad_coeficientes.csv` (lista de predictores); `R/modelo_etapa4.R` |
| Prior y corte | 0.259 | `E4/prueba_v2_sensibilidades.csv` (`prevalencia_entrena` 0.2589) |
| Tabla 5, Mardia: asimetría χ² 99 015 y 198 072, gl 120 | — | `E4/errores/supuestos_normalidad_mardia.csv` |
| Tabla 5: asimetría de la lluvia 7.6 y 19.9; razón DE lluvia 0.40, v 0.78, demás 0.85–1.05 | — | `E4/errores/supuestos_razon_de_y_asimetria.csv` |
| Tabla 5: M de Box χ² 3 213, gl 36 | — | `E4/errores/supuestos_box_m.csv` |
| Tabla 5 y sección 5.6: ACF a 1 día 0.50 (respuesta), 0.44 (M0), 0.42 (M1); a 14 días 0.12 (M1) | 0.495; 0.443; 0.422; 0.120 | `E4/errores/acf_promedio_y_residuos.csv` |
| Correlación entre estaciones el mismo día 0.48 → 0.36 | 0.477; 0.417; 0.356 | `E4/errores/correlacion_mismo_dia_y_residuos.csv` |
| VIF máximo 2.28; número de condición 2.97 | 2.276; 2.975 | `E4/errores/supuestos_vif.csv`, `E4/errores/supuestos_numero_condicion.csv` |
| Tabla 5, diagnóstico adicional: varianza de Y − p̂ de M1 de 0.086 (lluvias) a 0.205 (seca-cálida); F = 503 (Brown-Forsythe, solo descriptivo) | — | `E4/errores/residuos_varianza_por_temporada.csv`, `E4/errores/residuos_brown_forsythe.csv` (09g, bloque 2) |
| Error 1.34 veces el esperado en el decil 10 | 1.341 | `E4/errores/heterogeneidad_por_decil.csv` |
| Logística 0.071 | 0.0711 | `E4/prueba_v2_sensibilidades.csv` |
| QDA 0.788 frente a 0.792; solo meteorología 0.704–0.712 frente a 0.718 | — | `E4/lda/qda_vs_lda.csv` |
| Pendiente de recalibración 0.82; por temporada 0.69–0.76 | 0.822; 0.691–0.757 | `E4/lda/calibracion_recalibracion.csv`; `E4/errores/calibracion_m1_por_temporada.csv` (09g, bloque 3) |
| Validación progresiva: 0.074 (2022) y 0.083 (2023) | 0.0744; 0.0830 | `E4/lda/pliegues_auc_validacion.csv` |
| 1 000 réplicas, bloques de 14 días; los IC remuestrean predicciones de modelos ya ajustados; MICE con 20 × 200 réplicas agrupadas | — | `E4/registro_prueba_v2.txt`; `scripts/09a_evaluar_prueba_v2.R` (`N_REPLICAS`, `N_REPLICAS_MICE`); `R/modelo_etapa4.R` (bootstrap pareado por bloques) |
| Pliegues internos: la imputación y su selección usaron todo 2021–2023 | — | `scripts/08a_enmascaramiento_horario.R` y `scripts/08c_enmascaramiento_diario.R` (selección en 2021–2023); `scripts/08d_imputar_diario.R` (diferencia sitio-red con 2021–2023); `scripts/09b_validar_lda.R` (pliegues sobre la base ya imputada) |
| Tabla 17 (puente) | — | `E4/tabla_puente.csv` (se lee al renderizar) |
| 5.8: interacción 0.056; MICE 0.078 | — | `output/etapa3/prueba_sensibilidades.csv`; `E4/prueba_v2_sensibilidades.csv` |

## Sección 6. Resultados

| Cifra | Valor | Fuente |
|---|---|---|
| Tabla 6 (métricas e IC de LDA y logística) | LDA: AUC 0.713 → 0.792, EB 0.634 → 0.711; logística: 0.721 → 0.792, EB 0.631 → 0.711 | `E4/retro_final/metricas_lda_logistica.csv` e `ic_lda_logistica.csv` (10, bloque 4; se leen al renderizar). El script comprueba que el LDA coincide con `E4/prueba_v2_metricas_m0_m1.csv` y el IC de la logística con `E4/prueba_v2_sensibilidades.csv` (fila 2) |
| Figura 3a (ROC) | — | `E4/prueba_v2_predicciones.csv` (09g, bloque 6) |
| Figura 3b y texto: seca-cálida 0.151 [0.102, 0.193]; seca-fría 0.069 [0.037, 0.100]; lluvias 0.039 [−0.018, 0.104]; superación en lluvias 9.7 %; AUC de M1 en lluvias 0.706 | 0.7060 | `E4/prueba_v2_dauc_por_temporada.csv` (`auc_M1`, fila `calida_humeda`) |
| 2024: 0.069 [0.032, 0.106]; 2025: 0.088 [0.061, 0.124] | — | `E4/prueba_v2_dauc_por_anio.csv` |
| Figura 7 y texto: > 40 µg/m³ 90 % / 81 %; < 15 µg/m³ 21 % / 27 % | 89.7 / 81.1; 21.3 / 26.5 | `E4/errores/errores_por_magnitud_pm25.csv` |
| PCA: 36 %, 17 %, 13 %; cargas | 35.8; 17.5; 13.2 | `E4/pca/pca_v2_valores_propios.csv`, `E4/pca/pca_v2_cargas.csv` |
| Coeficientes: rapidez −0.50 [−0.63, −0.35]; PRS −0.46 [−0.57, −0.30]; TOUT 0.44 [0.16, 0.70]; correlación de estructura de TOUT −0.07 | — | `E4/lda/estabilidad_coeficientes.csv` |
| Mismo signo LDA y logística en las 8 meteorológicas | — | `E4/lda/lda_vs_logistica.csv` |
| Signo de las 5 estables en los pliegues 2022 y 2023 | — | `E4/lda/coeficientes_por_pliegue.csv` |
| Tabla 18 (robustez) | — | `E4/prueba_v2_sensibilidades.csv` y `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` (se leen al renderizar) |

## Sección 7 y anexos

| Cifra | Valor | Fuente |
|---|---|---|
| Hallazgos y Tabla 9 | Repiten cifras ya trazadas arriba | — |
| Hallazgos: el PM2.5 no tiene una periodicidad tan marcada como la del ozono | — | SIMA, comentario en la exposición de la etapa 3 (15 de octubre de 2026), citado como comunicación personal; `docs/etapa4/retroalimentacion_final.md` (R2) |
| Anexo A (Tabla 11): 0.064 [0.039, 0.090]; 0.056 [0.036, 0.076]; frente a 0.070 | — | `output/etapa3/prueba_sensibilidades.csv` |
| Anexo A: QDA, MICE, logaritmos | — | `E4/lda/qda_vs_lda.csv`; `E4/imputacion/eleccion_metodo_diario.csv`; `output/etapa3/validacion/seccion2_transformaciones.csv` |
| Anexo B (Tabla 16) | Diccionario | `data/clean/v2/diario_v2_imputado_2021_2025.csv` (columnas) |
| Anexo C, Tabla 19 (errores por estación) | — | `E4/errores/errores_por_estacion.csv`, `E4/errores/heterogeneidad_por_estacion.csv` |
| Anexo C, Tabla 20 (deciles) | — | `E4/lda/calibracion_deciles.csv` |
| Anexo C, Tabla 21 (recalibración por temporada) | — | `E4/errores/calibracion_m1_por_temporada.csv` |
| Anexo C, Tabla 22 (días por año) | — | `E4/imputacion/dias_por_estacion_anio_v12_v2.csv` |
| Anexo C: SO única estación con efecto estable mayor que CE; SE2 no se distingue | estSO 0.128, 99.8 %; estSE2 0.008, 56 % | `E4/lda/estabilidad_coeficientes.csv` |
| Figura 10 (NO2) y Figura 11 (coeficientes con estaciones) | — | `E4/figuras/no2_relativo_informe.png` y `E4/figuras/coeficientes_ic_informe.png` (09h, bloques 6 y 7), con `E4/descriptivos/pm25_pm10_relativo_mensual.csv` de 09f y `E4/lda/estabilidad_coeficientes.csv` de 09b |

## Figuras del cuerpo y de los anexos

| Figura | Archivo | Script |
|---|---|---|
| 1. Mapa de estaciones | `E4/figuras/mapa_estaciones_informe.png` | 09h (bloque 1), con `E4/area_estudio/mapa_estaciones_altitud.csv` de 09c |
| 2. ACF de la respuesta y de los residuos | `E4/figuras/acf_residuos_informe.png` | 09h (bloque 4), con `E4/errores/acf_promedio_y_residuos.csv` de 09d |
| 3. ROC y ΔAUC por temporada y año | `E4/figuras/roc_y_dauc_informe.png` | 09g (bloque 6) |
| 4. Cargas del PCA | `E4/figuras/pca_cargas_informe.png` | 09h (bloque 3), con `E4/pca/pca_v2_cargas.csv` y `pca_v2_valores_propios.csv` de 09g |
| 5. Coeficientes de la meteorología y la temporada: LDA frente a logística | `E4/retro_final/coef_lda_logistica_informe.png` | 10 (bloque 12), con `E4/lda/estabilidad_coeficientes.csv` de 09b y `E4/retro_final/a1_odds_ratios_logistica.csv` |
| 6. RMSE por método y hueco | `E4/figuras/rmse_imputacion_informe.png` | 09h (bloque 2), con `E4/imputacion/enmascaramiento_horario.csv` y `eleccion_metodo_horario.csv` de 08a |
| 7. Clasificación según la magnitud del PM2.5 | `E4/figuras/errores_magnitud_informe.png` | 09h (bloque 5), con `E4/errores/errores_por_magnitud_pm25.csv` de 09d |

| 8. Linealidad en la escala logit | `E4/retro_final/linealidad_logit_informe.png` | 10 (bloque 12), con `E4/retro_final/a2_gam_curvas.csv` y `a2_logits_empiricos.csv` |
| 9. Métricas según el corte | `E4/retro_final/metricas_por_corte_informe.png` | 10 (bloque 12), con `E4/retro_final/c_metricas_por_corte.csv` y `c_cortes_en_pliegues.csv` |
| 10. PM2.5 y PM10 de NO2 frente a la red | `E4/figuras/no2_relativo_informe.png` | 09h (bloque 6) |
| 11. Coeficientes con las indicadoras de estación | `E4/figuras/coeficientes_ic_informe.png` | 09h (bloque 7) |

Las Figuras 1–5 están en el cuerpo; la 6 en el Anexo B y las 7–11 en el Anexo C. 09h solo cambia la presentación de las Figuras 1, 2, 4, 6, 7, 10 y 11 (etiquetas en español, tamaño para el ancho de página y sin título interno): lee los CSV de 08a, 09b, 09c, 09d, 09f y 09g y no recalcula nada. Las figuras originales de esos scripts se conservan.

## Fase F: análisis posteriores a la retroalimentación final

`RF` = `output/etapa4/retro_final/` (todo de `scripts/10_analisis_retro_final.R`). Son posteriores a la evaluación de la prueba; las decisiones de A2, B y C se tomaron antes con el entrenamiento (`RF/decisiones_entrenamiento.csv`, `RF/log_10_solo_entrenamiento.txt`).

| Cifra | Valor en el informe | Fuente |
|---|---|---|
| Frase central (Resumen, 6.1, 7): ΔAUC entre 0.071 (logística) y 0.079 (LDA) | 0.0711; 0.0786 | `RF/metricas_lda_logistica.csv`; IC en `RF/ic_lda_logistica.csv` (LDA [0.054, 0.104]; logística [0.047, 0.095]) |
| Tabla 6: logística M0 / M1: AUC 0.721 / 0.792; EB 0.631 / 0.711; sensibilidad 0.580 / 0.739; especificidad 0.682 / 0.684; Brier 0.170 / 0.153; ΔEB 0.080 [0.054, 0.103] | — | `RF/metricas_lda_logistica.csv`, `RF/ic_lda_logistica.csv` |
| Detección M0 56 % (LDA) o 58 % (logística); M1 74 % | 0.565; 0.580; 0.742 / 0.739 | `RF/metricas_lda_logistica.csv` |
| 5.5: OR por 1 DE (rapidez 0.49 [0.39, 0.62]; presión 0.58 [0.49, 0.70]; temperatura 1.78 [1.24, 2.71]; lluvia 0.81 [0.64, 0.93]; radiación 0.82 [0.67, 1.00]); 1 DE = 0.85 m/s, 3.5 mm Hg, 6.3 °C, 1.1 h, 0.08 kW/m² | radiación: 97.3 % de réplicas con el mismo signo | `RF/a1_odds_ratios_logistica.csv` (`odds_ratio`, `or_li`, `or_ls`, `pct_mismo_signo`, `de_natural`); 1 000 réplicas válidas |
| 5.5: las 8 meteorológicas con el signo del LDA | — | `RF/a1_odds_ratios_logistica.csv` (`coincide_signo_lda`) |
| 5.5: caída del AUC por permutación: temporada 0.138, estación 0.067, presión 0.051, rapidez 0.038, temperatura 0.032; las demás < 0.01 | lluvia 0.0084; viento en conjunto 0.034 | `RF/a1_importancia_permutacion.csv` (fila «Logística», 200 permutaciones) |
| 5.5: grados de libertad efectivos 5.4 a 8.4; lluvia 1.6 | RH 5.35 … TOUT 8.40; 1.59 | `RF/a2_gam_edf.csv` |
| 5.5: temperatura crece más rápido arriba de 28 °C, rapidez se aplana arriba de 3 m/s, humedad cae arriba de 70 %, presión casi lineal | lectura de la Figura 8 | `RF/a2_gam_curvas.csv`, `RF/a2_logits_empiricos.csv` |
| 5.5: splines +0.006 (2022) y +0.021 (2023); regla ≥ 0.005 | 0.0056; 0.0214 | `RF/a2_auc_pliegues.csv`; `RF/decisiones_entrenamiento.csv` |
| 5.5: AUC con splines 0.811; ΔAUC 0.090 [0.060, 0.120] frente a 0.071; Tabla 18, última fila | 0.8111; 0.0900 | `RF/a2_dauc_splines_prueba.csv`; `RF/a2_auc_lineal_splines.csv` (fila `prueba`) |
| 5.5: «llovió» no agrega | +0.0002 y −0.00004 en validación | `RF/a2_auc_pliegues.csv` (`dif_llovio`) |
| 5.7: bloques por temporada 22 / 14 / 17; IC estratificado LDA [0.056, 0.101], logística [0.050, 0.091] | — | `RF/d_bootstrap_estratificado.csv` |
| 6.1: 1 799 días-estación, 733 episodios, mediana 2, máximo 16, 47 % de un día; M1 72 % y primer día 66 %; M0 49 % | 47.1; 72.4; 65.6; 49.0 | `RF/e_episodios_resumen.csv` (fila «PM2.5 > 25»); episodios en `RF/e_episodios.csv` |
| 6.1: 349 días-estación con PM2.5 > 40 en 219 rachas; M1 90 %, M0 77 % | 90.0; 77.2 | `RF/e_episodios_resumen.csv` (fila «PM2.5 > 40») |
| 6.5: 10 345 y 6 280 días con persistencia; 26.3 % | 26.3; 26.3 | `RF/b_persistencia_muestra.csv` |
| 6.5: escala original (el log no mejora en los dos pliegues) | +0.0030 y −0.0002 | `RF/b_escala_persistencia_pliegues.csv`; `RF/decisiones_entrenamiento.csv` |
| Tabla 7: AUC de M0, M1, MP y MP1; M1 − MP = −0.080 [−0.103, −0.055]; MP1 − MP = 0.016 [0.008, 0.025] | — | `RF/b_persistencia_auc.csv`, `RF/b_persistencia_dauc.csv` (se leen al renderizar) |
| 6.6: cortes 0.182 / 0.192 (vigilancia), 0.262 / 0.267 (equilibrio), 0.259 (actual) | — | `RF/decisiones_entrenamiento.csv`; desempeño en los pliegues en `RF/c_cortes_en_pliegues.csv` |
| Tabla 8 y texto: vigilancia del LDA 84 % de detección, 54 % de días marcados, 1.46 falsas alarmas por detección; equilibrio 74 % y 1.20; exactitud balanceada 0.70–0.71 | 0.839; 54.0; 1.46; 0.738; 1.20 | `RF/c_cortes_en_prueba.csv` (se lee al renderizar) |
| Figura 9 (métricas por corte) | — | `RF/c_metricas_por_corte.csv` |
| Tabla 3: causas (a)–(e) y respuesta por grupo | (a) 4 346, 18.3 %; superación (b) 27.0, (c) 23.5, (d) 33.3, (e) 29.5 | `RF/f1_causas_total.csv`, `RF/f2_respuesta_por_grupo.csv` (se leen al renderizar) |
| 4.5: NO2 9.8 % en (b) y 22.7 % en (c); 10.0 % (etapa 3) y 18.4 % (final) | — | `RF/f2_respuesta_por_estacion.csv`; `RF/f2_superacion_etapa3_etapa4.csv` (de `E4/dias_superacion_por_estacion.csv`) |
| 4.5: días (a) en NO 57 %, NE2 33 %, SUR 26 %; 2024 24 % y 2025 30 % frente a 10–15 % en 2021–2023; temporadas 17 % a 20 % | 57.3; 33.3; 25.6; 23.5; 30.3; 9.9–15.3; 17.2–19.6 | `RF/f1_causas_por_estacion_temporada_anio.csv` (se lee al renderizar en la Tabla 14) |
| 4.5: hueco de 532 días en NO desde marzo de 2024; la mitad de los días (a) en huecos de más de una semana | 532 (inicio 2024-03-09); 50.2 % | `RF/f3_rachas_mas_largas.csv`; `RF/f3_rachas_sin_respuesta.csv` |
| 4.5: PM10 en el 86 % de los días (a); menor que con respuesta en 31 de 39 combinaciones de estación y temporada | 86.1; 31 / 39 (mediana de la diferencia −6.1 µg/m³) | `RF/f3_pm10_dias_sin_respuesta.csv`; `RF/f3_pm10_resumen_estacion_temporada.csv` |
| Tabla 14 (causas por estación, temporada y año) | — | `RF/f1_causas_por_estacion_temporada_anio.csv`, `RF/f2_respuesta_por_estacion.csv`, `RF/f2_respuesta_por_temporada.csv` (se leen al renderizar) |
| Tabla 4: Mohd Shafi'i y Juahir (2024), 8 estaciones de Malasia (2011–2021), discriminante con 90.5 % de asignación correcta; Saminathan y Malathy (2023), 12 estaciones de Pekín (2013–2017) | — | Resúmenes en Europe PMC (PMID 38904667) y PMC (PMC10289837), consultados el 22 de octubre de 2026 |
