# =============================================================================================
# Presentación final: figuras regeneradas para las diapositivas. Solo cambia la presentación (tamaño
# final de la diapositiva, letra de 16 pt o más, sin título interno, etiquetas en español, 300 dpi);
# no ajusta ni cambia ningún modelo. Lee los CSV ya calculados de output/etapa4/ y, para la
# exploración (diapositiva 4), la base v2 con la misma muestra del análisis final (17 828 días-estación).
#
#   pres_mapa.png                  Diap. 3  mapa de estaciones: altitud y % de días con superación
#   pres_superacion_temporada.png  Diap. 4  % de días-estación con superación por temporada
#   pres_temperatura_simpson.png   Diap. 4  diferencia de temperatura (superación − no superación)
#   pres_pca_cargas.png            Diap. 7  cargas de los tres primeros componentes
#   pres_roc.png                   Diap. 8  curvas ROC de M0 y M1 en la prueba (LDA)
#   pres_dauc_temporada.png        Diap. 9  ΔAUC por temporada con IC 95 %
#   pres_or_logistica.png          Diap. 9  odds ratio de la logística (variables de signo estable)
#   pres_persistencia.png          Diap. 10 AUC de M0, M1, MP y MP1 (PM2.5 del día anterior)
#   pres_umbral.png                Diap. 10 sensibilidad, especificidad y VPP según el corte
#
# Colores: M0 azul #0072B2 y M1 naranja #D55E00 (paleta de Okabe e Ito, apta para daltonismo).
# Ejecutar desde la raíz:  Rscript scripts/11_figuras_presentacion.R   (después de 09a–09g y 10)
# Escribe en docs/presentacion_final/figuras/.
# =============================================================================================


# ---- Bloque 0. Paquetes, carpetas y tema --------------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(pROC)
})
E4 <- "output/etapa4"; RF <- file.path(E4, "retro_final")
SALIDA <- "docs/presentacion_final/figuras"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)

COL_M0 <- "#0072B2"; COL_M1 <- "#D55E00"; COL_MP <- "#6A5ACD"; COL_MP1 <- "#222222"
TINTA <- "#1F3B4D"; GRIS <- "#6B7C88"
PT <- 16                                  # tamaño mínimo de la letra, en puntos, al tamaño final
tema <- theme_minimal(base_size = PT, base_family = "sans") +
  theme(text = element_text(colour = TINTA, size = PT),
        axis.text = element_text(colour = TINTA, size = PT), axis.title = element_text(size = PT),
        legend.text = element_text(size = PT), legend.title = element_text(size = PT),
        strip.text = element_text(size = PT, face = "bold"),
        panel.grid.minor = element_blank(), plot.margin = margin(4, 8, 4, 4))
guardar <- function(g, nombre, ancho, alto) {
  ggsave(file.path(SALIDA, nombre), g, width = ancho, height = alto, dpi = 300, bg = "white", device = ragg::agg_png)
  message("  ", nombre, " (", ancho, " x ", alto, " pulgadas)")
}
txt <- PT / .pt                           # tamaño de geom_text equivalente a PT puntos


# ---- Bloque 1. Muestra del análisis final (para la exploración) ---------------------------------------------
# Misma muestra que el paso 4 de 09a: respuesta válida y las 8 meteorológicas completas tras la imputación
# diaria; el entrenamiento (2021–2023) sin los días previos a la reubicación (sitio_valido = 1).
v <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")
d <- v[respuesta_valida == 1L & met_completa_tras_imputar == 1L & (anio >= 2024L | sitio_valido == 1L)]
stopifnot(nrow(d) == 17828L)
nombre_temp <- c(seca_fria = "Nov–feb\n(seca-fría)", seca_calida = "Mar–may\n(seca-cálida)", calida_humeda = "Jun–oct\n(lluvias)")
orden_temp <- c("seca_fria", "seca_calida", "calida_humeda")


# ---- Bloque 2. Mapa de estaciones ---------------------------------------------------------------------------
# Mismo dibujo que la Figura 1 del informe (puntos con latitud y longitud, sin mapa base); el color da el %
# de días con superación y el número dentro del punto, ese porcentaje. Etiqueta (código y altitud) fuera.
mapa <- fread(file.path(E4, "area_estudio/mapa_estaciones_altitud.csv"))
mapa[, `:=`(pct_txt = sprintf("%.0f", pct_superacion_v2), etiqueta = sprintf("%s %d", estacion, altitud_msnm),
            dx = 0, dy = 0.02, hj = 0.5, vj = 0)]
pos <- function(e, ddx, ddy, hhj, vvj) mapa[estacion == e, `:=`(dx = ddx, dy = ddy, hj = hhj, vj = vvj)]
pos("SO", 0, 0.02, 0.5, 0); pos("SO2", 0, -0.02, 0.5, 1); pos("SUR", 0, -0.02, 0.5, 1)
pos("NO2", 0, 0.02, 0.5, 0); pos("SE3", 0, -0.02, 0.5, 1); pos("SE2", 0, 0.02, 0.5, 0)
pos("NE2", 0, 0.02, 0.5, 0); pos("SE", 0.016, 0, 0, 0.5); pos("CE", 0, -0.02, 0.5, 1)
pos("NE", 0.016, 0, 0, 0.5); pos("NTE", 0, 0.02, 0.5, 0); pos("NTE2", -0.016, 0, 1, 0.5)
pos("NO", -0.016, 0, 1, 0.5)
lat_m <- mean(mapa$latitud); km_lon <- 111.32 * cos(lat_m * pi / 180)
x0 <- min(mapa$longitud) + 0.005; y0 <- min(mapa$latitud) - 0.035
g_mapa <- ggplot(mapa, aes(longitud, latitud)) +
  geom_point(aes(fill = pct_superacion_v2), shape = 21, size = 9.5, colour = TINTA, stroke = 0.8) +
  geom_text(aes(label = pct_txt, colour = pct_superacion_v2 > 33), size = txt, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = TINTA)) +
  geom_text(aes(x = longitud + dx, y = latitud + dy, label = etiqueta, hjust = hj, vjust = vj), size = txt, colour = TINTA) +
  annotate("segment", x = x0, xend = x0 + 10 / km_lon, y = y0, yend = y0, linewidth = 1.2, colour = TINTA) +
  annotate("text", x = x0 + 5 / km_lon, y = y0 + 0.014, label = "10 km", size = txt, colour = TINTA) +
  scale_fill_gradient(low = "#FFF1C7", high = "#B03A00", limits = c(0, 50), breaks = c(0, 25, 50),
                      name = "% de días con PM2.5 > 25", guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0.07, 0.08))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.06))) +
  coord_quickmap() + labs(x = NULL, y = NULL) +
  tema + theme(axis.text = element_blank(), panel.grid = element_blank(), legend.position = "inside", legend.position.inside = c(0.998, 0.80),
               legend.justification = c(1, 1), legend.key.width = grid::unit(1.5, "cm"), legend.direction = "horizontal",
               legend.title.position = "top")
guardar(g_mapa, "pres_mapa.png", 11.9, 4.1)


# ---- Bloque 3. Exploración: superación por temporada y la paradoja de la temperatura ------------------------
sup_t <- d[, .(pct = 100 * mean(supera_25), n = .N), by = temporada][, temporada := factor(temporada, orden_temp)]
g_sup <- ggplot(sup_t, aes(temporada, pct)) +
  geom_col(fill = GRIS, width = 0.62) +
  geom_text(aes(label = sprintf("%.1f %%", pct)), vjust = -0.4, size = txt * 1.15, fontface = "bold", colour = TINTA) +
  scale_x_discrete(labels = nombre_temp) +
  scale_y_continuous(limits = c(0, 45), expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "% de días-estación\ncon PM2.5 > 25 µg/m³") + tema +
  theme(panel.grid.major.x = element_blank())
guardar(g_sup, "pres_superacion_temporada.png", 5.4, 3.7)

dif <- rbind(
  data.table(grupo = "Todos los días\njuntos", dT = d[, mean(TOUT[supera_25 == 1L]) - mean(TOUT[supera_25 == 0L])]),
  d[, .(dT = mean(TOUT[supera_25 == 1L]) - mean(TOUT[supera_25 == 0L])), by = temporada][
    , .(grupo = gsub("\n", " ", nombre_temp[temporada]), dT)])
dif[, grupo := gsub("\\(|\\)", "", sub(" ", "\n", grupo))]
dif[1, grupo := "Todos los días\njuntos"]
dif[, grupo := factor(grupo, rev(grupo))]
dif[, signo := ifelse(dT < 0, "neg", "pos")]
g_simp <- ggplot(dif, aes(dT, grupo)) +
  geom_vline(xintercept = 0, colour = TINTA, linewidth = 0.8) +
  geom_segment(aes(x = 0, xend = dT, yend = grupo, colour = signo), linewidth = 2.2) +
  geom_point(aes(colour = signo), size = 5) +
  geom_text(aes(label = sprintf("%+.1f °C", dT), hjust = ifelse(dT < 0, 1.25, -0.25)), size = txt * 1.1, fontface = "bold", colour = TINTA) +
  scale_colour_manual(values = c(neg = GRIS, pos = COL_M1), guide = "none") +
  scale_x_continuous(limits = c(-2.1, 4.9), breaks = c(-2, 0, 2, 4)) +
  labs(x = "Diferencia de temperatura media (°C):\ndías con superación − días sin superación", y = NULL) + tema +
  theme(panel.grid.major.y = element_blank())
guardar(g_simp, "pres_temperatura_simpson.png", 5.8, 3.7)


# ---- Bloque 4. Cargas del PCA -------------------------------------------------------------------------------
cargas <- fread(file.path(E4, "pca/pca_v2_cargas.csv"))
ve <- fread(file.path(E4, "pca/pca_v2_valores_propios.csv"))
nombre_var <- c(TOUT = "Temperatura", RH = "Humedad relativa", SR = "Radiación solar", PRS = "Presión (anomalía)",
                viento_rapidez_ms = "Rapidez del viento", viento_u = "Viento u (este-oeste)",
                viento_v = "Viento v (norte-sur)", horas_lluvia = "Horas con lluvia")
eje <- c(PC1 = "Calor y\nradiación", PC2 = "Humedad y\nflujo del este", PC3 = "Presión baja\ny lluvia")
cl <- melt(cargas, id.vars = "variable", variable.name = "pc", value.name = "carga")
cl[, `:=`(variable = factor(nombre_var[variable], rev(nombre_var)),
          eje = sprintf("%s · %.0f %%\n%s", pc, ve$pct_varianza[match(pc, ve$componente)], eje[as.character(pc)]))]
g_pca <- ggplot(cl, aes(eje, variable, fill = carga)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("%.2f", carga), colour = abs(carga) > 0.55), size = txt, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = TINTA)) +
  scale_fill_gradient2(low = "#B5446E", mid = "#F4F7F9", high = "#0B7A75", midpoint = 0, limits = c(-0.9, 0.9), guide = "none") +
  scale_x_discrete(position = "top") + labs(x = NULL, y = NULL) +
  tema + theme(panel.grid = element_blank(), axis.text.x = element_text(lineheight = 0.95))
guardar(g_pca, "pres_pca_cargas.png", 7.4, 4.7)


# ---- Bloque 5. Curvas ROC de M0 y M1 en la prueba (LDA, análisis final) -------------------------------------
pr <- fread(file.path(E4, "prueba_v2_predicciones.csv"))
stopifnot(nrow(pr) == 6863L)
curva <- function(p, m) {
  r <- roc(pr$supera_25, p, levels = c(0, 1), direction = "<", quiet = TRUE)
  data.table(modelo = m, fpr = 1 - r$specificities, tpr = r$sensitivities, auc = as.numeric(auc(r)))
}
roc_dt <- rbind(curva(pr$p_M0, "M0"), curva(pr$p_M1, "M1"))
met <- fread(file.path(E4, "prueba_v2_metricas_m0_m1.csv"))
stopifnot(abs(roc_dt[modelo == "M0", auc[1]] - met[modelo == "M0", auc]) < 1e-9)
puntos <- met[, .(modelo, fpr = 1 - especificidad, tpr = sensibilidad)]
g_roc <- ggplot(roc_dt, aes(fpr, tpr, colour = modelo)) +
  geom_abline(slope = 1, intercept = 0, colour = GRIS, linetype = "dashed", linewidth = 0.8) +
  geom_step(linewidth = 1.8) +
  geom_point(data = puntos, size = 5.5, shape = 21, fill = "white", stroke = 2) +
  annotate("text", x = 1, y = 0.27, label = sprintf("M0: AUC %.3f", met[modelo == "M0", auc]), colour = COL_M0, size = txt, fontface = "bold", hjust = 1) +
  annotate("text", x = 1, y = 0.17, label = sprintf("M1: AUC %.3f", met[modelo == "M1", auc]), colour = COL_M1, size = txt, fontface = "bold", hjust = 1) +
  annotate("text", x = 1, y = 0.07, label = "círculo: corte 0.259", colour = GRIS, size = txt, hjust = 1) +
  scale_colour_manual(values = c(M0 = COL_M0, M1 = COL_M1), guide = "none") +
  scale_x_continuous(breaks = seq(0, 1, 0.25), expand = expansion(mult = 0.01)) +
  scale_y_continuous(breaks = seq(0, 1, 0.25), expand = expansion(mult = 0.01)) +
  coord_equal() + labs(x = "1 − especificidad", y = "Sensibilidad") + tema
guardar(g_roc, "pres_roc.png", 4.4, 4.0)


# ---- Bloque 6. ΔAUC por temporada con IC 95 % ---------------------------------------------------------------
dt <- fread(file.path(E4, "prueba_v2_dauc_por_temporada.csv"))
gl <- fread(file.path(E4, "prueba_v2_sensibilidades.csv"))[1]
dd <- rbind(
  dt[, .(grupo = sub("Temporada: ", "", analisis), d_auc, li = d_auc_li, ls = d_auc_ls)],
  data.table(grupo = "global", d_auc = gl$d_auc, li = gl$d_auc_li, ls = gl$d_auc_ls))
nom_g <- c(seca_calida = "Mar–may (seca-cálida)", seca_fria = "Nov–feb (seca-fría)", calida_humeda = "Jun–oct (lluvias)", global = "Todo el periodo")
dd[, grupo := factor(nom_g[grupo], rev(nom_g[c("seca_calida", "seca_fria", "calida_humeda", "global")]))]
dd[, tipo := ifelse(grupo == "Todo el periodo", "g", ifelse(li > 0, "s", "n"))]
g_dauc <- ggplot(dd, aes(d_auc, grupo, colour = tipo)) +
  geom_vline(xintercept = 0, colour = TINTA, linewidth = 0.8) +
  geom_errorbar(aes(xmin = li, xmax = ls), width = 0.22, linewidth = 1.6, orientation = "y") +
  geom_point(size = 5.5) +
  geom_text(aes(x = ls, label = sprintf("%+.3f", d_auc)), hjust = -0.25, size = txt * 1.1, fontface = "bold", colour = TINTA) +
  scale_colour_manual(values = c(s = COL_M1, n = GRIS, g = TINTA), guide = "none") +
  scale_x_continuous(limits = c(-0.04, 0.32), breaks = seq(0, 0.2, 0.1)) +
  labs(x = "Mejora del AUC, IC 95 %", y = NULL) + tema + theme(panel.grid.major.y = element_blank())
guardar(g_dauc, "pres_dauc_temporada.png", 5.8, 3.2)


# ---- Bloque 7. Odds ratio de la logística (variables de signo estable) --------------------------------------
orr <- fread(file.path(RF, "a1_odds_ratios_logistica.csv"))
orr <- orr[tipo == "meteorología" & signo_estable == TRUE]
nom_o <- c(viento_rapidez_ms = "Viento más fuerte", PRS = "Presión más alta\nque lo normal", TOUT = "Temperatura más alta",
           SR = "Más radiación solar", horas_lluvia = "Más horas de lluvia")
orr[, `:=`(etq = factor(nom_o[predictor], rev(nom_o[c("viento_rapidez_ms", "PRS", "TOUT", "SR", "horas_lluvia")])),
           clave = predictor %in% c("viento_rapidez_ms", "PRS", "TOUT"))]
g_or <- ggplot(orr, aes(odds_ratio, etq, colour = clave)) +
  geom_vline(xintercept = 1, colour = TINTA, linewidth = 0.8) +
  geom_errorbar(aes(xmin = or_li, xmax = or_ls), width = 0.25, linewidth = 1.6, orientation = "y") +
  geom_point(size = 5.5) +
  geom_text(aes(x = 3.3, label = sprintf("%.2f", odds_ratio)), hjust = 0, size = txt * 1.1, fontface = "bold", colour = TINTA) +
  scale_colour_manual(values = c(`TRUE` = COL_M1, `FALSE` = GRIS), guide = "none") +
  scale_x_log10(limits = c(0.3, 4.6), breaks = c(0.5, 1, 2)) +
  labs(x = "Odds ratio por 1 DE, IC 95 %", y = NULL) + tema + theme(panel.grid.major.y = element_blank())
guardar(g_or, "pres_or_logistica.png", 5.8, 3.4)


# ---- Bloque 8. Persistencia: AUC de M0, M1, MP y MP1 (submuestra con PM2.5 del día anterior) ---------------
pa <- fread(file.path(RF, "b_persistencia_auc.csv"))[clasificador == "lda"]
nom_m <- c(M0 = "M0\nbase", M1 = "M1\n+ clima", MP = "MP\n+ ayer", MP1 = "MP1\n+ ambos")
pa[, etq := factor(nom_m[modelo], nom_m)]
g_per <- ggplot(pa, aes(etq, auc, colour = modelo)) +
  geom_hline(yintercept = 0.5, colour = GRIS, linetype = "dashed", linewidth = 0.8) +
  geom_segment(aes(xend = etq, y = 0.5, yend = auc), linewidth = 2.4) +
  geom_point(size = 6) +
  geom_text(aes(label = sprintf("%.3f", auc)), vjust = -1.2, size = txt * 1.15, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(M0 = COL_M0, M1 = COL_M1, MP = COL_MP, MP1 = COL_MP1), guide = "none") +
  scale_y_continuous(limits = c(0.5, 0.95), breaks = seq(0.5, 0.9, 0.1), expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "AUC en la prueba") + tema +
  theme(panel.grid.major.x = element_blank(), axis.text.x = element_text(lineheight = 0.95))
guardar(g_per, "pres_persistencia.png", 5.8, 3.7)


# ---- Bloque 9. Umbral: sensibilidad, especificidad y VPP según el corte -------------------------------------
cm <- fread(file.path(RF, "c_metricas_por_corte.csv"))[clasificador == "lda"]
cp <- fread(file.path(RF, "c_cortes_en_prueba.csv"))[clasificador == "lda" & objetivo == "vigilancia"]
largo <- melt(cm, id.vars = "corte", measure.vars = c("sensibilidad", "especificidad", "vpp"), variable.name = "metrica", value.name = "valor")
nom_k <- c(sensibilidad = "Sensibilidad", especificidad = "Especificidad", vpp = "VPP")
etq_k <- sprintf("%s %.2f", nom_k, unlist(cp[, .(sensibilidad, especificidad, vpp)]))
largo[, metrica := factor(nom_k[as.character(metrica)], nom_k, labels = etq_k)]
marca <- melt(cp, id.vars = "corte", measure.vars = c("sensibilidad", "especificidad", "vpp"), variable.name = "metrica", value.name = "valor")
marca[, metrica := factor(nom_k[as.character(metrica)], nom_k, labels = etq_k)]
cols_k <- setNames(c("#009E73", "#CC79A7", GRIS), etq_k)
g_umb <- ggplot(largo, aes(corte, valor, colour = metrica)) +
  geom_vline(xintercept = cp$corte, colour = TINTA, linetype = "dashed", linewidth = 0.9) +
  geom_line(linewidth = 1.8) +
  geom_point(data = marca, size = 6, shape = 21, fill = "white", stroke = 2.2) +
  annotate("text", x = cp$corte + 0.012, y = 0.98, label = sprintf("corte %.3f", cp$corte), hjust = 0, size = txt, colour = TINTA) +
  scale_colour_manual(values = cols_k, name = NULL) +
  scale_x_continuous(breaks = seq(0.1, 0.6, 0.1)) + scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = "Corte de probabilidad (M1, LDA)", y = "Valor en la prueba") + tema +
  theme(legend.position = "inside", legend.position.inside = c(0.99, 0.02), legend.justification = c(1, 0),
        legend.background = element_rect(fill = "white", colour = NA))
guardar(g_umb, "pres_umbral.png", 5.8, 3.7)

message("Listo: ", length(list.files(SALIDA, pattern = "^pres_.*png$")), " figuras en ", SALIDA)
