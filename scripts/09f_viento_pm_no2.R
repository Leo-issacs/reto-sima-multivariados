# =============================================================================================
# Etapa 4, fase D: descriptivos para el area de estudio y para las preguntas a SIMA. No ajusta modelos.
#
#   1. Viento por estacion (base v2, dias con respuesta valida): rapidez, componentes u y v, direccion
#      resultante, % de dias con flujo del este, y diferencias entre dias con y sin superacion (SMD).
#      SIMA comento que el viento sale del area metropolitana por Santa Catarina y Garcia.
#   2. Cociente PM2.5/PM10 por estacion y temporada, y correlacion de Spearman entre ambos. SIMA comento
#      que en Juarez el PM2.5 va ligado al PM10 (resuspension de vialidades sucias).
#   3. Nivel del PM2.5 de cada estacion frente a la red, mes por mes, comparado con su PM10: si el PM2.5
#      baja frente a la red y el PM10 no, apunta a un problema del equipo de PM2.5 (caso NO2).
#   4. Comparacion con el boletin estatal del 7-mar-2024 (PM2.5 de enero 2023 frente a enero 2024 en
#      Juarez, SE2, y Cadereyta, SE3).
#
# PM2.5: base v2 (>= 18 h observadas). PM10: datos-v1.2 (>= 18 h, incluye horas interpoladas <= 3 h).
# Ejecutar desde la raiz:  Rscript scripts/09f_viento_pm_no2.R
# Escribe: output/etapa4/descriptivos/
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas -------------------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
SALIDA <- "output/etapa4/descriptivos"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))
tema <- theme_minimal(base_size = 10)
smd <- function(x, g) { x1 <- x[g == 1 & !is.na(x)]; x0 <- x[g == 0 & !is.na(x)]; (mean(x1) - mean(x0)) / sqrt((var(x1) + var(x0)) / 2) }


# ---- Bloque 1. Datos ----------------------------------------------------------------------------------------
v2 <- fread("data/clean/v2/diario_v2_2021_2025.csv")[respuesta_valida == 1L]
v2[, fecha := as.Date(fecha)]
d12 <- fread("data/clean/sima_diario_2020_2025.csv")[anio >= 2021 & estacion %in% unique(v2$estacion), .(estacion, fecha, PM10)]
d12[, fecha := as.Date(fecha)]
d <- merge(v2, d12, by = c("estacion", "fecha"), all.x = TRUE)


# ---- Bloque 2. Viento por estacion ----------------------------------------------------------------------------
# u < 0 = el viento va hacia el oeste (viene del este); v < 0 = va hacia el sur (viene del norte).
# Direccion resultante = de donde viene el viento medio (grados desde el norte); constancia = rapidez del
# vector medio / rapidez media (1 = siempre la misma direccion).
w <- d[!is.na(viento_u) & !is.na(viento_v) & !is.na(viento_rapidez_ms)]
viento <- w[, .(dias = .N, rapidez_media = mean(viento_rapidez_ms), rapidez_mediana = median(viento_rapidez_ms),
                u_media = mean(viento_u), v_media = mean(viento_v), pct_dias_flujo_del_este = 100 * mean(viento_u < 0),
                direccion_resultante_grados = (atan2(-mean(viento_u), -mean(viento_v)) * 180 / pi) %% 360,
                constancia = sqrt(mean(viento_u)^2 + mean(viento_v)^2) / mean(viento_rapidez_ms),
                rapidez_con_superacion = mean(viento_rapidez_ms[supera_25 == 1]), rapidez_sin_superacion = mean(viento_rapidez_ms[supera_25 == 0]),
                smd_rapidez = smd(viento_rapidez_ms, supera_25), u_con_superacion = mean(viento_u[supera_25 == 1]),
                u_sin_superacion = mean(viento_u[supera_25 == 0]), smd_u = smd(viento_u, supera_25), smd_v = smd(viento_v, supera_25)),
            by = estacion][order(estacion)]
escribir(viento, "viento_por_estacion.csv")
print(viento[, .(estacion, rapidez_media, pct_dias_flujo_del_este, direccion_resultante_grados, smd_rapidez)])
vl <- melt(w[, .(estacion, supera = factor(supera_25, 0:1, c("sin superación", "con superación")), viento_rapidez_ms)],
           id.vars = c("estacion", "supera"))
g <- ggplot(vl, aes(estacion, value, fill = supera)) + geom_boxplot(outlier.size = 0.3, linewidth = 0.3) +
  scale_fill_manual(values = c("#5B9BD5", "#C0504D"), name = NULL) +
  labs(x = NULL, y = "Rapidez media diaria del viento (m/s)", title = "Viento en días con y sin superación, por estación (base v2)") +
  tema + theme(legend.position = "bottom")
ggsave(file.path(SALIDA, "viento_por_estacion.png"), g, width = 8, height = 4.2, dpi = 150)


# ---- Bloque 3. Cociente PM2.5/PM10 por estacion ----------------------------------------------------------------------
# Un cociente bajo indica mas particulas gruesas (polvo, resuspension); uno alto, mas finas (combustion,
# secundarias). Spearman mide si los dias con mas PM10 tambien tienen mas PM2.5.
pm <- d[!is.na(`PM2.5`) & !is.na(PM10) & PM10 > 0]
pm[, cociente := `PM2.5` / PM10]
cociente <- pm[, .(dias = .N, cociente_mediana = median(cociente), cociente_p25 = quantile(cociente, 0.25), cociente_p75 = quantile(cociente, 0.75),
                   spearman_pm25_pm10 = cor(`PM2.5`, PM10, method = "spearman"),
                   cociente_con_superacion = median(cociente[supera_25 == 1]), cociente_sin_superacion = median(cociente[supera_25 == 0])),
               by = estacion][order(-cociente_mediana)]
cociente_temp <- dcast(pm[, .(cociente_mediana = median(cociente)), by = .(estacion, temporada)], estacion ~ temporada, value.var = "cociente_mediana")
escribir(cociente, "cociente_pm25_pm10_por_estacion.csv"); escribir(cociente_temp, "cociente_pm25_pm10_por_temporada.csv")
print(cociente)


# ---- Bloque 4. Nivel del PM2.5 y del PM10 frente a la red, mes por mes ----------------------------------------------
# Para cada dia: valor de la estacion / mediana de las 13 estaciones ese dia. Despues, mediana mensual por
# estacion. Se marca un mes como "PM2.5 bajo con PM10 normal" si el PM2.5 relativo es < 0.75 y el PM10
# relativo >= 0.85 (umbrales descriptivos, no una prueba). Rachas de meses marcados = posibles periodos con
# problema del equipo de PM2.5.
todo <- merge(v2[, .(estacion, fecha, pm25 = `PM2.5`)], d12[, .(estacion, fecha, pm10 = PM10)], by = c("estacion", "fecha"), all = TRUE)
todo[, red25 := median(pm25, na.rm = TRUE), by = fecha][, red10 := median(pm10, na.rm = TRUE), by = fecha]
todo[, mes := as.Date(format(fecha, "%Y-%m-01"))]
rel <- todo[, .(dias_pm25 = sum(!is.na(pm25)), pm25_relativo = median(pm25 / red25, na.rm = TRUE), dias_pm10 = sum(!is.na(pm10)),
                pm10_relativo = median(pm10 / red10, na.rm = TRUE), cociente_pm25_pm10 = median(pm25 / pm10, na.rm = TRUE)), by = .(estacion, mes)]
rel[, marcado := dias_pm25 >= 10L & dias_pm10 >= 10L & pm25_relativo < 0.75 & pm10_relativo >= 0.85]
setorder(rel, estacion, mes)
escribir(rel, "pm25_pm10_relativo_mensual.csv")
rachas <- rel[marcado == TRUE][, grupo := cumsum(c(1L, diff(as.integer(format(mes, "%Y")) * 12L + as.integer(format(mes, "%m"))) != 1L)), by = estacion]
rachas <- rachas[, .(desde = format(min(mes), "%Y-%m"), hasta = format(max(mes), "%Y-%m"), meses = .N,
                     pm25_relativo_mediana = median(pm25_relativo), pm10_relativo_mediana = median(pm10_relativo)), by = .(estacion, grupo)][meses >= 3L]
escribir(rachas[, -"grupo"], "periodos_pm25_bajo_con_pm10_normal.csv")
print(rachas)
n2 <- melt(rel[estacion == "NO2", .(mes, `PM2.5 / red` = pm25_relativo, `PM10 / red` = pm10_relativo)], id.vars = "mes")
g <- ggplot(n2, aes(mes, value, colour = variable)) + geom_hline(yintercept = 1, colour = "grey50") + geom_line() + geom_point(size = 1) +
  scale_colour_manual(values = c("#D55E00", "#0072B2"), name = NULL) +
  labs(x = NULL, y = "Mediana mensual del cociente estación / mediana de la red",
       title = "NO2 (García): PM2.5 y PM10 frente a la red, 2021–2025",
       subtitle = "El PM2.5 baja a la mitad mientras el PM10 sigue en su nivel: apunta al equipo de PM2.5") + tema + theme(legend.position = "bottom")
ggsave(file.path(SALIDA, "no2_pm25_pm10_relativo.png"), g, width = 7.5, height = 4, dpi = 150)


# ---- Bloque 5. Boletin estatal: enero 2023 frente a enero 2024 en SE2 y SE3 ----------------------------------------
bol <- v2[estacion %in% c("SE2", "SE3") & format(fecha, "%m") == "01" & anio %in% 2023:2024,
          .(dias = .N, pm25_media = mean(`PM2.5`), pm25_mediana = median(`PM2.5`), pct_superacion = 100 * mean(supera_25)), by = .(estacion, anio)]
escribir(bol[order(estacion, anio)], "boletin_enero_2023_2024.csv")
print(bol)
message("Listo: ", SALIDA)
