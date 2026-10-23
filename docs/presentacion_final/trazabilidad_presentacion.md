# Trazabilidad de las cifras de la presentación final

Cada cifra de las 12 diapositivas (y de las notas del orador) con su archivo de origen. Rutas relativas a la raíz del repositorio; `E4` = `output/etapa4/`, `RF` = `output/etapa4/retro_final/`. Las cifras del informe (`quarto/etapa4_informe_final.qmd`) se rastrean en `docs/etapa4/trazabilidad_cifras.md`; aquí solo se repite el archivo de origen. Redondeo: igual que el informe (3 decimales en AUC y ΔAUC, 1 decimal en porcentajes); los porcentajes enteros de las tarjetas y de las notas son el redondeo del valor del CSV.

Todas las figuras se regeneran con `scripts/11_figuras_presentacion.R` (lee los CSV de abajo; no ajusta ningún modelo) y quedan en `docs/presentacion_final/figuras/`.

## Diapositiva 1. Portada

| Dato | Origen |
|---|---|
| Título (la pregunta) | `quarto/etapa4_informe_final.qmd` (título) y la instrucción de la presentación |
| Reto SIMA · Equipo 1 · Grupo 201 · MA2003B; socio formador SIMA y Agencia de Calidad del Aire de Nuevo León | instrucción de la presentación (sin matrículas) |
| Nombres de los cuatro integrantes | `quarto/etapa2.qmd` (línea de autores) y `quarto/etapa4_informe_final.qmd` |

## Diapositiva 2. Problema y pregunta

| Cifra | Valor | Origen |
|---|---|---|
| Metaanálisis de 196 artículos | 196 | `docs/etapa4/trazabilidad_cifras.md` (Orellano et al., 2020; `docs/etapa1/texto_etapa1_final.md`) |
| Límite diario de 25 µg/m³, NOM-025 | 25 | `docs/etapa4/trazabilidad_cifras.md` (Secretaría de Salud, 2021) |
| M0 = estación + temporada; M1 = M0 + meteorología del día; mejora = AUC(M1) − AUC(M0) | — | `docs/etapa4/decisiones_etapa4.md`; `R/modelo_etapa4.R` |
| Evaluación en 2024–2025 | — | `E4/prueba_v2_sensibilidades.csv` (`n`, años de la prueba); `E4/registro_prueba_v2.txt` |
| Utilidad para SIMA: paso previo a una alerta con pronóstico | — | `docs/etapa4/retroalimentacion_final.md` (R2, SIMA); informe, «Justificación para SIMA» |

## Diapositiva 3. Área de estudio

| Cifra | Valor | Origen |
|---|---|---|
| Porcentaje de días con superación por estación (número del círculo) | CE 35, NE 29, NE2 31, NO 32, NO2 18, NTE 15, NTE2 23, SE 15, SE2 46, SE3 19, SO 44, SO2 19, SUR 11 | `E4/area_estudio/mapa_estaciones_altitud.csv` (`pct_superacion_v2`) |
| Altitud (etiqueta) | NO2 702 … SE3 334 m | `E4/area_estudio/mapa_estaciones_altitud.csv` (`altitud_msnm`) |
| Posición de las estaciones | latitud y longitud | mismo archivo; mapa regenerado en `scripts/11_figuras_presentacion.R` (bloque 2) |
| SE2 46 % y SO 44 % | 46.1; 43.8 | mismo archivo |
| Flujo del este en 11 de 13 estaciones, 80–98 % de los días | 80.3–98.1 (NE2 62.3 y SO2 68.4 son las otras dos) | `E4/descriptivos/viento_por_estacion.csv` (`pct_dias_flujo_del_este`) |
| Contexto de SE2 (pluma de la refinería) y de SO (zona industrial, salida del viento) | — | `docs/etapa4/retroalimentacion_final.md` (R2, SIMA); se cita como comunicación personal |
| SE2 con el viento más débil, 1.55 m/s (solo en notas y banco de preguntas) | 1.550 | `E4/descriptivos/viento_por_estacion.csv` (`rapidez_media`) |

## Diapositiva 4. Datos y exploración

| Cifra | Valor | Origen |
|---|---|---|
| 17 828 días-estación | 17 828 | `E4/tabla_puente.csv`, paso 4 (`n_entrena` 10 965 + `n_prueba` 6 863) |
| 13 estaciones; 8 variables meteorológicas | — | `E4/area_estudio/mapa_estaciones_altitud.csv`; `data/clean/v2/diario_v2_imputado_2021_2025.csv` (columnas) |
| Superación por temporada: 36.9 % (nov–feb), 35.0 % (mar–may), 11.7 % (jun–oct) | 36.9; 35.0; 11.7 | **Calculado en `scripts/11_figuras_presentacion.R` (bloque 3)** sobre `data/clean/v2/diario_v2_imputado_2021_2025.csv` con la muestra del análisis final (el script verifica que sean exactamente 17 828 filas). No está en ningún CSV de `output/` ni en el informe |
| Diferencia de temperatura media, superación − sin superación: −0.3 °C (todos juntos), +2.0, +3.3 y +0.8 °C por temporada | −0.294; 1.999 (nov–feb); 3.315 (mar–may); 0.770 (jun–oct) | **Calculado en el mismo bloque** y misma muestra; no está en el informe. Apoya el hallazgo ya publicado: correlación de estructura de la temperatura −0.07 (`E4/lda/estabilidad_coeficientes.csv`) |

## Diapositiva 5. Datos faltantes

| Cifra | Valor | Origen |
|---|---|---|
| Faltaba el 12.3 %; 26 % del PM2.5 | 12.34; 26.03 | `data/clean/tabla_informe_limpieza.csv` |
| Invalidado 0.7 % | 0.715 | `data/clean/tabla_informe_limpieza.csv` |
| Apagones largos (sobre todo) | 51–82 % de las horas faltantes están en huecos de más de un día | `E4/errores/largo_huecos_horarios.csv` |
| Respuesta con ≥ 18 h observadas, no se imputa | 18 | D18 en `docs/etapa4/decisiones_etapa4.md` |
| imputeTS: descomposición estacional (`seadec`), Kalman, lineal, Stineman según variable y hueco | — | D19; `E4/imputacion/eleccion_metodo_horario.csv` |
| Mediana de la red ajustada frente a MICE: 0.450 frente a 0.593 | 0.4500; 0.5932 | `E4/imputacion/eleccion_metodo_diario.csv` |
| +2 438 días | 17 828 − 15 390 | `E4/imputacion/perdidas_v12_v2.csv` (15 390 casos completos v1.2) y `E4/tabla_puente.csv` |
| García (NO2) de 511 a 1 532 días | 511; 1 532 | `E4/imputacion/dias_por_estacion_anio_v12_v2.csv`; `RF/f2_superacion_etapa3_etapa4.csv` (`dias_v12`, `dias_v2`) |
| MIMA-v1 no se comparó (sin acceso a su dataset imputado; imputa la respuesta) | — | `docs/etapa4/decisiones_etapa4.md`, «Fase E»; `docs/etapa4/trazabilidad_cifras.md` (MIMA-v1) |

## Diapositiva 6. Ruta de análisis

| Cifra | Valor | Origen |
|---|---|---|
| 22 predictores (14 indicadoras + 8 meteorológicas) | 22 | `E4/lda/estabilidad_coeficientes.csv`; `R/modelo_etapa4.R`; `docs/etapa4/trazabilidad_cifras.md` |
| Referencias CE y cálida-húmeda (solo notas) | — | `R/modelo_etapa4.R`; informe, Sección 5 |
| Entrena 2021–2023, prueba 2024–2025 | — | `E4/prueba_v2_sensibilidades.csv`; `E4/registro_prueba_v2.txt` |
| Bloques de 14 días, 1 000 réplicas | 14; 1 000 | `scripts/09a_evaluar_prueba_v2.R` (`N_REPLICAS`); `R/modelo_etapa4.R` |
| Interdependencia (PCA) y dependencia (LDA, logística) | — | Clasificación del curso aplicada en el informe, Sección 5 |

## Diapositiva 7. PCA

| Cifra | Valor | Origen |
|---|---|---|
| 66.5 % de varianza en 3 ejes | 66.46 | `E4/pca/pca_v2_resumen.csv` (`varianza_acum_3`); informe «66.5 %» |
| 36, 17 y 13 % | 35.80; 17.48; 13.18 | `E4/pca/pca_v2_valores_propios.csv` |
| Cargas (celdas de la figura) | — | `E4/pca/pca_v2_cargas.csv` |
| KMO 0.64 (solo notas) | 0.635 | `E4/pca/pca_v2_resumen.csv` |
| Nombres de los ejes («calor y radiación», «humedad y flujo del este», «presión baja y lluvia») | — | **Lectura propia de las cargas** (no están en el informe). PC1: temperatura 0.84, radiación 0.82, rapidez 0.68; PC2: humedad 0.61, u −0.63, v 0.51; PC3: presión −0.67, lluvia 0.38 |
| PC1 mezcla temperatura y viento con efectos opuestos | — | Informe, Sección 5 (PCA) y 6.3 |

## Diapositiva 8. Resultado principal

| Cifra | Valor | Origen |
|---|---|---|
| AUC LDA M0 → M1 | 0.713 → 0.792 | `E4/prueba_v2_metricas_m0_m1.csv`; `RF/metricas_lda_logistica.csv` |
| AUC logística M0 → M1 | 0.721 → 0.792 | `RF/metricas_lda_logistica.csv` |
| ΔAUC LDA | 0.079 [0.054, 0.104] | `E4/prueba_v2_sensibilidades.csv`, fila 1; `RF/ic_lda_logistica.csv` |
| ΔAUC logística | 0.071 [0.047, 0.095] | `E4/prueba_v2_sensibilidades.csv` (robustez logística); `RF/ic_lda_logistica.csv` |
| Detección 56 % → 74 % | 0.565 → 0.742 | `E4/prueba_v2_metricas_m0_m1.csv` (`sensibilidad`) |
| Especificidad 0.70 → 0.68 (notas) | 0.703 → 0.680 | `E4/prueba_v2_metricas_m0_m1.csv` |
| Curvas ROC y círculos en el corte 0.259 | — | `E4/prueba_v2_predicciones.csv` (`p_M0`, `p_M1`, `supera_25`); el script verifica que el AUC coincida con `prueba_v2_metricas_m0_m1.csv` |
| Corte 0.259 | 0.2589 | `E4/prueba_v2_sensibilidades.csv` (`prevalencia_entrena`) |
| Título «de 0.71 a 0.79» | 0.713; 0.792 | `E4/prueba_v2_metricas_m0_m1.csv` |

## Diapositiva 9. ¿Cuándo y con qué ayuda?

| Cifra | Valor | Origen |
|---|---|---|
| ΔAUC mar–may | 0.151 [0.102, 0.193] | `E4/prueba_v2_dauc_por_temporada.csv` |
| ΔAUC nov–feb | 0.069 [0.037, 0.100] | mismo archivo |
| ΔAUC lluvias | 0.039 [−0.018, 0.104] | mismo archivo |
| Todo el periodo | 0.079 [0.054, 0.104] | `E4/prueba_v2_sensibilidades.csv`, fila 1 |
| 9.7 % de superación en lluvias (notas) | 9.7 | `E4/prueba_v2_dauc_por_temporada.csv` (`prevalencia`) |
| Odds ratio por 1 DE: viento 0.49 [0.39, 0.62]; presión 0.58 [0.49, 0.70]; temperatura 1.78 [1.24, 2.71]; radiación 0.82 [0.67, 1.00]; lluvia 0.81 [0.64, 0.93] | — | `RF/a1_odds_ratios_logistica.csv` (`odds_ratio`, `or_li`, `or_ls`; solo `signo_estable` = TRUE). El IC de la radiación llega a 1.00 (1.0016); la figura la muestra en gris, como las de menor peso |
| «Se asocia, no causa»; humedad, u y v sin signo estable | — | `RF/a1_odds_ratios_logistica.csv`; `E4/lda/estabilidad_coeficientes.csv` |

## Diapositiva 10. Persistencia y umbral

| Cifra | Valor | Origen |
|---|---|---|
| AUC con PM2.5 de ayer (LDA): M0 0.712, M1 0.792, MP 0.872, MP1 0.887 | 0.7124; 0.7918; 0.8716; 0.887 | `RF/b_persistencia_auc.csv` |
| n = 6 280 (días-estación de la prueba con PM2.5 de ayer) | 6 280 | `RF/RESUMEN.md`, sección B (`n_con_persistencia`) |
| M1 − MP = −0.080 [−0.103, −0.055] (en la tarjeta: «MP − M1 = 0.080») | −0.0798 | `RF/b_persistencia_dauc.csv` (LDA) |
| MP1 − MP = +0.016 [0.008, 0.025] | 0.0159 [0.0077, 0.0248] | `RF/b_persistencia_dauc.csv` (LDA) |
| Corte de vigilancia 0.182 (sensibilidad ≥ 0.80 en 2022–2023) | 0.1822 | `RF/decisiones_entrenamiento.csv`; `docs/etapa4/decisiones_etapa4.md` (fase F, C) |
| Curvas de sensibilidad, especificidad y VPP | — | `RF/c_metricas_por_corte.csv` (LDA) |
| En la prueba, con 0.182: sensibilidad 0.84, especificidad 0.57, VPP 0.41 | 0.839; 0.566; 0.407 | `RF/c_cortes_en_prueba.csv` |
| 1.46 falsas alarmas por detección; 54 % de los días marcados | 1.457; 54.0 | `RF/c_cortes_en_prueba.csv` |
| Corte de equilibrio 0.262: 74 % detectado, 1.20 falsas, 43 % marcado (notas) | 0.738; 1.204; 42.6 | `RF/c_cortes_en_prueba.csv` |

## Diapositiva 11. Supuestos y límites

| Cifra | Valor | Origen |
|---|---|---|
| Mardia y M de Box: no se cumplen | χ² 99 015 y 198 072 (gl 120); χ² 3 213 (gl 36) | `E4/errores/supuestos_normalidad_mardia.csv`; `E4/errores/supuestos_box_m.csv` |
| Autocorrelación de los residuos de M1 a un día: 0.42 | 0.422 | `E4/errores/acf_promedio_y_residuos.csv` |
| Prueba ya usada en etapas previas | — | `docs/etapa4/retroalimentacion_final.md` (R1); informe, Sección 5.4 |
| 189 días sin clima, 33.3 % frente a 27.0 % | 189; 33.3; 27.0 | `RF/f2_respuesta_por_grupo.csv` (grupos d y b) |
| Sensibilidades de 0.071 a 0.082 | 0.0711–0.0820 | `E4/prueba_v2_sensibilidades.csv` y `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` |
| Retrospectivo: el error del pronóstico reduciría la mejora | — | Informe, «Limitaciones» (1) |
| QDA 0.788 (solo notas) | 0.788 | `E4/lda/qda_vs_lda.csv` |

## Diapositiva 12. Conclusión y recomendaciones

| Cifra | Valor | Origen |
|---|---|---|
| 0.713 → 0.792; +0.079 [0.054, 0.104]; 56 % → 74 % | — | ver diapositiva 8 |
| Variantes de 0.071 a 0.082 (notas) | — | ver diapositiva 11 |
| Débil: lluvias, retrospectivo, probabilidades sin calibrar (pendiente 0.82), PM2.5 de ayer predice más | 0.822; 0.872 | `E4/lda/calibracion_recalibracion.csv`; `RF/b_persistencia_auc.csv` |
| Recomendaciones: pronóstico; reglas de control de calidad (radiación de madrugada, viento contra la red); sensores (radiación de NO2 y NTE; PM2.5 de NO2 de 2023 a 2025) | — | Informe, «Recomendaciones para SIMA»; `E4/descriptivos/sr_media_por_estacion.csv` (SR media NO2 0.015, NTE 0.041); `E4/descriptivos/periodos_pm25_bajo_con_pm10_normal.csv` |
| Repositorio `github.com/Leo-issacs/reto-sima-multivariados`, etiqueta `entrega-final`; código QR | `https://github.com/Leo-issacs/reto-sima-multivariados/tree/entrega-final` | `git remote -v`. La etiqueta anotada `entrega-final` se crea sobre el commit de fusión del PR #12 en main, que contiene la fase F (diapositiva 10) y esta presentación; verificada con `git ls-remote --tags origin`. El QR (`ppt/media/image-12-1.png`) se generó con `segno` (versión 5, corrección M) y se comprobó con un lector de QR (`pyzbar`) en la imagen y en el PDF exportado. `informe-final` (`2b2954e`) es la versión previa a la retroalimentación del 22 de octubre |

## Cifras solo de las notas y del banco de preguntas

| Cifra | Origen |
|---|---|
| Bloques de 7 y 28 días: [0.054, 0.103] y [0.045, 0.110] | `E4/prueba_v2_sensibilidades.csv` |
| Exactitud balanceada 0.634 → 0.711; Brier 0.172 → 0.154 | `E4/prueba_v2_metricas_m0_m1.csv` |
| Pérdida por no imputar la respuesta: 526; interpolación ≤ 3 h da 0.079 | `E4/imputacion/perdidas_v12_v2.csv`; `E4/prueba_v2_sensibilidades.csv` |
| Rachas sin PM2.5 de hasta 532 días; 18.3 % de días-estación sin PM2.5 suficiente | `RF/f3_rachas_mas_largas.csv`; `RF/f1_causas_total.csv` |
| Sensibilidad en lluvias: M1 0.298, M0 0.364 | `E4/errores/errores_por_temporada.csv`; `E4/RESUMEN_FASE_D.md`, sección 1 |
| MICE ΔAUC 0.078 | `E4/prueba_v2_sensibilidades.csv` |
| Episodios: 1 799 días-estación, 733 episodios, mediana 2 días, 47.1 % de un día; M1 detecta 72.4 % (M0 49.0 %); primer día 65.6 % (M0 49.0 %); > 40 µg/m³: 349 días-estación, 219 episodios, 90.0 % | `RF/e_episodios_resumen.csv` |
| Reubicaciones: 1 375 días excluidos; lista de SIMA da 0.081; presión confirma SUR | `RF/RESUMEN.md` (F1, e); `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv`; `E4/area_estudio/prs_antes_despues_reubicacion.csv` |
| NO2: 0 superaciones en 2024; sin NO2 ΔAUC 0.082 | `E4/RESUMEN_ETAPA4.md` (sección 4.1); `E4/sensibilidades_posteriores/sensibilidades_posteriores.csv` |
| PCs como predictores 0.064 (etapa 3) frente a 0.070 | `output/etapa3/prueba_sensibilidades.csv` |

## Lo que no se pudo trazar a un archivo ya existente

Ninguna cifra queda sin origen. Hay tres tipos de caso que conviene saber:

1. **Calculadas por primera vez en el script 11** (diapositiva 4): la superación por temporada (36.9, 35.0, 11.7 %) y las diferencias de temperatura (−0.3, +2.0, +3.3, +0.8 °C). Son reproducibles con `scripts/11_figuras_presentacion.R` pero no aparecen en el informe ni en los CSV previos.
2. **Interpretación propia, no cifra:** los nombres de los tres ejes del PCA.
3. **Redondeo distinto del enunciado:** la varianza acumulada del PCA es 66.46 %, que el informe da como **66.5 %** y la presentación escribe igual (el enunciado decía «67 %»).
