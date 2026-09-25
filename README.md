# Calidad del aire en Monterrey — Reto SIMA

Proyecto de Análisis Multivariado (MA2003B). Somos un equipo de cuatro integrantes y trabajaremos durante cinco semanas con datos de calidad del aire y meteorología del SIMA.

Estamos en la primera etapa: revisar las bases, confirmar qué significan las variables y elegir una pregunta que podamos responder con los datos disponibles.

## Para empezar

1. Abre este repositorio en **Posit Cloud → New Project → New Project from Git Repo**.
2. Abre `sima.Rproj` y ejecuta en la consola de R:

```r
source("scripts/restaurar_entorno.R")
source("scripts/00_verificar_entorno.R")
```

El proyecto usa **R 4.6.1** y `renv` para compartir las versiones de los paquetes. La [guía de arranque](docs/INICIO_GITHUB_POSIT.md) explica el acceso, la carga de datos y el uso desde RStudio local.

## Qué vamos a hacer

| Semana | Trabajo previsto |
|---|---|
| 1 | Conocer los datos y definir la pregunta. |
| 2 | Preparar la base y explorar las variables. |
| 3 | Desarrollar el análisis multivariado. |
| 4 | Evaluar resultados y preparar la demostración. |
| 5 | Cerrar el reporte y presentar. |

Las fechas y los requisitos de cada entrega se ajustarán a lo que indiquen las profesoras.

- [Tareas abiertas](https://github.com/Leo-issacs/reto-sima-multivariados/issues)
- [Hitos de las cinco semanas](https://github.com/Leo-issacs/reto-sima-multivariados/milestones)
- [Plan de trabajo](docs/PLAN_EJECUCION.md)
- [Integrantes y reparto de trabajo](docs/EQUIPO.md)
- [Guía de estudio](docs/GUIA_ESTUDIO.md)

## Dónde está cada cosa

| Carpeta | Contenido |
|---|---|
| `R/` y `scripts/` | Funciones y pasos del análisis. Por ahora, inventario de archivos. |
| `data/` | Instrucciones para las bases y metadatos revisados. |
| `config/` | Diccionario de variables por completar. |
| `quarto/` | Reporte y presentación. |
| `docs/` | Plan, fuentes, acuerdos y registro de entregas. |
| `output/` | Resultados generados en cada copia local. |
| `app/` | Espacio para la demostración, cuando definamos su alcance. |

Las seis bases del equipo se colocan en `data/raw/`; no se suben a GitHub. Para revisar sus hojas y columnas:

```r
source("scripts/01_inventario.R")
```

Para generar el reporte, ejecutar en la Terminal:

```sh
quarto render quarto/reporte.qmd --to docx
```

El archivo se guarda en `docs/quarto/`. También puede generarse desde el botón **Render** de RStudio. El reporte inicial es una plantilla; aún no contiene resultados.

## Cómo nos organizamos

Cada tarea tiene una persona responsable y otra que la revisa. Hacemos cambios pequeños en una rama y los integramos mediante una pull request. Los pasos están en [CONTRIBUTING.md](CONTRIBUTING.md).

Este repositorio es público. Falta que los otros tres integrantes acepten sus invitaciones y comprueben que pueden editar. La entrega del entorno será una sola liga por equipo: la de este repositorio.

La base parte de [2003B_Blank](https://github.com/Krul-dev/2003B_Blank) y conserva su licencia GPL-3.0. Las adaptaciones están en [PLANTILLA_CURSO.md](docs/PLANTILLA_CURSO.md); las comprobaciones realizadas, en [VERIFICACION_BASE.md](docs/VERIFICACION_BASE.md). Los datos y documentos externos conservan las condiciones de sus fuentes.
