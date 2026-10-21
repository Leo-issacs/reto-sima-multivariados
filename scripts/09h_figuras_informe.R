# =============================================================================================
# Etapa 4: version para el informe final de tres figuras ya calculadas. Solo cambia la presentacion
# (etiquetas en espanol, tamano de letra para el ancho de pagina); no recalcula nada: lee los CSV que
# guardaron 08a, 09c y 09g y no ajusta ni cambia ningun modelo.
#
#   1. Mapa de estaciones con altitud (datos de 09c: area_estudio/mapa_estaciones_altitud.csv).
#   2. RMSE del promedio diario por metodo y largo del hueco (datos de 08a: imputacion/enmascaramiento_horario.csv;
#      umbral de imputacion/eleccion_metodo_horario.csv).
#   3. Cargas del PCA v2 (datos de 09g: pca/pca_v2_cargas.csv y pca/pca_v2_valores_propios.csv).
#
# Las figuras originales de 08a, 09c y 09g se conservan sin cambios.
# Ejecutar desde la raiz:  Rscript scripts/09h_figuras_informe.R   (despues de 08a, 09c y 09g)
# Escribe: output/etapa4/figuras/{mapa_estaciones_informe,rmse_imputacion_informe,pca_cargas_informe}.png
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas -------------------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
E4 <- "output/etapa4"; SALIDA <- file.path(E4, "figuras")
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
guardar <- function(g, nombre, ancho, alto) ggsave(file.path(SALIDA, nombre), g, width = ancho, height = alto, dpi = 250, bg = "white")


# ---- Bloque 1. Mapa de estaciones con altitud ---------------------------------------------------------------
# Mismo dibujo que 09c (puntos con latitud y longitud, sin mapa base, escala de 10 km), a todo el ancho de
# texto (6.5 pulgadas) y con letra de 9 pt. Etiqueta arriba del punto, salvo SO (a la izquierda) y SO2 y
# SUR (abajo), que quedarian encimadas con sus vecinas.
mapa <- fread(file.path(E4, "area_estudio/mapa_estaciones_altitud.csv"))
mapa[, `:=`(etiqueta = sprintf("%s\n%d m", estacion, altitud_msnm), dx = 0, dy = 0.013, hj = 0.5, vj = 0)]
mapa[estacion == "SO", `:=`(dx = -0.014, dy = 0, hj = 1, vj = 0.5)]
mapa[estacion %in% c("SO2", "SUR"), `:=`(dy = -0.013, vj = 1)]
lat_m <- mean(mapa$latitud); km_por_grado_lon <- 111.32 * cos(lat_m * pi / 180)
x0 <- min(mapa$longitud) + 0.01; y0 <- min(mapa$latitud) - 0.02
g <- ggplot(mapa, aes(longitud, latitud)) +
  geom_point(aes(fill = pct_superacion_v2), shape = 21, size = 6.5, colour = "grey20") +
  geom_text(aes(x = longitud + dx, y = latitud + dy, label = etiqueta, hjust = hj, vjust = vj), size = 3.2, lineheight = 0.85) +
  annotate("segment", x = x0, xend = x0 + 10 / km_por_grado_lon, y = y0, yend = y0, linewidth = 1) +
  annotate("text", x = x0 + 5 / km_por_grado_lon, y = y0 + 0.009, label = "10 km", size = 3.2) +
  scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "% de días con\nPM2.5 > 25 µg/m³") +
  scale_y_continuous(expand = expansion(mult = c(0.10, 0.16))) +
  coord_quickmap() +
  labs(x = "Longitud", y = "Latitud") +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), legend.title = element_text(size = 9))
guardar(g, "mapa_estaciones_informe.png", 6.5, 3.2)


# ---- Bloque 2. RMSE del promedio diario por metodo y largo del hueco ----------------------------------------
# Mismos datos y escalas que la figura de 08a (log2 en x, log10 en y, umbral punteado = 0.10 x DE de la
# anomalia diaria); paneles y metodos con nombre en espanol y la leyenda en el hueco del octavo panel.
METODOS <- c(linear = "Lineal", spline = "Spline", stine = "Stineman", ma_exp = "Media móvil exponencial",
             kalman = "Kalman", seadec = "Descomposición estacional", locf = "LOCF")
COLORES <- setNames(c("#000000", "#E69F00", "#56B4E9", "#009E73", "#D55E00", "#0072B2", "#999999"), METODOS)
PANELES <- c(TOUT = "Temperatura (°C)", RH = "Humedad relativa (%)", SR = "Radiación solar (kW/m²)", PRS = "Presión (mm Hg)",
             viento_u = "Viento u (m/s)", viento_v = "Viento v (m/s)", PM2.5 = "PM2.5 (µg/m³)")
LARGOS <- c(1, 2, 3, 6, 12, 24)
r <- fread(file.path(E4, "imputacion/enmascaramiento_horario.csv"))[, .(variable, metodo, largo_hueco_h, rmse_diario)]
stopifnot(setequal(r$variable, names(PANELES)), setequal(r$metodo, names(METODOS)), setequal(r$largo_hueco_h, LARGOS))
u <- fread(file.path(E4, "imputacion/eleccion_metodo_horario.csv"))[, .(variable, umbral = umbral_rmse_diario)]
r[, `:=`(panel = factor(PANELES[variable], levels = PANELES), metodo = factor(METODOS[metodo], levels = METODOS))]
u[, panel := factor(PANELES[variable], levels = PANELES)]
g <- ggplot(r, aes(largo_hueco_h, rmse_diario, colour = metodo)) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.1) +
  geom_hline(data = u, aes(yintercept = umbral), linetype = "dotted", colour = "#B22222") +
  scale_x_continuous(trans = "log2", breaks = LARGOS) +
  scale_y_log10() +
  scale_colour_manual(values = COLORES, name = "Método") +
  facet_wrap(~panel, scales = "free_y", ncol = 4) +
  labs(x = "Largo del hueco borrado (h, escala log2)", y = "RMSE del promedio diario (escala log)") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "inside", legend.position.inside = c(0.875, 0.25), legend.key.height = unit(0.3, "cm"),
        panel.grid.minor = element_blank(), strip.text = element_text(size = 8.5))
guardar(g, "rmse_imputacion_informe.png", 6.5, 3.3)


# ---- Bloque 3. Cargas del PCA v2 ----------------------------------------------------------------------------
# Mismas cargas y orden de variables que la figura de 09g, con nombres de variable en espanol.
VARIABLES <- c(TOUT = "Temperatura", RH = "Humedad", SR = "Radiación", PRS = "Presión (anomalía)",
               viento_rapidez_ms = "Rapidez del viento", viento_u = "Viento u", viento_v = "Viento v", horas_lluvia = "Horas de lluvia")
cargas <- fread(file.path(E4, "pca/pca_v2_cargas.csv"))
valores <- fread(file.path(E4, "pca/pca_v2_valores_propios.csv"))
stopifnot(identical(cargas$variable, names(VARIABLES)))
cl <- melt(cargas, id.vars = "variable", variable.name = "componente", value.name = "carga")
cl[, variable := factor(VARIABLES[variable], levels = rev(VARIABLES))]
cl[, componente := factor(sprintf("%s (%.0f %%)", componente, valores$pct_varianza[match(componente, valores$componente)]))]
g <- ggplot(cl, aes(componente, variable, fill = carga)) +
  geom_tile(colour = "white") + geom_text(aes(label = sprintf("%.2f", carga)), size = 3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), name = "Carga") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 9.5) + theme(panel.grid = element_blank(), axis.text = element_text(size = 9, colour = "grey15"))
guardar(g, "pca_cargas_informe.png", 4.4, 2.5)
message("Listo: ", SALIDA)
