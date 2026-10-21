# =============================================================================================
# Etapa 4: cifras y figuras de la base v2 que necesita el informe final y que no estaban calculadas.
# No ajusta ni cambia ningun modelo de clasificacion.
#
#   1. PCA exploratorio con el ENTRENAMIENTO del analisis final v2 (2021-2023, sitio_valido = 1):
#      mismas reglas de 07a (anomalias por estacion, 8 meteorologicas, prcomp con escalado) y la misma
#      orientacion de signos de 07b (PC1 con TOUT positiva, PC2 con RH positiva, PC3 con PRS negativa).
#      KMO, Bartlett, valores propios, varianza explicada y cargas.
#   2. Varianza de los residuos (r = supera_25 - p) por estacion y por temporada, para M0 y M1, con la
#      prueba de Brown-Forsythe (Levene con la mediana) solo como descripcion: con este n casi siempre
#      rechaza. Usa las predicciones congeladas de 09a.
#   3. Calibracion de M1 por temporada (intercepto y pendiente de la recalibracion, como en 07c).
#   4. Largo de los huecos horarios antes de imputar (13 estaciones, 2021-2025).
#   5. y 6. Figuras compactas para el informe (coeficientes de la meteorologia; ROC y DeltaAUC por
#      temporada y anio), con las mismas salidas congeladas de 09a y 09b.
#   7. Radiacion solar media por estacion y por mes (descriptivo).
#
# Ejecutar desde la raiz:  Rscript scripts/09g_pca_y_residuos_v2.R   (despues de 09a y 09b)
# Escribe: output/etapa4/pca/, output/etapa4/errores/ (residuos_*, calibracion_m1_por_temporada,
#          largo_huecos_horarios), output/etapa4/lda/coeficientes_ic_meteorologia.png y
#          output/etapa4/figuras/roc_y_dauc_informe.png y output/etapa4/descriptivos/sr_*
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas ----------------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
PCA_DIR <- "output/etapa4/pca"; ERR_DIR <- "output/etapa4/errores"
dir.create(PCA_DIR, recursive = TRUE, showWarnings = FALSE); dir.create(ERR_DIR, recursive = TRUE, showWarnings = FALSE)
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")


# ---- Bloque 1. PCA del entrenamiento v2 (reglas de 07a) ------------------------------------------------------
# kmo() y bartlett() son las de 07a. Anomalia = valor menos la media de su estacion en el entrenamiento.
kmo <- function(R) {
  P <- solve(R); A <- -P / sqrt(outer(diag(P), diag(P))); diag(A) <- 0
  R0 <- R; diag(R0) <- 0
  sum(R0^2) / (sum(R0^2) + sum(A^2))
}
bartlett <- function(R, n) c(chi2 = -(n - 1 - (2 * ncol(R) + 5) / 6) * log(det(R)), gl = ncol(R) * (ncol(R) - 1) / 2)
d <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[respuesta_valida == 1L & met_completa_tras_imputar == 1L &
                                                               anio %in% 2021:2023 & sitio_valido == 1L]
d[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
stopifnot(nrow(d) == 10965L)                                   # entrenamiento del analisis final (09a)
d[, (MET) := lapply(.SD, function(x) x - mean(x)), by = estacion, .SDcols = MET]
x <- as.matrix(d[, ..MET]); R <- cor(x)
p <- prcomp(x, scale. = TRUE); ev <- p$sdev^2
cargas_m <- p$rotation[, 1:3] %*% diag(p$sdev[1:3])
signo <- c(sign(cargas_m["TOUT", 1]), sign(cargas_m["RH", 2]), -sign(cargas_m["PRS", 3]))
cargas <- data.table(variable = MET, sweep(cargas_m, 2, signo, `*`)); setnames(cargas, c("variable", "PC1", "PC2", "PC3"))
b <- bartlett(R, nrow(x))
resumen <- data.table(n = nrow(x), kmo = kmo(R), bartlett_chi2 = b[["chi2"]], bartlett_gl = b[["gl"]],
                      bartlett_p = pchisq(b[["chi2"]], b[["gl"]], lower.tail = FALSE), componentes_kaiser = sum(ev > 1),
                      varianza_acum_3 = 100 * sum(ev[1:3]) / sum(ev))
valores <- data.table(componente = paste0("PC", 1:8), valor_propio = ev, pct_varianza = 100 * ev / sum(ev))
fwrite(resumen, file.path(PCA_DIR, "pca_v2_resumen.csv")); fwrite(cargas, file.path(PCA_DIR, "pca_v2_cargas.csv"))
fwrite(valores, file.path(PCA_DIR, "pca_v2_valores_propios.csv"))
print(resumen); print(cargas)
cl <- melt(cargas, id.vars = "variable", variable.name = "componente", value.name = "carga")
cl[, variable := factor(variable, levels = rev(MET))]
cl[, componente := factor(sprintf("%s (%.0f %%)", componente, valores$pct_varianza[match(componente, valores$componente)]))]
g <- ggplot(cl, aes(componente, variable, fill = carga)) +
  geom_tile(colour = "white") + geom_text(aes(label = sprintf("%.2f", carga)), size = 3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), name = "Carga") +
  labs(x = NULL, y = NULL, title = "Cargas del PCA (base v2)", subtitle = "Anomalías por estación, entrenamiento 2021–2023") +
  theme_minimal(base_size = 10) + theme(panel.grid = element_blank())
ggsave(file.path(PCA_DIR, "pca_v2_cargas.png"), g, width = 5, height = 4.5, dpi = 150)


# ---- Bloque 2. Varianza de los residuos por estacion y temporada ------------------------------------------------
# Brown-Forsythe: ANOVA de |r - mediana del grupo| entre grupos. Si rechaza, la dispersion de los
# errores no es igual entre grupos (heterogeneidad). Con miles de dias es casi seguro que rechace.
pred <- fread("output/etapa4/prueba_v2_predicciones.csv")
pred[, `:=`(r_M0 = supera_25 - p_M0, r_M1 = supera_25 - p_M1)]
brown_forsythe <- function(r, g) {
  z <- abs(r - ave(r, g, FUN = median))
  a <- anova(lm(z ~ factor(g)))
  data.table(F = a$`F value`[1], gl1 = a$Df[1], gl2 = a$Df[2], p = a$`Pr(>F)`[1])
}
var_grupo <- function(col) rbindlist(lapply(c("M0", "M1"), function(m) {
  r <- pred[[paste0("r_", m)]]
  pred[, .(n = .N, media_residuo = mean(get(paste0("r_", m))), varianza_residuo = var(get(paste0("r_", m)))), by = col][, modelo := m][]
}))
v_est <- var_grupo("estacion"); v_temp <- var_grupo("temporada")
bf <- rbindlist(lapply(c("M0", "M1"), function(m) rbind(
  cbind(modelo = m, grupo = "estación", brown_forsythe(pred[[paste0("r_", m)]], pred$estacion)),
  cbind(modelo = m, grupo = "temporada", brown_forsythe(pred[[paste0("r_", m)]], pred$temporada)))))
fwrite(v_est, file.path(ERR_DIR, "residuos_varianza_por_estacion.csv")); fwrite(v_temp, file.path(ERR_DIR, "residuos_varianza_por_temporada.csv"))
fwrite(bf, file.path(ERR_DIR, "residuos_brown_forsythe.csv"))
print(bf); print(v_temp[modelo == "M1"])


# ---- Bloque 3. Calibracion de M1 por temporada -------------------------------------------------------------------
cal_temp <- pred[, {
  co <- coef(glm(supera_25 ~ qlogis(p_M1), family = binomial))
  .(n = .N, intercepto = co[[1]], pendiente = co[[2]], p_media = mean(p_M1), frecuencia_observada = mean(supera_25))
}, by = temporada]
fwrite(cal_temp, file.path(ERR_DIR, "calibracion_m1_por_temporada.csv"))
print(cal_temp)


# ---- Bloque 4. Largo de los huecos horarios (serie validada ANTES de imputar) -------------------------------------
# 13 estaciones, 2021-2025. Para cada variable, % de horas faltantes y como se reparten esas horas segun
# el largo del hueco al que pertenecen. Muestra que lo que falta son sobre todo apagones largos.
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); source("R/imputacion.R")
h <- quitar_imputacion(leer_horario_csv(2021:2025))[estacion %in% estaciones_muestra()]
CLASES <- c("1-3 h", "4-6 h", "7-24 h", "1-7 días", "> 7 días")
huecos <- rbindlist(lapply(c("PM2.5", "TOUT", "RH", "SR", "PRS", "viento_u"), function(v) {
  largos <- unlist(lapply(split(h[[v]], h$estacion), function(x) { r <- rle(is.na(x)); r$lengths[r$values] }))
  clase <- cut(largos, c(0, 3, 6, 24, 168, Inf), labels = CLASES)
  tot <- sum(largos)
  data.table(variable = v, pct_horas_faltantes = 100 * tot / nrow(h), clase = CLASES,
             pct_de_las_faltantes = vapply(CLASES, function(k) 100 * sum(largos[clase == k]) / tot, numeric(1)))
}))
fwrite(huecos, file.path(ERR_DIR, "largo_huecos_horarios.csv"))
print(dcast(huecos, variable + pct_horas_faltantes ~ clase, value.var = "pct_de_las_faltantes"))


# ---- Bloque 5. Figura compacta de estabilidad (meteorologia y temporada) para el cuerpo del informe ---------------
# Mismos datos de output/etapa4/lda/estabilidad_coeficientes.csv (09b); la figura completa, con las
# indicadoras de estacion, es output/etapa4/lda/coeficientes_ic.png.
est <- fread("output/etapa4/lda/estabilidad_coeficientes.csv")[tipo != "estación"]
nombres <- c(TOUT = "Temperatura (TOUT)", RH = "Humedad relativa (RH)", SR = "Radiación solar (SR)",
             PRS = "Presión, anomalía de su sitio (PRS)", viento_rapidez_ms = "Rapidez del viento", viento_u = "Viento u (este-oeste)",
             viento_v = "Viento v (norte-sur)", horas_lluvia = "Horas con lluvia",
             temseca_fria = "Temporada seca-fría", temseca_calida = "Temporada seca-cálida")
est[, etiqueta := factor(nombres[predictor], levels = nombres[predictor][order(coef_estandarizado)])]
g <- ggplot(est, aes(coef_estandarizado, etiqueta, colour = signo_estable)) +
  geom_vline(xintercept = 0, colour = "grey50") + geom_pointrange(aes(xmin = coef_li, xmax = coef_ls), size = 0.4) +
  scale_colour_manual(values = c(`TRUE` = "#D55E00", `FALSE` = "grey60"),
                      labels = c(`TRUE` = "signo estable (≥ 95 % de las réplicas)", `FALSE` = "signo no estable"), name = NULL) +
  labs(x = "Coeficiente estandarizado de M1 e IC 95 %", y = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave("output/etapa4/lda/coeficientes_ic_meteorologia.png", g, width = 6.5, height = 3.4, dpi = 150)


# ---- Bloque 6. Figura combinada para el informe: ROC y DeltaAUC por temporada y por anio ------------------------------
# Mismas predicciones congeladas de 09a (prueba_v2_predicciones.csv) y mismos intervalos de
# prueba_v2_dauc_por_temporada.csv y prueba_v2_dauc_por_anio.csv; solo junta dos paneles en una imagen.
COLORES <- c(M0 = "#0072B2", M1 = "#D55E00")
roc0 <- pROC::roc(pred$supera_25, pred$p_M0, levels = c(0, 1), direction = "<", quiet = TRUE)
roc1 <- pROC::roc(pred$supera_25, pred$p_M1, levels = c(0, 1), direction = "<", quiet = TRUE)
curvas <- rbind(data.table(modelo = sprintf("M0 (AUC %.3f)", as.numeric(roc0$auc)), fpr = 1 - roc0$specificities, tpr = roc0$sensitivities),
                data.table(modelo = sprintf("M1 (AUC %.3f)", as.numeric(roc1$auc)), fpr = 1 - roc1$specificities, tpr = roc1$sensitivities))
g_roc <- ggplot(curvas[order(modelo, fpr, tpr)], aes(fpr, tpr, colour = modelo)) +
  geom_abline(linetype = "dotted", colour = "grey50") + geom_path(linewidth = 0.8) +
  scale_colour_manual(values = unname(COLORES), name = NULL) + coord_equal() +
  labs(x = "1 − especificidad", y = "Sensibilidad", title = "(a) Curvas ROC") +
  theme_minimal(base_size = 10) + theme(legend.position = c(0.68, 0.18))
nom_t <- c(seca_fria = "Seca-fría (nov–feb)", seca_calida = "Seca-cálida (mar–may)", calida_humeda = "Lluvias (jun–oct)")
grupos <- rbind(
  fread("output/etapa4/prueba_v2_dauc_por_temporada.csv")[, .(grupo = "Temporada", etiqueta = nom_t[sub("Temporada: ", "", analisis)], d_auc, d_auc_li, d_auc_ls)],
  fread("output/etapa4/prueba_v2_dauc_por_anio.csv")[, .(grupo = "Año", etiqueta = sub("Año ", "", analisis), d_auc, d_auc_li, d_auc_ls)],
  fread("output/etapa4/prueba_v2_sensibilidades.csv")[1, .(grupo = "Total", etiqueta = "2024–2025", d_auc, d_auc_li, d_auc_ls)])
grupos[, etiqueta := factor(etiqueta, levels = rev(etiqueta))][, grupo := factor(grupo, levels = c("Total", "Temporada", "Año"))]
g_dauc <- ggplot(grupos, aes(d_auc, etiqueta)) + geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = d_auc_li, xmax = d_auc_ls), colour = "#D55E00", size = 0.35) +
  geom_text(aes(label = sprintf("%.3f", d_auc)), vjust = -0.9, size = 2.8) +
  facet_grid(grupo ~ ., scales = "free_y", space = "free_y") +
  labs(x = "ΔAUC (M1 − M0) e IC 95 %", y = NULL, title = "(b) ΔAUC por temporada y año") +
  theme_minimal(base_size = 10) + theme(strip.text.y = element_text(angle = 0))
png("output/etapa4/figuras/roc_y_dauc_informe.png", width = 7, height = 3.3, units = "in", res = 200)
grid::grid.newpage(); grid::pushViewport(grid::viewport(layout = grid::grid.layout(1, 2, widths = grid::unit(c(0.45, 0.55), "npc"))))
print(g_roc, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
print(g_dauc, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
invisible(dev.off())


# ---- Bloque 7. Radiacion solar media por estacion (descriptivo para la tabla de cambios de la red) -----------------
# Media diaria de SR observada (sin imputacion diaria) en 2021-2025, por estacion y por mes. NO2 y NTE leen
# mucho mas bajo que el resto; va como pregunta para SIMA, no cambia el analisis.
dsr <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv", select = c("estacion", "fecha", "SR", "imp_SR"))[imp_SR == 0L & !is.na(SR)]
sr_est <- dsr[, .(dias = .N, sr_media = mean(SR), sr_mediana = median(SR)), by = estacion][order(sr_media)]
fwrite(sr_est, "output/etapa4/descriptivos/sr_media_por_estacion.csv")
print(sr_est)
dsr[, mes := as.IDate(format(as.IDate(fecha), "%Y-%m-01"))]
sr_mes <- dsr[, .(sr_media = mean(SR)), by = .(estacion, mes)]
g <- ggplot(sr_mes, aes(mes, sr_media, group = estacion)) +
  geom_line(colour = "grey75", linewidth = 0.4) +
  geom_line(data = sr_mes[estacion %in% c("NO2", "NTE")], aes(colour = estacion), linewidth = 0.8) +
  labs(x = NULL, y = "SR media diaria (kW/m²)", colour = NULL, title = "Radiación solar mensual por estación, 2021–2025",
       subtitle = "En gris, las demás estaciones") +
  theme_minimal(base_size = 10)
ggsave("output/etapa4/descriptivos/sr_mensual_por_estacion.png", g, width = 6.5, height = 3.2, dpi = 150)
message("Listo: ", PCA_DIR, " y ", ERR_DIR)
