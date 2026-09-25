# Aprender análisis multivariado desde cero para el reto SIMA

Guía de estudio para Leo y su equipo · Septiembre de 2026

## 1. Para qué sirve esta guía

El equipo acaba de comenzar el bloque y tiene poca o ninguna experiencia en análisis multivariado. El propósito es adquirir vocabulario, criterio estadístico y capacidad para explicar las decisiones que se tomen después.

Esta es una síntesis didáctica preparada con asistencia de IA, apoyada en las referencias enlazadas. No es un documento oficial del curso ni un análisis de las bases SIMA. Los ejemplos son hipotéticos salvo indicación expresa. Las explicaciones deben contrastarse con las clases y las fuentes originales.

No hace falta estudiar toda la estadística a profundidad antes de comenzar. Conviene avanzar en tres niveles:

1. **Comprender:** saber qué pregunta responde cada concepto.
2. **Interpretar:** explicar un gráfico o resultado con palabras propias.
3. **Aplicar y justificar:** ejecutar el método, revisar sus condiciones y reconocer sus límites.

Ahora interesa construir los dos primeros niveles. La especialización vendrá cuando estén claras la pregunta y las posibilidades reales de los datos. Esta ruta de aprendizaje no fija el plan del proyecto, sus modelos ni sus entregables adicionales.

## 2. Contexto confirmado y cosas pendientes

Según el enunciado compartido, el reto aborda contaminantes y meteorología en estaciones de Monterrey, utiliza CRISP-DM y pide justificar técnicas y validar modelos. Incluye un reporte de equipo, un póster o presentación y una reflexión individual de 2–3 páginas. También menciona una interfaz gráfica para utilizar el modelo; su alcance está pendiente de aclarar.

Se han mencionado los siguientes archivos, cuyo contenido no se ha inspeccionado para redactar esta guía:

| Material | Qué habrá que averiguar al revisarlo |
|---|---|
| BD 2020.xlsx a BD 2025.xlsx | Variables, frecuencia temporal, cobertura, estaciones, unidades y calidad. Los nombres no garantizan años completos ni estructuras idénticas. |
| Etiquetas.xlsx | Si contiene el diccionario de variables, estaciones o códigos. |
| Rangos de los parámetros del SIMA.pdf | Qué significan sus rangos: instrumentales, de validación u otros. No asumir que son límites normativos. |
| Ubicación de las estaciones de monitoreo.docx | Coordenadas, identificadores y contexto de las estaciones. |
| Padrón medio ambiente.xlsx | Qué entidades contiene, de qué fecha son y qué uso permite. |
| INFO INVENTARIO SABANA 2018.xlsx | Qué inventaría y cómo se relaciona con los años de monitoreo. No representar automáticamente 2020–2025 con información de 2018. |
| PIMUS-Documento Ejecutivo.pdf | Qué contexto de movilidad o territorio puede aportar y para qué periodo. |

Posit Cloud + R + GitHub + Quarto es la opción preferida provisionalmente. Todavía no se ha decidido la pregunta, el método, el periodo de análisis ni la interfaz.

## 3. Cómo usar el material en NotebookLM

1. Añade este archivo `.md` como fuente desde la versión de escritorio/web.
2. Añade por separado el enunciado, los materiales docentes y las fuentes que vayas a estudiar. Una lista de enlaces dentro de este archivo no equivale a haber importado su contenido.
3. Incorpora los videos de la sección 4 mediante sus enlaces limpios. NotebookLM admite videos públicos de YouTube con subtítulos e importa su transcripción, por lo que las gráficas mostradas únicamente en pantalla pueden requerir revisión directa.
4. Para las diapositivas del campus, utiliza el archivo descargado desde tu acceso autorizado si la URL no se puede importar.
5. Copia al chat el mensaje de la sección 12 para iniciar la tutoría. Subir esta guía como fuente no garantiza que sus propuestas de estudio se ejecuten automáticamente.

Comprueba en cada fuente que la importación contiene texto útil. Pide referencias concretas y revisa las explicaciones dudosas. Los cálculos del futuro proyecto deberán verificarse en R; una explicación de NotebookLM no sustituye esa comprobación.

Fuente de funcionamiento: [Ayuda oficial para añadir fuentes a NotebookLM](https://support.google.com/gemininotebook/answer/16215270?hl=es).

## 4. Videos y material del curso

Los títulos y datos siguientes fueron proporcionados por el usuario. Se limpiaron los enlaces eliminando el texto pegado «Links to an external site». **No se pudo acceder a sus contenidos durante la preparación de esta guía; no se presentan como videos vistos ni resumidos.**

| Recurso | Enlace | Preguntas para orientar su estudio |
|---|---|---|
| Dr. Ernesto Reyes: Investigación sobre Contaminación del aire, semestre 2022 | https://youtu.be/rfquwYnsySU | ¿Cuál es el problema científico? ¿Qué datos y técnicas se utilizan? ¿Qué corresponde a 2022 y qué sigue siendo útil? |
| José Emilio Gómez S.: Un modelo de imputación de datos en datos de calidad del aire | https://youtu.be/GhwYOkN3vtM | ¿Cómo se definen los faltantes? ¿Cómo se evalúan las estimaciones? ¿Qué información necesita el método? |
| Introducción al reto, socio formador SIMA | https://youtu.be/vDNVaKJy6j4 | ¿Qué espera el socio formador? ¿Qué preguntas, restricciones y usos de los datos menciona? |
| Presentación del reto, diapositivas | https://experiencia21.tec.mx/courses/707681/files/292997472?wrap=1 | ¿Qué objetivos y requisitos están expresamente documentados? Puede requerir acceso al campus. |
| Retroalimentación a exposición de equipos, viernes 4 de septiembre, según el material compartido | https://youtu.be/wtXsJJUdNfQ | ¿Qué errores o mejoras se señalan? ¿Son observaciones generales o específicas de un equipo? |

Sobre el 28 de agosto de 2026, el material compartido dice que **no hubo sesión de preguntas**. No hay una grabación de esa sesión que debamos buscar a partir de esta lista.

Orden sugerido de estudio: introducción al reto y diapositivas; charla de investigación; conceptos básicos de faltantes y charla de imputación; retroalimentación. Es una propuesta pedagógica, no una secuencia oficial.

Para cada recurso, escribe cinco notas: idea principal, término nuevo, ejemplo, limitación y duda. Un trabajo de otro semestre puede enseñar un método, pero no define los requisitos vigentes del reto.

## 5. Ruta de aprendizaje desde cero

Realiza sesiones breves con explicación, ejemplo y una pregunta que debas responder sin ayuda. Avanza por comprensión, no por cantidad de videos vistos. Todos los integrantes necesitan una base común, aunque más adelante se repartan tareas.

### Módulo 1. Entender qué representa una tabla

Una **observación** es la unidad sobre la que se registra información. Una **variable** es una característica de esa unidad. En una tabla hipotética, una fila podría representar una estación en una hora y las columnas sus mediciones. Esa estructura debe comprobarse en los archivos reales.

| Estación ficticia | Fecha y hora ficticias | Temperatura, °C | PM2.5, µg/m³ |
|---|---|---:|---:|
| A | 2024-01-01 08:00 | 18 | 24 |
| A | 2024-01-01 09:00 | 20 | 28 |
| B | 2024-01-01 08:00 | 17 | NA |

Aquí hay tres observaciones. `NA` significa ausencia de un valor, no una concentración cero. La estación es categórica; temperatura y concentración son numéricas; la fecha y hora ubican la observación temporalmente.

**Aprende:** unidad de observación, variable numérica, categoría, identificador, unidad de medida, duplicado y dato faltante.

**Ejercicio:** explica por qué «estación A» puede aparecer varias veces sin que exista un duplicado. Después explica qué comprobarías si aparecen dos filas para A a la misma hora.

**Puedes avanzar cuando:** describes una fila sin confundirla con una persona, una estación completa o un promedio anual.

### Módulo 2. Estadística básica para leer los datos

La media resume mediante un promedio; la mediana identifica el centro de los datos ordenados. La desviación estándar describe dispersión. Un percentil indica una posición dentro de la distribución. Un histograma muestra cómo se reparten los valores; una serie temporal muestra cómo cambian con el tiempo.

La covarianza describe variación conjunta y depende de las unidades. La correlación de Pearson resume asociación lineal en una escala de −1 a 1. Correlación cero no descarta una relación no lineal. Ninguna de estas medidas demuestra por sí sola causalidad.

**Ejemplo inventado:** las concentraciones 10, 11, 12, 13 y 100 tienen media 29.2 y mediana 12. La diferencia invita a examinar el 100, no a borrarlo automáticamente.

**Aprende después:** muestra y población, incertidumbre, intervalos de confianza y valor p. Un valor p no es la probabilidad de que una hipótesis sea verdadera ni mide el tamaño de un efecto.

**Ejercicio:** dibuja esos cinco valores, calcula media y mediana y propone dos explicaciones distintas para el 100.

**Puedes avanzar cuando:** eliges una gráfica y explicas qué información perderías al comunicar solo un promedio.

### Módulo 3. Entender el problema ambiental

PM10 y PM2.5 designan fracciones de material particulado por tamaño, no sustancias químicas únicas. O₃ es ozono; NO₂, dióxido de nitrógeno; SO₂, dióxido de azufre; CO, monóxido de carbono. Conviene verificar la definición operativa de NOx en los datos.

El ozono a nivel del suelo puede formarse mediante reacciones entre precursores en presencia de luz solar. Por eso no todos los contaminantes deben interpretarse como emisiones directas de una instalación. [EPA: material particulado](https://www.epa.gov/pm-pollution/particulate-matter-pm-basics) y [EPA: formación de ozono](https://www.epa.gov/ground-level-ozone-pollution/ground-level-ozone-basics).

**Aprende a distinguir:** emisión y concentración; contaminante primario y secundario; medición horaria y promedio diario; concentración y clasificación de calidad del aire.

**Preguntas de estudio:** ¿qué puede hacer el viento con un contaminante?, ¿qué información adicional necesitaríamos para estudiar el efecto de lluvia, radiación, relieve o inversiones térmicas?, ¿cuál de esa información está realmente disponible?

No adoptes límites estadounidenses para interpretar cumplimiento en México. Si posteriormente se estudian excedencias, habrá que verificar la norma mexicana aplicable, el periodo de promediación, las unidades y los requisitos de suficiencia de datos.

**Puedes avanzar cuando:** diferencias «se midió más contaminación» de «se demostró quién la emitió».

### Módulo 4. Comprender CRISP-DM

El enunciado organiza el trabajo mediante comprensión del problema, comprensión y preparación de datos, modelado y evaluación, y despliegue/comunicación. En la representación habitual de seis fases, comprensión y preparación se separan, igual que modelado y evaluación.

| Fase | Pregunta que debes aprender a contestar |
|---|---|
| Comprensión del problema | ¿Qué queremos conocer y para quién sería útil? |
| Comprensión de los datos | ¿Qué registran y qué limitaciones tienen? |
| Preparación | ¿Qué transformamos y por qué? |
| Modelado | ¿Qué método responde a nuestra pregunta? |
| Evaluación | ¿Qué evidencia permite confiar en el resultado? |
| Despliegue/comunicación | ¿Cómo se interpreta y utiliza el producto final? |

No es una escalera irreversible: descubrir un problema de datos puede obligar a revisar la pregunta.

**Ejercicio:** explica por qué «hacer un PCA» describe una técnica, pero todavía no una pregunta de investigación.

### Módulo 5. Datos faltantes, errores e imputación

**Imputar** significa estimar un valor ausente. No convierte una estimación en una medición real. Primero hay que comprender cuándo, dónde y en qué variables faltan datos. Un valor extremo puede ser un error o un episodio real relevante. [FPP3: valores faltantes y atípicos](https://otexts.com/fpp3/missing-outliers.html).

**Aprende:** porcentaje de faltantes, duración de huecos, ausencia por estación, banderas de calidad y diferencia entre un dato inválido y uno no registrado. Después estudia MCAR, MAR y MNAR: describen supuestos sobre cómo se relaciona la ausencia con la información observada o no observada; no se identifican solo contando huecos.

**Ejemplo hipotético:** faltar una hora entre dos mediciones y faltar un mes completo plantean dificultades diferentes. Rellenar todo con la media puede borrar variación y modificar relaciones entre variables.

Para aprender a evaluar una imputación, imagina ocultar valores conocidos y comparar su estimación con el original. Incluye huecos continuos si esa es la situación relevante; acertar valores aislados no demuestra que el método reconstruya periodos largos. Esa simulación tampoco prueba que los faltantes reales se comporten igual.

**Puedes avanzar cuando:** explicas por qué hay que conservar la marca de los datos imputados y cómo evaluarías el método sin conocer los valores realmente ausentes.

### Módulo 6. Entender el mapa de técnicas multivariadas

La palabra «multivariado» se usa a veces ampliamente para estudiar muchas variables. En regresión conviene distinguir con precisión una respuesta de varias respuestas.

| Técnica | Idea central | Pregunta hipotética, no elegida para el proyecto |
|---|---|---|
| Regresión lineal múltiple | Relacionar una respuesta numérica con varios predictores. | ¿Cómo varía PM2.5 junto con temperatura, humedad y viento? |
| Regresión multivariada | Modelar conjuntamente varias respuestas numéricas. | ¿Cómo se relaciona la meteorología con PM2.5 y O₃ considerados conjuntamente? |
| Componentes principales, PCA | Resumir variación mediante combinaciones de variables. | ¿Puede resumirse un conjunto de mediciones en pocos ejes? |
| Análisis factorial | Representar covariación mediante factores latentes y variación específica. | ¿Hay dimensiones subyacentes compatibles con las relaciones observadas? |
| Conglomerados o clustering | Construir grupos por semejanza sin etiquetas previas. | ¿Qué estaciones presentan perfiles parecidos? |
| Análisis discriminante | Clasificar usando grupos conocidos durante el aprendizaje. | ¿Podemos distinguir tipos de días previamente definidos? |

Material de consulta: [Penn State, panorama de análisis multivariado](https://online.stat.psu.edu/stat505/). Es un curso de posgrado: al principio interesa consultar conceptos concretos, no completar todas sus demostraciones.

**Regresión múltiple:** en una fórmula como `PM2.5 = b0 + b1 × temperatura + b2 × humedad + error`, los coeficientes describen relaciones condicionadas a los demás predictores del modelo. Deben revisarse la forma de la relación, los residuos, su dependencia, su dispersión y la colinealidad. La normalidad de los errores interviene en la inferencia clásica; no significa que todas las variables deban ser normales. Un R² alto no garantiza predicción futura ni causalidad. [Penn State: regresión múltiple](https://online.stat.psu.edu/stat501/Lesson05).

**PCA y factores:** no son sinónimos. Aprende a interpretar cargas, puntuaciones y variación explicada, y a justificar el escalado cuando las unidades difieren. Nombrar un componente «industria» no demuestra que mida emisiones industriales. La interpretación necesita evidencia externa.

**Clustering:** aprende qué significa distancia, por qué la escala influye y cómo cambian los grupos al elegir variables o método. Un algoritmo puede producir grupos sin que estos sean categorías ambientales reales. [Penn State: conglomerados](https://online.stat.psu.edu/stat505/Lesson14).

**Discriminante:** requiere etiquetas conocidas. La versión lineal clásica modela distribuciones normales por grupo con una matriz de covarianza compartida; conviene estudiar esos supuestos y los errores de clasificación. [Penn State: análisis discriminante](https://online.stat.psu.edu/stat555/node/101/).

**Ejercicio:** inventa una pregunta para cada fila de la tabla e identifica cuáles requieren una respuesta o etiqueta y cuáles exploran estructura.

**Puedes avanzar cuando:** justificas una técnica por su pregunta y reconoces al menos una conclusión que esa técnica no permite.

### Módulo 7. Tiempo, espacio y validación

Mediciones cercanas en el tiempo o procedentes de una misma estación pueden parecerse. Tener muchas filas no equivale a tener la misma cantidad de observaciones independientes.

Si el objetivo fuera predecir el futuro, el entrenamiento debe usar información disponible antes del momento que se predice. La validación con origen móvil evalúa sucesivamente desde distintos puntos del pasado. [FPP3: validación temporal](https://otexts.com/fpp3/tscv.html).

**Ejemplo didáctico:** entrenar con años anteriores y evaluar con un periodo posterior puede simular una predicción futura. No estamos eligiendo todavía qué años usar. Predecir en una estación nunca observada plantea otra evaluación: habría que reservar estaciones, posiblemente combinando separación temporal y espacial.

**Fuga de información:** ocurre cuando el modelo recibe información que no tendría al usarse. Ejemplos: conocer la meteorología real de mañana al afirmar que se pronostica hoy, o ajustar imputaciones y escalado utilizando también el conjunto reservado para evaluación. Los pasos aprendidos de los datos deben ajustarse dentro de cada partición de entrenamiento.

**Aprende:** entrenamiento, validación, prueba final, sobreajuste, modelo de referencia y residuos. Para predicción numérica, MAE resume error absoluto y RMSE da más peso a errores grandes. Para clasificación, examina la matriz de confusión y el tipo de error, no solo el porcentaje total de aciertos.

PCA y clustering también necesitan evaluación, pero no la misma que un pronóstico: interesa examinar estabilidad, sensibilidad e interpretación.

**Puedes avanzar cuando:** explicas cómo un resultado aparentemente excelente puede deberse a una evaluación incorrecta.

### Módulo 8. R y las herramientas, sin perder de vista la estadística

Aprende primero a leer un archivo, reconocer tipos de columnas, contar registros, filtrar, agrupar, resumir y dibujar. Después estudia uniones de tablas, fechas y tratamiento explícito de faltantes. [R for Data Science, segunda edición](https://r4ds.hadley.nz/); el sitio enlaza traducciones al español.

Roles previstos: R realiza los cálculos; RStudio es el entorno de trabajo que puede utilizarse en Posit Cloud; GitHub permite organizar el historial compartido; Quarto combina explicación, código y resultados en documentos. Aprender el flujo importa más que memorizar botones.

**Ejercicio inicial:** con los cinco valores ficticios del módulo 2, calcula media y mediana en R y comprueba a mano el resultado. Explica cada línea antes de copiar código más complejo.

Mantén separados archivos originales, transformaciones y resultados. Anota el origen de datos, decisiones y versiones necesarias para reproducir el trabajo. Esto es aprendizaje de buenas prácticas; no se está configurando todavía el repositorio.

**Puedes avanzar cuando:** otra persona entiende qué entra en un cálculo, qué sale y qué transformación ocurrió entre ambos.

## 6. Cómo estudiar la rosa de los vientos compartida

Una rosa de los vientos resume frecuencias por dirección y categorías de velocidad. En la convención meteorológica, indica de dónde viene el viento. La rosa no identifica por sí sola fuentes de contaminación. [Documentación de `windRose`](https://openair-project.github.io/openair/reference/windRose.html) y [ejemplos del libro de openair](https://openair-project.github.io/book/sections/directional-analysis/wind-roses.html).

El script compartido permite practicar estas preguntas:

- `datos` debe existir: ¿qué tabla, estación y periodo contiene?
- `WS = as.numeric(WSR) / 3.6` presupone que WSR está en km/h. ¿Lo confirma el diccionario?
- `WD = as.numeric(WDR)`: ¿WDR representa grados y qué códigos utiliza?
- `filter(!is.na(WS), !is.na(WD))` elimina ausencias, pero no garantiza que los valores restantes sean válidos.
- `angle = 22.5` divide la circunferencia en 16 sectores.
- `breaks` define categorías de velocidad: ¿se corresponden con las unidades resultantes?
- La leyenda de colores representa velocidad; por eso `key.header = "Frecuencia (%)"` merece revisión. El porcentaje corresponde a la escala de frecuencias del gráfico.
- ¿Cómo se tratan las calmas y cuánto cambia la rosa si se mezclan estaciones o estaciones del año?

**Ejercicio:** describe una barra sin hablar de emisiones. Luego explica qué evidencia adicional necesitarías para relacionarla con un contaminante. No se ha ejecutado ni corregido el script en esta etapa.

## 7. Qué aprender primero y qué puede esperar

| Prioridad | Contenido | Evidencia de aprendizaje |
|---|---|---|
| Primero | Módulos 1–5 e introducción al reto | Explicas una fila, una gráfica, una ausencia y una pregunta investigable. |
| Después | Panorama del módulo 6, validación y R básico | Comparas técnicas y reconoces un ejemplo de fuga de información. |
| Cuando se delimite la pregunta | Método elegido, sus supuestos y alternativas | Justificas su uso, evalúas resultados y declaras limitaciones. |
| Solo si hace falta | Modelos espaciales complejos, aprendizaje automático avanzado o atribución de fuentes | Existe una necesidad documentada y datos adecuados. |

Para profundizar en PCA necesitarás nociones de vectores, matrices, combinaciones lineales y, posteriormente, autovalores y autovectores. Para comenzar basta una explicación geométrica; las exigencias matemáticas de la clase se incorporarán conforme avance el bloque.

## 8. Autoevaluación breve

Responde sin consultar la guía antes de pedir retroalimentación:

1. ¿Qué podría representar una fila de SIMA y por qué todavía debemos confirmarlo?
2. ¿Por qué cero y NA no significan lo mismo?
3. ¿Qué diferencia existe entre regresión múltiple y multivariada?
4. ¿Qué distingue clasificación de clustering?
5. ¿Qué resume un componente principal y qué no demuestra?
6. ¿Por qué no conviene borrar todos los valores extremos?
7. ¿Cómo comprobarías una imputación en un ejercicio con valores conocidos?
8. ¿Qué cambia entre reconstruir datos históricos y pronosticar el futuro?
9. ¿Por qué dividir horas al azar puede ser inadecuado para evaluar un pronóstico?
10. ¿Puede una rosa de los vientos identificar una empresa emisora?
11. ¿Qué información necesitas antes de hablar de una excedencia normativa?
12. ¿Por qué un R² alto no basta para aceptar un modelo?

Cuenta una respuesta como comprendida si incluye una explicación, un ejemplo y una limitación. Los errores indican qué repasar; no son un impedimento para aprender con el equipo.

## 9. Glosario inicial

| Término | Definición breve |
|---|---|
| Predictor | Variable utilizada para explicar o predecir una respuesta. |
| Respuesta | Resultado que interesa modelar. |
| Residuo | Diferencia entre un valor observado y el ajustado por un modelo. |
| Colinealidad | Relación fuerte entre predictores que puede dificultar separar sus asociaciones. |
| Estandarización | Cambio de escala; una forma común resta la media y divide por la desviación estándar. |
| Autocorrelación | Asociación de una variable consigo misma en distintos momentos o separaciones. |
| Estacionalidad | Patrón que se repite con una periodicidad reconocible. |
| Rezago | Valor observado en un momento anterior. |
| Imputación | Estimación de un dato ausente. |
| Sobreajuste | Adaptación excesiva a los datos de entrenamiento con mala generalización. |
| Carga | Peso o relación de una variable en una dimensión; su definición precisa depende del método. |
| Puntuación | Coordenada de una observación en una dimensión calculada. |
| Factor latente | Dimensión no observada directamente que se propone para explicar covariación. |
| Reproducibilidad | Posibilidad de obtener los resultados siguiendo datos, código y decisiones documentados. |

## 10. Plantilla para notas de estudio

Completa esta ficha después de una lectura o video:

- Fuente y sección o minuto:
- Idea central en mis palabras:
- Concepto que aprendí:
- Ejemplo hipotético que puedo explicar:
- Dato o afirmación realmente respaldado por la fuente:
- Interpretación mía que todavía debo comprobar:
- Limitación del método:
- Duda para el equipo o las profesoras:

No conviertas una recomendación de un video, de esta guía o de un asistente en un requisito oficial sin localizar su respaldo en el material vigente del curso.

## 11. Lecturas seleccionadas

Estas fuentes son de consulta, no una lista de libros que debas terminar. Importa capítulos o páginas concretas según lo que estés aprendiendo.

1. [R for Data Science](https://r4ds.hadley.nz/): lectura, transformación, visualización de datos y documentos reproducibles.
2. [Penn State STAT 501](https://online.stat.psu.edu/stat501/): regresión y evaluación de sus condiciones.
3. [Penn State STAT 505](https://online.stat.psu.edu/stat505/): consulta de técnicas multivariadas; nivel avanzado.
4. [FPP3: validación temporal](https://otexts.com/fpp3/tscv.html): separar pasado y futuro al evaluar pronósticos.
5. [FPP3: datos faltantes y atípicos](https://otexts.com/fpp3/missing-outliers.html): pensar antes de reemplazar observaciones.
6. [openair: rosas de los vientos](https://openair-project.github.io/book/sections/directional-analysis/wind-roses.html): gráficos meteorológicos aplicados.
7. [EPA: PM](https://www.epa.gov/pm-pollution/particulate-matter-pm-basics) y [EPA: ozono](https://www.epa.gov/ground-level-ozone-pollution/ground-level-ozone-basics): conceptos ambientales, no normas para México.

## 12. Mensaje para iniciar la tutoría en NotebookLM

Copia el siguiente texto en el chat después de añadir las fuentes que correspondan:

> Quiero que me ayudes a aprender desde cero para un proyecto universitario de análisis multivariado sobre calidad del aire en Monterrey con datos SIMA. Ni yo ni mi equipo dominamos todavía estos temas. Usa la fuente «Aprender análisis multivariado desde cero para el reto SIMA» como ruta orientativa, diferenciándola de los requisitos oficiales y de las fuentes académicas.
>
> Empieza con cinco preguntas breves para diagnosticar mis conocimientos, una por una. Después enséñame el primer concepto que necesite. Para cada concepto, ofrece una explicación sencilla, un ejemplo pequeño de calidad del aire claramente marcado como hipotético y un ejercicio. Espera mi respuesta antes de mostrar la solución. Corrige mis errores explicando por qué y pídeme que lo reformule con mis palabras.
>
> Trabaja en español, explica las siglas y presenta fórmulas solo después de la intuición. Cita las fuentes que hayas podido consultar. Si falta información, indícalo. No inventes contenido de videos, variables de Excel, resultados SIMA ni reglas del curso. No uses esta guía como prueba de afirmaciones ambientales locales. Todavía estamos reuniendo materiales: no elijas la pregunta definitiva, el modelo ni el plan del proyecto.

### Mensaje opcional para profundizar con fuentes

> Sobre el tema [ESCRIBIR TEMA], prepara una explicación por niveles: intuición, ejemplo, condiciones de uso, errores frecuentes, evaluación y límites. Usa únicamente las fuentes disponibles y señala qué falta investigar. Distingue consenso de las fuentes, desacuerdos e inferencias. Termina con tres preguntas para comprobar mi comprensión; no incluyas todavía las respuestas.

### Mensaje para estudiar una charla

> Trabaja únicamente con la fuente [NOMBRE DEL VIDEO]. Identifica el problema, los datos, el método, la evaluación y las limitaciones que realmente menciona. Incluye referencias localizables cuando estén disponibles. Separa explícitamente lo dicho por el ponente de tus interpretaciones. Si la transcripción no describe una gráfica, no inventes su contenido. Finalmente explícame los tres conceptos previos que necesito aprender para comprender la charla.

### Mensaje para repasar con el equipo

> Haznos una práctica oral sobre [TEMA]. Formula una pregunta por turno, pide un ejemplo y solicita que otro integrante cuestione una limitación de la respuesta. Al terminar, resume qué comprendimos, qué confundimos y qué fuente debemos repasar. No conviertas este ejercicio en decisiones del proyecto.

## 13. Punto de llegada de esta preparación

La meta inicial es poder decir: «entiendo qué representa el dato, qué pregunta quiero responder, qué técnica podría servir, cómo comprobaría el resultado y qué no puedo concluir». No hace falta resolver el proyecto ahora. Hace falta aprender lo suficiente para participar en sus decisiones con criterio.
