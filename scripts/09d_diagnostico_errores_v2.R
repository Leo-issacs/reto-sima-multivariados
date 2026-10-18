# =============================================================================================
# Etapa 4, fase D: diagnosticos POSTERIORES a la evaluacion de la prueba con la base v2 (09a).
# No reajusta ni cambia ningun modelo: usa las predicciones congeladas del analisis final
# (output/etapa4/prueba_v2_predicciones.csv) y el entrenamiento del analisis final.
#
# Responde a la retroalimentacion de la profesora (15-oct-2026): analisis de los supuestos y de los
# errores. ¿El modelo absorbe la autocorrelacion y la heterogeneidad de varianzas?
#   1. Matrices de confusion; errores por temporada, estacion, anio y magnitud del PM2.5.
#   2. Supuestos del LDA en el entrenamiento v2: normalidad (Mardia), covarianzas iguales (M de Box y
#      razon de DE por clase) y multicolinealidad (VIF, numero de condicion). Mismas formulas que 07a y 07c.
#   3. Autocorrelacion: ACF de la respuesta y del residuo (y - p) dentro de cada estacion, y correlacion
#      entre estaciones el mismo dia. Si el residuo conserva autocorrelacion, el modelo no la absorbe.
#   4. Heterogeneidad: error cuadratico observado (Brier) frente al esperado si las probabilidades
#      fueran correctas, p(1 - p), por estacion, temporada y decil de probabilidad.
#
# Ejecutar desde la raiz:  Rscript scripts/09d_diagnostico_errores_v2.R   (despues de 09a)
# Escribe: output/etapa4/errores/
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y constantes -------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
})
source("R/modelo_etapa4.R")
SALIDA <- "output/etapa4/errores"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))
ANIOS_ENTRENA <- 2021:2023; ANIOS_PRUEBA <- 2024:2025
INICIO_BLOQUES <- as.Date("2024-01-01"); N_REPLICAS <- 1000L; SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")
COLORES <- c(M0 = "#0072B2", M1 = "#D55E00")
tema <- theme_minimal(base_size = 10)


# ---- Bloque 1. Datos y predicciones congeladas -----------------------------------------------------------
# Se reconstruye el entrenamiento del analisis final (para los supuestos) y se comprueba que el modelo
# da las mismas predicciones que 09a.
d <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
d[, fecha := as.Date(fecha)][, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
setorder(d, estacion, fecha)
ESTACIONES <- sort(unique(d$estacion))
a <- prs_anomalia(d[anio %in% ANIOS_ENTRENA & sitio_valido == 1L], d[anio %in% ANIOS_PRUEBA])
tr <- a$tr; te <- a$te
m1 <- ajustar(tr, te, MET)
pred <- fread("output/etapa4/prueba_v2_predicciones.csv")[, fecha := as.Date(fecha)]
chk <- merge(pred, data.table(estacion = te$estacion, fecha = te$fecha, p_chk = m1$p), by = c("estacion", "fecha"))
stopifnot(nrow(chk) == nrow(pred), max(abs(chk$p_M1 - chk$p_chk)) < 1e-12)
CORTE <- m1$corte
y <- pred$supera_25


# ---- Bloque 2. Errores con el corte del modelo ------------------------------------------------------------
errores <- function(y, p, corte) {
  clase <- as.integer(p >= corte)
  vp <- sum(clase == 1 & y == 1); fn <- sum(clase == 0 & y == 1); fp <- sum(clase == 1 & y == 0); vn <- sum(clase == 0 & y == 0)
  data.table(n = length(y), pct_superacion = 100 * mean(y), VP = vp, FN = fn, FP = fp, VN = vn,
             sensibilidad = vp / (vp + fn), especificidad = vn / (vn + fp), tasa_FN = fn / (vp + fn), tasa_FP = fp / (vn + fp),
             brier = mean((p - y)^2))
}
confusion <- rbind(cbind(modelo = "M0", errores(y, pred$p_M0, CORTE)), cbind(modelo = "M1", errores(y, pred$p_M1, CORTE)))
escribir(confusion, "confusion_m0_m1.csv")
por_grupo <- function(col) rbindlist(lapply(c("M0", "M1"), function(m)
  pred[, cbind(modelo = m, errores(supera_25, get(paste0("p_", m)), CORTE)), by = col]))
err_temp <- por_grupo("temporada"); err_est <- por_grupo("estacion"); err_anio <- por_grupo("anio")
escribir(err_temp, "errores_por_temporada.csv"); escribir(err_est, "errores_por_estacion.csv"); escribir(err_anio, "errores_por_anio.csv")
INTERVALOS <- c("[0,15)", "[15,20)", "[20,25]", "(25,30]", "(30,40]", ">40")
pred[, intervalo := fcase(`PM2.5` < 15, "[0,15)", `PM2.5` < 20, "[15,20)", `PM2.5` <= 25, "[20,25]",
                          `PM2.5` <= 30, "(25,30]", `PM2.5` <= 40, "(30,40]", default = ">40")]
err_mag <- pred[, .(n = .N, pct_clasif_superacion_M0 = 100 * mean(p_M0 >= CORTE), pct_clasif_superacion_M1 = 100 * mean(p_M1 >= CORTE)), by = intervalo]
err_mag <- err_mag[match(INTERVALOS, intervalo)]
escribir(err_mag, "errores_por_magnitud_pm25.csv")


# ---- Bloque 3. Supuestos del LDA en el entrenamiento v2 ----------------------------------------------------
# M de Box (como 07a) y Mardia (como 07c), con las 8 meteorologicas (PRS como anomalia). Con n en miles,
# las dos pruebas rechazan casi cualquier diferencia: por eso tambien se reportan la razon de DE por clase
# y la asimetria, que dicen DONDE estan las diferencias.
m_de_box <- function(x, g) {
  grupos <- split(as.data.frame(x), g); p <- ncol(x); k <- length(grupos); n <- sapply(grupos, nrow)
  covs <- lapply(grupos, cov)
  comun <- Reduce(`+`, Map(function(s, ni) (ni - 1) * s, covs, n)) / (sum(n) - k)
  M <- (sum(n) - k) * log(det(comun)) - sum((n - 1) * sapply(covs, function(s) log(det(s))))
  c1 <- (sum(1 / (n - 1)) - 1 / (sum(n) - k)) * (2 * p^2 + 3 * p - 1) / (6 * (p + 1) * (k - 1))
  chi2 <- M * (1 - c1); gl <- p * (p + 1) / 2 * (k - 1)
  c(chi2 = chi2, gl = gl, p = pchisq(chi2, gl, lower.tail = FALSE))
}
mardia <- function(X) {
  n <- nrow(X); p <- ncol(X)
  Xc <- scale(X, center = TRUE, scale = FALSE)
  S_inv <- solve(crossprod(Xc) / n)
  A <- Xc %*% S_inv
  b1 <- 0
  for (ini in seq(1, n, by = 2000)) { filas <- ini:min(n, ini + 1999); b1 <- b1 + sum((A[filas, , drop = FALSE] %*% t(Xc))^3) }
  b1 <- b1 / n^2; b2 <- mean(rowSums(A * Xc)^2)
  asim <- n * b1 / 6; gl <- p * (p + 1) * (p + 2) / 6; curt <- (b2 - p * (p + 2)) / sqrt(8 * p * (p + 2) / n)
  data.table(n = n, asimetria_estadistico = asim, asimetria_gl = gl, asimetria_p = pchisq(asim, gl, lower.tail = FALSE),
             curtosis_estadistico = curt, curtosis_p = 2 * pnorm(-abs(curt)))
}
asimetria <- function(x) { x <- x - mean(x); mean(x^3) / mean(x^2)^1.5 }
X <- as.matrix(tr[, ..MET])
box <- m_de_box(X, tr$supera_25)
normalidad <- rbindlist(lapply(0:1, function(k) cbind(clase = k, mardia(X[tr$supera_25 == k, ]))))
razon_de <- data.table(variable = MET, de_clase0 = apply(X[tr$supera_25 == 0, ], 2, sd), de_clase1 = apply(X[tr$supera_25 == 1, ], 2, sd))
razon_de[, razon_de_clase1_clase0 := de_clase1 / de_clase0]
razon_de[, asimetria_clase0 := apply(X[tr$supera_25 == 0, ], 2, asimetria)][, asimetria_clase1 := apply(X[tr$supera_25 == 1, ], 2, asimetria)]
R_ent <- cor(X); ev <- eigen(R_ent, only.values = TRUE)$values
supuestos <- list(box = data.table(prueba = "M de Box (8 meteorológicas)", chi2 = box[["chi2"]], gl = box[["gl"]], p = box[["p"]]),
                  vif = data.table(variable = MET, vif = diag(solve(R_ent))),
                  condicion = data.table(numero_condicion = sqrt(max(ev) / min(ev))))
escribir(supuestos$box, "supuestos_box_m.csv"); escribir(normalidad, "supuestos_normalidad_mardia.csv")
escribir(razon_de, "supuestos_razon_de_y_asimetria.csv"); escribir(supuestos$vif, "supuestos_vif.csv")
escribir(supuestos$condicion, "supuestos_numero_condicion.csv")


# ---- Bloque 4. ¿El modelo absorbe la autocorrelacion? ---------------------------------------------------------
# Dentro de cada estacion, correlacion entre dias separados exactamente k dias (k = 1..14), de la
# respuesta y (lo que hay que explicar) y del residuo r = y - p (lo que queda sin explicar), para M0 y
# M1. Si la ACF del residuo es menor que la de y, el modelo absorbe esa parte de la dependencia; lo que
# queda es la dependencia que el bootstrap por bloques debe cubrir. Solo correlaciones con >= 30 pares.
MIN_PARES <- 30L
serie <- pred[, .(estacion, fecha, y = supera_25, r_M0 = supera_25 - p_M0, r_M1 = supera_25 - p_M1)]
acf_k <- function(col) rbindlist(lapply(1:14, function(k) {
  pares <- merge(serie[, .(estacion, fecha, x = get(col))], serie[, .(estacion, fecha = fecha - k, x_k = get(col))], by = c("estacion", "fecha"))
  pares[, .(rezago = k, pares = .N, acf = cor(x, x_k)), by = estacion][pares >= MIN_PARES]
}))[, serie := col]
acf_est <- rbindlist(lapply(c("y", "r_M0", "r_M1"), acf_k))
acf_prom <- acf_est[, .(acf_promedio = mean(acf), estaciones = .N), by = .(serie, rezago)]
escribir(acf_est, "acf_por_estacion.csv"); escribir(acf_prom, "acf_promedio_y_residuos.csv")
mismo_dia <- rbindlist(lapply(c("y", "r_M0", "r_M1"), function(col) {
  ancho <- dcast(serie, fecha ~ estacion, value.var = col); M <- as.matrix(ancho[, -1])
  C <- cor(M, use = "pairwise.complete.obs"); comunes <- crossprod(!is.na(M)); C[comunes < MIN_PARES] <- NA
  data.table(serie = col, correlacion_promedio_pares = mean(C[upper.tri(C)], na.rm = TRUE), pares = sum(!is.na(C[upper.tri(C)])))
}))
escribir(mismo_dia, "correlacion_mismo_dia_y_residuos.csv")


# ---- Bloque 5. ¿Hay heterogeneidad de varianzas en los errores? -------------------------------------------------
# Para una respuesta 0/1, si la probabilidad p fuera correcta, el error cuadratico esperado de un dia es
# p(1 - p). Se compara el observado (Brier) con el esperado por estacion, temporada y decil de p. Una
# razon observado/esperado lejos de 1 indica que el modelo se equivoca mas (o menos) de lo que el mismo
# predice en ese grupo: heterogeneidad que el modelo no recoge.
pred[, `:=`(e2_M1 = (supera_25 - p_M1)^2, esp_M1 = p_M1 * (1 - p_M1))]
pred[, decil_M1 := cut(rank(p_M1, ties.method = "first"), 10, labels = FALSE)]
het <- function(col) pred[, .(n = .N, brier_observado = mean(e2_M1), brier_esperado = mean(esp_M1),
                              razon = mean(e2_M1) / mean(esp_M1), pct_superacion = 100 * mean(supera_25), p_media = mean(p_M1)), by = col]
het_est <- het("estacion")[order(-razon)]; het_temp <- het("temporada"); het_dec <- het("decil_M1")[order(decil_M1)]
escribir(het_est, "heterogeneidad_por_estacion.csv"); escribir(het_temp, "heterogeneidad_por_temporada.csv")
escribir(het_dec, "heterogeneidad_por_decil.csv")
print(het_est)


# ---- Bloque 6. Figuras ---------------------------------------------------------------------------------------------
largo <- rbind(err_temp[, .(grupo = "Por temporada", nivel = temporada, modelo, sensibilidad, especificidad)],
               err_est[, .(grupo = "Por estación", nivel = estacion, modelo, sensibilidad, especificidad)])
largo <- melt(largo, measure.vars = c("sensibilidad", "especificidad"), variable.name = "metrica")
g <- ggplot(largo, aes(value, nivel, colour = modelo)) + geom_point(size = 2) +
  facet_grid(grupo ~ metrica, scales = "free_y", space = "free_y") + scale_colour_manual(values = COLORES, name = NULL) + xlim(0, 1) +
  labs(x = NULL, y = NULL, title = sprintf("Sensibilidad y especificidad en la prueba (base v2, corte %.3f)", CORTE)) + tema
ggsave(file.path(SALIDA, "errores_temporada_estacion.png"), g, width = 7, height = 6, dpi = 150)
em <- melt(err_mag, id.vars = c("intervalo", "n"), variable.name = "modelo", value.name = "pct")
em[, modelo := sub("pct_clasif_superacion_", "", modelo)][, intervalo := factor(intervalo, INTERVALOS)]
g <- ggplot(em, aes(intervalo, pct, fill = modelo)) + geom_col(position = "dodge") + geom_vline(xintercept = 3.5, linetype = "dashed") +
  scale_fill_manual(values = COLORES, name = NULL) + ylim(0, 100) +
  labs(x = "PM2.5 observado (µg/m³)", y = "% de días clasificados como superación", title = "Clasificación según la magnitud del PM2.5 (base v2)") + tema
ggsave(file.path(SALIDA, "errores_magnitud_pm25.png"), g, width = 6.5, height = 4, dpi = 150)
etq <- c(y = "Respuesta (supera_25)", r_M0 = "Residuo de M0", r_M1 = "Residuo de M1")
g <- ggplot(copy(acf_prom)[, serie := factor(etq[serie], levels = etq)], aes(rezago, acf_promedio, colour = serie)) +
  geom_hline(yintercept = 0, colour = "grey50") + geom_line(linewidth = 0.8) + geom_point() +
  scale_colour_manual(values = c("#000000", "#0072B2", "#D55E00"), name = NULL) + scale_x_continuous(breaks = 1:14) +
  labs(x = "Rezago (días)", y = "Autocorrelación promedio entre estaciones", title = "¿Absorbe el modelo la autocorrelación? (prueba, base v2)") + tema
ggsave(file.path(SALIDA, "acf_respuesta_y_residuos.png"), g, width = 6.5, height = 4, dpi = 150)
g <- ggplot(het_dec, aes(brier_esperado, brier_observado)) + geom_abline(linetype = "dotted") + geom_point(colour = "#D55E00", size = 2) +
  geom_text(aes(label = decil_M1), nudge_y = 0.012, size = 3) + coord_equal() +
  labs(x = "Error cuadrático esperado, media de p(1 − p)", y = "Error cuadrático observado (Brier)",
       title = "Error observado frente al esperado por decil de p (M1)") + tema
ggsave(file.path(SALIDA, "heterogeneidad_por_decil.png"), g, width = 5, height = 5, dpi = 150)
message("Listo: ", SALIDA)
