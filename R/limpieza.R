# Limpieza SIMA (etapa 1). Cada hora de cada variable queda con una bandera de una letra:
#   V valida (dato original)         N falta original (celda vacia o sin fila)
#   F fuera de rango duro            P regla de las notas del PDF (solo en su anio)
#   S salto > umbral en 1 h (SIMA h) R PM2.5 > PM10 (SIMA r): se invalidan ambas
#   K racha >= 24 h identicos invalidada
#   L saturacion del sensor (TOUT en el limite del fabricante, |TOUT| >= 49.9)
#   E consistencia espacial: TOUT (>10 C) o RH (>40 pp) lejos de la mediana de la red en esa hora
#   C racha >= 6 h identicos marcada pero conservada
#   I imputada (interpolacion lineal, huecos internos <= 3 h)
#   X imputacion revertida: el valor interpolado incumplia una regla y volvio a NA
# Rangos duros: contaminantes = rango de operacion del anio (ambos limites);
# meteorologia = rango del fabricante (RAINF: 0 al maximo de operacion del anio). Reglas y orden: ver data/clean/README.md.
# Requiere R/importar_sima.R y R/diagnostico.R (construir_malla, cargar_rangos).

# Permite usar sintaxis data.table en funciones definidas con source() (red_espacial).
.datatable.aware <- TRUE

CONTAMINANTES <- c("CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "SO2")
VARS_RACHA_INVALIDA <- c(CONTAMINANTES, "TOUT", "PRS", "RH")
VARS_IMPUTAR <- c(CONTAMINANTES, "TOUT", "RH", "SR", "PRS", "viento_u", "viento_v")
SALTO_MAX <- c(TOUT = 10, PRS = 10)      # grados C / mm Hg por hora
RACHA_MARCA_H <- 6L
RACHA_INVALIDA_H <- 24L
MAX_HUECO_H <- 3L
NOX_TOL_ABS_PPB <- 1                     # piso: resolucion tipica del analizador
NOX_TOL_REL <- 0.10                      # 10 % de NOX
HORAS_MIN_DIA_LIMPIO <- 18L
# Consistencia espacial (buddy check, Fiebrich et al. 2010): se invalida una lectura que se aleja
# de la mediana de la red a esa misma hora, solo si reportan >= 5 estaciones.
UMBRAL_E <- c(TOUT = 10, RH = 40)         # grados C / puntos porcentuales
MIN_ESTACIONES_E <- 5L
SATURACION_TOUT <- 49.9                   # |TOUT| >= 49.9 = sensor pegado al limite del fabricante (+-50)
# Notas del PDF (solo en su anio): var, anios, tipo de limite sobre el rango de operacion.
NOTAS_PDF <- data.frame(
  variable = c("WSR", "SR", "SR", "PRS"), anio = c(2020, 2020, 2021, 2020),
  tipo = c("alto", "alto", "alto", "ambos"), stringsAsFactors = FALSE)

cargar_rangos_fabricante <- function(ruta = "config/rangos_fabricante.csv") {
  r <- utils::read.csv(ruta, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  r$minimo <- as.numeric(r$minimo); r$maximo <- as.numeric(r$maximo)
  r$minimo[r$variable == "RAINF"] <- 0     # sin rango numerico en el PDF: solo >= 0
  r$maximo[r$variable == "RAINF"] <- Inf
  r
}

temporada_regional <- function(fecha) {
  m <- as.integer(format(fecha, "%m"))
  ifelse(m %in% c(11, 12, 1, 2), "seca_fria", ifelse(m %in% 3:5, "seca_calida", "calida_humeda"))
}

# Malla continua por hoja (todos sus anios) con los valores originales.
malla_hoja <- function(datos_hoja) {
  anios <- sort(unique(datos_hoja$anio_archivo))
  partes <- lapply(anios, function(a) {
    m <- construir_malla(datos_hoja[datos_hoja$anio_archivo == a, ], a)
    list(malla = m$malla, X = m$X)
  })
  list(fecha = do.call(c, lapply(partes, `[[`, "malla")),
       X = do.call(rbind, lapply(partes, `[[`, "X")))
}

runs_identicos <- function(x) {   # longitud de la racha a la que pertenece cada hora
  r <- rle(x); rep(r$lengths, r$lengths)
}

limpiar_hoja <- function(datos_hoja, rangos_op, rangos_fab, red = NULL, solo_fase1 = FALSE) {
  hoja <- datos_hoja$hoja[1L]
  g <- malla_hoja(datos_hoja)
  fecha <- g$fecha; X <- g$X; n <- length(fecha)
  anio <- as.integer(format(fecha, "%Y"))
  FL <- matrix(ifelse(is.na(X), "N", "V"), n, ncol(X), dimnames = dimnames(X))
  invalidar <- function(v, mascara, codigo) {
    m <- mascara & FL[, v] %in% c("V", "C") & !is.na(X[, v])
    m[is.na(m)] <- FALSE
    X[m, v] <<- NA_real_; FL[m, v] <<- codigo
  }
  lim_op <- function(v) {
    i <- match(paste(v, anio), paste(rangos_op$variable, rangos_op$anio))
    list(lo = rangos_op$minimo[i], hi = rangos_op$maximo[i])
  }

  # Limites duros por hora (segun el anio de esa hora): contaminantes = operacion del anio;
  # RAINF = 0 al maximo de operacion; resto de meteorologia = fabricante.
  limites <- function(v) {
    if (v %in% CONTAMINANTES) return(lim_op(v))
    if (v == "RAINF") return(list(lo = 0, hi = lim_op(v)$hi))
    f <- rangos_fab[rangos_fab$variable == v, ]
    list(lo = f$minimo, hi = f$maximo)
  }
  # Incumple el rango duro o una nota del PDF (en su anio). Sirve para validar originales e imputados.
  incumple_rango <- function(v, x) {
    l <- limites(v)
    malo <- x < l$lo | x > l$hi
    for (k in which(NOTAS_PDF$variable == v)) {
      nt <- NOTAS_PDF[k, ]; lo <- lim_op(v)
      extra <- if (nt$tipo == "alto") x > lo$hi else x < lo$lo | x > lo$hi
      malo <- malo | (anio == nt$anio & extra)
    }
    if (v == "TOUT") malo <- malo | abs(x) >= SATURACION_TOUT
    malo[is.na(malo)] <- FALSE
    malo
  }
  # Nota 2020 O3: "omitir maximo de NTE2". Se identifica sobre la serie ORIGINAL, antes de
  # aplicar F; si ese maximo ya cae fuera de rango, F lo elimina y no se toca ningun otro valor.
  i_o3_nota <- NA_integer_
  if (hoja == "NTE2") {
    e <- which(anio == 2020 & !is.na(X[, "O3"]))
    if (length(e)) i_o3_nota <- e[which.max(X[e, "O3"])]
  }

  # F: rango duro
  for (v in VARIABLES_SIMA) {
    l <- limites(v)
    invalidar(v, X[, v] < l$lo | X[, v] > l$hi, "F")
  }
  # P: notas del PDF en sus anios (sobre el rango de operacion de ese anio)
  for (k in seq_len(nrow(NOTAS_PDF))) {
    nt <- NOTAS_PDF[k, ]; v <- nt$variable; l <- lim_op(v); en <- anio == nt$anio
    m <- if (nt$tipo == "alto") X[, v] > l$hi else X[, v] < l$lo | X[, v] > l$hi
    invalidar(v, en & m, "P")
  }
  if (!is.na(i_o3_nota)) invalidar("O3", seq_len(n) == i_o3_nota, "P")
  # L: saturacion del sensor de temperatura (lectura pegada al limite del fabricante)
  invalidar("TOUT", abs(X[, "TOUT"]) >= SATURACION_TOUT, "L")
  # S: salto horario de TOUT / PRS respecto de la hora previa valida
  for (v in names(SALTO_MAX)) {
    d <- c(NA_real_, diff(X[, v]))
    invalidar(v, abs(d) > SALTO_MAX[[v]], "S")
  }
  # R: PM2.5 > PM10 invalida ambas
  r <- !is.na(X[, "PM2.5"]) & !is.na(X[, "PM10"]) & X[, "PM2.5"] > X[, "PM10"]
  invalidar("PM2.5", r, "R"); invalidar("PM10", r, "R")
  # K / C: rachas de valores identicos
  for (v in VARIABLES_SIMA) {
    x <- X[, v]; largo <- runs_identicos(x)
    ok <- !is.na(x)
    if (v %in% c("SR", "RAINF")) ok <- ok & x != 0      # ceros nocturnos / horas secas
    marca <- ok & largo >= RACHA_MARCA_H
    if (v %in% VARS_RACHA_INVALIDA) {
      inv <- ok & largo >= RACHA_INVALIDA_H
      if (v == "RH") inv <- inv & x != 100
      invalidar(v, inv, "K")
      marca <- marca & !inv
    }
    FL[marca & FL[, v] == "V", v] <- "C"
  }

  # Fin de la fase 1: solo TOUT y RH observados (F, P, L, S, R y K aplicadas) para la mediana de la red.
  if (solo_fase1) return(list(fecha = fecha, X = X[, c("TOUT", "RH")]))
  # E: consistencia espacial sobre datos OBSERVADOS, antes de imputar. `red` lista, por variable,
  # las lecturas a quitar (punto fijo de la red) y la mediana/numero de estaciones final por hora.
  t_num <- as.numeric(fecha)
  if (!is.null(red)) for (v in c("TOUT", "RH")) {
    tq <- red[[v]]$quitar$t[red[[v]]$quitar$hoja == hoja]
    invalidar(v, t_num %in% tq, "E")
  }
  espacial_viola <- function(v, x) {   # para revalidar imputados contra la red observada
    if (is.null(red)) return(rep(FALSE, n))
    i <- match(t_num, red[[v]]$ref$t)
    m <- !is.na(x) & !is.na(i) & red[[v]]$ref$n[i] >= MIN_ESTACIONES_E &
      abs(x - red[[v]]$ref$mediana[i]) > UMBRAL_E[[v]]
    m[is.na(m)] <- FALSE
    m
  }

  # Inconsistencia NOX vs NO + NO2 (solo bandera; no invalida). Se calcula sobre lo observado
  # aqui (diagnostico) y otra vez sobre los valores finales, que es la que se publica.
  bandera_nox <- function(NOX, NO, NO2) {
    s <- NO + NO2; comp <- !is.na(NOX) & !is.na(s)
    b <- rep(NA_integer_, length(NOX))
    b[comp] <- as.integer(abs(NOX[comp] - s[comp]) > pmax(NOX_TOL_ABS_PPB, NOX_TOL_REL * NOX[comp]))
    b
  }
  nox_inc_obs <- bandera_nox(X[, "NOX"], X[, "NO"], X[, "NO2"])

  # Viento: componentes u/v en m/s desde WSR (km/h) y WDR (grados desde donde sopla)
  ok_w <- !is.na(X[, "WSR"]) & !is.na(X[, "WDR"])
  rad <- X[, "WDR"] * pi / 180
  U <- cbind(viento_u = ifelse(ok_w, -X[, "WSR"] / 3.6 * sin(rad), NA_real_),
             viento_v = ifelse(ok_w, -X[, "WSR"] / 3.6 * cos(rad), NA_real_))
  causa_w <- ifelse(FL[, "WSR"] %in% c("V", "C"), FL[, "WDR"], FL[, "WSR"])
  f_uv <- ifelse(ok_w, "V", ifelse(causa_w %in% c("V", "C"), "N", causa_w))
  V0 <- cbind(X, U)                    # validado, SIN imputar (para diagnosticar cobertura)
  flags0 <- cbind(FL, f_uv = f_uv)

  # Sensibilidad: horas conservadas que el rango de operacion estricto habria eliminado
  sens <- do.call(rbind, lapply(c("TOUT", "PRS"), function(v) {
    l <- lim_op(v); x <- V0[, v]
    data.frame(estacion = hoja, anio = anio, variable = v,
               valida = !is.na(x), bajo = !is.na(x) & x < l$lo, alto = !is.na(x) & x > l$hi)
  }))

  # I: interpolacion lineal de huecos internos <= 3 h (por estacion y variable)
  V1 <- V0; flags1 <- flags0
  IMP <- matrix(FALSE, n, ncol(V0), dimnames = dimnames(V0))
  for (v in VARS_IMPUTAR) {
    x <- V0[, v]
    if (sum(!is.na(x)) < 2L) next
    r <- rle(is.na(x)); fin <- cumsum(r$lengths); ini <- fin - r$lengths + 1L
    hueco <- which(r$values & r$lengths <= MAX_HUECO_H & ini > 1L & fin < n)
    if (!length(hueco)) next
    y <- imputeTS::na_interpolation(x, option = "linear", maxgap = MAX_HUECO_H)
    idx <- unlist(mapply(seq, ini[hueco], fin[hueco], SIMPLIFY = FALSE))
    idx <- idx[!is.na(y[idx])]
    V1[idx, v] <- y[idx]; IMP[idx, v] <- TRUE
  }
  # Revalidacion: un valor imputado que incumple una regla vuelve a NA (bandera X). Nunca se
  # modifica un valor original. Se repite hasta que ya no haya reversiones.
  revertida <- matrix(FALSE, n, ncol(V0), dimnames = dimnames(V0))
  revertir <- function(v, m) {
    m <- m & IMP[, v]; m[is.na(m)] <- FALSE
    if (any(m)) { V1[m, v] <<- NA_real_; IMP[m, v] <<- FALSE; revertida[m, v] <<- TRUE }
    any(m)
  }
  repeat {
    cambio <- FALSE
    for (v in setdiff(VARS_IMPUTAR, c("viento_u", "viento_v")))            # rango del anio de cada hora
      cambio <- revertir(v, incumple_rango(v, V1[, v])) || cambio
    for (v in c("TOUT", "RH"))                                              # consistencia espacial
      cambio <- revertir(v, espacial_viola(v, V1[, v])) || cambio
    for (v in names(SALTO_MAX)) {                                         # salto contra hora vecina
      x <- V1[, v]
      salto <- abs(c(NA_real_, diff(x))) > SALTO_MAX[[v]] | abs(c(diff(x), NA_real_)) > SALTO_MAX[[v]]
      cambio <- revertir(v, salto) || cambio
    }
    pm <- !is.na(V1[, "PM2.5"]) & !is.na(V1[, "PM10"]) & V1[, "PM2.5"] > V1[, "PM10"]  # PM2.5 <= PM10
    cambio <- revertir("PM2.5", pm) || cambio
    cambio <- revertir("PM10", pm) || cambio
    if (!cambio) break
  }
  for (v in VARS_IMPUTAR) {
    col <- if (v %in% c("viento_u", "viento_v")) "f_uv" else v
    flags1[IMP[, v], col] <- "I"
    flags1[revertida[, v], col] <- "X"
  }
  # se evalua sobre los valores redondeados a 3 decimales, que son los publicados
  nox_inc <- bandera_nox(round(V1[, "NOX"], 3), round(V1[, "NO"], 3), round(V1[, "NO2"], 3))
  list(fecha = fecha, anio = anio, obs = V0, imp = V1, flags_obs = flags0, flags = flags1,
       nox_inconsistente = nox_inc, nox_inconsistente_obs = nox_inc_obs, sens = sens[sens$valida, ])
}

# Agregado diario de una matriz horaria (n filas = 24 x dias, desde 00:00).
# Devuelve valores diarios y numero de horas validas por variable.
agregar_diario <- function(fecha, M) {
  nd <- length(fecha) / 24L
  dia <- as.Date(fecha[seq(1L, length(fecha), by = 24L)])
  agr <- function(x, f) {
    m <- matrix(x, nrow = 24L); nv <- colSums(!is.na(m))
    v <- f(m); v[nv < HORAS_MIN_DIA_LIMPIO] <- NA_real_
    list(v = v, n = nv)
  }
  media <- function(m) colSums(m, na.rm = TRUE) / pmax(colSums(!is.na(m)), 1)
  val <- list(); nh <- list()
  for (v in c("CO", "NO", "NO2", "NOX", "PM10", "PM2.5", "SO2", "TOUT", "RH", "SR", "PRS",
              "viento_u", "viento_v")) {
    a <- agr(M[, v], media); val[[v]] <- a$v; nh[[v]] <- a$n
  }
  # O3: maximo diario del promedio movil de 8 h (>= 6 de 8 horas), ventana por hora inicial
  x <- M[, "O3"]; ok <- !is.na(x)
  cs <- c(0, cumsum(ifelse(ok, x, 0))); cn <- c(0L, cumsum(ok))
  ini <- seq_len(length(x) - 7L)
  s8 <- cs[ini + 8L] - cs[ini]; n8 <- cn[ini + 8L] - cn[ini]
  prom <- rep(NA_real_, length(x)); prom[ini] <- ifelse(n8 >= 6L, s8 / n8, NA_real_)
  pm <- matrix(prom, nrow = 24L)
  mx <- suppressWarnings(apply(pm, 2L, max, na.rm = TRUE)); mx[!is.finite(mx)] <- NA_real_
  nvo <- colSums(matrix(ok, nrow = 24L)); mx[nvo < HORAS_MIN_DIA_LIMPIO] <- NA_real_
  val[["O3_max8h"]] <- mx; nh[["O3_max8h"]] <- nvo
  # RAINF: solo si llovio y cuantas horas (la cantidad no se usa: unidad sin confirmar)
  r <- M[, "RAINF"]; rm <- matrix(r, nrow = 24L); nvr <- colSums(!is.na(rm))
  hl <- colSums(rm > 0, na.rm = TRUE)
  val[["horas_lluvia"]] <- ifelse(nvr >= HORAS_MIN_DIA_LIMPIO, hl, NA_real_)
  val[["llovio"]] <- ifelse(nvr >= HORAS_MIN_DIA_LIMPIO, as.numeric(hl > 0), NA_real_)
  nh[["RAINF"]] <- nvr
  # Rapidez media del viento (m/s) desde u/v horarios
  rap <- matrix(sqrt(M[, "viento_u"]^2 + M[, "viento_v"]^2), nrow = 24L)
  nvw <- colSums(!is.na(rap))
  val[["viento_rapidez_ms"]] <- ifelse(nvw >= HORAS_MIN_DIA_LIMPIO, media(rap), NA_real_)
  list(dia = dia, valores = val, n_horas = nh)
}

# Variables (nombre diario) que definen cada nucleo de analisis.
NUCLEO_A <- c("PM10", "O3_max8h", "NO2", "CO", "SO2", "TOUT", "RH", "SR", "viento_u", "PRS", "RAINF")
NUCLEO_B <- c(NUCLEO_A, "PM2.5")


# Consistencia espacial de la red. `fase1`: lista por hoja con `fecha` y `X` (TOUT, RH observados
# tras F, P, L, S, R y K). Para cada hora se calcula la mediana de las estaciones que reportan; si
# reportan >= 5, se quita toda lectura a mas de UMBRAL_E de la mediana y se repite (punto fijo) hasta
# que no haya mas. Asi las lecturas observadas que quedan cumplen la regla respecto de SU mediana.
red_espacial <- function(fase1, umbral = UMBRAL_E) {
  salida <- list(); sens <- list()
  for (v in c("TOUT", "RH")) {
    d <- data.table::rbindlist(lapply(names(fase1), function(h) {
      x <- fase1[[h]]$X[, v]; k <- !is.na(x)
      data.table::data.table(hoja = h, t = as.numeric(fase1[[h]]$fecha[k]), x = x[k])
    }))
    d[, `:=`(n0 = .N, med0 = stats::median(x)), by = t]
    d[, dev0 := abs(x - med0)]
    sens[[v]] <- d[, .(hoja, t, n0, dev0)]
    d[, quitado := FALSE]
    repeat {
      est <- d[quitado == FALSE, .(n = .N, mediana = stats::median(x)), by = t]
      d[est, on = "t", `:=`(n_act = i.n, med_act = i.mediana)]
      viola <- !d$quitado & d$n_act >= MIN_ESTACIONES_E & abs(d$x - d$med_act) > umbral[[v]]
      if (!any(viola)) break
      d[viola, quitado := TRUE]
    }
    salida[[v]] <- list(ref = as.data.frame(est), quitar = as.data.frame(d[quitado == TRUE, .(hoja, t)]))
  }
  list(red = salida, sens = sens)
}
