# Procedencia y adaptación de la plantilla

Referencia: [Krul-dev/2003B_Blank](https://github.com/Krul-dev/2003B_Blank), rama `trunk`, commit `ab041bd140da339b248c0991a95a237f8b2183cc` consultado el 25 de septiembre de 2026. Se conservaron `renv.lock`, `.Rprofile`, `renv/settings.json`, `renv/.gitignore` y `LICENSE` (GPL-3.0). Se adaptaron organización, instrucciones y reportes al reto SIMA. El lockfile registra R 4.6.1, renv 1.2.4 y 103 paquetes.

## Reparación del activador

El `renv/activate.R` de ese commit incluía `attr(version, "md5") <- ..md5..`, que falla al abrir R porque `..md5..` no está definido. Se descargó renv 1.2.4 de CRAN, se comprobaron sus sumas internas y se ejecutó `renv::activate()` para regenerar el archivo mediante el administrador oficial. Se verificó que esta reparación no cambiara `renv.lock`. No se sustituyeron las versiones del curso por las más recientes.

Referencias: [incidencia del activador en renv](https://github.com/rstudio/renv/issues/2257) y [activate](https://rstudio.github.io/renv/reference/activate.html).

## Cambios propios

- `sima.Rproj` abre la base del equipo.
- `quarto/` contiene el reporte acumulativo y una presentación inicial; `docs/quarto/` recibe sus salidas.
- `docs/` incluye el plan de cinco semanas, guía de estudio, roles, tareas, decisiones y evidencia de comprobaciones.
- `R/` y `scripts/` contienen solo el inventario inicial y las operaciones del entorno. El análisis se desarrollará por etapas.
- `data/raw/`, `data/processed/` y `output/` separan entradas y derivados; se excluyen de Git salvo sus instrucciones.
- Los archivos del entorno se distribuyen, pero las bibliotecas instaladas y cachés se reconstruyen con restore.
- `_dependencies.R` declara los 103 paquetes del curso para conservarlos con la captura implícita original. Sus declaraciones no se ejecutan. Esta lista resuelve el aviso de paquetes registrados pero todavía no usados por el esqueleto. Se sigue el mecanismo documentado por [renv para declarar dependencias](https://pkgs.rstudio.com/renv/reference/dependencies.html).

La licencia conservada corresponde al código de la plantilla. No concede derechos sobre documentos del campus ni sobre datos externos.

## Diferencias de materiales

El PDF recibido describe un archivo `quarto/reports/etapa1.qmd`; la plantilla consultada contiene `quarto/reporte.qmd`. Se documenta esa diferencia de versión y se usa la ruta existente.

Los Excel 2024 y 2025 incluidos en la plantilla tienen tamaños distintos de los archivos locales del equipo. No se consideran intercambiables ni se mezclaron con las seis bases inventariadas. La selección de datos debe registrarse en `DECISIONES.md`.

El `pyproject.toml` recibido declara Python >=3.10, numpy, matplotlib, scipy, ipython y jupyterlab. Es la alternativa Python. No se añadió un segundo entorno al proyecto R. Se conserva el archivo original del usuario en su ubicación de descarga.

El repositorio del equipo conserva el historial del origen hasta el commit indicado y añade la adaptación del reto en `main`. Las bases y el documento Word de ejemplo que venían en la plantilla no forman parte de la versión de trabajo actual; siguen presentes en su historial público. Para trabajar, clonar el repositorio del equipo como indica [INICIO_GITHUB_POSIT.md](INICIO_GITHUB_POSIT.md).
