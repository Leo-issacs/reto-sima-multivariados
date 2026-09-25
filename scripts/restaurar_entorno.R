# Restaura el entorno de la plantilla del curso; requiere internet la primera vez.
# No crea otro lockfile ni agrega dependencias nuevas.
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
if (!file.exists("renv.lock") || !file.exists("renv/activate.R")) {
  stop("Faltan archivos del entorno del curso. Recuperalos desde GitHub.", call. = FALSE)
}
# .Rprofile lo activa al abrir el proyecto. Esta llamada explicita tambien permite
# ejecutar el script desde una sesion que no haya cargado el perfil del proyecto.
source("renv/activate.R")
renv::restore()
renv::status()
