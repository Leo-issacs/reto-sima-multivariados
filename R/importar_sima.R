# Importacion sin transformar: lee cada celda con su tipo original de Excel y separa
# lo numerico de lo que no lo es (texto, banderas, logicos). No limpia nada.

VARIABLES_SIMA <- c("CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "PRS",
                    "RAINF", "RH", "SO2", "SR", "TOUT", "WSR", "WDR")
COLUMNAS_FECHA <- c("Fecha y hora", "date")

# Clase de cada celda de una columna leida con col_types = "list".
clase_celdas <- function(columna) {
  vapply(columna, function(v) class(v)[1L], character(1L), USE.NAMES = FALSE)
}

# Devuelve el vector numerico y los textos/otros de una columna de mediciones.
separar_numerico <- function(columna) {
  clase <- clase_celdas(columna)
  valores <- rep(NA_real_, length(columna))
  es_num <- clase == "numeric"
  if (any(es_num)) valores[es_num] <- unlist(columna[es_num], use.names = FALSE)
  # logical con NA = celda vacia; cualquier otra cosa se conserva como texto.
  otros <- which(!es_num & !(clase == "logical" &
                              vapply(columna, function(v) is.na(v), logical(1L))))
  texto <- vapply(columna[otros], function(v) as.character(v)[1L], character(1L))
  list(valores = valores, otros_idx = otros, otros_texto = texto,
       n_vacias = sum(clase == "logical" & !seq_along(columna) %in% otros))
}

# Comprueba que la fila 1 de la hoja sea el encabezado (fila_origen = posicion + 1).
verificar_encabezado_fila1 <- function(archivo, hoja, primer_nombre) {
  a1 <- suppressMessages(readxl::read_excel(
    archivo, sheet = hoja, range = "A1:A1", col_names = FALSE, col_types = "text"))
  identical(as.character(a1[[1L]][1L]), primer_nombre)
}

leer_hoja_sima <- function(archivo, hoja) {
  x <- suppressMessages(readxl::read_excel(
    archivo, sheet = hoja, col_types = "list", .name_repair = "minimal"))
  nombres <- names(x)
  col_fecha <- intersect(nombres, COLUMNAS_FECHA)
  stopifnot(length(col_fecha) == 1L)
  n <- nrow(x)

  # Fecha: readxl entrega POSIXct "ingenuo" (Excel no guarda zona horaria).
  clase_f <- clase_celdas(x[[col_fecha]])
  es_dt <- clase_f == "POSIXct"
  segundos <- rep(NA_real_, n)
  if (any(es_dt)) {
    segundos[es_dt] <- vapply(x[[col_fecha]][es_dt], as.numeric, numeric(1L))
  }
  fecha <- as.POSIXct(segundos, origin = "1970-01-01", tz = "UTC")

  datos <- data.frame(
    archivo = basename(archivo), hoja = hoja,
    anio_archivo = as.integer(sub("^.*?(\\d{4}).*$", "\\1", basename(archivo))),
    fila_origen = seq_len(n) + 1L, fecha_hora = fecha,
    stringsAsFactors = FALSE
  )
  no_num <- list()
  n_vacias <- c()
  for (v in intersect(VARIABLES_SIMA, nombres)) {
    s <- separar_numerico(x[[v]])
    datos[[v]] <- s$valores
    n_vacias[v] <- s$n_vacias
    if (length(s$otros_idx)) {
      no_num[[v]] <- data.frame(
        archivo = basename(archivo), hoja = hoja, fila_origen = s$otros_idx + 1L,
        variable = v, texto = s$otros_texto, stringsAsFactors = FALSE)
    }
  }
  for (v in setdiff(VARIABLES_SIMA, nombres)) datos[[v]] <- NA_real_

  info <- data.frame(
    archivo = basename(archivo), hoja = hoja, columna_fecha = col_fecha,
    n_filas = n, n_columnas = length(nombres),
    columnas_faltantes = paste(setdiff(VARIABLES_SIMA, nombres), collapse = ";"),
    columnas_extra = paste(setdiff(nombres, c(VARIABLES_SIMA, COLUMNAS_FECHA)),
                           collapse = ";"),
    fecha_celdas_datetime = sum(es_dt),
    fecha_celdas_texto = sum(clase_f == "character"),
    fecha_celdas_numero = sum(clase_f == "numeric"),
    fecha_celdas_vacias = sum(clase_f == "logical"),
    encabezado_en_fila1 = verificar_encabezado_fila1(archivo, hoja, nombres[1L]),
    stringsAsFactors = FALSE
  )
  list(datos = datos,
       no_numericos = if (length(no_num)) do.call(rbind, no_num) else NULL,
       info = info)
}

importar_sima <- function(carpeta) {
  archivos <- sort(list.files(carpeta, pattern = "^BD \\d{4}\\.xlsx$",
                              full.names = TRUE))
  if (!length(archivos)) stop("No hay archivos 'BD AAAA.xlsx' en ", carpeta)
  partes <- list()
  for (archivo in archivos) {
    for (hoja in readxl::excel_sheets(archivo)) {
      message("  leyendo ", basename(archivo), " / ", hoja)
      partes[[length(partes) + 1L]] <- leer_hoja_sima(archivo, hoja)
    }
  }
  list(
    datos = do.call(rbind, lapply(partes, `[[`, "datos")),
    no_numericos = do.call(rbind, lapply(partes, `[[`, "no_numericos")),
    info = do.call(rbind, lapply(partes, `[[`, "info"))
  )
}

# Verifica que los Excel sean los inventariados (misma huella MD5).
verificar_huellas <- function(carpeta, inventario = "data/metadata/inventario_archivos_inicial.csv") {
  inv <- utils::read.csv(inventario, stringsAsFactors = FALSE)
  h <- unname(tools::md5sum(file.path(carpeta, inv$archivo)))
  if (!all(h == inv$md5, na.rm = FALSE) || anyNA(h)) {
    stop("Huella distinta a la del inventario en: ",
         paste(inv$archivo[is.na(h) | h != inv$md5], collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}
