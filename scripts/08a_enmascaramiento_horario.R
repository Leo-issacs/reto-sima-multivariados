# =============================================================================================
# Etapa 4, fase A1 (D19 de docs/etapa4/decisiones_etapa4.md): eleccion del metodo de imputacion
# HORARIA de la meteorologia por enmascaramiento, usando SOLO 2021-2023 (entrenamiento).
#
# Idea: en tramos de la serie que estan completos, borramos a proposito bloques de horas que SI
# conocemos, los imputamos con cada metodo y medimos el error contra el valor real. Gana el metodo
# que mejor reproduce el PROMEDIO DIARIO, que es lo que entra al modelo. La regla de decision es la
# de D19 con los cambios del "Registro de cambios de la fase A" de decisiones_etapa4.md (descalifica
# metodos que la revalidacion revierte, umbral con la DE de la anomalia y maxgap iterativo).
#
# Este script NO usa 2024-2025: si encuentra esos anios, se detiene.
#
# Ejecutar desde la raiz:  Rscript scripts/08a_enmascaramiento_horario.R
#   (opcional) SIMA_DATA_DIR="C:/ruta/a/los/BD_AAAA": comprueba ademas, con los Excel, que la serie
#   reconstruida desde los CSV es la serie limpia antes de imputar. Sin los Excel corre igual.
# Lee:     data/clean/sima_horario_limpio_2021..2023.csv, data/clean/muestra_pm25_2021_2025.csv
# Escribe: output/etapa4/imputacion/enmascaramiento_horario.csv (+ _por_estacion.csv),
#          eleccion_metodo_horario.csv, reversion_por_metodo.csv, rmse_por_metodo_y_hueco.png,
#          rmse_horario_por_metodo_y_hueco.png,
#          verificacion_serie_previa.csv (solo con los Excel), tiempos_enmascaramiento_horario.csv
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y carpetas ----------------------------------------------------
# imputeTS trae los metodos de imputacion de series de tiempo (Moritz y Bartz-Beielstein, 2017);
# R/limpieza.R tiene imputar_serie(), que es el MISMO despachador que usa la base v2 (08b), asi el
# metodo que se valida aqui es exactamente el que despues se aplica. parallel reparte el trabajo.
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(parallel)
})
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); source("R/imputacion.R")
SALIDA <- "output/etapa4/imputacion"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
SEMILLA <- 2026


# ---- Bloque 1. Datos horarios 2021-2023 SIN imputar ------------------------------------------------
# Partimos de los CSV horarios publicados y regresamos a NA las horas que la etapa 1 imputo (bandera
# I). Las horas invalidadas por las reglas fisicas (E, L, M) ya vienen vacias y nunca se imputan.
# PM2.5 entra solo como diagnostico (para ver si los metodos aplanan los picos); no decide nada.
# Se leen las 15 estaciones porque la red (mediana por hora de TOUT, RH y WSR) que revalida los
# imputados usa todas, igual que en la etapa 1; las series que se enmascaran son las de las 13.
ANIOS <- 2021:2023
EST <- estaciones_muestra()
VARS <- c(MET_HORARIA, "PM2.5")
h <- quitar_imputacion(leer_horario_csv(ANIOS))
if (any(as.integer(format(h$fecha, "%Y")) >= 2024)) stop("Hay horas de 2024-2025 en la fase A. Detente.", call. = FALSE)
red <- red_desde_csv(h)
series <- setNames(lapply(EST, function(e) {
  m <- matrices_hoja(h[estacion == e])
  list(fecha = m$fecha, X = m$V0[, VARS], V0 = m$V0)
}), EST)
n_horas_serie <- length(series[[1]]$fecha)
stopifnot(all(vapply(series, function(s) length(s$fecha), 1L) == n_horas_serie), n_horas_serie == 1095L * 24L)
rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()
rm(h); invisible(gc())


# ---- Bloque 2. (Opcional) comprobacion con los Excel ---------------------------------------------
# Si estan los Excel, repetimos la limpieza de la etapa 1 hasta antes de imputar y comparamos con la
# serie del bloque 1 (redondeada a 3 decimales, como se publica). Deben coincidir valor por valor y
# en las posiciones de los NA; si no, el script se detiene.
carpeta_excel <- Sys.getenv("SIMA_DATA_DIR", unset = "")
if (nzchar(carpeta_excel) && dir.exists(carpeta_excel)) {
  message("Comprobando la serie previa a imputar contra los Excel (unos minutos)...")
  ex <- serie_previa_excel(carpeta_excel, EST)
  verif <- rbindlist(lapply(EST, function(e) {
    en <- as.integer(format(ex[[e]]$fecha, "%Y")) %in% ANIOS
    stopifnot(identical(as.numeric(ex[[e]]$fecha[en]), as.numeric(series[[e]]$fecha)))
    rbindlist(lapply(VARS, function(v) {
      a <- ex[[e]]$obs[en, v]; b <- series[[e]]$X[, v]
      data.table(estacion = e, variable = v, horas = length(a),
                 na_distintos = sum(is.na(a) != is.na(b)),
                 valores_distintos = sum(!is.na(a) & !is.na(b) & abs(a - b) > 1e-9))
    }))
  }))
  escribir_csv(verif, file.path(SALIDA, "verificacion_serie_previa.csv"))
  if (any(verif$na_distintos > 0 | verif$valores_distintos > 0))
    stop("La serie reconstruida desde los CSV no coincide con la de los Excel. Ver verificacion_serie_previa.csv", call. = FALSE)
  message("Coinciden: la serie desde los CSV es la serie limpia antes de imputar.")
  rm(ex); invisible(gc())
} else {
  message("Sin SIMA_DATA_DIR: se usa la serie reconstruida desde los CSV (sin la comprobacion con los Excel).")
}


# ---- Bloque 3. Tramos completos y bloques a borrar ------------------------------------------------
# Para cada estacion y variable buscamos tramos SIN faltantes de al menos 72 h. Dentro de cada tramo
# borramos bloques de 1, 2, 3, 6, 12 o 24 h (un largo por corrida) que suman, en promedio, el 5 % de
# las horas del tramo. Reglas de colocacion:
#   - el bloque nunca toca la primera ni la ultima hora del tramo (el metodo siempre tiene un dato
#     real a cada lado, como en un hueco interno real);
#   - entre dos bloques queda al menos una hora observada (si no, dos bloques serian un hueco mas largo);
#   - el numero de bloques por tramo es 5 % x horas / largo, con redondeo aleatorio (por ejemplo, 0.15
#     bloques = un bloque con probabilidad 0.15), para que en promedio se borre el 5 % tambien en
#     tramos cortos con bloques largos.
# Las mascaras se generan aqui, en orden fijo, con las semillas 2026 a 2030 (una por repeticion).
LARGOS <- c(1L, 2L, 3L, 6L, 12L, 24L)
FRACCION <- 0.05
TRAMO_MIN_H <- 72L
SEMILLAS <- SEMILLA + 0:4

tramos_completos <- function(x) {
  r <- rle(!is.na(x)); fin <- cumsum(r$lengths); ini <- fin - r$lengths + 1L
  k <- r$values & r$lengths >= TRAMO_MIN_H
  data.frame(ini = ini[k], fin = fin[k])
}
colocar_bloques <- function(tr, L) {
  idx <- integer(); bloque <- integer(); b <- 0L
  for (j in seq_len(nrow(tr))) {
    a <- tr$ini[j]; z <- tr$fin[j]; largo <- z - a + 1L
    esperado <- FRACCION * largo / L
    nb <- floor(esperado) + as.integer(stats::runif(1) < esperado - floor(esperado))
    if (nb == 0L || largo - L < 2L) next
    ocupado <- rep(FALSE, largo)                 # posiciones del tramo ya borradas
    s_ok <- 2:(largo - L)                        # inicios que no tocan los bordes del tramo
    for (k in seq_len(nb)) {
      # inicio s (relativo al tramo) valido si las horas s-1 ... s+L estan libres; la suma acumulada
      # cuenta cuantas horas ocupadas hay en esa ventana sin recorrerla una por una
      cs <- c(0L, cumsum(ocupado))
      cand <- s_ok[cs[s_ok + L + 1L] - cs[s_ok - 1L] == 0L]
      if (!length(cand)) break
      s <- cand[sample.int(length(cand), 1L)]
      ocupado[s:(s + L - 1L)] <- TRUE
      b <- b + 1L
      idx <- c(idx, a - 1L + s:(s + L - 1L)); bloque <- c(bloque, rep(b, L))
    }
  }
  list(idx = idx, bloque = bloque)
}

tramos <- lapply(EST, function(e) lapply(setNames(VARS, VARS), function(v) tramos_completos(series[[e]]$X[, v])))
names(tramos) <- EST
tareas <- list()
for (sem in SEMILLAS) {
  set.seed(sem)
  for (e in EST) for (v in VARS) for (L in LARGOS) {
    cb <- colocar_bloques(tramos[[e]][[v]], L)
    if (length(cb$idx)) tareas[[length(tareas) + 1L]] <- list(estacion = e, variable = v, semilla = sem,
                                                             largo = L, idx = cb$idx, bloque = cb$bloque)
  }
}
resumen_tramos <- rbindlist(lapply(EST, function(e) rbindlist(lapply(VARS, function(v) {
  tr <- tramos[[e]][[v]]
  data.table(estacion = e, variable = v, tramos = nrow(tr), horas_en_tramos = sum(tr$fin - tr$ini + 1L))
}))))
message(sprintf("Tareas de enmascaramiento: %d (estacion x variable x semilla x largo).", length(tareas)))


# ---- Bloque 4. Imputar cada serie enmascarada con los 7 metodos -------------------------------------
# Metodos (los recomendados por las fuentes de la clase; ver D19):
#   linear, spline, stine = na_interpolation; ma_exp = na_ma(k = 4, exponencial);
#   kalman = na_kalman(StructTS, suavizado) sobre la serie completa 2021-2023 de la estacion;
#   seadec = na_seadec sobre un ts de frecuencia 24 (ciclo diario); locf = piso de referencia.
# Cada metodo imputa la serie COMPLETA de la estacion (con sus faltantes reales), pero solo se evalua
# en las horas que borramos. Para cada tarea guardamos sumas (n, error, error^2, |error|), que luego
# se combinan entre estaciones y semillas para dar RMSE, MAE y sesgo agrupados.
# Error diario: en cada dia que contiene horas borradas, promedio con los imputados menos promedio
# real del mismo dia (mismas horas observadas; el dia debe tener >= 18 h, como en el diario).
# PM2.5: ademas, error en el maximo horario de cada bloque (negativo = el metodo aplana el pico).
# Reversion: los imputados se revalidan con las MISMAS reglas que la base v2 (revalidar_imputados(),
# de R/limpieza.R) y se cuenta cuantos regresarian a NA (bandera X). El error se mide sobre los
# valores sin revalidar; la reversion sirve para descalificar metodos (bloque 6).
METODOS <- c("linear", "spline", "stine", "ma_exp", "kalman", "seadec", "locf")

# Reglas por hora de cada estacion (rangos del anio, red, hora del dia); se arman una vez por proceso.
cache_rg <- new.env()
obtener_rg <- function(e) {
  if (is.null(cache_rg[[e]])) assign(e, reglas_hoja(series[[e]]$fecha, rangos_op, rangos_fab, red), envir = cache_rg)
  cache_rg[[e]]
}

# na_ma es muy lento en series con apagones largos (agranda su ventana punto por punto). Como es un
# metodo LOCAL, el valor en una hora borrada solo depende de lo observado a menos de max(4, largo) h
# (el bloque siempre tiene un dato real a cada lado), asi que lo calculamos en ventanas de +-48 h
# alrededor de los bloques: da exactamente el mismo resultado que sobre la serie completa (se
# comprueba en la primera tarea, abajo) y tarda segundos en vez de minutos.
imputar_en_ventanas <- function(xm, idx, metodo, margen = 48L) {
  n <- length(xm); y <- rep(NA_real_, n)
  r <- rle(seq_len(n) %in% idx); fin <- cumsum(r$lengths); ini <- fin - r$lengths + 1L
  a <- pmax(1L, ini[r$values] - margen); b <- pmin(n, fin[r$values] + margen)
  grupo <- cumsum(c(TRUE, a[-1] > b[-length(b)] + 1L))      # une ventanas que se enciman
  for (g in unique(grupo)) {
    w <- min(a[grupo == g]):max(b[grupo == g])
    y[w] <- imputar_serie(xm[w], metodo)
  }
  y
}

evaluar_tarea <- function(t) {
  x <- series[[t$estacion]]$X[, t$variable]
  xm <- x; xm[t$idx] <- NA_real_
  dia <- (seq_along(x) - 1L) %/% 24L
  dias_t <- unique(dia[t$idx])
  en_dia <- dia %in% dias_t
  verdad_dia <- tapply(x[en_dia], dia[en_dia], function(z) if (sum(!is.na(z)) >= HORAS_MIN_DIA_LIMPIO) mean(z, na.rm = TRUE) else NA_real_)
  rbindlist(lapply(METODOS, function(m) {
    t0 <- proc.time()[["elapsed"]]
    y <- tryCatch(suppressWarnings(
      if (m == "ma_exp") imputar_en_ventanas(xm, t$idx, m) else imputar_serie(xm, m)), error = function(e) NULL)
    seg <- proc.time()[["elapsed"]] - t0
    if (is.null(y)) return(data.table(metodo = m, fallo = 1L, segundos = seg))
    e_h <- y[t$idx] - x[t$idx]
    z <- x; z[t$idx] <- y[t$idx]                  # solo se reemplazan las horas borradas
    imp_dia <- tapply(z[en_dia], dia[en_dia], function(w) mean(w, na.rm = TRUE))
    e_d <- (imp_dia - verdad_dia)[!is.na(verdad_dia)]
    # Revalidacion: los imputados van a la matriz completa de la estacion (las demas variables con sus
    # valores observados) y se cuenta cuantos revierten las reglas.
    V1 <- series[[t$estacion]]$V0; V1[t$idx, t$variable] <- y[t$idx]
    IMP <- matrix(FALSE, nrow(V1), ncol(V1), dimnames = dimnames(V1)); IMP[t$idx, t$variable] <- TRUE
    n_rev <- sum(revalidar_imputados(V1, IMP, obtener_rg(t$estacion))$revertida[t$idx, t$variable])
    fila <- data.table(metodo = m, fallo = 0L, segundos = seg,
                       n_h = length(e_h), s_h = sum(e_h), s2_h = sum(e_h^2), sa_h = sum(abs(e_h)),
                       n_d = length(e_d), s_d = sum(e_d), s2_d = sum(e_d^2), sa_d = sum(abs(e_d)),
                       n_b = length(unique(t$bloque)), n_rev = n_rev)
    if (t$variable == "PM2.5") {
      p_real <- tapply(x[t$idx], t$bloque, max); p_imp <- tapply(y[t$idx], t$bloque, max)
      ep <- p_imp - p_real
      fila[, `:=`(s_p = sum(ep), s2_p = sum(ep^2), n_sub = sum(ep < 0))]
    }
    fila
  }), fill = TRUE)[, `:=`(estacion = t$estacion, variable = t$variable, semilla = t$semilla, largo = t$largo)]
}

# Comprobacion de la equivalencia de las ventanas en una tarea de TOUT (serie completa vs ventanas).
t_prueba <- Filter(function(t) t$variable == "TOUT" && t$largo == 24L, tareas)[[1]]
x_prueba <- series[[t_prueba$estacion]]$X[, "TOUT"]; x_prueba[t_prueba$idx] <- NA_real_
stopifnot(isTRUE(all.equal(imputar_serie(x_prueba, "ma_exp")[t_prueba$idx],
                           imputar_en_ventanas(x_prueba, t_prueba$idx, "ma_exp")[t_prueba$idx], tolerance = 1e-12)))

n_nucleos <- max(1L, min(12L, parallel::detectCores() - 2L))
message(sprintf("Imputando con %d procesos en paralelo...", n_nucleos))
t_inicio <- Sys.time()
# Los procesos arrancan sin .Rprofile (no activan renv cada uno, que con 12 a la vez tarda tanto que
# algunos no alcanzan a conectarse) y reciben la biblioteca del proyecto en .libPaths().
cl <- makeCluster(n_nucleos, rscript_args = "--no-init-file")
clusterCall(cl, function(wd, lp) { setwd(wd); .libPaths(lp); invisible(NULL) }, getwd(), .libPaths())
clusterEvalQ(cl, { suppressPackageStartupMessages(library(data.table))
  source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); NULL })
clusterExport(cl, c("series", "METODOS", "evaluar_tarea", "imputar_en_ventanas", "red", "rangos_op",
                    "rangos_fab", "cache_rg", "obtener_rg"))
res <- rbindlist(parLapplyLB(cl, tareas, evaluar_tarea), fill = TRUE)
stopCluster(cl)
minutos <- as.numeric(difftime(Sys.time(), t_inicio, units = "mins"))
message(sprintf("Listo en %.1f min.", minutos))
fallos <- res[fallo == 1L, .N, by = .(variable, metodo)]
if (nrow(fallos)) print(fallos)


# ---- Bloque 5. Metricas agrupadas por variable x metodo x largo de hueco ---------------------------
# RMSE = raiz del error cuadratico medio; MAE = error absoluto medio; sesgo = error medio (imputado
# menos real). "Horario" se mide en cada hora borrada; "diario", en el promedio del dia.
agrupar <- function(d, por) d[fallo == 0L, .(
  tareas = .N, n_bloques = sum(n_b), n_horas = sum(n_h), n_dias = sum(n_d),
  rmse_horario = sqrt(sum(s2_h) / sum(n_h)), mae_horario = sum(sa_h) / sum(n_h), sesgo_horario = sum(s_h) / sum(n_h),
  rmse_diario = sqrt(sum(s2_d) / sum(n_d)), mae_diario = sum(sa_d) / sum(n_d), sesgo_diario = sum(s_d) / sum(n_d),
  n_revertidas = sum(n_rev), pct_reversion = 100 * sum(n_rev) / sum(n_h),
  pico_sesgo = if (all(is.na(s_p))) NA_real_ else sum(s_p) / sum(n_b),
  pico_rmse = if (all(is.na(s2_p))) NA_real_ else sqrt(sum(s2_p) / sum(n_b)),
  pico_pct_subestima = if (all(is.na(n_sub))) NA_real_ else 100 * sum(n_sub) / sum(n_b)), by = por]
tabla <- agrupar(res, c("variable", "metodo", "largo"))
tabla <- merge(tabla, res[, .(fallos = sum(fallo)), by = .(variable, metodo, largo)], by = c("variable", "metodo", "largo"))
setnames(tabla, "largo", "largo_hueco_h")
tabla[, variable := factor(variable, levels = VARS)][, metodo := factor(metodo, levels = METODOS)]
setorder(tabla, variable, largo_hueco_h, metodo)
tabla[, `:=`(variable = as.character(variable), metodo = as.character(metodo))]
por_estacion <- agrupar(res, c("estacion", "variable", "metodo", "largo"))
setnames(por_estacion, "largo", "largo_hueco_h")


# ---- Bloque 6. Regla de decision (D19 con el registro de cambios de la fase A) ---------------------
# Por variable, en este orden:
#   a) Se descalifica todo metodo cuyas imputaciones revierte la revalidacion en mas de 5 % (sobre
#      todas las horas borradas, de todos los largos).
#   b) Umbral para cada largo L: RMSE del promedio diario <= 0.10 x la DE diaria de la ANOMALIA de la
#      variable (valor menos la media de su estacion en el entrenamiento). Asi el umbral no incluye las
#      diferencias entre estaciones (la altitud, en la presion), que M1 no usa.
#   c) maxgap inicial = el mayor L en que el mejor metodo no descalificado (el de menor RMSE en ese L)
#      cumple el umbral. Ganador = el metodo con menor RMSE diario promedio SOLO en los largos <= maxgap.
#      Se recalcula el maxgap con ese ganador y se repite hasta que no cambie.
#   d) Si la lineal (no descalificada) queda a menos de 5 % del ganador en los largos <= maxgap, se usa
#      la lineal; se comprueba y se reporta si la lineal tambien cumple el umbral hasta ese maxgap.
# "Cumple hasta L" exige que se cumpla en L y en todos los largos menores; como el RMSE crece con el
# largo, coincide con tomar el mayor L que cumple (el script lo comprueba). maxgap = 0: no se imputa.
# La DE de la anomalia sale de la muestra de entrenamiento de la etapa 3 (datos-v1.2, 2021-2023).
UMBRAL_REVERSION <- 5      # % maximo de imputaciones revertidas
TOL_LINEAL <- 5            # % de ventaja minima para no quedarse con la lineal
entrena <- fread("data/clean/muestra_pm25_2021_2025.csv")[anio <= 2023]
stopifnot(nrow(entrena) == 10170L)
de_anomalia <- vapply(MET_HORARIA, function(v) sd(entrena[[v]] - ave(entrena[[v]], entrena$estacion)), numeric(1))
de_cruda <- vapply(MET_HORARIA, function(v) sd(entrena[[v]]), numeric(1))

reversion <- res[fallo == 0L, .(imputadas = sum(n_h), revertidas = sum(n_rev)), by = .(variable, metodo)]
reversion[, pct_reversion := 100 * revertidas / imputadas]
reversion[, descalificado := pct_reversion > UMBRAL_REVERSION]

# Mayor largo L tal que el RMSE cumple el umbral en L y en todos los largos menores (r ordenado por L).
hasta_donde <- function(r, umbral) {
  ok <- r <= umbral
  if (!ok[1]) return(0L)
  LARGOS[max(which(cumsum(!ok) == 0L))]
}
eleccion <- rbindlist(lapply(MET_HORARIA, function(v) {
  umbral <- 0.10 * de_anomalia[[v]]
  rv <- reversion[variable == v]
  elegibles <- rv[descalificado == FALSE, metodo]
  R <- dcast(tabla[variable == v & metodo %in% elegibles], largo_hueco_h ~ metodo, value.var = "rmse_diario")
  setorder(R, largo_hueco_h); stopifnot(identical(R$largo_hueco_h, LARGOS))
  M <- as.matrix(R[, -"largo_hueco_h"])
  mejor_L <- apply(M, 1L, min)
  mg <- hasta_donde(mejor_L, umbral)
  literal <- if (any(mejor_L <= umbral)) LARGOS[max(which(mejor_L <= umbral))] else 0L
  historial <- mg; ganador <- NA_character_; ciclo <- FALSE
  while (mg > 0L) {
    medias <- colMeans(M[LARGOS <= mg, , drop = FALSE])
    ganador <- names(medias)[which.min(medias)]
    mg_nuevo <- hasta_donde(M[, ganador], umbral)
    if (mg_nuevo == mg) break
    if (mg_nuevo %in% historial) { ciclo <- TRUE; mg <- mg_nuevo; break }
    historial <- c(historial, mg_nuevo); mg <- mg_nuevo
  }
  if (mg == 0L) ganador <- NA_character_
  r_gan <- if (mg > 0L) mean(M[LARGOS <= mg, ganador]) else NA_real_
  lineal_ok <- "linear" %in% elegibles
  r_lin <- if (mg > 0L && lineal_ok) mean(M[LARGOS <= mg, "linear"]) else NA_real_
  dif_pct <- 100 * (r_lin - r_gan) / r_gan
  elegido <- if (mg == 0L) "ninguno" else if (lineal_ok && (ganador == "linear" || dif_pct < TOL_LINEAL)) "linear" else ganador
  lin_cumple <- if (elegido == "linear") all(M[LARGOS <= mg, "linear"] <= umbral) else NA
  motivo <- if (mg == 0L) "ningun metodo cumple el umbral ni en 1 h: no se imputa" else
    if (ganador == "linear") "la lineal tiene el menor RMSE diario medio en los largos <= maxgap" else
      if (elegido == "linear") sprintf("gana %s, pero la lineal queda a %.1f %% (< 5 %%): se usa la lineal", ganador, dif_pct) else
        sprintf("gana %s; la lineal queda a %.1f %% (>= 5 %%)%s", ganador, dif_pct, if (lineal_ok) "" else " (lineal descalificada)")
  data.table(variable = v, metodos_descalificados = paste(rv[descalificado == TRUE, metodo], collapse = ";"),
             de_cruda_entrenamiento = de_cruda[[v]], de_anomalia_entrenamiento = de_anomalia[[v]],
             umbral_rmse_diario = umbral, maxgap_inicial_h = historial[1], historial_maxgap = paste(historial, collapse = "->"),
             ciclo = ciclo, coincide_lectura_literal = literal == historial[1],
             ganador_iterativo = ganador, maxgap_h = mg, rmse_diario_medio_ganador = r_gan, rmse_diario_medio_lineal = r_lin,
             lineal_sobre_ganador_pct = dif_pct, metodo_elegido = elegido,
             pct_reversion_elegido = if (elegido == "ninguno") NA_real_ else rv[metodo == elegido, pct_reversion],
             lineal_cumple_umbral_hasta_maxgap = lin_cumple, motivo = motivo,
             rmse_diario_elegido_en_maxgap = if (mg > 0L) M[LARGOS == mg, elegido] else NA_real_)
}))
if (any(eleccion$ciclo) || !all(eleccion$coincide_lectura_literal) || any(eleccion$lineal_cumple_umbral_hasta_maxgap %in% FALSE))
  warning("Revisar eleccion_metodo_horario.csv: ciclo, lectura literal distinta o lineal fuera del umbral.", call. = FALSE)
print(eleccion[, .(variable, metodos_descalificados, historial_maxgap, ganador_iterativo, maxgap_h, lineal_sobre_ganador_pct, metodo_elegido)])


# ---- Bloque 7. Figuras ------------------------------------------------------------------------------
# Paneles por variable: RMSE del promedio diario (lo que decide) y RMSE horario, por metodo y largo de
# hueco. La linea punteada es el umbral (0.10 x DE diaria de la anomalia); PM2.5 no tiene umbral.
COLORES <- c(linear = "#000000", spline = "#E69F00", stine = "#56B4E9", ma_exp = "#009E73",
             kalman = "#D55E00", seadec = "#0072B2", locf = "#999999")
umbrales <- data.table(variable = MET_HORARIA, umbral = 0.10 * de_anomalia)
graficar <- function(col, titulo, eje, con_umbral) {
  d <- copy(tabla)[, variable := factor(variable, levels = VARS)][, metodo := factor(metodo, levels = METODOS)]
  g <- ggplot(d, aes(largo_hueco_h, .data[[col]], colour = metodo)) +
    geom_line(linewidth = 0.5) + geom_point(size = 1.2) +
    scale_x_continuous(trans = "log2", breaks = LARGOS) +
    scale_y_log10() +                                  # la spline se dispara en RH: sin log no se ve el resto
    scale_colour_manual(values = COLORES, name = "Método") +
    facet_wrap(~variable, scales = "free_y", ncol = 4) +
    labs(x = "Largo del hueco borrado (h, escala log2)", y = paste(eje, "(escala log)"), title = titulo,
         subtitle = "Enmascaramiento en tramos completos de 2021–2023, 13 estaciones, 5 semillas") +
    theme_minimal(base_size = 10) + theme(legend.position = "bottom")
  if (con_umbral) g <- g + geom_hline(data = umbrales[, variable := factor(variable, levels = VARS)],
                                      aes(yintercept = umbral), linetype = "dotted", colour = "#B22222")
  g
}
ggsave(file.path(SALIDA, "rmse_por_metodo_y_hueco.png"),
       graficar("rmse_diario", "RMSE del promedio diario según método y largo del hueco", "RMSE del promedio diario", TRUE),
       width = 9, height = 5.2, dpi = 150)
ggsave(file.path(SALIDA, "rmse_horario_por_metodo_y_hueco.png"),
       graficar("rmse_horario", "RMSE horario según método y largo del hueco", "RMSE horario", FALSE),
       width = 9, height = 5.2, dpi = 150)


# ---- Bloque 8. Salidas -------------------------------------------------------------------------------
# Tabla principal, detalle por estacion, eleccion y tiempos de corrida (Kalman sobre la serie completa
# de la estacion: no hizo falta usar ventanas mensuales).
escribir_csv(tabla, file.path(SALIDA, "enmascaramiento_horario.csv"))
escribir_csv(por_estacion, file.path(SALIDA, "enmascaramiento_horario_por_estacion.csv"))
escribir_csv(eleccion, file.path(SALIDA, "eleccion_metodo_horario.csv"))
escribir_csv(reversion[order(variable, metodo)], file.path(SALIDA, "reversion_por_metodo.csv"))
escribir_csv(resumen_tramos, file.path(SALIDA, "tramos_completos_2021_2023.csv"))
tiempos <- res[, .(llamadas = .N, segundos_total = sum(segundos), segundos_por_serie = mean(segundos)), by = metodo]
tiempos <- rbind(tiempos, data.table(metodo = "total (reloj, en paralelo)", llamadas = nrow(res),
                                     segundos_total = 60 * minutos, segundos_por_serie = NA_real_))
escribir_csv(tiempos, file.path(SALIDA, "tiempos_enmascaramiento_horario.csv"))
message("Listo: ", SALIDA)
