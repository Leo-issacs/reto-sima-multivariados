# Datos limpios SIMA 2020–2025

**Fuente:** Sistema Integral de Monitoreo Ambiental de Nuevo León (SIMA), libros `BD 2020.xlsx` … `BD 2025.xlsx` (6 archivos, 87 hojas estación-año, 15 estaciones). Metadatos: `Etiquetas.xlsx`, `Rangos de los parámetros del SIMA.pdf`, `Ubicación de las estaciones de monitoreo.docx`.
**Se reproduce con:** `SIMA_DATA_DIR="<carpeta con los Excel>" Rscript scripts/03_limpiar.R` (verifica las huellas MD5 de `data/metadata/inventario_archivos_inicial.csv`; requiere `renv::restore()`, incluye `imputeTS`).
**Generado el:** 2026-09-26. Los Excel originales no se modifican ni se publican.

## Archivos

| Archivo | Contenido |
|---|---|
| `sima_horario_limpio_AAAA.csv` | Una fila por estación-hora de la malla completa del año (24 × días; las horas sin fila en el Excel aparecen con todo vacío), 15 variables + viento u/v + una bandera por variable. Un archivo por año (< 18 MB cada uno). |
| `sima_diario_2020_2025.csv` | Una fila por estación-día. Base para PCA/conglomerados; trae `en_nucleo_A`, `en_nucleo_B` y `en_periodo_modelado` (ver más abajo). |
| `cobertura_dias_validos_hoja_anio.csv` | % de días válidos (≥ 18 h) por hoja-año × variable, con `cobertura_baja` = 1 si < 75 %. |
| `tabla_informe_limpieza.csv` | Por variable: % faltante original, % invalidado por regla, % imputado y % final, con denominador. |
| `DICCIONARIO.csv` | Columnas, unidades y reglas. |

No se elimina ninguna hoja-año, estación ni el año 2020. El modelado principal usa el **núcleo B** (`en_nucleo_B == 1`) en **2021–2025** (`en_periodo_modelado == 1`); el núcleo A es la sensibilidad. NE3 y NO3 se conservan, pero casi nunca completan B. Detalle de días completos: `output/diagnostico/dias_completos_nucleo.csv`.

## Validación

`scripts/04_validar_limpios.R` (se corre al final de `03_limpiar.R`) falla si en los CSV horarios hay PM2.5 > PM10, valores fuera del rango de su año (o de las notas del PDF) una terna NO/NO2/NOX completa con `nox_inconsistente` vacía, TOUT en el límite del sensor, una hora anulada por E/L reincorporada por imputación o un valor de TOUT/RH a más de 10 °C / 40 pp de la mediana de la red observada (con ≥ 5 estaciones). `scripts/05_probar_limpieza.R` prueba las reglas con datos sintéticos.

## Reglas, en este orden (cada hora de cada variable queda con una bandera)

1. **F, rango duro.** Contaminantes: rango de operación **del año** (ambos límites). Meteorología: rango del **fabricante** (TOUT −50 a 50 °C, PRS 449.9–824.9 mm Hg, RH 0–100, WSR 0–180 km/h, SR 0–1.4 kW/m², WDR 0–360; RAINF: de 0 al **máximo de operación del año**, porque el rango del fabricante no es numérico).
2. **P, notas del PDF**, solo en su año: 2020 O3 se omite el máximo **original** de NTE2 (identificado antes de aplicar F: si ya cae fuera de rango, F lo elimina y no se quita ningún otro valor); 2020 WSR > 75; SR > 1 en 2020 y 2021; 2020 PRS fuera de 690–750.
3. **L, límite del instrumento (TOUT).** Se invalidan las lecturas de TOUT próximas al límite del fabricante (|TOUT| ≥ 49.9 °C), excluidas por sospecha de saturación o fallo del sensor; encontrar un valor en el extremo no identifica por sí solo la causa técnica. Las 25 observaciones afectadas son de NTE, entre el 27 de marzo y el 30 de abril de 2020. Aplicar la regla también al extremo positivo (≥ 49.9 °C) es una decisión preventiva: no hay casos en ese extremo.
4. **S, salto horario** (bandera `h` de SIMA): |ΔTOUT| > 10 °C o |ΔPRS| > 10 mm Hg respecto de la hora previa; se invalida la hora que salta.
5. **R, PM2.5 > PM10** (bandera `r` de SIMA): se invalidan ambas.
6. **K / C, rachas de valores idénticos.** Toda racha ≥ 6 h queda marcada `C` (excepto ceros de SR y RAINF, que son noche y horas secas). Solo se invalidan (`K`) las de ≥ 24 h en contaminantes, TOUT, PRS y RH (RH = 100 no se invalida). SR, RAINF, WSR y WDR nunca se invalidan por racha.
7. **E, consistencia espacial** (prueba *buddy check*, Fiebrich et al., 2010). Sobre los datos **observados** y antes de imputar, se invalida TOUT cuando |TOUT − mediana de la red a esa hora| > 10 °C y RH cuando |RH − mediana| > 40 puntos porcentuales, solo en horas con ≥ 5 estaciones reportando. La mediana se calcula con las lecturas que sobrevivieron a las reglas anteriores y la prueba se repite hasta que no quedan más violaciones (así las lecturas observadas que quedan cumplen la regla respecto de su propia mediana). **Una lectura atípica frente a la red es sospechosa, no necesariamente errónea; los umbrales son decisión del equipo, justificada por la distribución de desviaciones, la plausibilidad física y un análisis de sensibilidad (8/10/15 °C; 30/40/50 pp).** Las horas anuladas por E (o por L) **no se imputan nunca**, aunque al excluirlas queden menos de 5 estaciones; `f_obs_TOUT` y `f_obs_RH` conservan la causa observada para poder comprobarlo. Detalle, histograma y criterio en `notebooks/01_auditoria_datos_crudos.qmd` (bloques 10 y 10b); sensibilidad en `output/diagnostico/sensibilidad_consistencia_espacial.csv`. Los conteos dependen de la base:

   | Base sobre la que se calcula (≥ 5 estaciones por hora; diferencia absoluta respecto de la mediana de la red) | TOUT > 10 °C | TOUT > 15 °C | RH > 40 pp |
   |---|---:|---:|---:|
   | Excel **originales** importados, antes de limpiar (sin imputaciones) | 1,082 | 901 | 4,104 |
   | Base `datos-v1.0` (CSV limpios anteriores, **incluye valores imputados**) | 614 | 392 | 4,251 |
   | Observaciones tras las reglas previas (F, P, L, S, R, K), **primera pasada de E** (base de esta versión) | 447 | 299 | 4,068 |

   Con la repetición hasta estabilizar, E excluye **450 lecturas de TOUT y 4,120 de RH**: esas son las cifras de la limpieza; las de una pasada son solo de sensibilidad. En `datos-v1.0`, de las 614 desviaciones de TOUT, 143 eran valores imputados; de las 4,251 de RH, 183 imputadas y 4,068 observadas (descomposición de la revisión del PR #7; recalculada la suma de cada base con el importador del proyecto). El cuaderno de auditoría se ejecuta sobre los Excel originales (primera fila); no reproduce la limpieza.
8. **NOX:** no se invalida. `nox_inconsistente` = 1 si |NOX − (NO + NO2)| > max(1 ppb, 10 % de NOX): el piso de 1 ppb evita marcar diferencias menores a la resolución del analizador. Se calcula sobre los **valores finales** publicados (tras imputar y revertir) en toda hora con NO, NO2 y NOX presentes; vacía solo si falta alguna.
9. **Viento:** `viento_u = −WSR/3.6·sin(WDR)`, `viento_v = −WSR/3.6·cos(WDR)` en m/s (requiere WSR y WDR válidas). WSR y WDR se publican validadas y sin imputar.
10. **I, imputación**: solo huecos internos de ≤ 3 h consecutivas, interpolación lineal (`imputeTS::na_interpolation(maxgap = 3)`), por estación y variable, sobre la serie continua 2020–2025 de la estación y antes del agregado diario. Se imputan contaminantes, TOUT, RH, SR, PRS y u/v; **no** RAINF ni WSR/WDR. Sin imputación por media. **Revalidación posterior:** después de interpolar se vuelven a aplicar el rango del año de cada hora (contaminantes: operación; meteorología: fabricante; notas del PDF), la saturación de TOUT, la consistencia espacial de TOUT y RH, el salto horario de TOUT y PRS con las horas vecinas y PM2.5 ≤ PM10. Un valor imputado que incumple una regla (incluida la consistencia espacial, contra la mediana de la red observada) vuelve a NA con bandera `X`; **nunca se modifica un valor original válido** (si PM2.5 imputada > PM10 original, se revierte la imputada; si ambas son imputadas, ambas). Se repite hasta que no haya más reversiones. Las horas anuladas por E o L quedan siempre vacías (no se imputan). En horas `I` y `X` se pierde el motivo original de invalidez (la tabla del informe sí lo separa y reporta el % imputado neto y las imputaciones revertidas).
11. Los valores extremos que superan todas las reglas anteriores se conservan.

**Duplicados:** no existen marcas duplicadas en los seis libros (verificado); el código conservaría el primer valor numérico de cada marca.

## Agregado diario

Valor diario solo con ≥ 18 h válidas de esa variable (incluidas imputadas); `n_horas_*` da el conteo. O3: máximo diario del promedio móvil de 8 h (≥ 6 de 8 horas). RAINF: `horas_lluvia` (horas con 0 < RAINF ≤ máximo de operación del año) y `llovio` (0/1); la cantidad **no se usa porque la unidad no está confirmada**. Viento: medias de u, v y de la rapidez. `temporada`: seca_fria (nov–feb), seca_calida (mar–may), calida_humeda (jun–oct) — definición operativa del equipo; nombres según Hernández-Romero et al. (2026); cortes según la climatología del PIGECA 2023–2033. `confinamiento_2020` = 1 del 2020-04-01 al 2020-05-31.

## Núcleos de modelado (columnas del diario)

- `en_nucleo_A` = 1 si el estación-día tiene ≥ 18 h válidas en PM10, O3 (máximo de 8 h), NO2, CO, SO2, TOUT, RH, SR, viento (u/v), PRS y RAINF (`horas_lluvia`).
- `en_nucleo_B` = A + PM2.5 (conjunto principal). NOX queda fuera de ambos núcleos y solo lleva bandera de inconsistencia.
- `en_periodo_modelado` = 1 si el año está entre 2021 y 2025.

## Advertencias

- **Zona horaria: hora local fija, sin cambio de horario visible (sin horas repetidas ni ausentes; sin salto de ~1 h en el ciclo de radiación solar). Confirmar con SIMA.**
- La resolución es **horaria**, no diaria (Etiquetas habla de "promedios diarios").
- Los Excel no traen banderas SIMA: una celda vacía no indica por qué falta.
- RAINF no se convirtió (la nota de Etiquetas `(valor × 0.25) × 100` no está confirmada) y su cantidad no se usa en el diario. Los valores sobre el máximo de operación del año se invalidan (bandera F); distribución en `output/diagnostico/rainf_distribucion.csv`.
- PRS: el rango de operación es único para toda la red y las estaciones están a distinta altitud; se usa el rango del fabricante. `output/diagnostico/sensibilidad_rango_TOUT_PRS.csv` reporta cuántas horas habría eliminado el rango de operación estricto.
- NO3 empieza el 2022-12-01; NE3 y NO3 casi no tienen PM2.5.

## Descarga sin iniciar sesión

Repositorio público `Leo-issacs/reto-sima-multivariados`. Formato de la URL directa (tras el merge a `main`):
`https://raw.githubusercontent.com/Leo-issacs/reto-sima-multivariados/main/data/clean/sima_diario_2020_2025.csv`
