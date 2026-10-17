# Etapa 4: funciones compartidas por scripts/08a, 08b y 08c (imputacion validada; D18-D20 de
# docs/etapa4/decisiones_etapa4.md). Las reglas de limpieza, imputacion y revalidacion viven en
# R/limpieza.R (reglas_hoja, imputar_serie, imputar_y_revalidar); aqui solo se leen los datos y se
# arma lo que esas funciones necesitan. Requiere R/importar_sima.R, R/diagnostico.R y R/limpieza.R.

# Variables meteorologicas que se imputan por hora (D19) y las 8 diarias que usa M1.
MET_HORARIA <- c("TOUT", "RH", "SR", "PRS", "viento_u", "viento_v")
MET_DIARIA <- c("TOUT", "RH", "SR", "PRS", "viento_u", "viento_v", "viento_rapidez_ms", "horas_lluvia")
COLS_VALOR <- c(VARIABLES_SIMA, "viento_u", "viento_v")      # columnas de la matriz horaria V0
COLS_BANDERA <- c(VARIABLES_SIMA, "f_uv")                    # columnas de la matriz de banderas

# Las 13 estaciones de la muestra (sin NE3 ni NO3, que casi no miden PM2.5).
estaciones_muestra <- function() {
  setdiff(sort(unique(data.table::fread("data/metadata/estaciones.csv")$codigo_hoja)), c("NE3", "NO3"))
}

# Columna de bandera que corresponde a cada variable del CSV horario.
col_bandera <- function(v) if (v %in% c("viento_u", "viento_v")) "f_uv" else paste0("f_", v)

# Lee los CSV horarios publicados (datos-v1.2) de los anios pedidos, con todas las estaciones.
leer_horario_csv <- function(anios) {
  dt <- data.table::rbindlist(lapply(anios, function(a) data.table::fread(
    sprintf("data/clean/sima_horario_limpio_%d.csv", a), encoding = "UTF-8",
    colClasses = list(character = "fecha_hora"))))
  dt[, fecha := as.POSIXct(fecha_hora, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")]
  stopifnot(!anyNA(dt$fecha))
  data.table::setorder(dt, estacion, fecha)
  dt
}

# Serie validada ANTES de imputar: las horas con bandera I (imputadas en la etapa 1) vuelven a NA.
# Las horas E, L y M ya vienen vacias y se quedan asi. Las banderas I y X se cambian a N (falta):
# el motivo original de esas horas no se publico, y para imputar solo importa si son E, L o M.
quitar_imputacion <- function(dt) {
  dt <- data.table::copy(dt)
  for (v in VARS_IMPUTAR) {
    f <- col_bandera(v)
    dt[get(f) == "I", (v) := NA_real_]
  }
  for (f in unique(vapply(VARS_IMPUTAR, col_bandera, ""))) dt[get(f) %in% c("I", "X"), (f) := "N"]
  dt
}

# Matrices de una estacion (malla horaria continua desde las 00:00), en el formato de limpiar_hoja():
# V0 = valores (VARIABLES_SIMA + u/v) y flags0 = banderas (VARIABLES_SIMA + f_uv).
matrices_hoja <- function(dt_est) {
  fecha <- dt_est$fecha
  paso <- unique(diff(as.numeric(fecha)))
  if (length(fecha) %% 24L != 0L || !identical(paso, 3600) ||
      format(fecha[1L], "%H") != "00") stop("La malla horaria de ", dt_est$estacion[1L], " no es continua.", call. = FALSE)
  V0 <- as.matrix(dt_est[, ..COLS_VALOR])
  storage.mode(V0) <- "double"
  F0 <- as.matrix(dt_est[, c(paste0("f_", VARIABLES_SIMA), "f_uv"), with = FALSE])
  colnames(F0) <- COLS_BANDERA
  list(fecha = fecha, V0 = V0, flags0 = F0)
}

# Red de referencia para revalidar imputados (la `red` que usa reglas_hoja()), reconstruida de los
# CSV publicados. TOUT y RH: mediana y numero de estaciones por hora con las lecturas observadas que
# sobrevivieron a la regla E (bandera V o C); es el punto fijo de red_espacial(). WSR: lecturas
# publicadas (validadas, sin imputar), que son las que conserva red_viento(). Usa TODAS las estaciones.
red_desde_csv <- function(dt) {
  ref <- function(x, ok) {
    d <- data.table::data.table(t = as.numeric(dt$fecha), x = x)[ok & !is.na(x)]
    as.data.frame(d[, .(n = .N, mediana = stats::median(x)), by = t])
  }
  list(TOUT = list(ref = ref(dt$TOUT, dt$f_TOUT %in% c("V", "C"))),
       RH = list(ref = ref(dt$RH, dt$f_RH %in% c("V", "C"))),
       WSR = list(ref = ref(dt$WSR, rep(TRUE, nrow(dt)))))
}

# Serie validada antes de imputar desde los Excel (misma ruta que scripts/03_limpiar.R: importar,
# fase 1, red, fase 2). Solo sirve para COMPROBAR que la reconstruccion desde los CSV es la misma
# serie; devuelve, por hoja, la fecha y la matriz `obs` (V0) redondeada a 3 decimales como se publica.
serie_previa_excel <- function(carpeta, hojas_pedidas) {
  verificar_huellas(carpeta)
  imp <- suppressMessages(importar_sima(carpeta))
  rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()
  hojas <- sort(unique(imp$datos$hoja))
  fase1 <- setNames(lapply(hojas, function(h)
    limpiar_hoja(imp$datos[imp$datos$hoja == h, ], rangos_op, rangos_fab, solo_fase1 = TRUE)), hojas)
  red <- c(red_espacial(fase1)$red, list(WSR = red_viento(fase1)$red))
  setNames(lapply(hojas_pedidas, function(h) {
    r <- limpiar_hoja(imp$datos[imp$datos$hoja == h, ], rangos_op, rangos_fab, red = red)
    list(fecha = r$fecha, obs = round(r$obs, 3))
  }), hojas_pedidas)
}

# Escribe un CSV en UTF-8 sin la columna de nombres de fila y con NA vacio.
escribir_csv <- function(x, ruta) utils::write.csv(x, ruta, row.names = FALSE, na = "", fileEncoding = "UTF-8")
