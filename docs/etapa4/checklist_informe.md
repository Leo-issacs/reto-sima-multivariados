# Checklist del informe final

Páginas según el PDF de revisión (`docs/etapa4/Informe_final_SIMA_Equipo1.pdf`, convertido con Word desde el .docx; 26 páginas en total). Si Leo edita el .docx, las páginas pueden moverse.

**Extensión:** las secciones 1–7 van de la página 3 («1. Introducción y justificación») a la 17 (fin de «7. Discusión y conclusiones»): **15 páginas** (límite 15). Con las correcciones de la revisión de Codex el cuerpo pasó de 14 a 15 páginas; la sección 7 termina a 8.65 pulgadas de la p. 17, así que caben unas 1.3 pulgadas más antes de pasar a 16. Las Referencias empiezan en la misma p. 17. El Resumen ocupa una página (p. 2).

Estado: ✔ atendido · ◐ atendido en parte (ver nota) · ✘ no atendido.

## Rúbrica

| # | Criterio | Dónde | Pág. | Estado |
|---|---|---|---|---|
| 1 | Estructura mínima completa, ≤ 15 páginas, PDF sin recortes | Carátula, Resumen, secciones 1–7, Referencias, Liga al código, Anexos A–D | 1–26; 1–7 en pp. 3–17 | ✔ (revisadas las 26 páginas como imagen: nada cortado ni encimado) |
| 1 | Identificación con equipo y matrículas | Carátula: «Matrícula: ________» para cada integrante (Leo las llena en Word); «Profesores: Blanca Rosa Ruiz Hernández y Jesús [COMPLETAR apellidos]» | 1 | ◐ faltan matrículas y los apellidos del segundo profesor |
| 1 | Ortografía y redacción | Todo el documento; revisión automática de «¿», «µg/m³», «PM2.5», palabras repetidas y dobles espacios; los números con separador de miles llevan espacio de no separación | — | ✔ (sin corrector ortográfico instalado: revisión de Leo en Word recomendada) |
| 2 | Resumen de una página, claro y completo | Resumen: problema, datos y preparación, técnicas, resultados con cifras, qué sí y qué no, recomendaciones | 2 | ✔ |
| 3 | Claridad y coherencia; descripción de la estación y factores geográficos | Sección 3 (valle, altitud, flujo del este, salida por Santa Catarina y García; Figura 1, Tablas 1–2; contexto de SE2, SO y SUR) | 4–6 | ✔ |
| 4 | Limpieza, imputaciones, transformaciones y justificación | 4.1 (Tabla 3), 4.2 (Tabla 4), 4.3 (Figura 2, Tabla 5, D18–D20, MIMA-v1), 4.4, 4.5; Anexo B | 6–9; 22 | ✔ |
| 5 | Al menos dos técnicas (dependencia e interdependencia), aplicación y validación | 5.1 (Tabla 6, ruta), 5.2 PCA, 5.3 LDA, 5.4 supuestos (Tabla 7), 5.5 errores (Figura 3), 5.6 validación (Tabla 8; alcance de los IC y de los pliegues internos) | 9–13 | ✔ |
| 5 | Técnicas no exitosas y su justificación | 5.7 y Anexo A (Tabla 13) | 13; 22 | ✔ |
| 6 | Solidez, calidad y pertinencia de los hallazgos | 6.1–6.4 (Tablas 9–10, Figuras 4–7); 7 | 13–17 | ✔ |
| 7 | Interpretación de gráficos y tablas, numeración y descripción; sin código | 9 figuras y 18 tablas, todas numeradas, con pie y con llamada explícita en el texto (las Tablas 11–14 la tienen desde la revisión de Codex); ninguna figura con título interno (la Figura 4 solo conserva los rótulos de sus paneles a y b); Figuras 1, 2, 3, 5, 6, 8 y 9 en su versión para el informe (09h); ningún bloque de código visible | todas | ✔ |
| 8 | Resultados relevantes, recomendaciones y nuevas preguntas | 7: hallazgos, Tabla 11, limitaciones, 5 recomendaciones por prioridad, 7 preguntas nuevas | 16–17 | ✔ |
| 9 | Referencias APA y coherencia citas–lista | Referencias (40 entradas); `scripts/utilidades/verificar_citas.R`: 0 citas sin referencia, 0 referencias sin cita, orden alfabético correcto | 17–20 | ✔ (ver la sección de referencias abajo) |
| 10 | Liga al código; organización, comentarios, lenguajes y ejecución con el dataset | «Liga al código y organización»: hipervínculo a la etiqueta `informe-final` (rama main), Tabla 12, lenguajes, cómo correrlo; README del repositorio | 20–21 | ✔ (la etiqueta se crea al fusionar el PR #11; reproducción desde un clon limpio, abajo) |

## Retroalimentación (`docs/etapa4/retroalimentacion_final.md`)

### R1. Retroalimentación escrita de la etapa 2 (profesora)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| Explicar cómo entran estación y temporada al LDA y por qué es apropiado para M0 y M1 | 5.3: indicadoras k − 1, referencias CE y cálida-húmeda, M0 aditivo con 39 combinaciones, M1, razones 1–4, prior y corte | 10–11 | ✔ |
| Respaldo académico de PCA, logística y bootstrap por bloques, ligado a pregunta y variables | 5.1, Tabla 6 (columnas pregunta, variables, por qué, respaldo); 5.2 (KMO con Kaiser y Rice, 1974); 5.3, razón 4 (alcance de Efron, 1975) | 9–10 | ✔ |
| Normalidad multivariada no se cumple con indicadoras; datos dependientes en el tiempo y entre estaciones | 5.3 (razón 3) y 5.4 (Tabla 7) | 10–11 | ✔ |
| El bootstrap no vuelve independientes los datos del ajuste; el PCA no controla la autocorrelación; la prueba ya se usó | 5.4, párrafo antes de la Tabla 7; Resumen; 5.2 (frase en negritas); 5.6 (los IC se condicionan a la preparación elegida y los pliegues internos no repiten la imputación); limitación 2 | 2, 10–12, 17 | ✔ |
| Exponer los supuestos con honestidad; validación temporal y logística como evidencia empírica; no interpretar como modelo generativo | 5.4 (Tabla 7, con implicaciones que no afirman cuál es la frontera óptima); 6.4; Tabla 11 | 11, 16–17 | ✔ |

### R2. Exposición de la etapa 3 (15 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| LDA supone normalidad: cuidado con la interpretación | 5.3 (razón 3: modelo de localización de Krzanowski y la aproximación lineal), 5.4; 6.3 (solo signos estables; la temperatura, sin leerla como efecto por temporada) | 10–11, 15 | ✔ |
| ¿El modelo absorbe la autocorrelación y la heterogeneidad de varianzas? | 5.5 (Figura 3: ACF 0.50 → 0.44 → 0.42; varianza por temporada, esperable en parte con una respuesta binaria; calibración); Tabla 7 (diagnóstico adicional, Brown-Forsythe solo descriptivo); Anexo C | 11–12; 23–24 | ✔ |
| Va a pedir la validación; qué sí y qué no se puede concluir | 5.6 (Tabla 8; pliegues internos como diagnóstico de estabilidad); Tabla 11 | 12–13; 17 | ✔ (la validación de todo el procedimiento dentro de cada pliegue queda declarada como pendiente) |
| «Vecinos cercanos» es malo para estos datos | 4.3 (no se usa KNN); Anexo A (no se aplicó, siguiendo la retroalimentación; un KNN que ignore el tiempo y la red puede elegir donantes poco pertinentes; existen variantes que sí los usan) | 7; 22 | ✔ |
| Usar los métodos del curso (MIMA-v1) en lugar de hacer otro proyecto de imputación | 4.3: métodos de imputeTS (fuente principal del curso) y párrafo «Imputación de referencia del curso» sobre MIMA-v1 | 7–8 | ◐ no se pudo comparar con MIMA-v1: no obtuvimos acceso al dataset (Fase E no realizada); 5.7 ya no dice que lo confirma |
| Imputar puede mejorar, sobre todo en ventanas grandes | 4.1 (Tabla 3: los huecos son largos); 4.3, párrafo «Principio» (las ventanas grandes de la meteorología se recuperan a nivel diario con la red; las del PM2.5 no se rellenan); 4.3 D20 (4 192 días recuperados); pregunta nueva sobre MIMA-v1 | 6–8, 17 | ✔ (respondido de forma explícita; los huecos largos se cubren a nivel diario, no horario) |
| Métodos en la presentación; Spearman «solo es una correlación» | Spearman solo como descriptivo (sección 3) | 5 | ✔ (lo de la presentación no aplica al informe) |
| SIMA: reubicaciones confirmadas (NO3, SUR, SE, NE, NO; no SO ni NTE) | Tabla 2; sensibilidad con la lista de SIMA (Tabla 10) | 5–6; 16 | ✔ |
| SIMA: Juárez (pluma de la refinería, resuspensión, quemas, transporte, obras) | 3, contexto por estación: SE2, con cociente PM2.5/PM10 y viento | 5 | ✔ |
| SIMA: Santa Catarina (industria, suelo, receptor de la salida del viento) | 3, contexto por estación: SO | 5 | ✔ |
| SIMA: cuidado con la imputación en esas dos estaciones; hace falta un buen validador | 4.3 D18 (la respuesta no se imputa) y validación por enmascaramiento de cada imputación | 7 | ✔ |
| SIMA: el PM2.5 es caótico, sin la periodicidad del ozono | 7, Hallazgos (comunicación personal: por eso estación y temporada separan solo una parte de los días); ACF de la respuesta (5.5, 5.6) | 16; 11–12 | ✔ |
| SIMA: interés en la alerta con pronóstico | 1 (justificación), 7 (recomendación 1 y primera pregunta nueva) | 3; 17 | ✔ |

### R3. Información previa del socio (9 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| 2021: renovación de sensores de viento y analizadores | Tabla 2 y 4.2 (exclusión de 2020) | 6 | ✔ |
| 2025: equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO | Tabla 2; mejora por año (6.1, Figura 4b) | 6; 14 | ✔ |
| Citar como comunicación personal en el texto, no en la lista | Secciones 1, 3, 7 y Tabla 2 | 3–5, 16 | ✔ (no está en la lista; el verificador de citas no lo busca) |

## Referencias

Comprobadas por la revisión de Codex en Crossref y con el editor (los 31 DOI existen y sus metadatos coinciden), con las correcciones ya aplicadas: Kaiser y Rice (1974) sustituye a Kaiser (1974), que trata otro índice; autores de Martínez-Cinco et al. (2016) y Moons et al. (2006); nombre completo de la revista de Jolliffe y Cadima (2016); «Artículo» antes del número de artículo en las nueve entradas que lo tienen. Wilks (2019, 4.ª ed., Elsevier) y Johnson y Wichern (2007, 6.ª ed., Pearson Prentice Hall) quedaron confirmados. Se agregaron las URL oficiales del boletín estatal (2024) y de la NOM-025-SSA1-2021 en el DOF (con su título completo); el PIGECA va con HTTPS.

Gómez Santos et al. (2027): capítulo publicado en *Artificial intelligence – COMIA 2026* (CCIS 3097, pp. 728–739, Springer), verificado por Opus en Springer; sustituye a la ponencia de 2026. Gómez et al. (2025), reporte de MIMA-v1: cobertura (9 estaciones, enero de 2021 a junio de 2025), MAE 4.01 y licencia verificadas por Opus contra los originales que dio Leo.

**Sin fuente pública:** Sistema Integral de Monitoreo Ambiental (2026, 14 de agosto), presentación de diapositivas (viene de la etapa 1). En el texto, la primera cita define la sigla: (Sistema Integral de Monitoreo Ambiental [SIMA], 2026); en la lista va el nombre completo sin la sigla.

## Cambios de la revisión de Opus (borrador 37de55d)

1. Prueba: en 5.4 y en el Resumen se dice que 2024–2025 ya se había usado y que los cambios de la etapa 4 se decidieron después de conocer el resultado de la etapa 3.
2. 5.3, razón 3: Krzanowski (1975) como modelo de localización; la regla lineal supone el mismo efecto de la meteorología en todas las estaciones y temporadas.
3. 6.3: Rencher (1992) pasa a la frase sobre las correlaciones de estructura.
4. Tabla 2, fila del PM2.5 de NO2: redacción nueva del detalle.
5. Tabla 6: «Interdependencia» en una línea (anchos de columna).
6. 4.3 (D20): MICE promediado (0.436), por qué no se usa y MICE como sensibilidad (0.078, Tabla 10). Se quitó «y MICE (m = 20) queda como sensibilidad» de la frase siguiente, que lo repetía.
7. 4.3, «Principio»: ventanas grandes a nivel diario; PM2.5 sin rellenar.
8. 7, Hallazgos: comentario de SIMA sobre la periodicidad del PM2.5.
9. Figuras 1, 2 y 6 redibujadas con 09h (solo presentación). Para no dejar huecos de página: el párrafo de 5.4 va antes de la Tabla 7, las Figuras 4 y 7 se reducen a 6.0 y 4.8 pulgadas y la Tabla 11 usa anchos 61/39.
10. Anexo A, KNN: razón nueva.
11. Liga al código: rama main, etiqueta informe-final.

## Cambios de la revisión de Codex (`4644e16`)

Ninguno cambia una cifra del análisis.

- **I1.** 5.6: los pliegues internos diagnostican la estabilidad del ajuste sobre la base final; la imputación y su selección usaron todo 2021–2023. Limitación 2 lo repite.
- **I2.** Tabla 7: la fila «Homogeneidad de los errores» pasa a «Diagnóstico adicional: variación de los residuos y calibración» (no es un supuesto del LDA; Brown-Forsythe solo descriptivo); implicaciones de normalidad y covarianzas reescritas; 5.5 dice que la variación es esperable en parte con una respuesta binaria.
- **I3.** 4.3 (D20): el 0.436 es el promedio de las cinco imputaciones de MICE del experimento de selección; la sensibilidad del clasificador usa 20 bases (ΔAUC 0.078).
- **I4.** Liga al código: hipervínculo a la etiqueta `informe-final`, que se crea al fusionar el PR #11.
- **I5.** `zip` registrado en `renv.lock`.
- **I6.** 5.2: KMO con Kaiser y Rice (1974); la entrada sustituye a Kaiser (1974).
- **I7.** 1, «Alcance»: umbral fijo de 25 µg/m³; no se evalúa el cumplimiento normativo.
- **I8.** 6.1: en lluvias el intervalo de la mejora no permite establecer una ganancia sobre M0, pero el AUC de M1 es 0.706.
- **I9.** 6.3: correlación de estructura como correlación marginal con el puntaje; el coeficiente positivo de la temperatura no se lee por temporada. En el Resumen y en 7, «dentro de cada temporada» pasa a «al ajustar por estación y temporada».
- **I10.** 4.3 y Anexo A: MIMA-v1 con 9 estaciones de enero de 2021 a junio de 2025; «su licencia exige autorización escrita para modificaciones o distribución derivada»; cita y referencia a Gómez Santos et al. (2027).
- **I11.** 5.3, razones 2 y 4: optimalidad con normalidad y covarianza común; Efron (1975) como resultado asintótico bajo esas condiciones.
- **I12.** Anexo A, KNN: texto nuevo con Belachsen y Broday (2022).
- **I13.** 5.7: solo las alternativas evaluadas numéricamente conservaron la conclusión.
- **Incertidumbre.** 5.6: los IC remuestrean predicciones de modelos ya ajustados y se condicionan a la preparación elegida; MICE con 20 × 200 réplicas, sin evaluar su cobertura.
- **M1.** 4.4: medias de presión de 700.8 a 731.5 mm Hg.
- **M2.** 4.5: «de ellos, 15 011 cuentan además con las ocho variables».
- **M3.** `trazabilidad_cifras.md`: NTE con 855 días de RH imputada en la muestra final (864 antes de excluir la reubicación).
- **M4.** 6.4: la conclusión se conserva en las dos estrategias de imputación diaria comparadas.
- **M5.** Referencias: autores, revista completa, «Artículo», URL del boletín y de la NOM, título completo de la NOM, HTTPS del PIGECA, SIMA sin sigla en la lista y sigla en la primera cita; ediciones como «2.ª ed.», «4.ª ed.» y «6.ª ed.» por uniformidad con «Artículo».
- **M6.** 4.3: Moons et al. (2006) como reducción del sesgo de las asociaciones; la respuesta se excluye para conservar una evaluación predictiva.
- **M7.** Figuras 3, 5, 8 y 9 sin título interno (09h); llamadas explícitas a las Tablas 11–14; «sin la meteorología diaria» (5.3); «días con PM2.5 menor de 15 µg/m³» (6.1).
- **M8.** Este checklist ya no nombra a personal de SIMA; `decisiones_etapa4.md` describe MIMA-v1 sin calificarlo.
- **Además (Opus):** sección 3, «por debajo de la mitad de la red»; carátula con los profesores. **Maquetación:** las Figuras 3 y 5 se dibujan a 4.4 pulgadas con letra de 9 pt y la Figura 9 se muestra a 6.5 pulgadas, para que se lean; los números con separador de miles ya no se parten entre líneas.
- **Reproducibilidad.** Los CSV se escriben con `\n` también en Windows, y el candado de 09a compara el contenido sin `\r` (descomprimido en el `.csv.gz`). Resultado de la corrida desde un clon limpio: ver abajo.

## Reproducción desde un clon limpio

PENDIENTE
