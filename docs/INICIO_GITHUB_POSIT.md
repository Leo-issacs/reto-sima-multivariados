# Abrir el proyecto y empezar a trabajar

Repositorio del equipo: https://github.com/Leo-issacs/reto-sima-multivariados

El repositorio ya está creado. No hay que crear otro ni volver a clonar la plantilla docente. Conserva su historial y el entorno R del curso; trabajamos en la rama `main`.

## Acceso del equipo

Leo administra el repositorio. Los otros tres integrantes deben compartir su usuario de GitHub, aceptar la invitación y comprobar que pueden subir una rama. Un repositorio público puede leerse sin invitación, pero editarlo requiere acceso de colaborador.

## Posit Cloud

1. Entrar con la cuenta propia a Posit Cloud.
2. Elegir **New Project → New Project from Git Repo** y pegar la URL del equipo.
3. Abrir `sima.Rproj` y completar la autenticación de GitHub para hacer Push.
4. Usar R 4.6.1 cuando esté disponible y comprobar la versión de Quarto. Si la cuenta ofrece otra versión, registrar la diferencia antes de cambiar el entorno compartido.
5. En la consola de R, ejecutar:

```r
source("scripts/restaurar_entorno.R")
source("scripts/00_verificar_entorno.R")
renv::status()
```

La primera restauración puede tardar: descarga las versiones que aparecen en `renv.lock`. No hace falta ejecutar `renv::init()`. Cada persona trabaja en su copia y comparte cambios por GitHub.

## RStudio local

En GitHub Desktop, **File → Clone repository → URL**, pegar la URL del equipo y elegir una carpeta. Abrir `sima.Rproj` y ejecutar los mismos pasos de restauración. En la computadora donde se preparó esta base, las herramientas y paquetes ya están instalados; ver [ENTORNO_LOCAL.md](ENTORNO_LOCAL.md).

## Comprobar el reporte

Abrir `quarto/reporte.qmd` y usar **Render**, o ejecutar en la Terminal:

```sh
quarto render quarto/reporte.qmd --to html
quarto render quarto/reporte.qmd --to docx
quarto render quarto/presentacion.qmd --to pptx
```

Las salidas quedan en `docs/quarto/`. Son plantillas que iremos completando. Si Windows no encuentra `quarto`, puede usarse el botón Render de RStudio o su ejecutable en `C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe`.

El PDF del curso menciona `quarto/reports/etapa1.qmd`. En nuestra base la ruta es `quarto/reporte.qmd`; la diferencia está documentada en [PLANTILLA_CURSO.md](PLANTILLA_CURSO.md).

## Cargar las bases

Obtener los mismos seis Excel BD 2020–2025 y colocar copias en `data/raw/` de cada proyecto. No vienen dentro de este repositorio. Una ruta de Windows no es accesible automáticamente desde Posit Cloud.

```r
source("scripts/01_inventario.R")
```

Comparar los CSV de `output/` con los metadatos de `data/metadata/`. Las huellas permiten comprobar que usamos los mismos archivos. Los dos Excel presentes en el historial de la plantilla docente son versiones distintas de las que se inventariaron para el equipo; no mezclarlos.

## Primer cambio

Por turnos, cada persona crea una rama, añade su nombre y usuario a [EQUIPO.md](EQUIPO.md) y solicita revisión a otra. Seguir [CONTRIBUTING.md](../CONTRIBUTING.md) para guardar y compartir el cambio.

El arranque termina cuando los cuatro tienen acceso de edición, restauran el entorno y generan el reporte. Se entrega una sola liga del repositorio por equipo; no las cuatro ligas de Posit Cloud.

Referencia: [proyectos en Posit Cloud](https://docs.posit.co/cloud/guide/projects.html).
