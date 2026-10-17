Crea la rama analisis/etapa4 a partir de analisis/etapa3. Antes de empezar, lee completos estos archivos:
- docs/etapa4/decisiones_etapa4.md (decisiones D18–D23; es el contrato de este trabajo);
- docs/etapa4/imputacion_reto_sima_consolidado.md;
- data/clean/README.md;
- docs/etapa2/protocolo.md.

Trabajarás en tres fases: A, B y C. **Al terminar la fase A, detente y repórtame. No empieces la B hasta que te diga "continúa".**

REGLAS GENERALES
- No sobrescribas nada de datos-v1.2 ni de output/etapa3: los resultados de la etapa 3 deben seguir reproduciéndose. Lo nuevo va en data/clean/v2/, output/etapa4/ y en scripts nuevos numerados 08* y 09*.
- Fija la semilla en 2026 en todo lo aleatorio.
- Escribe en bloques numerados, con un comentario breve que diga qué hace cada bloque y por qué. Leo está aprendiendo R.
- Paquetes nuevos (imputeTS ya está; mice, klaR o los que hagan falta): instálalos con renv y haz renv::snapshot().
- Nada de matrículas en el repositorio.
- Si algo de decisiones_etapa4.md no se puede hacer como está escrito, no improvises: repórtalo.

======================================================================
FASE A — Elegir los métodos de imputación usando solo 2021–2023
======================================================================

A1. scripts/08a_enmascaramiento_horario.R (D19)
- Usa los datos horarios de 2021–2023 de las 13 estaciones de la muestra.
- Si tienes los Excel (SIMA_DATA_DIR), parte de la serie limpia antes de imputar.
- Si no, parte de data/clean/sima_horario_limpio_AAAA.csv convirtiendo a NA las horas con bandera I. Las horas con bandera E, L o M deben quedar NA siempre.
- Busca tramos sin NA de al menos 72 h por estación y variable. En ellos, borra bloques de 1, 2, 3, 6, 12 y 24 h (unos 5 % de las horas del tramo), con 5 semillas.
- Variables: TOUT, RH, SR, PRS, viento_u, viento_v. Agrega PM2.5 solo como diagnóstico.
- Métodos de imputeTS, sobre la serie de la estación:
  - na_interpolation: linear, spline y stine;
  - na_ma con weighting = "exponential" y k = 4;
  - na_kalman con model = "StructTS" y smooth = TRUE;
  - na_seadec sobre un ts de frequency = 24;
  - na_locf, como piso de referencia.
  Verifica los nombres de los argumentos en la versión instalada. Si Kalman es demasiado lento en la serie completa, aplícalo por ventanas mensuales con 48 h de margen a cada lado y anota el tiempo de corrida.
- Métricas por variable × método × largo de hueco:
  - RMSE, MAE y sesgo horario;
  - RMSE del promedio diario resultante (el día que contiene el hueco, frente al mismo día sin borrar);
  - solo para PM2.5: error en el máximo horario del hueco, para mostrar si el método aplana los picos.
- Aplica la regla de decisión de D19 tal cual está escrita: método ganador por variable y maxgap.
- Salidas en output/etapa4/imputacion/:
  - enmascaramiento_horario.csv;
  - figura rmse_por_metodo_y_hueco.png (paneles por variable);
  - eleccion_metodo_horario.csv (método y maxgap por variable, con la cifra que lo justifica).

A2. scripts/08b_construir_base_v2.R (D18, D19, D23)
- Construye el diario con la imputación horaria elegida en A1, solo para la meteorología.
- Conserva las reglas: no imputar horas E, L ni M; revalidar todo valor imputado y revertir con bandera X el que viole una regla (reutiliza las funciones de R/limpieza.R; no las dupliques).
- PM2.5 diario: solo con horas observadas, ≥ 18 h (D18).
- Agrega la columna `sitio_valido` según D23: 0 en los días previos a la reubicación (NO antes del 2021-07-01; SE, SO, NTE y SUR antes del 2021-10-01; NE antes del 2022-03-01), 1 en los demás.
- Tabla de pérdidas al estilo de output/etapa2/perdidas_muestra.csv, comparando datos-v1.2 con v2: días con respuesta válida, días con meteorología completa y días que quedarían para MICE (≤ 4 variables faltantes de 8).

A3. scripts/08c_enmascaramiento_diario.R (D20)
- Solo 2021–2023 y solo días con meteorología diaria completa.
- Borra valores de las 8 meteorológicas imitando el patrón real de faltantes por variable (proporciones de la tabla A2).
- Compara tres métodos:
  1. mice con pmm, m = 5 para esta validación. Predictores: la mediana de la red ese día para cada variable, las otras meteorológicas de la estación, estación, temporada y año. SIN PM2.5 ni supera_25.
  2. La mediana de la red ajustada por la diferencia media de la estación en el entrenamiento.
  3. La media de estación × temporada.
- Métricas: RMSE y MAE por variable.
- Regla de D20: si MICE no gana, se usa el método que gane, con una sola imputación.
- Salida: output/etapa4/imputacion/enmascaramiento_diario.csv.

A4. Cierre de la fase A
- Escribe output/etapa4/imputacion/RESUMEN_FASE_A.md con:
  - las tablas de A1, A2 y A3;
  - los métodos elegidos;
  - el número de días que tendrá la base v2 por estación y por año, comparado con v1.2.
- NO ajustes ningún LDA ni calcules ningún AUC con 2024–2025.
- Commit; etiqueta anotada `etapa4-decisiones-cerradas`; push.

**DETENTE AQUÍ.** Dame:
1. la tabla de métodos ganadores y maxgap por variable;
2. el resultado del diagnóstico de picos de PM2.5;
3. la tabla de MICE frente a las referencias;
4. los días de v2 frente a v1.2;
5. cualquier cosa que no cuadre.

======================================================================
FASE B — Evaluación única de la prueba con la base v2 (solo cuando te diga "continúa")
======================================================================

B1. scripts/08d_imputar_diario_mice.R
- Aplica el método elegido en A3 a los días con respuesta válida y ≤ 4 meteorológicas faltantes.
- Ajusta los modelos de imputación solo con 2021–2023: usa el argumento `ignore` de mice para 2024–2025; verifica que exista en la versión instalada.
- m = 20.
- Guarda data/clean/v2/muestra_v2_imputada.csv.gz en formato largo, con columna .imp. Ajusta .gitignore para que se suba y comprueba que pese menos de 50 MB.
- Agrega diagnósticos: densidades observadas frente a imputadas por variable (figura) y convergencia de mice.

B2. scripts/09a_evaluar_prueba_v2.R
- Mismo procedimiento que 07b: LDA con prior y corte iguales a la prevalencia de entrenamiento; PRS como anomalía de su estación; sin transformaciones; logística como robustez.
- Cambios:
  - entrenamiento solo con sitio_valido == 1 (D23);
  - la media de PRS por estación se calcula solo con días sitio_valido == 1 del entrenamiento;
  - con las m = 20 bases: M0 y M1 en cada base y ΔAUC promedio;
  - IC: bootstrap por bloques de 14 días, 200 réplicas por base, percentiles de las 4 000 réplicas combinadas.
- Construye la TABLA PUENTE de decisiones_etapa4.md §6 (pasos 0 a 4). Cada paso cambia una sola cosa. El paso 0 debe reproducir 0.070 [0.047, 0.094].
- Sensibilidades:
  - límite de ≤ 2 variables faltantes para MICE;
  - respuesta con PM2.5 interpolado ≤ 3 h;
  - casos completos v2 sin MICE.
- Registra la corrida en output/etapa4/registro_prueba_v2.txt con el commit de la etiqueta y el commit del código. Es la ÚNICA evaluación prevista.
- Salidas en output/etapa4/: RESUMEN.md, tabla_puente.csv y las figuras ROC y ΔAUC por temporada, con el estilo de la etapa 3.

======================================================================
FASE C — Validación e interpretación del LDA (D21) y área de estudio (D22, D23)
======================================================================

C1. scripts/09b_validar_lda.R (usa el modelo final v2; si usaste MICE, trabaja con la primera base imputada y repite el punto 1 en 5 bases para confirmar)
1. Bootstrap por bloques de 14 días en el ENTRENAMIENTO (1 000 réplicas): IC 95 % del coeficiente estandarizado y de la correlación de estructura de cada predictor, y % de réplicas con el mismo signo que el modelo completo.
2. Tabla lado a lado: coeficientes estandarizados del LDA y de la logística (predictores estandarizados), con una marca donde el signo no coincida.
3. Coeficientes de M1 en los pliegues que validan 2022 y 2023 y en el modelo final.
4. QDA como técnica no exitosa:
   - QDA regularizada (klaR::rda, o MASS::qda solo con meteorología si la regularizada falla con las indicadoras) frente al LDA, con la misma partición. Reporta el AUC de cada uno.
   - Referencia de Opus en Python (no oficial): QDA regularizada 0.728–0.742 contra LDA 0.792; solo meteorología, 0.709 contra 0.718.
5. Calibración de M1 v2: deciles, intercepto y pendiente, como en 07c.

Salidas: output/etapa4/lda/estabilidad_coeficientes.csv, lda_vs_logistica.csv, coeficientes_por_pliegue.csv, qda_vs_lda.csv y una figura de los IC de los coeficientes (puntos con barras; resalta los de signo estable).

C2. scripts/09c_area_estudio_reubicaciones.R
1. % de superación y mediana de PM2.5 por estación y año (2021–2025), con un énfasis especial en SE2, SO y SUR.
2. Mediana mensual de PRS menos la mediana de la red (2020-10 a 2022-06) para NO, SE, SO, NTE, SUR, NE y CE (control). Figura.
3. Mapa de estaciones con altitud: reutiliza mapa_estaciones y agrega la altitud de data/metadata/estaciones.csv.

C3. Cierre
- Escribe output/etapa4/RESUMEN_ETAPA4.md con todas las cifras.
- Actualiza el README:
  - el orden de ejecución completo: 02 → 03 → 06 → 07a–c → 08a–d → 09a–c;
  - qué scripts necesitan los Excel y cuáles corren solo con data/clean;
  - el papel de cada lenguaje: R para todo el análisis; Python solo para la prueba de viabilidad y verificaciones, de las que ningún resultado del informe depende.
- Comprueba que, desde un clon limpio con renv::restore(), corren de 06 en adelante sin los Excel.
- Commit y push; abre un PR de analisis/etapa4 contra main SIN fusionarlo.

Al terminar la fase C, dame:
- la tabla puente;
- el resultado principal v2 con su IC;
- la tabla de estabilidad de coeficientes (solo los de signo estable);
- QDA frente a LDA;
- los % de superación por año de SE2, SO y SUR;
- la liga del PR;
- todo lo que no cuadre.
