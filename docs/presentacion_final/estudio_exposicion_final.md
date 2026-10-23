# Guía de estudio para la exposición final — Reto SIMA, Equipo 1

Úsala en este orden. Lo que está **arriba** es lo que no puede fallar.

1. La historia en 30 segundos (§1).
2. Las cifras de memoria (§2).
3. Lo que hay que **corregir al decirlo** (§3): el guion tiene frases que ya no coinciden con el informe final.
4. Los conceptos explicados simple (§4).
5. El dashboard, pestaña por pestaña (§5).
6. Las preguntas difíciles (§6).

La retroalimentación de la exposición anterior dijo dos cosas que hay que corregir:

- **«Interacción desigual: dos cargaron la participación y uno no habló».** Hablan los 4 y **todos contestan preguntas** (§6 dice quién).
- **«El interés del socio pareció moderado».** Cierren con lo que SIMA puede usar ya, no solo con lo que falta (§1, última línea).

---

## 1. La historia en 30 segundos

> Queríamos saber **cuánto ayuda la meteorología del día** a identificar los días con PM2.5 mayor de 25 µg/m³ en 13 estaciones del SIMA, comparado con un modelo que solo sabe **la estación y la temporada**.
> **Sí ayuda:** el AUC sube de **0.713 a 0.792** (+0.079, IC 95 % [0.054, 0.104]) y se detecta el **74 %** de los días con superación en lugar del **56 %**.
> Ayuda sobre todo de **marzo a mayo** y casi nada en **lluvias**. Las condiciones asociadas son **viento débil, presión más baja de lo normal para el sitio y más temperatura**.
> Pero el **PM2.5 de ayer clasifica mejor (0.872)**, y la meteorología solo le agrega 0.016. Además es **retrospectivo**: usa el clima observado, no un pronóstico.
> **Para SIMA:** (1) probarlo con meteorología pronosticada y con la persistencia como base; (2) dos reglas de control de calidad listas para usar; (3) revisar el equipo de PM2.5 de García y la radiación de García y Escobedo.

---

## 2. Cifras que hay que saber de memoria

| Qué | Cifra | Cómo decirlo |
|---|---|---|
| Estaciones y periodo | 13 estaciones, 2021–2025 | Se excluyen NE3 y NO3 porque casi no miden PM2.5 |
| Unidad de análisis | **17 828 días-estación** | Un día-estación es el promedio de 24 h de una estación en un día |
| Entrenamiento / prueba | 10 965 (2021–2023) / 6 863 (2024–2025) | Superación: 25.9 % / 26.2 % |
| Umbral | PM2.5 > 25 µg/m³ | Límite de 24 h de la NOM-025, usado como **referencia fija**, no para evaluar cumplimiento |
| Faltantes | 12.3 % de todo; **26 % del PM2.5** | Sobre todo apagones largos de días |
| Limpieza | 0.7 % invalidado | Reglas físicas y de consistencia con la red |
| **Resultado principal (LDA)** | AUC **0.713 → 0.792**, ΔAUC **0.079 [0.054, 0.104]** | El intervalo no incluye el cero |
| Logística | 0.721 → 0.792, ΔAUC 0.071 [0.047, 0.095] | Misma conclusión |
| Detección | M0 **56 %** → M1 **74 %** | Especificidad casi igual: 0.70 → 0.68 |
| Por temporada (frente a M0) | mar–may **0.151**; nov–feb 0.069; lluvias 0.039 (incluye 0) | En primavera la estación separa poco (AUC de M0 0.58) |
| Variantes | Todas entre **0.071 y 0.082** | MICE, bloques de 7 y 28 días, sin NO2, etc. |
| Splines (no lineal) | 0.090 | La forma lineal, si acaso, subestima |
| Odds ratios (por 1 DE) | viento **0.49**, presión **0.58**, temperatura **1.78** | Asociación condicional, no causa |
| **Persistencia** | PM2.5 de ayer **0.872**; con meteorología 0.887 (+**0.016**) | El clima agrega poco sobre ayer, sobre todo de nov a feb |
| Umbral de vigilancia | **0.182** → detecta 84 %, 1.46 falsas alarmas por detección | Elegido con 2022–2023, sin ver la prueba |
| Umbral de equilibrio | 0.262 (Youden) → detecta 74 % | Casi igual al actual (0.259) |
| Episodios | 733 rachas; M1 marca al menos un día del **72 %** | Del 90 % de las rachas con > 40 µg/m³ |
| PCA | 3 ejes, **66.5 %** de la varianza | De la **meteorología**, no de las superaciones |
| Supuestos | ACF de residuos 0.42; VIF máximo 2.28; calibración 0.82 | Normalidad y covarianzas iguales **no** se cumplen |

---

## 3. Frases del guion y de la presentación que hay que decir distinto

La auditoría y las anotaciones de la profesora del 22 de octubre cambiaron estas frases. **Digan la versión de la derecha** aunque la diapositiva diga otra cosa.

| Diapositiva | Lo que dice el guion | Lo que hay que decir |
|---|---|---|
| 5 (Leo) | «la mediana de la red… **superó a MICE**, 0.450 frente a 0.593» | «Comparamos con MICE: **quedan casi empatadas** en error (0.450 frente a 0.436 si se promedian las imputaciones de MICE). Elegimos la mediana por ser simple y determinista, y con MICE la mejora da lo mismo: 0.078.» |
| 5 (Leo) | MIMA-v1 «no tuvimos acceso… **y además imputa la respuesta**» | «No lo usamos porque **no obtuvimos acceso a su dataset a tiempo**. Lo natural habría sido usar su meteorología imputada con nuestro PM2.5 observado.» La profesora es coautora de MIMA: no lo presenten como un método que rechazamos. |
| 7 (Pablo) | Ejes: «calor y radiación; humedad con flujo del este; presión baja con lluvia» | Nombres del informe: **día cálido, soleado y ventilado (36 %); día húmedo y lluvioso (17 %); día de presión baja y poco viento (13 %).** Agreguen: «el 66.5 % es la variación de las 8 variables meteorológicas; **no** quiere decir que el clima explique el 66.5 % de las superaciones». |
| 6 u 8 | «bootstrap por bloques de 14 días» | Agreguen: «**14 días es el tamaño del bloque** para medir la incertidumbre, **no** un horizonte de pronóstico: el modelo clasifica cada día con la meteorología de ese mismo día». |
| 9 (Daniel) | «de marzo a mayo… la temporada por sí sola dice poco» | «De marzo a mayo **la estación separa poco los días** (AUC de M0 de 0.58), así que el clima tiene más espacio para aportar». |
| 9 (Daniel) | «La mejora es mayor de marzo a mayo» | Agreguen: «**frente a M0**. Frente al PM2.5 de ayer, el clima aporta más de noviembre a febrero (0.036) y nada en lluvias». |
| 9 (Daniel) | «radiación y lluvia también tienen signo estable» | «La radiación es débil y **puede ir al revés**: las partículas bloquean la luz, así que el PM2.5 alto puede bajar la radiación.» |
| 12 (Ignacio) | «revisar… el PM2.5 de García» | Agreguen: «la mitad de los días de prueba de García caen en el periodo con el equipo dañado y **ninguno** supera: su porcentaje bajo es en parte la falla». |
| Demo del dashboard | (no estaba en el guion) | Avisen que **el dashboard usa el modelo de la etapa 3** (ver §5.4). |

---

## 4. Conceptos explicados simple

**Día-estación.** El promedio de PM2.5 de 24 h de una estación en un día. Solo cuenta si tiene **al menos 18 horas observadas**, el mismo criterio de la NOM-025.

**Superación (`supera_25`).** Vale 1 si ese promedio pasa de 25 µg/m³. Es una **referencia fija** para comparar 2021–2025, porque los límites de la norma cambiaron en esos años. No evaluamos cumplimiento normativo.

**Temporadas.** Son tres periodos fijados en la etapa 1, antes de modelar. La superación de cada una es la de la base final.

| Temporada | Meses | Superación |
|---|---|---|
| Seca-fría | noviembre a febrero | 38 % |
| Seca-cálida | marzo a mayo | 36 % |
| Cálida-húmeda o lluvias | junio a octubre | 13 % |

**M0 y M1.** M0 usa solo la estación (12 indicadoras, con CE como referencia) y la temporada (2 indicadoras, con lluvias como referencia). Da la misma probabilidad a todos los días de una combinación estación × temporada: es «lo que ya se sabe sin ver el clima del día». M1 agrega las 8 meteorológicas: temperatura, humedad, radiación, presión como anomalía de su sitio, viento u, viento v, rapidez del viento y horas con lluvia.

**AUC.** Es la probabilidad de que, si tomas al azar un día con superación y uno sin superación, el modelo le dé más puntaje al que sí superó. **0.5 es azar y 1 es perfecto. No es el porcentaje de aciertos.**

**ΔAUC.** La diferencia M1 − M0: cuánto agrega la meteorología. Usamos el mismo método y los mismos días para los dos modelos, así que la diferencia se atribuye al clima.

**LDA (análisis discriminante lineal).** Busca la combinación lineal de variables que mejor separa los días con y sin superación. Supone normalidad y covarianzas iguales, y **no se cumplen**. Por eso lo usamos como **clasificador** y lo respaldamos con evidencia empírica: validación temporal y comparación con la logística. No lo interpretamos como un modelo generativo.

**Regresión logística.** Responde lo mismo **sin suponer normalidad**. Da odds ratios fáciles de leer: con un OR de 0.49 para el viento, 1 DE más de viento (0.85 m/s) multiplica los momios de superación por 0.49. Es nuestra referencia para interpretar las variables.

**PCA.** Resume las 8 variables meteorológicas en 3 ejes que explican el 66.5 % de **su** varianza. Es descriptivo, porque el KMO de 0.64 es mediocre. **No lo usamos para predecir:** el primer eje junta temperatura y viento, que empujan en sentidos opuestos. Usar los componentes como predictores dio menos mejora (0.064).

**Bootstrap por bloques de 14 días.** Remuestrea bloques de 14 días seguidos con todas las estaciones, porque un episodio de contaminación dura días y afecta a varias estaciones a la vez. Da el **intervalo de confianza** de la mejora. **No** vuelve independientes los datos ni modela la autocorrelación. Con bloques de 28 días, la versión conservadora, el intervalo es [0.045, 0.110] y tampoco incluye el cero.

**Validación temporal.** Entrenamos con 2021–2023 y evaluamos en 2024–2025. Con validación progresiva, la mejora fue de 0.074 al validar 2022 y de 0.083 al validar 2023. **Ojo:** 2024–2025 ya se habían usado en etapas previas, y lo declaramos.

**Imputación.** La respuesta (PM2.5) **no se imputa**, porque sería inventar etiquetas. La meteorología horaria se imputa con imputeTS (descomposición estacional, Kalman, Stineman o lineal, según la variable), con el método elegido por **enmascaramiento**: tapamos datos que sí conocemos, imputamos y medimos el error. Los días con 1 a 4 meteorológicas faltantes se completan con la **mediana de la red ajustada por la estación**. En la prueba, el 27 % de los días tiene alguna variable completada así. Sin esa imputación diaria, la mejora es 0.071.

**Persistencia (MP).** Un modelo que usa el PM2.5 del día anterior en la misma estación. Es la línea base natural de un pronóstico.

**Corte o umbral.** La probabilidad a partir de la cual el modelo dice «superación». El actual es 0.259, la prevalencia del entrenamiento. Con el de vigilancia (0.182) se detecta más (84 %) a cambio de más falsas alarmas.

**Calibración.** Las probabilidades **ordenan bien** los días, pero son demasiado extremas (pendiente 0.82; lo ideal es 1). Por eso se leen como puntajes, no como «probabilidad real».

**Episodio.** Una racha de días seguidos con superación en una estación. Hay 733 en la prueba, el 47 % de un solo día. M1 marca al menos un día del 72 % de los episodios.

---

## 5. El dashboard (aplicación Shiny, carpeta `app/`)

**Qué es.** Una interfaz para **usar el modelo**: le das una estación, una temporada y la meteorología de un día, y te da la probabilidad de superación con M0 y con M1. También muestra cómo le fue al modelo en 2024–2025.
**Qué no es.** **No es un pronóstico.** Usa meteorología *observada* del mismo día. Es lo que la profesora pidió aclarar: «para usarlo como pronóstico haría falta evaluarlo con meteorología pronosticada».
**Cómo se abre.** En RStudio, desde la carpeta del repositorio: `shiny::runApp("app")`.

Tiene 3 pestañas arriba: **Calcular**, **Desempeño 2024–2025** y **Acerca de**.

### 5.1 Pestaña 1 — «Calcular»

**Barra lateral izquierda (las entradas):**

- **Estación:** las 13 estaciones.
- **«Definir la temporada por»:** puedes elegir la temporada directamente o poner una **fecha**, y la app calcula a qué temporada pertenece (por ejemplo, el 15 de marzo cae en seca-cálida).
- **8 deslizadores, uno por variable meteorológica** (temperatura, humedad, radiación, presión, rapidez del viento, viento u, viento v y horas de lluvia).
  - **Valor inicial:** la **mediana de esa estación en esa temporada** en el entrenamiento, un día «típico».
  - **Rango:** del percentil 1 al 99 del entrenamiento, para no pedirle al modelo valores que nunca vio.
- **Botón «Volver a las medianas»:** regresa los deslizadores al día típico.

**Arriba, aviso amarillo:** «Clasificación retrospectiva con meteorología observada. No es un pronóstico.»

**Tarjeta izquierda — «Probabilidad de superación (PM2.5 > 25 µg/m³)»:**

- **Dos barras:** la azul es M0 (solo estación y temporada) y la naranja es M1 (con meteorología). La altura es la probabilidad.
- **Línea punteada horizontal:** el **corte**. Si la barra pasa la línea, el modelo dice «superación».
- **Abajo, una frase:** «Clasificación con el corte…: M0 → superación / sin superación; M1 → …».
- **Cómo explicarla:** «La barra azul **no se mueve** con los deslizadores, porque M0 no ve el clima. La naranja sí: si bajo el viento o subo la temperatura, sube la probabilidad. La distancia entre las dos barras es lo que aporta la meteorología ese día.»

**Tarjeta derecha — «Contribución de cada variable al puntaje de M1»:**

- **Barras horizontales:** una por variable meteorológica, más una barra para la estación y otra para la temporada.
- **Qué mide cada barra:** el **coeficiente discriminante × el valor estandarizado** de esa variable.
  - **0** es la media del entrenamiento.
  - **Naranja, a la derecha:** empuja hacia superación.
  - **Azul, a la izquierda:** empuja hacia no superación.
- **Cómo explicarla:** «Muestra **por qué** M1 dio esa probabilidad ese día. Por ejemplo, con viento muy débil la barra del viento se va a la derecha, en naranja.»
- **Cuidado:** solo describe el modelo y no prueba causalidad. Además, la humedad, *u* y *v* no tienen signo estable, así que no se interpretan.

### 5.2 Pestaña 2 — «Desempeño 2024–2025»

Muestra **cómo le fue al modelo en la prueba** (los días reales de 2024–2025).

**Barra lateral:**

- **Estación** («Todas» o una).
- **Temporada** («Todas» o una).
- **Corte de clasificación:** el valor fijo con el que se cuentan aciertos y errores.

**Tarjeta izquierda — tabla de métricas** del subconjunto que elegiste, con su número de días y su % de superación en el título:

| Métrica | Qué es |
|---|---|
| AUC | Capacidad de ordenar (0.5 es azar y 1 es perfecto) |
| Exactitud balanceada | Promedio de sensibilidad y especificidad |
| Sensibilidad | Proporción de los días que sí superaron que el modelo detecta |
| Especificidad | Proporción de los días que no superaron que el modelo deja como «sin superación» |
| Brier | Error cuadrático de las probabilidades: más bajo es mejor |
| VP, FN, FP, VN | Matriz de confusión: verdaderos positivos, falsos negativos, falsos positivos y verdaderos negativos |

**Tarjeta derecha — dos gráficas de serie de tiempo** (aparecen al elegir **una estación**; con «Todas» la app pide que elijas una).

- **Gráfica de arriba: «PM2.5 observado».** Cada punto es un día: el eje *x* es la fecha y el eje *y*, el PM2.5 medido. La **línea punteada es 25 µg/m³**, de modo que arriba de ella hubo superación. El color dice si **M1** acertó:
  - **gris claro:** acierto sin superación;
  - **gris oscuro:** acierto con superación;
  - **naranja:** **falso positivo**, una falsa alarma (el modelo dijo superación y no hubo);
  - **rojo:** **falso negativo**, una superación que el modelo no detectó.
- **Gráfica de abajo: «Probabilidad M1».** Son los mismos días, con la probabilidad que dio M1. La **línea punteada es el corte**: arriba de ella el modelo dijo «superación». Usa los mismos colores.
- **Cómo leerlas juntas:** un punto **rojo** está **arriba** de los 25 µg/m³ en la gráfica de arriba, pero **abajo** del corte en la de abajo. Fue un día contaminado que el modelo no vio.
- **Qué mostrar:** los errores se concentran **cerca de 25 µg/m³**, en días que apenas pasaron o apenas no pasaron. Los días muy altos (> 40) casi siempre se detectan, el 90 %.

**Ejemplos útiles para la demo:**

- **SE2 (Juárez):** casi todo naranja o gris oscuro. Detecta casi todas las superaciones, pero con muchas falsas alarmas, porque ahí son frecuentes.
- **SUR (Pueblo Serena):** aparecen rojos. Ahí las superaciones son raras y un corte único para toda la red pierde varias. Esto **justifica los cortes por estación**.
- **Temporada «Cálida húmeda»:** la mejora de M1 sobre M0 casi no aparece.

### 5.3 Pestaña 3 — «Acerca de»

Es texto fijo: datos, modelo (LDA, M0/M1, corte), **limitaciones** (retrospectivo, asociación y no causa, probabilidades no calibradas, supuestos no cumplidos, deslizadores de viento independientes) y la liga al repositorio.

La limitación de los deslizadores importa: en la app puedes mover la rapidez del viento sin mover *u* y *v*, pero en datos reales la rapidez es al menos la magnitud del vector (*u*, *v*). Combinaciones raras dan probabilidades poco realistas.

### 5.4 Advertencia importante: el dashboard usa el modelo de la etapa 3

La app carga `output/etapa3/modelo_final.rds`, el modelo **de la etapa 3**, y no el del informe final:

| | Dashboard (etapa 3) | Informe final (etapa 4) |
|---|---|---|
| Días de prueba | 5 220 | 6 863 |
| AUC M0 → M1 | 0.722 → 0.792 | 0.713 → 0.792 |
| ΔAUC | 0.070 | 0.079 |
| Corte | 0.258 | 0.259 |
| Calibración (pendiente) | 0.76 | 0.82 |
| Base | casos completos, sin imputación diaria | imputación validada, sin días previos a las reubicaciones |

Si alguien ve «Todas / Todas» en la pestaña 2 y nota otros números, la respuesta es:

> «El dashboard tiene el modelo de la etapa 3. El final cambia la preparación de los datos, no el método, y el resultado casi no se mueve: M1 llega a 0.792 en los dos y la mejora pasa de 0.070 a 0.079.»

Lo mejor es **decirlo antes de que pregunten**. Si hay tiempo, se puede actualizar la app al modelo final.

### 5.5 Guion de demo (60–90 s, si la piden)

1. **Pestaña Calcular:** SE2, temporada seca-cálida. «Este es un día típico de primavera en Juárez: M0 da X y M1 da Y.»
2. **Bajar la rapidez del viento y subir la temperatura:** «La barra naranja sube; en la derecha se ve que lo que empuja es el viento débil y la temperatura. La azul no cambia, porque M0 no ve el clima.»
3. **Pestaña Desempeño:** SUR. «Los rojos son superaciones no detectadas: en estaciones donde son raras, un corte único falla; por eso recomendamos cortes por estación.»
4. **Cerrar:** «Es una evaluación retrospectiva con clima observado; el siguiente paso es probarlo con el pronóstico de SIMA.»

---

## 6. Preguntas difíciles (respuesta corta y quién contesta)

La regla es que **contesta el dueño del tema y otro complementa en una frase**. Así se nota que todos dominan el proyecto.

1. **«Si el PM2.5 de ayer da 0.872, ¿para qué sirve la meteorología?»** (Daniel) La meteorología agrega poco pero distinto de cero (0.016 [0.008, 0.025]), sobre todo de noviembre a febrero. Además, es lo que se puede **pronosticar** con varios días de anticipación; la persistencia solo sirve para mañana. Un aviso debería usar las dos.
2. **«El LDA no cumple supuestos, ¿por qué lo usan?»** (Pablo) Estaba fijado en el protocolo, y lo usamos como clasificador lineal, no como modelo generativo. La logística, que no supone normalidad, da la misma conclusión (0.071 y los mismos signos), y la QDA no mejora (0.788).
3. **«¿Qué hace y qué no hace el bootstrap?»** (Pablo) Da el intervalo de la mejora respetando que los días cercanos se parecen. No elimina la autocorrelación ni la mete en el modelo; por eso no damos valores p de los coeficientes.
4. **«¿14 días es el horizonte de pronóstico?»** (Pablo) No. Es el tamaño de los bloques del remuestreo. El modelo clasifica el mismo día.
5. **«¿El 67 % del PCA es lo que explica el clima?»** (Pablo) No. Es la parte de la variación de las 8 variables meteorológicas que resumen los 3 ejes. No dice nada de cuánto explican las superaciones.
6. **«¿Por qué no imputaron el PM2.5?»** (Leo) Sería inventar la variable que queremos clasificar. Además, interpolar aplana los picos, como también encontró MIMA-v1.
7. **«¿Por qué no usaron MIMA-v1?»** (Leo) No obtuvimos acceso a su dataset imputado a tiempo. Lo natural habría sido usar su meteorología imputada en sus 9 estaciones, con nuestro PM2.5 observado. Queda como pregunta nueva.
8. **«¿Qué imputaron, qué excluyeron y qué mostró la sensibilidad?»** (Leo)
   - Se imputó la meteorología horaria en huecos cortos y la diaria en los días con 1 a 4 variables faltantes.
   - Se excluyeron los días sin 18 h de PM2.5 (4 346), los que tenían 5 a 8 meteorológicas faltantes (189) y los previos a una reubicación (1 375, solo en el entrenamiento).
   - Sensibilidad: sin imputación diaria la mejora es 0.071, con MICE 0.078 y con las reubicaciones según SIMA 0.081.
9. **«¿Las exclusiones sesgan?»** (Leo) Donde hay respuesta, los excluidos tienen una superación parecida a la de los incluidos (29–33 % frente a 27 %). En los días sin PM2.5, su PM10 es menor en 31 de 39 combinaciones de estación y temporada. No lo descartamos del todo, sobre todo en NO, NE2 y 2024–2025.
10. **«Ya conocían 2024–2025, ¿no sobreajustaron?»** (Leo) Las decisiones se cerraron antes de cada evaluación, y lo declaramos. La mejora coincide con la validación progresiva (0.074 y 0.083) y todas las variantes caen entre 0.071 y 0.082.
11. **«¿Por qué presión baja? Lo esperado es alta presión.»** (Daniel) La asociación aparece también sin ajustar, dentro de cada temporada (correlación de −0.20 a −0.30), así que no es un artefacto. En nuestros datos la presión baja acompaña al aire cálido. La idea de situaciones previas a frentes es una **hipótesis** que requiere datos sinópticos.
12. **«¿Por qué casi no mejora en lluvias?»** (Daniel) Solo el 9.7 % de esos días supera. La lluvia ya limpia el aire y la temporada sola lo captura, y el intervalo incluye el cero. Ojo: M1 sí discrimina en lluvias (AUC 0.706), solo que no mejora a M0.
13. **«¿Es causal? ¿El viento causa el PM2.5?»** (Daniel) Es asociación en un estudio observacional. Es coherente con la literatura sobre ventilación y acumulación en la ZMM, pero no lo probamos.
14. **«¿Cómo eligieron el umbral?»** (Daniel) Con 2022–2023, sin ver la prueba: el corte más alto que detecta al menos el 80 % (0.182). SIMA decide según cuánto le cuesta una falsa alarma frente a una superación perdida.
15. **«¿Qué le sirve a SIMA hoy?»** (Ignacio)
    - Dos reglas de control de calidad listas para usar: radiación de madrugada y viento contra la red.
    - Una revisión de sensores: el PM2.5 de García de 2023 a 2025 y la radiación de García y Escobedo.
    - La persistencia como base y un umbral de vigilancia.
    - El código abierto para repetirlo con su pronóstico.
16. **«¿Por qué Juárez y Santa Catarina?»** (Ignacio) SIMA lo explica por la pluma de la refinería, las vialidades y las quemas (Juárez) y por la zona industrial y la salida del viento (Santa Catarina). En nuestros datos, Juárez tiene el viento más débil de la red. No lo atribuimos causalmente.
17. **«¿Qué pasó con García (NO2)?»** (Ignacio) Su PM2.5 baja a la mitad del de la red mientras su PM10 sigue normal. Apunta a una falla del equipo: en la prueba, 272 días de ese periodo no tienen ninguna superación. Sin NO2, la mejora es 0.082.
18. **«¿El dashboard pronostica?»** (Leo o Ignacio) No. Clasifica con el clima observado del mismo día. Para pronosticar habría que evaluarlo con meteorología pronosticada. Además usa el modelo de la etapa 3 (§5.4).

**Si no saben la respuesta:** «Buena pregunta; no lo evaluamos. Lo que sí podemos decir es [lo más cercano que sí hicieron], y lo dejamos como siguiente paso.» No inventen cifras.
