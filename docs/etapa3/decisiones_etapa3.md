# Etapa 3: decisiones cerradas con validación progresiva (5 oct 2026; corregido)

Estas decisiones se tomaron **solo con 2021–2023**. Los años de prueba (2024–2025) no se tocaron. Los números vienen de un prototipo en Python (`scikit-learn` 1.8). El script de R `07_modelar_etapa3.R` debe reproducirlos (±0.002) antes de evaluar la prueba.

## 1. Validación progresiva: M0 frente a M1

Se usa la muestra datos-v1.2 (n = 10 170 en 2021–2023), con LDA y probabilidades a priori iguales a la prevalencia de entrenamiento. Los predictores se estandarizan con las medias y desviaciones del entrenamiento. El punto de corte es la prevalencia de entrenamiento.

| Modelo | AUC, valida 2022 (entrena 2021) | AUC, valida 2023 (entrena 2021–22) | Exactitud balanceada 2022 | Exactitud balanceada 2023 |
|---|---|---|---|---|
| M0 (estación + temporada) | 0.711 | 0.749 | 0.640 | 0.689 |
| M1 (M0 + 8 meteorológicas) | 0.777 | 0.829 | 0.704 | 0.734 |
| **ΔAUC (M1 − M0)** | **+0.066** | **+0.080** | +0.064 | +0.045 |
| M0 con interacción estación × temporada | 0.689 | 0.752 | 0.640 | 0.691 |
| M1 con interacción | 0.756 | 0.835 | 0.685 | 0.747 |
| Logística M0 / M1 | 0.717 / 0.771 | 0.752 / 0.828 | — | — |

**Lectura:**
- La mejora de M1 es consistente en los dos pliegues.
- La logística da prácticamente lo mismo que el LDA, así que la conclusión no depende de la técnica.
- Con un solo año de entrenamiento, la interacción empeora (celdas pequeñas; NTE tiene 132 días en seca-fría). Con dos años queda igual. Se mantiene como sensibilidad, no como modelo principal.

## 2. Transformaciones (D16)

AUC de M1 según la transformación aplicada:

| Variante | Valida 2022 | Valida 2023 |
|---|---|---|
| Sin transformar | 0.7767 | 0.8286 |
| log(1 + horas_lluvia) | 0.7774 | 0.8282 |
| `llovio` (0/1) en lugar de las horas | 0.7772 | 0.8277 |
| log de lluvia + log de rapidez del viento | 0.7802 | 0.8355 |

**D16: no se transforma ninguna variable.**
- El logaritmo del viento mejora el AUC en los dos pliegues, pero muy poco (+0.004 y +0.007). Es una ganancia sin importancia práctica frente a la ΔAUC de la meteorología (+0.07 a +0.08).
- El logaritmo del viento sobrecorrige: en el entrenamiento, su asimetría pasa de +0.37 a −0.98.
- Las variables sin transformar conservan las unidades de la etapa 2.
- El logaritmo del viento queda como sensibilidad.
- Esta regla se fija después de ver estos números de validación, no los de prueba, y así se declara.

## 3. Presión como anomalía de su estación (D17)

En M1, la presión cruda tiene el coeficiente estandarizado más grande (−1.00). Pero las variables indicadoras de estación lo compensan, porque la presión depende de la altitud. Por ejemplo, SE3 tiene coeficiente +0.40 y correlación de estructura −0.17, un efecto de supresión.

**D17:** usar `PRS_anom` = PRS − media de su estación **calculada solo con el entrenamiento**.
- Es una combinación lineal de PRS y de las indicadoras de estación, así que el ajuste y el AUC son idénticos.
- Solo cambia la interpretación: los coeficientes de estación dejan de compensar la altitud.
- En la prueba se usan las medias del entrenamiento, para que no haya fuga de información.

## 4. Supuestos del LDA (se reportan; no cambian el modelo)

- **Normalidad multivariada:** no se cumple.
  - La lluvia tiene asimetría de 7.2 (clase 0) y 21.1 (clase 1), con 94 % de días en cero en el entrenamiento.
  - Las variables indicadoras no son normales por definición.
  - Con predictores mixtos, el LDA funciona como clasificador lineal y no como modelo generativo exacto (Johnson & Wichern, 2007).
- **Covarianzas iguales:** la M de Box las rechaza (χ² = 3 651, gl = 36, p < 0.001). Con n = 10 170 rechaza casi cualquier diferencia.
  - Lo relevante es la magnitud: la razón de desviaciones estándar (clase 1 / clase 0) es 0.38 en lluvia y está entre 0.81 y 1.08 en las demás variables (rapidez del viento: 1.08). La heterogeneidad se concentra en la lluvia.
  - La logística no supone ni normalidad ni covarianzas iguales, y da el mismo AUC. Eso indica que la violación no cambia la conclusión.

## 5. PCA exploratorio (entrenamiento, variables meteorológicas estandarizadas)

| | Versión cruda | Versión anomalía por estación (preferida) |
|---|---|---|
| Valores propios > 1 | 3 (2.50, 1.37, 1.04) | 3 (2.92, 1.36, 1.04) |
| Varianza acumulada con 3 componentes | 61 % | 67 % |
| KMO | 0.64 | 0.65 |
| Bartlett | χ² = 15 402, gl = 28 | χ² = 24 798, gl = 28 |

Cargas de la versión con anomalías:
- **PC1 (36 %), «día cálido, soleado y ventilado»:** TOUT +0.84, SR +0.82, rapidez +0.67, PRS −0.61, *u* −0.64 (más flujo del este).
- **PC2 (17 %), «día húmedo y lluvioso»:** RH +0.67, lluvia +0.48, *v* +0.43, *u* −0.58.
- **PC3 (13 %), «presión baja y poco viento»:** PRS −0.63, rapidez −0.43, lluvia +0.34, TOUT +0.33, *u* +0.32, RH +0.32.

PC1 mezcla variables que empujan la superación en sentidos opuestos: la temperatura la favorece y el viento la reduce. Es una evidencia concreta de que maximizar la varianza no maximiza la separación, y justifica que el PCA sea exploratorio.

**Sensibilidad con PCs como predictores:** se fija k = 3 (criterio de Kaiser en el entrenamiento), con el PCA ajustado solo con 2021–2023.

## 6. Métricas secundarias que se agregan antes de abrir la prueba

- Puntaje de Brier, porque el AUC no mide la calibración.
- ΔAUC dentro de cada temporada (descriptivo, con su IC por bootstrap), para que SIMA sepa en qué época aporta más la meteorología.
- Sensibilidad con el logaritmo de la rapidez del viento (D16).

## Registro de correcciones

**5 oct 2026.** La reproducción en R (`scripts/07a_validacion_progresiva.R`) detectó dos errores en la primera versión de este documento:

1. **Variante equivocada en las secciones 4 y 5.** El prototipo de Python calculó los supuestos y el PCA con la lluvia en log(1 + x) y el viento en logaritmo, que es la variante que D16 rechaza. Ahora todo se reporta sin transformar, de forma coherente con el modelo. R y Python coinciden en esta versión. Cambia la heterogeneidad del viento (razón de DE de 1.08, no 1.37) y cambian algunas cargas. No cambia ninguna decisión: k = 3 por Kaiser se mantiene y la M de Box sigue rechazando.
2. **Cifras de la muestra completa.** La asimetría del viento (+0.49) y el porcentaje de días sin lluvia (92 %) venían de la muestra completa 2021–2025, que incluye la prueba. Son descriptivos que ya se publicaron en la etapa 2, no resultados de ningún modelo, pero aquí deben ser del entrenamiento: +0.37 y 94 %. Ninguna decisión se tomó con base en ellos.
