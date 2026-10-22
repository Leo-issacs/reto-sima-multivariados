# Ejecutar desde la raiz. Solo lee Excel; genera metadatos en output.
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
source("R/inventario.R")
carpeta_datos <- Sys.getenv("SIMA_DATA_DIR", unset = "data/raw")
inventario <- inventariar_excel(carpeta_datos)
dir.create("output", showWarnings = FALSE)
# Conexion binaria: fin de linea "\n" tambien en Windows.
escribir <- function(x, ruta) {
  con <- file(ruta, "wb"); on.exit(close(con))
  write.csv(x, con, row.names = FALSE, na = "")
}
escribir(inventario$archivos, "output/inventario_archivos.csv")
escribir(inventario$columnas, "output/inventario_columnas.csv")
message("Inventario generado: ", length(unique(inventario$archivos$archivo)),
        " archivos y ", nrow(inventario$archivos), " hojas.")
message("Esto no valida cobertura, unidades, datos faltantes ni modelos.")
