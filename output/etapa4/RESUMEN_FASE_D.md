# Etapa 4 · Fase D: errores, supuestos, sensibilidades posteriores y descriptivos

Scripts:
- `scripts/09d_diagnostico_errores_v2.R`: errores y supuestos; salidas en `output/etapa4/errores/`.
- `scripts/09e_sensibilidades_posteriores.R`: salidas en `output/etapa4/sensibilidades_posteriores/`.
- `scripts/09f_viento_pm_no2.R`: salidas en `output/etapa4/descriptivos/`.

**Todo es posterior a la evaluación única de la prueba (09a).** Ningún resultado reemplaza el análisis final (ΔAUC = 0.079 [0.054, 0.104]). Las sensibilidades quedaron anotadas en `output/etapa4/registro_prueba_v2.txt`. Responde a la retroalimentación del 15 de octubre de 2026 (profesora y SIMA) y a los pendientes de las fases B y C.

## 1. Análisis de los errores (modelo congelado, prueba 2024–2025, corte 0.259)

**Matriz de confusión** (`errores/confusion_m0_m1.csv`):

| | VP | FN | FP | VN | Sensibilidad | Especificidad | Brier |
|---|---|---|---|---|---|---|---|
| M0 | 1,016 | 783 | 1,505 | 3,559 | 0.565 | 0.703 | 0.172 |
| M1 | 1,334 | 465 | 1,621 | 3,443 | 0.742 | 0.680 | 0.154 |

**Por temporada (M1):**

| Temporada | Sensibilidad | Especificidad |
|---|---|---|
| Seca-fría | 0.862 | 0.449 |
| Seca-cálida | 0.769 | 0.542 |
| Lluvias | 0.298 | 0.875 |

En lluvias M1 detecta menos que M0 (0.298 contra 0.364), igual que en la etapa 3. **Por año (M1):** 2024 tiene sensibilidad 0.751 y especificidad 0.682; 2025, 0.729 y 0.678.

**Según la magnitud del PM2.5** (% de días clasificados como superación):

| PM2.5 (µg/m³) | n | M0 | M1 |
|---|---|---|---|
| < 15 | 2,401 | 26.5 | 21.3 |
| 15–20 | 1,544 | 30.3 | 36.2 |
| 20–25 | 1,119 | 35.7 | 49.2 |
| 25–30 | 705 | 45.7 | 64.1 |
| 30–40 | 745 | 55.2 | 76.4 |
| > 40 | 349 | 81.1 | 89.7 |

- M1 mejora en los dos extremos: menos falsas alarmas en los días limpios y más detecciones en los episodios.
- Los errores se concentran cerca del umbral, donde unos pocos µg/m³ cambian la clase.

## 2. Supuestos del LDA (entrenamiento v2, n = 10,965; `errores/supuestos_*.csv`)

| Supuesto | Resultado | Lectura |
|---|---|---|
| Normalidad multivariada por clase (Mardia) | Asimetría χ² = 99,015 (clase 0) y 198,072 (clase 1), gl = 120; curtosis z = 346 y 1,236 | No se cumple. La lluvia es la más asimétrica (7.6 y 19.9) |
| Covarianzas iguales (M de Box) | χ² = 3,213, gl = 36, p < 0.001 | No se cumple. La diferencia está sobre todo en la lluvia (razón de DE clase 1 / clase 0 = 0.40) y en v (0.78); en las demás, 0.85–1.05 |
| Multicolinealidad | VIF máximo 2.28 (TOUT); número de condición 2.97 | Baja |

Como dijo la profesora, el LDA puede usarse aunque no se cumplan los supuestos, pero la interpretación no puede ser fina. Por eso:
- se usa como clasificador lineal;
- la logística da la misma conclusión (0.071 [0.047, 0.095]);
- la QDA, que no supone covarianzas iguales, no mejora (0.788 contra 0.792);
- solo se interpretan los signos estables (`lda/estabilidad_coeficientes.csv`).

## 3. ¿El modelo absorbe la autocorrelación?

ACF promedio entre estaciones de la respuesta y de los residuos, dentro de cada estación (`errores/acf_promedio_y_residuos.csv`; figura `errores/acf_respuesta_y_residuos.png`):

| Rezago (días) | Respuesta | Residuo de M0 | Residuo de M1 |
|---|---|---|---|
| 1 | 0.50 | 0.44 | 0.42 |
| 7 | 0.25 | 0.18 | 0.17 |
| 14 | 0.17 | 0.09 | 0.12 |

Correlación promedio entre estaciones el mismo día: respuesta 0.48, residuo de M0 0.42 y residuo de M1 0.36.

**El modelo absorbe solo una parte de la dependencia.** La meteorología del día explica algo de la correlación entre estaciones (0.48 → 0.36) y de la persistencia, pero el residuo sigue autocorrelacionado (0.42 a un día) y correlacionado entre estaciones. Por eso:
- los IC se calculan con bootstrap por bloques de 14 días que llevan todas las estaciones;
- los errores estándar usuales de los coeficientes no valen;
- se usa la estabilidad por bootstrap y no la significancia.

La persistencia (PM2.5 del día anterior) queda como extensión natural.

## 4. ¿Hay heterogeneidad de varianzas en los errores?

Error cuadrático observado (Brier) frente al esperado si las probabilidades fueran correctas, p(1 − p) (`errores/heterogeneidad_*.csv`):

- **Por temporada.** La razón observado/esperado es 1.09 en seca-fría, 1.16 en seca-cálida y 0.91 en lluvias: en las temporadas secas el modelo se equivoca más de lo que él mismo predice.
- **Por decil de p.**
  - En el decil más alto la razón es 1.34: el modelo es demasiado confiado cuando predice probabilidades altas (p media 0.79, frecuencia observada 0.70).
  - Es coherente con la pendiente de calibración de 0.82 (09b).
- **Por estación.**
  - Las razones van de 0.90 (SE2) a 1.49 (SO2). Después de SO2 siguen SE3 (1.17) y NTE2 (1.13).
  - En SO2, SE3 y NTE2 el modelo se equivoca más de lo que espera; SE2 y NO2 tienen menos error del esperado.

**Hay heterogeneidad que el modelo no recoge**, entre temporadas, estaciones y niveles de probabilidad. Es otra razón para no tomar las probabilidades al pie de la letra. Opciones para mejorarla: recalibración y cortes por estación.

## 5. Sensibilidades posteriores

Declaradas en el registro; `sensibilidades_posteriores/sensibilidades_posteriores.csv`.

| Análisis | n entrenamiento | n prueba | AUC M0 | AUC M1 | ΔAUC [IC 95 %] |
|---|---|---|---|---|---|
| Análisis final (09a) | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.104] |
| a) SR imputada truncada en 0 (341 valores en las filas del análisis) | 10,965 | 6,863 | 0.713 | 0.792 | 0.079 [0.054, 0.105] |
| b) Reubicaciones según SIMA (D23 solo para SUR, SE, NE y NO) | 11,365 | 6,863 | 0.710 | 0.791 | 0.081 [0.054, 0.107] |
| c) Sin NO2 | 9,971 | 6,325 | 0.715 | 0.797 | 0.082 [0.056, 0.108] |

- **SR negativa:** truncarla en 0 no cambia nada.
- **Lista de reubicaciones:** usar la de SIMA (que no incluye SO ni NTE) en lugar de la del PIGECA tampoco cambia la conclusión.
- **NO2:** quitarla (por el problema de su PM2.5, sección 7) sube un poco la ΔAUC.

## 6. Viento por estación (base v2, días con respuesta válida; `descriptivos/viento_por_estacion.csv`)

**Flujo predominante.**
- El flujo del este domina: u < 0 en el 80–98 % de los días en 11 de las 13 estaciones (SO 96 %, NTE 98 %, NE 97 %).
- Las excepciones son NE2 (62 %) y SO2 (68 %).
- La dirección resultante está entre 68° y 140° (del este al sureste). Es coherente con el comentario de SIMA: el viento sale del área metropolitana hacia el oeste, por Santa Catarina y García.

**SE2 (Juárez)** tiene el viento más débil de la red: 1.55 m/s de media, contra 2.0–2.8 en las demás.

**En los días con superación el viento es más débil en todas las estaciones** (SMD de la rapidez):

| Estación | SMD | Rapidez con / sin superación (m/s) | u con / sin superación |
|---|---|---|---|
| SO | −0.76 | 2.02 / 2.62 | −1.16 / −2.01 |
| NE | −0.69 | | |
| NO | −0.64 | | |
| CE | −0.55 | | |
| SE2 | −0.54 | 1.37 / 1.70 | |

Es casi nulo en NTE (−0.07) y NO2 (−0.13).

**Con promedios diarios no se distingue la acumulación del transporte.** En SO, los días con superación tienen un flujo del este más débil, no más fuerte. Si el transporte desde la ciudad fuera la causa principal, esperaríamos lo contrario, pero esto no se puede afirmar sin datos horarios.

## 7. Cociente PM2.5/PM10 por estación (`descriptivos/cociente_pm25_pm10_*.csv`)

- **Cociente mediano.** Va de 0.25 (SE3) a 0.42 (NO). SE2 (0.40) y SO (0.40) están entre los más altos: su PM2.5 es una fracción relativamente grande del PM10.
- **Correlación de Spearman entre PM2.5 y PM10.**
  - Es de 0.71–0.82 en 11 estaciones; la más alta es SE2 (0.82). NTE tiene 0.58 y NO2 0.39. Coincide con el comentario de SIMA de que en Juárez el PM2.5 va ligado al PM10.
  - Pero un cociente alto no sugiere que domine el polvo grueso (resuspensión). Es más compatible con fuentes de combustión (tráfico, quema, la pluma de la refinería) o con partículas secundarias. Es una lectura descriptiva, no una atribución.
- **En los días con superación el cociente es mayor en todas las estaciones** (por ejemplo, SE2 0.46 contra 0.35): los episodios son de partículas más finas.
- **NO2 es la excepción:** su cociente se desploma en algunos periodos (sección 8).

## 8. NO2 (García): problema probable del equipo de PM2.5 (`descriptivos/pm25_pm10_relativo_mensual.csv`)

Mediana mensual del PM2.5 de NO2 dividido entre la mediana de la red, y lo mismo con el PM10 (figura `descriptivos/no2_pm25_pm10_relativo.png`):

| Periodo | PM2.5 / red | PM10 / red | PM2.5/PM10 |
|---|---|---|---|
| Enero a mayo de 2021 | 0.48–0.62 | 0.87–1.00 | 0.16–0.27 |
| Junio de 2021 a junio de 2023 | 0.90–1.31 | 0.84–1.08 | 0.28–0.51 |
| Julio de 2023 a enero de 2025 | 0.37–0.68 | 0.81–1.21 | 0.13–0.22 (junio de 2024: 0.30, con 2 días) |
| Febrero a noviembre de 2025 | 1.00–1.37 | 1.02–1.37 | 0.29–0.54 |

- **En dos periodos el PM2.5 de NO2 baja a la mitad del de la red mientras su PM10 sigue en su nivel**: enero–mayo de 2021 y julio de 2023–enero de 2025. Con el mismo criterio, solo hay rachas de 3 a 5 meses en NTE, SE3 y CE (`descriptivos/periodos_pm25_bajo_con_pm10_normal.csv`), mucho más cortas.
- **Explica las 0 superaciones de NO2 en 2024.** No parece un cambio real del aire (el PM10 no baja), sino del equipo de PM2.5.
- **Afecta a la prueba**, pero quitar NO2 no cambia la conclusión (sección 5).
- **Hay que preguntarle a SIMA** qué pasó con el equipo de PM2.5 de García en esos periodos.

## 9. Boletín estatal (7 de marzo de 2024): enero 2023 frente a enero 2024 (`descriptivos/boletin_enero_2023_2024.csv`)

| Estación | Enero 2023 | Enero 2024 |
|---|---|---|
| SE2 (Juárez) | media 33.1 µg/m³, 19 días | 43.1 µg/m³, 30 días |
| SE3 (Cadereyta) | 22.4 µg/m³ | 22.4 µg/m³ |

- Coincide con lo que dijo SIMA: la pluma de la refinería «brinca» Cadereyta y llega a Juárez.
- La dirección también coincide con el boletín: de 32.6 a 47.2 µg/m³, con los promedios oficiales de enero.
- Enero de 2023 en SE2 tiene solo 19 días válidos.

## 10. Para el informe y para SIMA

- **Supuestos y errores (profesora).** No se cumplen normalidad ni covarianzas iguales. El modelo absorbe solo una parte de la autocorrelación y hay heterogeneidad entre temporadas y estaciones. Por eso: bootstrap por bloques, interpretación solo de signos estables, logística y QDA como contraste, y probabilidades tratadas como puntajes.
- **Preguntas para SIMA:**
  - qué pasó con el PM2.5 de NO2 en 2021 y en 2023–2025;
  - fechas de las reubicaciones (SIMA no mencionó SO ni NTE);
  - la radiación baja de NO2 y NTE;
  - zona horaria y unidad de la lluvia.
