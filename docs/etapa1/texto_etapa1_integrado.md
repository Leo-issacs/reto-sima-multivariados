# Etapa 1 · Borrador de texto (Opus) para integrar en `quarto/etapa1.qmd`

> **Instrucciones para el equipo (borrar antes de entregar).**
> - Las secciones 1.1–1.4 las aportan los compañeros (`docs/etapa1/`). Este archivo cubre 1.5–1.8, la Parte II completa y la declaratoria de IA.
> - Presupuesto de palabras: 1.5–1.8 ≈ 650 palabras; Parte II ≈ 800 palabras más 2 tablas y 2 figuras.
> - Todas las cifras de la Parte II salen de `output/diagnostico/RESUMEN.md` y de `data/clean/` (rama `datos/etapa1`, 26 sep 2026). Si se regeneran los datos, hay que volver a comprobarlas.
> - Lo marcado **[verificar]** debe confirmarse con la ficha del artículo antes de entregar.

---

# Parte I. Conociendo el negocio

> *Borrador de respaldo (Opus) para 1.1–1.4. Si los compañeros entregan su versión antes del lunes a las 2 p. m., se usa la que tenga mejor sustento y se ajusta la declaratoria de IA.*

## 1.1 El socio formador: SIMA

El Sistema Integral de Monitoreo Ambiental (SIMA) de Nuevo León opera desde el 20 de noviembre de 1992 la red de monitoreo de la calidad del aire de la Zona Metropolitana de Monterrey (ZMM), en coordinación con la Agencia de Calidad del Aire del Estado (SIMA, 2026).

**Qué mide y dónde.** La red tiene hoy 15 estaciones distribuidas en los municipios de la metrópoli. Cada hora mide seis contaminantes criterio (PM10, PM2.5, O3, SO2, NO2 y CO; además NO y NOx) y siete variables meteorológicas: temperatura, humedad relativa, precipitación, presión, radiación solar, y velocidad y dirección del viento.

**Cómo valida los datos.** Los datos pasan por:

1. una prevalidación automática, que revisa que haya al menos 75 % de datos completos, las banderas de falla y la comparación entre contaminantes;
2. una revisión horaria por un analista;
3. una revisión semanal y mensual por un supervisor.

**Qué produce.** Con esos datos, SIMA publica cada hora el Índice Aire y Salud, elabora pronósticos y activa el Programa de Respuesta a Contingencias Atmosféricas (SIMA, 2026).

**Propósito.** El programa estatal PIGECA 2023–2033 plantea fortalecer al SIMA para generar información "confiable, representativa, oportuna y verificable" que sustente la evaluación de normas, el estudio de impactos en salud y la gestión ambiental (Secretaría de Medio Ambiente del Estado de Nuevo León & Clean Air Institute, 2023). Este proyecto se apoya en ese propósito: usa los datos de la red para caracterizar patrones que ayuden a anticipar y comunicar episodios.

## 1.2 Importancia de la calidad del aire para la salud
*(Integra la aportación de Ignacio Kume, editada.)*

La calidad del aire importa a la población porque la exposición a contaminantes atmosféricos se asocia con efectos adversos en la salud y con mayor mortalidad. SIMA monitorea los contaminantes criterio PM10, PM2.5, O3, SO2, NO2 y CO (SIMA, 2026).

Orellano et al. (2020), en una revisión sistemática con metaanálisis de 196 artículos **[verificar la cifra en el resumen]**, encontraron asociaciones positivas entre la exposición de corto plazo a PM10, PM2.5, NO2 y O3 y la mortalidad por todas las causas. Las partículas se asociaron además con mortalidad cardiovascular, respiratoria y cerebrovascular.

Las **partículas finas (PM2.5)** son las más preocupantes: por su tamaño llegan a los alvéolos pulmonares. Los contaminantes **primarios** se emiten directamente; los **secundarios** se forman en la atmósfera. El ejemplo principal es el O3, que se forma a partir de óxidos de nitrógeno y compuestos orgánicos volátiles en presencia de luz solar.

En 2021 la Organización Mundial de la Salud redujo sus valores guía, por ejemplo PM2.5 a 15 µg/m³ en 24 h y 5 µg/m³ anual (World Health Organization, 2021). En la ZMM, las concentraciones de partículas rebasan esos lineamientos, lo que el PIGECA reconoce como un riesgo significativo para la salud pública (Secretaría de Medio Ambiente del Estado de Nuevo León & Clean Air Institute, 2023).

El PM10 en Monterrey muestra un ciclo anual: el otoño-invierno está más contaminado que la primavera-verano, y las concentraciones medias son mayores en el occidente y en las zonas de mayor altitud (Aguirre-López et al., 2022).

## 1.3 Medición, variables y normas
*(Integra la aportación de Ignacio Kume, editada.)*

**Variables.** SIMA mide seis contaminantes criterio y siete variables meteorológicas: temperatura, humedad relativa, precipitación, presión, radiación solar, y velocidad y dirección del viento (SIMA, 2026). En nuestros datos, las partículas se reportan en µg/m³, el O3, NO2, SO2 y NO en ppb, y el CO en ppm. Las normas de los gases se expresan en ppm (1 ppm = 1000 ppb).

**Tres referencias distintas.** Conviene no confundirlas:

1. **Rango instrumental:** lo que el equipo puede medir. Sirve para detectar errores.
2. **Límite normativo de salud:** se define con un periodo de promedio. Sirve para evaluar la exposición.
3. **Índice Aire y Salud** (NOM-172-SEMARNAT-2023, publicada el 25 de enero de 2024): comunica el riesgo cada hora (SIMA, 2026).

**Límites vigentes.** Las normas de salud se endurecen gradualmente. A diciembre de 2025 son:

| Contaminante | Norma | Periodo de promedio | Límite |
|---|---|---|---|
| PM10 | NOM-025-SSA1-2021 | 24 h | 50 µg/m³ |
| PM2.5 | NOM-025-SSA1-2021 | 24 h | 25 µg/m³ |
| O3 | NOM-020-SSA1-2021 | 1 h | 0.090 ppm |
| O3 | NOM-020-SSA1-2021 | 8 h (promedio móvil) | 0.051 ppm |

*Nota.* Entre diciembre de 2021 y diciembre de 2025, el límite de 24 h pasó de 70 a 50 µg/m³ en PM10 y de 41 a 25 µg/m³ en PM2.5. El de 8 h del O3 pasó de 0.065 a 0.051 ppm (SIMA, 2026).

**Problemas de las normas.** Esta gradualidad complica comparar años, porque parte del aumento de excedencias se debe al cambio del límite (Hernández-Romero et al., 2026). SIMA señala además que las normas de salud se han vuelto más estrictas sin un endurecimiento equivalente de las normas de emisión de las fuentes (SIMA, 2026).

## 1.4 Dificultades de la medición

Medir la calidad del aire de forma continua implica varios problemas:

- **Datos faltantes** por fallas eléctricas, calibraciones, mantenimiento o fallas de comunicación.
- **Errores instrumentales:** valores fuera de rango, lecturas repetidas por sensores atorados y saltos bruscos.
- **Inconsistencias entre variables**, como PM2.5 mayor que PM10 o NOx distinto de NO + NO2.
- **Representatividad espacial limitada:** cada estación refleja solo su entorno (Centro Mario Molina, 2021).
- **Cambios en la red y en los criterios de validación a lo largo del tiempo.** En nuestros datos, dos estaciones se incorporaron después de 2020 y los rangos válidos cambian cada año.

Estas dificultades obligan a documentar criterios explícitos de limpieza antes de cualquier análisis (Parte II).

## 1.5 Antecedentes: qué se ha hecho en la ZMM y en otras redes

Los estudios con datos de SIMA han abordado la contaminación **un contaminante a la vez**:

- Aguirre-López et al. (2022) analizaron promedios mensuales de PM10 de siete estaciones entre 2010 y 2018. Encontraron una tendencia decreciente con ciclo anual, con otoño e invierno como las temporadas más contaminadas y concentraciones mayores en el oeste de la metrópoli. Los propios autores proponen, como trabajo futuro, incorporar parámetros meteorológicos al análisis.
- Hernández-Romero et al. (2026) estudiaron la persistencia de las excedencias de PM10, PM2.5 y O3 en cinco estaciones entre 2019 y 2023, con pruebas no paramétricas, correlaciones de Spearman y una descomposición temporal sin regresores meteorológicos. Reportan que ningún sitio cumplió de forma continua la norma de PM10 y que las partículas alcanzan su máximo en la temporada seca-fría y el O3 en las cálidas **[verificar con la ficha]**.
- En la línea predictiva, Ramírez-Velarde et al. (2024) combinaron componentes principales y clasificadores para anticipar contingencias de O3 y PM2.5 con variables meteorológicas de SIMA de 2015. Hernandez-Santiago et al. (2026) modelaron el O3 horario con XGBoost y validaron entrenando con unas temporadas y probando con otra.
- Desde la química, Martínez-Cinco et al. (2016) mostraron, en dos campañas en Escobedo y Santa Catarina, que el PM2.5 otoñal está dominado por emisiones vehiculares y material orgánico y se acumula con viento débil y baja altura de mezcla. En verano aumenta el sulfato secundario, favorecido por la radiación, con la refinería de Cadereyta como principal fuente de azufre.

En otras regiones, el análisis multivariado se usa para **clasificar patrones**:

- Mohd Shafi'i y Juahir (2024) agruparon estaciones de Malasia con conglomerados jerárquicos, validaron los grupos con análisis discriminante (90.5 % de clasificación correcta, evaluada con los mismos datos) y los interpretaron con PCA.
- Elmourssi et al. (2026) identificaron cuatro regímenes de contaminación en El Cairo con k-medias y evaluaron su estabilidad entre años con el Índice de Rand Ajustado.

## 1.6 Problema, pregunta y objetivos

**Problema.** SIMA mide cada hora seis contaminantes criterio y siete variables meteorológicas en 15 estaciones, pero comunica y gestiona la calidad del aire contaminante por contaminante. No existe una caracterización de **qué combinaciones de contaminación y clima se repiten** en la ZMM ni de qué tan bien las condiciones meteorológicas permiten anticiparlas.

**Pregunta central.** ¿Qué combinaciones típicas de contaminantes y condiciones meteorológicas ("regímenes diarios") se presentan en la Zona Metropolitana de Monterrey entre 2021 y 2025, en qué temporadas y estaciones ocurren con mayor frecuencia, y qué condiciones meteorológicas permiten anticipar los regímenes de peor calidad del aire?

**Objetivos:**

- **O1 (esta etapa).** Construir una base estación-día depurada y documentada a partir de las mediciones horarias 2020–2025, reportando por variable el porcentaje de datos faltantes, invalidados e imputados.
- **O2.** Identificar entre tres y seis regímenes diarios mediante componentes principales y análisis de conglomerados, e interpretarlos física y químicamente. Criterio de estabilidad: acuerdo entre periodos medido con el Índice de Rand Ajustado, con umbral a justificar en la etapa 2.
- **O3.** Cuantificar la frecuencia de cada régimen por temporada y estación, y la proporción de días que rebasan los límites de PM10, PM2.5 y O3 en cada uno.
- **O4.** Evaluar con análisis discriminante si la meteorología del día identifica el régimen mejor que una referencia basada solo en la temporada, entrenando con 2021–2023 y probando con 2024–2025.
- **O5.** Implementar una interfaz que, dadas condiciones meteorológicas, estime la probabilidad de cada régimen y muestre su desempeño en datos de prueba.

## 1.7 Justificación

En la literatura revisada no encontramos para la ZMM un análisis que agrupe **días** según la combinación conjunta de contaminantes y meteorología con datos horarios de toda la red. Los antecedentes locales son univariados, se limitan a un contaminante o se basan en campañas de pocos días. Los estudios multivariados de otras redes agrupan estaciones o no incorporan la meteorología, y en algún caso evalúan la clasificación con los mismos datos de ajuste.

Nuestra propuesta combina tres elementos:

- el enfoque de regímenes de Elmourssi et al. (2026);
- la secuencia conglomerados–discriminante–PCA de Mohd Shafi'i y Juahir (2024);
- una validación temporal, como la de Hernandez-Santiago et al. (2026).

Para el socio, los regímenes traducen trece variables en unos pocos tipos de día comunicables. Además, permiten anticipar episodios a partir del pronóstico meteorológico. Esto responde a las medidas de fortalecimiento de pronóstico y modelación (4T), de gestión del riesgo por contingencias (6T) y de comunicación (9T) del PIGECA 2023–2033 (Secretaría de Medio Ambiente del Estado de Nuevo León y Clean Air Institute, 2023).

## 1.8 Fuentes de datos

Usamos seis libros Excel proporcionados por SIMA para el reto (`BD 2020.xlsx` a `BD 2025.xlsx`), con mediciones horarias de 15 estaciones: 87 hojas estación-año, 754 603 registros y 16 columnas (fecha y hora, 8 contaminantes y 7 variables meteorológicas).

Los complementamos con tres documentos del socio:

- `Etiquetas.xlsx`: unidades, estaciones y banderas de validez.
- *Rangos de los parámetros del SIMA*: rangos de operación por año y rangos del fabricante.
- *Ubicación de las estaciones de monitoreo*: coordenadas y altitud.

Los originales no se modificaron; su integridad se verificó con huellas MD5.

---

# Parte II. Comprensión y preparación de los datos

## 2.1 Importación y estructura

Importamos las 87 hojas en R (paquete `readxl`) conservando el archivo, la hoja (estación) y la fila de origen, y unificamos la columna de fecha (`Fecha y hora` en 2020–2024 y `date` en 2025).

La resolución es **horaria**: el 99.98 % de los saltos entre registros es de una hora, y hay una mediana de 24 filas por día. La nota de `Etiquetas.xlsx` sobre "promedios diarios" no describe estos archivos.

Otras características de la base:

- Las fechas no incluyen zona horaria y no muestran cambio de horario. Las tratamos como hora local fija, pendiente de confirmar con SIMA.
- No hay registros duplicados ni celdas con texto: las 11 319 045 celdas de medición son numéricas.
- Los archivos **no traen banderas de validez**, por lo que una celda vacía no indica la causa del faltante.
- Faltan 8 189 horas sin fila (1.07 % de 762 792 horas esperadas). De ellas, 8 017 corresponden a la estación NO3, que inicia el 1 de diciembre de 2022.
- Las 15 variables de medición son numéricas continuas; la estación (15 niveles) y la temporada son categóricas.

La @tbl-dimensiones resume las bases publicadas; el diccionario completo está en el Anexo A.

## 2.2 Calidad de los datos

**Faltantes.** Medido sobre 762 792 horas esperadas por variable, el porcentaje faltante original va de 4.7 % (radiación solar) a 26.0 % (PM2.5), con 5.7 % en PM10 y entre 14 % y 18 % en los gases (@fig-faltantes y Anexo C). Los faltantes se concentran en ciertas estaciones y años:

- 2020 tiene la peor cobertura: solo 2 de 13 estaciones alcanzan 75 % de días válidos en NO2, y 3 en O3.
- NE3 y NO3 prácticamente no miden PM2.5.

**Rangos.** Contrastamos cada valor con los rangos de operación anuales y del fabricante de SIMA (Anexo B). Los contaminantes casi nunca los violan (≤ 0.05 %). En la meteorología, el rango de operación resultó inadecuado como criterio de error:

- **Temperatura:** marcaría como error 458 temperaturas bajo cero en años cuyo rango inicia en 0 °C.
- **Presión:** marcaría 1.14 % de las horas, concentradas en estaciones de mayor altitud. El rango es único para toda la red y no considera la altitud de cada estación.

**Consistencia.** PM2.5 superó a PM10 (algo físicamente imposible) en solo 37 de 555 259 horas comparables (0.007 %), lo que indica una depuración previa de SIMA. En cambio, NOX difirió de NO + NO2 en más de 1 ppb y 10 % en 11.35 % de las horas de NE3 y 8.21 % de NTE2, frente a menos de 2 % en el resto.

**Valores repetidos.** Las rachas de valores idénticos fueron frecuentes en la radiación solar, pero corresponden a lecturas nocturnas reales.

## 2.3 Selección de datos y variables

**Periodo.** Conservamos 2020 en la base publicada, marcado con una variable de confinamiento (1 de abril al 31 de mayo), pero lo excluimos del modelado por su baja cobertura y por el efecto atípico del confinamiento en la calidad del aire (Schiavo et al., 2023). El periodo de análisis es **2021–2025**.

**Variables activas.** Los regímenes se definirán con los contaminantes criterio:

- PM10 y PM2.5 (promedio de 24 h);
- O3 (máximo diario del promedio móvil de 8 h, métrica de la NOM-020-SSA1-2021);
- NO2, CO y SO2 (promedio de 24 h).

Las variables meteorológicas (temperatura, humedad, radiación, presión, viento y lluvia) funcionarán como descriptores y como predictores del análisis discriminante. Excluimos NO y NOX porque son redundantes con NO2 y porque NOX es inconsistente en algunas estaciones.

**Registros.** Solo entran al modelado los días completos en todas las variables anteriores (núcleo B). Son 14 551 de 27 025 días-estación del periodo (53.8 %), con proporciones similares por temporada (52.2 % a 54.9 %), lo que descarta un sesgo estacional por la selección (@fig-nucleos). Las estaciones NE3 (1.5 % de días completos) y NO3 (8.6 %) quedan fuera del modelado. Las otras 13 conservan entre 28.0 % (NTE) y 81.5 % (SE3) de sus días.

Como análisis de sensibilidad conservamos el núcleo A, sin PM2.5: 17 740 días (65.6 %).

## 2.4 Limpieza

Aplicamos las siguientes reglas sobre los datos horarios, siempre anulando el valor (NA) con una bandera y **sin eliminar filas**:

1. **Fuera de rango:** en contaminantes, el rango de operación del año; en meteorología, el rango del fabricante; en lluvia, el máximo de operación del año. Se aplicaron también las notas del documento de rangos.
2. **Saltos físicamente implausibles:** más de 10 °C o 10 mm Hg en una hora, criterio de la bandera *h* de SIMA.
3. **PM2.5 > PM10:** se anulan ambos valores (bandera *r* de SIMA).
4. **Rachas idénticas de 24 h o más** en contaminantes, temperatura, humedad y presión. Las de 6 h o más solo se marcan. Las rachas se evalúan sobre los datos observados, antes de imputar.
5. **Consistencia espacial** de temperatura y humedad: se anula la lectura que se aparta más de 10 °C (temperatura) o 40 puntos porcentuales (humedad) de la mediana de la red a la misma hora, cuando reportan al menos cinco estaciones. También se anulan las lecturas en el límite del sensor (−50 °C). Esta prueba es habitual en el control de calidad meteorológico (Fiebrich et al., 2010). Una lectura atípica frente a la red es sospechosa, no necesariamente errónea; por eso los umbrales son una decisión del equipo, justificada por la distribución de las desviaciones y por la ausencia de heladas en verano en Monterrey, y reportamos su sensibilidad. En los Excel originales, 1 082 lecturas de temperatura se desviaban más de 10 °C. Las horas anuladas por esta regla no se imputan.

Los valores extremos **dentro de rango se conservaron**, porque pueden ser episodios reales de contaminación, como hacen Hernández-Romero et al. (2026). Una excedencia normativa no es un error de medición.

Por variable, el porcentaje anulado fue a lo sumo de 0.82 % (NO).

**Imputación.** Usamos un solo método: interpolación lineal de huecos de hasta 3 horas consecutivas, por estación y variable (`imputeTS`; Moritz & Bartz-Beielstein, 2017). El viento se imputó en sus componentes u y v, y la lluvia no se imputó. Descartamos la imputación por la media porque borra los ciclos diarios y estacionales.

Como la interpolación rellena cada variable por separado, **volvimos a validar cada valor imputado** con las mismas reglas: rango, saltos y PM2.5 ≤ PM10. Revertimos a NA las imputaciones que violaban alguna regla (3 599 horas de PM2.5, 252 de PM10, 147 de temperatura y 54 de presión), sin modificar ningún valor original.

El porcentaje imputado neto fue de 0 % a 2.88 % (PM2.5), y el faltante final quedó entre 4.5 % (SR) y 23.2 % (PM2.5) (@tbl-limpieza). Un script de validación comprueba automáticamente que la base publicada no contenga PM2.5 > PM10 ni valores fuera de rango, y dos revisiones independientes reprodujeron exactamente los CSV publicados.

## 2.5 Transformación y preparación

1. **Agregación horaria → diaria.** Un valor diario es válido solo con al menos 18 horas válidas, el criterio de completitud del 75 % que usa SIMA. El O3 se resume como máximo del promedio móvil de 8 h.
2. **Viento.** Lo convertimos de km/h a m/s y de dirección a componentes u y v, porque la dirección es una variable circular: 359° y 1° son casi iguales.
3. **Lluvia.** Como la unidad no está confirmada (hay valores de hasta 360 y repeticiones sospechosas), la resumimos como número de horas con lluvia y como indicador de lluvia (0/1) en lugar de su cantidad.
4. **Atributos derivados:** temporada (seca-fría, noviembre–febrero; seca-cálida, marzo–mayo; cálida-húmeda, junio–octubre; definición operativa del equipo), confinamiento 2020 e indicadores de pertenencia a los núcleos.
5. **Lo que dejamos para el modelado.** No discretizamos concentraciones, porque se perdería información. La estandarización z se aplicará al modelar, ajustada solo con los datos de entrenamiento, para evitar fuga de información. Las variables dummy de estación y temporada solo serán necesarias en la regresión alternativa, porque PCA y conglomerados no las requieren.

**Acceso a los datos limpios.** Base horaria depurada (un CSV por año, 13–17 MB), base diaria de 31 783 filas × 40 columnas, diccionario, reglas y scripts de reproducción: **https://github.com/Leo-issacs/reto-sima-multivariados/tree/main/data/clean** *(enlace válido tras integrar el PR #6 a `main`)*.

---

# Declaratoria de uso de IA (Opción B) — el equipo debe completarla con lo que realmente hizo

- **Herramientas:** Claude (Anthropic): Claude Opus en conversación y Claude Code; ChatGPT (OpenAI); Codex (OpenAI).
- **Uso realizado:**
  - Codex: preparación del repositorio y del entorno R.
  - Claude Opus: planeación, búsqueda y resumen de literatura, propuesta de decisiones de limpieza y borradores de las secciones 1.5–1.8 y de la Parte II.
  - Claude Code: scripts de R para importación, diagnóstico, limpieza y generación del documento.
  - ChatGPT (usado por Ignacio Kume): borradores de 1.2 y 1.3 y ficha de lectura de Aguirre-López et al. (2022), a partir de los PDF proporcionados.
  - Claude Opus: borradores de 1.1 y 1.4 e integración y edición de 1.2 y 1.3.
- **Secciones donde se utilizó:** Parte I (1.1–1.8), Parte II (2.1–2.5), scripts en `scripts/` y `R/`.
- **Validación realizada por los estudiantes:** *[completar con lo que hicieron realmente; por ejemplo: revisamos cada cifra contra las tablas generadas, leímos los artículos citados, verificamos las referencias por DOI, ejecutamos los scripts y comprobamos el enlace del CSV]*.
- Confirmamos que revisamos y verificamos el contenido y asumimos la responsabilidad del contenido final entregado.

---

# Referencias de estas secciones (APA 7)

- Aguirre-López, M. A., Rodríguez-González, M. A., Soto-Villalobos, R., Gómez-Sánchez, L. E., Benavides-Ríos, Á. G., Benavides-Bravo, F. G., Walle-García, O., & Pamanés-Aguilar, M. G. (2022). Statistical analysis of PM10 concentration in the Monterrey Metropolitan Area, Mexico (2010–2018). *Atmosphere, 13*(2), 297. https://doi.org/10.3390/atmos13020297
- Centro Mario Molina. (2021). *Estudio para el rediseño de la red de monitoreo de la calidad del aire de Monterrey* [Informe final].
- Orellano, P., Reynoso, J., Quaranta, N., Bardach, A., & Ciapponi, A. (2020). Short-term exposure to particulate matter (PM10 and PM2.5), nitrogen dioxide (NO2), and ozone (O3) and all-cause and cause-specific mortality: Systematic review and meta-analysis. *Environment International, 142*, 105876. https://doi.org/10.1016/j.envint.2020.105876
- SEMARNAT. (2024, 25 de enero). NORMA Oficial Mexicana NOM-172-SEMARNAT-2023, Lineamientos para la obtención y comunicación del índice de calidad del aire y riesgos a la salud. *Diario Oficial de la Federación*.
- SIMA. (2026). *Red de monitoreo y manejo de datos de calidad del aire* [Diapositivas de la exposición del reto, 14 de agosto de 2026]. Secretaría de Medio Ambiente del Estado de Nuevo León.
- World Health Organization. (2021). *WHO global air quality guidelines: Particulate matter (PM2.5 and PM10), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide*. https://www.who.int/publications/i/item/9789240034228
- Elmourssi, D. M., El-Assy, A. M., & Amer, H. M. (2026). Clustering and machine learning techniques identify air pollution regimes in Greater Cairo. *Scientific Reports*. https://doi.org/10.1038/s41598-026-49777-5
- Fiebrich, C. A., Morgan, C. R., McCombs, A. G., Hall, P. K., & McPherson, R. A. (2010). Quality assurance procedures for mesoscale meteorological data. *Journal of Atmospheric and Oceanic Technology, 27*(10), 1565–1582. https://doi.org/10.1175/2010JTECHA1433.1
- Hernández-Romero, K., Hernández-Romero, I. M., Mendoza, A., Pérez-Rodríguez, M., Barajas-Villarruel, L. R., Medellín-Carrillo, S., & González, L. T. (2026). Persistent air pollution regimes and regulatory exceedances of PM10, PM2.5, and O3 in the Monterrey Metropolitan Area, Mexico. *City and Environment Interactions, 31*, 100410. https://doi.org/10.1016/j.cacint.2026.100410
- Hernandez-Santiago, E., Tello-Leal, E., Jaramillo-Perez, J. M., & Macías-Hernández, B. A. (2026). Development of an ozone (O3) predictive emissions model using the XGBoost machine learning algorithm. *Big Data and Cognitive Computing, 10*(1), 15. https://doi.org/10.3390/bdcc10010015
- Martínez-Cinco, M. A., Santos-Guzmán, J., & Mejía-Velázquez, G. M. (2016). Source apportionment of PM2.5 for supporting control strategies in the Monterrey Metropolitan Area, Mexico. *Journal of the Air & Waste Management Association, 66*(6), 631–642. https://doi.org/10.1080/10962247.2016.1159259
- Mohd Shafi'i, M. S., & Juahir, H. (2024). Assessment of spatial air quality on the East Coast of Peninsular Malaysia utilizing environmetric techniques. *Environmental Monitoring and Assessment, 196*(7), 640. https://doi.org/10.1007/s10661-024-12787-9
- Moritz, S., & Bartz-Beielstein, T. (2017). imputeTS: Time series missing value imputation in R. *The R Journal, 9*(1), 207–218. https://doi.org/10.32614/RJ-2017-009
- Ramírez-Velarde, R., Esquivel-Flores, O., & Mejía-Velázquez, G. (2024). Forecasting air pollution contingencies using predictive analytic techniques. *Atmosphere, 15*(11), 1271. https://doi.org/10.3390/atmos15111271
- Schiavo, B., Morton-Bermea, O., Arredondo-Palacios, T. E., Meza-Figueroa, D., Robles-Morua, A., García-Martínez, R., Valera-Fernández, D., Inguaggiato, C., & Gonzalez-Grijalva, B. (2023). Analysis of COVID-19 lockdown effects on urban air quality: A case study of Monterrey, Mexico. *Sustainability, 15*(1), 642. https://doi.org/10.3390/su15010642
- Secretaría de Medio Ambiente del Estado de Nuevo León & Clean Air Institute. (2023). *Programa Integral para la Gestión Estratégica de la Calidad del Aire de la Zona Metropolitana de Monterrey (PIGECA) 2023–2033* **[verificar año y autoría en la portada]**.
- Secretaría de Salud. (2021). *NOM-020-SSA1-2021, Salud ambiental. Criterio para evaluar la calidad del aire ambiente con respecto al ozono (O3)*. Diario Oficial de la Federación **[verificar título exacto y fecha de publicación]**.
