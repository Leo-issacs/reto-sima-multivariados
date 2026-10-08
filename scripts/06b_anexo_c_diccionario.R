# Etapa 2, Anexo C: diccionario completo de las tres bases publicadas. Ejecutar desde la raiz,
# despues de scripts/06_explorar_etapa2.R (que escribe la muestra):
#   Rscript scripts/06b_anexo_c_diccionario.R
# Lee: data/clean/sima_horario_limpio_AAAA.csv, sima_diario_2020_2025.csv, muestra_pm25_2021_2025.csv,
#      data/clean/tabla_informe_limpieza.csv, config/rangos_operacion.csv, config/rangos_fabricante.csv
# Escribe: output/etapa2/anexo_c_diccionario.csv y agrega a data/clean/DICCIONARIO.csv las columnas
#          dominio, pct_nulos_antes y pct_nulos_despues. El .docx sale de quarto/anexo_c.qmd.
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages(library(data.table))
escribir <- function(x, ruta) utils::write.csv(x, ruta, row.names = FALSE, na = "", fileEncoding = "UTF-8")

# ---- 1. Leer las tres bases y comprobar el inventario de columnas --------------------------
archivos_h <- sort(Sys.glob("data/clean/sima_horario_limpio_*.csv"))
horaria <- rbindlist(lapply(archivos_h, fread, encoding = "UTF-8", colClasses = list(character = "fecha_hora")))
diaria  <- fread("data/clean/sima_diario_2020_2025.csv", encoding = "UTF-8")
muestra <- fread("data/clean/muestra_pm25_2021_2025.csv", encoding = "UTF-8")
BASES <- list(horaria = horaria, diaria = diaria, muestra = muestra)
ARCHIVO <- c(horaria = "sima_horario_limpio_AAAA.csv", diaria = "sima_diario_2020_2025.csv",
             muestra = "muestra_pm25_2021_2025.csv")
esperado <- c(horaria = 39, diaria = 40, muestra = 24)
n_col <- sapply(BASES, ncol)
if (any(n_col != esperado))
  stop("Inventario de columnas distinto del esperado: ", paste(names(n_col), n_col, collapse = ", "), call. = FALSE)
if (nrow(horaria) != 762792) stop("La base horaria no tiene las 762 792 horas de la malla.", call. = FALSE)

# ---- 2. Insumos: faltante original, rangos de validez y codigos de bandera -----------------
informe <- fread("data/clean/tabla_informe_limpieza.csv")
falt_orig <- setNames(informe$faltante_original_pct, informe$variable)   # % sobre 762 792 h, con las 8 189 sin fila
oper <- fread("config/rangos_operacion.csv", encoding = "UTF-8")
fab  <- fread("config/rangos_fabricante.csv", encoding = "UTF-8")

CONTAMINANTES <- c("CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "SO2")   # validez: operacion del año
METEO <- c("TOUT", "RH", "SR", "PRS", "WSR", "WDR")                         # validez: fabricante
UNIDAD <- c(CO = "ppm", NO = "ppb", NO2 = "ppb", NOX = "ppb", O3 = "ppb", PM10 = "µg/m³", PM2.5 = "µg/m³",
            SO2 = "ppb", TOUT = "°C", RH = "%", SR = "kW/m²", PRS = "mm Hg", WSR = "km/h", WDR = "grados",
            RAINF = "mm/h (no confirmada)", viento_u = "m/s", viento_v = "m/s", viento_rapidez_ms = "m/s",
            O3_max8h = "ppb", horas_lluvia = "horas")
NOMBRE <- c(CO = "monóxido de carbono", NO = "monóxido de nitrógeno", NO2 = "dióxido de nitrógeno",
            NOX = "óxidos de nitrógeno", O3 = "ozono", PM10 = "PM10", PM2.5 = "PM2.5",
            SO2 = "dióxido de azufre", TOUT = "temperatura del aire", RH = "humedad relativa",
            SR = "radiación solar", PRS = "presión atmosférica")
CODIGOS <- c(V = "válida original", N = "falta original", F = "fuera de rango", P = "regla de notas del PDF",
             S = "salto horario", R = "PM2.5 > PM10", K = "racha ≥ 24 h idéntica", L = "TOUT saturada",
             E = "consistencia espacial", M = "SR nocturna (D15)", C = "racha ≥ 6 h conservada",
             I = "imputada", X = "imputación revertida")

num <- function(x) format(signif(x, 4), scientific = FALSE, trim = TRUE, drop0trailing = TRUE)
rango_obs <- function(x) if (all(is.na(x))) "sin datos" else sprintf("%s a %s", num(min(x, na.rm = TRUE)), num(max(x, na.rm = TRUE)))
validez <- function(v, cuando = "") {
  if (v %in% CONTAMINANTES) {
    r <- oper[variable == v]
    sprintf("Validez%s: operación del año, %s a %s (máx. según año)", cuando, num(min(r$minimo)),
            if (min(r$maximo) == max(r$maximo)) num(max(r$maximo)) else paste0(num(min(r$maximo)), "–", num(max(r$maximo))))
  } else if (v == "RAINF") {
    r <- oper[variable == v]
    sprintf("Validez%s: 0 a máx. de operación del año (%s–%s)", cuando, num(min(r$maximo)), num(max(r$maximo)))
  } else {
    r <- fab[variable == v]
    extra <- c(TOUT = "; L si |TOUT| ≥ 49.9; E contra la red", RH = "; E contra la red",
               SR = "; M si SR nocturna (D15)", WSR = "; E contra la red (D15)", WDR = "; E con WSR (D15)",
               PRS = "; S si salto > 10 mm Hg")
    sprintf("Validez%s: fabricante, %s a %s%s", cuando, num(r$minimo), num(r$maximo), if (v %in% names(extra)) extra[[v]] else "")
  }
}
codigos_txt <- function(x) {
  presentes <- intersect(names(CODIGOS), unique(x))
  paste(sprintf("%s %s", presentes, CODIGOS[presentes]), collapse = "; ")
}
pct_txt <- function(p) if (p == 0) "0" else if (p < 0.05) "< 0.1" else formatC(p, format = "f", digits = 1)

# ---- 3. Ficha por columna: descripcion corta, tipo, unidad, dominio y % de nulos ----------
ficha <- function(base, col) {
  d <- BASES[[base]]; x <- d[[col]]
  var_origen <- sub("^n_horas_", "", col)
  es_medida <- col %in% c(CONTAMINANTES, METEO, "RAINF")
  desc <- tipo <- dominio <- NULL; unidad <- if (col %in% names(UNIDAD)) UNIDAD[[col]] else ""
  antes <- if (col %in% c("estacion", "fecha", "fecha_hora")) "no aplica (clave)" else
    if (es_medida) pct_txt(falt_orig[[col]]) else "no aplica (derivada)"

  if (col == "estacion") {
    desc <- if (base == "muestra") "Código de estación SIMA (13; excluye NE3 y NO3)" else "Código de estación SIMA (hoja del Excel)"
    tipo <- "categórico"; dominio <- paste(sort(unique(x)), collapse = ", ")
  } else if (col == "fecha_hora") {
    desc <- "Hora local de la medición (00:00 a 23:00), sin zona horaria"
    tipo <- "fecha-hora"; dominio <- sprintf("%s a %s", min(x), max(x))
  } else if (col == "fecha") {
    desc <- "Día calendario local"; tipo <- "fecha"; dominio <- sprintf("%s a %s", min(x), max(x))
  } else if (col == "anio") {
    desc <- "Año calendario"; tipo <- "entero"; dominio <- rango_obs(x)
  } else if (col == "temporada") {
    desc <- "Temporada regional: seca fría (nov–feb), seca cálida (mar–may), cálida húmeda (jun–oct)"
    tipo <- "categórico"; dominio <- paste(sort(unique(x)), collapse = ", ")
  } else if (col == "confinamiento_2020") {
    desc <- if (base == "muestra") "Siempre 0: la muestra excluye 2020" else "1 entre 2020-04-01 y 2020-05-31; 0 en el resto"
    tipo <- "binario"; dominio <- paste(sort(unique(x)), collapse = ", ")
  } else if (grepl("^f_", col)) {
    v <- sub("^f_(obs_)?", "", col)
    desc <- if (grepl("^f_obs_", col)) sprintf("Bandera de %s antes de imputar; conserva la causa de invalidez", v) else
      if (v == "uv") "Bandera de calidad de las componentes u y v del viento" else sprintf("Bandera de calidad de la hora para %s", v)
    tipo <- "categórico (1 letra)"; dominio <- codigos_txt(x)
  } else if (col == "nox_inconsistente") {
    desc <- "1 si |NOX − (NO+NO2)| > máx(1 ppb, 10 % de NOX); solo bandera"
    tipo <- "binario"; dominio <- "0, 1; vacío si falta NO, NO2 o NOX"
  } else if (es_medida && base == "horaria") {
    desc <- switch(col, RAINF = "Precipitación horaria tal como viene en el Excel; solo se usa en horas_lluvia",
                   WSR = "Velocidad horaria del viento, validada y sin imputar",
                   WDR = "Dirección de donde sopla el viento, validada y sin imputar",
                   sprintf("Valor horario de %s, ya limpio (incluye imputadas)", NOMBRE[[col]]))
    tipo <- "numérico"; dominio <- sprintf("%s; observado: %s", validez(col), rango_obs(x))
  } else if (es_medida) {
    desc <- sprintf("Media diaria de %s (≥ 18 h válidas, incluye imputadas)", NOMBRE[[col]])
    tipo <- "numérico"; dominio <- sprintf("%s; observado (media diaria): %s", validez(col, " por hora"), rango_obs(x))
  } else if (col %in% c("viento_u", "viento_v")) {
    eje <- if (col == "viento_u") "este-oeste" else "norte-sur"
    desc <- if (base == "horaria") sprintf("Componente %s del viento, derivada de WSR y WDR", eje) else
      sprintf("Media diaria de la componente %s del viento", eje)
    tipo <- "numérico"; dominio <- sprintf("Derivada de WSR y WDR válidos; observado: %s", rango_obs(x))
  } else if (col == "viento_rapidez_ms") {
    desc <- "Media diaria de la rapidez horaria del viento, raíz de u² + v²"
    tipo <- "numérico"; dominio <- sprintf("≥ 0; observado: %s", rango_obs(x))
  } else if (col == "O3_max8h") {
    desc <- "Máximo diario del promedio móvil de 8 h de ozono"
    tipo <- "numérico"; dominio <- sprintf("Derivada de O3 válido (≥ 6 de 8 h); observado: %s", rango_obs(x))
  } else if (col == "horas_lluvia") {
    desc <- "Horas del día con 0 < RAINF ≤ máximo de operación"
    tipo <- "entero"; dominio <- sprintf("0 a 24; observado: %s", rango_obs(x))
  } else if (col == "llovio") {
    desc <- "1 si hubo al menos una hora con lluvia"; tipo <- "binario"; dominio <- "0, 1"
  } else if (col == "n_horas_nox_inconsistente") {
    desc <- "Horas del día con nox_inconsistente = 1"; tipo <- "entero"; dominio <- sprintf("0 a 24; observado: %s", rango_obs(x))
  } else if (grepl("^n_horas_", col)) {
    desc <- switch(var_origen, viento = "Horas válidas del día con componentes u y v",
                   O3_max8h = "Horas válidas de O3 en el día", RAINF = "Horas válidas de RAINF en el día",
                   sprintf("Horas válidas de %s en el día (incluye imputadas)", var_origen))
    tipo <- "entero"; dominio <- sprintf("0 a 24; observado: %s", rango_obs(x))
  } else if (col == "en_nucleo_A") {
    desc <- "1 si el día completa el núcleo A (indicador de la etapa 1)"; tipo <- "binario"; dominio <- "0, 1"
  } else if (col == "en_nucleo_B") {
    desc <- "1 si el día completa el núcleo B = A + PM2.5 (etapa 1)"; tipo <- "binario"; dominio <- "0, 1"
  } else if (col == "en_periodo_modelado") {
    desc <- "1 si el año está entre 2021 y 2025"; tipo <- "binario"; dominio <- "0, 1"
  } else if (col == "supera_25") {
    desc <- "1 si la media diaria de PM2.5 supera 25 µg/m³"; tipo <- "binario"; dominio <- "0, 1"
  } else if (col == "supera_15") {
    desc <- "1 si supera 15 µg/m³ (sensibilidad, guía 24 h de la OMS)"; tipo <- "binario"; dominio <- "0, 1"
  } else stop("Columna sin ficha: ", base, "/", col, call. = FALSE)

  data.table(base = base, archivo = ARCHIVO[[base]], columna = col, descripcion = desc, tipo = tipo,
             unidad = unidad, dominio = dominio, pct_nulos_antes = antes,
             pct_nulos_despues = pct_txt(100 * mean(is.na(x) | (if (is.character(x)) x %in% "" else FALSE))))
}
anexo <- rbindlist(lapply(names(BASES), function(b) rbindlist(lapply(names(BASES[[b]]), function(col) ficha(b, col)))))

# ---- 4. Controles -----------------------------------------------------------------------------
palabras <- lengths(strsplit(anexo$descripcion, "\\s+"))
if (any(palabras > 15)) stop("Descripciones con más de 15 palabras: ", paste(anexo$columna[palabras > 15], collapse = ", "))
stopifnot(all(table(factor(anexo$base, names(BASES))) == esperado))
# El % de nulos despues de la base horaria debe coincidir con faltante_final de tabla_informe_limpieza.csv
for (v in c(CONTAMINANTES, METEO, "RAINF"))
  stopifnot(abs(100 * mean(is.na(horaria[[v]])) - informe[variable == v, faltante_final_pct]) < 0.001)

escribir(anexo, "output/etapa2/anexo_c_diccionario.csv")

# ---- 5. DICCIONARIO.csv: filas individuales n_horas_* y tres columnas nuevas ----------------
dic <- fread("data/clean/DICCIONARIO.csv", encoding = "UTF-8")
dic[, intersect(c("dominio", "pct_nulos_antes", "pct_nulos_despues"), names(dic)) := NULL]   # idempotente
generica <- dic[archivo == ARCHIVO[["diaria"]] & columna == "n_horas_<variable>"]
if (nrow(generica) == 1) {
  cols_n <- setdiff(grep("^n_horas_", names(diaria), value = TRUE), "n_horas_nox_inconsistente")
  filas_n <- generica[rep(1, length(cols_n))][, columna := cols_n]
  filas_n[, descripcion := sprintf("Número de horas válidas (incluye imputadas) del día para %s", sub("^n_horas_", "", columna))]
  filas_n[columna == "n_horas_viento", descripcion := "Número de horas válidas del día con componentes u y v"]
  filas_n[columna == "n_horas_O3_max8h", descripcion := "Número de horas válidas de O3 en el día"]
  pos <- which(dic$archivo == ARCHIVO[["diaria"]] & dic$columna == "n_horas_<variable>")
  dic <- rbind(dic[seq_len(pos - 1)], filas_n, dic[(pos + 1):.N])
}
dic[anexo, on = .(archivo, columna), `:=`(dominio = i.dominio, pct_nulos_antes = i.pct_nulos_antes,
                                          pct_nulos_despues = i.pct_nulos_despues)]
for (b in names(BASES)) {
  falta <- setdiff(names(BASES[[b]]), dic[archivo == ARCHIVO[[b]], columna])
  if (length(falta)) stop("DICCIONARIO.csv no documenta: ", b, "/", paste(falta, collapse = ", "), call. = FALSE)
}
escribir(dic, "data/clean/DICCIONARIO.csv")
message("Anexo C: ", paste(sprintf("%s %d", names(BASES), as.vector(table(factor(anexo$base, names(BASES))))), collapse = ", "),
        " columnas. Escrito output/etapa2/anexo_c_diccionario.csv y DICCIONARIO.csv.")
