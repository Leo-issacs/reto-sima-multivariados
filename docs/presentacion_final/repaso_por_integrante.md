# Repaso por integrante

Para cada integrante: sus diapositivas, los 3 conceptos que debe dominar y 5 preguntas que debe poder contestar **aunque no sean de su parte** (los números remiten a `banco_preguntas.md`, donde está la respuesta de referencia). La rúbrica evalúa presencia de todo el equipo y comprensión de todos: cualquiera puede ser interrogado sobre cualquier diapositiva.

Antes de cualquier repaso, todos deben poder decir de memoria la historia en una frase: *«Sabiendo solo la estación y la temporada ya se identifican muchos días con PM2.5 alto. La meteorología del día agrega información, sobre todo de marzo a mayo, pero es una clasificación retrospectiva: el siguiente paso es probarla con pronóstico»*, y estas seis cifras: **0.713 → 0.792**, **ΔAUC 0.079 [0.054, 0.104]**, **56 % → 74 %**, **17 828 días-estación**, **marzo–mayo +0.151** y **corte 0.182 con 84 % detectado**.

---

## Leonardo Orozco

**Diapositivas:** 1 (portada), 5 (datos faltantes), 8 (resultado principal). **Tiempo:** 3:40.

**Tres conceptos que debe dominar**
1. **Imputación sin tocar la respuesta.** El PM2.5 no se imputa (≥ 18 h observadas); la meteorología horaria se imputa con imputeTS (descomposición estacional, Kalman) elegida por enmascaramiento (tapar datos conocidos y medir el error); la diaria, con la mediana de la red ajustada, que superó a MICE (0.450 frente a 0.593). Se recuperan 2 438 días.
2. **AUC y ΔAUC.** El AUC es la probabilidad de ordenar bien un día con superación frente a uno sin; no es % de aciertos. ΔAUC = AUC(M1) − AUC(M0) = 0.079 [0.054, 0.104] en LDA y 0.071 [0.047, 0.095] en logística, con bootstrap por bloques de 14 días.
3. **Diseño M0 frente a M1 con prueba temporal.** Entrena 2021–2023, prueba 2024–2025; M0 = estación + temporada, M1 = M0 + 8 variables meteorológicas; sensibilidad 56 % → 74 %, especificidad 0.70 → 0.68.

**Cinco preguntas ajenas que debe poder contestar**
1. ¿Por qué usan LDA si no se cumplen los supuestos? (n.º 1; Pablo)
2. ¿Qué hace y qué no hace el bootstrap por bloques? (n.º 2; Pablo)
3. ¿Cómo se eligió el umbral de 0.182? (n.º 20; Daniel)
4. ¿Por qué la mejora casi no aparece en lluvias? (n.º 15; Daniel)
5. ¿Por qué es retrospectivo y no pronóstico, y qué le sirve a SIMA? (n.º 22 y 21; Ignacio)

---

## Pablo Alonso Robles Nava

**Diapositivas:** 6 (ruta de análisis), 7 (PCA), 11 (supuestos y límites). **Tiempo:** 3:10.

**Tres conceptos que debe dominar**
1. **Qué pregunta responde cada técnica.** PCA (interdependencia: estructura del clima, 3 ejes, 66.5 %, KMO 0.64, exploratorio); LDA y logística (dependencia: M0 frente a M1); validación temporal (años posteriores); bootstrap por bloques de 14 días (incertidumbre). Estación y temporada como indicadoras: 22 predictores.
2. **Supuestos diagnosticados y su consecuencia.** Mardia y M de Box rechazan normalidad y covarianzas iguales → clasificador, no modelo generativo, con evidencia empírica (validación, logística, QDA 0.788). Residuos autocorrelacionados (0.42 a un día) → bootstrap por bloques estima la incertidumbre, no la elimina. Prueba ya usada, exclusiones y carácter retrospectivo.
3. **Lo que el PCA sí y no hace.** Resume la correlación entre variables, no elimina la autocorrelación ni predice: maximiza varianza, no separación; PC1 mezcla temperatura y viento (efectos opuestos).

**Cinco preguntas ajenas que debe poder contestar**
1. ¿Por qué no se imputa el PM2.5? (n.º 8; Leo)
2. ¿Por qué no usaron MIMA-v1 ni KNN? (n.º 9; Leo)
3. ¿Qué significa un AUC de 0.79? (n.º 13; Leo)
4. ¿No basta con el PM2.5 de ayer? (n.º 19; Daniel)
5. ¿Qué hacen con las reubicaciones? (n.º 24; Ignacio)

---

## Ignacio Kume

**Diapositivas:** 2 (problema y pregunta), 3 (área de estudio), 12 (conclusión y recomendaciones). **Tiempo:** 3:50.

**Tres conceptos que debe dominar**
1. **Problema y justificación.** PM2.5 y salud por exposición de pocos días (metaanálisis de 196 artículos); límite diario de 25 µg/m³ de la NOM-025 como referencia fija; la pregunta M0 frente a M1; sirve a SIMA como paso previo a una alerta con pronóstico (su área de pronósticos).
2. **Contexto del valle.** Sin relación simple con la altitud (SO 674 m y SE2 387 m, las más altas en superación: 44 y 46 %); flujo del este en 11 de 13 estaciones; SE2 con el viento más débil de la red; explicaciones de SIMA (comunicación personal), que no atribuimos. Reubicaciones y el caso de NO2.
3. **La respuesta explícita y las recomendaciones.** «Sí, en esta medida: +0.079 de AUC, 56 % → 74 % de detección; queda débil: lluvias, retrospectivo, probabilidades sin calibrar, el PM2.5 de ayer predice más». Tres recomendaciones por prioridad: pronóstico; reglas de calidad (radiación de madrugada, viento contra la red); sensores (radiación de NO2 y NTE; PM2.5 de NO2 de 2023 a 2025).

**Cinco preguntas ajenas que debe poder contestar**
1. ¿Por qué usan LDA si no se cumplen los supuestos? (n.º 1; Pablo)
2. ¿Cómo eligieron el método de imputación y por qué la mediana de la red y no MICE? (n.º 10 y 11; Leo)
3. ¿Qué significa un AUC de 0.79 y qué tan grande es la mejora? (n.º 13 y 14; Leo)
4. ¿Cómo se eligió el umbral y cuántas falsas alarmas da? (n.º 20; Daniel)
5. ¿Por qué la temperatura parece no importar y luego sí? (n.º 17; Daniel)

---

## Daniel Ayala

**Diapositivas:** 4 (datos y exploración), 9 (¿cuándo y con qué ayuda?), 10 (persistencia y umbral). **Tiempo:** 3:50.

**Tres conceptos que debe dominar**
1. **Exploración y paradoja de la temperatura.** 17 828 días-estación, 13 estaciones, 8 variables meteorológicas; superación de 36.9 % (nov–feb), 35.0 % (mar–may) y 11.7 % (lluvias); con todos los días juntos la temperatura es 0.3 °C menor en los días con superación, dentro de cada temporada es mayor (+2.0, +3.3, +0.8 °C).
2. **Cuándo mejora y con qué se asocia.** ΔAUC por temporada: mar–may 0.151 [0.102, 0.193], nov–feb 0.069, lluvias 0.039 con IC que incluye el cero. Odds ratio por 1 DE (logística, signo estable): viento 0.49, presión 0.58, temperatura 1.78. «Se asocia», no «causa»; no se interpretan humedad ni u y v.
3. **Persistencia y umbral.** MP (PM2.5 de ayer) 0.872 frente a M1 0.792; el clima agrega +0.016 [0.008, 0.025] sobre ayer; ayer se conoce antes, el clima observado de hoy no. Corte de vigilancia 0.182 elegido en 2022–2023 con sensibilidad ≥ 0.80; en la prueba, 84 % detectado, 1.46 falsas alarmas por detección y 54 % de los días marcados.

**Cinco preguntas ajenas que debe poder contestar**
1. ¿Por qué no se imputa el PM2.5 y cómo se elige el método de imputación? (n.º 8 y 10; Leo)
2. ¿Cómo entran estación y temporada al LDA? (n.º 3; Pablo)
3. ¿Qué pasó con NO2 (García) y con las exclusiones? (n.º 25 y 12; Ignacio y Leo)
4. ¿Qué le sirve a SIMA de todo esto? (n.º 21; Ignacio)
5. ¿Las probabilidades están calibradas y la prueba ya se había usado? (n.º 6 y 7; Pablo)

---

## Simulacro sugerido (30 minutos)

1. Una pasada completa cronometrada con el guion (`guion.md`): objetivo, 14:30.
2. Ronda de preguntas cruzadas: cada integrante sortea 5 preguntas del banco que **no** sean suyas y contesta en menos de 40 segundos; los demás complementan solo si falta algo.
3. Repetir la diapositiva 11 (supuestos) y la 12 (respuesta explícita) entre todos hasta que cualquiera pueda decirlas sin leer.
