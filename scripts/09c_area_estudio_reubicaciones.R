# =============================================================================================
# Etapa 4, fase C2 (D22 y D23 de docs/etapa4/decisiones_etapa4.md): area de estudio y reubicaciones.
# Solo describe los datos; no ajusta modelos.
#
#   1. % de dias con superacion y mediana del PM2.5 por estacion y anio (2021-2025), con enfasis en
#      SE2 (Juarez), SO (Santa Catarina) y SUR. Se usa la respuesta de la base v2 (PM2.5 con >= 18 h
#      observadas) en todos los dias con respuesta valida, y tambien la de la etapa 3 para comparar.
#   2. Mediana mensual de PRS menos la mediana de la red (2020-10 a 2022-06) para NO, SE, SO, NTE, SUR,
#      NE y CE (control): un cambio de nivel en la fecha de reubicacion (PIGECA, p. 91) es evidencia de
#      que la estacion cambio de sitio.
#   3. Mapa de estaciones con su altitud y el % de superacion del analisis final v2.
#
# Ejecutar desde la raiz:  Rscript scripts/09c_area_estudio_reubicaciones.R   (despues de 09a)
# Escribe: output/etapa4/area_estudio/
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas ----------------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
SALIDA <- "output/etapa4/area_estudio"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))
tema <- theme_minimal(base_size = 10)
ENFASIS <- c("SE2", "SO", "SUR")
REUBICACION <- c(NO = "2021-07-01", SE = "2021-10-01", SO = "2021-10-01", NTE = "2021-10-01",
                 SUR = "2021-10-01", NE = "2022-03-01")     # primer dia del sitio nuevo (D23)


# ---- Bloque 1. Superacion y mediana del PM2.5 por estacion y anio ---------------------------------------------
# v2: dias con PM2.5 de >= 18 h observadas (todos, tengan o no meteorologia). Etapa 3: PM2.5 de
# datos-v1.2 (incluye horas interpoladas <= 3 h), tambien en todos los dias con PM2.5 valido.
v2 <- fread("data/clean/v2/diario_v2_2021_2025.csv")[respuesta_valida == 1L]
v12 <- fread("data/clean/sima_diario_2020_2025.csv")[anio %in% 2021:2025 & estacion %in% unique(v2$estacion) & !is.na(`PM2.5`)]
v12[, supera_25 := as.integer(`PM2.5` > 25)]
resumen <- function(d, sufijo) {
  r <- d[, .(dias = .N, pct_superacion = 100 * mean(supera_25), mediana_pm25 = median(`PM2.5`)), by = .(estacion, anio)]
  setnames(r, c("dias", "pct_superacion", "mediana_pm25"), paste0(c("dias", "pct_superacion", "mediana_pm25"), sufijo))
  r
}
por_anio <- merge(resumen(v2, "_v2"), resumen(v12, "_v12"), by = c("estacion", "anio"), all = TRUE)
setorder(por_anio, estacion, anio)
escribir(por_anio, "superacion_por_estacion_anio.csv")
enfasis <- dcast(por_anio[estacion %in% ENFASIS], estacion ~ anio, value.var = "pct_superacion_v2")
escribir(enfasis, "superacion_se2_so_sur.csv")
print(enfasis)
# SUR antes y despues de su reubicacion (D23): abril-junio de 2021 frente a abril-junio de 2022.
sur <- v2[estacion == "SUR" & format(as.Date(fecha), "%m") %in% c("04", "05", "06") & anio %in% 2021:2022,
          .(dias = .N, pct_superacion = 100 * mean(supera_25), mediana_pm25 = median(`PM2.5`)), by = anio]
escribir(sur, "sur_abril_junio_2021_2022.csv")
g <- ggplot(por_anio, aes(anio, pct_superacion_v2, group = estacion)) +
  geom_line(colour = "grey75") +
  geom_line(data = por_anio[estacion %in% ENFASIS], aes(colour = estacion), linewidth = 1) +
  geom_point(data = por_anio[estacion %in% ENFASIS], aes(colour = estacion), size = 2) +
  scale_colour_manual(values = c(SE2 = "#D55E00", SO = "#0072B2", SUR = "#009E73"), name = NULL) +
  labs(x = NULL, y = "% de días con PM2.5 > 25 µg/m³", title = "Superación por estación y año (base v2, días con respuesta válida)",
       subtitle = "Gris: las demás estaciones") + tema
ggsave(file.path(SALIDA, "superacion_por_estacion_anio.png"), g, width = 7, height = 4.2, dpi = 150)


# ---- Bloque 2. PRS frente a la red alrededor de las reubicaciones (2020-10 a 2022-06) ----------------------------
# Para cada dia, PRS de la estacion menos la mediana de la PRS de todas las estaciones que reportan ese
# dia (datos-v1.2, que incluye 2020). Despues, mediana mensual por estacion. La altitud fija el nivel de
# cada estacion; un salto de nivel coincide con un cambio de sitio. CE no se reubico (control).
d <- fread("data/clean/sima_diario_2020_2025.csv")[!is.na(PRS)]
d[, fecha := as.Date(fecha)][, mediana_red := median(PRS), by = fecha][, rel := PRS - mediana_red]
d[, mes := as.Date(format(fecha, "%Y-%m-01"))]
EST_PRS <- c(names(REUBICACION), "CE")
prs_mes <- d[estacion %in% EST_PRS & mes >= as.Date("2020-10-01") & mes <= as.Date("2022-06-01"),
             .(dias = .N, mediana_prs_menos_red = median(rel)), by = .(estacion, mes)][order(estacion, mes)]
escribir(prs_mes, "prs_relativa_mensual_2020_2022.csv")
antes_despues <- rbindlist(lapply(names(REUBICACION), function(e) {
  f <- as.Date(REUBICACION[[e]]); z <- d[estacion == e]
  data.table(estacion = e, fecha_reubicacion = f,
             mediana_6_meses_antes = z[fecha >= f - 183 & fecha < f, median(rel)],
             mediana_6_meses_despues = z[fecha >= f & fecha < f + 183, median(rel)])
}))
antes_despues[, cambio := mediana_6_meses_despues - mediana_6_meses_antes]
ce <- d[estacion == "CE"]
antes_despues <- rbind(antes_despues, data.table(estacion = "CE (control, corte 2021-10-01)", fecha_reubicacion = as.Date("2021-10-01"),
  mediana_6_meses_antes = ce[fecha >= as.Date("2021-10-01") - 183 & fecha < as.Date("2021-10-01"), median(rel)],
  mediana_6_meses_despues = ce[fecha >= as.Date("2021-10-01") & fecha < as.Date("2021-10-01") + 183, median(rel)]), fill = TRUE)
antes_despues[is.na(cambio), cambio := mediana_6_meses_despues - mediana_6_meses_antes]
escribir(antes_despues, "prs_antes_despues_reubicacion.csv")
print(antes_despues)
malla <- CJ(estacion = EST_PRS, mes = seq(as.Date("2020-10-01"), as.Date("2022-06-01"), by = "month"))
lineas_reub <- data.table(estacion = names(REUBICACION), fecha = as.Date(REUBICACION))
g <- ggplot(merge(malla, prs_mes, by = c("estacion", "mes"), all.x = TRUE), aes(mes, mediana_prs_menos_red)) +
  geom_line(colour = "#0072B2", na.rm = TRUE) + geom_point(size = 1, colour = "#0072B2", na.rm = TRUE) +
  geom_vline(data = lineas_reub, aes(xintercept = fecha), linetype = "dashed", colour = "#D55E00") +
  facet_wrap(~estacion, ncol = 4, scales = "free_y") +
  labs(x = NULL, y = "Mediana mensual de PRS − mediana de la red (mm Hg)",
       title = "Presión de cada estación frente a la red, 2020-10 a 2022-06",
       subtitle = "Línea punteada: reubicación según el PIGECA (p. 91); CE no se reubicó (control)") + tema
ggsave(file.path(SALIDA, "prs_relativa_reubicaciones.png"), g, width = 9, height = 5, dpi = 150)


# ---- Bloque 3. Mapa de estaciones con altitud --------------------------------------------------------------------
# Mismo estilo que el mapa de la etapa 3 (07c): solo puntos con latitud y longitud, sin mapa base. Color =
# % de dias con superacion en el analisis final v2; etiqueta = estacion y altitud (m s. n. m.).
est <- fread("data/metadata/estaciones.csv")
sup <- fread("output/etapa4/dias_superacion_por_estacion.csv")[estacion != "Total", .(estacion, pct_superacion_v2, dias_v2)]
mapa <- merge(est[, .(estacion = codigo_hoja, nombre = nombre_confirmado, municipio, latitud, longitud, altitud_msnm)], sup, by = "estacion")
escribir(mapa, "mapa_estaciones_altitud.csv")
lat_m <- mean(mapa$latitud); km_por_grado_lon <- 111.32 * cos(lat_m * pi / 180)
x0 <- min(mapa$longitud) + 0.01; y0 <- min(mapa$latitud) - 0.02
g <- ggplot(mapa, aes(longitud, latitud)) +
  geom_point(aes(fill = pct_superacion_v2), shape = 21, size = 6, colour = "grey20") +
  geom_text(aes(label = sprintf("%s\n%d m", estacion, altitud_msnm)), nudge_y = 0.022, size = 2.8, lineheight = 0.9) +
  annotate("segment", x = x0, xend = x0 + 10 / km_por_grado_lon, y = y0, yend = y0, linewidth = 1) +
  annotate("text", x = x0 + 5 / km_por_grado_lon, y = y0 + 0.008, label = "10 km", size = 3) +
  scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "% días con\nPM2.5 > 25") +
  coord_quickmap() +
  labs(x = "Longitud", y = "Latitud", title = "Estaciones, altitud y frecuencia de superación (base v2, 2021–2025)",
       caption = sprintf("Altitud de data/metadata/estaciones.csv. Escala aproximada: 0.1° de longitud ≈ %.1f km a %.2f° N.",
                         0.1 * km_por_grado_lon, lat_m)) +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank())
ggsave(file.path(SALIDA, "mapa_estaciones_altitud.png"), g, width = 7.5, height = 5.6, dpi = 150)
message("Listo: ", SALIDA)
