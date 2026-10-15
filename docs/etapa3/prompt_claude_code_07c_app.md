Rama: analisis/etapa3. La fase B (07b) ya evaluó la prueba. NO se reajusta ni se cambia ningún modelo: lo que sigue son diagnósticos del modelo congelado y la interfaz que pide la etapa 3.

PARTE 1 — scripts/07c_diagnostico_errores.R (diagnósticos posteriores; no cambian decisiones)
0. Reconstruye exactamente los modelos finales de 07b: M0 y M1 con LDA, entrenados con 2021–2023, con PRS como anomalía de su estación, sin transformaciones y con corte en 0.258. Verifica que los AUC de la prueba coincidan con prueba_metricas_m0_m1.csv (tolerancia 1e-9); si no coinciden, detente.
   - Guarda output/etapa3/modelo_final.rds con:
     · los objetos de M0 y M1;
     · las medias y desviaciones de escalado del entrenamiento;
     · las medias de PRS por estación del entrenamiento;
     · los niveles de los factores;
     · el corte;
     · las predicciones de la prueba (estación, fecha, PM2.5, supera_25, p_M0, p_M1).
   - Agrega al final de output/etapa3/registro_prueba.txt: "Diagnósticos posteriores (07c): no modifican modelos ni métricas".
1. Matrices de confusión de M0 y M1 en la prueba (conteos y tasas: VP, FN, FP, VN).
2. Errores por temporada y por estación, para M0 y M1: n, % de superación, sensibilidad, especificidad, tasa de FN y tasa de FP.
3. Errores según la magnitud del PM2.5, con intervalos [0,15), [15,20), [20,25], (25,30], (30,40] y >40. Reporta el % de días clasificados como superación por M0 y por M1. Sirve para ver si los errores se concentran cerca del umbral.
4. Calibración: agrupa la probabilidad predicha en deciles; compara la probabilidad media predicha con la frecuencia observada, para M0 y M1. Agrega intercepto y pendiente de recalibración (logística de y sobre logit(p)).
5. Importancia por permutación en la prueba (M1), con 200 permutaciones y set.seed(2026):
   - cada una de las 8 variables meteorológicas por separado;
   - el grupo «viento» (u, v y rapidez juntos);
   - «estación» (permutar la etiqueta);
   - «temporada».
   Reporta la caída media del AUC y sus percentiles 2.5 y 97.5. Haz lo mismo en M0 para «estación» y «temporada».
6. Supuestos que faltaban (entrenamiento 2021–2023):
   a) VIF de los predictores continuos de M1 (con car::vif sobre un lm auxiliar o con la diagonal de la inversa de la matriz de correlación) y número de condición.
   b) Dependencia: residuo r = supera_25 − p_M1 en la prueba. Calcula la autocorrelación a rezagos 1–14 dentro de cada estación (promedio entre estaciones) y la correlación promedio entre pares de estaciones el mismo día. Esto justifica el bootstrap por bloques.
   c) Normalidad multivariada por clase: prueba de Henze-Zirkler o de Mardia (paquete MVN) sobre las 8 variables continuas; reporta solo el estadístico y el p-valor. Con este n va a rechazar; se documenta.
7. Figura de mapa: output/etapa3/figuras/mapa_estaciones.png. Puntos con la latitud y longitud de data/metadata/estaciones.csv (solo las 13 estaciones), color = % de días con superación en la muestra y etiqueta con el código. SIN mapa base descargado: solo ggplot con coord_quickmap y ejes limpios. Agrega una nota con la escala aproximada en km.
8. Figuras en output/etapa3/figuras/ (títulos sin "Figura N"):
   - errores_temporada_estacion.png (sensibilidad y especificidad de M0 y M1 por temporada y por estación);
   - errores_magnitud_pm25.png;
   - calibracion.png;
   - importancia_permutacion.png;
   - acf_residuos.png;
   - dauc_temporada.png (ΔAUC por temporada con IC, desde prueba_dauc_por_temporada.csv).
9. CSV en output/etapa3/diagnostico/ y un resumen en output/etapa3/RESUMEN_DIAGNOSTICO.md con todas las cifras.

PARTE 1b — Diagnósticos por cambios de instrumentos (información nueva del socio formador; dentro de 07c)
Contexto: SIMA informó el 9 de octubre de 2026 que (1) en 2021 renovó los sensores de viento (WSR y WDR) de todas las estaciones y los analizadores de O3, NO2, SO2 y CO (excepto en SE2, SO2 y NTE2); (2) en 2025 instaló equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO, completó CO en SE2, SO2 y NTE2 y cambió las bombas de los BAM de PM10. Opus ya vio que el viento cambia de nivel entre marzo y abril de 2021 (la mediana diaria de SE3 pasa de 0.6 a 2.7 m/s).
Todo esto es POSTERIOR a la evaluación de la prueba: regístralo así en registro_prueba.txt ("diagnósticos posteriores motivados por información del socio formador recibida el 9-oct-2026; el modelo principal no cambia").
1. Figura viento_mensual_2020_2025.png: mediana mensual de viento_rapidez_ms por estación (13 estaciones, facetas o líneas), con una línea vertical en 2021-03-01. Tabla con el mes en que cada estación cambia de nivel (el primer mes de 2021 cuya mediana difiere más del 30 % de la mediana de 2020), solo como apoyo descriptivo.
2. Desempeño en la prueba por año: AUC de M0 y M1 y ΔAUC con IC por bootstrap de bloques de 14 días, por separado para 2024 y 2025.
3. Desempeño por grupo de estaciones: las 5 con equipo nuevo de PM2.5 en 2025 (SE2, NTE2, SUR, SO2, NO) frente a las otras 8, en 2024 y en 2025 (4 celdas). Mismas métricas y n por celda. Si alguna celda tiene menos de 100 días o menos de 20 superaciones, repórtala pero márcala como "n insuficiente".
4. Nivel relativo del PM2.5: mediana mensual del cociente PM2.5 de la estación / mediana de la red del mismo día, 2024–2025, para las 5 estaciones. Figura pm25_relativo_2024_2025.png.
5. Sensibilidad posterior: reentrena M0 y M1 solo con días desde 2021-04-01 (después de la renovación del viento) y evalúa la prueba con el mismo procedimiento. Reporta ΔAUC [IC 95 %] y el n de entrenamiento.
6. Agrega todo a RESUMEN_DIAGNOSTICO.md, en una sección "Cambios de instrumentos".

PARTE 2 — Interfaz gráfica (la etapa 3 pide "una interfaz gráfica que permita utilizar el modelo y validar los resultados")
Shiny en app/app.R. En español, letra legible, sin dependencias exóticas (shiny, bslib si ya está en renv, ggplot2). Carga output/etapa3/modelo_final.rds.
- Pestaña «Calcular»:
  · Elegir estación y temporada (o una fecha, de la que se deduce la temporada).
  · 8 deslizadores meteorológicos. Valor inicial: la mediana de esa estación × temporada en el entrenamiento. Rango: percentiles 1–99 del entrenamiento.
  · Salida: probabilidad de superación según M0 y según M1 (barras), clasificación con el corte 0.258 y la contribución de cada variable al puntaje discriminante (barras: coeficiente × valor estandarizado).
  · Texto fijo visible: "Clasificación retrospectiva con meteorología observada. No es un pronóstico."
- Pestaña «Desempeño 2024–2025»: elegir estación y temporada. Mostrar la tabla de métricas de M0 y M1 de ese subconjunto y una serie de tiempo del PM2.5 observado con la probabilidad de M1, marcando los falsos negativos y los falsos positivos.
- Pestaña «Acerca de»: datos, modelo, limitaciones y liga al repositorio.
- Validación: tests/test_app_predicciones.R. La función de predicción de la app debe reproducir p_M0 y p_M1 de 20 filas aleatorias de la prueba (tolerancia 1e-10). Agrega también una prueba de que la app no falla con valores en los extremos de los deslizadores.
- README: sección "Interfaz", con cómo correrla (shiny::runApp("app")) y, opcional, instrucciones para publicarla en shinyapps.io (no la publiques sin que Leo lo pida).
- Toma 3 capturas de la app y guárdalas en output/etapa3/figuras/app_*.png.

ESTILO: Leo está aprendiendo R. Escribe por bloques numerados, con un comentario breve que explique qué hace cada bloque y por qué.

PARTE 3 — Pendientes del PR #9 (después de las partes 1 y 2; van en analisis/etapa2)
- 04_validar_limpios.R:
  · exigir la anulación conjunta de WSR, WDR, u y v en las horas E;
  · revalidar la rapidez implícita sqrt(u² + v²) de las componentes imputadas contra la regla de la red;
  · agregar a 05 pruebas que fallen con los tres errores que sembró Codex.
- 05_probar_limpieza.R: agregar los casos de viento exactamente a +30 km/h y de una invalidación que deje la red con 4 estaciones.
- 03_limpiar.R, línea 269: corregir la frase que todavía llama al núcleo B "conjunto principal de modelado".
- Después, rebasa analisis/etapa3 sobre analisis/etapa2 actualizado.

Al terminar, dame:
- la verificación del paso 0;
- las matrices de confusión;
- la tabla de errores por temporada;
- la tabla de errores por magnitud del PM2.5;
- la calibración;
- la importancia por permutación;
- el VIF y el número de condición;
- la autocorrelación (rezago 1 y promedio entre estaciones);
- la prueba de normalidad;
- la ruta de la app, el resultado de sus pruebas y las capturas;
- todo lo que no cuadre.
