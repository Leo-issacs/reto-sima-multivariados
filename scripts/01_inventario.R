# Ejecutar desde la raiz. Solo lee Excel; genera metadatos en output.
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
source("R/inventario.R")
carpeta_datos <- Sys.getenv("SIMA_DATA_DIR", unset = "data/raw")
inventario <- inventariar_excel(carpeta_datos)
dir.create("output", showWarnings = FALSE)
write.csv(inventario$archivos, "output/inventario_archivos.csv",
          row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(inventario$columnas, "output/inventario_columnas.csv",
          row.names = FALSE, na = "", fileEncoding = "UTF-8")
message("Inventario generado: ", length(unique(inventario$archivos$archivo)),
        " archivos y ", nrow(inventario$archivos), " hojas.")
message("Esto no valida cobertura, unidades, datos faltantes ni modelos.")
