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

## Reglas, en este orden (cada hora de cada variable queda con una bandera)

1. **F, rango duro.** Contaminantes: rango de operación **del año** (ambos límites). Meteorología: rango del **fabricante** (TOUT −50 a 50 °C, PRS 449.9–824.9 mm Hg, RH 0–100, WSR 0–180 km/h, SR 0–1.4 kW/m², WDR 0–360; RAINF: de 0 al **máximo de operación del año**, porque el rango del fabricante no es numérico).
2. **P, notas del PDF**, solo en su año: 2020 O3 se omite el máximo de NTE2; 2020 WSR > 75; SR > 1 en 2020 y 2021; 2020 PRS fuera de 690–750.
3. **S, salto horario** (bandera `h` de SIMA): |ΔTOUT| > 10 °C o |ΔPRS| > 10 mm Hg respecto de la hora previa; se invalida la hora que salta.
4. **R, PM2.5 > PM10** (bandera `r` de SIMA): se invalidan ambas.
5. **K / C, rachas de valores idénticos.** Toda racha ≥ 6 h queda marcada `C` (excepto ceros de SR y RAINF, que son noche y horas secas). Solo se invalidan (`K`) las de ≥ 24 h en contaminantes, TOUT, PRS y RH (RH = 100 no se invalida). SR, RAINF, WSR y WDR nunca se invalidan por racha.
6. **NOX:** no se invalida. `nox_inconsistente` = 1 si |NOX − (NO + NO2)| > max(1 ppb, 10 % de NOX): el piso de 1 ppb evita marcar diferencias menores a la resolución del analizador.
7. **Viento:** `viento_u = −WSR/3.6·sin(WDR)`, `viento_v = −WSR/3.6·cos(WDR)` en m/s (requiere WSR y WDR válidas). WSR y WDR se publican validadas y sin imputar.
8. **I, imputación**: solo huecos internos de ≤ 3 h consecutivas, interpolación lineal (`imputeTS::na_interpolation(maxgap = 3)`), por estación y variable, sobre la serie continua 2020–2025 de la estación y antes del agregado diario. Se imputan contaminantes, TOUT, RH, SR, PRS y u/v; **no** RAINF ni WSR/WDR. Sin imputación por media. Al imputar se pierde el motivo original de invalidez en la bandera (la tabla del informe sí lo separa).
9. Los valores extremos dentro de rango se conservan.

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
