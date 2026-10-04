# Etapa 2 — Objetivo de indagación, ruta de análisis y exploración descriptiva

> **Borrador v1 (4 oct 2026).** Las cifras entre ⟦ ⟧ cambian con `datos-v1.2` (sección 3.3) y deben copiarse de `output/etapa2/` cuando se vuelva a correr `06_explorar_etapa2.R`. Las que no van entre corchetes no dependen de la nueva regla. Longitud objetivo: 5 páginas de cuerpo con Tabla 1, Figura 1, Figura 2 y referencias.

## 1. Objetivo de indagación

### 1.1 Por qué cambió

En la etapa 1 propusimos identificar regímenes multicontaminante con conglomerados. La retroalimentación fue que la pregunta era demasiado ambiciosa para tres semanas, y estamos de acuerdo: un análisis no supervisado exige muchas decisiones de diseño (número de grupos, distancia, variables) sin un criterio externo para validarlas. Reenfocamos el trabajo en un desenlace con significado sanitario y una respuesta medible. Conservamos la base limpia, la definición de temporadas y el periodo 2021–2025 de la etapa 1, y dejamos los regímenes como extensión futura.

El PM2.5 es el contaminante con mayor carga sanitaria por exposición de corto plazo (Orellano et al., 2020; World Health Organization [WHO], 2021). En la ZMM, el PM2.5 de 24 h supera con frecuencia los valores de referencia (Hernández-Romero et al., 2026).

### 1.2 Pregunta

¿En qué medida la meteorología del día mejora la clasificación retrospectiva de los días-estación con PM2.5 promedio de 24 h superior a 25 µg/m³, respecto de un modelo que solo considera la estación de monitoreo y la temporada, en 13 estaciones de la ZMM durante 2021–2025?

### 1.3 Objetivo general

Estimar y comparar, con validación temporal, el desempeño de dos modelos de análisis discriminante lineal (LDA):

- **M0:** estación + temporada.
- **M1:** M0 + ocho variables meteorológicas del mismo día.

La mejora atribuible a la meteorología se cuantifica con la diferencia de AUC (ΔAUC) y de exactitud balanceada, con intervalos de confianza por bootstrap.

### 1.4 Objetivos específicos

1. **(Etapa 2)** Describir cómo se distribuyen las superaciones por estación, temporada y año.
2. **(Etapa 2)** Describir en qué difieren las condiciones meteorológicas de los días con y sin superación, dentro de cada estación y temporada.
3. **(Etapa 3)** Estimar M0 y M1, cuantificar ΔAUC con su incertidumbre y verificar que la conclusión no dependa del LDA.

**Sobre el umbral.** 25 µg/m³ es el límite de 24 h en el quinto año de aplicación de la NOM-025-SSA1-2021. Lo usamos como **referencia fija** para comparar todo el periodo; **no** evaluamos el cumplimiento normativo histórico, porque los límites aplicables cambiaron entre 2021 y 2025. El resultado describe **concentraciones** y no un riesgo individual: estar por debajo de 25 µg/m³ no equivale a ausencia de riesgo (WHO, 2021).

## 2. Ruta de análisis

El análisis sigue un protocolo escrito **antes** de ajustar los modelos (repositorio, `docs/etapa2/protocolo.md`). En él quedan fijas la partición, las métricas y las sensibilidades, para evitar elegir el análisis según el resultado. La Tabla 1 resume la ruta.

**Tabla 1.** Ruta de análisis: técnica, rol y justificación.

| Etapa | Técnica | Variables | Rol | Justificación |
|---|---|---|---|---|
| 2 | Proporciones de superación; diferencias de medias estandarizadas (SMD); correlación de Spearman | `supera_25`, estación, temporada, año; 8 meteorológicas | Describir el desenlace y anticipar qué variables separan las clases | El SMD no depende de *n* ni de las unidades y es comparable entre variables (Austin, 2009). Spearman es robusto a la asimetría |
| 3 | Análisis de componentes principales (PCA) | 8 meteorológicas, estandarizadas | Exploratorio: describir la estructura de correlación de la meteorología | Hay colinealidad (Sección 4.3). Maximizar la varianza no garantiza separar las clases, por eso los componentes no son predictores del modelo principal |
| 3 | LDA (M0 y M1) | Respuesta: `supera_25`. Predictores: estación y temporada (indicadoras) + 8 meteorológicas | Técnica principal: clasificar y comparar M0 contra M1 | Produce una combinación lineal interpretable. Es un precedente en estudios de calidad del aire con varias estaciones (Mohd Shafi'i & Juahir, 2024). Sus supuestos se revisan y se reportan (Johnson & Wichern, 2007) |
| 3 | Regresión logística | Las mismas | Solo robustez | Verifica que la conclusión no dependa del LDA |
| 3 | Validación temporal y bootstrap por bloques de 14 días | Años 2021–2025 | Estimar el desempeño fuera de muestra y su incertidumbre | Entrenamiento 2021–2023 y prueba 2024–2025, usada una sola vez. Los bloques conservan juntas las estaciones porque un episodio afecta a varias a la vez |

**Rol de las variables.**

- **Respuesta:** `supera_25` = 1 si el PM2.5 promedio diario es mayor de 25 µg/m³.
- **Predictores de referencia (M0):**
  - estación (13 categorías);
  - temporada: seca-fría (nov–feb), seca-cálida (mar–may) y cálida-húmeda (jun–oct).
- **Predictores meteorológicos (M1):**
  - temperatura (TOUT), humedad relativa (RH), radiación solar (SR) y presión (PRS);
  - viento como componentes zonal (*u*) y meridional (*v*) y como rapidez, en m/s;
  - horas con lluvia en el día.
- **Variables auxiliares:**
  - año, para la partición;
  - `supera_15` (guía de la OMS), para sensibilidad;
  - horas válidas por variable, para el control de calidad.
- **Excluidas a propósito:**
  - **Otros contaminantes:** comparten fuentes con el PM2.5 y en parte son co-desenlaces, no condiciones externas.
  - **Dirección del viento en grados:** es circular; la sustituyen *u* y *v*.
  - **Lluvia en mm:** su unidad no está confirmada; solo usamos horas con lluvia.

## 3. Datos

### 3.1 Muestra

La unidad es el **estación-día**. La muestra parte de la base `datos-v1.2` (etapa 1, más la regla de la Sección 3.3) y exige:

- PM2.5 diario válido, con al menos 18 h (criterio de suficiencia de SIMA);
- los ocho predictores meteorológicos completos, cada uno con al menos 18 h.

NE3 y NO3 se excluyen porque casi no miden PM2.5. De 23 738 estación-días posibles (13 estaciones × 2021–2025) quedan ⟦15 388 (64.8 %)⟧ [Anexo A, tabla de pérdidas]:

- 3 820 días se pierden por PM2.5 insuficiente;
- ⟦≈ 5 700⟧ por meteorología incompleta o inválida;
- 1 181 días fallan los dos requisitos y se cuentan en ambos grupos.

### 3.2 La estación, explícitamente

La estación entra como variable categórica en M0 y en M1. Así absorbe las diferencias persistentes entre sitios: cercanía a fuentes industriales y viales, topografía y altitud. Esto tiene tres consecuencias:

- **PRS no es comparable entre estaciones sin controlar la estación.** Su promedio va de 701 mm Hg (NO2, SO) a 731 mm Hg (SE3) por la altitud de cada sitio. Por eso la meteorología se describe también como anomalía respecto de la media de su estación y temporada (Sección 4.2).
- **Las estaciones no pesan igual.** La retención va de ⟦28 % (NO2)⟧ a 95.5 % (NTE2): NTE aporta 597 días y NTE2, 1 743. Los resultados describen esta muestra, no la ZMM en su conjunto.
- **Los faltantes no son aleatorios** en el tiempo: las fallas de sensores se concentran en periodos y estaciones concretos. Esto se reporta como limitación.

### 3.3 Hallazgo de calidad durante la exploración y regla nueva

Al revisar la distribución de los predictores aparecieron valores físicamente imposibles que las reglas de la etapa 1 no detectaban:

- **Viento:** promedios diarios de hasta 33 m/s (≈ 119 km/h) en SO2 (junio–octubre de 2021) y en NE2 (noviembre–diciembre de 2021). Hubo horas cercanas a 179 km/h mientras la mediana horaria de la red rondaba 10 km/h.
- **Radiación solar:** valores distintos de cero de noche. Entre las 00 y las 04 h llegaban hasta 0.73 kW/m², sobre todo en NO2 (2022–2023 y 2025), SE3 y CE. La regla de rachas de la etapa 1 excluía a SR a propósito, porque los ceros nocturnos son reales, y por eso no los detectó.

El perfil horario de SR en las estaciones sanas (cero entre las 21 y las 05 h, puesta de sol cerca de las 20 h en junio) confirma además que las marcas de tiempo están en hora local.

Agregamos dos pruebas de consistencia, en la línea de los procedimientos para estaciones automáticas (Estévez et al., 2011; Fiebrich et al., 2010):

1. **Radiación nocturna:** si el promedio de SR entre las 00 y las 04 h es mayor de 0.02 kW/m², se invalida SR en todo ese día.
2. **Viento frente a la red:** si la rapidez supera en más de 30 km/h a la mediana de la red en la misma hora (con al menos 5 estaciones reportando), la hora se marca. Con 3 o más horas marcadas se invalida el viento de todo el día.

Las horas invalidadas no se imputan. Los umbrales son una decisión del equipo, apoyada en la distribución observada:

- entre los percentiles 90 y 95, el promedio nocturno de SR salta de 0.002 a 0.036 kW/m²;
- con un umbral de 0.01 kW/m² se excluirían 988 días en lugar de 933;
- después de la regla, el viento diario máximo es ⟦7.2 m/s⟧.

En total se retiran ⟦1 073⟧ días.

**Sensibilidad a la imputación de la etapa 1** (huecos ≤ 3 h). Recalculamos el PM2.5 diario solo con horas observadas:

- el ⟦2.7 %⟧ de los días deja de ser evaluable por tener menos de 18 h;
- de los días comparables, el ⟦0.6 %⟧ cambia de clase.

La imputación no altera la variable respuesta de forma apreciable.

## 4. Exploración descriptiva

### 4.1 ¿Cómo se distribuyen las superaciones? (objetivo específico 1)

El ⟦26.3 %⟧ de los estación-días supera 25 µg/m³. La mediana del PM2.5 diario es ⟦18.3⟧ µg/m³ y la distribución es asimétrica a la derecha (asimetría ⟦1.9⟧), con episodios de hasta ⟦166⟧ µg/m³ (Anexo A, distribución por estación).

La Figura 1 cruza estación y temporada:

- **Temporada:** la superación es mucho más frecuente en las temporadas secas (⟦37.7 %⟧ en seca-fría y ⟦35.5 %⟧ en seca-cálida) que en la cálida-húmeda (⟦12.5 %⟧). Esto es coherente con los vientos débiles y la menor altura de mezcla que se han asociado a la época fría en la ZMM (Martínez-Cinco et al., 2016).
- **Estación:** el gradiente es amplio. SE2 y SO superan en casi la mitad de sus días; SUR, en menos del 10 %.
- **Interacción:** el patrón estacional no es igual en todas las estaciones.
  - SO llega a 75 % en seca-fría y baja a 42 % en seca-cálida.
  - CE alcanza su máximo en seca-cálida (57 %).
  - NTE casi no cambia entre temporadas (17–23 %).
- **Año:** entre años la proporción varía poco (⟦23.8–30.0 %⟧; Anexo A), sin tendencia clara.

**Interpretación para el objetivo.** Estación y temporada, por sí solas, ya separan buena parte de los días con superación. Por eso M0 es una referencia exigente y cualquier aporte de la meteorología se mide sobre ese piso. La interacción estación × temporada implica que un M0 aditivo podría subestimar la referencia. Proponemos registrarla como sensibilidad antes de ajustar los modelos (Sección 5).

![](../output/etapa2/figuras/fig2_heatmap_superacion_estacion_temporada.png)

**Figura 1.** Porcentaje de estación-días con PM2.5 > 25 µg/m³ por estación y temporada, 2021–2025 (*n* por celda entre paréntesis). Elaboración propia con datos de SIMA.

### 4.2 ¿En qué difiere la meteorología de los días con superación? (objetivo específico 2)

La Figura 2 compara la meteorología de los días con y sin superación mediante el SMD. Se presenta de tres formas:

- **global:** toda la muestra junta;
- **dentro de cada temporada;**
- **como anomalía:** cada valor menos la media de su estación y temporada.

La tercera forma es la que corresponde a la pregunta, porque mide lo que la meteorología añade cuando estación y temporada ya se conocen.

Hallazgos principales:

- **Temperatura (efecto de confusión por temporada).** En el global, TOUT casi no difiere entre clases (SMD ⟦−0.04⟧). Dentro de cada temporada, en cambio, los días con superación son más cálidos (⟦0.23 a 0.84⟧), y como anomalía el SMD es ⟦0.50⟧. El efecto se anula al agrupar porque la superación es más frecuente en la temporada fría. Es un caso de la paradoja de Simpson: correlaciones agrupadas débiles (|ρ| ≤ ⟦0.27⟧ con PM2.5; Anexo A) no implican que la meteorología no aporte.
- **Viento.** Los días con superación tienen menos viento: ⟦−0.55⟧ global y ⟦−0.35⟧ como anomalía, con el efecto más fuerte en seca-fría (⟦−0.75⟧). También tienen menos flujo del este (*u* ⟦+0.33⟧). Es consistente con una menor ventilación.
- **Presión.** Tiene el mayor contraste como anomalía (⟦−0.59⟧): los días con superación tienen una presión más baja de lo normal para su estación y temporada. Junto con la temperatura más alta, esto sugiere condiciones previas al paso de frentes, pero es una **hipótesis** que no podemos verificar con estos datos.
- **Lluvia.** Hay menos horas con lluvia en los días con superación (⟦−0.26⟧).
- **Humedad, radiación y viento meridional.** Casi no separan las clases (|SMD| ≤ ⟦0.16⟧ como anomalía).

**Interpretación para el objetivo.** Hay señal meteorológica condicional a estación y temporada, pero de magnitud moderada (|SMD| ≤ 0.6), con gran traslape entre clases. Por eso esperamos una mejora de M1 sobre M0 real pero acotada. Una ΔAUC pequeña sería un resultado válido e informativo para SIMA.

![](../output/etapa2/figuras/fig3_smd_meteo.png)

**Figura 2.** Diferencia de medias estandarizada (días con superación menos días sin superación) de cada variable meteorológica: global, dentro de cada temporada y como anomalía respecto de la media de su estación y temporada. Las líneas punteadas marcan ±0.2. Elaboración propia con datos de SIMA.

### 4.3 Implicaciones para el modelado

- **Colinealidad.** Varios predictores están correlacionados: *u* con la rapidez (ρ = −0.60) y TOUT con SR (ρ = 0.51). Por eso los coeficientes del LDA se interpretarán en conjunto, y el PCA servirá para nombrar los ejes meteorológicos.
- **Asimetría.** Las horas con lluvia (⟦92 %⟧ de días con cero) y la rapidez del viento tienen distribuciones muy asimétricas. Eso afecta el supuesto de normalidad del LDA. Las transformaciones se decidirán solo con la validación progresiva dentro de 2021–2023.

## 5. Síntesis

**¿Qué se descubrió?**

- La superación de 25 µg/m³ es frecuente (⟦26 %⟧ de los estación-días).
- Depende sobre todo de la temporada y de la estación, con interacción entre ambas.
- Dentro de cada estación y temporada, los días con superación son más cálidos, con presión más baja, menos viento y menos lluvia.
- La exploración también detectó dos fallas de sensores (viento y radiación) que obligaron a una nueva regla de limpieza.

**¿Cómo se ligan los resultados al objetivo?**

- Que estación y temporada separen tanto valida a M0 como referencia exigente.
- Que haya diferencias meteorológicas condicionales (Figura 2) indica que M1 tiene información adicional que aportar.
- La magnitud de esas diferencias anticipa que la mejora será moderada.

**Limitaciones**

- **Muestra no aleatoria:** retención desigual por estación y faltantes concentrados en ciertos periodos.
- **Umbral:** 25 µg/m³ es una referencia fija, no una evaluación normativa.
- **Meteorología del mismo día:** permite asociar, no anticipar.
- **Dependencia:** los días y las estaciones están correlacionados en el tiempo y el espacio.
- **Variables ausentes:** no hay altura de la capa de mezcla, que es clave para la dispersión.
- **Pendientes de confirmar con SIMA:** la unidad de la lluvia.

**Análisis pendientes (etapa 3)**

1. PCA exploratorio de la meteorología.
2. M0 y M1 con LDA y validación progresiva.
3. ΔAUC con bootstrap por bloques (sensibilidad con 7 y 28 días).
4. Logística como robustez.
5. Revisión de supuestos.
6. Sensibilidades:
   - umbral de 15 µg/m³;
   - PM2.5 solo con horas observadas;
   - componentes principales como predictores;
   - **nueva:** M0 y M1 con interacción estación × temporada, que se registrará en el protocolo antes de ajustar.

**Camino a seguir**

- **Etapa 3 (15 oct):** modelos y validación.
- **Exposición (22 oct):** una aplicación sencilla para explorar los resultados por estación y temporada.

**Nuevas preguntas**

- ¿El patrón de presión baja y temperatura alta corresponde a situaciones previas a frentes?
- ¿Cuánto añade el PM2.5 del día anterior (persistencia)?
- ¿Se conserva la mejora con meteorología pronosticada, que permitiría una alerta real?
- ¿Hay grupos de estaciones con sensibilidad meteorológica parecida?

**Repositorio y reproducibilidad.** https://github.com/Leo-issacs/reto-sima-multivariados. La sección «Cómo reproducir» del README indica el orden de los scripts 02 a 06; el protocolo está en `docs/etapa2/`.

**Uso de IA.** Usamos asistentes de IA (Claude y Codex) para revisar código, proponer pruebas de calidad y editar la redacción. Las decisiones, la verificación de cifras y la interpretación son del equipo (detalle en el Anexo B).

## Referencias

Austin, P. C. (2009). Balance diagnostics for comparing the distribution of baseline covariates between treatment groups in propensity-score matched samples. *Statistics in Medicine, 28*(25), 3083–3107. https://doi.org/10.1002/sim.3697

Estévez, J., Gavilán, P., & Giráldez, J. V. (2011). Guidelines on validation procedures for meteorological data from automatic weather stations. *Journal of Hydrology, 402*(1–2), 144–154. https://www.sciencedirect.com/science/article/pii/S0022169411001594

Fiebrich, C. A., Morgan, C. R., McCombs, A. G., Hall, P. K., & McPherson, R. A. (2010). Quality assurance procedures for mesoscale meteorological data. *Journal of Atmospheric and Oceanic Technology, 27*(10), 1565–1582. https://doi.org/10.1175/2010JTECHA1433.1

Hernández-Romero, K., Hernández-Romero, I. M., Mendoza, A., Pérez-Rodríguez, M., Barajas-Villarruel, L. R., Medellín-Carrillo, S., & González, L. T. (2026). Persistent air pollution regimes and regulatory exceedances of PM10, PM2.5, and O3 in the Monterrey Metropolitan Area, Mexico. *City and Environment Interactions, 31*, 100410. https://doi.org/10.1016/j.cacint.2026.100410

Johnson, R. A., & Wichern, D. W. (2007). *Applied multivariate statistical analysis* (6th ed.). Pearson.

Martínez-Cinco, M. A., Santos-Guzmán, J., & Mejía-Velázquez, G. M. (2016). Source apportionment of PM2.5 for supporting control strategies in the Monterrey Metropolitan Area, Mexico. *Journal of the Air & Waste Management Association, 66*(6), 631–642. https://doi.org/10.1080/10962247.2016.1159259

Mohd Shafi'i, M. S., & Juahir, H. (2024). Assessment of spatial air quality on the East Coast of Peninsular Malaysia utilizing environmetric techniques. *Environmental Monitoring and Assessment, 196*(7), 640. https://doi.org/10.1007/s10661-024-12787-9

Orellano, P., Reynoso, J., Quaranta, N., Bardach, A., & Ciapponi, A. (2020). Short-term exposure to particulate matter (PM10 and PM2.5), nitrogen dioxide (NO2), and ozone (O3) and all-cause and cause-specific mortality: Systematic review and meta-analysis. *Environment International, 142*, 105876. https://doi.org/10.1016/j.envint.2020.105876

Secretaría de Salud. (2021, 27 de octubre). NOM-025-SSA1-2021, Salud ambiental. Criterio para evaluar la calidad del aire ambiente, con respecto a las partículas suspendidas PM10 y PM2.5. *Diario Oficial de la Federación*.

World Health Organization. (2021). *WHO global air quality guidelines: Particulate matter (PM2.5 and PM10), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide*. https://www.who.int/publications/i/item/9789240034228

---

## Anexo A. Tablas y figuras complementarias

- **A1.** Pérdidas de la muestra por requisito (`perdidas_muestra.csv`) y retención por estación.
- **A2.** PM2.5 diario por estación (diagrama de caja, escala logarítmica, con líneas en 15 y 25 µg/m³).
- **A3.** Porcentaje mensual de superación por año.
- **A4.** Matriz de correlación de Spearman.
- **A5.** Descriptivos de PM2.5 y de los ocho predictores (*n*, media, DE, cuartiles, asimetría).
- **A6.** Días retirados por la regla de la Sección 3.3, por estación.

## Anexo B. Declaratoria de uso de IA

[Mismo formato que en la etapa 1. Debe precisar qué hizo cada herramienta: Claude para la revisión de diseño, la literatura y la edición; Claude Code para implementar los scripts; Codex para la revisión independiente de cada PR. También debe precisar qué verificó el equipo.]
