# =============================================================================================
# Etapa 4, fase B1 (D20 y registro de cambios de la fase A, puntos 2 y 3): imputacion DIARIA de la
# meteorologia en los estacion-dias a los que les faltan de 1 a 4 de las 8 variables de M1.
#
#   - Metodo principal: mediana de la red ajustada (el que gano en 08c), una sola imputacion.
#     Para cada variable: mediana de las OTRAS estaciones ese dia + la diferencia media de la estacion
#     respecto de esa mediana, calculada SOLO con 2021-2023. La diferencia se calcula por sitio
#     (estacion x sitio_valido): antes y despues de una reubicacion la estacion es otro sitio (D23).
#   - Sensibilidad: MICE (pmm, m = 20) con los predictores de D20 (medianas de la red, las otras
#     meteorologicas, estacion, temporada y anio), sin PM2.5 ni supera_25. Los modelos de imputacion
#     se ajustan solo con 2021-2023 (argumento `ignore` para 2024-2025, que si se imputan).
#
# La imputacion no usa la respuesta, asi que se imputan todos los dias con 1 a 4 faltantes (tengan o
# no PM2.5 valido): 09a elige las filas segun la respuesta de cada analisis. MICE se aplica, como dice
# D20, a los dias con respuesta valida. No ajusta LDA ni calcula AUC.
#
# Ejecutar desde la raiz:  Rscript scripts/08d_imputar_diario.R   (no necesita los Excel)
# Lee:     data/clean/v2/diario_v2_2021_2025.csv
# Escribe: data/clean/v2/diario_v2_imputado_2021_2025.csv (metodo principal),
#          data/clean/v2/muestra_v2_mice_m20.csv.gz (sensibilidad, formato largo con .imp),
#          output/etapa4/imputacion/imputacion_diaria_*.csv y figuras de diagnostico
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y carpetas -------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(mice)
  library(ggplot2)
})
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); source("R/imputacion.R")
SALIDA <- "output/etapa4/imputacion"
SEMILLA <- 2026
M_MICE <- 20L
MAXIT_MICE <- 10L            # iteraciones por cadena (en 08c bastaron 5; aqui 10 para revisar la convergencia)
MAX_FALTANTES <- 4L
RED <- paste0("red_", MET_DIARIA)


# ---- Bloque 1. Datos: base v2 (todos los anios) ------------------------------------------------------
v2 <- fread("data/clean/v2/diario_v2_2021_2025.csv")
v2[, (MET_DIARIA) := lapply(.SD, as.numeric), .SDcols = MET_DIARIA]
v2[, fecha := as.Date(fecha)][, id := .I]
stopifnot(nrow(v2) == 23738L)


# ---- Bloque 2. Mediana de la red de cada dia, sin la propia estacion -----------------------------------
# Usa lo que reportaron las otras 12 estaciones ese dia (completas o no). En la prueba son datos de
# meteorologia de esos mismos dias, no de la respuesta.
for (v in MET_DIARIA) v2[[paste0("red_", v)]] <- mediana_red(v2, v)


# ---- Bloque 3. Metodo principal: mediana de la red ajustada ----------------------------------------------
# Diferencia media de cada sitio (estacion x sitio_valido) respecto de la mediana de la red, con los
# dias de 2021-2023 en que ambas estan observadas. Se imputa toda celda faltante de un dia con 1 a 4
# faltantes. Si falta la mediana de la red ese dia o el sitio no tiene diferencia, la celda queda vacia.
candidato <- v2$n_met_faltantes >= 1L & v2$n_met_faltantes <= MAX_FALTANTES
imp_red <- copy(v2)
conteo <- list()
for (v in MET_DIARIA) {
  rv <- paste0("red_", v)
  dif <- v2[anio <= 2023 & !is.na(get(v)) & !is.na(get(rv)), .(dif = mean(get(v) - get(rv))), by = .(estacion, sitio_valido)]
  z <- merge(v2[, .(id, estacion, sitio_valido, med = get(rv))], dif, by = c("estacion", "sitio_valido"), all.x = TRUE)[order(id)]
  k <- which(candidato & is.na(v2[[v]]))
  valor <- z$med[k] + z$dif[k]
  set(imp_red, i = k, j = v, value = round(valor, 3))
  set(imp_red, j = paste0("imp_", v), value = as.integer(seq_len(nrow(v2)) %in% k[!is.na(valor)]))
  conteo[[v]] <- data.table(variable = v, celdas_a_imputar = length(k), imputadas = sum(!is.na(valor)),
                            sin_mediana_de_red = sum(is.na(z$med[k])), sin_diferencia_del_sitio = sum(!is.na(z$med[k]) & is.na(z$dif[k])))
}
imp_red[, n_met_faltantes_tras_imputar := Reduce(`+`, lapply(MET_DIARIA, function(v) as.integer(is.na(get(v)))))]
imp_red[, met_completa_tras_imputar := as.integer(n_met_faltantes_tras_imputar == 0L)]
conteo <- rbindlist(conteo)
# Valores imputados fuera del rango fisico de la variable diaria (no se recortan: el metodo es el
# validado en 08c; solo se cuentan).
fuera <- data.table(variable = MET_DIARIA, imputados_fuera_de_rango = c(
  TOUT = 0L, RH = sum(imp_red$imp_RH == 1L & (imp_red$RH < 0 | imp_red$RH > 100)),
  SR = sum(imp_red$imp_SR == 1L & imp_red$SR < 0), PRS = 0L, viento_u = 0L, viento_v = 0L,
  viento_rapidez_ms = sum(imp_red$imp_viento_rapidez_ms == 1L & imp_red$viento_rapidez_ms < 0),
  horas_lluvia = sum(imp_red$imp_horas_lluvia == 1L & (imp_red$horas_lluvia < 0 | imp_red$horas_lluvia > 24))))
conteo <- merge(conteo, fuera, by = "variable", sort = FALSE)
print(conteo)
cols_pub <- c(setdiff(names(v2), c("id", RED)), paste0("imp_", MET_DIARIA), "n_met_faltantes_tras_imputar", "met_completa_tras_imputar")
setcolorder(imp_red, cols_pub)
escribir_csv(imp_red[, ..cols_pub], "data/clean/v2/diario_v2_imputado_2021_2025.csv")
escribir_csv(conteo, file.path(SALIDA, "imputacion_diaria_conteo.csv"))
message(sprintf("Dias con respuesta valida y meteorologia completa tras imputar: %s",
                format(sum(imp_red$respuesta_valida == 1L & imp_red$met_completa_tras_imputar == 1L), big.mark = ",")))


# ---- Bloque 4. Sensibilidad: MICE (pmm, m = 20) ------------------------------------------------------------
# Filas: dias con respuesta valida y <= 4 faltantes (los del analisis principal). `ignore` = 2024-2025:
# esas filas se imputan con modelos ajustados solo con 2021-2023. Nota: con `ignore`, las indicadoras
# de 2024 y 2025 valen 0 en todas las filas de ajuste, asi que mice las descarta y esos anios se
# imputan como el anio de referencia (2021); queda registrado en los eventos de mice.
dm <- v2[respuesta_valida == 1L & n_met_faltantes <= MAX_FALTANTES, c("id", "estacion", "fecha", MET_DIARIA, RED, "temporada", "anio"), with = FALSE]
datos_mice <- as.data.frame(dm[, c(MET_DIARIA, RED, "estacion", "temporada", "anio"), with = FALSE])
datos_mice$estacion <- factor(datos_mice$estacion); datos_mice$temporada <- factor(datos_mice$temporada)
datos_mice$anio <- factor(datos_mice$anio)
ignorar <- dm$anio >= 2024
t0 <- Sys.time()
imp <- mice(datos_mice, m = M_MICE, maxit = MAXIT_MICE, method = make.method(datos_mice),
            predictorMatrix = make.predictorMatrix(datos_mice), ignore = ignorar, seed = SEMILLA,
            printFlag = FALSE, maxcor = 0.9999)
minutos <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("MICE: %d filas (%d ignoradas para ajustar), m = %d, %d iteraciones, %.1f min.",
                nrow(datos_mice), sum(ignorar), M_MICE, MAXIT_MICE, minutos))
largo <- rbindlist(lapply(seq_len(M_MICE), function(k) {
  cc <- as.data.table(complete(imp, k))[, c(MET_DIARIA), with = FALSE]
  cbind(.imp = k, dm[, .(estacion, fecha)], cc)
}))
for (v in MET_DIARIA) set(largo, j = v, value = round(largo[[v]], 3))
ruta_mice <- "data/clean/v2/muestra_v2_mice_m20.csv.gz"
fwrite(largo, ruta_mice, compress = "gzip")
mb <- file.size(ruta_mice) / 1e6
message(sprintf("%s: %.1f MB", ruta_mice, mb))
stopifnot(mb < 50)
if (!is.null(imp$loggedEvents)) escribir_csv(imp$loggedEvents, file.path(SALIDA, "imputacion_diaria_mice_eventos.csv"))


# ---- Bloque 5. Diagnosticos: convergencia de MICE y distribucion de lo imputado ---------------------------
# Convergencia: media y DE de los valores imputados en cada iteracion, una linea por cadena (m = 20).
# Si las cadenas se mezclan y no tienen tendencia, el algoritmo convergio.
cad <- rbindlist(lapply(MET_DIARIA, function(v) {
  if (all(is.na(imp$chainMean[v, , ]))) return(NULL)
  rbind(data.table(variable = v, estadistico = "media", iteracion = rep(seq_len(MAXIT_MICE), M_MICE),
                   cadena = rep(seq_len(M_MICE), each = MAXIT_MICE), valor = as.vector(imp$chainMean[v, , ])),
        data.table(variable = v, estadistico = "DE", iteracion = rep(seq_len(MAXIT_MICE), M_MICE),
                   cadena = rep(seq_len(M_MICE), each = MAXIT_MICE), valor = sqrt(as.vector(imp$chainVar[v, , ]))))
}))
g <- ggplot(cad, aes(iteracion, valor, group = cadena)) + geom_line(alpha = 0.5, colour = "#0072B2") +
  facet_wrap(estadistico ~ variable, scales = "free_y", ncol = 8) +
  labs(x = "Iteración", y = NULL, title = "Convergencia de MICE (m = 20): media y DE de los valores imputados por iteración") +
  theme_minimal(base_size = 8)
ggsave(file.path(SALIDA, "imputacion_diaria_mice_convergencia.png"), g, width = 12, height = 4.5, dpi = 150)
# Distribucion: valores observados frente a imputados (metodo principal y MICE), en los dias con
# respuesta valida. Las imputaciones deberian parecerse a lo observado, condicionadas a la red.
obs_l <- melt(v2[respuesta_valida == 1L, ..MET_DIARIA], measure.vars = MET_DIARIA, variable.name = "variable", value.name = "valor")[!is.na(valor)]
obs_l[, origen := "observado"]
red_l <- rbindlist(lapply(MET_DIARIA, function(v) data.table(variable = v, valor = imp_red[respuesta_valida == 1L & get(paste0("imp_", v)) == 1L][[v]])))
red_l[, origen := "imputado: mediana de la red ajustada"]
falta <- is.na(dm[, ..MET_DIARIA])
mice_l <- rbindlist(lapply(MET_DIARIA, function(v) data.table(variable = v, valor = largo[[v]][rep(falta[, v], M_MICE)])))
mice_l[, origen := "imputado: MICE (20 bases)"]
dens <- rbind(obs_l, red_l, mice_l)[, variable := factor(variable, levels = MET_DIARIA)]
g <- ggplot(dens, aes(valor, colour = origen)) + geom_density(linewidth = 0.6) +
  facet_wrap(~variable, scales = "free", ncol = 4) +
  scale_colour_manual(values = c("observado" = "#000000", "imputado: mediana de la red ajustada" = "#D55E00",
                                 "imputado: MICE (20 bases)" = "#0072B2"), name = NULL) +
  labs(x = NULL, y = "Densidad", title = "Valores observados frente a imputados (días con respuesta válida)") +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom")
ggsave(file.path(SALIDA, "imputacion_diaria_densidades.png"), g, width = 9, height = 5.5, dpi = 150)
resumen_dist <- dens[, .(n = .N, media = mean(valor), de = sd(valor), p05 = quantile(valor, 0.05), p95 = quantile(valor, 0.95)),
                     by = .(variable, origen)][order(variable, origen)]
escribir_csv(resumen_dist, file.path(SALIDA, "imputacion_diaria_distribucion.csv"))
message("Listo: data/clean/v2/ y ", SALIDA)
