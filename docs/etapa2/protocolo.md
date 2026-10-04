# Protocolo de análisis — Reto SIMA (versión 2, 4 de octubre de 2026)

Este protocolo se fija **antes** de ajustar los modelos definitivos. Cualquier cambio posterior se registra al final con su fecha y su razón.

## 1. Pregunta

¿En qué medida la meteorología del día mejora la clasificación retrospectiva de los días-estación con PM2.5 promedio de 24 h superior a 25 µg/m³, respecto de un modelo que solo considera la estación de monitoreo y la temporada, en 13 estaciones de la ZMM durante 2021–2025?

**Subpreguntas descriptivas (etapa 2):**

1. ¿Cómo se distribuyen las superaciones por estación, temporada y año?
2. ¿En qué difieren las condiciones meteorológicas de los días con y sin superación?

## 2. Objetivo general

Estimar y comparar, con validación temporal, el desempeño de dos modelos de análisis discriminante lineal:

- **M0:** estación + temporada.
- **M1:** M0 + meteorología del mismo día.

La mejora atribuible a la meteorología se cuantifica con la diferencia de AUC (ΔAUC) y de exactitud balanceada, con intervalos de confianza por bootstrap.

## 3. Definiciones fijas

- **Unidad:** estación-día.
- **Muestra:** 2021–2025; 13 estaciones (sin NE3 ni NO3, que casi no miden PM2.5); PM2.5 diario válido (≥ 18 h) y meteorología completa. Son 16 461 estación-días de 23 738 posibles.
- **Respuesta:** `supera_25` = 1 si PM2.5 > 25 µg/m³.
  - 25 µg/m³ es el valor del quinto año de aplicación de la NOM-025-SSA1-2021.
  - Se usa como **referencia fija para comparar todo el periodo**. **No** es una evaluación del cumplimiento normativo histórico: en 2021–2025 los límites aplicables cambiaron (norma anterior de 2014 y gradualidad de la de 2021), y la evaluación normativa tiene reglas propias de suficiencia, redondeo y percentil.
  - El resultado es **ambiental** (concentraciones), no un riesgo individual de salud. Estar por debajo de 25 no equivale a ausencia de riesgo.
- **Predictores de M1:** TOUT, RH, SR, PRS, viento_rapidez_ms, viento_u, viento_v y horas_lluvia.
- **Estación y temporada:** variables indicadoras (dummies) con categoría de referencia.
- **Partición temporal:**
  - Entrenamiento 2021–2023.
  - Prueba 2024–2025, que se evalúa **una sola vez**.
  - Las decisiones del modelo (por ejemplo, transformaciones) se toman solo con validación progresiva dentro del entrenamiento:
    1. entrenar con 2021 y validar con 2022;
    2. entrenar con 2021–2022 y validar con 2023.
  - Después se cierran las decisiones, se reentrena con 2021–2023 y se evalúa 2024–2025.
- **Preprocesamiento:** escalado y, si se usa, PCA se ajustan solo con entrenamiento y se aplican a prueba con esos mismos parámetros.

## 4. Métricas

- **Principal:** AUC en prueba de M0 y M1 (ambos con análisis discriminante) y ΔAUC = AUC(M1) − AUC(M0).
- **Intervalo de confianza de ΔAUC (95 %):** bootstrap pareado por bloques de fechas consecutivas.
  - El periodo de prueba se divide en bloques no traslapados de 14 días. Cada bloque lleva juntas todas las estaciones disponibles en esas fechas.
  - Se remuestrean bloques con reemplazo (1 000 réplicas) y en cada réplica se calcula el AUC de M0 y de M1 sobre exactamente las mismas observaciones.
  - **Por qué 14 días:** los episodios de partículas en la ZMM pueden durar más de una semana en la temporada seca-fría (Hernández-Romero et al., 2026), y varias estaciones registran el mismo episodio. Como sensibilidad se reportan bloques de 7 y 28 días.
- **Secundarias:** exactitud balanceada, sensibilidad y especificidad. El punto de corte es una probabilidad posterior igual a la prevalencia de entrenamiento.
- **Lectura correcta:**
  - Un AUC de 0.79 **no** significa 79 % de aciertos, ni que las probabilidades estén calibradas.
  - Una mejora pequeña frente a M0 es un resultado válido.
  - El ensayo de viabilidad comparó una M0 logística con una M1 discriminante. La pareja definitiva M0–M1 con discriminante **aún no está evaluada**.

## 5. Papel de cada técnica

- **PCA (exploratorio):** describir la estructura de correlación de la meteorología y nombrar sus ejes principales. Los componentes no se usan como predictores del modelo principal: maximizar la varianza no garantiza maximizar la separación entre clases. Su uso como predictores queda solo como sensibilidad.
- **Análisis discriminante lineal:** técnica principal, para M0 y M1. Estima la combinación lineal de predictores que mejor separa los días con y sin superación.
  - Los supuestos (normalidad y covarianzas iguales) se revisan y se reportan.
  - Con variables indicadoras, el LDA funciona como clasificador lineal, no como modelo generativo exacto.
  - **Interpretación:** los coeficientes estandarizados se interpretan **en conjunto**. Con predictores correlacionados no constituyen una clasificación automática de importancia ambiental.
- **Regresión logística:** solo comprobación de robustez. Repetir M0 frente a M1 con la misma partición y métricas, para verificar que la conclusión no depende del discriminante. No se usa para elegir modelos ni para pruebas de razón de verosimilitud, cuyos supuestos de independencia no se cumplen con días y estaciones dependientes.

## 6. Sensibilidades (se reportan, no se usan para escoger)

1. Umbral de 15 µg/m³ (guía de la OMS para 24 h).
2. Imputación: recalcular el PM2.5 diario solo con horas **observadas**, exigiendo de nuevo al menos 18 horas válidas. Se reportan por separado:
   - los días comparables que cambian de clase;
   - los días que dejan de ser evaluables por cobertura insuficiente.
3. Componentes principales de la meteorología en lugar de las variables originales.

## 7. Extensiones futuras (fuera del alcance de las 3 semanas)

- PM2.5 del día calendario previo, como persistencia. En el ensayo se usó la fila previa disponible: en 481 registros de prueba no correspondía al día anterior, así que su AUC de 0.882 es solo un antecedente exploratorio.
- Meteorología pronosticada, para una alerta real.
- PM10, O3 y las categorías del Índice Aire y Salud.
- Impacto sanitario con AirQ+.
- Regímenes multicontaminante.

## 8. Antecedente declarado

El 4 de octubre se realizó una prueba de viabilidad que usó 2024–2025: `docs/etapa2/prueba_viabilidad_2026-10-04.py`. Codex la reprodujo (AUC 0.718 / 0.790 / 0.781 / 0.882). Se documenta como exploración preliminar. Desde este protocolo no se ajusta ninguna decisión del modelo con base en esos años.

## 9. Alcance de las conclusiones

- Los resultados son **asociaciones retrospectivas**: la meteorología del mismo día no permite anticipar.
- Para SIMA, una mejora de M1 sobre M0 es **evidencia preliminar** para valorar investigaciones posteriores, por ejemplo con meteorología pronosticada. Por sí sola no justifica invertir en un sistema operativo.
- El 26.6 % de superación describe la **muestra seleccionada**, no todos los días de la ZMM.

## Registro de cambios

- v1 (4 oct 2026): versión inicial.
- v2 (4 oct 2026): incorpora las observaciones de la revisión de Codex:
  - validación progresiva en lugar de dejar un año fuera;
  - bootstrap pareado por bloques de fechas que conservan juntas las estaciones;
  - logística solo como robustez, sin prueba de razón de verosimilitud;
  - sensibilidad de imputación con ≥ 18 horas observadas;
  - interpretación conjunta de los coeficientes;
  - alcance mesurado de la utilidad para SIMA;
  - nota normativa corregida;
  - limitación de la "fila previa".
  
  Pendiente: reproducir la pareja M0–M1 con discriminante.
