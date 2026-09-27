# Diagnóstico de datos SIMA 2020–2025 (etapa 1, sin limpiar)

Generado por `scripts/02_importar_diagnosticar.R` el 2026-09-26. Huellas MD5 de los 6 Excel = inventario del 25-sep. Tablas y heatmaps en `output/diagnostico/`.

**Denominadores.** 87 hojas estación-año (15 estaciones; por año: 2020: 13, 2021: 14, 2022: 15, 2023: 15, 2024: 15, 2025: 15), 754,603 filas. Horas esperadas por variable = 762,792 (24 × días del año de cada hoja-año, incluye horas sin fila). Cobertura diaria: 87 hojas-año por variable.

**1. Fecha y resolución.** Todas las celdas de fecha son datetime nativo de Excel (754,603 de 754,603; ninguna texto). Sin zona horaria en el archivo (readxl la rotula UTC; es hora local ingenua). Nombre de columna: `Fecha y hora` (2020–24) y `date` (2025). **Resolución horaria, no diaria**: 99.98% de los saltos entre marcas son de 1 h, todas las marcas caen en punto y la mediana es de 24 filas/día; la nota de Etiquetas sobre «promedios diarios» no describe estos archivos. Sin marcas duplicadas ni filas fuera del año; orden creciente en las 87 hojas. Sin cambio de horario visible: no hay hora repetida ni ausente en abril/octubre y el centroide de SR 2020 es 12.74 h (dic–feb) vs 13.15 h (jun–ago), sin el salto de ~1 h que dejaría el horario de verano. Parece hora fija; confirmar con SIMA.

**2. Celdas no numéricas: 0** de 11,319,045 celdas de medición (ni texto ni banderas). No hay banderas en los archivos: una celda vacía no dice si fue falla, calibración o invalidación.

**3. Faltantes, rango y rachas** (faltante: % de 762,792 h esperadas; fuera de rango: % de horas presentes contra el rango de operación de ese año; rachas: horas en rachas ≥ 6 h idénticas y distintas de 0; última columna: hojas-año con ≥ 75 % de los días con ≥ 18 h válidas, por año 2020/…/2025, y total sobre 87).

| Variable | % falt. | % fuera rango | Negativos | Horas en rachas | Cobertura ≥75 % por año | Total |
|---|---|---|---|---|---|---|
| CO | 14.2 | 0.00 | 0 | 1,064 | 6 / 13 / 14 / 15 / 14 / 11 | 73 |
| NO | 17.6 | 0.05 | 0 | 10,965 | 3 / 11 / 14 / 15 / 14 / 12 | 69 |
| NO2 | 18.3 | 0.00 | 0 | 6,290 | 2 / 12 / 14 / 15 / 14 / 12 | 69 |
| NOX | 17.7 | 0.04 | 2 | 3,107 | 3 / 12 / 14 / 15 / 14 / 12 | 70 |
| O3 | 15.6 | 0.00 | 0 | 39 | 3 / 13 / 14 / 15 / 15 / 14 | 74 |
| PM10 | 5.7 | 0.00 | 0 | 105 | 12 / 14 / 14 / 15 / 15 / 14 | 84 |
| PM2.5 | 26.0 | 0.00 | 0 | 426 | 7 / 12 / 12 / 12 / 9 / 8 | 60 |
| PRS | 6.1 | 1.14 | 0 | 14,906 | 12 / 13 / 12 / 15 / 15 / 14 | 81 |
| RAINF | 5.8 | 0.00 | 1 | 86 | 11 / 12 / 14 / 15 / 15 / 14 | 81 |
| RH | 12.3 | 0.04 | 9 | 8,542 | 11 / 12 / 14 / 13 / 13 / 11 | 74 |
| SO2 | 15.9 | 0.00 | 0 | 11,869 | 6 / 9 / 12 / 15 / 14 / 13 | 69 |
| SR | 4.7 | 0.16 | 265 | 59,679 | 13 / 14 / 13 / 14 / 14 / 13 | 81 |
| TOUT | 7.9 | 0.07 | 1,625 | 0 | 12 / 12 / 14 / 15 / 13 / 13 | 79 |
| WSR | 7.9 | 0.24 | 1 | 73 | 9 / 11 / 14 / 14 / 15 / 15 | 78 |
| WDR | 9.3 | 0.00 | 1 | 0 | 7 / 10 / 13 / 15 / 15 / 15 | 75 |

Horas sin fila: 8,189 (1.07% de 762,792); 8,017 son de NO3 2022, que empieza el 2022-12-01 01:00.

**4. Consistencia.** |NOX − (NO + NO2)| > 1 ppb: 23,844 de 613,378 h comparables (3.89%); > 5 ppb: 1,158 (0.19%). PM2.5 > PM10: 37 de 555,259 h comparables (0.007%). Hojas-año sin ningún valor de PM2.5: 6 (hojas: NE3, NO3).

**5. Cobertura conjunta** (días con ≥ 18 h válidas en PM10, PM2.5, O3, NO2, CO, TOUT, RH, WSR y WDR a la vez, % de días del año): mediana por hoja-año 58%; 24 de 87 hojas-año ≥ 75%. Detalle en `cobertura_conjunta_dias.csv`.

**6. Heatmaps** de faltantes (estación × mes, 15 variables): `output/diagnostico/heatmaps/faltantes_<VAR>.png`. **Alertas de rango:** TOUT tiene 458 h bajo el mínimo del rango cuando ese mínimo es 0 (2020 y 2023; pueden ser temperaturas reales bajo cero); PRS concentra 8,172 h fuera de rango en pocas hojas-año (p. ej. NO2 2022: 3,085 h), consistente con un rango único para estaciones a distinta altitud.

**7. Tamaño estimado del CSV limpio** (escrito de prueba, 15 variables a 2 decimales): horario 754,603 filas ≈ **60 MB** (≈ 82 MB con una columna bandera por variable; año mayor ≈ 14 MB); diario 31,449 filas ≈ **4.2 MB**. Un solo CSV horario supera 50 MB: dividir por año o publicar solo el diario.


## Parte B. Limpieza y publicación

Generado por `scripts/03_limpiar.R` el 2026-09-26. Reglas completas en `data/clean/README.md`: rango duro (contaminantes: operación del año; meteorología: fabricante; RAINF: 0 al máximo de operación del año), notas del PDF, salto horario (TOUT/PRS), PM2.5 > PM10, rachas ≥ 24 h (marcadas desde 6 h) e imputación lineal de huecos ≤ 3 h, con revalidación posterior (un valor imputado que incumple rango, salto o PM2.5 ≤ PM10 vuelve a NA, bandera X; nunca se toca un original). Denominador de las tablas: 762,792 horas esperadas por variable (87 hojas-año).

| Variable | % falt. original | % invalidado | % imputado neto | Imputaciones revertidas (n) | % falt. final |
|---|---|---|---|---|---|
| CO | 14.2 | 0.02 | 0.60 | 0 | 13.7 |
| NO | 17.6 | 0.82 | 1.80 | 0 | 16.7 |
| NO2 | 18.3 | 0.67 | 1.18 | 0 | 17.7 |
| NOX | 17.7 | 0.19 | 1.17 | 0 | 16.7 |
| O3 | 15.6 | 0.00 | 1.20 | 0 | 14.4 |
| PM10 | 5.7 | 0.01 | 0.95 | 252 | 4.7 |
| PM2.5 | 26.0 | 0.02 | 2.88 | 3,599 | 23.2 |
| PRS | 6.1 | 0.41 | 0.80 | 54 | 5.7 |
| RAINF | 5.8 | 0.00 | 0.00 | 0 | 5.8 |
| RH | 12.3 | 0.04 | 0.64 | 0 | 11.7 |
| SO2 | 15.9 | 0.00 | 2.25 | 0 | 13.7 |
| SR | 4.7 | 0.14 | 0.34 | 0 | 4.5 |
| TOUT | 7.9 | 0.12 | 0.65 | 147 | 7.4 |
| WSR | 7.9 | 0.01 | 0.00 | 0 | 7.9 |
| WDR | 9.3 | 0.00 | 0.00 | 0 | 9.3 |
| viento_uv | 12.5 | 0.01 | 1.08 | 0 | 11.4 |

**Núcleos (días estación completos, 2021–2025, sobre 27,025 días).** Núcleo A (PM10, O3 máx. 8 h, NO2, CO, SO2, TOUT, RH, SR, viento, PRS, RAINF): 17,920 (66.3%). Núcleo B (A + PM2.5, conjunto principal de modelado): 14,675 (54.3%). Por estación, B va de 1% (NE3) a 82% (SE3); NE3 y NO3 casi nunca completan B. `sima_diario_2020_2025.csv` trae `en_nucleo_A`, `en_nucleo_B` y `en_periodo_modelado`.

**NOX.** Horas con |NOX − (NO + NO2)| > max(1 ppb, 10% de NOX), sobre las horas comparables de cada estación, con los valores finales publicados (incluye imputados): NE3 11.50% (de 41,076); NTE2 8.45% (de 43,573); CE 1.87% (de 48,550); NTE 0.94% (de 40,744); NO 0.79% (de 40,308). El resto de estaciones queda bajo 0.5%.

**Sensibilidad.** Con el rango de operación estricto se habrían eliminado 88 horas de TOUT (0.013% de 701,213) y 7,895 de PRS (1.11% de 713,116).

**RAINF.** 32 horas sobre el máximo de operación del año se invalidaron (bandera F). Con lo que queda: 1.56% de 718,811 horas válidas tienen lluvia > 0; valor positivo más frecuente 0.01. La cantidad no se usa (unidad sin confirmar); el diario publica `horas_lluvia` y `llovio`.

**Tamaños.** diario_2020_2025 5.5 MB, horario_limpio_2020 13.2 MB, horario_limpio_2021 15.8 MB, horario_limpio_2022 17.0 MB, horario_limpio_2023 17.3 MB, horario_limpio_2024 17.3 MB, horario_limpio_2025 16.9 MB; máximo por archivo 17.3 MB (límite 50 MB). Diario: 31,783 filas × 40 columnas.
