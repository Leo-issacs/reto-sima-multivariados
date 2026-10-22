# Guion de la presentación final · Reto SIMA · Equipo 1

Exposición de 15 minutos más 5 de preguntas. Doce diapositivas; este guion es el mismo texto que está en las notas del orador del `.pptx`. Todas las cifras se explican en `trazabilidad_presentacion.md`.

**Tiempo planeado:** 14:30 de exposición (30 s de holgura para las transiciones y las pausas). **Palabras del guion:** 1743 (≈ 804 s a 130 palabras por minuto; el ritmo real por diapositiva queda entre 112 y 141 palabras por minuto).

## Reparto

| Expositor | Diapositivas | Tiempo | Palabras del guion |
|---|---|---|---|
| Leonardo Orozco | 1, 5, 8 | 3:40 | 421 |
| Pablo Alonso Robles Nava | 6, 7, 11 | 3:10 | 366 |
| Ignacio Kume | 2, 3, 12 | 3:50 | 470 |
| Daniel Ayala | 4, 9, 10 | 3:50 | 486 |
| **Total** | 1–12 | **14:30** | **1743** |

Orden de la voz: Leo (1) → Ignacio (2–3) → Daniel (4) → Leo (5) → Pablo (6–7) → Leo (8) → Daniel (9–10) → Pablo (11) → Ignacio (12). Cada cambio de expositor está marcado con una transición al final del texto del que termina.

**Reglas de ritmo.** Si va justo de tiempo: en la 5, omitir la mención de MIMA-v1 y el detalle del filtro de Kalman; en la 9, omitir radiación y lluvia. No quitar nunca los supuestos (diapositiva 11) ni la respuesta explícita (diapositiva 12). Quien no habla en una diapositiva la cambia y no interrumpe.

## Diapositiva 1 · Portada

**Expositor:** Leonardo Orozco · **Duración:** 0:20 · **Reloj:** 0:00–0:20 · 47 palabras

Buenos días. Somos el Equipo 1 del grupo 201 y trabajamos con SIMA y la Agencia de Calidad del Aire de Nuevo León. Nuestra pregunta es: ¿cuánto mejora la meteorología del día la identificación de días con PM2.5 alto en Monterrey? Ignacio empieza explicando por qué importa.

## Diapositiva 2 · Problema y pregunta

**Expositor:** Ignacio Kume · **Duración:** 1:10 · **Reloj:** 0:20–1:30 · 148 palabras

Respirar PM2.5 durante pocos días ya se asocia con efectos en la salud; un metaanálisis de 196 artículos lo respalda. Para vigilarlo usamos una referencia fija: el límite diario de 25 microgramos por metro cúbico de la NOM-025. Llamamos superación a un día-estación por encima de ese valor. Nuestra pregunta compara dos modelos. M0 solo sabe la estación y la temporada. M1 sabe lo mismo y además la meteorología del día. Lo que medimos es cuánto sube el AUC al pasar de M0 a M1, es decir, cuánto mejora la identificación de días con superación. Esto le sirve a SIMA porque es el paso previo a una alerta con pronóstico: antes de pronosticar, hay que saber si la meteorología aporta algo sobre lo que ya se conoce. Lo evaluamos en 2024 y 2025, años que el modelo no vio al ajustarse. Ahora paso a la zona de estudio.

## Diapositiva 3 · Área de estudio

**Expositor:** Ignacio Kume · **Duración:** 1:20 · **Reloj:** 1:30–2:50 · 158 palabras

Trabajamos con 13 estaciones del SIMA en el valle de Monterrey. En el mapa, cada círculo muestra el porcentaje de días con superación y la etiqueta da la estación y su altitud en metros. Dos cosas se ven de inmediato. Primero, no hay una relación simple con la altitud: Santa Catarina, a 674 metros, y Juárez, a 387, tienen los porcentajes más altos, 44 y 46 por ciento, y están en extremos opuestos del valle. Segundo, el viento dominante viene del este: en 11 de las 13 estaciones el viento tiene componente del este entre el 80 y el 98 por ciento de los días. SIMA nos explicó el contexto de las dos estaciones altas. Juárez es el primer receptor de la pluma de la refinería, además del crecimiento urbano. Santa Catarina tiene zona industrial y es la salida del viento del área metropolitana. Son explicaciones de SIMA; nuestro diseño no permite atribuirlas. Daniel nos presenta los datos.

## Diapositiva 4 · Datos y exploración

**Expositor:** Daniel Ayala · **Duración:** 1:10 · **Reloj:** 2:50–4:00 · 140 palabras

Partimos de datos horarios de 2021 a 2025 que convertimos a un registro por estación y día: 17 828 días-estación en el análisis final, con PM2.5 y ocho variables meteorológicas: temperatura, humedad, radiación, presión, viento en dos componentes y su rapidez, y horas con lluvia. A la izquierda, el porcentaje de días con superación por temporada: alrededor de 37 por ciento de noviembre a febrero, 35 de marzo a mayo y solo 11.7 en lluvias. La estación y la temporada ya dicen mucho. A la derecha, un hallazgo que guía el resto: con todos los días juntos, la temperatura es 0.3 grados menor en los días con superación; pero dentro de cada temporada es mayor, entre 0.8 y 3.3 grados. La temperatura solo se asocia con la superación cuando controlamos la temporada. Leo explica qué hicimos con los datos faltantes.

## Diapositiva 5 · Datos faltantes

**Expositor:** Leonardo Orozco · **Duración:** 1:40 · **Reloj:** 4:00–5:40 · 187 palabras

Faltaba el 12.3 por ciento de los datos, y del PM2.5 el 26 por ciento, sobre todo por apagones largos de equipos. Además invalidamos el 0.7 por ciento por inconsistencias. Tomamos tres decisiones. Una: la respuesta, el PM2.5, no se imputa. Un día cuenta solo si tiene al menos 18 horas observadas; imputar la respuesta fabricaría justo lo que queremos clasificar. Dos: la meteorología horaria se imputa con métodos del paquete imputeTS, que vimos en el curso: descomposición estacional, que repite el ciclo del día, o filtro de Kalman, según el tamaño del hueco. Para elegir el método usamos enmascaramiento: tapamos datos que sí conocemos, imputamos y medimos el error. Tres: para la meteorología diaria usamos la mediana de la red ajustada por estación, que superó a MICE, con error relativo de 0.450 frente a 0.593. El resultado es que recuperamos días: García pasa de 511 a 1 532, y en total son 2 438 días más que en la etapa anterior. También quisimos comparar con MIMA-v1, el trabajo de semestres anteriores, pero no tuvimos acceso al código y además imputa la respuesta. Pablo explica cómo analizamos.

## Diapositiva 6 · Ruta de análisis

**Expositor:** Pablo Alonso Robles Nava · **Duración:** 1:10 · **Reloj:** 5:40–6:50 · 131 palabras

Nuestra ruta tiene cuatro pasos, y cada uno responde una pregunta. Primero, componentes principales, una técnica de interdependencia: nos dice cómo se estructura el clima. Segundo, análisis discriminante lineal y regresión logística, técnicas de dependencia: comparan M0 contra M1 para clasificar días con superación. La logística es nuestra comparación para el LDA. Tercero, validación temporal: entrenamos con 2021 a 2023 y probamos en 2024 y 2025, para saber cómo clasifica en años posteriores. Cuarto, bootstrap por bloques de 14 días, que da la incertidumbre de la mejora respetando que los días cercanos se parecen. Estación y temporada entran como variables indicadoras: 22 predictores en total, con Obispado y la temporada cálida-húmeda como referencia. Todo se ajusta solo con el entrenamiento; la prueba se usa únicamente para evaluar. Veamos el primer paso.

## Diapositiva 7 · Estructura del clima (PCA)

**Expositor:** Pablo Alonso Robles Nava · **Duración:** 0:50 · **Reloj:** 6:50–7:40 · 104 palabras

Los componentes principales resumen cómo varía el clima, medido como anomalía respecto de la media de cada estación. Tres ejes explican el 66.5 por ciento de la varianza: calor y radiación, 36 por ciento; humedad con flujo del este, 17; y presión baja con lluvia, 13. Los nombres son nuestra lectura de las cargas. La adecuación es modesta, KMO de 0.64, así que lo usamos de forma exploratoria. Y no lo usamos para predecir: el primer eje mezcla temperatura y viento, que se asocian con la superación en sentidos contrarios, y maximizar varianza no es maximizar separación entre clases. Leo presenta el resultado principal.

## Diapositiva 8 · Resultado principal

**Expositor:** Leonardo Orozco · **Duración:** 1:40 · **Reloj:** 7:40–9:20 · 187 palabras

Este es el resultado principal, en la prueba de 2024 y 2025. Con LDA, el AUC pasa de 0.713 con M0 a 0.792 con M1. Con regresión logística, de 0.721 a 0.792. La mejora, ΔAUC, es de 0.079 con intervalo de 95 por ciento de 0.054 a 0.104 para el LDA, y 0.071, de 0.047 a 0.095, para la logística. Ningún intervalo incluye el cero. En términos concretos, M1 detecta el 74 por ciento de los días-estación con superación, contra 56 por ciento de M0. La especificidad casi no cambia: 0.68 frente a 0.70. Una aclaración importante: el AUC no es un porcentaje de aciertos. Es la probabilidad de que, si tomamos al azar un día con superación y uno sin superación, el modelo le dé el puntaje más alto al que sí superó. Con 0.5 sería azar y con 1, perfecto. Las curvas muestran que la naranja, M1, queda por encima de la azul en casi todo el recorrido; los círculos marcan el corte de 0.259. Los intervalos salen de un bootstrap por bloques de 14 días con 1 000 réplicas. Daniel explica cuándo mejora más.

## Diapositiva 9 · ¿Cuándo y con qué ayuda?

**Expositor:** Daniel Ayala · **Duración:** 1:20 · **Reloj:** 9:20–10:40 · 176 palabras

La mejora no es pareja. Por temporada, de marzo a mayo el ΔAUC es de 0.151, con intervalo de 0.102 a 0.193: ahí la temporada por sí sola dice poco y el clima ayuda más. De noviembre a febrero es 0.069. En lluvias, 0.039, y su intervalo incluye el cero, así que no se distingue de cero; en esa temporada solo el 9.7 por ciento de los días supera. A la derecha, la regresión logística: odds ratios por cada desviación estándar, solo para variables cuyo signo se mantiene en el bootstrap. Con las demás variables constantes, viento más débil, presión más baja de lo normal para ese sitio y más temperatura se asocian con superación: un viento más fuerte tiene odds ratio de 0.49, una presión más alta, 0.58, y más temperatura, 1.78. Radiación y lluvia también tienen signo estable, pero pesan poco. Y una advertencia: es asociación, no causa, y no interpretamos humedad ni las componentes u y v, cuyo signo no es estable. Ahora vemos si el clima le gana al PM2.5 de ayer.

## Diapositiva 10 · Persistencia y umbral

**Expositor:** Daniel Ayala · **Duración:** 1:20 · **Reloj:** 10:40–12:00 · 170 palabras

La pregunta natural de SIMA es si el PM2.5 de ayer no basta. Comparamos con la persistencia en los días que tienen dato de ayer: M0 0.712, M1 0.792, el modelo con solo PM2.5 de ayer 0.872, y con ambos 0.887. Es decir: el PM2.5 de ayer predice más que el clima del día, con una diferencia de menos 0.080. Pero el clima sí agrega sobre ayer: 0.016, con intervalo de 0.008 a 0.025. Es pequeño, pero distinguible de cero. La comparación es retrospectiva: ayer sí se conoce antes, el clima observado de hoy no. A la derecha, el umbral. Elegimos el corte con los años de validación, antes de ver la prueba, con un objetivo explícito: detectar al menos el 80 por ciento. Salió 0.182. En la prueba detecta el 84 por ciento de las superaciones, con 1.46 falsas alarmas por cada detección, y marca el 54 por ciento de los días. Es un modo de vigilancia; el corte de equilibrio, 0.262, marca menos días. Pablo expone los límites.

## Diapositiva 11 · Supuestos y límites

**Expositor:** Pablo Alonso Robles Nava · **Duración:** 1:10 · **Reloj:** 12:00–13:10 · 131 palabras

Queremos ser honestos con los supuestos. El LDA supone normalidad multivariada y covarianzas iguales: la prueba de Mardia y la M de Box dicen que no se cumplen, y era de esperarse con indicadoras de estación y temporada. Por eso lo usamos como clasificador lineal y no como modelo generativo bien especificado, y la evidencia es empírica: validación temporal y comparación con la logística, que da la misma conclusión; la QDA tampoco mejora. Segundo, la dependencia: los residuos siguen autocorrelacionados, 0.42 a un día. El bootstrap por bloques estima la incertidumbre respetando esa dependencia, pero no la elimina, y por eso no interpretamos los errores estándar usuales. Tercero, la prueba ya se usó en etapas anteriores. Cuarto, las exclusiones pueden sesgar. Y quinto, el análisis es retrospectivo, no pronóstico. Ignacio cierra.

## Diapositiva 12 · Conclusión y recomendaciones

**Expositor:** Ignacio Kume · **Duración:** 1:20 · **Reloj:** 13:10–14:30 · 164 palabras

Respondemos la pregunta. Sí, la meteorología del día mejora la identificación, en esta medida: el AUC sube 0.079, de 0.713 a 0.792, y la detección de superaciones pasa de 56 a 74 por ciento, con intervalos que no incluyen el cero y resultados parecidos en todas las variantes, de 0.071 a 0.082. Queda débil lo siguiente: la mejora casi no aparece en lluvias, es retrospectiva porque usa clima observado, las probabilidades no están calibradas, y el PM2.5 de ayer predice más que el clima. Para SIMA recomendamos, en orden de prioridad: uno, evaluar el modelo con meteorología pronosticada, junto con su área de pronósticos; dos, incorporar las reglas de control de calidad, como radiación de madrugada y viento contra la red; y tres, revisar los sensores señalados: la radiación de García y Escobedo, y el PM2.5 de García de 2023 a 2025. Todo el código está en el repositorio, con la etiqueta informe-final; ahí está el código QR. Gracias; estamos listos para sus preguntas.
