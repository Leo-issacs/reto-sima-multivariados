# Guion de la exposición (≤ 5 minutos)

Unas 560 palabras habladas: entre 4:15 y 4:30 a ritmo tranquilo. El rol C avisa en el minuto 4.

---

## Portada (≈ 10 s)

Buenos días. Somos el equipo 1. Nuestro proyecto se llama «¿Cuánto ayuda la meteorología del día a identificar los días de PM2.5 alto en Monterrey?».

## Diapositiva 1 — Qué queremos hacer y con qué datos (≈ 1:10)

El PM2.5 tiene evidencia sólida de efectos en la salud por exposición de pocos días. Nuestra pregunta es concreta: **¿cuánto mejora la meteorología del día la identificación de los días en que una estación supera 25 microgramos por metro cúbico**, comparado con solo saber qué estación es y en qué temporada estamos? Usamos 25 porque es el límite de 24 horas de la NOM-025 en su etapa final; lo tomamos como referencia fija, no como evaluación normativa.

Trabajamos con 13 estaciones, de 2021 a 2025, con el PM2.5 y ocho variables meteorológicas. En los archivos originales faltaba el 12 % de los valores horarios, y en PM2.5 el 26 %. Invalidamos menos del 1 % por lecturas inconsistentes e imputamos el 1 %, solo en huecos de hasta 3 horas. Nos quedaron 15 390 estación-días. En el mapa se ve que la superación va de 9 % en SUR a casi 48 % en Juárez.

## Diapositiva 2 — Cómo lo analizamos y qué encontramos (≈ 1:40)

Usamos dos técnicas multivariadas. **Componentes principales**, para entender la estructura del clima: ocho variables se resumen en tres ejes que explican el 67 % de la variación. Y **análisis discriminante lineal**, para comparar dos modelos: M0, que solo sabe la estación y la temporada, y M1, que además conoce el clima del día.

Entrenamos con 2021 a 2023 y probamos con 2024 y 2025. Las decisiones del modelo quedaron registradas antes de la evaluación final.

El resultado: el AUC sube de **0.72 a 0.79**, una mejora de 0.07 con intervalo de confianza de 0.05 a 0.09. En términos prácticos, el modelo con clima detecta el **73 %** de los días con superación, contra el 58 % del modelo sin clima, y el **89 % de los episodios mayores de 40**.

La mejora es mayor de **marzo a mayo** y no es concluyente en temporada de lluvias. Lo que más pesa es la **presión más baja de lo normal**, la **temperatura** dentro de cada temporada y el **viento débil**. Son asociaciones, no causas comprobadas.

## Diapositiva 3 — Problemas, valor para SIMA y qué sigue (≈ 1:30)

Encontramos tres problemas:
- **Lecturas imposibles:** viento de más de 100 kilómetros por hora y radiación solar de noche en algunas estaciones; agregamos reglas para detectarlas.
- **Cambios de equipos y de ubicación:** sensores de viento en 2021, cinco equipos de PM2.5 en 2025 y seis estaciones reubicadas entre 2021 y 2022; los revisamos y no alteran la conclusión.
- **Retención desigual:** algunas estaciones conservan pocos días.

Ya tenemos una **interfaz** donde se elige estación, temporada y clima, y da la probabilidad de superación.

**¿Qué le sirve esto a SIMA?** Tres cosas: la meteorología del día sí ayuda, sobre todo de marzo a mayo, y eso justifica probar una alerta con pronóstico; dos reglas de control de calidad que detectaron sensores con fallas y que pueden incorporar; y una base limpia con todo el código abierto.

**Lo que sigue:** en la etapa 4, recalibrar las probabilidades, definir un corte por estación e incorporar lo que nos respondan hoy. Después, probar el modelo con meteorología pronosticada, que es lo que lo convertiría en una alerta real.

## Cierre (≈ 15 s)

Nos ayudaría mucho saber dos cosas: las fechas y coordenadas exactas de los cambios de sensores y de las seis reubicaciones, y si les serviría una alerta basada en pronóstico. Gracias.

---

## Preguntas de respaldo (no se leen; solo si sobra tiempo o en la sesión de preguntas)

- ¿Las horas están en tiempo local? ¿En qué unidad está la lluvia?
- ¿Qué fuentes cercanas explican que Juárez y Santa Catarina superen tanto?
- ¿Conocían las lecturas de viento de SO2 y NE2 en 2021 y la radiación nocturna de NO2, SE3 y CE?

## Quién contesta qué

| Tema | Contesta |
|---|---|
| Limpieza, datos, modelo, AUC, cambios de equipos | Leo |
| Juárez, Santa Catarina, fuentes y PIGECA | Rol de contexto (ChatGPT) |
| «¿Sirve para pronosticar?» | Quien expone: «Todavía no; usa clima observado. Probarlo con pronóstico es el siguiente paso». |

## Reglas para el expositor

- No leas la diapositiva: la diapositiva tiene las cifras y tú cuentas la historia.
- Si te preguntan algo, presenta al compañero: «Eso lo trabajó [nombre]».
- Di «se asocia», no «causa». Di «identifica» o «clasifica», no «predice».
