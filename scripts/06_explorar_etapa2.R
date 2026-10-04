# Etapa 2: exploración descriptiva de la muestra del protocolo (docs/etapa2/protocolo.md, v2).
# Solo describe la muestra: sin PCA ni modelos (eso es la etapa 3). Ejecutar desde la raiz:
#   Rscript scripts/06_explorar_etapa2.R
# Lee: data/clean/sima_diario_2020_2025.csv, data/clean/sima_horario_limpio_AAAA.csv (2021-2025)
# Escribe: data/clean/muestra_pm25_2021_2025.csv, data/clean/DICCIONARIO.csv (ampliado),
#          output/etapa2/ (tablas, figuras y RESUMEN.md)
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

dir.create("output/etapa2/figuras", recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, ruta) utils::write.csv(x, ruta, row.names = FALSE, na = "", fileEncoding = "UTF-8")
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
pct <- function(x, d = 1) formatC(x, format = "f", digits = d)

# ---- Definiciones fijas del protocolo (seccion 3) ------------------------------------------
ESTACIONES_13 <- setdiff(sort(unique(data.table::fread("data/metadata/estaciones.csv")$codigo_hoja)),
                         c("NE3", "NO3"))
ANIOS <- 2021:2025
MET <- c("TOUT", "RH", "SR", "PRS", "viento_u", "viento_v", "viento_rapidez_ms", "horas_lluvia")
UMBRAL_PM25 <- 25     # NOM-025-SSA1-2021, quinto año de aplicacion (referencia fija, no normativa)
UMBRAL_OMS <- 15      # sensibilidad: guia OMS 24 h
HORAS_MIN_DIA <- 18L  # criterio de completitud del 75 % que usa SIMA

message("Cargando datos diarios...")
diario <- fread("data/clean/sima_diario_2020_2025.csv", encoding = "UTF-8")
stopifnot(all(ESTACIONES_13 %in% diario$estacion))

# ---- 1. Muestra del protocolo -------------------------------------------------------------
universo <- diario[estacion %in% ESTACIONES_13 & anio %in% ANIOS]
stopifnot(nrow(universo) == length(ESTACIONES_13) * 1826L)   # 13 estaciones x dias calendario 2021-2025

ok_pm <- !is.na(universo[["PM2.5"]])
ok_met <- Reduce(function(a, b) a & b, lapply(MET, function(v) !is.na(universo[[v]])))
muestra <- universo[ok_pm & ok_met]
muestra[, supera_25 := as.integer(`PM2.5` > UMBRAL_PM25)]
muestra[, supera_15 := as.integer(`PM2.5` > UMBRAL_OMS)]
setorder(muestra, estacion, fecha)

pub <- muestra[, .(estacion, fecha, anio, temporada, confinamiento_2020,
                   `PM2.5`, supera_25, supera_15, n_horas_PM2.5,
                   TOUT, RH, SR, PRS, viento_u, viento_v, viento_rapidez_ms,
                   horas_lluvia, llovio, n_horas_TOUT, n_horas_RH, n_horas_SR, n_horas_PRS,
                   n_horas_viento, n_horas_RAINF)]
escribir(pub, "data/clean/muestra_pm25_2021_2025.csv")
message("Muestra: ", nrow(pub), " estacion-dias de ", nrow(universo), " posibles (",
        pct(100 * nrow(pub) / nrow(universo)), "%).")

# ---- DICCIONARIO.csv: documenta el archivo nuevo -------------------------------------------
dic <- fread("data/clean/DICCIONARIO.csv", encoding = "UTF-8")
A <- "muestra_pm25_2021_2025.csv"
desc_pub <- list(
  estacion = "Código de estación SIMA (13: excluye NE3 y NO3, que casi no miden PM2.5)",
  fecha = "Día calendario local (AAAA-MM-DD)",
  anio = "Año (2021-2025)",
  temporada = "seca_fria (nov-feb), seca_calida (mar-may), calida_humeda (jun-oct)",
  confinamiento_2020 = "Siempre 0 en esta muestra (2020 esta excluido por protocolo)",
  `PM2.5` = "Media diaria de PM2.5 (µg/m3), ya limpia; requiere >=18 h válidas (incluye imputadas)",
  supera_25 = "1 si PM2.5 > 25 µg/m3 (referencia fija de comparación, no evaluación normativa); 0 si no",
  supera_15 = "1 si PM2.5 > 15 µg/m3 (sensibilidad: guía 24 h de la OMS); 0 si no",
  n_horas_PM2.5 = "Horas válidas de PM2.5 usadas en la media diaria (observadas + imputadas, >=18)",
  TOUT = "Media diaria de temperatura (°C); predictor de M1", RH = "Media diaria de humedad relativa (%); predictor de M1",
  SR = "Media diaria de radiación solar (kW/m2); predictor de M1", PRS = "Media diaria de presión atmosférica (mm Hg); predictor de M1",
  viento_u = "Media diaria de la componente u del viento (m/s); predictor de M1",
  viento_v = "Media diaria de la componente v del viento (m/s); predictor de M1",
  viento_rapidez_ms = "Media diaria de la rapidez del viento (m/s); predictor de M1",
  horas_lluvia = "Horas del día con 0 < RAINF <= máximo de operación; predictor de M1 (no la cantidad de lluvia)",
  llovio = "1 si horas_lluvia > 0",
  n_horas_TOUT = "Horas válidas usadas en la media diaria de TOUT", n_horas_RH = "Horas válidas usadas en la media diaria de RH",
  n_horas_SR = "Horas válidas usadas en la media diaria de SR", n_horas_PRS = "Horas válidas usadas en la media diaria de PRS",
  n_horas_viento = "Horas válidas usadas en viento_u/viento_v/viento_rapidez_ms",
  n_horas_RAINF = "Horas válidas de RAINF usadas para horas_lluvia")
nuevas <- rbindlist(lapply(names(desc_pub), function(col) data.table(
  archivo = A, columna = col, tipo = if (col %in% c("estacion", "temporada", "fecha")) "texto" else
    if (col %in% c("anio", "confinamiento_2020", "supera_25", "supera_15", "llovio") || grepl("^n_horas", col)) "entero" else "numérico",
  unidad = "", descripcion = desc_pub[[col]],
  fuente_o_regla = "scripts/06_explorar_etapa2.R, sobre data/clean/sima_diario_2020_2025.csv")))
dic <- dic[archivo != A]   # reemplaza si ya existia (idempotente)
dic <- rbind(dic, nuevas)
escribir(dic, "data/clean/DICCIONARIO.csv")

# ---- 2. Perdidas de la muestra -------------------------------------------------------------
message("Calculando pérdidas de la muestra...")
n_univ <- nrow(universo)
n_falta_pm <- sum(!ok_pm); n_falta_met <- sum(!ok_met)
n_solo_pm <- sum(!ok_pm & ok_met); n_solo_met <- sum(ok_pm & !ok_met); n_ambos <- sum(!ok_pm & !ok_met)
perdidas <- data.table(
  requisito = c("Universo (13 estaciones x 2021-2025)", "Pierde por PM2.5 (< 18 h válidas)",
               "Pierde por meteorología incompleta (algún predictor de M1 < 18 h)",
               "  de ellos: solo falta PM2.5", "  de ellos: solo falta meteorología",
               "  de ellos: faltan ambos", "Muestra final (PM2.5 y meteorología completas)"),
  n = c(n_univ, n_falta_pm, n_falta_met, n_solo_pm, n_solo_met, n_ambos, nrow(muestra)),
  pct_del_universo = round(100 * c(n_univ, n_falta_pm, n_falta_met, n_solo_pm, n_solo_met, n_ambos, nrow(muestra)) / n_univ, 1))

# Dias retirados por la regla D15 (datos-v1.2): dias que estarian en la muestra si las horas con bandera
# M (SR nocturna) y E de viento contaran como validas. Se reconstruye con las banderas horarias.
message("Contando dias retirados por D15...")
hd15 <- rbindlist(lapply(ANIOS, function(a) {
  d <- fread(sprintf("data/clean/sima_horario_limpio_%d.csv", a), encoding = "UTF-8",
             select = c("estacion", "fecha_hora", "SR", "f_SR", "viento_u", "f_uv"),
             colClasses = list(character = "fecha_hora"))
  d[estacion %in% ESTACIONES_13]
}))
hd15[, fecha := as.Date(substr(fecha_hora, 1, 10))]
d15_dia <- hd15[, .(sr_M = sum(f_SR == "M"), sr_validas = sum(!is.na(SR)),
                    w_E = sum(f_uv == "E"), w_validas = sum(!is.na(viento_u))), by = .(estacion, fecha)]
u2 <- merge(universo[, c("estacion", "fecha", "PM2.5", MET), with = FALSE], d15_dia, by = c("estacion", "fecha"), all.x = TRUE)
otras <- setdiff(MET, c("SR", "viento_u", "viento_v", "viento_rapidez_ms"))
u2[, otras_ok := Reduce(function(a, b) a & b, lapply(otras, function(v) !is.na(get(v))))]
u2[, sr_ok_sin := !is.na(SR) | (sr_M > 0 & sr_validas + sr_M >= HORAS_MIN_DIA)]
u2[, w_ok_sin := !is.na(viento_u) | (w_E > 0 & w_validas + w_E >= HORAS_MIN_DIA)]
u2[, en_muestra := !is.na(`PM2.5`) & otras_ok & !is.na(SR) & !is.na(viento_u)]
u2[, sin_d15 := !is.na(`PM2.5`) & otras_ok & sr_ok_sin & w_ok_sin]
u2[, retirado_d15 := sin_d15 & !en_muestra]
u2[, por_sr := retirado_d15 & is.na(SR)]
u2[, por_viento := retirado_d15 & is.na(viento_u)]
n_d15 <- sum(u2$retirado_d15)
perdidas <- rbind(perdidas[1:6],
  data.table(requisito = c("  de la meteorología: días retirados por la regla D15 (SR nocturna o viento contra la red)",
                           "    por SR nocturna", "    por viento contra la red"),
             n = c(n_d15, sum(u2$por_sr), sum(u2$por_viento)),
             pct_del_universo = round(100 * c(n_d15, sum(u2$por_sr), sum(u2$por_viento)) / n_univ, 1)),
  perdidas[7])
escribir(perdidas, "output/etapa2/perdidas_muestra.csv")
d15_est <- u2[, .(dias_retirados_d15 = sum(retirado_d15), por_sr_nocturna = sum(por_sr),
                  por_viento_red = sum(por_viento),
                  dias_con_sr_M = sum(sr_M > 0, na.rm = TRUE), dias_con_viento_E = sum(w_E > 0, na.rm = TRUE)),
              by = estacion][order(-dias_retirados_d15)]
d15_est <- rbind(d15_est, d15_est[, c(list(estacion = "TOTAL"), lapply(.SD, sum)), .SDcols = -"estacion"])
escribir(d15_est, "output/etapa2/anexo_d15_por_estacion.csv")

ret_est <- universo[, .(dias_totales = .N), by = estacion]
ret_est <- merge(ret_est, muestra[, .(dias_retenidos = .N), by = estacion], by = "estacion", all.x = TRUE)
ret_est[is.na(dias_retenidos), dias_retenidos := 0L]
ret_est[, pct_retenido := round(100 * dias_retenidos / dias_totales, 1)]
setorder(ret_est, -pct_retenido)
escribir(ret_est, "output/etapa2/retencion_por_estacion.csv")

ret_temp <- universo[, .(dias_totales = .N), by = temporada]
ret_temp <- merge(ret_temp, muestra[, .(dias_retenidos = .N), by = temporada], by = "temporada", all.x = TRUE)
ret_temp[is.na(dias_retenidos), dias_retenidos := 0L]
ret_temp[, pct_retenido := round(100 * dias_retenidos / dias_totales, 1)]
escribir(ret_temp, "output/etapa2/retencion_por_temporada.csv")

# ---- 3. Sensibilidad de imputacion: PM2.5 solo con horas observadas ------------------------
message("Recalculando PM2.5 solo con horas observadas (2021-2025, 13 estaciones)...")
horario <- rbindlist(lapply(ANIOS, function(a) {
  d <- fread(sprintf("data/clean/sima_horario_limpio_%d.csv", a), encoding = "UTF-8",
             select = c("estacion", "fecha_hora", "PM2.5", "f_PM2.5"))
  d[estacion %in% ESTACIONES_13]
}))
horario[, fecha := as.Date(fecha_hora)]
horario[, observada := f_PM2.5 %in% c("V", "C")]
obs_diario <- horario[, .(
  n_obs = sum(observada),
  pm25_obs = if (sum(observada) >= HORAS_MIN_DIA) mean(`PM2.5`[observada]) else NA_real_
), by = .(estacion, fecha)]
obs_diario[, pm25_obs := round(pm25_obs, 3)]

comp <- merge(muestra[, .(estacion, fecha, pm25_actual = `PM2.5`, supera_25_actual = supera_25)],
             obs_diario, by = c("estacion", "fecha"), all.x = TRUE)
comp[, evaluable_obs := !is.na(pm25_obs)]
comp[, supera_25_obs := as.integer(pm25_obs > UMBRAL_PM25)]

no_evaluables <- comp[evaluable_obs == FALSE]
escribir(no_evaluables[, .(estacion, fecha, n_obs, pm25_actual, supera_25_actual)],
         "output/etapa2/sensibilidad_imputacion_no_evaluables.csv")

comparables <- comp[evaluable_obs == TRUE]
comparables[, cambia_clase := supera_25_actual != supera_25_obs]
cambios <- comparables[cambia_clase == TRUE]
escribir(cambios[, .(estacion, fecha, n_obs, pm25_actual, supera_25_actual, pm25_obs, supera_25_obs)],
         "output/etapa2/sensibilidad_imputacion_cambios_clase.csv")

sens_imp <- data.table(
  concepto = c(sprintf("Días de la muestra (%s)", fmt(nrow(muestra))), "Días comparables (>=18 h observadas, sin imputar)",
              "  de ellos: cambian de clase en supera_25", "Días que dejan de ser evaluables (quedan < 18 h observadas)"),
  n = c(nrow(muestra), nrow(comparables), nrow(cambios), nrow(no_evaluables)),
  pct_de_la_muestra = round(100 * c(nrow(muestra), nrow(comparables), nrow(cambios), nrow(no_evaluables)) / nrow(muestra), 2))
escribir(sens_imp, "output/etapa2/sensibilidad_imputacion_resumen.csv")

# ---- 4. Descriptivos y SMD ------------------------------------------------------------------
message("Calculando descriptivos y SMD...")
asimetria <- function(x) { x <- x[!is.na(x)]; n <- length(x); m <- mean(x); s <- sqrt(sum((x - m)^2) / n)
  (sum((x - m)^3) / n) / s^3 }
descr_una <- function(x, etiqueta) {
  x <- x[!is.na(x)]
  q <- stats::quantile(x, c(0.25, 0.5, 0.75))
  iqr <- q[3] - q[1]; lim <- q[3] + 3 * iqr
  data.table(variable = etiqueta, n = length(x), media = mean(x), de = stats::sd(x),
             mediana = q[2], q1 = q[1], q3 = q[3], minimo = min(x), maximo = max(x),
             asimetria = asimetria(x), extremos_mayores_q3_mas_3iqr = sum(x > lim))
}
descriptivos <- rbindlist(lapply(c("PM2.5", MET), function(v) descr_una(muestra[[v]], v)))
descriptivos[, (3:10) := lapply(.SD, round, 3), .SDcols = 3:10]
escribir(descriptivos, "output/etapa2/descriptivos_pm25_meteo.csv")

smd <- function(x, g) {
  x1 <- x[g == 1 & !is.na(x)]; x0 <- x[g == 0 & !is.na(x)]
  if (length(x1) < 2 || length(x0) < 2) return(NA_real_)
  (mean(x1) - mean(x0)) / sqrt((stats::var(x1) + stats::var(x0)) / 2)
}
smd_global <- rbindlist(lapply(MET, function(v) data.table(
  variable = v, media_supera = mean(muestra[[v]][muestra$supera_25 == 1], na.rm = TRUE),
  media_no_supera = mean(muestra[[v]][muestra$supera_25 == 0], na.rm = TRUE),
  smd = smd(muestra[[v]], muestra$supera_25))))
smd_global[, 2:3 := lapply(.SD, round, 3), .SDcols = 2:3]
smd_global[, smd := round(smd, 6)]   # 6 decimales: evita el doble redondeo al reportar con 2
escribir(smd_global, "output/etapa2/smd_meteo_global.csv")

smd_temp <- rbindlist(lapply(sort(unique(muestra$temporada)), function(tp) {
  z <- muestra[temporada == tp]
  rbindlist(lapply(MET, function(v) data.table(temporada = tp, variable = v, smd = smd(z[[v]], z$supera_25))))
}))
smd_temp[, smd := round(smd, 6)]
escribir(smd_temp, "output/etapa2/smd_meteo_temporada.csv")

# Anomalia: cada variable menos la media de su estacion x temporada (lo que la meteorologia anade
# cuando estacion y temporada ya se conocen).
anom <- copy(muestra)
anom[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]   # horas_lluvia es entera: la anomalia no debe truncarse
for (v in MET) anom[, (v) := get(v) - mean(get(v)), by = .(estacion, temporada)]
smd_anom <- rbindlist(lapply(MET, function(v) data.table(
  variable = v, media_anom_supera = mean(anom[[v]][anom$supera_25 == 1]),
  media_anom_no_supera = mean(anom[[v]][anom$supera_25 == 0]), smd = smd(anom[[v]], anom$supera_25))))
smd_anom[, 2:3 := lapply(.SD, round, 3), .SDcols = 2:3]
smd_anom[, smd := round(smd, 6)]
escribir(smd_anom, "output/etapa2/smd_meteo_anomalia.csv")
pct_sin_lluvia <- round(100 * mean(muestra$horas_lluvia == 0), 1)

# ---- 5. Figuras principales -----------------------------------------------------------------
message("Generando figuras...")
TEMA <- theme_minimal(base_size = 10)

# Fig 1: PM2.5 diario por estacion (boxplot, orden por mediana, eje log, lineas en 15 y 25)
orden_est <- muestra[, .(mediana = median(`PM2.5`)), by = estacion][order(mediana), estacion]
d1 <- copy(muestra); d1[, estacion := factor(estacion, levels = orden_est)]
fig1 <- ggplot(d1, aes(estacion, `PM2.5`)) +
  geom_boxplot(outlier.size = 0.6, outlier.alpha = 0.4, fill = "#8CA9C9", linewidth = 0.3) +
  geom_hline(yintercept = c(UMBRAL_OMS, UMBRAL_PM25), linetype = c("dotted", "dashed"), colour = "#B22222") +
  annotate("text", x = 1, y = c(UMBRAL_OMS, UMBRAL_PM25), label = c("15 (OMS)", "25"),
           hjust = -0.1, vjust = -0.4, size = 2.8, colour = "#B22222") +
  scale_y_log10() +
  labs(x = "Estación (orden: mediana creciente)", y = "PM2.5 diario (µg/m³, escala log)",
       title = sprintf("PM2.5 diario por estación, 2021-2025 (n = %s estación-días)", fmt(nrow(muestra)))) +
  TEMA + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("output/etapa2/figuras/fig1_pm25_boxplot_estacion.png", fig1, width = 7.5, height = 4.3, dpi = 150)

# Fig 2: heatmap % de superacion por estacion x temporada, con n
hm <- muestra[, .(pct = 100 * mean(supera_25), n = .N), by = .(estacion, temporada)]
hm[, estacion := factor(estacion, levels = orden_est)]
hm[, temporada := factor(temporada, levels = c("seca_fria", "seca_calida", "calida_humeda"))]
fig2 <- ggplot(hm, aes(temporada, estacion, fill = pct)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.0f%%\n(n=%d)", pct, n)), size = 2.6, lineheight = 0.9) +
  scale_fill_gradientn(colours = c("#f7fbff", "#fee8c8", "#fdbb84", "#e34a33", "#7f0000"),
                       limits = c(0, 100), name = "% superación") +
  labs(x = "Temporada", y = "Estación",
       title = "% de días con PM2.5 > 25 µg/m³, por estación y temporada") +
  TEMA + theme(panel.grid = element_blank())
ggsave("output/etapa2/figuras/fig2_heatmap_superacion_estacion_temporada.png", fig2, width = 6.5, height = 5, dpi = 150)

# Fig 3: meteorologia segun superacion (boxplots en facetas)
etiquetas_met <- c(TOUT = "TOUT (°C)", RH = "RH (%)", SR = "SR (kW/m²)", PRS = "PRS (mm Hg)",
                   viento_u = "viento_u (m/s)", viento_v = "viento_v (m/s)",
                   viento_rapidez_ms = "rapidez viento (m/s)", horas_lluvia = "horas_lluvia (h)")
d3 <- melt(muestra[, c("supera_25", MET), with = FALSE][, (MET) := lapply(.SD, as.numeric), .SDcols = MET], id.vars = "supera_25",
          variable.name = "variable", value.name = "valor")
d3[, variable := factor(etiquetas_met[as.character(variable)], levels = etiquetas_met)]
d3[, supera_25 := factor(supera_25, levels = c(0, 1), labels = c("No supera (≤25)", "Supera (>25)"))]
fig3 <- ggplot(d3, aes(supera_25, valor, fill = supera_25)) +
  geom_boxplot(outlier.size = 0.4, outlier.alpha = 0.4, linewidth = 0.3, show.legend = FALSE) +
  facet_wrap(~variable, scales = "free_y", ncol = 4) +
  scale_fill_manual(values = c("#5B9BD5", "#C0504D")) +
  labs(x = NULL, y = NULL, title = "Meteorología del día según PM2.5 supera 25 µg/m³ (2021-2025)") +
  TEMA + theme(strip.text = element_text(size = 8), axis.text.x = element_text(size = 7))
ggsave("output/etapa2/figuras/anexo_meteo_facetas_superacion.png", fig3, width = 8.5, height = 4.8, dpi = 150)
unlink("output/etapa2/figuras/fig3_meteo_facetas_superacion.png")   # nombre anterior

# Fig 3 (nueva): SMD de cada variable en 5 versiones (global, por temporada y anomalia)
smd_todas <- rbind(smd_global[, .(variable, smd, version = "global")],
                   smd_temp[, .(variable, smd, version = temporada)],
                   smd_anom[, .(variable, smd, version = "anomalía estación × temporada")])
smd_todas[, version := factor(version, levels = c("global", "seca_fria", "seca_calida", "calida_humeda",
                                                  "anomalía estación × temporada"))]
smd_todas[, variable := factor(etiquetas_met[variable], levels = rev(etiquetas_met))]
fig3s <- ggplot(smd_todas, aes(smd, variable, colour = version, shape = version)) +
  geom_vline(xintercept = 0, colour = "grey40") +
  geom_vline(xintercept = c(-0.2, 0.2), linetype = "dotted", colour = "grey40") +
  geom_point(size = 2.4, position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = c("#000000", "#0072B2", "#E69F00", "#009E73", "#CC0000"), name = NULL) +
  scale_shape_manual(values = c(16, 15, 17, 18, 8), name = NULL) +
  labs(x = "SMD (días con superación − días sin superación)", y = NULL,
       title = "Diferencia de medias estandarizada de la meteorología, por versión") +
  TEMA + theme(legend.position = "bottom") + guides(colour = guide_legend(nrow = 2, byrow = TRUE), shape = guide_legend(nrow = 2, byrow = TRUE))
ggsave("output/etapa2/figuras/fig3_smd_meteo.png", fig3s, width = 7.5, height = 5, dpi = 150)

# ---- Anexos: Spearman y % mensual de superacion por anio -------------------------------------
message("Generando anexos...")
vars_sp <- c("PM2.5", MET)
mat <- stats::cor(muestra[, vars_sp, with = FALSE], method = "spearman", use = "pairwise.complete.obs")
escribir(as.data.table(mat, keep.rownames = "variable"), "output/etapa2/anexo_matriz_spearman.csv")
msp <- as.data.table(mat, keep.rownames = "v1")
msp <- melt(msp, id.vars = "v1", variable.name = "v2", value.name = "rho")
msp[, v1 := factor(v1, levels = vars_sp)]; msp[, v2 := factor(v2, levels = rev(vars_sp))]
figA <- ggplot(msp, aes(v1, v2, fill = rho)) +
  geom_tile(colour = "white") + geom_text(aes(label = sprintf("%.2f", rho)), size = 2.4) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0, limits = c(-1, 1),
                       name = "Spearman") +
  labs(x = NULL, y = NULL, title = "Matriz de correlación de Spearman (PM2.5 y meteorología de M1)") +
  TEMA + theme(panel.grid = element_blank(), axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("output/etapa2/figuras/anexo_matriz_spearman.png", figA, width = 6, height = 5, dpi = 150)

muestra[, mes := as.integer(format(fecha, "%m"))]
mensual <- muestra[, .(pct_superacion = round(100 * mean(supera_25), 1), n = .N), by = .(anio, mes)]
setorder(mensual, anio, mes)
escribir(mensual, "output/etapa2/anexo_superacion_mensual_por_anio.csv")
mensual[, fecha_mes := as.Date(sprintf("%d-%02d-01", anio, mes))]
figB <- ggplot(mensual, aes(fecha_mes, pct_superacion)) +
  geom_line(colour = "#B2182B") + geom_point(size = 1, colour = "#B2182B") +
  scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  labs(x = NULL, y = "% de días con PM2.5 > 25 µg/m³",
       title = "% mensual de superación de PM2.5 > 25 µg/m³, por año") +
  TEMA + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("output/etapa2/figuras/anexo_superacion_mensual_por_anio.png", figB, width = 7.5, height = 3.5, dpi = 150)

# ---- 6. RESUMEN.md -----------------------------------------------------------------------------
message("Escribiendo RESUMEN.md...")
prev_pct <- round(100 * mean(muestra$supera_25), 1)
peor_est <- hm[order(-pct)][1]; mejor_est <- hm[order(pct)][1]
por_temp <- muestra[, .(pct = 100 * mean(supera_25), n = .N), by = temporada]
por_anio <- muestra[, .(pct = 100 * mean(supera_25), n = .N), by = anio][order(anio)]
rho_pm <- mat["PM2.5", MET]
dmx <- diario[which.max(viento_rapidez_ms)]
mmx <- muestra[which.max(viento_rapidez_ms)]
g <- function(tab, v, col = "smd") tab[[col]][tab$variable == v]
tabla_md <- function(dt) c(paste0("| ", paste(names(dt), collapse = " | "), " |"),
                          paste0("|", paste(rep("---", ncol(dt)), collapse = "|"), "|"),
                          apply(dt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
smd_tabla <- dcast(smd_todas[, .(variable = as.character(variable), version, smd = sprintf("%.2f", smd))],
                   variable ~ version, value.var = "smd")
lineas <- c(
  "# Etapa 2 · Exploración descriptiva de la muestra (sin PCA ni modelos)",
  "",
  sprintf("Generado por `scripts/06_explorar_etapa2.R` el %s, sobre `docs/etapa2/protocolo.md` y la base `datos-v1.2` (con la regla D15). Solo describe la muestra que define el protocolo; el modelado (PCA, discriminante, logística) es la etapa 3.",
          format(Sys.Date())),
  "",
  "## 1. Muestra",
  "",
  sprintf("Universo: 13 estaciones (excluye NE3 y NO3) × 2021–2025 = **%s estación-días**. Muestra final (`data/clean/muestra_pm25_2021_2025.csv`): **%s estación-días** (%s %% del universo), con PM2.5 diario válido (≥ 18 h) y los ocho predictores de M1 completos. Superación (PM2.5 > 25 µg/m³): **%s %%** de la muestra (%s días).",
          fmt(n_univ), fmt(nrow(muestra)), pct(100 * nrow(muestra) / n_univ), pct(prev_pct), fmt(sum(muestra$supera_25))),
  "",
  "## 2. Pérdidas de la muestra",
  "",
  sprintf("De %s estación-días posibles: %s (%s %%) pierden por PM2.5 sin 18 h válidas y %s (%s %%) por faltar al menos un predictor meteorológico; %s pierden por ambos motivos y se cuentan en los dos grupos. De las pérdidas meteorológicas, **%s días se retiran por la regla D15** (%s por SR nocturna y %s por viento contra la red; un día puede caer en ambas). Detalle en `perdidas_muestra.csv` y por estación en `anexo_d15_por_estacion.csv`.",
          fmt(n_univ), fmt(n_falta_pm), pct(100 * n_falta_pm / n_univ), fmt(n_falta_met), pct(100 * n_falta_met / n_univ), fmt(n_ambos),
          fmt(n_d15), fmt(sum(u2$por_sr)), fmt(sum(u2$por_viento))),
  "",
  sprintf("Retención por estación (`retencion_por_estacion.csv`): de %s %% (%s, %s días) a %s %% (%s, %s días). Por temporada (`retencion_por_temporada.csv`): de %s %% a %s %%.",
          min(ret_est$pct_retenido), ret_est$estacion[which.min(ret_est$pct_retenido)], fmt(ret_est$dias_retenidos[which.min(ret_est$pct_retenido)]),
          max(ret_est$pct_retenido), ret_est$estacion[which.max(ret_est$pct_retenido)], fmt(ret_est$dias_retenidos[which.max(ret_est$pct_retenido)]),
          min(ret_temp$pct_retenido), max(ret_temp$pct_retenido)),
  "",
  "## 3. Sensibilidad: PM2.5 recalculado solo con horas observadas",
  "",
  sprintf("Exigiendo ≥ 18 h **observadas** (sin imputar): %s de los %s días (%s %%) dejan de ser evaluables (`sensibilidad_imputacion_no_evaluables.csv`). De los %s días comparables, **%s (%s %%) cambian de clase** en `supera_25` (`sensibilidad_imputacion_cambios_clase.csv`).",
          fmt(nrow(no_evaluables)), fmt(nrow(muestra)), pct(100 * nrow(no_evaluables) / nrow(muestra)),
          fmt(nrow(comparables)), fmt(nrow(cambios)), pct(100 * nrow(cambios) / nrow(comparables))),
  "",
  "## 4. Distribución de las superaciones",
  "",
  sprintf("PM2.5 diario: media %s, mediana %s, asimetría %s, máximo %s µg/m³, %s extremos (> Q3 + 3·IQR); `descriptivos_pm25_meteo.csv`.",
          pct(g(descriptivos, "PM2.5", "media"), 1), pct(g(descriptivos, "PM2.5", "mediana"), 1), pct(g(descriptivos, "PM2.5", "asimetria"), 2),
          pct(g(descriptivos, "PM2.5", "maximo"), 1), fmt(g(descriptivos, "PM2.5", "extremos_mayores_q3_mas_3iqr"))),
  "",
  sprintf("Por temporada: %s. Por año: %s (rango %s–%s %%). Mayor %% por estación × temporada: %s en %s (%.0f %%, n=%d); menor: %s en %s (%.0f %%, n=%d).",
          paste(sprintf("%s %s %% (n=%s)", por_temp$temporada, pct(por_temp$pct), fmt(por_temp$n)), collapse = "; "),
          paste(sprintf("%d %s %%", por_anio$anio, pct(por_anio$pct)), collapse = ", "), pct(min(por_anio$pct)), pct(max(por_anio$pct)),
          peor_est$estacion, peor_est$temporada, peor_est$pct, peor_est$n, mejor_est$estacion, mejor_est$temporada, mejor_est$pct, mejor_est$n),
  "",
  "## 5. Meteorología según superación (SMD)",
  "",
  "SMD = (media con superación − media sin superación) / DE combinada. Global (`smd_meteo_global.csv`), dentro de cada temporada (`smd_meteo_temporada.csv`) y como anomalía respecto de la media de su estación × temporada (`smd_meteo_anomalia.csv`):",
  "",
  tabla_md(smd_tabla),
  "",
  sprintf("Spearman con PM2.5 (`anexo_matriz_spearman.csv`): máximo |ρ| = %.2f (%s). Días con `horas_lluvia` = 0: **%s %%**.",
          max(abs(rho_pm)), names(rho_pm)[which.max(abs(rho_pm))], pct(pct_sin_lluvia)),
  "",
  sprintf("Viento diario máximo tras D15: %.2f m/s en la base diaria completa (%s, %s) y %.2f m/s en la muestra (%s, %s).",
          dmx$viento_rapidez_ms, dmx$estacion, dmx$fecha, mmx$viento_rapidez_ms, mmx$estacion, mmx$fecha),
  "",
  "## 6. Figuras",
  "",
  "`output/etapa2/figuras/`: `fig1_pm25_boxplot_estacion.png` (PM2.5 por estación, eje log, líneas en 15 y 25), `fig2_heatmap_superacion_estacion_temporada.png` (% de superación por estación × temporada con n) y `fig3_smd_meteo.png` (SMD en cinco versiones, líneas en ±0.2). Anexos: `anexo_meteo_facetas_superacion.png`, `anexo_matriz_spearman.png` y `anexo_superacion_mensual_por_anio.png`.",
  "",
  "## Alcance",
  "",
  "Este documento describe la muestra seleccionada (13 estaciones, 2021–2025), no la calidad del aire de toda la ZMM. `supera_25` es una referencia fija de comparación, no una evaluación del cumplimiento normativo (ver `docs/etapa2/protocolo.md`, sección 3)."
)
con <- file("output/etapa2/RESUMEN.md", "w", encoding = "UTF-8"); writeLines(lineas, con); close(con)
message("Listo: output/etapa2/ y data/clean/muestra_pm25_2021_2025.csv")
