# =============================================================================================
# Figuras de la presentacion (etapa 3) en tamaño de diapositiva.
# Mismo codigo y mismos datos que scripts/07c (mapa) y la figura dauc_temporada.png; solo cambian
# el tamaño de letra, se quita el titulo interno (lo pone la diapositiva) y se rotulan los valores.
#   Rscript docs/presentacion/figuras_presentacion.R
# Lee: output/etapa3/diagnostico/mapa_estaciones.csv, output/etapa3/prueba_dauc_por_temporada.csv
# Escribe: docs/presentacion/figuras/*.png
# =============================================================================================
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
dir.create("docs/presentacion/figuras", showWarnings = FALSE)

# ---- 1. Mapa de estaciones: % de dias con superacion (datos de 07c) ----------------------------
mapa <- fread("output/etapa3/diagnostico/mapa_estaciones.csv")
lat_m <- mean(mapa$latitud); km_por_grado_lon <- 111.32 * cos(lat_m * pi / 180)
x0 <- min(mapa$longitud); y0 <- min(mapa$latitud) - 0.025
# Etiquetas a un lado del punto para que no se encimen; a la izquierda donde hay vecinos a la derecha.
izquierda <- c("SO", "NO", "NTE2")
abajo <- "SO2"
mapa[, `:=`(lx = longitud + ifelse(estacion %in% izquierda, -0.02, 0.02), ly = latitud,
            h = ifelse(estacion %in% izquierda, 1, 0))]
mapa[estacion %in% abajo, `:=`(lx = longitud, ly = latitud - 0.025, h = 0.5)]
mapa[estacion == "CE", `:=`(lx = longitud, ly = latitud + 0.024, h = 0.5)]   # arriba: a la derecha toca SE
g <- ggplot(mapa, aes(longitud, latitud)) +
  geom_point(aes(fill = pct_superacion), shape = 21, size = 7, colour = "grey20") +
  geom_text(aes(x = lx, y = ly, label = estacion, hjust = h), size = 6.5, fontface = "bold", colour = "grey15") +
  annotate("segment", x = x0, xend = x0 + 10 / km_por_grado_lon, y = y0, yend = y0, linewidth = 1.2) +
  annotate("text", x = x0 + 5 / km_por_grado_lon, y = y0 + 0.02, label = "10 km", size = 5.5) +
  scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "% de días\ncon PM2.5\n> 25 µg/m³",
                       breaks = c(10, 20, 30, 40)) +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.17))) +
  scale_y_continuous(expand = expansion(mult = c(0.06, 0.08))) +
  coord_quickmap() + labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 18) +
  theme(panel.grid = element_blank(), axis.text = element_blank(),
        legend.title = element_text(size = 14), legend.text = element_text(size = 13),
        legend.key.height = unit(0.7, "cm"))
ggsave("docs/presentacion/figuras/mapa_estaciones_diapositiva.png", g, width = 6.2, height = 3.2, dpi = 240, bg = "white")

# ---- 2. dAUC por temporada con su IC (datos de 07b) --------------------------------------------
dt <- fread("output/etapa3/prueba_dauc_por_temporada.csv")[, temporada := sub("Temporada: ", "", analisis)]
etiquetas <- c(seca_fria = "Seca fría\n(nov–feb)", seca_calida = "Seca cálida\n(mar–may)",
               calida_humeda = "Cálida húmeda\n(jun–oct)")
dt[, nombre := factor(etiquetas[temporada], levels = rev(etiquetas[c("seca_fria", "seca_calida", "calida_humeda")]))]
g <- ggplot(dt, aes(d_auc, nombre)) + geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.8) +
  geom_errorbar(aes(xmin = d_auc_li, xmax = d_auc_ls), width = 0, orientation = "y", colour = "#D55E00", linewidth = 1.6) +
  geom_point(colour = "#D55E00", size = 6) +
  geom_text(aes(label = sprintf("%+.2f", d_auc)), nudge_y = 0.32, size = 7, fontface = "bold", colour = "#D55E00") +
  scale_x_continuous(breaks = c(0, 0.05, 0.10, 0.15), labels = function(x) sprintf("%.2f", x)) +
  labs(x = "Mejora del AUC (M1 − M0)\ne IC 95 %", y = NULL) +
  theme_minimal(base_size = 20) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        axis.text.y = element_text(colour = "grey15", size = 19, lineheight = 0.9),
        axis.text.x = element_text(colour = "grey40", size = 16), plot.margin = margin(8, 16, 8, 8))
ggsave("docs/presentacion/figuras/dauc_temporada_diapositiva.png", g, width = 6.4, height = 3.6, dpi = 200, bg = "white")
# ---- 3. Curvas ROC de M0 y M1 en la prueba (predicciones congeladas de modelo_final.rds) -------
mf <- readRDS("output/etapa3/modelo_final.rds"); pr <- mf$predicciones_prueba
roc0 <- pROC::roc(pr$supera_25, pr$p_M0, levels = c(0, 1), direction = "<", quiet = TRUE)
roc1 <- pROC::roc(pr$supera_25, pr$p_M1, levels = c(0, 1), direction = "<", quiet = TRUE)
curvas <- rbind(data.table(modelo = sprintf("M0: estación + temporada (AUC %.2f)", pROC::auc(roc0)), fpr = 1 - roc0$specificities, tpr = roc0$sensitivities),
                data.table(modelo = sprintf("M1: + meteorología del día (AUC %.2f)", pROC::auc(roc1)), fpr = 1 - roc1$specificities, tpr = roc1$sensitivities))
g <- ggplot(curvas[order(modelo, fpr, tpr)], aes(fpr, tpr, colour = modelo)) +
  geom_abline(linetype = "dotted", colour = "grey55") + geom_path(linewidth = 1.6) +
  scale_colour_manual(values = c("#0072B2", "#D55E00"), name = NULL) + coord_equal() +
  labs(x = "Falsas alarmas (1 − especificidad)", y = "Detección (sensibilidad)") +
  theme_minimal(base_size = 17) +
  theme(legend.position = "inside", legend.position.inside = c(0.56, 0.15), legend.text = element_text(size = 13.5),
        panel.grid.minor = element_blank())
ggsave("docs/presentacion/figuras/roc_m0_m1_diapositiva.png", g, width = 5.6, height = 5.6, dpi = 200, bg = "white")
cat("Figuras escritas en docs/presentacion/figuras/\n")
