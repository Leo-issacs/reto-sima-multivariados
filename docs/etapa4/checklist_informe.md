# Checklist del informe final

Páginas según el PDF de revisión (`docs/etapa4/Informe_final_SIMA_Equipo1.pdf`, convertido con Word desde el .docx; 25 páginas en total). Si Leo edita el .docx, las páginas pueden moverse.

**Extensión:** las secciones 1–7 van de la página 3 («1. Introducción y justificación») a la 16 (fin de «7. Discusión y conclusiones»): **14 páginas** (límite 15, meta 14). Las Referencias empiezan en la página 17. El Resumen ocupa una página (p. 2).

Estado: ✔ atendido · ◐ atendido en parte (ver nota) · ✘ no atendido.

## Rúbrica

| # | Criterio | Dónde | Pág. | Estado |
|---|---|---|---|---|
| 1 | Estructura mínima completa, ≤ 15 páginas, PDF sin recortes | Carátula, Resumen, secciones 1–7, Referencias, Liga al código, Anexos A–D | 1–25; 1–7 en pp. 3–16 | ✔ (revisadas las 25 páginas como imagen: nada cortado ni encimado) |
| 1 | Identificación con equipo y matrículas | Carátula: «Matrícula: ________» para cada integrante (Leo las llena en Word) | 1 | ◐ faltan matrículas y profesores [COMPLETAR] |
| 1 | Ortografía y redacción | Todo el documento; revisión automática de «¿», «µg/m³», «PM2.5», palabras repetidas y dobles espacios | — | ✔ (sin corrector ortográfico instalado: revisión de Leo en Word recomendada) |
| 2 | Resumen de una página, claro y completo | Resumen: problema, datos y preparación, técnicas, resultados con cifras, qué sí y qué no, recomendaciones | 2 | ✔ |
| 3 | Claridad y coherencia; descripción de la estación y factores geográficos | Sección 3 (valle, altitud, flujo del este, salida por Santa Catarina y García; Figura 1, Tablas 1–2; contexto de SE2, SO y SUR) | 4–5 | ✔ |
| 4 | Limpieza, imputaciones, transformaciones y justificación | 4.1 (Tabla 3), 4.2 (Tabla 4), 4.3 (Figura 2, Tabla 5, D18–D20, MIMA-v1), 4.4, 4.5; Anexo B | 6–9; 21 | ✔ |
| 5 | Al menos dos técnicas (dependencia e interdependencia), aplicación y validación | 5.1 (Tabla 6, ruta), 5.2 PCA, 5.3 LDA, 5.4 supuestos (Tabla 7), 5.5 errores (Figura 3), 5.6 validación (Tabla 8) | 9–12 | ✔ |
| 5 | Técnicas no exitosas y su justificación | 5.7 y Anexo A (Tabla 13) | 12; 21 | ✔ |
| 6 | Solidez, calidad y pertinencia de los hallazgos | 6.1–6.4 (Tablas 9–10, Figuras 4–7); 7 | 12–16 | ✔ |
| 7 | Interpretación de gráficos y tablas, numeración y descripción; sin código | 9 figuras y 18 tablas, todas numeradas, con pie y citadas en el texto antes o junto a ellas; ningún bloque de código visible | todas | ✔ |
| 8 | Resultados relevantes, recomendaciones y nuevas preguntas | 7: hallazgos, Tabla 11, limitaciones, 5 recomendaciones por prioridad, 7 preguntas nuevas | 16 | ✔ |
| 9 | Referencias APA y coherencia citas–lista | Referencias (40 entradas); `scripts/utilidades/verificar_citas.R`: 0 citas sin referencia, 0 referencias sin cita, orden alfabético correcto | 17–19 | ✔ (ver lista [verificar] abajo) |
| 10 | Liga al código; organización, comentarios, lenguajes y ejecución con el dataset | «Liga al código y organización» (Tabla 12, lenguajes, cómo correrlo); README del repositorio | 19–20 | ✔ |

## Retroalimentación (`docs/etapa4/retroalimentacion_final.md`)

### R1. Retroalimentación escrita de la etapa 2 (profesora)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| Explicar cómo entran estación y temporada al LDA y por qué es apropiado para M0 y M1 | 5.3: indicadoras k − 1, referencias CE y cálida-húmeda, M0 aditivo con 39 combinaciones, M1, razones 1–4, prior y corte | 10 | ✔ |
| Respaldo académico de PCA, logística y bootstrap por bloques, ligado a pregunta y variables | 5.1, Tabla 6 (columnas pregunta, variables, por qué, respaldo) | 9 | ✔ |
| Normalidad multivariada no se cumple con indicadoras; datos dependientes en el tiempo y entre estaciones | 5.3 (razón 3) y 5.4 (Tabla 7) | 10–11 | ✔ |
| El bootstrap no vuelve independientes los datos del ajuste; el PCA no controla la autocorrelación; la prueba ya se usó | 5.4, párrafo bajo la Tabla 7; 5.2 (frase en negritas) | 9–11 | ✔ |
| Exponer los supuestos con honestidad; validación temporal y logística como evidencia empírica; no interpretar como modelo generativo | 5.4; 6.4; Tabla 11 | 10–11, 15–16 | ✔ |

### R2. Exposición de la etapa 3 (15 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| LDA supone normalidad: cuidado con la interpretación | 5.3, 5.4; 6.3 (solo signos estables) | 10–11, 14 | ✔ |
| ¿El modelo absorbe la autocorrelación y la heterogeneidad de varianzas? | 5.5 (Figura 3: ACF 0.50 → 0.44 → 0.42; varianza por temporada; calibración); Tabla 7; Anexo C | 11; 22 | ✔ |
| Va a pedir la validación; qué sí y qué no se puede concluir | 5.6 (Tabla 8); Tabla 11 | 12; 16 | ✔ |
| «Vecinos cercanos» es malo para estos datos | 4.3 (no se usa KNN); Anexo A | 7; 21 | ✔ |
| Usar los métodos del curso (MIMA-v1) en lugar de hacer otro proyecto de imputación | 4.3: métodos de imputeTS (fuente principal del curso) y párrafo «Imputación de referencia del curso» sobre MIMA-v1 | 7–8 | ◐ no se pudo comparar con MIMA-v1: no obtuvimos acceso al dataset (Fase E no realizada) |
| Imputar puede mejorar, sobre todo en ventanas grandes | 4.1 (Tabla 3: los huecos son largos); 4.3 D20 (imputación diaria con la red recupera 4 192 días); pregunta nueva sobre MIMA-v1 | 6, 8, 16 | ◐ los huecos largos se cubren a nivel diario, no horario |
| Métodos en la presentación; Spearman «solo es una correlación» | Spearman solo como descriptivo (sección 3) | 5 | ✔ (lo de la presentación no aplica al informe) |
| SIMA: reubicaciones confirmadas (NO3, SUR, SE, NE, NO; no SO ni NTE) | Tabla 2; sensibilidad con la lista de SIMA (Tabla 10) | 5; 15 | ✔ |
| SIMA: Juárez (pluma de la refinería, resuspensión, quemas, transporte, obras) | 3, contexto por estación: SE2, con cociente PM2.5/PM10 y viento | 5 | ✔ |
| SIMA: Santa Catarina (industria, suelo, receptor de la salida del viento) | 3, contexto por estación: SO | 5 | ✔ |
| SIMA (H. Vélez): cuidado con la imputación en esas dos estaciones; hace falta un buen validador | 4.3 D18 (la respuesta no se imputa) y validación por enmascaramiento de cada imputación | 7 | ✔ |
| SIMA (H. Vélez): el PM2.5 es caótico, sin la periodicidad del ozono | Implícito: ACF de la respuesta y episodios de varios días (5.5, 5.6) | 11–12 | ◐ no se comenta explícitamente |
| SIMA (H. Vélez): interés en la alerta con pronóstico | 1 (justificación), 7 (recomendación 1 y primera pregunta nueva) | 3; 16 | ✔ |

### R3. Información previa del socio (9 oct 2026)

| Punto | Dónde | Pág. | Estado |
|---|---|---|---|
| 2021: renovación de sensores de viento y analizadores | Tabla 2 y 4.2 (exclusión de 2020) | 5–6 | ✔ |
| 2025: equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO | Tabla 2; mejora por año (6.1, Figura 4b) | 5; 13 | ✔ |
| Citar como comunicación personal en el texto, no en la lista | Secciones 1, 3 y Tabla 2 | 3–5 | ✔ (no está en la lista; el verificador de citas no lo busca) |

## Referencias marcadas [verificar]

Verificadas en Crossref en esta sesión (autores, revista, volumen, número, páginas y DOI coinciden): Efron (1975), Krzanowski (1975), Roberts et al. (2017), Carlstein (1986), Mardia (1970), Kaiser (1974), Moons et al. (2006), Rencher (1992), Jolliffe y Cadima (2016), Estévez et al. (2011, DOI agregado), Bartlett (1950), James et al. (2021), Vélez-Pereira et al. (2025), Plaia y Bondì (2006), Quinteros et al. (2019), Belachsen y Broday (2022), Hadeed et al. (2020), van Buuren y Groothuis-Oudshoorn (2011), Box (1949), Künsch (1989), Kaiser (1960) y Fawcett (2006).

**[verificar]** (sin DOI o sin fuente consultable desde aquí):

- Wilks, D. S. (2019). *Statistical methods in the atmospheric sciences* (4th ed.). Elsevier. Libro: confirmar edición y año.
- Johnson, R. A., & Wichern, D. W. (2007). *Applied multivariate statistical analysis* (6th ed.). Pearson. Viene de los informes anteriores.
- Gómez et al. (2025) y Gómez Santos et al. (2026): datos dados por Leo; confirmar con el reporte de MIMA-v1 y el programa del COMIA 2026.
- Gobierno del Estado de Nuevo León (2024, 7 de marzo), boletín: sin URL; viene de la etapa 1.
- Sistema Integral de Monitoreo Ambiental (2026, 14 de agosto), presentación: viene de la etapa 1.
- Secretaría de Salud (2021), NOM-025-SSA1-2021 en el DOF: viene de la etapa 2.
