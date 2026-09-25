# Lectura estructural: no convierte unidades ni evalua calidad de las mediciones.
inventariar_excel <- function(carpeta) {
  if (!dir.exists(carpeta)) {
    stop("No existe la carpeta de datos: ", carpeta, call. = FALSE)
  }
  archivos <- sort(list.files(carpeta, pattern = "\\.xlsx$", full.names = TRUE,
                              ignore.case = TRUE))
  archivos <- archivos[!startsWith(basename(archivos), "~$")]
  if (length(archivos) == 0L) {
    stop("No hay archivos .xlsx. Copialos a data/raw o configura SIMA_DATA_DIR.",
         call. = FALSE)
  }
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Falta readxl. Ejecuta scripts/restaurar_entorno.R en tu proyecto.",
         call. = FALSE)
  }

  filas_archivos <- list()
  filas_columnas <- list()
  for (archivo in archivos) {
    huella <- unname(tools::md5sum(archivo))
    hojas <- readxl::excel_sheets(archivo)
    for (hoja in hojas) {
      # n_max = 0 limita la lectura a encabezados; no informa cobertura temporal.
      encabezados <- names(readxl::read_excel(
        archivo, sheet = hoja, n_max = 0, .name_repair = "minimal"
      ))
      if (length(encabezados) == 0L) {
        stop("Hoja sin encabezados: ", basename(archivo), " / ", hoja,
             call. = FALSE)
      }
      filas_archivos[[length(filas_archivos) + 1L]] <- data.frame(
        archivo = basename(archivo), hoja = hoja,
        bytes = file.info(archivo)$size, md5 = huella,
        columnas = length(encabezados), stringsAsFactors = FALSE
      )
      filas_columnas[[length(filas_columnas) + 1L]] <- data.frame(
        archivo = basename(archivo), hoja = hoja,
        posicion = seq_along(encabezados), columna_original = encabezados,
        stringsAsFactors = FALSE
      )
    }
  }
  list(archivos = do.call(rbind, filas_archivos),
       columnas = do.call(rbind, filas_columnas))
}
