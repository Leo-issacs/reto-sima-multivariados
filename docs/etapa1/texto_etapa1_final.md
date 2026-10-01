# Parte I. Conociendo el negocio

## 1.1 El socio formador: SIMA

El Sistema Integral de Monitoreo Ambiental (SIMA) es la red de monitoreo de la calidad del aire del Gobierno de Nuevo León. Opera desde el 20 de noviembre de 1992 y su centro de control, el C5 Ambiental, se inauguró el 5 de junio de 2026 (SIMA, 2026). Sus 15 estaciones automáticas en la Zona Metropolitana de Monterrey (ZMM) miden cada hora seis contaminantes criterio (PM10, PM2.5, O3, SO2, NO2 y CO) y siete variables meteorológicas.

Los datos pasan por una prevalidación automática, que exige 75 % de completitud y revisa banderas de falla, y después por revisiones manuales horarias, semanales y mensuales. Con ellos, SIMA calcula cada hora el Índice Aire y Salud (que sustituyó al IMECA en 2020), elabora pronósticos y activa el Programa de Respuesta a Contingencias Atmosféricas (SIMA, 2026).

El PIGECA 2023–2033 le asigna el propósito de generar información "confiable, representativa, oportuna y verificable" para evaluar la calidad del aire, sus impactos en la salud y la gestión ambiental. Nuestro proyecto se vincula con cuatro de sus medidas transversales: fortalecimiento del SIMA (1T), pronóstico (4T), gestión de contingencias (6T) y comunicación (9T) (Secretaría de Medio Ambiente del Estado de Nuevo León [SMA] y Clean Air Institute [CAI], 2024).

## 1.2 Importancia de la calidad del aire para la salud

Orellano et al. (2020), en un metaanálisis de 196 artículos, encontraron asociaciones positivas entre la exposición de corto plazo a PM10, PM2.5, NO2 y O3 y la mortalidad por todas las causas. Las partículas se asociaron además con mortalidad cardiovascular, respiratoria y cerebrovascular.

Las PM2.5 son las más preocupantes porque, por su tamaño, llegan a los alvéolos pulmonares. Los contaminantes primarios se emiten directamente; los secundarios, como el O3, se forman en la atmósfera a partir de precursores y radiación solar.

La Organización Mundial de la Salud redujo en 2021 su guía de PM2.5 a 15 µg/m³ en 24 h y 5 µg/m³ anual (World Health Organization, 2021). En la ZMM las partículas rebasan esos lineamientos, lo que el PIGECA reconoce como un riesgo significativo (SMA y CAI, 2024). Además, el PM10 muestra un ciclo anual, más alto en otoño-invierno, y concentraciones mayores en el occidente y en las zonas de mayor altitud (Aguirre-López et al., 2022).

## 1.3 Medición, variables y normas

Hay que distinguir tres referencias:

1. el **rango instrumental**, que delimita lo que el equipo puede medir y sirve para detectar errores;
2. el **límite normativo de salud**, que se define con un periodo de promedio;
3. el **Índice Aire y Salud** (NOM-172-SEMARNAT-2023; SEMARNAT, 2024), que comunica el riesgo cada hora.

En nuestros datos, las partículas se reportan en µg/m³, el CO en ppm y el resto de los gases en ppb; las normas expresan los gases en ppm (1 ppm = 1000 ppb). Los límites de salud se endurecen gradualmente. A diciembre de 2025 son:

| Contaminante | Norma | Promedio | Límite |
|---|---|---|---|
| PM10 | NOM-025-SSA1-2021 | 24 h | 50 µg/m³ |
| PM2.5 | NOM-025-SSA1-2021 | 24 h | 25 µg/m³ |
| O3 | NOM-020-SSA1-2021 | 1 h / 8 h móvil | 0.090 / 0.051 ppm |

*Fuente: SIMA (2026).*

Esta gradualidad complica comparar años, porque parte del aumento de excedencias se debe al cambio del límite (Hernández-Romero et al., 2026). SIMA señala además que las normas de salud se endurecen sin un cambio equivalente en las normas de emisión (SIMA, 2026).

## 1.4 Dificultades de la medición

Medir continuamente la calidad del aire implica varias dificultades:

- **Datos faltantes.** Fallas eléctricas, calibraciones y periodos fuera de línea invalidan horas (SIMA, 2026). El PIGECA reconoce que en algunos años no hay suficientes datos válidos para ciertos contaminantes y estaciones (SMA y CAI, 2024).
- **Errores instrumentales.** Valores fuera de rango, ceros, negativos, valores repetidos y saltos bruscos.
- **Inconsistencias entre variables.** Por eso SIMA compara PM10 con PM2.5 y revisa los cambios de más de 10 °C o 10 mm Hg en una hora (SIMA, 2026).
- **Representatividad espacial.** Cada estación refleja sus fuentes cercanas (Hernández-Romero et al., 2026).
- **Cambios en la red.** La red cambia con el tiempo: se agregan estaciones y no todas miden todas las variables (SMA y CAI, 2024).

Estas dificultades obligan a fijar criterios explícitos de limpieza (Parte II).

## 1.5 Antecedentes

Los estudios con datos de SIMA analizan un contaminante a la vez:

- **Aguirre-López et al. (2022)** estudiaron el PM10 mensual de siete estaciones entre 2010 y 2018. Reportan una tendencia decreciente con ciclo anual y proponen, como trabajo futuro, incorporar variables meteorológicas.
- **Hernández-Romero et al. (2026)** analizaron la persistencia de excedencias de PM10, PM2.5 y O3 en cinco estaciones entre 2019 y 2023. Usaron pruebas no paramétricas, correlaciones de Spearman por pares y una descomposición temporal sin regresores meteorológicos. Encontraron que ninguna estación cumplió de forma continua la norma de PM10 y que las partículas alcanzan su máximo en la temporada seca-fría, mientras que el O3 lo alcanza en las cálidas.
- **Ramírez-Velarde et al. (2024)** combinaron componentes principales y clasificadores para anticipar contingencias con meteorología de SIMA.
- **Hernandez-Santiago et al. (2026)** modelaron el O3 horario con XGBoost y validaron por temporadas.
- **Martínez-Cinco et al. (2016)**, desde la química, mostraron que el PM2.5 otoñal está dominado por emisiones vehiculares y se acumula con viento débil, mientras que en verano aumenta el sulfato secundario.

Fuera de México, el análisis multivariado se ha usado para clasificar patrones de contaminación:

- **Mohd Shafi'i y Juahir (2024)** combinaron conglomerados, discriminante y componentes principales para agrupar estaciones.
- **Elmourssi et al. (2026)** identificaron regímenes de contaminación con k-medias y evaluaron su estabilidad entre años.

## 1.6 Problema, pregunta y objetivos

**Problema.** SIMA gestiona y comunica la calidad del aire contaminante por contaminante. No existe una caracterización de qué **combinaciones** de contaminantes se repiten en la ZMM ni de las condiciones meteorológicas que las acompañan.

**Pregunta central.** ¿Qué combinaciones típicas de contaminantes ("regímenes diarios") se presentan en la ZMM entre 2021 y 2025? ¿En qué temporadas y estaciones ocurren? ¿Con qué condiciones meteorológicas se asocian? ¿Qué tan bien distingue la meteorología del día los regímenes de peor calidad del aire?

Los regímenes se construyen **solo con contaminantes**; la meteorología se usa después para caracterizarlos y discriminarlos.

**Objetivos:**

- **O1 (esta etapa).** Construir una base estación-día depurada y documentada, que reporte por variable el porcentaje de datos faltantes, invalidados e imputados.
- **O2.** Identificar entre tres y seis regímenes con componentes principales y conglomerados, y evaluar su estabilidad entre periodos con el Índice de Rand Ajustado.
- **O3.** Cuantificar la frecuencia de cada régimen por temporada y estación, y la proporción de días que rebasan los límites de PM10, PM2.5 y O3.
- **O4.** Evaluar, con análisis discriminante, si la meteorología observada del mismo día clasifica los regímenes mejor que una referencia basada solo en la temporada. Se entrena con 2021–2023 y se prueba con 2024–2025.
- **O5.** Implementar una interfaz que muestre la clasificación y su desempeño en los datos de prueba.

## 1.7 Justificación

En la literatura revisada no encontramos, para la ZMM, un análisis que agrupe días según la combinación conjunta de contaminantes con datos horarios de toda la red. Tampoco encontramos uno que evalúe qué tan bien la meteorología distingue esos tipos de día.

Proponemos un procedimiento que se apoya en tres antecedentes:

- el enfoque de regímenes de Elmourssi et al. (2026);
- la secuencia de técnicas de Mohd Shafi'i y Juahir (2024);
- la validación temporal de Hernandez-Santiago et al. (2026).

El aporte para SIMA es resumir seis contaminantes en pocos tipos de día que se puedan comunicar. Además, si la meteorología observada los distingue bien, la clasificación podría combinarse en el futuro con pronósticos meteorológicos para anticipar episodios. Usar la meteorología observada del mismo día no demuestra por sí solo capacidad de pronóstico.

## 1.8 Fuentes de datos

Usamos seis libros Excel proporcionados por SIMA (2020–2025), con mediciones horarias de 15 estaciones. Los complementamos con tres documentos del socio:

- `Etiquetas.xlsx`, con unidades, estaciones y banderas;
- *Rangos de los parámetros del SIMA*;
- *Ubicación de las estaciones de monitoreo*.

Los originales no se modificaron y su integridad se verificó con huellas MD5.

# Parte II. Comprensión y preparación de los datos

## 2.1 Importación y estructura

Importamos en R las 87 hojas (una por estación y año) conservando la estación, el año y la fila de origen, y unificamos la columna de fecha, que se llama `Fecha y hora` en 2020–2024 y `date` en 2025 (@tbl-dimensiones). La base tiene 754 603 registros y 16 columnas.

Características encontradas:

- **Resolución horaria** (99.98 % de saltos de 1 h), aunque `Etiquetas.xlsx` menciona "promedios diarios".
- Fechas sin zona horaria y sin cambio de horario visible. Las tratamos como hora local fija, pendiente de confirmar con SIMA.
- Sin duplicados.
- **Sin celdas no numéricas ni banderas de validez:** una celda vacía no indica la causa del faltante.
- **8 189 horas sin registro** (1.07 % de 762 792 esperadas). La mayoría corresponde a la estación NO3, que inicia en diciembre de 2022.

El diccionario completo está en el Anexo A.

## 2.2 Calidad de los datos

**Faltantes.** Sobre 762 792 horas esperadas por variable, el faltante original va de 4.7 % (radiación solar) a 26.0 % (PM2.5) (@fig-faltantes). Se concentra en 2020 y en las estaciones NE3 y NO3, que casi no miden PM2.5.

**Rangos.** Los contaminantes casi nunca violan los rangos de operación de SIMA (≤ 0.05 %). En la meteorología, esos rangos resultaron inadecuados como criterio de error:

- marcarían heladas reales de invierno;
- marcarían 1.1 % de las horas de presión, concentradas en las estaciones de mayor altitud, porque el rango es único para toda la red.

**Consistencia.**

- **PM2.5 > PM10:** solo 37 de 555 259 horas, lo que indica una depuración previa de SIMA.
- **NOX ≠ NO + NO2:** en 11.4 % de las horas de NE3 y 8.2 % de NTE2, frente a menos de 2 % en el resto.
- **Temperatura:** 1 082 lecturas se apartan más de 10 °C de la mediana de la red a la misma hora. Incluyen 25 horas en el límite del sensor (−50 °C) y valores bajo cero en verano.

Un cuaderno reproducible de auditoría documenta cada hallazgo (`notebooks/01_auditoria_datos_crudos.qmd`).

## 2.3 Selección de datos y variables

**Periodo.** Conservamos 2020 en la base publicada, pero lo excluimos del modelado por su baja cobertura y por el efecto atípico del confinamiento (Schiavo et al., 2023). El periodo de análisis es 2021–2025.

**Variables.**

- **Activas** (definen los regímenes): PM10 y PM2.5 (24 h), O3 (máximo diario del promedio móvil de 8 h), NO2, CO y SO2.
- **Meteorológicas:** temperatura, humedad, radiación, presión, viento y lluvia. Caracterizan los regímenes y sirven como predictoras en el discriminante.
- **Excluidas:** NO y NOX, por redundantes con NO2.

**Registros.** Entran los días completos en todas esas variables (núcleo B). Excluimos las estaciones NE3 y NO3, que casi no miden PM2.5. Quedan **14 398 días-estación de 13 estaciones** (60.7 % de sus días entre 2021 y 2025), entre 28.0 % (NTE) y 81.5 % (SE3) por estación.

La proporción de días retenidos es similar por temporada (59.2–61.5 %). Esto reduce, pero no descarta, un sesgo de selección: los faltantes podrían concentrarse en condiciones particulares.

Como sensibilidad conservamos un núcleo sin PM2.5 (Anexo C).

## 2.4 Limpieza

Sobre los datos horarios anulamos valores (NA con bandera), **sin eliminar filas**, cuando se cumplía alguno de estos criterios:

1. **Fuera de rango.** En contaminantes, el rango de operación del año; en meteorología, el del fabricante; en lluvia, el máximo de operación.
2. **Saltos de más de 10 °C o 10 mm Hg en una hora.**
3. **PM2.5 > PM10**, siguiendo las banderas de SIMA.
4. **Rachas de 24 h o más con valores idénticos.**
5. **Consistencia espacial.** Temperatura con desviación mayor de 10 °C, o humedad mayor de 40 puntos, respecto de la mediana de la red a la misma hora, cuando reportan al menos cinco estaciones. También las lecturas en el límite del sensor.

La prueba espacial es habitual en el control de calidad meteorológico (Fiebrich et al., 2010). Una lectura atípica es sospechosa, no necesariamente errónea; por eso los umbrales son una decisión del equipo, justificada por la distribución de las desviaciones y por la plausibilidad física.

Los extremos dentro de rango se conservaron, porque pueden ser episodios reales (Hernández-Romero et al., 2026). En total se anuló como máximo 0.82 % de las horas de una variable (NO).

**Imputación.** Usamos interpolación lineal en huecos de hasta 3 h, por estación y variable (Moritz & Bartz-Beielstein, 2017). No imputamos la lluvia ni las horas anuladas por la prueba espacial. Después volvimos a validar los valores imputados y revertimos los que violaban alguna regla: 3 599 en PM2.5, 252 en PM10, 54 en presión y 5 en humedad.

El imputado neto fue de 0 % a 2.88 % (PM2.5) y el faltante final quedó entre 4.5 % y 23.2 % (@tbl-limpieza). Un script valida automáticamente la base publicada, y dos revisiones independientes reprodujeron exactamente los CSV.

## 2.5 Transformación y preparación

- **Agregación diaria.** Un valor diario es válido con al menos 18 horas válidas, el criterio del 75 % de SIMA.
- **Viento.** Lo convertimos a m/s y a componentes u y v, porque la dirección es una variable circular.
- **Lluvia.** Como su unidad no está confirmada, la resumimos como horas con lluvia y un indicador 0/1.
- **Atributos derivados:** temporada (seca-fría, nov–feb; seca-cálida, mar–may; cálida-húmeda, jun–oct; definición operativa del equipo) e indicador del confinamiento de 2020.
- **No discretizamos concentraciones.** La estandarización se aplicará al modelar, ajustada solo con los datos de entrenamiento.

**Base limpia** (CSV horarios por año, CSV diario, diccionario y scripts): https://github.com/Leo-issacs/reto-sima-multivariados/tree/main/data/clean (versión `datos-v1.1`).

# Declaratoria de uso de IA (Opción B)

- **Herramientas:** Claude (Anthropic): Claude Opus y Claude Code; ChatGPT y Codex (OpenAI).
- **Uso realizado:**
  - Codex: preparación del entorno y revisión independiente del código y de los datos.
  - Claude Opus: planeación, búsqueda de literatura, decisiones de limpieza propuestas e integración y edición del texto.
  - Claude Code: scripts de R de importación, diagnóstico, limpieza y validación.
  - Claude y ChatGPT, usados por integrantes del equipo: borradores de 1.1–1.4 y fichas de lectura, a partir de los PDF de las fuentes.
- **Secciones:** Partes I y II, scripts en `scripts/` y `R/` y cuaderno de auditoría.
- **Validación realizada por los estudiantes:** **[COMPLETAR por el equipo con lo realmente revisado]**.
- Confirmamos que revisamos y verificamos el contenido final y asumimos la responsabilidad sobre él.

# Referencias

Aguirre-López, M. A., Rodríguez-González, M. A., Soto-Villalobos, R., Gómez-Sánchez, L. E., Benavides-Ríos, Á. G., Benavides-Bravo, F. G., Walle-García, O., & Pamanés-Aguilar, M. G. (2022). Statistical analysis of PM10 concentration in the Monterrey Metropolitan Area, Mexico (2010–2018). *Atmosphere, 13*(2), 297. https://doi.org/10.3390/atmos13020297

Elmourssi, D. M., El-Assy, A. M., & Amer, H. M. (2026). Clustering and machine learning techniques identify air pollution regimes in Greater Cairo. *Scientific Reports*. https://doi.org/10.1038/s41598-026-49777-5

Fiebrich, C. A., Morgan, C. R., McCombs, A. G., Hall, P. K., & McPherson, R. A. (2010). Quality assurance procedures for mesoscale meteorological data. *Journal of Atmospheric and Oceanic Technology, 27*(10), 1565–1582. https://doi.org/10.1175/2010JTECHA1433.1

Hernández-Romero, K., Hernández-Romero, I. M., Mendoza, A., Pérez-Rodríguez, M., Barajas-Villarruel, L. R., Medellín-Carrillo, S., & González, L. T. (2026). Persistent air pollution regimes and regulatory exceedances of PM10, PM2.5, and O3 in the Monterrey Metropolitan Area, Mexico. *City and Environment Interactions, 31*, 100410. https://doi.org/10.1016/j.cacint.2026.100410

Hernandez-Santiago, E., Tello-Leal, E., Jaramillo-Perez, J. M., & Macías-Hernández, B. A. (2026). Development of an ozone (O3) predictive emissions model using the XGBoost machine learning algorithm. *Big Data and Cognitive Computing, 10*(1), 15. https://doi.org/10.3390/bdcc10010015

Martínez-Cinco, M. A., Santos-Guzmán, J., & Mejía-Velázquez, G. M. (2016). Source apportionment of PM2.5 for supporting control strategies in the Monterrey Metropolitan Area, Mexico. *Journal of the Air & Waste Management Association, 66*(6), 631–642. https://doi.org/10.1080/10962247.2016.1159259

Mohd Shafi'i, M. S., & Juahir, H. (2024). Assessment of spatial air quality on the East Coast of Peninsular Malaysia utilizing environmetric techniques. *Environmental Monitoring and Assessment, 196*(7), 640. https://doi.org/10.1007/s10661-024-12787-9

Moritz, S., & Bartz-Beielstein, T. (2017). imputeTS: Time series missing value imputation in R. *The R Journal, 9*(1), 207–218. https://doi.org/10.32614/RJ-2017-009

Orellano, P., Reynoso, J., Quaranta, N., Bardach, A., & Ciapponi, A. (2020). Short-term exposure to particulate matter (PM10 and PM2.5), nitrogen dioxide (NO2), and ozone (O3) and all-cause and cause-specific mortality: Systematic review and meta-analysis. *Environment International, 142*, 105876. https://doi.org/10.1016/j.envint.2020.105876

Ramírez-Velarde, R., Esquivel-Flores, O., & Mejía-Velázquez, G. (2024). Forecasting air pollution contingencies using predictive analytic techniques. *Atmosphere, 15*(11), 1271. https://doi.org/10.3390/atmos15111271

Schiavo, B., Morton-Bermea, O., Arredondo-Palacios, T. E., Meza-Figueroa, D., Robles-Morua, A., García-Martínez, R., Valera-Fernández, D., Inguaggiato, C., & Gonzalez-Grijalva, B. (2023). Analysis of COVID-19 lockdown effects on urban air quality: A case study of Monterrey, Mexico. *Sustainability, 15*(1), 642. https://doi.org/10.3390/su15010642

Secretaría de Medio Ambiente del Estado de Nuevo León & Clean Air Institute. (2024). *Plan Integral de Gestión Estratégica de la Calidad del Aire 2023–2033 (PIGECA)*. Gobierno del Estado de Nuevo León. http://aire.nl.gob.mx/docs/reportes/PIGECA_2023_2033.pdf

SEMARNAT. (2024, 25 de enero). NOM-172-SEMARNAT-2023, Lineamientos para la obtención y comunicación del índice de calidad del aire y riesgos a la salud. *Diario Oficial de la Federación*.

Sistema Integral de Monitoreo Ambiental [SIMA]. (2026, 14 de agosto). *Red de monitoreo y manejo de datos de calidad del aire* [Presentación de diapositivas]. Gobierno de Nuevo León.

World Health Organization. (2021). *WHO global air quality guidelines: Particulate matter (PM2.5 and PM10), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide*. https://www.who.int/publications/i/item/9789240034228
