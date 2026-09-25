# Plan de ejecución del reto SIMA en cinco semanas

**Objetivo:** responder una pregunta acotada sobre calidad del aire mediante análisis multivariado, con resultados reproducibles y comprensibles para el socio formador.

**Arquitectura:** un repositorio para el equipo, scripts de R y un reporte Quarto acumulativo. Los originales se conservan fuera del historial de Git; las transformaciones y decisiones quedan documentadas.

**Herramientas:** Posit Cloud, R/RStudio, GitHub y Quarto; `renv` con el lockfile de la plantilla del curso. Diseño de referencia: [DISENO_BASE.md](DISENO_BASE.md).

**Condiciones conocidas:** cuatro integrantes y una entrega semanal durante cinco semanas, según lo comunicado por Leo. No se conocen fechas exactas, rúbricas parciales ni nombres de los integrantes. Esta distribución es una propuesta ajustable, no el calendario oficial del curso.

## Requisito de entrega del entorno

Actualización del 25 de septiembre de 2026: crear un repositorio público basado en el entorno R de `Krul-dev/2003B_Blank`, dar acceso de edición a los cuatro integrantes y entregar una sola URL por equipo. Esta actividad de arranque no requiere esperar al análisis final. Se leyeron las 14 páginas de `Instructions_MA2003B.pdf`; los pasos están integrados en `INICIO_GITHUB_POSIT.md`. Se mantiene R como ruta elegida; la alternativa Python no se configura en paralelo.

## Resultado mínimo viable

Una pregunta principal, una selección justificada de estaciones y periodos, una base preparada y trazable, un método multivariado principal con evaluación adecuada y los entregables del curso. Una técnica complementaria solo se incorpora si aporta a la pregunta y cabe en el tiempo.

No es necesario cubrir los siete ejes del enunciado ni utilizar todas las técnicas. La atribución de emisiones a empresas, los mapas complejos y los pronósticos operativos requieren evidencia adicional; no se asumen como alcance inicial.

## Qué ya existe y qué falta

Esta base incluye plan, estructura, catálogos iniciales, inventario de encabezados y plantillas. El repositorio está en [GitHub](https://github.com/Leo-issacs/reto-sima-multivariados). Falta completar los accesos de colaboradores, abrir los proyectos Posit, confirmar metadatos, evaluar todos los registros, seleccionar la pregunta y desarrollar el análisis y la interfaz. Consultar [VERIFICACION_BASE.md](VERIFICACION_BASE.md) para las comprobaciones ejecutadas.

## Distribución semanal

| Semana | Foco CRISP-DM | Producto propuesto para revisión | Condición para pasar |
|---|---|---|---|
| 1 | Problema y comprensión inicial | Pregunta provisional, fuentes, inventario, diccionario inicial y primer reporte | Factibilidad documentada y dudas críticas asignadas. |
| 2 | Comprensión y preparación | Datos preparados, control de calidad, exploración y pregunta delimitada | Unidades/reglas confirmadas para las variables elegidas y reproducción revisada. |
| 3 | Modelado | Método principal, comparación de referencia y resultados preliminares | Procedimiento de evaluación definido antes de ajustar decisiones al resultado. |
| 4 | Evaluación y uso | Evaluación final, sensibilidad, interpretación y prototipo de interfaz | Resultados revisados y demostración utilizable con límites visibles. |
| 5 | Comunicación y entrega | Reporte, póster/diapositivas, demostración y reflexiones individuales | Reproducción desde sesión limpia, revisión visual y coherencia de cifras. |

Si las profesoras asignan otro contenido semanal, actualizar esta tabla y el tablero de tareas conservando el trabajo ya validado. Cada fin de semana significa una versión revisada del reporte; no exige inventar un documento distinto.

## Semana 1 — Pregunta viable y puesta en marcha

**Objetivo:** entender qué es posible responder y establecer un modo de trabajo que los cuatro puedan usar.

- [ ] **Manual, equipo:** leer el enunciado y la introducción SIMA. Recuperar rúbrica, etiquetas, rangos y ubicación de estaciones. Registrar fuente y versión en `docs/FUENTES.md`.
- [ ] **Manual, coordinación:** completar los permisos de edición de los otros tres integrantes y abrir una copia por persona en Posit Cloud. El repositorio público ya está creado. Seguir `INICIO_GITHUB_POSIT.md`.
- [ ] **Automatizado, responsable de datos:** ejecutar `scripts/00_verificar_entorno.R` y `scripts/01_inventario.R`. Comparar hojas y encabezados con `data/metadata/inventario_hojas_inicial.csv`.
- [ ] **Manual, datos + revisor:** completar unidades, significados, códigos inválidos y zona horaria en `config/variables.csv` y `DECISIONES.md`; conservar explícitamente lo no confirmado.
- [ ] **Manual, método:** proponer como máximo tres preguntas con población, variables, periodo, utilidad y restricciones. Revisar literatura del tema elegido.
- [ ] **Manual, equipo:** elegir una pregunta provisional y pedir retroalimentación docente. Si faltan metadatos críticos, preparar una pregunta alternativa menos dependiente de ellos.
- [ ] **Reproducible, comunicación:** actualizar las primeras secciones de `quarto/reporte.qmd`, generar Word y revisar el documento.

**Aceptación:** los cuatro abren el proyecto; las bases tienen inventario; hay una pregunta provisional evaluable, una lista concreta de faltantes y un responsable por duda. La presencia de una columna no se confunde con disponibilidad suficiente de sus valores.

**Posibles preguntas, aún sin seleccionar:** asociación entre un contaminante y meteorología; perfiles conjuntos de contaminantes entre estaciones comparables; evaluación de imputación para huecos de una variable. La tercera cambia el foco hacia calidad de datos y necesita confirmar su aceptación docente.

## Semana 2 — Preparación y exploración

**Objetivo:** producir una base de análisis entendida y reproducible.

- [ ] **R, datos:** implementar `scripts/02_preparar.R` y funciones pequeñas en `R/`. Importar conservando archivo, hoja y fila de origen; homogeneizar `Fecha y hora`/`date` sin inventar zona horaria.
- [ ] **R, datos:** evaluar registros efectivos, fechas, duplicados estación-fecha, tipos, huecos y faltantes por variable/estación/periodo. Las dimensiones declaradas por Excel no bastan.
- [ ] **Manual, método + revisor:** acordar población, granularidad y criterios de inclusión según la pregunta y requisitos oficiales. Justificar cualquier umbral de cobertura; no utilizar uno arbitrario como si fuera norma.
- [ ] **R, datos:** conservar valores originales y banderas de transformación. No sustituir automáticamente vacíos por cero ni descartar valores extremos solo por ser altos.
- [ ] **R, método:** implementar `scripts/03_explorar.R` con series temporales, distribuciones y relaciones entre variables seleccionadas. Añadir rosa de vientos solo tras confirmar unidades y códigos.
- [ ] **Manual, equipo:** cerrar pregunta y alcance con la evidencia disponible; registrar exclusiones y alternativas descartadas.
- [ ] **Revisión cruzada:** repetir preparación en otra copia del proyecto y comparar conteos y resultados. Actualizar el reporte.

**Aceptación:** otro integrante reproduce la base preparada, explica cada exclusión y concilia entradas/salidas. Los huecos, las estaciones nuevas y los cambios de periodo no desaparecen al unir archivos. Si las unidades de una variable siguen sin confirmarse, no se convierte ni se incorpora a interpretación cuantitativa.

## Semana 3 — Modelo principal y evaluación diseñada

**Objetivo:** construir una primera respuesta a la pregunta sin sobrecargar el proyecto.

- [ ] **Manual, método:** justificar la técnica, sus supuestos y el resultado esperado en una ficha dentro del reporte. Distinguir descripción, asociación, clasificación y pronóstico.
- [ ] **Manual, revisión:** fijar evaluación, métricas y comparación de referencia antes de elegir el mejor resultado. Registrar la partición o esquema de remuestreo y la semilla cuando corresponda.
- [ ] **R, método:** implementar `scripts/04_modelar.R`. Ajustar transformaciones aprendidas e imputación dentro del entrenamiento si existe evaluación predictiva.
- [ ] **R, revisión:** ejecutar diagnósticos; revisar residuos, colinealidad y dependencia para regresión, o escalado, cargas/variación y estabilidad para PCA y conglomerados.
- [ ] **Manual, comunicación:** escribir qué muestran los resultados y qué no demuestran. No atribuir causalidad ni fuentes industriales a partir de correlaciones o proximidad.
- [ ] **Manual, equipo:** definir con las profesoras qué debe permitir la interfaz y elegir una interacción mínima ligada al método.

**Aceptación:** modelo ejecutable con parámetros registrados, comparación razonable y límites explícitos. Si el método no cumple condiciones, simplificar o justificar una alternativa; no acumular métodos para esconder el problema.

Para pronóstico se respeta el orden temporal y la disponibilidad real de predictores. Para generalizar a estaciones nuevas se evalúa esa separación. Para métodos exploratorios no se impone una división entrenamiento/prueba sin finalidad: se evalúan estabilidad, sensibilidad e interpretación.

## Semana 4 — Validación e interfaz mínima

**Objetivo:** revisar la respuesta y demostrar cómo se utilizaría.

- [ ] **R, revisión:** implementar `scripts/05_evaluar.R`; aplicar el protocolo decidido en la semana 3 y conservar resultados completos, incluidos fallos.
- [ ] **R, método:** estudiar sensibilidad a decisiones relevantes: periodo, estaciones, imputación, escalado o número de componentes/grupos, según el método.
- [ ] **Manual, equipo:** discutir incertidumbre, utilidad y límites. Si hay prueba final reservada, no reajustar repetidamente el modelo después de verla sin reconocerlo.
- [ ] **R/GUI, responsable de implementación:** construir la interfaz definida en `app/README.md`. Para un modelo predictivo puede recibir entradas y mostrar estimación; para uno exploratorio debe mostrar sus resultados con una interacción pertinente aceptada por la docente.
- [ ] **Manual, revisor:** probar una entrada válida, una incompleta, una fuera de alcance y correspondencia con resultados de R. Revisar etiquetas, unidades y advertencias específicas.
- [ ] **Manual, comunicación:** integrar retroalimentación y preparar un borrador de presentación con una conclusión respaldada por cada figura.

**Aceptación:** evaluación documentada y demostración funcional sin resultados inventados. El despliegue público no se presume obligatorio: confirmar si basta demostración en el entorno del equipo.

## Semana 5 — Cierre y entrega

**Objetivo:** entregar una solución que todos puedan explicar y reproducir.

- [ ] **Reproducible, integrante distinto del autor principal:** restaurar paquetes, disponer de las mismas fuentes y ejecutar el flujo desde una sesión limpia. Registrar versiones y tiempo aproximado.
- [ ] **Manual, equipo:** verificar trazabilidad pregunta → datos → método → evaluación → conclusión → recomendación. Ajustar afirmaciones a la evidencia.
- [ ] **Quarto, comunicación:** generar Word y, si lo exigen, PDF mediante el formato aceptado. Revisar tablas, figuras, bibliografía, títulos y anexos.
- [ ] **Manual, equipo:** terminar póster o diapositivas y ensayar exposición. Cada integrante explica al menos una decisión metodológica y una limitación.
- [ ] **Individual:** redactar la reflexión de 2–3 páginas sobre el valor de los modelos y el aprendizaje propio.
- [ ] **Manual, coordinación:** comprobar rúbrica final, nombres, formato y canal de entrega; guardar la versión exacta entregada y su commit de referencia en `docs/ENTREGAS.md`.

**Aceptación:** archivos abren, resultados coinciden, fuentes están citadas, interfaz se demuestra y cada entrega tiene evidencia de revisión. La entrega al campus la realiza la persona acordada por el equipo.

## Cadencia dentro de cada semana

Inicio: 20–30 minutos para leer retroalimentación y asignar tareas. Mitad: revisión corta de un resultado concreto, no solo estado verbal. Antes del cierre: revisión por otra persona, generación del reporte y comprobación de formato. Tras la entrega: registrar comentarios y ajustar la siguiente semana.

Reservar al menos un bloque de trabajo al final de cada semana para integración y correcciones. Las horas exactas dependen de disponibilidad y rúbrica; no se han estimado como compromiso del equipo.

## Criterios generales y contingencias

| Situación | Acción concreta |
|---|---|
| Faltan etiquetas o rangos | Recuperar el material con la docente; avanzar en inventario y literatura. No adivinar unidades o códigos. |
| Cobertura insuficiente | Reducir periodo/estaciones/variables y explicar la selección antes de imputar extensamente. |
| Recursos limitados en Posit | Procesar archivos por etapas y guardar derivados; evaluar RStudio local si sigue siendo insuficiente. |
| Muchas tareas abiertas | Cerrar primero un análisis principal reproducible y el reporte; posponer mapas o técnicas opcionales. |
| Rúbrica exige otra técnica | Ajustar el modelo al requisito y a una pregunta coherente, con asesoría docente. |
| Integración difícil en Git | Un archivo o sección con responsable temporal, cambios pequeños y revisión antes de integrar. |
| Interfaz consume demasiado tiempo | Una sola interacción útil; confirmar el mínimo aceptable antes de ampliar. |
| No puede reproducirse un resultado | Detener su incorporación al reporte y revisar datos, versiones, semilla y transformaciones. |

La ejecución futura se realiza tarea por tarea, verificando cada hito. No se deben implementar todos los modelos o decisiones pendientes solo porque aparezcan mencionados como alternativas.
