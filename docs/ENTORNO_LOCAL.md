# Entorno local preparado

Comprobación del 25 de septiembre de 2026 en la computadora de Leo.

| Herramienta | Versión comprobada | Acción |
|---|---|---|
| R | 4.6.1 | Ya instalado; utilizado para restauración e inventario. |
| RStudio | 2026.09.0+174 | Ya instalado. |
| Git | 2.54.0.windows.1 | Ya instalado. |
| Quarto incluido en RStudio | 1.10.18 | Ya instalado; generó HTML, Word y PowerPoint. |
| GitHub Desktop | 3.6.6 | Instalado en esta preparación. |
| Rtools45 | Distribución 6768-6492; GCC 14.3.0 | Instalado; permitió compilar las versiones del curso. |
| renv | 1.2.4 | Activador reparado y entorno restaurado. |
| Paquetes del curso | 103 versiones exactas | Instalados en la biblioteca del proyecto. |

Para abrir la base local, abrir `sima.Rproj` con RStudio. Conservar la carpeta `renv/` junto al proyecto: incluye la biblioteca local, que no se envía en el ZIP ni a GitHub. En otra copia, ejecutar `renv::restore()`.

No se preparó la alternativa Python del TOML: el equipo eligió R. `openair` (rosa de vientos) y `maps` (ejemplo del PDF) no forman parte del lockfile recibido; se incorporarán con `renv::install()` y `snapshot()` cuando se necesiten. La rosa de vientos requiere además confirmar unidades y códigos de los datos.

## Lo que sigue

1. Aceptar las invitaciones al repositorio del equipo y comprobar edición.
2. Cada persona abre el repositorio en su Posit Cloud y restaura el entorno allí.
3. Seguir [INICIO_GITHUB_POSIT.md](INICIO_GITHUB_POSIT.md) para generar el reporte y practicar el primer cambio.

Posit Cloud es el entorno de trabajo preferido; estas instalaciones locales sirven como alternativa y para comprobar la base. Una instalación local no se transfiere a la nube: se transfieren el código y el lockfile, y se reconstruyen los paquetes.

Fuentes de los instaladores: [GitHub Desktop](https://desktop.github.com/download/) y [Rtools45 en CRAN](https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html).
