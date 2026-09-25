# Ejecutar desde la raiz del proyecto, por ejemplo con source().
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}

paquetes <- c("readxl", "dplyr", "tidyr", "ggplot2", "lubridate",
              "knitr", "rmarkdown", "renv")
disponibles <- vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
cat("Motor:", R.version.string, "\n")
print(data.frame(paquete = paquetes, disponible = disponibles), row.names = FALSE)
cat("Quarto en PATH:", if (nzchar(Sys.which("quarto"))) Sys.which("quarto") else
    "no localizado; comprueba con quarto check en la Terminal", "\n")
cat("renv.lock:", if (file.exists("renv.lock")) "presente: entorno de la plantilla" else
    "falta; recuperar el archivo de la plantilla", "\n")
cat("R del entorno del curso: 4.6.1; comprobar compatibilidad si la sesion usa otra version.\n")
if (any(!disponibles)) {
  message("Hay paquetes pendientes. Revisa scripts/restaurar_entorno.R antes de ejecutarlo.")
}
