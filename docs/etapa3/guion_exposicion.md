# Guion de la exposición (≤ 5 minutos)

Unas 620 palabras, que a ritmo tranquilo dan entre 4:30 y 4:50. Los tiempos son una referencia; el rol C avisa en el minuto 4.

---

## Portada (≈ 15 s)

Buenos días. Somos el equipo 1. Nuestro proyecto se llama «¿Cuánto ayuda el clima a identificar los días de PM2.5 alto en Monterrey?». Trabajamos con los datos horarios de SIMA de 2020 a 2025.

## Diapositiva 1 — Qué queremos hacer y con qué datos (≈ 1:20)

El PM2.5 tiene evidencia sólida de efectos en la salud por exposición de pocos días. Nuestra pregunta es concreta: **¿cuánto mejora la meteorología del día la identificación de los días en que una estación supera 25 microgramos por metro cúbico**, comparado con solo saber qué estación es y en qué temporada estamos? Usamos 25 porque es el límite de 24 horas de la NOM-025 en su etapa final.

Trabajamos con 13 estaciones, de 2021 a 2025, con el PM2.5 y ocho variables meteorológicas. La unidad es el estación-día.

Sobre la limpieza:
- en los archivos originales faltaba el 12 % de los valores horarios, y en PM2.5 el 26 %;
- invalidamos menos del 1 % por lecturas inconsistentes, como radiación solar de noche o un viento muy distinto al del resto de la red;
- imputamos 1 %, solo en huecos de hasta 3 horas.

Al final nos quedaron 15 390 estación-días. En el mapa se ve que el porcentaje de días con superación va de 9 % en SUR a casi 48 % en Juárez.

## Diapositiva 2 — Cómo lo analizamos y qué encontramos (≈ 1:50)

Usamos dos técnicas multivariadas:
- **Componentes principales**, para entender la estructura del clima. Ocho variables se resumen en tres ejes: un día cálido, soleado y ventilado; un día húmedo y lluvioso; y un día de presión baja y poco viento.
- **Análisis discriminante lineal**, para comparar dos modelos: M0, que solo sabe la estación y la temporada, y M1, que además conoce el clima del día.

Entrenamos con 2021 a 2023 y probamos con 2024 y 2025. Las decisiones del modelo quedaron registradas antes de abrir esos años.

El resultado: el AUC sube de **0.72 a 0.79**, una mejora de 0.07 con intervalo de confianza de 0.05 a 0.09. En términos prácticos, el modelo con clima detecta el **73 %** de los días con superación, contra el 58 % del modelo sin clima, y el **89 % de los episodios mayores de 40**.

La mejora no es igual en todo el año. Es mayor en **marzo a mayo** y casi nula en temporada de lluvias. Las variables que más pesan son la **presión más baja de lo normal**, la **temperatura** dentro de cada temporada y el **viento débil**. Son asociaciones, no causas comprobadas.

## Diapositiva 3 — Problemas, qué sigue y preguntas para SIMA (≈ 1:20)

Encontramos tres problemas:
- **Lecturas sospechosas:** viento de hasta 33 metros por segundo en SO2 y NE2 en 2021, y radiación solar de noche en NO2, SE3 y CE. Agregamos una regla de limpieza para ellas.
- **Cambios de equipos:** SIMA nos contó que en 2021 cambió los sensores de viento y en 2025 cinco equipos de PM2.5. Revisamos ambos cambios y no alteran la conclusión.
- **Retención desigual:** algunas estaciones conservan pocos días.

Ya tenemos una **interfaz** donde se elige estación, temporada y clima, y da la probabilidad de superación.

Lo que sigue:
- probar el modelo con **meteorología pronosticada**, para que sirva como alerta;
- agregar el PM2.5 del día anterior;
- ajustar cortes por estación.

Y tenemos preguntas para ustedes:
- ¿En qué fechas se cambiaron los sensores, y hubo reubicación de estaciones en 2021?
- ¿Las horas están en tiempo local y en qué unidad está la lluvia?
- ¿Qué fuentes cercanas explican que Juárez y Santa Catarina superen tanto?
- ¿Les serviría una alerta basada en pronóstico?

Gracias.

---

## Reglas para el expositor

- No leas la diapositiva: la diapositiva tiene las cifras y tú cuentas la historia.
- Si te preguntan algo, presenta al compañero: «Eso lo trabajó [nombre]».
- Di «se asocia», no «causa». Di «identifica» o «clasifica», no «predice».
