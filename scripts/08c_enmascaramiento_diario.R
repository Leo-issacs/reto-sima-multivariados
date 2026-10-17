# =============================================================================================
# Etapa 4, fase A3 (D20 de docs/etapa4/decisiones_etapa4.md): validacion por enmascaramiento de la
# imputacion DIARIA de la meteorologia, usando SOLO 2021-2023.
#
# En dias con las 8 meteorologicas completas borramos valores que si conocemos, imitando el patron
# real de faltantes de los dias que MICE tendria que imputar, y comparamos tres metodos:
#   1. MICE con predictive mean matching (pmm), m = 5 (van Buuren y Groothuis-Oudshoorn, 2011).
#      Predictores: la mediana de la red ese dia para cada variable, las otras meteorologicas de la
#      estacion, estacion, temporada y anio. SIN PM2.5 ni supera_25.
#   2. La mediana de la red ajustada por la diferencia media de la estacion.
#   3. La media de estacion x temporada.
# Regla de D20: si MICE no gana, se usa el metodo que gane, con una sola imputacion.
#
# Este script NO usa 2024-2025: si encuentra esos anios, se detiene. No ajusta LDA ni calcula AUC.
#
# Ejecutar desde la raiz:  Rscript scripts/08c_enmascaramiento_diario.R   (no necesita los Excel)
# Lee:     data/clean/v2/diario_v2_2021_2025.csv, output/etapa4/imputacion/patrones_faltantes_2021_2023.csv
# Escribe: output/etapa4/imputacion/enmascaramiento_diario.csv (+ _por_imputacion.csv)
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas -----------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(mice)
})
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); source("R/imputacion.R")
SALIDA <- "output/etapa4/imputacion"
SEMILLA <- 2026
M_VALIDACION <- 5L


# ---- Bloque 1. Datos: base v2, solo 2021-2023 -------------------------------------------------------
# `todo` tiene todos los estacion-dias de 2021-2023 (sirve para la mediana de la red: cada dia usa
# lo que reportaron las demas estaciones, esten completas o no). `base` son los dias con las 8
# meteorologicas completas: ahi conocemos el valor real y podemos borrar y comparar.
todo <- fread("data/clean/v2/diario_v2_2021_2025.csv")[anio <= 2023]
if (any(todo$anio >= 2024)) stop("Hay filas de 2024-2025 en la fase A. Detente.", call. = FALSE)
todo[, (MET_DIARIA) := lapply(.SD, as.numeric), .SDcols = MET_DIARIA]   # horas_lluvia es entera
todo[, id := .I]
base_ids <- todo[met_completa == 1L, id]
message(sprintf("Dias 2021-2023 con meteorologia completa: %s", format(length(base_ids), big.mark = ",")))


# ---- Bloque 2. Enmascaramiento con el patron real de faltantes ---------------------------------------
# Entre los dias con respuesta valida de 2021-2023, una fraccion p tiene de 1 a 4 meteorologicas
# faltantes (los candidatos a MICE). Borramos esa misma fraccion de los dias completos y, a cada dia
# elegido, le asignamos un patron real (que variables faltan juntas) sorteado con su frecuencia en
# 2021-2023 (tabla de 08b). Asi se reproducen las proporciones por variable de la tabla A2 y tambien
# que, por ejemplo, u, v y la rapidez del viento faltan siempre juntas.
patrones <- fread(file.path(SALIDA, "patrones_faltantes_2021_2023.csv"))
stopifnot(setequal(setdiff(names(patrones), "N"), MET_DIARIA))
p_falta <- todo[respuesta_valida == 1L, sum(candidato_mice) / (sum(candidato_mice) + sum(met_completa))]
set.seed(SEMILLA)
n_borrar <- round(p_falta * length(base_ids))
dias_borrar <- base_ids[sample.int(length(base_ids), n_borrar)]
patron_dia <- sample.int(nrow(patrones), n_borrar, replace = TRUE, prob = patrones$N)
real <- copy(todo)                             # valores verdaderos
mascara <- matrix(FALSE, nrow(todo), length(MET_DIARIA), dimnames = list(NULL, MET_DIARIA))
for (j in seq_along(MET_DIARIA)) mascara[dias_borrar, j] <- patrones[[MET_DIARIA[j]]][patron_dia] == 1L
enm <- copy(todo)
for (v in MET_DIARIA) set(enm, which(mascara[, v]), v, NA_real_)
resumen_mascara <- data.table(variable = MET_DIARIA, celdas_borradas = colSums(mascara),
                              pct_de_dias_completos = round(100 * colSums(mascara) / length(base_ids), 2))
message(sprintf("Fraccion de dias con faltantes entre los de respuesta valida: %.3f; dias enmascarados: %d", p_falta, n_borrar))
print(resumen_mascara)


# ---- Bloque 3. Mediana de la red de cada dia (sin la propia estacion) ---------------------------------
# Para cada variable y dia, mediana de las OTRAS estaciones que reportan ese dia. Se excluye la propia
# estacion: si se incluyera, al ajustar MICE en los dias observados el predictor contendria el valor que
# se quiere predecir, y en los dias faltantes no; el modelo de imputacion quedaria mal calibrado.
mediana_red <- function(d, v) {
  w <- dcast(d[, .(fecha, estacion, x = get(v))], fecha ~ estacion, value.var = "x")
  est <- setdiff(names(w), "fecha")
  M <- as.matrix(w[, ..est])
  L <- vapply(seq_along(est), function(j) apply(M[, -j, drop = FALSE], 1L, function(z) if (all(is.na(z))) NA_real_ else stats::median(z, na.rm = TRUE)),
              numeric(nrow(M)))
  colnames(L) <- est
  out <- melt(data.table(fecha = w$fecha, L), id.vars = "fecha", variable.name = "estacion", value.name = "med")
  out[, estacion := as.character(estacion)]
  merge(d[, .(id, fecha, estacion)], out, by = c("fecha", "estacion"), all.x = TRUE)[order(id), med]
}
for (v in MET_DIARIA) enm[[paste0("red_", v)]] <- mediana_red(enm, v)
RED <- paste0("red_", MET_DIARIA)


# ---- Bloque 4. Metodo 1: MICE (pmm, m = 5) --------------------------------------------------------------
# MICE se ajusta sobre los dias completos ya enmascarados (los unicos donde sabemos la verdad). Cada
# meteorologica faltante se predice con las otras 7 de la estacion, las 8 medianas de la red, la
# estacion, la temporada y el anio. Si alguna mediana de la red falta (ninguna otra estacion reporto),
# MICE tambien la imputa, solo como predictor auxiliar. pmm toma valores observados reales de los
# "donantes" mas parecidos, asi que nunca inventa valores fuera del rango observado.
dm <- enm[id %in% base_ids, c("id", MET_DIARIA, RED, "estacion", "temporada", "anio"), with = FALSE]
dm[, `:=`(estacion = factor(estacion), temporada = factor(temporada), anio = factor(anio))]
datos_mice <- as.data.frame(dm[, -"id"])
metodo <- make.method(datos_mice)                    # pmm para toda variable numerica con faltantes
pred <- make.predictorMatrix(datos_mice)             # cada variable usa a todas las demas
message(sprintf("Medianas de la red faltantes: %d celdas.", sum(is.na(dm[, ..RED]))))
# Ojo: por defecto mice quita, en cada iteracion, todo predictor con correlacion > 0.99 con la variable
# que imputa (remove.lindep, maxcor = 0.99). La temperatura diaria es casi comun en la ciudad, asi que
# con ese valor mice descarta justo la mediana de la red de TOUT, que D20 pide como predictor. Subimos
# el limite a 0.9999: sigue protegiendo contra columnas duplicadas, pero respeta los predictores de D20.
# Correlacion cruda (la que ve mice) y dentro de cada estacion (quitando la media de la estacion, que en
# PRS es sobre todo la altitud): la segunda es la que D20 cita para la presion (0.96-0.99).
dentro <- function(x, g) x - ave(x, g, FUN = function(z) mean(z, na.rm = TRUE))
cor_red <- data.table(variable = MET_DIARIA,
  cor_con_mediana_red = vapply(MET_DIARIA, function(v) stats::cor(dm[[v]], dm[[paste0("red_", v)]], use = "complete.obs"), numeric(1)),
  cor_dentro_de_estacion = vapply(MET_DIARIA, function(v) stats::cor(dentro(dm[[v]], dm$estacion),
    dentro(dm[[paste0("red_", v)]], dm$estacion), use = "complete.obs"), numeric(1)))
print(cor_red)
t0 <- Sys.time()
imp <- mice(datos_mice, m = M_VALIDACION, method = metodo, predictorMatrix = pred, seed = SEMILLA, printFlag = FALSE,
            maxcor = 0.9999)
minutos_mice <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("MICE listo en %.1f min. Eventos registrados: %d", minutos_mice, if (is.null(imp$loggedEvents)) 0L else nrow(imp$loggedEvents)))
completos <- lapply(seq_len(M_VALIDACION), function(k) as.data.table(complete(imp, k))[, id := dm$id])


# ---- Bloque 5. Metodos 2 y 3: referencias simples ------------------------------------------------------
# 2. Mediana de la red (sin la estacion) + la diferencia media de la estacion respecto de esa mediana,
#    calculada con los valores observados (no borrados) de los dias completos.
# 3. Media de la estacion x temporada, con los mismos valores observados.
# Si la mediana de la red falta en una celda borrada, el metodo 2 no puede imputarla: se cuenta y se
# reporta (no se rellena con otro metodo).
obs <- enm[id %in% base_ids]
ref_red <- list(); ref_media <- list()
for (v in MET_DIARIA) {
  rv <- paste0("red_", v)
  dif <- obs[!is.na(get(v)) & !is.na(get(rv)), .(dif = mean(get(v) - get(rv))), by = estacion]
  z <- merge(enm[, .(id, estacion, med = get(rv))], dif, by = "estacion", all.x = TRUE)[order(id)]
  ref_red[[v]] <- z$med + z$dif
  mt <- obs[!is.na(get(v)), .(media = mean(get(v))), by = .(estacion, temporada)]
  ref_media[[v]] <- merge(enm[, .(id, estacion, temporada)], mt, by = c("estacion", "temporada"), all.x = TRUE)[order(id), media]
}


# ---- Bloque 6. Metricas por variable ------------------------------------------------------------------
# En las celdas borradas: RMSE y MAE de cada metodo contra el valor real. Para MICE se reportan dos
# lecturas, porque no miden lo mismo:
#   - "mice_por_imputacion": el error de CADA base imputada (promedio de los 5 RMSE). Es el error de
#     los valores con que se ajustaria cada modelo; incluye el ruido que pmm agrega a proposito para
#     reflejar la incertidumbre de imputar.
#   - "mice_promedio_m": el error del promedio de las 5 imputaciones (se acerca a la mejor prediccion
#     puntual de MICE, sin ese ruido).
# rmse_rel = RMSE / DE de la variable en los dias completos (antes de borrar), para poder promediar
# entre variables con unidades distintas.
rm_ <- function(e) sqrt(mean(e^2, na.rm = TRUE)); ma_ <- function(e) mean(abs(e), na.rm = TRUE)
partes <- lapply(MET_DIARIA, function(v) {
  k <- which(mascara[, v]); y <- real[[v]][k]; de <- sd(real[[v]][base_ids])
  m_imp <- vapply(completos, function(cc) cc[[v]][match(todo$id[k], cc$id)], numeric(length(k)))
  por_imp <- data.table(variable = v, imputacion = seq_len(M_VALIDACION),
                        rmse = apply(m_imp, 2L, function(z) rm_(z - y)), mae = apply(m_imp, 2L, function(z) ma_(z - y)))
  r2 <- ref_red[[v]][k]; r3 <- ref_media[[v]][k]
  tab <- data.table(variable = v, metodo = c("mice_por_imputacion", "mice_promedio_m", "red_ajustada", "media_estacion_temporada"),
                    celdas = length(k), celdas_sin_imputar = c(0L, 0L, sum(is.na(r2)), sum(is.na(r3))),
                    rmse = c(mean(por_imp$rmse), rm_(rowMeans(m_imp) - y), rm_(r2 - y), rm_(r3 - y)),
                    mae = c(mean(por_imp$mae), ma_(rowMeans(m_imp) - y), ma_(r2 - y), ma_(r3 - y)),
                    sesgo = c(mean(m_imp - y), mean(rowMeans(m_imp) - y), mean(r2 - y, na.rm = TRUE), mean(r3 - y, na.rm = TRUE)),
                    de_variable = de)
  tab[, rmse_rel := rmse / de]
  list(tab = tab, por_imp = por_imp)
})
metricas <- rbindlist(lapply(partes, `[[`, "tab"))
por_imputacion <- rbindlist(lapply(partes, `[[`, "por_imp"))
print(dcast(metricas, variable ~ metodo, value.var = "rmse"))


# ---- Bloque 7. Regla de D20 --------------------------------------------------------------------------
# "Gana" el metodo con menor RMSE relativo promedio en las 8 variables (cada variable pesa igual), y se
# reporta tambien el ganador por variable. D20 no dice cual de las dos lecturas de MICE usar, y pueden
# dar resultados distintos (el RMSE castiga el ruido que pmm agrega a proposito; ver van Buuren, 2018,
# "Imputation is not prediction" [verificar cita]). Por eso se calcula el ganador con cada lectura: si coinciden, esa es la decision; si no,
# el script no elige y lo marca como pendiente para que el equipo lo decida.
ganador <- function(lectura) {
  t <- metricas[metodo %in% c(lectura, "red_ajustada", "media_estacion_temporada")]
  global <- t[, .(rmse_rel_medio = mean(rmse_rel)), by = metodo][order(rmse_rel_medio)]
  por_var <- t[, .SD[which.min(rmse)], by = variable][, .(variable, ganador = metodo)]
  list(global = global, por_var = por_var)
}
gA <- ganador("mice_por_imputacion"); gB <- ganador("mice_promedio_m")
norm <- function(x) sub("^mice_.*", "mice", x)
decision <- data.table(
  lectura = c("MICE por imputacion", "MICE promedio de las m"),
  ganador_global = c(norm(gA$global$metodo[1]), norm(gB$global$metodo[1])),
  rmse_rel_medio_mice = c(gA$global[metodo == "mice_por_imputacion", rmse_rel_medio], gB$global[metodo == "mice_promedio_m", rmse_rel_medio]),
  rmse_rel_medio_red_ajustada = gA$global[metodo == "red_ajustada", rmse_rel_medio],
  rmse_rel_medio_media_est_temp = gA$global[metodo == "media_estacion_temporada", rmse_rel_medio],
  variables_donde_gana_mice = c(sum(grepl("^mice", gA$por_var$ganador)), sum(grepl("^mice", gB$por_var$ganador))))
decision[, metodo_elegido := if (length(unique(ganador_global)) == 1L) ganador_global[1] else "pendiente: las dos lecturas no coinciden"]
print(decision)


# ---- Bloque 8. Salidas -------------------------------------------------------------------------------
escribir_csv(metricas, file.path(SALIDA, "enmascaramiento_diario.csv"))
escribir_csv(por_imputacion, file.path(SALIDA, "enmascaramiento_diario_por_imputacion.csv"))
escribir_csv(merge(resumen_mascara, cor_red, by = "variable", sort = FALSE), file.path(SALIDA, "enmascaramiento_diario_mascara.csv"))
escribir_csv(decision, file.path(SALIDA, "eleccion_metodo_diario.csv"))
escribir_csv(merge(gA$por_var, gB$por_var, by = "variable", suffixes = c("_lectura_por_imputacion", "_lectura_promedio_m")),
             file.path(SALIDA, "enmascaramiento_diario_ganador_por_variable.csv"))
if (!is.null(imp$loggedEvents)) escribir_csv(imp$loggedEvents, file.path(SALIDA, "enmascaramiento_diario_mice_eventos.csv"))
message(sprintf("Listo: %s (MICE tardo %.1f min)", SALIDA, minutos_mice))
