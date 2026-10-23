# Calidad del aire en Monterrey — Reto SIMA

Proyecto de Análisis Multivariado (MA2003B). Somos un equipo de cuatro integrantes y trabajaremos durante cinco semanas con datos de calidad del aire y meteorología del SIMA.

Estamos en la primera etapa: revisar las bases, confirmar qué significan las variables y elegir una pregunta que podamos responder con los datos disponibles.

## Para empezar

1. Abre este repositorio en **Posit Cloud → New Project → New Project from Git Repo**.
2. Abre `sima.Rproj` y ejecuta en la consola de R:

```r
source("scripts/restaurar_entorno.R")
source("scripts/00_verificar_entorno.R")
```

El proyecto usa **R 4.6.1** y `renv` para compartir las versiones de los paquetes. La [guía de arranque](docs/INICIO_GITHUB_POSIT.md) explica el acceso, la carga de datos y el uso desde RStudio local.

## Qué vamos a hacer

| Semana | Trabajo previsto |
|---|---|
| 1 | Conocer los datos y definir la pregunta. |
| 2 | Preparar la base y explorar las variables. |
| 3 | Desarrollar el análisis multivariado. |
| 4 | Evaluar resultados y preparar la demostración. |
| 5 | Cerrar el reporte y presentar. |

Las fechas y los requisitos de cada entrega se ajustarán a lo que indiquen las profesoras.

- [Tareas abiertas](https://github.com/Leo-issacs/reto-sima-multivariados/issues)
- [Hitos de las cinco semanas](https://github.com/Leo-issacs/reto-sima-multivariados/milestones)
- [Plan de trabajo](docs/PLAN_EJECUCION.md)
- [Integrantes y reparto de trabajo](docs/EQUIPO.md)
- [Guía de estudio](docs/GUIA_ESTUDIO.md)

## Dónde está cada cosa

| Carpeta | Contenido |
|---|---|
| `R/` y `scripts/` | Funciones (`R/`) y pasos numerados del análisis (`scripts/02` a `10`, en orden de ejecución); utilidades del informe final en `scripts/utilidades/`. |
| `data/` | Bases limpias publicables (`data/clean/`, con la base v2 en `data/clean/v2/`) e instrucciones para los Excel de SIMA (`data/raw/`, no se suben). |
| `config/` | Diccionario de variables y rangos de operación y del fabricante que usa la limpieza. |
| `quarto/` | Fuentes de los informes (etapas 1 y 2 e informe final) y plantillas de Word. |
| `docs/` | Decisiones, protocolo, retroalimentación, textos de cada etapa y control de calidad del informe final. |
| `output/` | Resultados de cada etapa (tablas, figuras y resúmenes), versionados. |
| `app/` | Interfaz Shiny del modelo final de la etapa 3. |

Las seis bases del equipo se colocan en `data/raw/`; no se suben a GitHub. Para revisar sus hojas y columnas:

```r
source("scripts/01_inventario.R")
```

Para generar el informe final, ejecutar en la Terminal, desde la raíz (después de los scripts de la etapa 4):

```sh
quarto render quarto/etapa4_informe_final.qmd --to docx
Rscript scripts/utilidades/formato_docx.R docs/quarto/etapa4_informe_final.docx docs/etapa4/Informe_final_SIMA_Equipo1.docx
Rscript scripts/utilidades/verificar_citas.R
```

Quarto escribe el borrador en `docs/quarto/`. `formato_docx.R` solo ajusta la paginación de tablas y figuras (no cambia el texto) y escribe el Word de entrega; `verificar_citas.R` comprueba que cada cita tenga su referencia y viceversa. El Word y su PDF no se suben al repositorio porque llevan las matrículas. Las cifras del informe y su archivo de origen están en [`docs/etapa4/trazabilidad_cifras.md`](docs/etapa4/trazabilidad_cifras.md).

## Cómo reproducir

**Orden completo:** 02 → 03 → 06 → 07a–c → 08a–d → 09a–h → 10 (desde la raíz del proyecto, con `renv::restore()` hecho).

- **Necesitan los Excel** (`BD 2020.xlsx` … `BD 2025.xlsx` en `data/raw/` o en la carpeta de `SIMA_DATA_DIR`): 01, 02 y 03, que generan `data/clean/` desde cero. El cuaderno de auditoría también los usa.
- **Corren solo con `data/clean/`** (lo que está en el repositorio): 04, 05, 06, 06b, 07a–c, 08a–d, 09a–h y 10. 08a usa los Excel solo para una comprobación opcional si `SIMA_DATA_DIR` está definido.
- **Evaluaciones únicas de la prueba:** 07b (etapa 3) y 09a (etapa 4) dejan registro (`output/etapa3/registro_prueba.txt`, `output/etapa4/registro_prueba_v2.txt`) y no vuelven a correr sin `MOTIVO_RECORRIDA`. Ambos tienen un modo `ENSAYO=1` que no lee 2024–2025.
- **Finales de línea:** todos los CSV se escriben con `\n`, también en Windows, y `.gitattributes` los guarda con LF. 09a exige que `R/`, `scripts/` y `data/clean/v2/` no tengan cambios sin commit, pero compara el contenido sin `\r` (y descomprimido en el `.csv.gz`), así que volver a correr 08b y 08d no lo bloquea si su contenido no cambia.
- **Informe en Word:** `scripts/utilidades/formato_docx.R` usa el paquete `zip`, registrado en `renv.lock`; el script 10 usa `mgcv`, también registrado.

**Lenguajes:** R para todo el análisis (limpieza, imputación, modelos, validaciones, figuras y app). Python solo se usó en la prueba de viabilidad del 4 de octubre (`docs/etapa2/prueba_viabilidad_2026-10-04.py`) y en verificaciones cruzadas: ningún resultado del informe depende de Python.

Pasos de la limpieza y de la etapa 2:

| Paso | Script | Qué hace | Qué genera |
|---|---|---|---|
| 1 | `Rscript scripts/02_importar_diagnosticar.R` | Verifica las huellas MD5 de los Excel, importa las 87 hojas sin transformar y diagnostica (faltantes, rangos, consistencia, cobertura) | `output/diagnostico/` (tablas, heatmaps, `RESUMEN.md`) |
| 2 | `Rscript scripts/03_limpiar.R` | Limpia (rango, notas del PDF, saturación, saltos, PM2.5 > PM10, consistencia espacial, rachas), imputa (interpolación ≤ 3 h, revalidada) y agrega a diario. Llama a `04_validar_limpios.R` al final | `data/clean/` (CSV horarios por año, diario, diccionario, README) y `output/diagnostico/` (núcleos, sensibilidades) |
| 3 | `Rscript scripts/04_validar_limpios.R` | Valida los CSV publicados (sin PM2.5 > PM10, sin valores fuera de rango, `nox_inconsistente` coherente, sin TOUT saturada, consistencia espacial, horas E/L nunca imputadas, viento D15 con anulación conjunta y rapidez de u/v imputados). Ya se ejecuta dentro del paso 2; puede correrse solo | Mensaje de validación (falla con `stop()` si algo no se cumple) |
| 4 | `Rscript scripts/05_probar_limpieza.R` | Pruebas sintéticas de las reglas de limpieza (no usa los Excel) y pruebas del validador con una copia alterada del CSV de 2022 | Mensajes `ok:` por cada caso |
| 5 | `Rscript scripts/06_explorar_etapa2.R` | Construye la muestra del protocolo de la etapa 2 (13 estaciones, 2021–2025, PM2.5 y meteorología completos) y la describe: pérdidas, sensibilidad de imputación, descriptivos, SMD y figuras. Sin PCA ni modelos | `data/clean/muestra_pm25_2021_2025.csv` y `output/etapa2/` (tablas, figuras, `RESUMEN.md`) |
| 6 | `Rscript scripts/06b_anexo_c_diccionario.R` y `quarto render quarto/anexo_c.qmd --execute-dir .` | Anexo C: diccionario de las tres bases (horaria, diaria, muestra) con dominio y % de nulos antes y después de la limpieza; agrega esas columnas a `data/clean/DICCIONARIO.csv` | `output/etapa2/anexo_c_diccionario.csv` y `quarto/anexo_c.docx` (copia entregada en `docs/etapa2/Anexo_C_diccionario.docx`) |
| — | `quarto render notebooks/01_auditoria_datos_crudos.qmd` | Cuaderno reproducible de auditoría sobre los Excel originales, independiente de los scripts anteriores | `notebooks/01_auditoria_datos_crudos.html` |

El protocolo de la etapa 2 (pregunta, modelos M0/M1, métricas y sensibilidades) está en [`docs/etapa2/protocolo.md`](docs/etapa2/protocolo.md).

Etapas 3 y 4 (no necesitan los Excel):

| Paso | Script | Qué hace | Qué genera |
|---|---|---|---|
| 7 | `Rscript scripts/07a_validacion_progresiva.R` | Etapa 3: validación progresiva en 2021–2023 (transformaciones, PRS como anomalía, PCA) | `output/etapa3/validacion/` |
| 8 | `Rscript scripts/07b_evaluar_prueba.R` | Etapa 3: evaluación única de la prueba 2024–2025 con `datos-v1.2` (ΔAUC = 0.070) | `output/etapa3/` (`RESUMEN.md`, registro) |
| 9 | `Rscript scripts/07c_diagnostico_errores.R` | Etapa 3: diagnósticos posteriores y modelo final para la app | `output/etapa3/diagnostico/`, `modelo_final.rds` |
| 10 | `Rscript scripts/08a_enmascaramiento_horario.R` | Etapa 4 (D19): elige el método y el `maxgap` de imputación horaria por enmascaramiento en 2021–2023 (unos 25 min) | `output/etapa4/imputacion/` |
| 11 | `Rscript scripts/08b_construir_base_v2.R` | Etapa 4 (D18, D19, D23): base diaria `datos-v2.0` (PM2.5 solo observado, meteorología con D19, `sitio_valido`) | `data/clean/v2/diario_v2_2021_2025.csv` |
| 12 | `Rscript scripts/08c_enmascaramiento_diario.R` | Etapa 4 (D20): compara MICE con la mediana de la red ajustada y la media estación × temporada | `output/etapa4/imputacion/` |
| 13 | `Rscript scripts/08d_imputar_diario.R` | Etapa 4: imputación diaria (mediana de la red ajustada) y MICE m = 20 como sensibilidad | `data/clean/v2/` |
| 14 | `Rscript scripts/09a_evaluar_prueba_v2.R` | Etapa 4: evaluación única de la prueba con la base v2, tabla puente y sensibilidades | `output/etapa4/` (`RESUMEN.md`, registro) |
| 15 | `Rscript scripts/09b_validar_lda.R` | Etapa 4 (D21): estabilidad de coeficientes, LDA frente a logística, pliegues, QDA y calibración | `output/etapa4/lda/` |
| 16 | `Rscript scripts/09c_area_estudio_reubicaciones.R` | Etapa 4 (D22, D23): superación por estación y año, PRS frente a la red en las reubicaciones, mapa con altitud | `output/etapa4/area_estudio/` |
| 17 | `Rscript scripts/09d_diagnostico_errores_v2.R` | Etapa 4, fase D: errores del modelo congelado, supuestos del LDA, autocorrelación y heterogeneidad de los residuos | `output/etapa4/errores/` |
| 18 | `Rscript scripts/09e_sensibilidades_posteriores.R` | Etapa 4, fase D: sensibilidades posteriores a la prueba (SR ≥ 0, reubicaciones según SIMA, sin NO2), anotadas en el registro | `output/etapa4/sensibilidades_posteriores/` |
| 19 | `Rscript scripts/09f_viento_pm_no2.R` | Etapa 4, fase D: viento por estación, cociente PM2.5/PM10, PM2.5 frente a la red (NO2) y boletín estatal | `output/etapa4/descriptivos/` |
| 20 | `Rscript scripts/09g_pca_y_residuos_v2.R` | Informe final: PCA con el entrenamiento v2, varianza de los residuos, calibración por temporada, largo de los huecos, radiación por estación y figuras compactas. No ajusta modelos nuevos | `output/etapa4/pca/`, `output/etapa4/errores/`, `output/etapa4/figuras/roc_y_dauc_informe.png` |
| 21 | `Rscript scripts/09h_figuras_informe.R` | Informe final: versión de siete figuras (mapa, error de la imputación horaria, cargas del PCA, autocorrelación de los residuos, magnitud del PM2.5, NO2 y coeficientes con las estaciones) con etiquetas en español, tamaño para el ancho de página y sin título interno. Solo presentación: lee los CSV de 08a, 09b, 09c, 09d, 09f y 09g y no recalcula nada | `output/etapa4/figuras/` (`mapa_estaciones_informe.png`, `rmse_imputacion_informe.png`, `pca_cargas_informe.png`, `acf_residuos_informe.png`, `errores_magnitud_informe.png`, `no2_relativo_informe.png`, `coeficientes_ic_informe.png`) |
| 22 | `Rscript scripts/10_analisis_retro_final.R` | Fase F, **posterior** a la evaluación de la prueba: regresión logística (odds ratios, importancia por permutación y linealidad con GAM), persistencia, umbral elegido con los pliegues, bootstrap estratificado por temporada, episodios y exclusiones. No cambia el modelo principal. Con `SOLO_ENTRENAMIENTO=1` calcula solo las decisiones del entrenamiento y se detiene (unos 15 min la corrida completa) | `output/etapa4/retro_final/` (`RESUMEN.md`, CSV y tres figuras) |

Decisiones de la etapa 4: [`docs/etapa4/decisiones_etapa4.md`](docs/etapa4/decisiones_etapa4.md); resumen: [`output/etapa4/RESUMEN_ETAPA4.md`](output/etapa4/RESUMEN_ETAPA4.md).

## Interfaz

La etapa 3 incluye una interfaz gráfica para usar el modelo final (LDA, M0 y M1) y revisar su desempeño en la prueba 2024–2025. Está en [`app/`](app/) y lee el modelo congelado `output/etapa3/modelo_final.rds`; no reentrena nada.

1. Si no existe `output/etapa3/modelo_final.rds`, genéralo con `Rscript scripts/07c_diagnostico_errores.R` (también escribe los diagnósticos de `output/etapa3/diagnostico/` y `RESUMEN_DIAGNOSTICO.md`).
2. Abre `sima.Rproj` y corre `shiny::runApp("app")`.
3. Pruebas: `Rscript tests/test_app_predicciones.R` comprueba que la app reproduce las probabilidades de la prueba (tolerancia 1e-10) y que no falla con los deslizadores en sus extremos.

Pestañas: **Calcular** (probabilidad de superación según M0 y M1 para una estación, temporada o fecha y valores meteorológicos; contribución de cada variable), **Desempeño 2024–2025** (métricas y serie de tiempo con falsos positivos y negativos) y **Acerca de**. Es una clasificación retrospectiva con meteorología observada, no un pronóstico. Capturas: `output/etapa3/figuras/app_*.png`; se tomaron con el paquete `webshot2`, que no está en `renv.lock` y no hace falta para correr la app.

Publicación en shinyapps.io (opcional; solo cuando el equipo lo decida): copia `output/etapa3/modelo_final.rds` dentro de `app/`, instala `rsconnect`, configura la cuenta con `rsconnect::setAccountInfo()` y ejecuta `rsconnect::deployApp("app")`.

## Cómo nos organizamos

Cada tarea tiene una persona responsable y otra que la revisa. Hacemos cambios pequeños en una rama y los integramos mediante una pull request. Los pasos están en [CONTRIBUTING.md](CONTRIBUTING.md).

Este repositorio es público. Falta que los otros tres integrantes acepten sus invitaciones y comprueben que pueden editar. La entrega del entorno será una sola liga por equipo: la de este repositorio.

La base parte de [2003B_Blank](https://github.com/Krul-dev/2003B_Blank) y conserva su licencia GPL-3.0. Las adaptaciones están en [PLANTILLA_CURSO.md](docs/PLANTILLA_CURSO.md); las comprobaciones realizadas, en [VERIFICACION_BASE.md](docs/VERIFICACION_BASE.md). Los datos y documentos externos conservan las condiciones de sus fuentes.
