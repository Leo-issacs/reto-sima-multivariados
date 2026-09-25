# Verificación de la base

Actualizada el 25 de septiembre de 2026. Comprueba el esqueleto y el entorno técnico local; no valida un estudio estadístico ni acredita una entrega académica.

## Resultado comprobado

- R 4.6.1 restauró los **103 paquetes** del `renv.lock` del curso. Se comprobó la carga de cada paquete y su versión exacta leyendo su descripción instalada.
- El lockfile mantiene el mismo contenido JSON de la plantilla consultada. No se actualizaron sus versiones para resolver las instalaciones.
- Se regeneró el activador con renv 1.2.4 para corregir el marcador inválido de la plantilla.
- Se conserva la configuración original de captura implícita. `_dependencies.R` declara los paquetes del curso y evita que se proponga retirarlos por no usarse aún en el análisis.
- Una sesión nueva de R cargó automáticamente el proyecto. `renv::status()` terminó con **“No issues found -- the project is in a consistent state.”**
- Una prueba de `snapshot()` hacia un archivo temporal conservó los mismos 103 paquetes y versiones. El `renv.lock` real no se modificó.
- Los cuatro archivos operativos de R y la nueva declaración de dependencias pasaron el análisis de sintaxis.
- El inventario detectó correctamente la ausencia de Excel. Sobre copias de las seis bases BD 2020–2025 produjo 87 filas de archivo/hoja y 1392 encabezados, con huellas iguales a las registradas inicialmente.
- Quarto 1.10.18 generó HTML, Word y una presentación PowerPoint de siete diapositivas en `docs/quarto/`. Siguen siendo plantillas sin resultados.
- Los enlaces internos se verificaron y el ZIP contiene los archivos del entorno, documentación y código, excluyendo bibliotecas instaladas, originales de datos, credenciales y archivos temporales.
- El repositorio del equipo utiliza `main` y conserva el historial de la plantilla docente. El ZIP es una copia de los archivos de trabajo; para colaborar se debe clonar desde GitHub.

## Instalaciones y alcance

Se instalaron GitHub Desktop 3.6.6 y Rtools45 (compilador GCC 14.3.0; Make 4.4.1), desde instaladores oficiales con firma válida. Ambos instaladores finalizaron con código 0. R, RStudio, Git y Quarto ya estaban presentes. Véase [ENTORNO_LOCAL.md](ENTORNO_LOCAL.md).

La primera restauración no pudo compilar algunos paquetes porque faltaba Rtools. La restauración posterior lo resolvió. Aparecieron advertencias de configuración regional `C.UTF-8` durante la ejecución automatizada; no impidieron las comprobaciones y no se cambiaron las preferencias regionales de Windows.

El lanzador local `quarto.cmd` tuvo un problema con espacios en su ruta. Se verificó `quarto.exe` de la misma instalación. Las descargas y algunas operaciones necesitaron acceso ampliado fuera del aislamiento de las herramientas de verificación; esto no es un paso obligatorio para Posit Cloud.

## Pendiente con el equipo

- Completar las tres invitaciones y comprobar que los cuatro pueden editar el repositorio público.
- Restaurar y probar el entorno en cada cuenta de Posit Cloud, registrando R y Quarto disponibles allí.
- Confirmar unidades, códigos, zona horaria y versión de los datos; evaluar los registros completos antes de elegir modelos.
- Incorporar la rúbrica y fechas semanales cuando se comuniquen.
- Revisar visualmente los documentos cuando contengan tablas, figuras y resultados reales.

Las instalaciones locales no configuran automáticamente cuentas de GitHub o Posit Cloud. Se publicó la base del repositorio. Aún no se eligió el método estadístico ni se ejecutaron modelos.
