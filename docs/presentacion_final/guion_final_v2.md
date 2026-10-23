# Guion final de la exposición — Reto SIMA, Equipo 1 (versión 2)

Este guion sigue las 12 diapositivas del Canva «Presentación final SIMA · Equipo 1 (ejes PCA del informe)» y está actualizado con el informe final de la etapa 4. Ya incluye:

- las correcciones de la auditoría: MICE casi empatado, MIMA-v1 solo por falta de acceso, la persistencia por temporada y García (NO2);
- las anotaciones de la profesora del 22 de octubre: qué es el 66.5 % del PCA, qué son los 14 días, qué se imputó y qué se excluyó, y que el dashboard es retrospectivo.

**Formato:** 15 min de exposición + 5 de preguntas. El guion tiene 1 758 palabras: unos 13:30 a 130 palabras por minuto y cerca de **14:30** con pausas y cambios de expositor.

## Reparto (los 4 hablan entre 3:15 y 3:55)

| Expositor | Diapositivas | Tiempo aprox. |
|---|---|---|
| Leonardo Orozco | 1, 5, 8 | 3:30 |
| Ignacio Kume | 2, 3, 12 | 3:55 |
| Daniel Ayala | 4, 9, 10 | 3:50 |
| Pablo Alonso Robles Nava | 6, 7, 11 | 3:15 |

**Orden de voz:** Leo (1) → Ignacio (2–3) → Daniel (4) → Leo (5) → Pablo (6–7) → Leo (8) → Daniel (9–10) → Pablo (11) → Ignacio (12).

**Reglas.**

- Quien no habla cambia la diapositiva y no interrumpe.
- **En preguntas contesta el dueño del tema y otro complementa en una frase.** La vez pasada nos señalaron que dos cargaron la participación y uno no habló; esta vez se tiene que notar que los 4 dominan el proyecto.
- **Si van justos de tiempo:** en la 5, omitan MIMA-v1; en la 9, omitan radiación y lluvia; en la 10, omitan el corte de equilibrio. **Nunca quiten** la 11 (supuestos) ni la respuesta explícita de la 12.

---

## Diapositiva 1 · Portada
**Leo · 0:20**

> Buenos días. Somos el Equipo 1 del grupo 201 y trabajamos con SIMA y la Agencia de Calidad del Aire de Nuevo León. Nuestra pregunta es: ¿cuánto mejora la meteorología del día la identificación de días con PM2.5 alto en Monterrey? Ignacio empieza explicando por qué importa.

---

## Diapositiva 2 · La pregunta
**Ignacio · 1:10**

> Respirar PM2.5 durante pocos días ya se asocia con efectos en la salud; un metaanálisis de 196 artículos lo respalda. Usamos como referencia fija el límite diario de 25 microgramos por metro cúbico de la NOM-025: es una referencia para comparar todos los años, no una evaluación del cumplimiento de la norma. Llamamos superación a un día-estación, es decir, el promedio de 24 horas de una estación en un día, por encima de ese valor.
>
> Comparamos dos modelos. M0 solo sabe la estación y la temporada. M1 sabe lo mismo y además la meteorología del día. Medimos cuánto sube el AUC al pasar de M0 a M1. A SIMA le sirve porque es el paso previo a una alerta con pronóstico: antes de pronosticar, hay que saber si la meteorología aporta algo sobre lo que ya se conoce. Lo evaluamos en 2024 y 2025, años que el modelo no usó para ajustarse. Ahora, la zona de estudio.

---

## Diapositiva 3 · Área de estudio
**Ignacio · 1:20**

> Trabajamos con 13 estaciones del SIMA en el valle de Monterrey. En el mapa, cada círculo muestra el porcentaje de días con superación, y la etiqueta, la estación y su altitud. Se ven dos cosas. Primero, la superación no sigue la altitud: Santa Catarina, a 674 metros, y Juárez, a 387, tienen los porcentajes más altos, 44 y 46 por ciento, y están en extremos opuestos del valle. Segundo, domina el flujo del este: en 11 de las 13 estaciones el viento viene del este entre el 80 y el 98 por ciento de los días.
>
> SIMA nos explicó el contexto de esas dos estaciones. Juárez es el primer receptor de la pluma de la refinería, y además tiene crecimiento urbano, vialidades sucias y quemas. Santa Catarina tiene zona industrial y es por donde sale el viento del área metropolitana. En nuestros datos, Juárez tiene el viento más débil de la red. Son explicaciones de contexto: nuestro diseño no permite atribuir causas. Daniel presenta los datos.

---

## Diapositiva 4 · Datos y exploración
**Daniel · 1:10**

> Partimos de datos horarios de 2021 a 2025 y los convertimos a un registro por estación y día: 17 828 días-estación con PM2.5 y ocho variables meteorológicas: temperatura, humedad, radiación, presión, el viento en dos componentes y su rapidez, y horas con lluvia.
>
> Las temporadas son tres periodos que fijamos desde la etapa 1: seca-fría, de noviembre a febrero; seca-cálida, de marzo a mayo; y lluvias, de junio a octubre. A la izquierda se ve que la superación ronda el 37 por ciento de noviembre a febrero, el 35 de marzo a mayo y solo el 11.7 en lluvias: la temporada ya dice mucho. A la derecha, un hallazgo que guía todo lo demás: con todos los días juntos, la temperatura es 0.3 grados menor en los días con superación; pero dentro de cada temporada es mayor, entre 0.8 y 3.3 grados. La temperatura solo se asocia con la superación cuando se controla la temporada. Leo explica qué hicimos con los datos faltantes.

---

## Diapositiva 5 · Datos faltantes
**Leo · 1:40**

> Faltaba el 12.3 por ciento de los datos, y del PM2.5 el 26 por ciento, sobre todo por apagones largos de los equipos. Además invalidamos el 0.7 por ciento por inconsistencias. Tomamos tres decisiones.
>
> Uno: la respuesta, el PM2.5, no se imputa. Un día cuenta solo con al menos 18 horas observadas; imputarla fabricaría justo lo que queremos clasificar. Esos días sin PM2.5 suficiente se excluyen.
>
> Dos: la meteorología horaria se imputa con métodos de imputeTS, que vimos en el curso, como descomposición estacional o filtro de Kalman, según la variable y el tamaño del hueco. Elegimos el método por enmascaramiento: tapamos datos que sí conocemos, imputamos y medimos el error.
>
> Tres: los días con una a cuatro variables meteorológicas faltantes se completan con la mediana de la red ajustada por estación. La comparamos con MICE y quedaron casi empatadas en error; elegimos la mediana por simple, y con MICE la mejora final da prácticamente lo mismo: 0.078.
>
> Así recuperamos 2 438 días; García pasa de 511 a 1 532. Y como sensibilidad, sin esta imputación diaria la mejora sigue en 0.071. No pudimos comparar con MIMA-v1 porque no obtuvimos acceso a su dataset a tiempo. Pablo explica cómo analizamos.

---

## Diapositiva 6 · Ruta de análisis
**Pablo · 1:10**

> Nuestra ruta tiene cuatro pasos, y cada uno responde una pregunta. Primero, componentes principales, una técnica de interdependencia: describe cómo se estructura el clima. Segundo, análisis discriminante lineal y regresión logística, técnicas de dependencia: comparan M0 contra M1. La logística no supone normalidad y es nuestra referencia para interpretar las variables. Tercero, validación temporal: entrenamos con 2021 a 2023 y probamos en 2024 y 2025. Cuarto, bootstrap por bloques de 14 días, que da el intervalo de confianza de la mejora. Ojo: los 14 días son el tamaño de cada bloque del remuestreo, no un horizonte de pronóstico; el modelo clasifica cada día con el clima de ese mismo día. Estación y temporada entran como variables indicadoras: 22 predictores en total, con Obispado y lluvias como referencia. Todo se ajusta con el entrenamiento; la prueba solo evalúa. Veamos el primer paso.

---

## Diapositiva 7 · Estructura del clima (PCA)
**Pablo · 0:55**

> Los componentes principales resumen cómo varía el clima, medido como anomalía respecto de la media de cada estación. Tres ejes resumen el 66.5 por ciento de la varianza: un día cálido, soleado y ventilado, 36 por ciento; un día húmedo y lluvioso, 17; y un día de presión baja y poco viento, 13. Importante: ese 66.5 por ciento es la variación de las ocho variables meteorológicas; no significa que el clima explique el 66.5 por ciento de las superaciones. La adecuación es modesta, un KMO de 0.64, así que es exploratorio. Y no lo usamos para predecir: el primer eje mezcla temperatura y viento, que se asocian con la superación en sentidos contrarios. Leo presenta el resultado principal.

---

## Diapositiva 8 · Resultado principal
**Leo · 1:45**

> Este es el resultado principal, en la prueba de 2024 y 2025. Con LDA, el AUC pasa de 0.713 con M0 a 0.792 con M1; con regresión logística, de 0.721 a 0.792. La mejora es de 0.079, con intervalo de 95 por ciento de 0.054 a 0.104, en el LDA, y de 0.071 en la logística. Ningún intervalo incluye el cero, y en todas las variantes que probamos la mejora queda entre 0.071 y 0.082.
>
> En concreto, M1 detecta el 74 por ciento de los días-estación con superación, contra el 56 de M0, con una especificidad casi igual: 0.68 frente a 0.70. Y una aclaración: el AUC no es un porcentaje de aciertos. Es la probabilidad de que, si tomamos al azar un día con superación y uno sin superación, el modelo le dé más puntaje al que sí superó: 0.5 es azar y 1 es perfecto. La curva naranja, M1, queda por encima de la azul en casi todo el recorrido. Daniel explica cuándo mejora más.

---

## Diapositiva 9 · ¿Cuándo y con qué ayuda?
**Daniel · 1:20**

> La mejora no es pareja. Frente a M0, de marzo a mayo el aumento es de 0.151, con intervalo de 0.102 a 0.193: en esa temporada la estación separa poco los días, con un AUC de M0 de solo 0.58, así que el clima tiene más espacio para aportar. De noviembre a febrero es de 0.069. En lluvias es de 0.039 y su intervalo incluye el cero: no se distingue de cero, y en esa temporada solo el 9.7 por ciento de los días supera.
>
> A la derecha están los odds ratios de la logística, solo de las variables con signo estable. Con lo demás constante, más viento tiene un odds ratio de 0.49, más presión respecto de lo normal del sitio 0.58, y más temperatura 1.78: el viento débil, la presión baja y el calor acompañan a la superación. Es asociación, no causa. Ahora vemos si el clima le gana al PM2.5 de ayer.

*(Si sobra tiempo, antes de la última frase: «La radiación es débil y puede ir al revés, porque las partículas bloquean la luz».)*

---

## Diapositiva 10 · Persistencia y umbral
**Daniel · 1:20**

> La pregunta natural de SIMA es si no basta el PM2.5 de ayer. Lo comparamos en los días que tienen dato del día anterior. El modelo con el PM2.5 de ayer llega a 0.872, más que el clima del día, que da 0.792. Pero el clima sí agrega sobre ayer: 0.016, con intervalo de 0.008 a 0.025; es pequeño, pero distinto de cero, y aporta sobre todo de noviembre a febrero. Por eso un aviso debería partir de la persistencia y sumarle el clima.
>
> A la derecha, el umbral. Lo elegimos con los años de validación, antes de ver la prueba, con un objetivo explícito: detectar al menos el 80 por ciento. Salió 0.182. En la prueba detecta el 84 por ciento de las superaciones, con 1.46 falsas alarmas por cada detección. Es un modo de vigilancia; si SIMA prefiere menos alarmas, el corte de equilibrio es 0.26. Pablo expone los límites.

---

## Diapositiva 11 · Supuestos y límites
**Pablo · 1:15**

> Queremos ser honestos con los supuestos. Uno: el LDA supone normalidad multivariada y covarianzas iguales, y las pruebas de Mardia y M de Box dicen que no se cumplen. Por eso lo usamos como clasificador, no como modelo generativo, y la evidencia es empírica: la validación temporal y la logística, que da la misma conclusión. Dos: los residuos siguen autocorrelacionados, 0.42 a un día; el bootstrap por bloques estima la incertidumbre respetando esa dependencia, pero no la elimina, y por eso no interpretamos errores estándar ni valores p. Tres: la prueba 2024–2025 ya se había usado en etapas anteriores y lo declaramos. Cuatro: las exclusiones pueden sesgar; donde hay respuesta, los excluidos se parecen a los incluidos, y las sensibilidades dan de 0.071 a 0.082. Y cinco: es retrospectivo, usa el clima observado. Ignacio cierra.

---

## Diapositiva 12 · Conclusión y recomendaciones
**Ignacio · 1:20**

> Respondemos la pregunta. Sí, la meteorología del día mejora la identificación, en esta medida: el AUC sube 0.079, de 0.713 a 0.792, y la detección pasa de 56 a 74 por ciento. Queda débil en cuatro puntos: casi no mejora en lluvias, es retrospectivo, las probabilidades no están calibradas y el PM2.5 de ayer predice más que el clima. Por lo mismo, la aplicación del repositorio muestra una evaluación retrospectiva, no un pronóstico.
>
> Para SIMA recomendamos, por prioridad: uno, evaluar el modelo con meteorología pronosticada y con la persistencia como base, junto con su área de pronósticos; dos, incorporar dos reglas de control de calidad listas para usar: radiación de madrugada y viento contra la red; y tres, revisar sensores: la radiación de García y Escobedo, y el PM2.5 de García, cuyo equipo bajó a la mitad entre 2023 y 2025. El código está en el repositorio, en la etiqueta entrega-final. Gracias; estamos listos para sus preguntas.

---

## Cambios que conviene hacer en las diapositivas de Canva

El guion ya lo dice bien, pero **el texto de las diapositivas todavía tiene la versión vieja**:

1. **Diapositiva 5, tarjeta 3:** dice «Superó a MICE: error relativo 0.450 frente a 0.593». Cambiar a **«Casi empatada con MICE (0.450 frente a 0.436); con MICE la mejora da 0.078»**.
2. **Diapositiva 5, última línea:** dice «MIMA-v1 no se comparó: no tuvimos acceso a su dataset e imputa la respuesta». Cambiar a **«MIMA-v1 no se comparó: no obtuvimos acceso a su dataset a tiempo»**.
3. **Diapositiva 9, título:** dice «La mejora se concentra de marzo a mayo…». Agregar **«frente a M0»** o dejarlo así y que Daniel lo diga (ya está en el guion).
4. **Diapositiva 6 (opcional):** en la tarjeta del bootstrap agregar **«(tamaño del bloque, no horizonte de pronóstico)»**.
5. **Diapositiva 7 (opcional):** junto a «66.5 %» agregar **«de la variación del clima, no de las superaciones»**.

## Si muestran el dashboard en preguntas

- La app ya usa el modelo final (main, commit `d0ae46f`). Antes de exponer, ábranla y comprueben que en «Desempeño 2024–2025» con «Todas / Todas» salga AUC 0.713 → 0.792 y 6 863 días.
- Digan siempre que es una **evaluación retrospectiva con clima observado**, no un pronóstico.
- El guion de la demo está en `estudio_exposicion_final.md`, §5.5.
