# Inspección inicial de las bases

Revisión realizada el 21 de septiembre de 2026 (hora de Guatemala). Se abrieron los seis Excel en modo de lectura y se inspeccionaron nombres de hojas, dimensiones declaradas, encabezados y cuatro filas iniciales por hoja. No se modificaron los originales ni se calcularon estadísticas ambientales.

## Evidencia observada

| Archivo | Hojas | Tamaño MiB | Primera columna |
|---|---:|---:|---|
| BD 2020.xlsx | 13 | 8.64 | Fecha y hora |
| BD 2021.xlsx | 14 | 10.63 | Fecha y hora |
| BD 2022.xlsx | 15 | 10.77 | Fecha y hora |
| BD 2023.xlsx | 15 | 11.33 | Fecha y hora |
| BD 2024.xlsx | 15 | 11.54 | Fecha y hora |
| BD 2025.xlsx | 15 | 10.78 | date |

Se revisaron 87 hojas y se observaron 16 columnas en todas ellas. Los tamaños corresponden a archivos comprimidos en disco, no a memoria requerida. Los catálogos y huellas están en `data/metadata/`.

Encabezados comunes: CO, NO, NO2, NOX, O3, PM10, PM2.5, PRS, RAINF, RH, SO2, SR, TOUT, WSR y WDR, además de la fecha. En 2025 la fecha se llama `date`; en los otros libros, `Fecha y hora`.

Hay 15 códigos de hoja distintos en el conjunto. NE3 aparece a partir del libro 2021 y NO3 a partir del libro 2022. Esto prueba presencia de hojas, no fechas de inicio de operación de estaciones.

La hoja NO3 de BD 2022.xlsx declara 744 filas en Excel. Los otros tamaños también varían. Las dimensiones pueden incluir cabeceras y filas vacías o formateadas: no permiten concluir por sí solas la cantidad de mediciones, los huecos o la cobertura anual.

Se observaron celdas vacías en la muestra inicial. No se cuantificó el porcentaje de faltantes de los libros completos. Algunas mediciones consecutivas coinciden; eso por sí solo no demuestra duplicados o fallos instrumentales.

## Material no disponible en las rutas indicadas

- PIMUS-Documento Ejecutivo.pdf
- Padrón medio ambiente.xlsx
- INFO INVENTARIO SABANA 2018.xlsx
- Ubicación de las estaciones de monitoreo.docx
- Rangos de los parámetros del SIMA.pdf
- Etiquetas.xlsx

No se localizaron estos seis archivos en las rutas de Descargas comunicadas ni por nombre en la búsqueda acotada a esa carpeta. Esto no significa que no existan en otra ubicación. Recuperarlos es una tarea de la semana 1.

## Consecuencias para el plan

1. Preservar archivo y hoja al importar; no unir por posición de hoja.
2. Normalizar los dos nombres de fecha y verificar formato, zona horaria y límites de periodo.
3. Distinguir códigos de hoja NO2/SO2 de variables de contaminantes con esos nombres.
4. Confirmar unidades y códigos antes de convertir WSR o interpretar rangos.
5. Seleccionar estaciones y periodos tras evaluar registros reales, no solo presencia de hojas.

Esta inspección es una base de planificación. No constituye una validación de los datos ni una entrega académica completa.
