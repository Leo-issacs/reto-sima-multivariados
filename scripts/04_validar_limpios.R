# Valida los CSV publicados en data/clean/. Falla (stop) si se rompe alguna regla adoptada.
# Se ejecuta al final de scripts/03_limpiar.R y tambien solo:  Rscript scripts/04_validar_limpios.R
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
if (!exists("VARIABLES_SIMA")) source("R/importar_sima.R")
if (!exists("cargar_rangos")) source("R/diagnostico.R")
if (!exists("cargar_rangos_fabricante")) source("R/limpieza.R")

validar_limpios <- function(carpeta = "data/clean") {
  rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()
  archivos <- sort(list.files(carpeta, pattern = "^sima_horario_limpio_\\d{4}\\.csv$", full.names = TRUE))
  stopifnot(length(archivos) == 6L)
  fallos <- character()
  viento_max <- NULL
  for (f in archivos) {
    d <- data.table::fread(f, encoding = "UTF-8", colClasses = list(character = "fecha_hora"))
    anio <- as.integer(substr(d$fecha_hora, 1, 4)); stopifnot(length(unique(anio)) == 1L)
    a <- anio[1L]
    # 1. PM2.5 <= PM10 en toda hora con ambas
    n_pm <- sum(d$`PM2.5` > d$PM10, na.rm = TRUE)
    if (n_pm) fallos <- c(fallos, sprintf("%s: %d horas con PM2.5 > PM10", basename(f), n_pm))
    # 2. Ningun valor fuera del rango de su anio (la fecha decide el anio, tambien en el limite)
    for (v in VARIABLES_SIMA) {
      if (v %in% CONTAMINANTES) {
        r <- rangos_op[rangos_op$anio == a & rangos_op$variable == v, ]; lo <- r$minimo; hi <- r$maximo
      } else if (v == "RAINF") {
        lo <- 0; hi <- rangos_op$maximo[rangos_op$anio == a & rangos_op$variable == "RAINF"]
      } else {
        r <- rangos_fab[rangos_fab$variable == v, ]; lo <- r$minimo; hi <- r$maximo
      }
      x <- d[[v]]; malo <- sum(x < lo | x > hi, na.rm = TRUE)
      if (malo) fallos <- c(fallos, sprintf("%s: %d valores de %s fuera de [%s, %s]", basename(f), malo, v, lo, hi))
    }
    # 2b. Notas del PDF en su anio (WSR 2020 > 75, SR 2020-2021 > 1, PRS 2020 fuera de 690-750)
    for (k in which(NOTAS_PDF$anio == a)) {
      v <- NOTAS_PDF$variable[k]; r <- rangos_op[rangos_op$anio == a & rangos_op$variable == v, ]
      x <- d[[v]]
      malo <- if (NOTAS_PDF$tipo[k] == "alto") sum(x > r$maximo, na.rm = TRUE) else sum(x < r$minimo | x > r$maximo, na.rm = TRUE)
      if (malo) fallos <- c(fallos, sprintf("%s: %d valores de %s incumplen la nota del PDF %d", basename(f), malo, v, a))
    }
    # 3. Toda terna final completa NO/NO2/NOX tiene nox_inconsistente 0/1; las incompletas, vacio
    completa <- !is.na(d$NO) & !is.na(d$NO2) & !is.na(d$NOX)
    n_vacia <- sum(completa & is.na(d$nox_inconsistente))
    if (n_vacia) fallos <- c(fallos, sprintf("%s: %d ternas completas con nox_inconsistente vacia", basename(f), n_vacia))
    n_sobra <- sum(!completa & !is.na(d$nox_inconsistente))
    if (n_sobra) fallos <- c(fallos, sprintf("%s: %d ternas incompletas con nox_inconsistente", basename(f), n_sobra))
    tol <- with(d, abs(NOX - (NO + NO2)) > pmax(NOX_TOL_ABS_PPB, NOX_TOL_REL * NOX))
    n_inc <- sum(completa & as.integer(tol) != d$nox_inconsistente, na.rm = TRUE)
    if (n_inc) fallos <- c(fallos, sprintf("%s: %d ternas con nox_inconsistente incoherente con la tolerancia", basename(f), n_inc))
    # 4. Saturacion del sensor: ningun TOUT pegado al limite del fabricante
    n_sat <- sum(abs(d$TOUT) >= SATURACION_TOUT, na.rm = TRUE)
    if (n_sat) fallos <- c(fallos, sprintf("%s: %d horas con TOUT en el limite del sensor (|TOUT| >= %s)", basename(f), n_sat, SATURACION_TOUT))
    # 5. Consistencia espacial: cada valor publicado (observado o imputado) esta a <= umbral de la mediana
    #    de las lecturas OBSERVADAS (bandera V/C) de la red en esa hora, si reportan >= 5 estaciones
    for (v in c("TOUT", "RH")) {
      x <- d[[v]]; obs <- d[[paste0("f_", v)]] %in% c("V", "C") & !is.na(x)
      n_obs <- tapply(obs, d$fecha_hora, sum)
      med <- tapply(ifelse(obs, x, NA_real_), d$fecha_hora, stats::median, na.rm = TRUE)
      k <- match(d$fecha_hora, names(n_obs))
      viola <- !is.na(x) & n_obs[k] >= MIN_ESTACIONES_E & abs(x - med[k]) > UMBRAL_E[[v]] + 0.001
      if (any(viola, na.rm = TRUE)) fallos <- c(fallos, sprintf("%s: %d valores de %s a mas de %s de la mediana de la red", basename(f), sum(viola, na.rm = TRUE), v, UMBRAL_E[[v]]))
    }
    # 6. Horas anuladas por E o L nunca se imputan: siguen vacias y conservan su bandera
    stopifnot(all(c("f_obs_TOUT", "f_obs_RH") %in% names(d)))
    anul <- list(TOUT = d$f_obs_TOUT %in% c("E", "L"), RH = d$f_obs_RH %in% "E")
    for (v in names(anul)) {
      m <- anul[[v]]
      n_rein <- sum(m & (!is.na(d[[v]]) | !(d[[paste0("f_", v)]] %in% c("E", "L"))))
      if (n_rein) fallos <- c(fallos, sprintf("%s: %d horas de %s anuladas por E/L reincorporadas (imputadas)", basename(f), n_rein, v))
    }
    # 7. D15 SR nocturna: ningun dia conserva SR con media entre 00 y 04 h > umbral (>= 3 lecturas)
    noc <- d[as.integer(substr(fecha_hora, 12, 13)) %in% SR_NOCHE_HORAS & !is.na(SR),
             .(n = .N, m = mean(SR)), by = .(estacion, dia = substr(fecha_hora, 1, 10))]
    n_sr <- noc[n >= SR_NOCHE_MIN_LECTURAS & m > SR_NOCHE_UMBRAL + 0.0006, .N]
    if (n_sr) fallos <- c(fallos, sprintf("%s: %d estacion-dias conservan SR con media nocturna > %s", basename(f), n_sr, SR_NOCHE_UMBRAL))
    n_m <- sum(d$f_SR == "M" & !is.na(d$SR))
    if (n_m) fallos <- c(fallos, sprintf("%s: %d horas de SR con bandera M tienen valor (imputadas)", basename(f), n_m))
    # 8. D15 viento: ninguna hora conservada con WSR > mediana de la red + umbral, con >= 5 estaciones
    obs_w <- d$f_WSR %in% c("V", "C") & !is.na(d$WSR)
    w <- d[obs_w, .(estacion, fecha_hora, WSR)]
    w[, `:=`(nr = .N, med = stats::median(WSR)), by = fecha_hora]
    n_w <- w[nr >= MIN_ESTACIONES_E & WSR - med > UMBRAL_WSR_RED + 0.001, .N]
    if (n_w) fallos <- c(fallos, sprintf("%s: %d horas conservan WSR a mas de %s km/h sobre la mediana de la red", basename(f), n_w, UMBRAL_WSR_RED))
    n_uv <- sum(d$f_uv == "E" & (!is.na(d$viento_u) | !is.na(d$viento_v)))
    if (n_uv) fallos <- c(fallos, sprintf("%s: %d horas de u/v con bandera E tienen valor (imputadas)", basename(f), n_uv))
    viento_max <- rbind(viento_max, data.frame(archivo = basename(f), wsr_horario_max_kmh = max(d$WSR, na.rm = TRUE)))
  }
  if (length(fallos)) stop("Validacion de CSV limpios FALLO:\n - ", paste(fallos, collapse = "\n - "), call. = FALSE)
  message("Validacion OK: sin PM2.5 > PM10, sin valores fuera de rango del anio, nox_inconsistente coherente, sin saturacion de TOUT, consistencia espacial de TOUT/RH y regla D15 (SR nocturna y viento contra la red) (",
          length(archivos), " CSV horarios).")
  dd <- data.table::fread(file.path(carpeta, "sima_diario_2020_2025.csv"), select = c("estacion", "fecha", "viento_rapidez_ms"))
  k <- which.max(dd$viento_rapidez_ms)
  message(sprintf("Viento diario maximo: %.2f m/s (%s, %s). Maximo horario de WSR por anio: %s km/h.",
                  dd$viento_rapidez_ms[k], dd$estacion[k], dd$fecha[k],
                  paste(sprintf("%s %.1f", sub("^.*_(\\d{4})\\.csv$", "\\1", viento_max$archivo), viento_max$wsr_horario_max_kmh), collapse = "; ")))
  invisible(TRUE)
}

validar_limpios()
