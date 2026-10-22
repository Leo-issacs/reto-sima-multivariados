# =============================================================================================
# Etapa 3: diagnosticos POSTERIORES a la evaluacion de la prueba (07b).
#
# No reajusta ni cambia ningun modelo: reconstruye M0 y M1 tal como los dejo 07b, verifica que
# dan los mismos AUC, guarda el modelo final para la app y describe donde y como se equivocan.
# La parte 1b agrega diagnosticos motivados por informacion del socio formador (cambios de
# instrumentos, recibida el 9-oct-2026); tampoco cambia el modelo principal.
#
#   Rscript scripts/07c_diagnostico_errores.R
#
# Escribe: output/etapa3/modelo_final.rds, output/etapa3/diagnostico/*.csv,
#          output/etapa3/figuras/*.png, output/etapa3/RESUMEN_DIAGNOSTICO.md
#          y anexa una nota a output/etapa3/registro_prueba.txt.
# Como usarlo en RStudio: corre los bloques en orden. Cada uno explica que hace y por que.
# =============================================================================================


# ---- Bloque 0. Paquetes, carpetas y constantes ------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
})
source("app/predecir.R")   # funciones de prediccion que tambien usa la app
SALIDA <- "output/etapa3"
DIAG <- file.path(SALIDA, "diagnostico")
FIGURAS <- file.path(SALIDA, "figuras")
dir.create(DIAG, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(DIAG, nombre), eol = "\n")
ANIOS_ENTRENA <- 2021:2023
ANIOS_PRUEBA <- 2024:2025
INICIO_BLOQUES <- as.Date("2024-01-01")
N_REPLICAS <- 1000L
SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")


# ---- Bloque 1. Datos (igual que 07b) ----------------------------------------------------------
muestra <- fread("data/clean/muestra_pm25_2021_2025.csv")
muestra[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
muestra[, fecha := as.Date(fecha)]
ESTACIONES <- sort(unique(muestra$estacion))
entrena <- muestra[anio %in% ANIOS_ENTRENA]
prueba <- muestra[anio %in% ANIOS_PRUEBA]


# ---- Bloque 2. Funciones del modelo, copiadas sin cambios de 07b --------------------------------
# Son las mismas lineas de 07b (bloques 3 a 5). Solo se agrega que ajustar() devuelva tambien
# las medias y desviaciones de escalado, que la app necesita.
prs_anomalia <- function(tr, te) {
  medias <- tr[, .(media_prs = mean(PRS)), by = estacion]
  f <- function(d) { d <- merge(copy(d), medias, by = "estacion", sort = FALSE); d[, PRS := PRS - media_prs][, media_prs := NULL] }
  list(tr = f(tr), te = f(te), medias = medias)
}
matriz_x <- function(d, numericas, interaccion = FALSE) {
  est <- factor(d$estacion, levels = ESTACIONES); tem <- factor(d$temporada, levels = TEMPORADAS)
  x <- model.matrix(if (interaccion) ~ est * tem else ~ est + tem, data.frame(est, tem))[, -1, drop = FALSE]
  if (length(numericas)) x <- cbind(x, as.matrix(d[, ..numericas]))
  x
}
ajustar <- function(tr, te, numericas, y = "supera_25") {
  x_tr <- matriz_x(tr, numericas); x_te <- matriz_x(te, numericas)
  medias <- colMeans(x_tr); desv <- apply(x_tr, 2, sd); desv[desv == 0] <- 1
  z_tr <- scale(x_tr, medias, desv); z_te <- scale(x_te, medias, desv)
  prev <- mean(tr[[y]])
  modelo <- lda(z_tr, grouping = tr[[y]], prior = c(1 - prev, prev))
  p <- predict(modelo, z_te)$posterior[, "1"]
  list(p = p, corte = prev, modelo = modelo, z_tr = z_tr, medias = medias, desv = desv)
}
auc_proc <- function(y, p) as.numeric(pROC::auc(pROC::roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)))
auc_rapido <- function(y, p) {
  r <- rank(p); n1 <- sum(y == 1); n0 <- length(y) - n1
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
eb_rapida <- function(y, p, corte) { clase <- p >= corte; 0.5 * (mean(clase[y == 1]) + mean(!clase[y == 0])) }
bootstrap <- function(fechas, y, p_a, p_b, corte_a, corte_b, dias = 14L, n = N_REPLICAS, semilla = SEMILLA) {
  bloque <- as.integer(fechas - INICIO_BLOQUES) %/% dias
  filas <- split(seq_along(bloque), bloque)
  set.seed(semilla)
  rep <- t(vapply(seq_len(n), function(i) {
    idx <- unlist(filas[sample.int(length(filas), length(filas), replace = TRUE)], use.names = FALSE)
    c(auc_a = auc_rapido(y[idx], p_a[idx]), auc_b = auc_rapido(y[idx], p_b[idx]),
      eb_a = eb_rapida(y[idx], p_a[idx], corte_a), eb_b = eb_rapida(y[idx], p_b[idx], corte_b))
  }, numeric(4)))
  rep <- as.data.table(rep)[, `:=`(d_auc = auc_b - auc_a, d_eb = eb_b - eb_a)]
  list(n_bloques = length(filas),
       ic = rep[, .(d_auc_li = quantile(d_auc, 0.025), d_auc_ls = quantile(d_auc, 0.975),
                    d_eb_li = quantile(d_eb, 0.025), d_eb_ls = quantile(d_eb, 0.975))])
}
# Metricas de error con un corte fijo: cuantos aciertos y errores de cada tipo.
errores <- function(y, p, corte) {
  clase <- as.integer(p >= corte)
  vp <- sum(clase == 1 & y == 1); fn <- sum(clase == 0 & y == 1)
  fp <- sum(clase == 1 & y == 0); vn <- sum(clase == 0 & y == 0)
  data.table(n = length(y), pct_superacion = 100 * mean(y), VP = vp, FN = fn, FP = fp, VN = vn,
             sensibilidad = vp / (vp + fn), especificidad = vn / (vn + fp),
             tasa_FN = fn / (vp + fn), tasa_FP = fp / (vn + fp))
}
# comparar(): AUC de M0 y M1 en un subconjunto, dAUC con IC por bloques y exactitud balanceada.
comparar <- function(nombre, fechas, y, p0, p1, corte0, corte1) {
  b <- bootstrap(fechas, y, p0, p1, corte0, corte1)
  data.table(analisis = nombre, n = length(y), superaciones = sum(y), pct_superacion = 100 * mean(y),
             auc_M0 = auc_rapido(y, p0), auc_M1 = auc_rapido(y, p1), d_auc = auc_rapido(y, p1) - auc_rapido(y, p0),
             d_auc_li = b$ic$d_auc_li, d_auc_ls = b$ic$d_auc_ls,
             eb_M0 = eb_rapida(y, p0, corte0), eb_M1 = eb_rapida(y, p1, corte1), bloques = b$n_bloques)
}


# ---- Bloque 3 (paso 0). Reconstruir M0 y M1 y verificar contra 07b --------------------------------
# Se reentrena exactamente lo mismo (misma muestra, mismas funciones). Si el AUC de la prueba no
# coincide con prueba_metricas_m0_m1.csv hasta 1e-9, algo cambio y nos detenemos.
a <- prs_anomalia(entrena, prueba)
tr <- a$tr; te <- a$te
m0 <- ajustar(tr, te, character())
m1 <- ajustar(tr, te, MET)
ref <- fread(file.path(SALIDA, "prueba_metricas_m0_m1.csv"))
auc0 <- auc_proc(te$supera_25, m0$p); auc1 <- auc_proc(te$supera_25, m1$p)
dif <- c(M0 = auc0 - ref[modelo == "M0", auc], M1 = auc1 - ref[modelo == "M1", auc])
verificacion <- data.table(modelo = c("M0", "M1"), auc_07b = ref$auc, auc_07c = c(auc0, auc1), diferencia = dif)
print(verificacion)
if (any(abs(dif) > 1e-9)) stop("Los AUC reconstruidos no coinciden con 07b. Me detengo.", call. = FALSE)
if (round(m1$corte, 3) != 0.258 || m0$corte != m1$corte) stop("El corte no es 0.258.", call. = FALSE)
CORTE <- m1$corte
escribir(verificacion, "paso0_verificacion.csv")


# ---- Bloque 4. Guardar el modelo final para la app --------------------------------------------------
# Todo lo necesario para predecir sin volver a entrenar: los objetos LDA, el escalado, las medias
# de PRS por estacion, los niveles, el corte y las predicciones de la prueba. Tambien un resumen
# del entrenamiento (medianas por estacion x temporada y percentiles 1-99) para los deslizadores.
pred <- te[, .(estacion, fecha, `PM2.5`, supera_25, temporada, p_M0 = m0$p, p_M1 = m1$p)]
setorder(pred, fecha, estacion)
ld <- as.vector(m1$z_tr %*% m1$modelo$scaling[, 1])
mediana_ent <- entrena[, lapply(.SD, median), by = .(estacion, temporada), .SDcols = MET]
rango_ent <- data.table(variable = MET, p01 = sapply(MET, function(v) quantile(entrena[[v]], 0.01)),
                        p99 = sapply(MET, function(v) quantile(entrena[[v]], 0.99)))
modelo_final <- list(
  modelos = list(M0 = m0$modelo, M1 = m1$modelo),
  escalado = list(M0 = list(medias = m0$medias, desv = m0$desv), M1 = list(medias = m1$medias, desv = m1$desv)),
  medias_prs = setNames(a$medias$media_prs, a$medias$estacion),
  niveles = list(estacion = ESTACIONES, temporada = TEMPORADAS),
  met = MET, corte = CORTE,
  signo_ld1 = sign(mean(ld[tr$supera_25 == 1]) - mean(ld[tr$supera_25 == 0])),
  predicciones_prueba = pred,
  entrenamiento = list(medianas = mediana_ent, rangos = rango_ent, n = nrow(tr), anios = ANIOS_ENTRENA),
  creado = list(script = "scripts/07c_diagnostico_errores.R", fecha = format(Sys.time(), "%Y-%m-%d %H:%M")))
# Control: las funciones de la app, con la meteorologia original (PRS sin restar), reproducen
# las predicciones de 07b.
chk <- merge(pred, prueba[, c("estacion", "fecha", MET), with = FALSE], by = c("estacion", "fecha"))
stopifnot(nrow(chk) == nrow(pred),
          max(abs(predecir_modelo(modelo_final, chk, "M0") - chk$p_M0)) < 1e-10,
          max(abs(predecir_modelo(modelo_final, chk, "M1") - chk$p_M1)) < 1e-10)
saveRDS(modelo_final, file.path(SALIDA, "modelo_final.rds"))


# ---- Bloque 5. Nota en el registro de la prueba ----------------------------------------------------
# Deja constancia de que estos diagnosticos son posteriores y no cambian nada. Solo se anexa una vez.
registro <- file.path(SALIDA, "registro_prueba.txt")
nota <- c("", "## Diagnósticos posteriores (07c)",
          "Diagnósticos posteriores (07c): no modifican modelos ni métricas.",
          paste("Diagnósticos posteriores motivados por información del socio formador recibida el 9-oct-2026",
                "(cambios de instrumentos en 2021 y 2025); el modelo principal no cambia."))
if (!any(grepl("Diagnósticos posteriores (07c)", readLines(registro, encoding = "UTF-8"), fixed = TRUE)))
  cat(nota, file = registro, sep = "\n", append = TRUE)


# ---- Bloque 6 (paso 1). Matrices de confusion en la prueba ------------------------------------------
y <- pred$supera_25
confusion <- rbind(cbind(modelo = "M0", errores(y, pred$p_M0, CORTE)), cbind(modelo = "M1", errores(y, pred$p_M1, CORTE)))
escribir(confusion, "confusion_m0_m1.csv")


# ---- Bloque 7 (paso 2). Errores por temporada y por estacion ----------------------------------------
por_grupo <- function(col) rbindlist(lapply(c("M0", "M1"), function(m)
  pred[, cbind(modelo = m, errores(supera_25, get(paste0("p_", m)), CORTE)), by = col]))
err_temp <- por_grupo("temporada"); err_est <- por_grupo("estacion")
escribir(err_temp, "errores_por_temporada.csv"); escribir(err_est, "errores_por_estacion.csv")


# ---- Bloque 8 (paso 3). Errores segun la magnitud del PM2.5 -----------------------------------------
# Si los errores se concentran cerca de 25 ug/m3, el modelo falla sobre todo en los dias dificiles.
pred[, intervalo := fcase(`PM2.5` < 15, "[0,15)", `PM2.5` < 20, "[15,20)", `PM2.5` <= 25, "[20,25]",
                          `PM2.5` <= 30, "(25,30]", `PM2.5` <= 40, "(30,40]", default = ">40")]
INTERVALOS <- c("[0,15)", "[15,20)", "[20,25]", "(25,30]", "(30,40]", ">40")
err_mag <- pred[, .(n = .N, pct_clasif_superacion_M0 = 100 * mean(p_M0 >= CORTE),
                    pct_clasif_superacion_M1 = 100 * mean(p_M1 >= CORTE)), by = intervalo]
err_mag <- err_mag[match(INTERVALOS, intervalo)]
escribir(err_mag, "errores_por_magnitud_pm25.csv")


# ---- Bloque 9 (paso 4). Calibracion por deciles ---------------------------------------------------------
# Si el modelo esta calibrado, entre los dias con probabilidad media 0.30 hay ~30 % de superaciones.
# Recalibracion: logistica de y sobre logit(p); intercepto 0 y pendiente 1 = calibracion perfecta.
calib <- rbindlist(lapply(c("M0", "M1"), function(m) {
  p <- pred[[paste0("p_", m)]]
  decil <- cut(rank(p, ties.method = "first"), 10, labels = FALSE)
  data.table(modelo = m, decil, p, y)[, .(n = .N, p_media = mean(p), frecuencia_observada = mean(y)), by = .(modelo, decil)][order(decil)]
}))
recal <- rbindlist(lapply(c("M0", "M1"), function(m) {
  co <- coef(glm(y ~ qlogis(pred[[paste0("p_", m)]]), family = binomial))
  data.table(modelo = m, intercepto = co[[1]], pendiente = co[[2]])
}))
escribir(calib, "calibracion_deciles.csv"); escribir(recal, "calibracion_recalibracion.csv")


# ---- Bloque 10 (paso 5). Importancia por permutacion en la prueba ---------------------------------------
# Se desordena una variable (o un grupo) en la prueba, se vuelve a predecir con el modelo congelado
# y se mide cuanto cae el AUC. 200 permutaciones por variable, semilla 2026.
# PRS se permuta ya como anomalia; "estacion" y "temporada" permutan la etiqueta.
te_ord <- copy(te)[, p_M1 := m1$p][, p_M0 := m0$p]
pred_te <- function(d, cual) {   # predice con el modelo congelado sobre te con PRS ya en anomalia
  as.vector(predict(modelo_final$modelos[[cual]],
                    scale(matriz_x(d, if (cual == "M1") MET else character()),
                          modelo_final$escalado[[cual]]$medias, modelo_final$escalado[[cual]]$desv))$posterior[, "1"])
}
stopifnot(max(abs(pred_te(te_ord, "M1") - m1$p)) < 1e-10)
GRUPOS <- c(setNames(as.list(MET), MET), list(viento = c("viento_u", "viento_v", "viento_rapidez_ms"),
                                               estacion = "estacion", temporada = "temporada"))
permutar <- function(cual, grupos, n_perm = 200L) {
  auc_base <- auc_rapido(te_ord$supera_25, te_ord[[paste0("p_", cual)]])
  set.seed(SEMILLA)
  rbindlist(lapply(names(grupos), function(g) {
    caidas <- vapply(seq_len(n_perm), function(i) {
      d <- copy(te_ord); idx <- sample.int(nrow(d))
      for (v in grupos[[g]]) set(d, j = v, value = d[[v]][idx])   # misma permutacion para todo el grupo
      auc_base - auc_rapido(d$supera_25, pred_te(d, cual))
    }, numeric(1))
    data.table(modelo = cual, variable = g, caida_auc_media = mean(caidas),
               p2.5 = quantile(caidas, 0.025), p97.5 = quantile(caidas, 0.975))
  }))
}
importancia <- rbind(permutar("M1", GRUPOS), permutar("M0", GRUPOS[c("estacion", "temporada")]))
escribir(importancia, "importancia_permutacion.csv")


# ---- Bloque 11 (paso 6a). Multicolinealidad: VIF y numero de condicion -----------------------------------
# VIF = diagonal de la inversa de la matriz de correlacion de las 8 continuas (PRS en anomalia),
# en el entrenamiento. Numero de condicion = raiz(valor propio maximo / minimo) de esa matriz.
R_ent <- cor(as.matrix(tr[, ..MET]))
vif <- data.table(variable = MET, vif = diag(solve(R_ent)))
ev <- eigen(R_ent, only.values = TRUE)$values
condicion <- data.table(numero_condicion = sqrt(max(ev) / min(ev)), razon_valores_propios = max(ev) / min(ev))
escribir(vif, "vif.csv"); escribir(condicion, "numero_condicion.csv")


# ---- Bloque 12 (paso 6b). Dependencia de los residuos --------------------------------------------------
# r = supera_25 - p_M1 en la prueba. (1) Autocorrelacion dentro de cada estacion a rezagos de 1-14
# dias de calendario (pares de dias separados exactamente k dias), promediada entre estaciones.
# (2) Correlacion entre pares de estaciones el mismo dia. Si ambas son > 0, las filas no son
# independientes y el bootstrap debe remuestrear bloques de fechas con todas las estaciones.
# Solo se usan correlaciones con >= 30 pares de dias (con menos, salen valores extremos sin sentido).
MIN_PARES <- 30L
res <- pred[, .(estacion, fecha, r = supera_25 - p_M1)]
acf_est <- rbindlist(lapply(1:14, function(k) {
  pares <- merge(res, res[, .(estacion, fecha = fecha - k, r_k = r)], by = c("estacion", "fecha"))
  pares[, .(rezago = k, pares = .N, acf = cor(r, r_k)), by = estacion][pares >= MIN_PARES]
}))
acf_prom <- acf_est[, .(acf_promedio = mean(acf), acf_min = min(acf), acf_max = max(acf), estaciones = .N), by = rezago]
ancho <- dcast(res, fecha ~ estacion, value.var = "r")
M <- as.matrix(ancho[, -1])
C <- cor(M, use = "pairwise.complete.obs")
comunes <- crossprod(!is.na(M))   # dias con dato en las dos estaciones del par
C[comunes < MIN_PARES] <- NA
corr_mismo_dia <- data.table(correlacion_promedio_pares = mean(C[upper.tri(C)], na.rm = TRUE),
                             minimo = min(C[upper.tri(C)], na.rm = TRUE), maximo = max(C[upper.tri(C)], na.rm = TRUE),
                             pares = sum(!is.na(C[upper.tri(C)])))
escribir(acf_est, "acf_residuos_por_estacion.csv"); escribir(acf_prom, "acf_residuos_promedio.csv")
escribir(corr_mismo_dia, "correlacion_residuos_mismo_dia.csv")


# ---- Bloque 13 (paso 6c). Normalidad multivariada por clase (Mardia) --------------------------------------
# La LDA supone normalidad multivariada con covarianza comun. Prueba de Mardia (asimetria y
# curtosis) sobre las 8 continuas del entrenamiento, por clase. Se calcula aqui mismo (formula
# de Mardia, 1970) para no agregar el paquete MVN. Con n en miles casi seguro rechaza.
mardia <- function(X) {
  n <- nrow(X); p <- ncol(X)
  Xc <- scale(X, center = TRUE, scale = FALSE)
  S_inv <- solve(crossprod(Xc) / n)                 # covarianza de maxima verosimilitud
  A <- Xc %*% S_inv
  b1 <- 0
  for (ini in seq(1, n, by = 2000)) {              # por bloques para no crear una matriz n x n
    filas <- ini:min(n, ini + 1999)
    b1 <- b1 + sum((A[filas, , drop = FALSE] %*% t(Xc))^3)
  }
  b1 <- b1 / n^2
  b2 <- mean(rowSums(A * Xc)^2)
  asim <- n * b1 / 6; gl <- p * (p + 1) * (p + 2) / 6
  curt <- (b2 - p * (p + 2)) / sqrt(8 * p * (p + 2) / n)
  data.table(n = n, asimetria_estadistico = asim, asimetria_gl = gl,
             asimetria_p = pchisq(asim, gl, lower.tail = FALSE),
             curtosis_estadistico = curt, curtosis_p = 2 * pnorm(-abs(curt)))
}
normalidad <- rbindlist(lapply(0:1, function(k) cbind(clase = k, mardia(as.matrix(tr[supera_25 == k, ..MET])))))
escribir(normalidad, "normalidad_mardia.csv")


# ---- Bloque 14 (paso 7). Mapa de estaciones ---------------------------------------------------------------
# Solo puntos con latitud y longitud (sin mapa base descargado). Color = % de dias con superacion en
# la muestra 2021-2025. Se agrega una barra de 10 km calculada a la latitud media.
est <- fread("data/metadata/estaciones.csv")[codigo_hoja %in% ESTACIONES]
sup_est <- muestra[, .(pct_superacion = 100 * mean(supera_25), n = .N), by = estacion]
mapa <- merge(est[, .(estacion = codigo_hoja, nombre = nombre_confirmado, latitud, longitud)], sup_est, by = "estacion")
escribir(mapa, "mapa_estaciones.csv")
lat_m <- mean(mapa$latitud); km_por_grado_lon <- 111.32 * cos(lat_m * pi / 180)
x0 <- min(mapa$longitud) + 0.01; y0 <- min(mapa$latitud) - 0.02
g_mapa <- ggplot(mapa, aes(longitud, latitud)) +
  geom_point(aes(fill = pct_superacion), shape = 21, size = 6, colour = "grey20") +
  geom_text(aes(label = estacion), nudge_y = 0.016, size = 3.2) +
  annotate("segment", x = x0, xend = x0 + 10 / km_por_grado_lon, y = y0, yend = y0, linewidth = 1) +
  annotate("text", x = x0 + 5 / km_por_grado_lon, y = y0 + 0.008, label = "10 km", size = 3) +
  scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "% días con\nPM2.5 > 25") +
  coord_quickmap() +
  labs(x = "Longitud", y = "Latitud", title = "Estaciones de la muestra y frecuencia de superación (2021–2025)",
       caption = sprintf("Escala aproximada: 0.1° de longitud ≈ %.1f km y 0.1° de latitud ≈ 11.1 km a %.2f° N.",
                         0.1 * km_por_grado_lon, lat_m)) +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank())
ggsave(file.path(FIGURAS, "mapa_estaciones.png"), g_mapa, width = 7, height = 5.2, dpi = 150)


# ---- Bloque 15 (paso 8). Figuras de los diagnosticos ------------------------------------------------------
COLORES <- c(M0 = "#0072B2", M1 = "#D55E00")
tema <- theme_minimal(base_size = 10)

# 15a. Sensibilidad y especificidad por temporada y por estacion.
largo <- rbind(err_temp[, .(grupo = "Por temporada", nivel = temporada, modelo, sensibilidad, especificidad)],
               err_est[, .(grupo = "Por estación", nivel = estacion, modelo, sensibilidad, especificidad)])
largo <- melt(largo, measure.vars = c("sensibilidad", "especificidad"), variable.name = "metrica")
g <- ggplot(largo, aes(value, nivel, colour = modelo)) + geom_point(size = 2) +
  facet_grid(grupo ~ metrica, scales = "free_y", space = "free_y") +
  scale_colour_manual(values = COLORES, name = NULL) + xlim(0, 1) +
  labs(x = NULL, y = NULL, title = "Sensibilidad y especificidad en la prueba (corte 0.258)") + tema
ggsave(file.path(FIGURAS, "errores_temporada_estacion.png"), g, width = 7, height = 6, dpi = 150)

# 15b. Porcentaje clasificado como superacion segun el PM2.5 observado.
em <- melt(err_mag, id.vars = c("intervalo", "n"), variable.name = "modelo", value.name = "pct")
em[, modelo := sub("pct_clasif_superacion_", "", modelo)][, intervalo := factor(intervalo, INTERVALOS)]
g <- ggplot(em, aes(intervalo, pct, fill = modelo)) + geom_col(position = "dodge") +
  geom_vline(xintercept = 3.5, linetype = "dashed") +
  annotate("text", x = 3.55, y = 98, label = "25 µg/m³", hjust = 0, size = 3) +
  scale_fill_manual(values = COLORES, name = NULL) + ylim(0, 100) +
  labs(x = "PM2.5 observado (µg/m³)", y = "% de días clasificados como superación",
       title = "Clasificación según la magnitud del PM2.5 en la prueba") + tema
ggsave(file.path(FIGURAS, "errores_magnitud_pm25.png"), g, width = 6.5, height = 4, dpi = 150)

# 15c. Calibracion.
g <- ggplot(calib, aes(p_media, frecuencia_observada, colour = modelo)) +
  geom_abline(linetype = "dotted") + geom_line() + geom_point() +
  scale_colour_manual(values = COLORES, name = NULL) + coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Probabilidad media predicha (decil)", y = "Frecuencia observada de superación",
       title = "Calibración en la prueba") + tema
ggsave(file.path(FIGURAS, "calibracion.png"), g, width = 5, height = 5, dpi = 150)

# 15d. Importancia por permutacion.
im <- copy(importancia)[, variable := factor(variable, levels = importancia[modelo == "M1"][order(caida_auc_media), variable])]
g <- ggplot(im, aes(caida_auc_media, variable, colour = modelo)) +
  geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = p2.5, xmax = p97.5), position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = COLORES, name = NULL) +
  labs(x = "Caída del AUC al permutar (media y percentiles 2.5–97.5)", y = NULL,
       title = "Importancia por permutación en la prueba (200 permutaciones)") + tema
ggsave(file.path(FIGURAS, "importancia_permutacion.png"), g, width = 6.5, height = 4.5, dpi = 150)

# 15e. Autocorrelacion de los residuos.
g <- ggplot(acf_est, aes(rezago, acf)) + geom_hline(yintercept = 0, colour = "grey50") +
  geom_line(aes(group = estacion), colour = "grey75") +
  geom_line(data = acf_prom, aes(y = acf_promedio), colour = "#D55E00", linewidth = 1) +
  scale_x_continuous(breaks = 1:14) +
  labs(x = "Rezago (días)", y = "Autocorrelación del residuo de M1",
       title = "Autocorrelación de los residuos dentro de cada estación",
       subtitle = "Gris: cada estación; naranja: promedio") + tema
ggsave(file.path(FIGURAS, "acf_residuos.png"), g, width = 6.5, height = 4, dpi = 150)

# 15f. dAUC por temporada con su IC (de 07b).
dt_temp <- fread(file.path(SALIDA, "prueba_dauc_por_temporada.csv"))[, temporada := sub("Temporada: ", "", analisis)]
g <- ggplot(dt_temp, aes(d_auc, temporada)) + geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = d_auc_li, xmax = d_auc_ls), colour = "#D55E00") +
  labs(x = "ΔAUC (M1 − M0) e IC 95 % por bloques de 14 días", y = NULL, title = "ΔAUC por temporada en la prueba") + tema
ggsave(file.path(FIGURAS, "dauc_temporada.png"), g, width = 6, height = 3, dpi = 150)


# ---- Bloque 16 (parte 1b, paso 1). Viento mensual 2020-2025 ------------------------------------------------
# SIMA renovo los sensores de viento en 2021. Mediana mensual de la rapidez diaria por estacion,
# con una linea en 2021-03-01. El "mes de cambio" es el primer mes de 2021 cuya mediana difiere
# mas de 30 % de la mediana de 2020 (solo descriptivo).
diario <- fread("data/clean/sima_diario_2020_2025.csv")[estacion %in% ESTACIONES]
diario[, fecha := as.Date(fecha)][, mes := as.Date(format(fecha, "%Y-%m-01"))]
viento_mes <- diario[!is.na(viento_rapidez_ms), .(mediana = median(viento_rapidez_ms), dias = .N), by = .(estacion, mes)]
med_2020 <- diario[anio == 2020 & !is.na(viento_rapidez_ms), .(mediana_2020 = median(viento_rapidez_ms)), by = estacion]
cambio <- merge(viento_mes[year(mes) == 2021], med_2020, by = "estacion")[order(estacion, mes)]
cambio[, difiere := abs(mediana / mediana_2020 - 1) > 0.30]
mes_cambio <- cambio[, .(mediana_2020 = mediana_2020[1],
                         mes_cambio = if (any(difiere)) format(mes[which(difiere)[1]], "%Y-%m") else "sin cambio > 30 %",
                         mediana_mes_cambio = if (any(difiere)) mediana[which(difiere)[1]] else NA_real_), by = estacion]
mes_cambio <- merge(data.table(estacion = ESTACIONES), mes_cambio, by = "estacion", all.x = TRUE)
mes_cambio[is.na(mes_cambio), mes_cambio := "sin datos de 2020"]
escribir(viento_mes, "viento_mensual_2020_2025.csv"); escribir(mes_cambio, "viento_mes_de_cambio_2021.csv")
# Malla completa estacion x mes para que la linea se corte en los meses sin datos (no una huecos).
malla <- CJ(estacion = ESTACIONES, mes = seq(as.Date("2020-01-01"), as.Date("2025-12-01"), by = "month"))
g <- ggplot(merge(malla, viento_mes, by = c("estacion", "mes"), all.x = TRUE), aes(mes, mediana)) +
  geom_line(colour = "#0072B2", na.rm = TRUE) +
  geom_vline(xintercept = as.Date("2021-03-01"), linetype = "dashed", colour = "#D55E00") +
  facet_wrap(~ estacion, ncol = 4) +
  labs(x = NULL, y = "Mediana mensual de la rapidez diaria (m/s)",
       title = "Rapidez del viento por estación, 2020–2025", subtitle = "Línea: 2021-03-01 (renovación de sensores de viento)") + tema
ggsave(file.path(FIGURAS, "viento_mensual_2020_2025.png"), g, width = 8, height = 7, dpi = 150)


# ---- Bloque 17 (parte 1b, pasos 2 y 3). Desempeño por año y por grupo de estaciones ------------------------
# 2024 y 2025 por separado, y las 5 estaciones con equipo nuevo de PM2.5 en 2025 frente a las otras 8.
# Mismas predicciones congeladas; IC por bloques de 14 dias. Celdas con < 100 dias o < 20
# superaciones se marcan como "n insuficiente".
NUEVO_PM25 <- c("SE2", "NTE2", "SUR", "SO2", "NO")
pred[, anio := year(fecha)][, grupo := ifelse(estacion %in% NUEVO_PM25, "5 con PM2.5 nuevo en 2025", "otras 8")]
sub_cmp <- function(nombre, k) comparar(nombre, pred$fecha[k], pred$supera_25[k], pred$p_M0[k], pred$p_M1[k], CORTE, CORTE)
por_anio <- rbindlist(lapply(ANIOS_PRUEBA, function(an) sub_cmp(paste("Año", an), pred$anio == an)))
por_celda <- rbindlist(lapply(ANIOS_PRUEBA, function(an) rbindlist(lapply(unique(pred$grupo), function(gr)
  cbind(anio = an, grupo = gr, sub_cmp(paste(gr, an), pred$anio == an & pred$grupo == gr))))))
por_celda[, nota := ifelse(n < 100 | superaciones < 20, "n insuficiente", "")]
escribir(por_anio, "desempeno_por_anio.csv"); escribir(por_celda, "desempeno_por_grupo_y_anio.csv")


# ---- Bloque 18 (parte 1b, paso 4). Nivel relativo del PM2.5, 2024-2025 -------------------------------------
# Cociente PM2.5 de la estacion / mediana de la red ese dia (13 estaciones con PM2.5 diario valido).
# Un cambio de nivel tras instalar el equipo nuevo se veria como un salto en este cociente.
pm <- diario[anio %in% ANIOS_PRUEBA & !is.na(`PM2.5`), .(estacion, fecha, mes, pm25 = `PM2.5`)]
pm[, mediana_red := median(pm25), by = fecha][, cociente := pm25 / mediana_red]
rel <- pm[estacion %in% NUEVO_PM25, .(mediana_cociente = median(cociente), dias = .N), by = .(estacion, mes)][order(estacion, mes)]
escribir(rel, "pm25_relativo_2024_2025.csv")
malla_rel <- CJ(estacion = NUEVO_PM25, mes = seq(as.Date("2024-01-01"), as.Date("2025-12-01"), by = "month"))
g <- ggplot(merge(malla_rel, rel, by = c("estacion", "mes"), all.x = TRUE), aes(mes, mediana_cociente, colour = estacion)) +
  geom_hline(yintercept = 1, colour = "grey50") + geom_line(na.rm = TRUE) + geom_point(size = 1, na.rm = TRUE) + geom_vline(xintercept = as.Date("2025-01-01"), linetype = "dashed") +
  labs(x = NULL, y = "Mediana mensual de PM2.5 / mediana de la red", colour = NULL,
       title = "Nivel relativo del PM2.5 en las 5 estaciones con equipo nuevo en 2025") + tema
ggsave(file.path(FIGURAS, "pm25_relativo_2024_2025.png"), g, width = 7, height = 4, dpi = 150)


# ---- Bloque 19 (parte 1b, paso 5). Sensibilidad posterior: entrenar desde 2021-04-01 ------------------------
# Se reentrenan M0 y M1 solo con dias posteriores a la renovacion del viento, con el mismo
# procedimiento (medias de PRS y prevalencia del nuevo entrenamiento). No reemplaza al modelo principal.
a2 <- prs_anomalia(entrena[fecha >= as.Date("2021-04-01")], prueba)
s0 <- ajustar(a2$tr, a2$te, character()); s1 <- ajustar(a2$tr, a2$te, MET)
sens_abril <- cbind(n_entrena = nrow(a2$tr), corte = s1$corte,
                    comparar("Entrenamiento desde 2021-04-01", a2$te$fecha, a2$te$supera_25, s0$p, s1$p, s0$corte, s1$corte))
principal_fila <- comparar("Principal (entrenamiento 2021-2023)", pred$fecha, pred$supera_25, pred$p_M0, pred$p_M1, CORTE, CORTE)
sens_abril <- rbind(cbind(n_entrena = nrow(tr), corte = CORTE, principal_fila), sens_abril)
escribir(sens_abril, "sensibilidad_entrena_desde_2021_04.csv")


# ---- Bloque 20 (paso 9). RESUMEN_DIAGNOSTICO.md --------------------------------------------------------------
f3 <- function(x) ifelse(is.na(x), "—", sprintf("%.3f", x))
f1 <- function(x) sprintf("%.1f", x)
ic <- function(li, ls) sprintf("[%.3f, %.3f]", li, ls)
tabla_md <- function(dt) c(paste0("| ", paste(names(dt), collapse = " | "), " |"),
                          paste0("|", paste(rep("---", ncol(dt)), collapse = "|"), "|"),
                          apply(dt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
t_err <- function(d, col) d[, list(grupo = get(col), Modelo = modelo, n = n, `% sup.` = f1(pct_superacion), Sens. = f3(sensibilidad),
                                    Espec. = f3(especificidad), `Tasa FN` = f3(tasa_FN), `Tasa FP` = f3(tasa_FP))] |>
  setnames("grupo", if (col == "temporada") "Temporada" else "Estación")
t_cmp <- function(d) d[, .(Análisis = analisis, n, Superaciones = superaciones, `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1),
                           `ΔAUC` = f3(d_auc), `IC 95 %` = ic(d_auc_li, d_auc_ls))]
lineas <- c(
  "# Etapa 3 · Diagnósticos posteriores del modelo final", "",
  sprintf("Generado por `scripts/07c_diagnostico_errores.R` el %s. **No cambia ningún modelo ni métrica de 07b**: reconstruye M0 y M1 (LDA, entrenamiento 2021–2023, PRS como anomalía de su estación, sin transformaciones, corte %.3f) y describe sus errores en la prueba 2024–2025 (n = %s).",
          format(Sys.time(), "%Y-%m-%d %H:%M"), CORTE, format(nrow(pred), big.mark = ",")),
  "", "## 0. Verificación de la reconstrucción", "",
  tabla_md(verificacion[, .(Modelo = modelo, `AUC 07b` = sprintf("%.12f", auc_07b), `AUC 07c` = sprintf("%.12f", auc_07c),
                            Diferencia = sprintf("%.1e", diferencia))]), "",
  "El modelo quedó en `output/etapa3/modelo_final.rds` (objetos LDA, escalado, medias de PRS por estación, niveles, corte y predicciones de la prueba).",
  "", "## 1. Matrices de confusión (prueba)", "",
  tabla_md(confusion[, .(Modelo = modelo, VP, FN, FP, VN, Sensibilidad = f3(sensibilidad), Especificidad = f3(especificidad),
                         `Tasa FN` = f3(tasa_FN), `Tasa FP` = f3(tasa_FP))]),
  "", "## 2. Errores por temporada y por estación", "", tabla_md(t_err(err_temp[order(temporada, modelo)], "temporada")), "",
  tabla_md(t_err(err_est[order(estacion, modelo)], "estacion")),
  "", "## 3. Errores según la magnitud del PM2.5", "",
  tabla_md(err_mag[, .(`PM2.5 (µg/m³)` = intervalo, n, `% clasificado superación M0` = f1(pct_clasif_superacion_M0),
                       `% clasificado superación M1` = f1(pct_clasif_superacion_M1))]), "",
  "En [0,15), [15,20) y [20,25] el porcentaje clasificado como superación es la tasa de falsos positivos de ese intervalo; en (25,30], (30,40] y >40 es la sensibilidad.",
  "", "## 4. Calibración", "",
  tabla_md(dcast(calib, decil ~ modelo, value.var = c("p_media", "frecuencia_observada"))[, lapply(.SD, f3), by = decil] |>
             setnames(c("Decil", "p media M0", "p media M1", "Frecuencia obs. M0", "Frecuencia obs. M1"))), "",
  tabla_md(recal[, .(Modelo = modelo, Intercepto = f3(intercepto), Pendiente = f3(pendiente))]), "",
  "Recalibración: logística de la superación observada sobre logit(p). Intercepto 0 y pendiente 1 indicarían calibración perfecta.",
  "", "## 5. Importancia por permutación (prueba, 200 permutaciones, semilla 2026)", "",
  tabla_md(importancia[order(modelo != "M1", -caida_auc_media), .(Modelo = modelo, Variable = variable,
                       `Caída media del AUC` = f3(caida_auc_media), `P2.5` = f3(p2.5), `P97.5` = f3(p97.5))]),
  "", "## 6. Supuestos (entrenamiento 2021–2023)", "",
  "**a) Multicolinealidad** (PRS como anomalía):", "", tabla_md(vif[, .(Variable = variable, VIF = sprintf("%.2f", vif))]), "",
  sprintf("Número de condición de la matriz de correlación: %.2f (razón de valores propios %.1f).",
          condicion$numero_condicion, condicion$razon_valores_propios),
  "", "**b) Dependencia de los residuos de M1 en la prueba** (r = supera_25 − p_M1):", "",
  tabla_md(acf_prom[, .(Rezago = rezago, `ACF promedio` = f3(acf_promedio), Mínimo = f3(acf_min), Máximo = f3(acf_max))]), "",
  sprintf("Correlación promedio entre pares de estaciones el mismo día: %.3f (de %.3f a %.3f; %d pares). Junto con la autocorrelación, justifica el bootstrap por bloques de fechas que lleva todas las estaciones.",
          corr_mismo_dia$correlacion_promedio_pares, corr_mismo_dia$minimo, corr_mismo_dia$maximo, corr_mismo_dia$pares),
  "", "**c) Normalidad multivariada por clase** (Mardia, 8 continuas; calculada en el script, sin el paquete MVN):", "",
  tabla_md(normalidad[, .(Clase = clase, n, `Asimetría (χ²)` = sprintf("%.1f", asimetria_estadistico), gl = asimetria_gl,
                          `p` = format.pval(asimetria_p, digits = 3), `Curtosis (z)` = sprintf("%.1f", curtosis_estadistico),
                          `p ` = format.pval(curtosis_p, digits = 3))]), "",
  "Con este tamaño de muestra la prueba rechaza; se documenta como limitación de la LDA (la logística de 07b es la robustez).",
  "", "## 7. Mapa", "", "`figuras/mapa_estaciones.png` (datos en `diagnostico/mapa_estaciones.csv`).",
  "", "## 8. Cambios de instrumentos (diagnósticos posteriores)", "",
  "Información del socio formador recibida el 9-oct-2026: en 2021 SIMA renovó los sensores de viento de todas las estaciones y los analizadores de O3, NO2, SO2 y CO (excepto SE2, SO2 y NTE2); en 2025 instaló equipos nuevos de PM2.5 (Thermo 5014i) en SE2, NTE2, SUR, SO2 y NO, completó CO en SE2, SO2 y NTE2 y cambió las bombas de los BAM de PM10. Estos diagnósticos son posteriores a la evaluación de la prueba; el modelo principal no cambia.",
  "", "**Mes de cambio del viento en 2021** (primer mes de 2021 cuya mediana difiere más de 30 % de la mediana de 2020; descriptivo):", "",
  tabla_md(mes_cambio[, .(Estación = estacion, `Mediana 2020 (m/s)` = f3(mediana_2020), `Mes de cambio` = mes_cambio,
                          `Mediana ese mes` = f3(mediana_mes_cambio))]), "",
  "**Desempeño por año de la prueba:**", "", tabla_md(t_cmp(por_anio)), "",
  "**Por grupo de estaciones y año** (5 con PM2.5 nuevo en 2025: SE2, NTE2, SUR, SO2, NO):", "",
  tabla_md(cbind(t_cmp(por_celda), Nota = por_celda$nota)), "",
  "**Nivel relativo del PM2.5** (mediana mensual de PM2.5 / mediana de la red): `figuras/pm25_relativo_2024_2025.png`, datos en `diagnostico/pm25_relativo_2024_2025.csv`. Mediana del cociente por estación y año:", "",
  tabla_md(dcast(pm[estacion %in% NUEVO_PM25, .(m = f3(median(cociente))), by = .(Estación = estacion, anio = year(fecha))],
                 Estación ~ anio, value.var = "m")), "",
  "**Sensibilidad posterior: entrenar solo desde 2021-04-01** (después de la renovación del viento):", "",
  tabla_md(cbind(`n entrenamiento` = format(sens_abril$n_entrena, big.mark = ","), Corte = f3(sens_abril$corte), t_cmp(sens_abril))),
  "", "## 9. Figuras", "",
  paste0("`figuras/", c("errores_temporada_estacion", "errores_magnitud_pm25", "calibracion", "importancia_permutacion",
                         "acf_residuos", "dauc_temporada", "mapa_estaciones", "viento_mensual_2020_2025", "pm25_relativo_2024_2025"),
         ".png`", collapse = ", "))
con <- file(file.path(SALIDA, "RESUMEN_DIAGNOSTICO.md"), "w", encoding = "UTF-8"); writeLines(lineas, con); close(con)
cat("Listo: output/etapa3/RESUMEN_DIAGNOSTICO.md\n")
