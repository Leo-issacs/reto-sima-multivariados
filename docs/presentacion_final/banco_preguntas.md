# Banco de preguntas probables (5 minutos de preguntas)

25 preguntas de profesores, de SIMA y de compañeros, con una respuesta de 2 a 3 líneas y quién la contesta. Las cifras salen de `trazabilidad_presentacion.md`. Regla del equipo: contesta quien tiene la pregunta asignada, pero **cualquiera puede completar**, y nadie dice «eso lo hizo otro»; la rúbrica evalúa que todos comprendan todo. Si no sabemos algo, lo decimos y decimos dónde está (informe, sección o archivo).

Respondedores: **L** = Leonardo, **P** = Pablo, **I** = Ignacio, **D** = Daniel.

## A. Método y supuestos

**1. ¿Por qué usan LDA si no se cumplen la normalidad ni las covarianzas iguales?** (P)
Lo usamos como clasificador lineal, no como modelo generativo bien especificado, y lo dijimos desde el principio: Mardia y la M de Box rechazan los supuestos, como era de esperar con indicadoras de estación y temporada. La evidencia es empírica: validación temporal en 2024–2025, la logística da la misma conclusión (0.071 frente a 0.079) y la QDA, que no supone covarianzas iguales, no mejora (0.788 frente a 0.792).

**2. ¿Qué hace y qué no hace el bootstrap por bloques?** (P)
Hace: estima la incertidumbre de la mejora respetando que días cercanos y estaciones el mismo día se parecen (bloques de 14 días con todas las estaciones). No hace: no vuelve independientes los datos ni corrige el ajuste del LDA. Con bloques de 7 y de 28 días el intervalo casi no cambia (0.054 a 0.103 y 0.045 a 0.110), y los errores estándar usuales no se interpretan.

**3. ¿Cómo entran estación y temporada, que son categóricas, al LDA?** (P)
Como variables indicadoras: 12 de estación (referencia CE) y 2 de temporada (referencia cálida-húmeda), más 8 meteorológicas, 22 predictores. Las indicadoras no son normales, por eso la pregunta 1: es otra razón para leer el LDA como clasificador y contrastarlo con la logística.

**4. ¿Para qué usan PCA si luego no predicen con él?** (P)
Responde otra pregunta: cómo se estructura el clima (tres ejes, 66.5 % de la varianza, KMO 0.64, uso exploratorio). No lo usamos para predecir porque maximizar varianza no es maximizar separación entre clases y PC1 mezcla temperatura y viento, que se asocian con la superación en sentidos opuestos; en la etapa 3 usar los componentes dio una mejora menor (0.064 frente a 0.070).

**5. ¿Por qué además de LDA hacen regresión logística?** (P)
Por tres razones: es la comparación natural cuando los supuestos del LDA fallan, da odds ratio interpretables y sirve de robustez. Dan la misma conclusión: AUC de M1 0.792 en ambas y mejora de 0.071 [0.047, 0.095] contra 0.079 [0.054, 0.104]; las ocho meteorológicas tienen el mismo signo.

**6. ¿Las probabilidades del modelo están calibradas?** (P)
No: la pendiente de recalibración en la prueba es 0.82 (1 sería ideal) y el modelo es demasiado confiado en probabilidades altas. Por eso hablamos de puntaje y de clasificación, no de probabilidades al pie de la letra; la recalibración y los cortes por estación quedan como recomendación.

**7. ¿La prueba 2024–2025 no se había usado antes?** (P)
Sí, se usó en etapas anteriores (una prueba preliminar en la etapa 2), y lo decimos como limitación. Por eso las decisiones de la etapa 4 se cerraron con etiqueta antes de evaluar con la base nueva, los umbrales se eligieron solo con 2022–2023 y lo posterior a la evaluación se marca como tal. Aun así no es una prueba virgen.

## B. Datos faltantes

**8. ¿Por qué no se imputa el PM2.5?** (L)
Porque es la respuesta: imputarla fabricaría justo lo que queremos clasificar y podría inflar el resultado. Un día cuenta solo con al menos 18 horas observadas (NOM-025). El costo fue perder 526 días-estación frente a la muestra de la etapa 3, y una sensibilidad que interpola el PM2.5 hasta 3 horas da lo mismo (0.079).

**9. ¿Por qué no usaron MIMA-v1 ni KNN?** (L)
MIMA-v1 (trabajo de semestres anteriores) no se pudo comparar: no obtuvimos el acceso al dataset a tiempo y además imputa la respuesta, que nosotros no imputamos; lo dejamos como pregunta abierta. KNN lo descartamos porque la profesora señaló que los vecinos cercanos son malos para estas series y porque elegimos los métodos con evidencia propia (enmascaramiento), con la fuente del curso: imputeTS.

**10. ¿Cómo eligieron el método de imputación?** (L)
Por enmascaramiento: tapamos datos que sí conocemos en 2021–2023, imputamos y medimos el error por método y tamaño de hueco. Para la meteorología horaria ganaron métodos de imputeTS (descomposición estacional o Kalman según la variable y el hueco, con lineal en el viento); para la diaria ganó la mediana de la red ajustada, con error relativo de 0.450 frente a 0.593 de MICE.

**11. ¿Por qué la mediana de la red y no MICE?** (L)
Porque con el error de cada base imputada ganó (0.450 frente a 0.593) y es más simple de explicar y de auditar. MICE queda como sensibilidad con 20 bases y da lo mismo en el resultado (ΔAUC 0.078).

**12. ¿Las exclusiones sesgan el resultado?** (L)
Puede haber sesgo y lo decimos. Quedan fuera 18.3 % de días-estación sin PM2.5 suficiente (sobre todo apagones largos, con rachas de hasta 532 días) y 189 por clima faltante, que superan más (33.3 % frente a 27.0 %), pero son 0.8 %. Las sensibilidades (sin imputación diaria, límite de 2 faltantes, sin NO2) dan entre 0.071 y 0.082.

## C. Resultados

**13. ¿Qué significa un AUC de 0.79?** (L)
Es la probabilidad de que, tomando al azar un día con superación y uno sin, el modelo dé el puntaje más alto al que sí superó: 0.5 es azar y 1 es perfecto. No es un porcentaje de aciertos. Con M0 es 0.713 y con M1, 0.792; en términos concretos, M1 detecta 74 % de las superaciones (M0, 56 %) con especificidad de 0.68 (0.70).

**14. ¿Es una mejora grande o pequeña?** (L)
Moderada y distinguible de cero: 0.079 [0.054, 0.104], robusta en todas las variantes (0.071 a 0.082). La exactitud balanceada pasa de 0.634 a 0.711 y el Brier de 0.172 a 0.154. La mejora es mayor de marzo a mayo (0.151) y mucho menor en las otras temporadas.

**15. ¿Por qué la mejora casi no aparece en lluvias?** (D)
Porque ahí el intervalo incluye el cero (0.039 [−0.018, 0.104]): no podemos distinguirla de cero. Solo 9.7 % de los días supera el límite, así que hay pocos eventos que detectar, y M1 detecta menos que M0 (sensibilidad 0.298 frente a 0.364). No probamos por qué; una explicación plausible es que la estación y la temporada ya capturan casi todo en esa época.

**16. ¿La mejora es causal? ¿El viento «causa» el PM2.5?** (D)
No. Es una clasificación retrospectiva y las variables se **asocian**: con el resto constante, viento más débil, presión más baja de lo normal para el sitio y más temperatura acompañan la superación. No interpretamos humedad ni u y v (signo no estable), ni ordenamos variables por el tamaño del coeficiente.

**17. ¿Por qué la temperatura parece no importar y luego sí?** (D)
Es una paradoja de tipo Simpson: con todos los días juntos, los días con superación son 0.3 °C más fríos, porque la superación es frecuente en la época fría; dentro de cada temporada son más cálidos (+2.0, +3.3 y +0.8 °C). Por eso el coeficiente de la temperatura se lee solo condicional a la temporada.

**18. Días-estación frente a episodios: ¿detecta episodios o días sueltos?** (D)
Hay 1 799 días-estación con superación en la prueba, agrupados en 733 episodios (rachas de días seguidos); la mediana dura 2 días y 47 % es de un solo día. M1 detecta 72 % de los episodios (M0, 49 %) y acierta el primer día en 66 % (M0, 49 %). Con más de 40 µg/m³: 349 días-estación, 219 episodios, detecta 90 %.

## D. Persistencia y umbral

**19. ¿No basta con el PM2.5 de ayer? Persistencia frente a meteorología.** (D)
Para predecir, ayer gana: el AUC con PM2.5 de ayer es 0.872 frente a 0.792 del clima (diferencia de −0.080 [−0.103, −0.055]). Pero el clima agrega sobre ayer +0.016 [0.008, 0.025] (0.872 → 0.887). Ojo: es retrospectivo; ayer se conoce antes, el clima observado de hoy no. Con pronóstico del clima la comparación cambia y por eso es nuestra primera recomendación.

**20. ¿Cómo se eligió el umbral?** (D)
Con los pliegues de validación 2022 y 2023, sin ver la prueba, con un objetivo explícito: el corte más alto con sensibilidad de al menos 0.80 (vigilancia), 0.182 en el LDA. En la prueba detecta 84 %, con 1.46 falsas alarmas por detección y marca 54 % de los días. El corte de equilibrio (Youden), 0.262, detecta 74 % con 1.20 falsas alarmas y marca 43 %. SIMA debe elegir según el costo de una falsa alarma.

## E. Contexto y SIMA

**21. ¿Qué le sirve a SIMA de todo esto?** (I)
Tres cosas: la medida de cuánto agrega el clima sobre estación y temporada (paso previo a una alerta con pronóstico); un corte de vigilancia con su costo en falsas alarmas; y hallazgos de calidad de datos (radiación de NO2 y NTE, PM2.5 de NO2 de 2023 a 2025, reglas de control de calidad). La siguiente prueba es con meteorología pronosticada, junto con su área de pronósticos.

**22. ¿Por qué es retrospectivo y no pronóstico?** (I)
Porque M1 usa la meteorología observada del mismo día, que no se conoce de antemano. Sirve para saber si el clima aporta información; para alertar hace falta usar clima pronosticado, cuyo error reduciría la mejora. No lo probamos y lo declaramos como límite principal.

**23. ¿Por qué Juárez (SE2) y Santa Catarina (SO) tienen más superaciones?** (I)
Según SIMA: Juárez recibe la pluma de la refinería (la dispersión «brinca» Cadereyta), con crecimiento urbano, vialidades sucias y quema; Santa Catarina tiene zona industrial y es la salida del viento del área metropolitana. Nuestro diseño no permite atribuirlo; vemos que SE2 tiene el viento más débil de la red (1.55 m/s) y en ambas el PM2.5 va ligado al PM10.

**24. ¿Qué hacen con las reubicaciones de estaciones?** (I)
Se trata «sitio» y no solo «estación»: el entrenamiento excluye los días previos a la reubicación (fechas del PIGECA para NO, SE, SO, NTE, SUR y NE; 1 375 días). SIMA confirmó SUR, SE, NE y NO, sin fechas, y no mencionó SO ni NTE. Usar solo la lista de SIMA da 0.081 y la presión solo confirma bien la de SUR; las fechas son una pregunta abierta para SIMA.

**25. ¿Qué pasó con NO2 (García)? ¿Y qué harían con más tiempo?** (I)
Su PM2.5 baja a la mitad de la red con PM10 normal en enero–mayo de 2021 y de julio de 2023 a enero de 2025 (0 superaciones en 2024): parece falla del equipo, no del aire; quitar NO2 sube la mejora a 0.082. Con más tiempo: probar con pronóstico, un modelo temporal explícito (autocorrelación, efectos por estación), recalibrar y fijar cortes por estación.

---

### Si preguntan algo que no está aquí

1. Reconocer la pregunta y decir «no lo probamos» si es el caso; no inventar cifras.
2. Remitir al informe: supuestos y errores (Secciones 5 y 6), limitaciones (Sección 7) y los anexos A y C.
3. Redirigir a lo que sí se sabe: ΔAUC 0.079 [0.054, 0.104], por temporada, robustez 0.071 a 0.082.
