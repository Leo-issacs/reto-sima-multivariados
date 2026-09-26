# Diagnostico de calidad de datos SIMA. Solo mide: no imputa, no recorta, no corrige.
# Unidad de analisis: hoja (= estacion) x anio del archivo, sobre una malla horaria
# completa del anio calendario (00:00 del 1 de enero a 23:00 del 31 de diciembre).

# Conjuntos para la cobertura conjunta (exploratoria; se redefinen al decidir variables).
CONJUNTOS_COBERTURA <- list(
  contaminantes = c("PM10", "PM2.5", "O3", "NO2", "CO"),
  meteorologia  = c("TOUT", "RH", "WSR", "WDR")
)
CONJUNTOS_COBERTURA$todo <- unlist(CONJUNTOS_COBERTURA, use.names = FALSE)

HORAS_MIN_DIA <- 18L
RACHA_MIN_HORAS <- 6L
TOL_NOX_PPB <- c(1, 5)      # umbrales de |NOX - (NO + NO2)|
TOL_PM_UGM3 <- 5            # exceso de PM2.5 sobre PM10 considerado material

cargar_rangos <- function(ruta = "config/rangos_operacion.csv") {
  r <- utils::read.csv(ruta, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  r$minimo <- as.numeric(r$minimo)
  r$maximo <- as.numeric(r$maximo)
  r
}

# Rachas de valores identicos consecutivos (NA rompe la racha).
rachas_identicas <- function(x, min_len = RACHA_MIN_HORAS) {
  vacio <- c(n = 0L, horas = 0L, max_horas = 0L, horas_no_cero = 0L)
  if (all(is.na(x))) return(vacio)
  r <- rle(x)
  largas <- which(r$lengths >= min_len & !is.na(r$values))
  if (!length(largas)) return(vacio)
  c(n = length(largas), horas = sum(r$lengths[largas]),
    max_horas = max(r$lengths[largas]),
    horas_no_cero = sum(r$lengths[largas][r$values[largas] != 0]))
}

# Malla horaria del anio y valores por variable, resolviendo duplicados con la regla
# "primer valor numerico de la marca" (solo para medir; la regla final va en la limpieza).
construir_malla <- function(d, anio) {
  malla <- seq(as.POSIXct(sprintf("%d-01-01 00:00:00", anio), tz = "UTC"),
               as.POSIXct(sprintf("%d-12-31 23:00:00", anio), tz = "UTC"), by = "hour")
  pos <- match(as.numeric(d$fecha_hora), as.numeric(malla))
  en_anio <- !is.na(pos)
  X <- matrix(NA_real_, nrow = length(malla), ncol = length(VARIABLES_SIMA),
              dimnames = list(NULL, VARIABLES_SIMA))
  for (v in VARIABLES_SIMA) {
    ok <- en_anio & !is.na(d[[v]])
    ok[ok] <- !duplicated(pos[ok])
    X[pos[ok], v] <- d[[v]][ok]
  }
  ts_dup <- unique(d$fecha_hora[duplicated(d$fecha_hora)])
  list(malla = malla, X = X,
       filas = nrow(d), filas_fuera_anio = sum(!en_anio),
       distintas = length(unique(pos[en_anio])),
       marcas_duplicadas = length(ts_dup),
       filas_extra_por_duplicado = sum(duplicated(d$fecha_hora)),
       ausentes = malla[!malla %in% d$fecha_hora],
       duplicadas = ts_dup)
}

# Bloques contiguos de horas ausentes (para leer las tablas sin miles de filas).
bloques_ausentes <- function(horas) {
  if (!length(horas)) return(NULL)
  h <- sort(horas)
  corte <- c(TRUE, diff(as.numeric(h)) != 3600)
  grupo <- cumsum(corte)
  data.frame(inicio = as.POSIXct(tapply(as.numeric(h), grupo, min), origin = "1970-01-01", tz = "UTC"),
             fin = as.POSIXct(tapply(as.numeric(h), grupo, max), origin = "1970-01-01", tz = "UTC"),
             horas = as.integer(tapply(as.numeric(h), grupo, length)))
}

diagnosticar_hoja <- function(d, rangos, no_num) {
  hoja <- d$hoja[1L]; anio <- d$anio_archivo[1L]
  m <- construir_malla(d, anio)
  n_esp <- length(m$malla)
  dias <- n_esp / 24L
  mes <- as.integer(format(m$malla, "%m"))
  rg <- rangos[rangos$anio == anio, ]

  series <- list(); mensual <- list(); diaria <- list(); valido <- list()
  for (v in VARIABLES_SIMA) {
    x <- m$X[, v]
    lim <- rg[rg$variable == v, ]
    lo <- lim$minimo; hi <- lim$maximo
    pres <- !is.na(x)
    bajo <- pres & x < lo
    alto <- pres & x > hi
    ok <- pres & !bajo & !alto
    ra <- rachas_identicas(x)
    nn <- if (is.null(no_num)) 0L else
      sum(no_num$hoja == hoja & no_num$archivo == d$archivo[1L] & no_num$variable == v)
    series[[v]] <- data.frame(
      archivo = d$archivo[1L], hoja = hoja, anio = anio, variable = v,
      horas_esperadas = n_esp, horas_presentes = sum(pres),
      pct_faltante = 100 * (1 - sum(pres) / n_esp),
      no_numericos = nn,
      rango_min = lo, rango_max = hi,
      fuera_rango_bajo = sum(bajo), fuera_rango_alto = sum(alto),
      pct_fuera_rango = if (sum(pres)) 100 * (sum(bajo) + sum(alto)) / sum(pres) else NA_real_,
      negativos = sum(pres & x < 0),
      horas_validas = sum(ok),
      rachas_n = ra[["n"]], rachas_horas = ra[["horas"]], racha_max_horas = ra[["max_horas"]],
      rachas_horas_no_cero = ra[["horas_no_cero"]],
      stringsAsFactors = FALSE)
    mensual[[v]] <- data.frame(
      hoja = hoja, anio = anio, mes = 1:12, variable = v,
      horas_esperadas = tabulate(mes, 12L), horas_presentes = tabulate(mes[pres], 12L))
    hp <- colSums(matrix(pres, nrow = 24L)); hv <- colSums(matrix(ok, nrow = 24L))
    diaria[[v]] <- data.frame(
      archivo = d$archivo[1L], hoja = hoja, anio = anio, variable = v,
      dias_esperados = dias,
      dias_ge18_presentes = sum(hp >= HORAS_MIN_DIA),
      dias_ge18_validos = sum(hv >= HORAS_MIN_DIA))
    valido[[v]] <- hv >= HORAS_MIN_DIA
  }
  completos <- vapply(CONJUNTOS_COBERTURA, function(vs) sum(Reduce(`&`, valido[vs])), integer(1L))
  cobertura_conjunta <- data.frame(
    archivo = d$archivo[1L], hoja = hoja, anio = anio, dias_esperados = dias,
    as.list(setNames(completos, paste0("dias_completos_", names(completos)))),
    stringsAsFactors = FALSE)

  X <- m$X
  s <- X[, "NO"] + X[, "NO2"]
  ok3 <- !is.na(X[, "NOX"]) & !is.na(s)
  dif <- abs(X[ok3, "NOX"] - s[ok3])
  cons_nox <- data.frame(
    hoja = hoja, anio = anio, horas_comparables = sum(ok3),
    dif_gt_1ppb = sum(dif > TOL_NOX_PPB[1]), dif_gt_5ppb = sum(dif > TOL_NOX_PPB[2]),
    pct_dif_gt_1ppb = if (sum(ok3)) 100 * mean(dif > TOL_NOX_PPB[1]) else NA_real_,
    pct_dif_gt_5ppb = if (sum(ok3)) 100 * mean(dif > TOL_NOX_PPB[2]) else NA_real_,
    dif_mediana = if (sum(ok3)) median(dif) else NA_real_,
    dif_p95 = if (sum(ok3)) unname(quantile(dif, 0.95)) else NA_real_,
    dif_max = if (sum(ok3)) max(dif) else NA_real_)
  okp <- !is.na(X[, "PM10"]) & !is.na(X[, "PM2.5"])
  ex <- X[okp, "PM2.5"] - X[okp, "PM10"]
  cons_pm <- data.frame(
    hoja = hoja, anio = anio, horas_comparables = sum(okp),
    pm25_gt_pm10 = sum(ex > 0), pm25_gt_pm10_mas5 = sum(ex > TOL_PM_UGM3),
    pct_pm25_gt_pm10 = if (sum(okp)) 100 * mean(ex > 0) else NA_real_,
    pct_pm25_gt_pm10_mas5 = if (sum(okp)) 100 * mean(ex > TOL_PM_UGM3) else NA_real_)

  bl <- bloques_ausentes(m$ausentes)
  list(
    hoja_anio = data.frame(
      archivo = d$archivo[1L], hoja = hoja, anio = anio, filas_hoja = m$filas,
      horas_esperadas = n_esp, horas_con_marca = m$distintas,
      horas_ausentes = length(m$ausentes), bloques_ausentes = if (is.null(bl)) 0L else nrow(bl),
      bloque_ausente_max_horas = if (is.null(bl)) 0L else max(bl$horas),
      filas_fuera_del_anio = m$filas_fuera_anio,
      marcas_duplicadas = m$marcas_duplicadas,
      filas_extra_por_duplicado = m$filas_extra_por_duplicado,
      primera_marca = format(min(d$fecha_hora), "%Y-%m-%d %H:%M"),
      ultima_marca = format(max(d$fecha_hora), "%Y-%m-%d %H:%M"),
      stringsAsFactors = FALSE),
    bloques = if (is.null(bl)) NULL else cbind(archivo = d$archivo[1L], hoja = hoja, anio = anio, bl),
    duplicadas = if (length(m$duplicadas)) data.frame(archivo = d$archivo[1L], hoja = hoja,
                                                       fecha_hora = m$duplicadas) else NULL,
    series = do.call(rbind, series), mensual = do.call(rbind, mensual),
    diaria = do.call(rbind, diaria), cobertura_conjunta = cobertura_conjunta,
    cons_nox = cons_nox, cons_pm = cons_pm)
}

diagnosticar <- function(datos, rangos, no_numericos = NULL) {
  grupos <- split(seq_len(nrow(datos)), paste(datos$archivo, datos$hoja, sep = "|"))
  partes <- lapply(grupos, function(i) diagnosticar_hoja(datos[i, ], rangos, no_numericos))
  unir <- function(campo) {
    z <- lapply(partes, `[[`, campo); z <- z[!vapply(z, is.null, logical(1L))]
    if (length(z)) { r <- do.call(rbind, z); rownames(r) <- NULL; r } else NULL
  }
  campos <- c("hoja_anio", "bloques", "duplicadas", "series", "mensual", "diaria",
              "cobertura_conjunta", "cons_nox", "cons_pm")
  setNames(lapply(campos, unir), campos)
}

# Cobertura diaria por hoja x variable x anio, con porcentajes sobre dias del anio.
tabla_cobertura_diaria <- function(diaria) {
  diaria$pct_dias_ge18_presentes <- 100 * diaria$dias_ge18_presentes / diaria$dias_esperados
  diaria$pct_dias_ge18_validos <- 100 * diaria$dias_ge18_validos / diaria$dias_esperados
  diaria
}

# Descripcion de la columna de fecha por hoja (tipo, formato, zona, resolucion).
resumen_fechas <- function(datos, info) {
  grupos <- split(seq_len(nrow(datos)), paste(datos$archivo, datos$hoja, sep = "|"))
  filas <- lapply(grupos, function(i) {
    f <- as.numeric(datos$fecha_hora[i]); dl <- diff(f) / 3600
    data.frame(archivo = datos$archivo[i[1L]], hoja = datos$hoja[i[1L]],
               primera = format(min(datos$fecha_hora[i]), "%Y-%m-%d %H:%M"),
               ultima = format(max(datos$fecha_hora[i]), "%Y-%m-%d %H:%M"),
               orden_estrictamente_creciente = all(dl > 0),
               marcas_en_punto = mean(f %% 3600 == 0),
               pct_saltos_1h = 100 * mean(dl == 1),
               saltos_mayores_1h = sum(dl > 1), salto_max_h = max(dl),
               filas_por_dia_mediana = median(as.integer(table(as.Date(datos$fecha_hora[i])))),
               stringsAsFactors = FALSE)
  })
  fechas <- do.call(rbind, filas)
  merge(info[, c("archivo", "hoja", "columna_fecha", "n_filas", "fecha_celdas_datetime",
                 "fecha_celdas_texto", "fecha_celdas_numero", "fecha_celdas_vacias",
                 "encabezado_en_fila1")], fechas, by = c("archivo", "hoja"))
}

# Hora del centroide de radiacion solar por temporada: si el reloj llevara horario de
# verano, el centroide de jun-ago se movería ~1 h respecto de dic-feb.
centroide_solar <- function(datos) {
  m <- as.integer(format(datos$fecha_hora, "%m")); h <- as.integer(format(datos$fecha_hora, "%H"))
  filas <- list()
  for (a in sort(unique(datos$anio_archivo))) {
    for (temp in list(invierno = c(12, 1, 2), verano = c(6, 7, 8))) {
      k <- datos$anio_archivo == a & m %in% temp & !is.na(datos$SR) &
        datos$SR >= 0 & datos$SR <= 1.4
      mh <- tapply(datos$SR[k], h[k], mean)
      filas[[length(filas) + 1L]] <- data.frame(
        anio = a, temporada = if (identical(temp, c(12, 1, 2))) "dic-feb" else "jun-ago",
        centroide_hora = sum(as.numeric(names(mh)) * mh) / sum(mh))
    }
  }
  do.call(rbind, filas)
}

# ---- Heatmaps ---------------------------------------------------------------
heatmap_faltantes <- function(mensual, hojas, variable, archivo_png) {
  d <- mensual[mensual$variable == variable, ]
  agr <- stats::aggregate(cbind(horas_esperadas, horas_presentes) ~ hoja + anio + mes, d, sum)
  rejilla <- expand.grid(hoja = hojas, anio = 2020:2025, mes = 1:12, stringsAsFactors = FALSE)
  g <- merge(rejilla, agr, all.x = TRUE)
  g$pct_faltante <- 100 * (1 - g$horas_presentes / g$horas_esperadas)  # NA = sin hoja
  g$fecha <- as.Date(sprintf("%d-%02d-01", g$anio, g$mes))
  g$hoja <- factor(g$hoja, levels = rev(hojas))
  p <- ggplot2::ggplot(g, ggplot2::aes(fecha, hoja, fill = pct_faltante)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
    ggplot2::scale_fill_gradientn(
      colours = c("#f7fbff", "#fee8c8", "#fdbb84", "#e34a33", "#7f0000"),
      limits = c(0, 100), na.value = "grey80", name = "% faltante") +
    ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y", expand = c(0, 0)) +
    ggplot2::labs(x = NULL, y = "Estacion (hoja)",
                  title = paste0("Horas faltantes por mes: ", variable),
                  subtitle = "% de horas del mes sin valor numerico; gris = la estacion no tiene hoja ese anio") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
  ggplot2::ggsave(archivo_png, p, width = 10, height = 4.2, dpi = 110)
  invisible(g)
}

# ---- Tamano de los CSV limpios -------------------------------------------------
# Mide escribiendo de verdad un CSV con la forma prevista (estacion, fecha_hora, 15
# variables redondeadas a 2 decimales) y otro diario; los flags se estiman aparte.
estimar_tamanos_csv <- function(datos, redondeo = 2L) {
  horario <- datos[, c("hoja", "fecha_hora", VARIABLES_SIMA)]
  names(horario)[1:2] <- c("estacion", "fecha_hora")
  horario$fecha_hora <- format(horario$fecha_hora, "%Y-%m-%d %H:%M:%S")
  for (v in VARIABLES_SIMA) horario[[v]] <- round(horario[[v]], redondeo)
  f1 <- tempfile(fileext = ".csv")
  data.table::fwrite(horario, f1)
  b_horario <- file.size(f1)

  dia <- as.Date(datos$fecha_hora)
  idx <- interaction(datos$hoja, dia, drop = TRUE)
  med <- vapply(VARIABLES_SIMA, function(v) tapply(datos[[v]], idx, function(z)
    if (all(is.na(z))) NA_real_ else mean(z, na.rm = TRUE)), numeric(nlevels(idx)))
  nval <- vapply(VARIABLES_SIMA, function(v) tapply(!is.na(datos[[v]]), idx, sum), numeric(nlevels(idx)))
  colnames(nval) <- paste0("n_", VARIABLES_SIMA)
  diario <- data.frame(estacion = sub("\\.[0-9-]+$", "", levels(idx)),
                       fecha = sub("^.*\\.", "", levels(idx)), round(med, redondeo), nval)
  f2 <- tempfile(fileext = ".csv"); data.table::fwrite(diario, f2)
  b_diario <- file.size(f2)
  unlink(c(f1, f2))
  por_fila <- b_horario / nrow(horario)
  por_fila_flags <- por_fila + length(VARIABLES_SIMA) * 2   # ",0" por variable
  max_filas_anio <- max(table(datos$anio_archivo))
  list(
    filas_horario = nrow(horario), filas_diario = nrow(diario),
    mb_horario = b_horario / 1e6, mb_horario_con_flags = por_fila_flags * nrow(horario) / 1e6,
    mb_horario_anio_mayor = por_fila * max_filas_anio / 1e6,
    mb_horario_anio_mayor_con_flags = por_fila_flags * max_filas_anio / 1e6,
    mb_diario = b_diario / 1e6)
}
