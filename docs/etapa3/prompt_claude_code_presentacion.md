Rama analisis/etapa3. Crea la presentación de la exposición con el socio formador (SIMA). Usa todas tus skills de diseño de presentaciones (pptx o equivalente) y de visualización. Antes de empezar, léete docs/etapa3/guion_exposicion.md y docs/etapa3/texto_etapa3_borrador.md.

REQUISITOS DEL CURSO (no negociables)
- Portada + 3 diapositivas de contenido, para una exposición de máximo 5 minutos con un solo expositor.
- Letra legible: cuerpo de 20 pt como mínimo, títulos de 28 pt como mínimo; cifras clave grandes (40 pt o más).
- Debe contestar: qué queremos hacer (objetivo y justificación); el plan (datos: zonas, variables y años; técnicas y su justificación); qué se ha hecho y qué problemas encontramos; qué falta por hacer.
- Debe incluir: porcentaje de datos imputados, porcentaje perdido por faltantes y porcentaje de datos atípicos o inconsistentes eliminados, con el motivo.
- Portada: nombre del proyecto, «Equipo 1 · Grupo 201 · Análisis multivariado (MA2003B)», socio formador SIMA y los nombres de los cuatro integrantes (Leonardo Orozco, Pablo Alonso Robles Nava, Daniel Ayala, Ignacio Kume) con "Matrícula: ________" en blanco. NO pongas matrículas: este archivo va al repositorio público.

DISEÑO
- Estilo sobrio y profesional, de fondo claro y alto contraste. Una idea por diapositiva, una figura grande y como máximo 4–5 viñetas cortas (≤ 12 palabras).
- Paleta coherente con las figuras del proyecto: azul #0072B2 para M0 y naranja #D55E00 para M1, más grises neutros. No uses colores que choquen con las figuras.
- Las cifras clave van como "tarjetas" de número grande: "0.72 → 0.79", "73 % vs 58 %", "89 % de episodios > 40 µg/m³", "+0.14 en mar–may".
- Usa solo figuras que ya existen en output/etapa3/figuras/. Puedes recortar márgenes o regenerar una figura en tamaño de diapositiva con el mismo código, pero sin cambiar datos.
- Antes de entregar, renderiza cada diapositiva a imagen y revisa: que no haya texto desbordado ni encimado, que todo sea legible a distancia y que no haya figuras deformadas. Corrige y vuelve a revisar.

CONTENIDO (las cifras son exactas; no las cambies ni agregues otras)

Portada
- Título: «¿Cuánto ayuda el clima a identificar los días de PM2.5 alto en Monterrey?»
- Subtítulo: Reto SIMA · Etapa 3: modelado y evaluación

Diapositiva 1 — Qué queremos hacer y con qué datos
- Objetivo: medir cuánto mejora la meteorología del día la identificación de días-estación con PM2.5 > 25 µg/m³ (24 h, NOM-025-SSA1-2021), frente a solo conocer estación y temporada.
- Por qué: el PM2.5 se asocia con efectos en la salud por exposición de corto plazo; sirve para orientar la vigilancia de SIMA.
- Datos: 13 estaciones · 2021–2025 · PM2.5 + 8 variables meteorológicas · 15 390 estación-días.
- Preparación de datos (en un recuadro o tarjetas):
  · Faltantes de origen: 12.3 % de los valores horarios (PM2.5: 26 %).
  · Inconsistentes eliminados: 0.7 % (radiación nocturna, viento distinto al de la red, valores repetidos 24 h, saltos, fuera de rango).
  · Imputados: 1.0 % (solo huecos ≤ 3 h).
- Figura: output/etapa3/figuras/mapa_estaciones.png (% de días con superación por estación).

Diapositiva 2 — Cómo lo analizamos y qué encontramos
- Técnicas:
  · PCA (interdependencia): 3 ejes del clima explican el 67 %.
  · LDA (dependencia): M0 (estación + temporada) frente a M1 (+ clima).
- Validación: entrenamiento 2021–2023 y prueba 2024–2025, con decisiones fijadas antes.
- Tarjetas: AUC 0.72 → 0.79 (+0.07; IC 95 %: 0.05–0.09) · detecta 73 % vs 58 % de las superaciones · 89 % de los episodios > 40 µg/m³.
- Ayuda más en marzo–mayo (+0.14); casi nada en lluvias.
- Se asocia con: presión baja, más temperatura y menos viento.
- Figura: roc_m0_m1_prueba.png o dauc_temporada.png (elige la más legible en tamaño diapositiva; puedes usar ambas si caben grandes).

Diapositiva 3 — Problemas, qué sigue y preguntas para SIMA
- Problemas:
  · lecturas sospechosas (viento SO2/NE2 2021; radiación nocturna NO2, SE3, CE), atendidas con una regla nueva;
  · cambios de equipos 2021/2025: revisados, no cambian la conclusión;
  · retención desigual entre estaciones.
- Hecho: interfaz Shiny para usar el modelo (captura pequeña de output/etapa3/figuras/app_calcular.png).
- Sigue: meteorología pronosticada (alerta real) · PM2.5 del día anterior · cortes por estación.
- Preguntas para SIMA:
  · fechas de cambio de sensores y posibles reubicaciones de 2021;
  · hora local y unidad de lluvia;
  · ¿qué fuentes explican Juárez (SE2) y Santa Catarina (SO)?;
  · ¿les serviría una alerta con pronóstico?

NOTAS DEL ORADOR: copia en las notas de cada diapositiva el texto correspondiente de docs/etapa3/guion_exposicion.md.

ENTREGABLES
1. docs/presentacion/Presentacion_Etapa3_SIMA.pptx (editable; debe abrir bien en Google Slides: usa fuentes estándar como Calibri o Arial, sin dependencias raras).
2. docs/presentacion/Presentacion_Etapa3_SIMA.pdf.
3. Imágenes de revisión de cada diapositiva en docs/presentacion/revision/ (no las subas al repo; agrégalas al .gitignore).
4. Commit y push de 1 y 2, más docs/etapa3/guion_exposicion.md y los dos .md de Opus que estén en la carpeta, si no están versionados.
5. Abre el PR de analisis/etapa3 contra main SIN fusionarlo, con una descripción breve: etapas 07a–07c, app, informe y presentación.

Al terminar, dame:
- las rutas de los archivos;
- las 4 imágenes de revisión (o su ruta);
- cualquier cifra o texto que tuviste que acortar;
- el enlace del PR.
