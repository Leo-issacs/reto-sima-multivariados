# Checklist del informe final

Páginas según el PDF de revisión (`docs/etapa4/Informe_final_SIMA_Equipo1.pdf`, convertido con Word desde el .docx; 31 páginas en total). Si Leo edita el .docx, las páginas pueden moverse.

**Extensión:** las secciones 1–7 van de la página 3 («1. Introducción y justificación») a la 17 (fin de «7. Discusión y conclusiones»): **15 páginas** (límite 15). La sección 7 termina con 0.77 pulgadas libres al pie de la p. 17, y las Referencias empiezan en la p. 18. El Resumen ocupa una página (p. 2, con 1.1 pulgadas libres). Para que la fase F cupiera se movieron a los anexos los seis elementos de la lista de prioridad y, además, la tabla de reglas de limpieza (ver «Fase F: elementos movidos a los anexos»).

Estado: ✔ atendido · ◐ atendido en parte (ver nota) · ✘ no atendido.

## Rúbrica

| # | Criterio | Dónde | Pág. | Estado |
|---|---|---|---|---|
| 1 | Estructura mínima completa, ≤ 15 páginas, PDF sin recortes | Carátula, Resumen, secciones 1–7, Referencias, Liga al código, Anexos A–D | 1–31; 1–7 en pp. 3–17 | ✔ (revisadas las 31 páginas como imagen: nada cortado ni encimado; las tablas largas que se parten repiten el encabezado) |
| 1 | Identificación con equipo y matrículas | Carátula: «Matrícula: ________» para cada integrante (Leo las llena en Word); «Profesores: Blanca Rosa Ruiz Hernández y Jesús [COMPLETAR apellidos]» | 1 | ◐ faltan matrículas y los apellidos del segundo profesor |
| 1 | Ortografía y redacción | Todo el documento; los números con separador de miles llevan espacio de no separación | — | ✔ (sin corrector ortográfico instalado: revisión de Leo en Word recomendada) |
| 2 | Resumen de una página, claro y completo | Resumen: problema, datos y preparación, técnicas (LDA y logística en paralelo; bootstrap como validación temporal útil), resultados con la frase central, persistencia, qué sí y qué no, recomendaciones con el corte | 2 | ✔ |
| 3 | Claridad y coherencia; descripción de la estación y factores geográficos | Sección 3 (valle, altitud, flujo del este; Figura 1, Tabla 1; contexto de SE2, SO y SUR; cambios en la red en un párrafo, con la Tabla 12 en el Anexo B) | 4–5; 23 | ✔ |
| 4 | Limpieza, imputaciones, transformaciones y justificación | 4.1 (Tabla 13, Anexo B), 4.2 (Tabla 15, Anexo B), 4.3 (Tabla 2; Figura 6, Anexo B; D18–D20; MIMA-v1), 4.4, 4.5 (Tabla 3: exclusiones y posible sesgo); Anexo B | 6–8; 22–24 | ✔ |
| 5 | Al menos dos técnicas (dependencia e interdependencia), aplicación y validación | 5.1 (Tabla 4, con aplicación previa), 5.2 PCA, 5.3 LDA (dos clasificadores en paralelo), 5.4 supuestos (Tabla 5), 5.5 logística (variables y linealidad), 5.6 errores (Figura 2), 5.7 validación (bootstrap también estratificado por temporada; Tabla 17 en el Anexo C) | 8–13 | ✔ |
| 5 | Técnicas no exitosas y su justificación | 5.8 y Anexo A (Tabla 11) | 13; 22 | ✔ |
| 6 | Solidez, calidad y pertinencia de los hallazgos | 6.1–6.6 (Tablas 6–8, Figuras 3–5); 7 | 13–17 | ✔ |
| 7 | Interpretación de gráficos y tablas, numeración y descripción; sin código | 11 figuras y 22 tablas, todas numeradas, con pie y llamada explícita en el texto; ninguna figura con título interno (las Figuras 3 y 5 solo rotulan sus paneles); ningún bloque de código visible | todas | ✔ |
| 8 | Resultados relevantes, recomendaciones y nuevas preguntas | 7: conclusión, hallazgos, Tabla 9, 7 limitaciones, 5 recomendaciones por prioridad, 7 preguntas nuevas | 16–17 | ✔ |
| 9 | Referencias APA y coherencia citas–lista | Referencias (44 entradas); `scripts/utilidades/verificar_citas.R`: 0 citas sin referencia, 0 referencias sin cita, orden alfabético correcto | 18–19 | ✔ |
| 10 | Liga al código; organización, comentarios, lenguajes y ejecución con el dataset | «Liga al código y organización»: Tabla 10 (con `10_analisis_retro_final.R`), lenguajes, cómo correrlo; README | 20–21 | ◐ la liga apunta a la etiqueta `informe-final`, que no contiene la fase F: al fusionar habrá que mover o crear la etiqueta y actualizar la liga |

## Retroalimentación (`docs/etapa4/retroalimentacion_final.md`)

### R1. Retroalimentación escrita de la etapa 2 (profesora)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| Explicar cómo entran estación y temporada al LDA y por qué es apropiado para M0 y M1 | 5.3: indicadoras k − 1, referencias CE y cálida-húmeda, M0 aditivo con 39 combinaciones, M1, razones 1–4, prior y corte | 9–10 | ✔ |
| Respaldo académico de PCA, logística y bootstrap por bloques, ligado a pregunta y variables | 5.1, Tabla 4 (pregunta, variables, por qué, respaldo y aplicación previa); 5.2 (KMO con Kaiser y Rice, 1974); 5.3, razón 4 | 8–10 | ✔ |
| Normalidad multivariada no se cumple con indicadoras; datos dependientes en el tiempo y entre estaciones | 5.3 (razón 3) y 5.4 (Tabla 5) | 10–11 | ✔ |
| El bootstrap no vuelve independientes los datos del ajuste; el PCA no controla la autocorrelación; la prueba ya se usó | 5.4; 5.2 (frase en negritas); 5.7 (el bootstrap no elimina la autocorrelación ni la incorpora al ajuste); Resumen; limitaciones 2 y 3 | 2, 9–13, 17 | ✔ |
| Exponer los supuestos con honestidad; validación temporal y logística como evidencia empírica; no interpretar como modelo generativo | 5.4 (Tabla 5); 5.3 («Dos clasificadores en paralelo»); 6.4; Tabla 9 | 10–11, 15, 17 | ✔ |

### R2. Exposición de la etapa 3 (15 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| LDA supone normalidad: cuidado con la interpretación | 5.3 (razón 3), 5.4; 6.3 (solo signos estables) | 10–11, 14 | ✔ |
| ¿El modelo absorbe la autocorrelación y la heterogeneidad de varianzas? | 5.6 (Figura 2; varianza por temporada; calibración); Tabla 5 (diagnóstico adicional); Anexo C | 12; 10–11; 28 | ✔ |
| Va a pedir la validación; qué sí y qué no se puede concluir | 5.7 (pliegues internos como diagnóstico de estabilidad; Tabla 17); Tabla 9 | 12–13; 25; 17 | ✔ (la validación de todo el procedimiento dentro de cada pliegue queda declarada como pendiente) |
| «Vecinos cercanos» es malo para estos datos | 4.3 (no se usa KNN); Anexo A | 7; 22 | ✔ |
| Usar los métodos del curso (MIMA-v1) en lugar de hacer otro proyecto de imputación | 4.3: métodos de imputeTS y párrafo «Imputación de referencia del curso» | 7 | ◐ no se pudo comparar con MIMA-v1: no obtuvimos acceso al dataset (Fase E no realizada) |
| Imputar puede mejorar, sobre todo en ventanas grandes | 4.1 (Tabla 13, Anexo B); 4.3 («Principio» y D20); pregunta nueva sobre MIMA-v1 | 6–7, 17 | ✔ |
| Métodos en la presentación; Spearman «solo es una correlación» | Spearman solo como descriptivo (sección 3) | 5 | ✔ (lo de la presentación no aplica al informe) |
| SIMA: reubicaciones confirmadas (NO3, SUR, SE, NE, NO; no SO ni NTE) | Sección 3 («Cambios en la red»); Tabla 12 (Anexo B); sensibilidad en la Tabla 18 | 5; 23; 25–26 | ✔ |
| SIMA: Juárez (pluma de la refinería, resuspensión, quemas, transporte, obras) | 3, contexto por estación: SE2 | 5 | ✔ |
| SIMA: Santa Catarina (industria, suelo, receptor de la salida del viento) | 3, contexto por estación: SO | 5 | ✔ |
| SIMA: cuidado con la imputación en esas dos estaciones; hace falta un buen validador | 4.3 D18 (la respuesta no se imputa) y validación por enmascaramiento | 6–7 | ✔ |
| SIMA: el PM2.5 es caótico, sin la periodicidad del ozono | 7, Hallazgos; ACF de la respuesta (5.6) | 16; 12 | ✔ |
| SIMA: interés en la alerta con pronóstico | 1 (justificación); 6.5 (la persistencia como base); 7 (recomendación 1 y primera pregunta nueva) | 3; 15–16; 17 | ✔ |

### R3. Información previa del socio (9 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| 2021: renovación de sensores de viento y analizadores | Sección 3 («Cambios en la red»), Tabla 12 y 4.2 (exclusión de 2020) | 5–6; 23 | ✔ |
| 2025: equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO | Sección 3; mejora por año (6.1, Figura 3b) | 5; 14 | ✔ |
| Citar como comunicación personal en el texto, no en la lista | Secciones 1, 3, 7 y Tabla 12 | 3–5, 16, 23 | ✔ (no está en la lista; el verificador de citas no lo busca) |

### R4. Retroalimentación de la etapa 3 y puntos para el reporte final (22 oct 2026)

Todo lo de este bloque es posterior a la evaluación de la prueba (fase F de `decisiones_etapa4.md`); no cambia el modelo principal.

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| Etapa 3: aplicación previa de PCA, LDA y logística en artículos, en series de tiempo o contextos ambientales, y su utilidad para el objetivo | 5.1: Tabla 4, columna «Aplicación previa en contexto ambiental o de series de tiempo» (Ramírez-Velarde et al., 2024; Mohd Shafi'i y Juahir, 2024; Vélez-Pereira et al., 2025; Saminathan y Malathy, 2023; Wilks, 2019), y una oración por técnica sobre su utilidad | 8–9 | ✔ (que Vélez-Pereira et al. usen validación temporal no se pudo verificar en el texto completo; la tabla no lo afirma) |
| Etapa 3: variables relevantes de la logística y cómo influyen en las conclusiones | 5.5, «Variables relevantes»: OR por 1 DE con IC por bootstrap por bloques, % de réplicas con el mismo signo, coincidencia con el LDA, importancia por permutación, interpretación en momios y sin valores p; Figura 5, panel b | 11; 15 | ✔ |
| Etapa 3: linealidad de los predictores continuos en la escala logit y tratamiento | 5.5, «Linealidad»: logits empíricos por decil, GAM con grados de libertad efectivos, AUC con splines en los pliegues y en la prueba; regla cumplida, así que los splines se reportan como tratamiento (ΔAUC 0.090) sin cambiar el modelo principal; Figura 8 y Tabla 18 (Anexo C) | 11; 25–27 | ✔ |
| 1. Conclusión acotada: clasificación retrospectiva en el periodo evaluado, sin respaldar un pronóstico | Resumen; 6.1 (frase central); 7, «Conclusión»; Tabla 9 | 2; 13; 16–17 | ✔ |
| 2. Describir con precisión el bootstrap, con la estructura estacional; validación temporal útil, no confirmación independiente | 5.7, «Bootstrap por bloques» (texto pedido e IC estratificado por temporada); Resumen | 12; 2 | ✔ |
| 3. Línea base de persistencia | 6.5 (Tabla 7); 7 (Hallazgos, recomendación 1); Resumen | 15–16; 16–17; 2 | ✔ (la persistencia clasifica mejor: AUC 0.872 frente a 0.792; la meteorología le agrega 0.016) |
| 4. Umbral según el uso, elegido con el entrenamiento y evaluado en la prueba; métricas por corte | 6.6 (Tabla 8); Figura 9 (Anexo C); 7, recomendación 2; Resumen | 16; 27; 17; 2 | ✔ |
| 5. Distinguir días-estación de episodios | Todo el informe usa «días-estación» para los conteos y «episodio» solo con la definición de la fase F; detección por episodio en 6.1 | 14 | ✔ (no había «episodios graves» en el texto; se cambiaron cuatro usos genéricos de «episodio») |
| 6. Causas y patrones de exclusión; respuesta en los excluidos; posible sesgo | 4.5 (Tabla 3 y texto, incluida la comparación etapa 3 → etapa 4 de NO2); Tabla 14 (Anexo B) | 8; 24 | ✔ |
| 7. Interpretación empírica del LDA y logística como referencia | 5.3, «Dos clasificadores en paralelo»; Tabla 6 con las dos columnas; 5.5; Figura 5 | 10; 13; 11; 15 | ✔ |
| 8. Las medidas acotan la incertidumbre, pero no hacen un modelo temporal completo ni una alerta operativa | 7, limitación 3 (frase textual); Tabla 9; Resumen | 17; 2 | ✔ |
| Preguntas nuevas: modelo temporal explícito y evaluación con pronóstico | 7, «Preguntas nuevas» (las dos primeras) | 17 | ✔ |

## Fase F: elementos movidos a los anexos

En el orden de prioridad pedido, cada uno sigue citado en el cuerpo:

1. Figura 2 de `informe-final` (error de imputación por método) → Figura 6, Anexo B; 4.3 conserva la tabla del método y una oración.
2. Tabla 3 (largo de los huecos) → Tabla 13, Anexo B; 4.1 conserva la cifra clave (51 % a 82 % en huecos de más de un día).
3. Tabla 2 (cambios en la red) → Tabla 12, Anexo B; la sección 3 la resume en un párrafo.
4. Tabla 8 (puente) → Tabla 17, Anexo C; 5.7 conserva una oración con 0.070 → 0.079.
5. Figura 5 (magnitud del PM2.5) → Figura 7, Anexo C; 6.1 la resume en una oración.
6. Tabla 10 (robustez) → Tabla 18, Anexo C; 6.4 la resume con el rango 0.071–0.082, y la tabla suma la fila de los splines.
7. **Fuera de la lista:** la tabla de reglas de limpieza (antes Tabla 4) → Tabla 15, Anexo B; 4.2 conserva el resumen. Con los seis anteriores el cuerpo seguía en 16 páginas.

Además, la Figura 7 de `informe-final` (coeficientes del LDA) se sustituyó por la Figura 5, del LDA frente a la logística. También se acortaron textos de las secciones 4.5, 5.1, 5.3, 6.3 y 7, se reacomodaron figuras y tablas para no dejar huecos de página, y se ajustó el tamaño de las figuras (mapa a 6.0 pulgadas, ACF a 4.0, ROC a 5.0, PCA a 3.6 y coeficientes a 5.4). En 7 se quitó la frase de comparación con Vélez-Pereira et al. (2025), que Codex había señalado como generalización; el artículo sigue citado en la sección 1 y en la Tabla 4.

## Referencias

44 entradas. Comprobadas por la revisión de Codex en Crossref y con el editor, con las correcciones ya aplicadas en la versión `informe-final`. Nuevas en la fase F, verificadas el 22 de octubre de 2026:

- **Mohd Shafi'i y Juahir (2024).** *Environmental Monitoring and Assessment, 196*(7), Artículo 640, en Crossref; el resumen (Europe PMC) confirma datos diarios de 8 estaciones (2011–2021), análisis discriminante (90.50 % de asignación correcta) y PCA.
- **Saminathan y Malathy (2023).** *Frontiers in Big Data, 6*, Artículo 1175259, en PMC; logística entre otros clasificadores de PM2.5 con variables meteorológicas en 12 estaciones de Pekín.
- **Wood (2017).** 2.ª ed., Chapman and Hall/CRC, en Crossref.
- **Youden (1950).** *Cancer, 3*(1), 32–35, en Crossref.
- **Vélez-Pereira et al. (2025)**, ya citado: el resumen confirma la logística para superaciones diarias de PM2.5 y PM10 en Chile, pero no se pudo leer el texto completo para confirmar una validación temporal.
- **Ramírez-Velarde et al. (2024)**, ya citado: el resumen confirma PCA con datos meteorológicos para contingencias en la ZMM.

**Sin fuente pública:** Sistema Integral de Monitoreo Ambiental (2026, 14 de agosto), presentación de diapositivas. En el texto, la primera cita define la sigla; en la lista va el nombre completo sin la sigla.

## Cambios de la revisión de Opus (borrador 37de55d; numeración de tablas y figuras de esa versión)

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

## Cambios de la revisión de Codex (`4644e16`; numeración de tablas y figuras de la versión `informe-final`)

Ninguno cambia una cifra del análisis.

- **I1.** 5.6: los pliegues internos diagnostican la estabilidad del ajuste sobre la base final; la imputación y su selección usaron todo 2021–2023. Limitación 2 lo repite.
- **I2.** Tabla 7: la fila «Homogeneidad de los errores» pasa a «Diagnóstico adicional: variación de los residuos y calibración» (no es un supuesto del LDA; Brown-Forsythe solo descriptivo); implicaciones de normalidad y covarianzas reescritas; 5.5 dice que la variación es esperable en parte con una respuesta binaria.
- **I3.** 4.3 (D20): el 0.436 es el promedio de las cinco imputaciones de MICE del experimento de selección; la sensibilidad del clasificador usa 20 bases (ΔAUC 0.078).
- **I4.** Liga al código: hipervínculo a la etiqueta `informe-final`, creada sobre el commit de fusión del PR #11 (no se enlaza el commit `4644e16`).
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

## Reproducción desde un clon limpio (versión `informe-final`)

21 de octubre de 2026, Windows 11, R 4.6.1. Clon desde GitHub de la rama `analisis/etapa4` en el commit `fa4baf0`, en una carpeta nueva; `renv::restore()` instaló 159 paquetes (incluido `zip`) y `renv::status()` no reportó problemas. Sin los Excel y sin `SIMA_DATA_DIR`; con `MOTIVO_RECORRIDA`, porque los registros de 07b y 09a ya están versionados.

- **Orden del README:** 06 → 06b → 07a → 07b → 07c → 08a → 08b → 08c → 08d → 09a → 09b → 09c → 09d → 09e → 09f → 09g → 09h. Los 17 scripts terminaron con código 0 (unos 50 minutos; 08a, 35).
- **El candado de 09a ya no se dispara:** 08d regeneró `data/clean/v2/muestra_v2_mice_m20.csv.gz` con otros bytes (ahora con `\n`), pero su contenido descomprimido y sin `\r` es el mismo que en el commit, y 09a corrió.
- **Salidas versionadas (380 archivos):** todos los CSV, PNG y datos coinciden en contenido con el commit. Solo difieren, como se espera, la fecha y el commit de cuatro `RESUMEN.md` (etapas 2, 3 y 4 y el diagnóstico de la etapa 3), los registros de la prueba de 07b y 09a (agregan esta corrida), los tiempos de cómputo de 08a (`tiempos_enmascaramiento_horario.csv`) y la fecha de creación dentro de `output/etapa3/modelo_final.rds` (`all.equal` sin ese campo: TRUE).
- **09h del commit `9726021`:** en el mismo clon, las siete figuras del informe salen idénticas a las versionadas.
- **Receta del Word en el clon:** `quarto render`, `scripts/utilidades/formato_docx.R` (con `zip` 3.0.2 de la biblioteca restaurada) y `scripts/utilidades/verificar_citas.R` terminan sin error; el Word resultante es idéntico al de la entrega salvo `docProps/core.xml` (fecha).
