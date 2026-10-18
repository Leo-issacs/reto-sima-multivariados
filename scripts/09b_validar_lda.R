# =============================================================================================
# Etapa 4, fase C1 (D21 de docs/etapa4/decisiones_etapa4.md): validacion e interpretacion del LDA.
# No cambia el modelo: usa el analisis final v2 de 09a (base con la mediana de la red ajustada,
# entrenamiento 2021-2023 solo con sitio_valido = 1, prueba 2024-2025).
#
#   1. Estabilidad: bootstrap por bloques de 14 dias en el ENTRENAMIENTO (1 000 replicas). IC 95 % del
#      coeficiente estandarizado y de la correlacion de estructura de cada predictor, y % de replicas
#      con el mismo signo que el modelo completo. Solo se interpretan los de signo estable (>= 95 %).
#   2. Concordancia: coeficientes estandarizados del LDA y de la logistica, lado a lado.
#   3. Consistencia en el tiempo: coeficientes de M1 en los pliegues que validan 2022 y 2023 y en el
#      modelo final.
#   4. QDA como tecnica no exitosa: QDA regularizada (klaR::rda) frente al LDA, con la misma particion;
#      y QDA solo con meteorologia frente al LDA solo con meteorologia.
#   5. Calibracion de M1 en la prueba: deciles, intercepto y pendiente (como en 07c).
#
# Ejecutar desde la raiz:  Rscript scripts/09b_validar_lda.R   (despues de 09a)
# Escribe: output/etapa4/lda/
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y constantes -------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
  library(klaR)
})
source("R/modelo_etapa4.R")
SALIDA <- "output/etapa4/lda"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))
ANIOS_ENTRENA <- 2021:2023; ANIOS_PRUEBA <- 2024:2025
INICIO_BLOQUES <- as.Date("2024-01-01")       # bloques de la prueba (no se usan aqui)
INICIO_ENTRENA <- as.Date("2021-01-01")       # bloques del entrenamiento
N_REPLICAS <- 1000L
SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")


# ---- Bloque 1. Datos del analisis final v2 (igual que 09a, paso 4) ------------------------------------------
d <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
d[, fecha := as.Date(fecha)][, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
setorder(d, estacion, fecha)
ESTACIONES <- sort(unique(d$estacion))
entrena <- d[anio %in% ANIOS_ENTRENA & sitio_valido == 1L]
prueba <- d[anio %in% ANIOS_PRUEBA]
a <- prs_anomalia(entrena, prueba)
tr <- a$tr; te <- a$te
m0 <- ajustar(tr, te, character()); m1 <- ajustar(tr, te, MET)
ref <- fread("output/etapa4/prueba_v2_metricas_m0_m1.csv")
stopifnot(abs(auc_proc(te$supera_25, m1$p) - ref[modelo == "M1", auc]) < 1e-12)   # mismo modelo que 09a


# ---- Bloque 2. Coeficientes orientados ----------------------------------------------------------------------
# El signo de la funcion discriminante es arbitrario: se orienta para que una puntuacion mayor sea "mas
# superacion" (media de la clase 1 > media de la clase 0). Coeficiente estandarizado = el de la funcion
# sobre los predictores estandarizados; correlacion de estructura = correlacion de cada predictor con la
# puntuacion en el entrenamiento (Rencher, 1992).
coef_lda <- function(fit, y) {
  w <- fit$modelo$scaling[, 1]
  s <- as.vector(fit$z_tr %*% w)
  sg <- sign(mean(s[y == 1]) - mean(s[y == 0]))
  list(w = sg * w, estructura = as.vector(cor(fit$z_tr, sg * s)))
}
c_fin <- coef_lda(m1, tr$supera_25)
PRED <- colnames(m1$z_tr)


# ---- Bloque 3. Estabilidad: bootstrap por bloques en el entrenamiento --------------------------------------
# Cada replica remuestrea bloques de 14 dias (con todas las estaciones) y repite TODO el ajuste: medias
# de PRS por estacion, estandarizacion y LDA con prior = prevalencia de la replica.
bloque <- as.integer(entrena$fecha - INICIO_ENTRENA) %/% 14L
filas <- split(seq_len(nrow(entrena)), bloque)
set.seed(SEMILLA)
reps <- lapply(seq_len(N_REPLICAS), function(i) {
  idx <- unlist(filas[sample.int(length(filas), length(filas), replace = TRUE)], use.names = FALSE)
  e <- entrena[idx]
  r <- tryCatch({
    ab <- prs_anomalia(e, e[1:2])
    f <- ajustar(ab$tr, ab$te, MET)
    cl <- coef_lda(f, ab$tr$supera_25)
    if (!identical(names(cl$w), PRED)) NULL else cl
  }, error = function(err) NULL)
  r
})
ok <- !vapply(reps, is.null, logical(1))
W <- do.call(rbind, lapply(reps[ok], `[[`, "w")); S <- do.call(rbind, lapply(reps[ok], `[[`, "estructura"))
estab <- data.table(predictor = PRED, coef_estandarizado = c_fin$w, coef_relativo_al_maximo = c_fin$w / max(abs(c_fin$w)),
                    coef_li = apply(W, 2, quantile, 0.025), coef_ls = apply(W, 2, quantile, 0.975),
                    pct_mismo_signo_coef = 100 * colMeans(sign(W) == rep(sign(c_fin$w), each = nrow(W))),
                    estructura = c_fin$estructura, estructura_li = apply(S, 2, quantile, 0.025), estructura_ls = apply(S, 2, quantile, 0.975),
                    pct_mismo_signo_estructura = 100 * colMeans(sign(S) == rep(sign(c_fin$estructura), each = nrow(S))))
estab[, signo_estable := pct_mismo_signo_coef >= 95]
estab[, tipo := fifelse(predictor %in% MET, "meteorología", fifelse(grepl("^est", predictor), "estación", "temporada"))]
estab[, replicas_validas := sum(ok)]
escribir(estab, "estabilidad_coeficientes.csv")
print(estab[tipo == "meteorología", .(predictor, coef = round(coef_estandarizado, 3), li = round(coef_li, 3), ls = round(coef_ls, 3),
                                       signo = round(pct_mismo_signo_coef, 1), estr = round(estructura, 3), estable = signo_estable)])


# ---- Bloque 4. LDA frente a logistica (predictores estandarizados) ----------------------------------------------
l1 <- ajustar(tr, te, MET, metodo = "logistica")
b_log <- coef(l1$modelo)[-1]
names(b_log) <- PRED
lda_log <- data.table(predictor = PRED, lda = c_fin$w, logistica = b_log,
                      lda_relativo = c_fin$w / max(abs(c_fin$w)), logistica_relativo = b_log / max(abs(b_log)))
lda_log[, signo_coincide := sign(lda) == sign(logistica)]
lda_log[, marca := fifelse(signo_coincide, "", "SIGNO DISTINTO")]
escribir(lda_log, "lda_vs_logistica.csv")


# ---- Bloque 5. Coeficientes por pliegue (validacion progresiva) y modelo final ------------------------------------
# Entrena 2021 -> valida 2022; entrena 2021-2022 -> valida 2023; y el modelo final (2021-2023). Mismos
# datos de entrenamiento del analisis final (sitio_valido = 1). Se reporta tambien el AUC de validacion.
# Con D23, NE no tiene dias en 2021 (todo su 2021 es previo a la reubicacion): en cada pliegue se usan
# solo las estaciones presentes en su entrenamiento (tambien en su validacion), y el coeficiente de una
# estacion ausente queda vacio.
pliegues <- list("valida_2022" = list(tr = 2021, va = 2022), "valida_2023" = list(tr = 2021:2022, va = 2023))
coef_pl <- data.table(predictor = PRED)
auc_pl <- list()
ESTACIONES_TODAS <- ESTACIONES
for (nm in names(pliegues)) {
  e <- entrena[anio %in% pliegues[[nm]]$tr]
  ESTACIONES <- sort(unique(e$estacion))           # matriz_x() usa ESTACIONES para las indicadoras
  v <- entrena[anio %in% pliegues[[nm]]$va & estacion %in% ESTACIONES]
  ab <- prs_anomalia(e, v)
  f0 <- ajustar(ab$tr, ab$te, character()); f1 <- ajustar(ab$tr, ab$te, MET)
  cf <- coef_lda(f1, ab$tr$supera_25)
  set(coef_pl, j = nm, value = unname(cf$w[PRED]))
  auc_pl[[nm]] <- data.table(pliegue = nm, estaciones = length(ESTACIONES), n_entrena = nrow(ab$tr), n_valida = nrow(ab$te),
                             auc_M0 = auc_proc(ab$te$supera_25, f0$p), auc_M1 = auc_proc(ab$te$supera_25, f1$p))
}
ESTACIONES <- ESTACIONES_TODAS
set(coef_pl, j = "final_2021_2023", value = unname(c_fin$w))
coef_pl[, signo_igual_en_los_tres := sign(valida_2022) == sign(valida_2023) & sign(valida_2023) == sign(final_2021_2023)]
coef_pl[, tipo := fifelse(predictor %in% MET, "meteorología", fifelse(grepl("^est", predictor), "estación", "temporada"))]
auc_pl <- rbindlist(auc_pl)[, d_auc := auc_M1 - auc_M0]
escribir(coef_pl, "coeficientes_por_pliegue.csv")
escribir(auc_pl, "pliegues_auc_validacion.csv")


# ---- Bloque 6. QDA como tecnica no exitosa ----------------------------------------------------------------------
# a) Todos los predictores de M1 (indicadoras + meteorologia): QDA regularizada (klaR::rda), que elige
#    por validacion cruzada en el entrenamiento cuanto acercar cada covarianza a la comun (lambda) y a la
#    identidad (gamma). Prior = prevalencia de entrenamiento, como el LDA.
# b) Solo las 8 meteorologicas: QDA sin regularizar (MASS::qda) y regularizada, frente al LDA con esas 8.
# Se compara el AUC en la prueba con el del LDA (misma particion y mismos datos).
prev <- mean(tr$supera_25)
y_tr <- factor(tr$supera_25, levels = c(0, 1))
auc_te <- function(p) auc_proc(te$supera_25, p)
set.seed(SEMILLA)
rda_todo <- tryCatch(klaR::rda(m1$z_tr, grouping = y_tr, prior = c(1 - prev, prev)), error = function(e) e)
z_met_tr <- m1$z_tr[, MET]; z_met_te <- m1$z_te[, MET]
set.seed(SEMILLA)
rda_met <- tryCatch(klaR::rda(z_met_tr, grouping = y_tr, prior = c(1 - prev, prev)), error = function(e) e)
qda_met <- MASS::qda(z_met_tr, grouping = y_tr, prior = c(1 - prev, prev))
lda_met <- MASS::lda(z_met_tr, grouping = y_tr, prior = c(1 - prev, prev))
fila_rda <- function(nombre, preds, fit, x_te) {
  if (inherits(fit, "error")) return(data.table(modelo = nombre, predictores = preds, auc_prueba = NA_real_, gamma = NA_real_,
                                                lambda = NA_real_, nota = conditionMessage(fit)))
  p <- predict(fit, x_te)$posterior[, "1"]
  data.table(modelo = nombre, predictores = preds, auc_prueba = auc_te(p), gamma = fit$regularization[["gamma"]],
             lambda = fit$regularization[["lambda"]], nota = "")
}
qda_lda <- rbind(
  data.table(modelo = "LDA (M1, análisis final)", predictores = "indicadoras + 8 meteorológicas", auc_prueba = auc_te(m1$p), gamma = NA_real_, lambda = NA_real_, nota = ""),
  fila_rda("QDA regularizada (klaR::rda)", "indicadoras + 8 meteorológicas", rda_todo, m1$z_te),
  data.table(modelo = "LDA", predictores = "solo 8 meteorológicas", auc_prueba = auc_te(predict(lda_met, z_met_te)$posterior[, "1"]),
             gamma = NA_real_, lambda = NA_real_, nota = ""),
  data.table(modelo = "QDA (MASS::qda)", predictores = "solo 8 meteorológicas", auc_prueba = auc_te(predict(qda_met, z_met_te)$posterior[, "1"]),
             gamma = NA_real_, lambda = NA_real_, nota = ""),
  fila_rda("QDA regularizada (klaR::rda)", "solo 8 meteorológicas", rda_met, z_met_te))
qda_lda[, referencia_python_opus_no_oficial := c("0.792", "0.728–0.742", "0.718", "0.709", "0.709")]
escribir(qda_lda, "qda_vs_lda.csv")
print(qda_lda)


# ---- Bloque 7. Calibracion de M1 en la prueba (como en 07c) ------------------------------------------------------
pred <- fread("output/etapa4/prueba_v2_predicciones.csv")
calib <- rbindlist(lapply(c("M0", "M1"), function(m) {
  p <- pred[[paste0("p_", m)]]
  decil <- cut(rank(p, ties.method = "first"), 10, labels = FALSE)
  data.table(modelo = m, decil, p, y = pred$supera_25)[, .(n = .N, p_media = mean(p), frecuencia_observada = mean(y)), by = .(modelo, decil)][order(decil)]
}))
recal <- rbindlist(lapply(c("M0", "M1"), function(m) {
  co <- coef(glm(pred$supera_25 ~ qlogis(pred[[paste0("p_", m)]]), family = binomial))
  data.table(modelo = m, intercepto = co[[1]], pendiente = co[[2]])
}))
escribir(calib, "calibracion_deciles.csv"); escribir(recal, "calibracion_recalibracion.csv")


# ---- Bloque 8. Figuras -----------------------------------------------------------------------------------------
# IC del coeficiente estandarizado de cada predictor (puntos con barras); en color los de signo estable.
fe <- copy(estab)[, etiqueta := sub("^est", "estación ", sub("^tem", "temporada ", predictor))]
fe[predictor == "PRS", etiqueta := "PRS (anomalía de su estación)"]
fe[, etiqueta := factor(etiqueta, levels = etiqueta[order(coef_estandarizado)])]
g <- ggplot(fe, aes(coef_estandarizado, etiqueta, colour = signo_estable)) +
  geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = coef_li, xmax = coef_ls)) +
  scale_colour_manual(values = c(`TRUE` = "#D55E00", `FALSE` = "grey60"), labels = c(`TRUE` = "signo estable (≥ 95 %)", `FALSE` = "signo no estable"), name = NULL) +
  facet_grid(tipo ~ ., scales = "free_y", space = "free_y") +
  labs(x = "Coeficiente estandarizado de M1 (IC 95 %, bootstrap por bloques de 14 días en el entrenamiento)", y = NULL,
       title = "Estabilidad de la función discriminante (base v2, 1 000 réplicas)") +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom")
ggsave(file.path(SALIDA, "coeficientes_ic.png"), g, width = 7.5, height = 7, dpi = 150)
g <- ggplot(calib, aes(p_media, frecuencia_observada, colour = modelo)) +
  geom_abline(linetype = "dotted") + geom_line() + geom_point() +
  scale_colour_manual(values = c(M0 = "#0072B2", M1 = "#D55E00"), name = NULL) + coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Probabilidad media predicha (decil)", y = "Frecuencia observada de superación", title = "Calibración en la prueba (base v2)") +
  theme_minimal(base_size = 10)
ggsave(file.path(SALIDA, "calibracion_v2.png"), g, width = 5, height = 5, dpi = 150)
message("Listo: ", SALIDA)
