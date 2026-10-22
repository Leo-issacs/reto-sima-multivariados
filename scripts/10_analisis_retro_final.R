# =============================================================================================
# Etapa 4, fase F: analisis posteriores a la retroalimentacion final (22 de octubre de 2026).
#
# Todo lo de este script es POSTERIOR a la evaluacion de la prueba (09a). No cambia el modelo principal
# ni sus cifras: usa el analisis final v2 (base con la mediana de la red ajustada, entrenamiento
# 2021-2023 con sitio_valido = 1, prueba 2024-2025) y las funciones de R/modelo_etapa4.R sin cambios, y
# agrega evidencia complementaria. Las reglas estan en docs/etapa4/decisiones_etapa4.md (fase F); las
# decisiones se toman solo con el entrenamiento, con los pliegues de la validacion progresiva de 09b
# (entrenar 2021 -> validar 2022; entrenar 2021-2022 -> validar 2023).
#
#   A. Regresion logistica: odds ratios por 1 DE con IC por bootstrap por bloques en el entrenamiento,
#      importancia por permutacion en la prueba y linealidad en la escala logit (logits empiricos por
#      grupos, GAM y AUC con splines).
#   B. Persistencia: PM2.5 del dia calendario anterior frente a la meteorologia del dia.
#   C. Umbral de clasificacion elegido con los pliegues y evaluado en la prueba.
#   D. Bootstrap por bloques estratificado por temporada.
#   E. Episodios frente a dias-estacion.
#   F. Exclusiones y posible sesgo.
#
# Modo solo entrenamiento (fija las decisiones de A2, B y C antes de mirar la prueba):
#   SOLO_ENTRENAMIENTO=1 Rscript scripts/10_analisis_retro_final.R
#   escribe output/etapa4/retro_final/decisiones_entrenamiento.csv y se detiene.
# Corrida completa (despues de 09a y 09b):
#   Rscript scripts/10_analisis_retro_final.R
# Escribe: output/etapa4/retro_final/
# =============================================================================================


# ---- Bloque 0. Paquetes, constantes y carpetas -------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
  library(mgcv)
})
source("R/modelo_etapa4.R")
SOLO_ENTRENAMIENTO <- Sys.getenv("SOLO_ENTRENAMIENTO") == "1"
SALIDA <- "output/etapa4/retro_final"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre), eol = "\n")
guardar <- function(g, nombre, ancho, alto) ggsave(file.path(SALIDA, nombre), g, width = ancho, height = alto, dpi = 250, bg = "white")
ANIOS_ENTRENA <- 2021:2023; ANIOS_PRUEBA <- 2024:2025
INICIO_BLOQUES <- as.Date("2024-01-01")       # bloques de la prueba (como 09a)
INICIO_ENTRENA <- as.Date("2021-01-01")       # bloques del entrenamiento (como 09b)
FIN_PRUEBA <- as.Date("2025-12-31")
N_REPLICAS <- 1000L
N_PERMUTACIONES <- 200L
SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")   # orden de 07b
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")
MEJORA_MINIMA_SPLINES <- 0.005                # regla de A2c (fase F)
SENSIBILIDAD_VIGILANCIA <- 0.80               # regla de C2 (i)
UMBRAL_LLUVIA <- 0.5                          # "llovio": >= 0.5 h (la imputacion diaria deja fracciones como 0.018)
NOMBRES <- c(TOUT = "Temperatura", RH = "Humedad relativa", SR = "Radiación solar", PRS = "Presión (anomalía)",
             viento_rapidez_ms = "Rapidez del viento", viento_u = "Viento u (este-oeste)", viento_v = "Viento v (norte-sur)",
             horas_lluvia = "Horas con lluvia")
UNIDADES <- c(TOUT = "°C", RH = "%", SR = "kW/m²", PRS = "mm Hg", viento_rapidez_ms = "m/s", viento_u = "m/s", viento_v = "m/s",
              horas_lluvia = "h")


# ---- Bloque 1. Datos del analisis final (igual que 09a, paso 4, y 09b) ---------------------------------------
# `todo` son los 23 738 estacion-dias (13 estaciones x 1 826 dias). La persistencia es el PM2.5 del dia
# calendario anterior de la misma estacion (columna PM2.5 de v2: >= 18 h observadas, vacia si no); se anula
# si el dia anterior es de otro sitio (cruce de una reubicacion, D23). El 1 de enero de 2021 no tiene dia
# anterior en la base.
todo <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")
todo[, fecha := as.Date(fecha)][, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
ayer <- todo[, .(estacion, fecha = fecha + 1L, pm_ayer = `PM2.5`, sitio_ayer = sitio_valido)]
todo <- merge(todo, ayer, by = c("estacion", "fecha"), all.x = TRUE)
todo[!is.na(sitio_ayer) & sitio_ayer != sitio_valido, pm_ayer := NA_real_]
todo[, `:=`(log_pm_ayer = log(pm_ayer), llovio_ind = as.integer(horas_lluvia >= UMBRAL_LLUVIA), sitio_ayer = NULL)]
setorder(todo, estacion, fecha)
stopifnot(nrow(todo) == 23738L)
d <- todo[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
ESTACIONES <- sort(unique(d$estacion))
entrena <- d[anio %in% ANIOS_ENTRENA & sitio_valido == 1L]
prueba <- d[anio %in% ANIOS_PRUEBA]
a <- prs_anomalia(entrena, prueba)
tr <- a$tr
stopifnot(nrow(tr) == 10965L, nrow(prueba) == 6863L)


# ---- Bloque 2. Funciones ------------------------------------------------------------------------------------
# con_estaciones(): evalua `expr` con ESTACIONES = `est` (matriz_x() usa esa variable global) y la restaura.
con_estaciones <- function(est, expr) {
  anterior <- ESTACIONES; ESTACIONES <<- est; on.exit(ESTACIONES <<- anterior)
  expr
}
# pliegue(): un pliegue de la validacion progresiva, como en 09b: entrena con los anios `tr`, valida el anio
#   `va`, solo con las estaciones presentes en el entrenamiento del pliegue (con D23, NE no tiene dias en
#   2021) y PRS como anomalia con las medias del entrenamiento del pliegue.
PLIEGUES <- list(valida_2022 = list(tr = 2021L, va = 2022L), valida_2023 = list(tr = 2021:2022, va = 2023L))
pliegue <- function(base, p) {
  e <- base[anio %in% p$tr]; est <- sort(unique(e$estacion))
  v <- base[anio %in% p$va & estacion %in% est]
  ab <- prs_anomalia(e, v)
  list(tr = ab$tr, te = ab$te, estaciones = est)
}
# ajustar_gam(): M1 logistico con las indicadoras lineales y un spline penalizado por cada continua (mgcv,
#   REML), sobre los mismos predictores estandarizados de ajustar().
ajustar_gam <- function(tr, te, numericas = MET) {
  base <- ajustar(tr, te, numericas, metodo = "logistica")
  ind <- setdiff(colnames(base$z_tr), numericas)
  f <- reformulate(c(ind, sprintf("s(%s)", numericas)), response = "yy")
  m <- mgcv::gam(f, family = binomial, method = "REML", data = data.frame(yy = tr$supera_25, base$z_tr))
  list(p = as.vector(predict(m, data.frame(base$z_te), type = "response")), corte = base$corte, modelo = m, base = base)
}
# metricas_corte(): matriz de confusion y metricas de la regla p >= corte.
metricas_corte <- function(y, p, corte) {
  cl <- p >= corte
  vp <- sum(cl & y == 1); fp <- sum(cl & y == 0); fn <- sum(!cl & y == 1); vn <- sum(!cl & y == 0)
  data.table(corte = corte, vp = vp, fp = fp, fn = fn, vn = vn, sensibilidad = vp / (vp + fn), especificidad = vn / (vn + fp),
             vpp = vp / (vp + fp), falsas_por_detectada = fp / vp, exactitud_balanceada = (vp / (vp + fn) + vn / (vn + fp)) / 2,
             pct_marcados = 100 * mean(cl))
}
# elegir_cortes(): (i) el corte mas alto con sensibilidad >= 0.80 y (ii) el que maximiza el indice de Youden,
#   entre los valores observados de p (regla p >= corte).
elegir_cortes <- function(y, p) {
  u <- sort(unique(p), decreasing = TRUE)
  sens <- cumsum(tabulate(match(p[y == 1], u), nbins = length(u))) / sum(y == 1)
  espe <- 1 - cumsum(tabulate(match(p[y == 0], u), nbins = length(u))) / sum(y == 0)
  c(vigilancia = max(u[sens >= SENSIBILIDAD_VIGILANCIA]), equilibrio = u[which.max(sens + espe - 1)])
}
# bootstrap_estratificado(): como bootstrap() de R/modelo_etapa4.R (bloques de 14 dias con todas las
#   estaciones, predicciones fijas), pero remuestrea los bloques dentro de su temporada y conserva cuantos
#   bloques tiene cada una. `temporada_bloque` es un vector con nombre = numero de bloque.
bootstrap_estratificado <- function(fechas, y, p_a, p_b, temporada_bloque, dias = 14L, n = N_REPLICAS, semilla = SEMILLA,
                                    inicio = INICIO_BLOQUES) {
  bloque <- as.integer(fechas - inicio) %/% dias
  filas <- split(seq_along(bloque), bloque)
  grupos <- split(seq_along(filas), temporada_bloque[names(filas)])
  set.seed(semilla)
  rep <- t(vapply(seq_len(n), function(i) {
    elegidos <- unlist(lapply(grupos, function(k) k[sample.int(length(k), length(k), replace = TRUE)]), use.names = FALSE)
    idx <- unlist(filas[elegidos], use.names = FALSE)
    c(auc_a = auc_rapido(y[idx], p_a[idx]), auc_b = auc_rapido(y[idx], p_b[idx]))
  }, numeric(2)))
  rep <- as.data.table(rep)[, d_auc := auc_b - auc_a]
  list(replicas = rep, bloques_por_temporada = vapply(grupos, length, integer(1)),
       ic = c(li = quantile(rep$d_auc, 0.025, names = FALSE), ls = quantile(rep$d_auc, 0.975, names = FALSE)))
}
# rachas(): numera las rachas de dias consecutivos de una misma estacion que cumplen `cond`; un dia ausente
#   de `x` (sin respuesta o excluido) corta la racha. Devuelve `x` con la columna `episodio` (NA si no cumple).
rachas <- function(x, cond) {
  x <- copy(x)[, cumple := cond]
  setorder(x, estacion, fecha)
  x[, inicio := cumple & !(c(FALSE, diff(as.integer(fecha)) == 1L) & shift(cumple, fill = FALSE)), by = estacion]
  x[, episodio := fifelse(cumple, cumsum(inicio), NA_integer_)]
  x[, c("cumple", "inicio") := NULL]
  x
}
# grupos_logit(): grupos de un predictor continuo para los logits empiricos: deciles; en la lluvia (92 % de
#   los dias sin lluvia), los dias sin lluvia y cuartiles de los dias con lluvia.
grupos_logit <- function(x, lluvia = FALSE) {
  if (lluvia) {
    pos <- x >= UMBRAL_LLUVIA
    g <- rep("sin lluvia", length(x))
    g[pos] <- as.character(cut(x[pos], unique(quantile(x[pos], 0:4 / 4)), include.lowest = TRUE))
    return(factor(g))
  }
  cut(x, unique(quantile(x, 0:10 / 10)), include.lowest = TRUE)
}
auc_m <- function(y, p) auc_proc(y, p)


# ---- Bloque 3. Decisiones con el entrenamiento (pliegues de la validacion progresiva) ------------------------------
# A2c: AUC de validacion de M1 logistico lineal, con splines (GAM) y con la indicadora "llovio".
# B: AUC de validacion de MP logistico con el PM2.5 del dia anterior en escala original y en log.
# C1-C2: predicciones fuera de muestra de M1 (LDA y logistica) en 2022 y 2023, y cortes elegidos con ellas.
pl_auc <- list(); pl_pred <- list(); pl_pers <- list()
for (nm in names(PLIEGUES)) {
  pl <- pliegue(entrena, PLIEGUES[[nm]])
  y <- pl$te$supera_25
  con_estaciones(pl$estaciones, {
    lin <- ajustar(pl$tr, pl$te, MET, metodo = "logistica")
    gam_f <- ajustar_gam(pl$tr, pl$te)
    llov <- ajustar(pl$tr, pl$te, c(MET, "llovio_ind"), metodo = "logistica")
    lda <- ajustar(pl$tr, pl$te, MET)
  })
  pl_auc[[nm]] <- data.table(pliegue = nm, n_entrena = nrow(pl$tr), n_valida = nrow(pl$te), auc_M1_lineal = auc_m(y, lin$p),
                             auc_M1_splines = auc_m(y, gam_f$p), auc_M1_llovio = auc_m(y, llov$p))
  pl_pred[[nm]] <- data.table(pliegue = nm, supera_25 = y, p_lda = lda$p, p_logistica = lin$p, prior_lda = lda$corte)
  # Persistencia: solo los dias con PM2.5 del dia anterior (en el entrenamiento y la validacion del pliegue).
  ps <- pliegue(entrena[!is.na(pm_ayer)], PLIEGUES[[nm]])
  con_estaciones(ps$estaciones, {
    mp_lin <- ajustar(ps$tr, ps$te, "pm_ayer", metodo = "logistica")
    mp_log <- ajustar(ps$tr, ps$te, "log_pm_ayer", metodo = "logistica")
    mp_lin_lda <- ajustar(ps$tr, ps$te, "pm_ayer"); mp_log_lda <- ajustar(ps$tr, ps$te, "log_pm_ayer")
  })
  yp <- ps$te$supera_25
  pl_pers[[nm]] <- data.table(pliegue = nm, n_entrena = nrow(ps$tr), n_valida = nrow(ps$te),
                              auc_MP_lineal_logistica = auc_m(yp, mp_lin$p), auc_MP_log_logistica = auc_m(yp, mp_log$p),
                              auc_MP_lineal_lda = auc_m(yp, mp_lin_lda$p), auc_MP_log_lda = auc_m(yp, mp_log_lda$p))
}
pl_auc <- rbindlist(pl_auc)[, `:=`(dif_splines = auc_M1_splines - auc_M1_lineal, dif_llovio = auc_M1_llovio - auc_M1_lineal)]
pl_pers <- rbindlist(pl_pers)[, dif_log_logistica := auc_MP_log_logistica - auc_MP_lineal_logistica]
pl_pred <- rbindlist(pl_pred)
ADOPTA_SPLINES <- all(pl_auc$dif_splines >= MEJORA_MINIMA_SPLINES)
USA_LOG <- all(pl_pers$dif_log_logistica > 0)
LAG <- if (USA_LOG) "log_pm_ayer" else "pm_ayer"
CORTE_ACTUAL <- mean(tr$supera_25)
cortes <- rbindlist(lapply(c(lda = "p_lda", logistica = "p_logistica"), function(col) {
  k <- elegir_cortes(pl_pred$supera_25, pl_pred[[col]])
  data.table(objetivo = c("vigilancia", "equilibrio", "actual"), corte = c(k[["vigilancia"]], k[["equilibrio"]], CORTE_ACTUAL))
}), idcol = "clasificador")
cortes_pliegues <- rbindlist(lapply(seq_len(nrow(cortes)), function(i) {
  col <- if (cortes$clasificador[i] == "lda") "p_lda" else "p_logistica"
  cbind(cortes[i, .(clasificador, objetivo)], metricas_corte(pl_pred$supera_25, pl_pred[[col]], cortes$corte[i]))
}))
decisiones <- data.table(
  decision = c("A2: splines como tratamiento de la no linealidad", "B: escala del PM2.5 del día anterior",
               sprintf("C: corte de vigilancia (%s)", cortes[objetivo == "vigilancia", clasificador]),
               sprintf("C: corte de equilibrio (%s)", cortes[objetivo == "equilibrio", clasificador]), "C: corte actual"),
  resultado = c(if (ADOPTA_SPLINES) "sí" else "no", if (USA_LOG) "log" else "original",
                sprintf("%.4f", cortes[objetivo == "vigilancia", corte]), sprintf("%.4f", cortes[objetivo == "equilibrio", corte]),
                sprintf("%.4f", CORTE_ACTUAL)),
  base = c(sprintf("Diferencia de AUC de validación (splines − lineal): %s; regla ≥ %.3f en los dos pliegues",
                   paste(sprintf("%.4f", pl_auc$dif_splines), collapse = " y "), MEJORA_MINIMA_SPLINES),
           sprintf("Diferencia de AUC de validación de MP logístico (log − original): %s; regla > 0 en los dos pliegues",
                   paste(sprintf("%.4f", pl_pers$dif_log_logistica), collapse = " y ")),
           rep("Predicciones de M1 en 2022 y 2023 (pliegues de la validación progresiva)", 4), "Prevalencia del entrenamiento"))
escribir(pl_auc, "a2_auc_pliegues.csv")
escribir(pl_pers, "b_escala_persistencia_pliegues.csv")
escribir(pl_pred, "c_predicciones_pliegues.csv")
escribir(cortes_pliegues, "c_cortes_en_pliegues.csv")
escribir(decisiones, "decisiones_entrenamiento.csv")
print(pl_auc); print(pl_pers); print(cortes_pliegues); print(decisiones)
if (SOLO_ENTRENAMIENTO) {
  message("Modo SOLO_ENTRENAMIENTO: decisiones escritas en ", file.path(SALIDA, "decisiones_entrenamiento.csv"), "; no se lee la prueba.")
  quit(save = "no", status = 0)
}


# ---- Bloque 4. Modelos del analisis final y comprobacion contra 09a ------------------------------------------------
te <- a$te
m0 <- ajustar(tr, te, character()); m1 <- ajustar(tr, te, MET)
l0 <- ajustar(tr, te, character(), metodo = "logistica"); l1 <- ajustar(tr, te, MET, metodo = "logistica")
ref <- fread("output/etapa4/prueba_v2_metricas_m0_m1.csv")
stopifnot(abs(auc_proc(te$supera_25, m1$p) - ref[modelo == "M1", auc]) < 1e-12,
          abs(auc_proc(te$supera_25, m0$p) - ref[modelo == "M0", auc]) < 1e-12)
ref_log <- fread("output/etapa4/prueba_v2_sensibilidades.csv")[2]
b_lda <- bootstrap(te$fecha, te$supera_25, m0$p, m1$p, m0$corte, m1$corte)
b_log <- bootstrap(te$fecha, te$supera_25, l0$p, l1$p, l0$corte, l1$corte)
stopifnot(abs(auc_proc(te$supera_25, l1$p) - auc_proc(te$supera_25, l0$p) - ref_log$d_auc) < 1e-12,
          abs(b_log$ic$d_auc_li - ref_log$d_auc_li) < 1e-12, abs(b_log$ic$d_auc_ls - ref_log$d_auc_ls) < 1e-12)
# Metricas de los dos clasificadores con el corte = prevalencia de entrenamiento (para la tabla principal).
met_cols <- c("auc", "exactitud_balanceada", "sensibilidad", "especificidad", "brier")
tabla_principal <- rbindlist(list(
  data.table(clasificador = "LDA", modelo = c("M0", "M1"), rbind(metricas(te$supera_25, m0$p, m0$corte), metricas(te$supera_25, m1$p, m1$corte))),
  data.table(clasificador = "Logística", modelo = c("M0", "M1"), rbind(metricas(te$supera_25, l0$p, l0$corte), metricas(te$supera_25, l1$p, l1$corte)))))
ic_principal <- rbind(data.table(clasificador = "LDA", b_lda$ic), data.table(clasificador = "Logística", b_log$ic))
escribir(tabla_principal, "metricas_lda_logistica.csv")
escribir(ic_principal, "ic_lda_logistica.csv")


# ---- Bloque 5. A1: variables relevantes de la logistica -------------------------------------------------------------
# Odds ratio por 1 DE = exp(coeficiente) sobre los predictores estandarizados. IC por bootstrap por bloques
# de 14 dias en el entrenamiento, repitiendo todo el ajuste (medias de PRS, estandarizacion y glm); con la
# misma semilla y los mismos bloques que la estabilidad del LDA en 09b, las replicas remuestrean los mismos
# bloques. Los valores p de Wald solo se guardan con su advertencia: la dependencia entre dias los invalida.
PRED <- colnames(l1$z_tr)
b1 <- coef(l1$modelo); stopifnot(identical(names(b1)[-1], make.names(PRED)))
b1 <- setNames(unname(b1[-1]), PRED)
p_wald <- setNames(unname(summary(l1$modelo)$coefficients[-1, 4]), PRED)
bloque_tr <- as.integer(entrena$fecha - INICIO_ENTRENA) %/% 14L
filas_tr <- split(seq_len(nrow(entrena)), bloque_tr)
set.seed(SEMILLA)
B1 <- t(vapply(seq_len(N_REPLICAS), function(i) {
  idx <- unlist(filas_tr[sample.int(length(filas_tr), length(filas_tr), replace = TRUE)], use.names = FALSE)
  e <- entrena[idx]
  r <- tryCatch({
    ab <- prs_anomalia(e, e[1:2])
    co <- coef(ajustar(ab$tr, ab$te, MET, metodo = "logistica")$modelo)[-1]
    if (length(co) != length(PRED) || anyNA(co)) rep(NA_real_, length(PRED)) else unname(co)
  }, error = function(err) rep(NA_real_, length(PRED)))
  r
}, numeric(length(PRED))))
B1 <- B1[stats::complete.cases(B1), , drop = FALSE]
estab_lda <- fread("output/etapa4/lda/estabilidad_coeficientes.csv")[match(PRED, predictor)]
a1 <- data.table(predictor = PRED, tipo = estab_lda$tipo, coef_logistica = b1, odds_ratio = exp(b1),
                 or_li = exp(apply(B1, 2, quantile, 0.025)), or_ls = exp(apply(B1, 2, quantile, 0.975)),
                 pct_mismo_signo = 100 * colMeans(sign(B1) == rep(sign(b1), each = nrow(B1))),
                 coef_lda = estab_lda$coef_estandarizado, pct_mismo_signo_lda = estab_lda$pct_mismo_signo_coef,
                 de_natural = unname(l1$desv[PRED]), replicas_validas = nrow(B1),
                 p_wald_convencional_NO_VALIDO_por_dependencia = p_wald)
a1[, `:=`(signo_estable = pct_mismo_signo >= 95, coincide_signo_lda = sign(coef_logistica) == sign(coef_lda),
          signo_estable_lda = pct_mismo_signo_lda >= 95)]
# Importancia por permutacion en la prueba: caida del AUC de M1 (logistica y LDA) al permutar las filas de
# un grupo de columnas (juntas) de la matriz estandarizada de la prueba; 200 permutaciones por grupo.
GRUPOS <- c(list(`Estación` = grep("^est", PRED, value = TRUE), Temporada = grep("^tem", PRED, value = TRUE),
                 `Viento (u, v y rapidez)` = c("viento_u", "viento_v", "viento_rapidez_ms")), setNames(as.list(MET), MET))
pred_log <- function(z) as.vector(plogis(coef(l1$modelo)[1] + z %*% b1))
pred_lda <- function(z) predict(m1$modelo, z)$posterior[, "1"]
stopifnot(max(abs(pred_log(l1$z_te) - l1$p)) < 1e-10, max(abs(pred_lda(m1$z_te) - m1$p)) < 1e-10)
y_te <- te$supera_25
perm <- rbindlist(lapply(names(GRUPOS), function(g) {
  rbindlist(lapply(list(Logística = list(f = pred_log, z = l1$z_te, p = l1$p), LDA = list(f = pred_lda, z = m1$z_te, p = m1$p)), function(m) {
    set.seed(SEMILLA)
    auc0 <- auc_rapido(y_te, m$p)
    caidas <- vapply(seq_len(N_PERMUTACIONES), function(k) {
      z <- m$z; z[, GRUPOS[[g]]] <- m$z[sample.int(nrow(z)), GRUPOS[[g]], drop = FALSE]
      auc0 - auc_rapido(y_te, m$f(z))
    }, numeric(1))
    data.table(grupo = g, caida_auc = mean(caidas), caida_li = quantile(caidas, 0.025, names = FALSE),
               caida_ls = quantile(caidas, 0.975, names = FALSE))
  }), idcol = "clasificador")
}))
a1 <- merge(a1, perm[clasificador == "Logística", .(predictor = grupo, caida_auc_permutacion = caida_auc)], by = "predictor", all.x = TRUE, sort = FALSE)
escribir(a1, "a1_odds_ratios_logistica.csv")
escribir(perm, "a1_importancia_permutacion.csv")
print(a1[tipo != "estación", .(predictor, OR = round(odds_ratio, 3), li = round(or_li, 3), ls = round(or_ls, 3),
                               signo = round(pct_mismo_signo, 1), lda = coincide_signo_lda, caida = round(caida_auc_permutacion, 4))])
print(perm)


# ---- Bloque 6. A2: linealidad en la escala logit (entrenamiento) y AUC con splines ---------------------------------
# (a) Logits empiricos ajustados: para cada continua, M1 logistico con esa variable en grupos (deciles; en la
#     lluvia, sin lluvia y cuartiles con lluvia) en lugar de lineal, con las demas variables lineales. El
#     coeficiente de cada grupo es su logit con los demas predictores en su media (0 al estandarizar). Se
#     alinea con la recta del modelo lineal (coeficiente x media del grupo) por su promedio ponderado: el
#     nivel no importa, solo la forma.
Z <- l1$z_tr; y_tr <- tr$supera_25
logit_grupos <- rbindlist(lapply(MET, function(j) {
  g <- grupos_logit(Z[, j] * l1$desv[[j]] + l1$medias[[j]], lluvia = j == "horas_lluvia")
  otros <- Z[, setdiff(PRED, j)]
  f <- glm(y_tr ~ 0 + g + otros, family = binomial)
  theta <- coef(f)[seq_len(nlevels(g))]
  zbar <- tapply(Z[, j], g, mean); n_g <- as.vector(table(g))
  recta <- b1[[j]] * zbar
  data.table(variable = j, grupo = levels(g), n = n_g, x_media = zbar * l1$desv[[j]] + l1$medias[[j]],
             logit_empirico = theta - weighted.mean(theta - recta, n_g), logit_recta = recta)
}))
logit_grupos[, desvio := logit_empirico - logit_recta]
# (b) GAM logistico (M1 con un spline penalizado por continua) en el entrenamiento: grados de libertad
#     efectivos (edf; 1 = recta) y funciones suavizadas con banda de +-2 errores estandar (bajo independencia,
#     por eso demasiado estrecha) frente al termino lineal de la logistica.
g_fin <- ajustar_gam(tr, te)
st <- summary(g_fin$modelo)$s.table
edf <- data.table(variable = MET, edf = st[sprintf("s(%s)", MET), "edf"],
                  p_aproximado_NO_VALIDO_por_dependencia = st[sprintf("s(%s)", MET), "p-value"])
curvas <- rbindlist(lapply(MET, function(j) {
  rango <- quantile(Z[, j], c(0.01, 0.99))
  rejilla <- as.data.frame(matrix(0, 100, length(PRED), dimnames = list(NULL, PRED)))
  rejilla[[j]] <- seq(rango[1], rango[2], length.out = 100)
  pr <- predict(g_fin$modelo, rejilla, type = "terms", se.fit = TRUE)
  k <- sprintf("s(%s)", j)
  data.table(variable = j, x = rejilla[[j]] * l1$desv[[j]] + l1$medias[[j]], f = pr$fit[, k], se = pr$se.fit[, k],
             lineal = b1[[j]] * rejilla[[j]])
}))
# (c) AUC de M1 lineal frente a M1 con splines y M1 + "llovio" en la prueba (los pliegues estan en el bloque 3).
l1_llov <- ajustar(tr, te, c(MET, "llovio_ind"), metodo = "logistica")
a2c <- rbind(pl_auc[, .(conjunto = pliegue, n = n_valida, auc_M1_lineal, auc_M1_splines, dif_splines, auc_M1_llovio, dif_llovio)],
             data.table(conjunto = "prueba", n = nrow(te), auc_M1_lineal = auc_m(y_te, l1$p), auc_M1_splines = auc_m(y_te, g_fin$p),
                        dif_splines = auc_m(y_te, g_fin$p) - auc_m(y_te, l1$p), auc_M1_llovio = auc_m(y_te, l1_llov$p),
                        dif_llovio = auc_m(y_te, l1_llov$p) - auc_m(y_te, l1$p)))
# Sensibilidad (se reporta como tal solo si se adopta la regla; se calcula siempre): dAUC de M1 con splines
# sobre M0 logistico, con el mismo bootstrap por bloques de la prueba.
b_gam <- bootstrap(te$fecha, y_te, l0$p, g_fin$p, l0$corte, g_fin$corte)
a2_sens <- data.table(modelo = c("M1 logístico lineal", "M1 logístico con splines (GAM)"),
                      auc_M0 = auc_m(y_te, l0$p), auc_M1 = c(auc_m(y_te, l1$p), auc_m(y_te, g_fin$p)),
                      d_auc = c(auc_m(y_te, l1$p), auc_m(y_te, g_fin$p)) - auc_m(y_te, l0$p),
                      d_auc_li = c(b_log$ic$d_auc_li, b_gam$ic$d_auc_li), d_auc_ls = c(b_log$ic$d_auc_ls, b_gam$ic$d_auc_ls),
                      adopta_splines = ADOPTA_SPLINES)
escribir(logit_grupos, "a2_logits_empiricos.csv")
escribir(edf, "a2_gam_edf.csv")
escribir(curvas, "a2_gam_curvas.csv")
escribir(a2c, "a2_auc_lineal_splines.csv")
escribir(a2_sens, "a2_dauc_splines_prueba.csv")
print(edf); print(a2c); print(a2_sens)


# ---- Bloque 7. B: persistencia -------------------------------------------------------------------------------------
# Submuestra con PM2.5 del dia anterior, en el entrenamiento y en la prueba. PRS ya es la anomalia con las
# medias del entrenamiento completo; cada modelo se reajusta en la submuestra (prior y corte = su prevalencia).
tr_p <- tr[!is.na(pm_ayer)]; te_p <- te[!is.na(pm_ayer)]
# Escala del PM2.5 del dia anterior en el entrenamiento completo: edf de un spline en MP logistico.
mp_gam <- mgcv::gam(supera_25 ~ factor(estacion) + factor(temporada) + s(pm_ayer), family = binomial, method = "REML", data = tr_p)
edf_lag <- summary(mp_gam)$s.table["s(pm_ayer)", "edf"]
MODELOS_P <- list(M0 = character(), M1 = MET, MP = LAG, MP1 = c(LAG, MET))
ajustes_p <- lapply(c(lda = "lda", logistica = "logistica"), function(me) lapply(MODELOS_P, function(v) ajustar(tr_p, te_p, v, metodo = me)))
b_tabla <- rbindlist(lapply(names(ajustes_p), function(me) {
  f <- ajustes_p[[me]]
  data.table(clasificador = me, modelo = names(f), auc = vapply(f, function(x) auc_m(te_p$supera_25, x$p), numeric(1)),
             exactitud_balanceada = vapply(f, function(x) metricas(te_p$supera_25, x$p, x$corte)[["exactitud_balanceada"]], numeric(1)),
             sensibilidad = vapply(f, function(x) metricas(te_p$supera_25, x$p, x$corte)[["sensibilidad"]], numeric(1)))
}))
PARES <- list(c("MP", "M1"), c("MP", "MP1"), c("M0", "M1"), c("M0", "MP"), c("M1", "MP1"))
b_dif <- rbindlist(lapply(names(ajustes_p), function(me) rbindlist(lapply(PARES, function(pr) {
  fa <- ajustes_p[[me]][[pr[1]]]; fb <- ajustes_p[[me]][[pr[2]]]
  bb <- bootstrap(te_p$fecha, te_p$supera_25, fa$p, fb$p, fa$corte, fb$corte)
  data.table(clasificador = me, comparacion = sprintf("%s − %s", pr[2], pr[1]),
             d_auc = auc_m(te_p$supera_25, fb$p) - auc_m(te_p$supera_25, fa$p), d_auc_li = bb$ic$d_auc_li, d_auc_ls = bb$ic$d_auc_ls)
}))))
b_muestra <- data.table(parte = c("entrenamiento", "prueba"), n_total = c(nrow(tr), nrow(te)), n_con_persistencia = c(nrow(tr_p), nrow(te_p)),
                        pct_superacion_total = 100 * c(mean(tr$supera_25), mean(te$supera_25)),
                        pct_superacion_con_persistencia = 100 * c(mean(tr_p$supera_25), mean(te_p$supera_25)),
                        escala = if (USA_LOG) "log" else "original", edf_spline_entrenamiento = edf_lag,
                        cor_spearman_pm_ayer_pm = c(cor(tr_p$pm_ayer, tr_p$`PM2.5`, method = "spearman"),
                                                    cor(te_p$pm_ayer, te_p$`PM2.5`, method = "spearman")))
escribir(b_tabla, "b_persistencia_auc.csv"); escribir(b_dif, "b_persistencia_dauc.csv"); escribir(b_muestra, "b_persistencia_muestra.csv")
print(b_muestra); print(b_tabla); print(b_dif)


# ---- Bloque 8. C: umbral de clasificacion ------------------------------------------------------------------------------
# C3: los cortes elegidos con los pliegues (bloque 3), aplicados al M1 del analisis final en la prueba.
# C4: metricas en la prueba para cortes de 0.10 a 0.60 (descriptivo).
p_final <- list(lda = m1$p, logistica = l1$p)
c3 <- rbindlist(lapply(seq_len(nrow(cortes)), function(i) {
  cbind(cortes[i, .(clasificador, objetivo)], metricas_corte(y_te, p_final[[cortes$clasificador[i]]], cortes$corte[i]))
}))
REJILLA <- round(seq(0.10, 0.60, by = 0.05), 2)
c4 <- rbindlist(lapply(names(p_final), function(k) rbindlist(lapply(REJILLA, function(ct) metricas_corte(y_te, p_final[[k]], ct)))[, clasificador := k]))
escribir(c3, "c_cortes_en_prueba.csv"); escribir(c4, "c_metricas_por_corte.csv")
print(c3)


# ---- Bloque 9. D: bootstrap estratificado por temporada -----------------------------------------------------------------
# Temporada de cada bloque de 14 dias: la de la mayoria de sus dias de calendario (en la prueba no hay empates:
# ningun cambio de temporada cae a la mitad de un bloque).
mes_temp <- function(f) { m <- as.integer(format(f, "%m")); fifelse(m %in% 3:5, "seca_calida", fifelse(m %in% 6:10, "calida_humeda", "seca_fria")) }
cal <- data.table(fecha = seq(INICIO_BLOQUES, FIN_PRUEBA, by = "day"))[, `:=`(bloque = as.integer(fecha - INICIO_BLOQUES) %/% 14L, temporada = mes_temp(fecha))]
stopifnot(identical(cal[match(te$fecha, fecha), temporada], te$temporada))
temp_bloque <- cal[, .N, by = .(bloque, temporada)][order(bloque, -N)]
empates <- temp_bloque[, .(empate = sum(N == max(N)) > 1), by = bloque][, sum(empate)]
temp_bloque <- temp_bloque[, .SD[1], by = bloque]
TEMP_BLOQUE <- setNames(temp_bloque$temporada, temp_bloque$bloque)
d_est <- rbindlist(lapply(list(LDA = list(a = m0$p, b = m1$p, actual = b_lda$ic), `Logística` = list(a = l0$p, b = l1$p, actual = b_log$ic)), function(m) {
  be <- bootstrap_estratificado(te$fecha, y_te, m$a, m$b, TEMP_BLOQUE)
  data.table(d_auc = auc_m(y_te, m$b) - auc_m(y_te, m$a), ic_actual_li = m$actual$d_auc_li, ic_actual_ls = m$actual$d_auc_ls,
             ic_estratificado_li = be$ic[["li"]], ic_estratificado_ls = be$ic[["ls"]],
             bloques = paste(sprintf("%s: %d", names(be$bloques_por_temporada), be$bloques_por_temporada), collapse = "; "),
             empates_asignados = empates)
}), idcol = "clasificador")
escribir(d_est, "d_bootstrap_estratificado.csv")
print(d_est)


# ---- Bloque 10. E: episodios frente a dias-estacion -----------------------------------------------------------------------
# Episodio = racha de dias-estacion consecutivos de la prueba con supera_25 = 1; un dia fuera de la muestra
# corta la racha. Deteccion con el corte actual: al menos un dia de la racha clasificado como superacion, y
# el primer dia clasificado como superacion. Lo mismo para las rachas con PM2.5 > 40.
pe <- te[, .(estacion, fecha, temporada, `PM2.5`, supera_25, p_M0 = m0$p, p_M1 = m1$p, p_L1 = l1$p)]
resumen_rachas <- function(x, nombre) {
  ep <- x[!is.na(episodio), .(dias = .N, estacion = estacion[1], inicio = min(fecha), temporada = temporada[1],
                              M0_alguno = any(p_M0 >= CORTE_ACTUAL), M1_alguno = any(p_M1 >= CORTE_ACTUAL), L1_alguno = any(p_L1 >= CORTE_ACTUAL),
                              M0_primero = p_M0[1] >= CORTE_ACTUAL, M1_primero = p_M1[1] >= CORTE_ACTUAL, L1_primero = p_L1[1] >= CORTE_ACTUAL),
             by = episodio]
  list(episodios = ep[, tipo := nombre],
       resumen = data.table(tipo = nombre, dias_estacion = sum(ep$dias), episodios = nrow(ep), duracion_mediana = median(ep$dias),
                            duracion_media = mean(ep$dias), duracion_maxima = max(ep$dias), pct_un_dia = 100 * mean(ep$dias == 1),
                            pct_dias_en_episodios_de_3_o_mas = 100 * sum(ep$dias[ep$dias >= 3]) / sum(ep$dias),
                            pct_detectados_M0 = 100 * mean(ep$M0_alguno), pct_detectados_M1 = 100 * mean(ep$M1_alguno),
                            pct_detectados_L1 = 100 * mean(ep$L1_alguno),
                            pct_primer_dia_M0 = 100 * mean(ep$M0_primero), pct_primer_dia_M1 = 100 * mean(ep$M1_primero),
                            pct_primer_dia_L1 = 100 * mean(ep$L1_primero),
                            pct_dias_detectados_M0 = 100 * mean(x[!is.na(episodio), p_M0 >= CORTE_ACTUAL]),
                            pct_dias_detectados_M1 = 100 * mean(x[!is.na(episodio), p_M1 >= CORTE_ACTUAL])))
}
e25 <- resumen_rachas(rachas(pe, pe$supera_25 == 1L), "PM2.5 > 25")
e40 <- resumen_rachas(rachas(pe, pe$`PM2.5` > 40), "PM2.5 > 40")
e_res <- rbind(e25$resumen, e40$resumen)
e_dur <- rbind(e25$episodios, e40$episodios)[, .N, by = .(tipo, dias = pmin(dias, 8L))][order(tipo, dias)]
escribir(e_res, "e_episodios_resumen.csv"); escribir(rbind(e25$episodios, e40$episodios), "e_episodios.csv"); escribir(e_dur, "e_duracion.csv")
print(e_res)


# ---- Bloque 11. F: exclusiones y posible sesgo --------------------------------------------------------------------------------
# F1: causa de cada estacion-dia. Las causas (a)-(d) son excluyentes y suman los 23 738; (e) es un subconjunto
#     de (b) y (c) (dias previos a una reubicacion, fuera solo del entrenamiento).
f <- copy(todo)
f[, causa := fifelse(respuesta_valida == 0L, "a",
             fifelse(met_completa == 1L, "b", fifelse(met_completa_tras_imputar == 1L, "c", "d")))]
stopifnot(!anyNA(f$causa), f[met_completa == 1L, all(met_completa_tras_imputar == 1L)])
f[, previo_reubicacion := causa %in% c("b", "c") & sitio_valido == 0L]
CAUSAS <- c(a = "(a) Sin PM2.5 suficiente (< 18 h observadas)", b = "(b) PM2.5 y meteorología completa",
            c = "(c) PM2.5 y 1–4 meteorológicas imputadas (incluidos)", d = "(d) PM2.5 y 5–8 meteorológicas faltantes (excluidos)",
            e = "(e) De (b) o (c), previos a una reubicación (fuera del entrenamiento)")
f1_total <- rbind(f[, .N, by = causa], data.table(causa = "e", N = sum(f$previo_reubicacion)))[, `:=`(pct = 100 * N / nrow(f), descripcion = CAUSAS[causa])][order(causa)]
cruce <- function(by) {
  x <- f[, .(a = sum(causa == "a"), b = sum(causa == "b"), c = sum(causa == "c"), d = sum(causa == "d"), e = sum(previo_reubicacion), total = .N), by = by]
  x[, `:=`(pct_a = 100 * a / total, pct_c = 100 * c / total, pct_d = 100 * d / total, pct_e = 100 * e / total)]
  setnames(x, by, "grupo")[, dimension := by]
}
f1_cruces <- rbind(cruce("estacion"), cruce("temporada"), cruce("anio")[, grupo := as.character(grupo)])
# F2: respuesta en (c), (d) y (e) frente a (b), donde existe: % superacion, mediana de PM2.5 y % > 40.
f_resp <- rbind(f[causa %in% c("b", "c", "d")][, grupo := causa], f[previo_reubicacion == TRUE][, grupo := "e"])
resp <- function(by = character()) f_resp[, .(n = .N, pct_superacion = 100 * mean(supera_25), mediana_pm25 = median(`PM2.5`),
                                             pct_mayor_40 = 100 * mean(`PM2.5` > 40)), by = c("grupo", by)]
f2_total <- resp()[order(grupo)]
f2_estacion <- dcast(resp("estacion"), estacion ~ grupo, value.var = c("n", "pct_superacion"))
f2_temporada <- resp("temporada")[order(temporada, grupo)]
etapas <- fread("output/etapa4/dias_superacion_por_estacion.csv")[, .(estacion, dias_v12, pct_superacion_v12, dias_v2, pct_superacion_v2)]
# F3: los dias (a): donde y cuando, rachas de dias consecutivos sin respuesta y PM10 de esos dias (base diaria
#     de la etapa 1, >= 18 h validas) frente al PM10 de los dias con respuesta de la misma estacion.
pm10 <- fread("data/clean/sima_diario_2020_2025.csv", select = c("estacion", "fecha", "PM10"))[, fecha := as.Date(fecha)]
f <- merge(f, pm10, by = c("estacion", "fecha"), all.x = TRUE)
fa <- rachas(f[, .(estacion, fecha, causa)], f$causa == "a")[!is.na(episodio)][, .(dias = .N, estacion = estacion[1], inicio = min(fecha)), by = episodio]
f3_rachas <- data.table(dias_a = sum(fa$dias), rachas = nrow(fa), racha_mediana = median(fa$dias), racha_maxima = max(fa$dias),
                        pct_dias_en_rachas_mayores_7 = 100 * sum(fa$dias[fa$dias > 7]) / sum(fa$dias),
                        pct_dias_en_rachas_mayores_30 = 100 * sum(fa$dias[fa$dias > 30]) / sum(fa$dias))
f3_pm10 <- f[, .(dias_a = sum(causa == "a"), pct_a_con_pm10 = 100 * mean(!is.na(PM10[causa == "a"])),
                 pm10_mediana_a = median(PM10[causa == "a"], na.rm = TRUE), pm10_mediana_con_respuesta = median(PM10[causa != "a"], na.rm = TRUE)),
             by = estacion][order(-dias_a)]
f3_pm10 <- rbind(f3_pm10, f[, .(estacion = "Total", dias_a = sum(causa == "a"), pct_a_con_pm10 = 100 * mean(!is.na(PM10[causa == "a"])),
                                pm10_mediana_a = median(PM10[causa == "a"], na.rm = TRUE), pm10_mediana_con_respuesta = median(PM10[causa != "a"], na.rm = TRUE))])
f3_rachas_largas <- fa[order(-dias)][1:10]
# PM10 dentro de cada estacion y temporada: mediana en los dias (a) frente a los dias con respuesta.
f3_et <- dcast(f[!is.na(PM10), .(mediana = median(PM10), n = .N), by = .(estacion, temporada, grupo = fifelse(causa == "a", "sin_respuesta", "con_respuesta"))],
               estacion + temporada ~ grupo, value.var = c("mediana", "n"))
f3_et[, diferencia := mediana_sin_respuesta - mediana_con_respuesta]
f3_et_resumen <- f3_et[!is.na(diferencia), .(combinaciones = .N, con_pm10_menor_en_a = sum(diferencia < 0), mediana_diferencia = median(diferencia))]
f3_anio <- f[, .(dias_a = sum(causa == "a"), pct_a = 100 * mean(causa == "a")), by = anio]
escribir(f1_total, "f1_causas_total.csv"); escribir(f1_cruces, "f1_causas_por_estacion_temporada_anio.csv")
escribir(f2_total, "f2_respuesta_por_grupo.csv"); escribir(f2_estacion, "f2_respuesta_por_estacion.csv"); escribir(f2_temporada, "f2_respuesta_por_temporada.csv")
escribir(etapas, "f2_superacion_etapa3_etapa4.csv")
escribir(f3_rachas, "f3_rachas_sin_respuesta.csv"); escribir(f3_pm10, "f3_pm10_dias_sin_respuesta.csv"); escribir(f3_rachas_largas, "f3_rachas_mas_largas.csv")
escribir(f3_et, "f3_pm10_por_estacion_temporada.csv"); escribir(f3_et_resumen, "f3_pm10_resumen_estacion_temporada.csv")
print(f1_total); print(f2_total); print(f3_rachas); print(f3_pm10)


# ---- Bloque 12. Figuras para el informe ------------------------------------------------------------------------------------
# 1. Coeficientes de la meteorologia y la temporada: LDA (de 09b) y logistica (A1), con IC por bootstrap por
#    bloques en el entrenamiento; en color los de signo estable. La etiqueta de la logistica es el odds ratio.
NOM_FIG <- c(NOMBRES, temseca_fria = "Temporada seca-fría", temseca_calida = "Temporada seca-cálida")
fc <- rbind(estab_lda[tipo != "estación", .(predictor, panel = "(a) LDA: coeficiente estandarizado", valor = coef_estandarizado,
                                            li = coef_li, ls = coef_ls, estable = pct_mismo_signo_coef >= 95, etiqueta = "")],
            a1[tipo != "estación", .(predictor, panel = "(b) Logística: log(odds ratio) por 1 DE", valor = coef_logistica,
                                     li = log(or_li), ls = log(or_ls), estable = signo_estable, etiqueta = sprintf("OR %.2f", odds_ratio))])
orden <- estab_lda[tipo != "estación"][order(coef_estandarizado), predictor]
fc[, var := factor(NOM_FIG[predictor], levels = NOM_FIG[orden])]
fc[, x_etiqueta := max(ls) + 0.08, by = panel]                 # columna de etiquetas a la derecha del panel
g <- ggplot(fc, aes(valor, var, colour = estable)) +
  geom_vline(xintercept = 0, colour = "grey50") + geom_pointrange(aes(xmin = li, xmax = ls), size = 0.3) +
  geom_text(aes(x = x_etiqueta, label = etiqueta), hjust = 0, size = 2.6, colour = "grey25") +
  facet_wrap(~panel, scales = "free_x") + scale_x_continuous(expand = expansion(mult = c(0.05, 0.28))) +
  scale_colour_manual(values = c(`TRUE` = "#D55E00", `FALSE` = "grey60"),
                      labels = c(`TRUE` = "signo estable (≥ 95 % de las réplicas)", `FALSE` = "signo no estable"), name = NULL) +
  labs(x = "Coeficiente e IC 95 % (bootstrap por bloques de 14 días en el entrenamiento)", y = NULL) +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), strip.text = element_text(hjust = 0))
guardar(g, "coef_lda_logistica_informe.png", 6.5, 3.3)
# 2. Linealidad en la escala logit: funcion del GAM con banda de +-2 EE, termino lineal de la logistica y
#    logits empiricos por grupo (centrados).
etq <- setNames(sprintf("%s (%s)", NOMBRES, UNIDADES), MET)
cv <- copy(curvas)[, panel := factor(etq[variable], levels = etq)]
lg <- copy(logit_grupos)[, panel := factor(etq[variable], levels = etq)]
g <- ggplot(cv, aes(x)) +
  geom_ribbon(aes(ymin = f - 2 * se, ymax = f + 2 * se), fill = "grey85") +
  geom_line(aes(y = f, linetype = "GAM (spline penalizado)"), colour = "black", linewidth = 0.5) +
  geom_line(aes(y = lineal, linetype = "Logística lineal"), colour = "#D55E00", linewidth = 0.6) +
  geom_point(data = lg, aes(x_media, logit_empirico, shape = "Logit empírico por grupo"), colour = "#0072B2", size = 1.2) +
  facet_wrap(~panel, nrow = 2, scales = "free") +
  scale_linetype_manual(values = c(`GAM (spline penalizado)` = "solid", `Logística lineal` = "dashed"), name = NULL) +
  scale_shape_manual(values = c(`Logit empírico por grupo` = 16), name = NULL) +
  labs(x = NULL, y = "Efecto en la escala logit") +
  theme_minimal(base_size = 8) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), strip.text = element_text(size = 7))
guardar(g, "linealidad_logit_informe.png", 6.5, 3.9)
# 3. Metricas en la prueba segun el corte (C4), con los tres cortes elegidos con los pliegues.
NOM_CLAS <- c(lda = "LDA", logistica = "Logística")
c4l <- melt(c4, id.vars = c("clasificador", "corte"), measure.vars = c("sensibilidad", "especificidad", "vpp"), variable.name = "metrica")
c4l[, metrica := factor(c(sensibilidad = "Sensibilidad", especificidad = "Especificidad", vpp = "Valor predictivo positivo")[as.character(metrica)],
                        levels = c("Sensibilidad", "Especificidad", "Valor predictivo positivo"))]
c4l[, clas := NOM_CLAS[clasificador]]
cv3 <- copy(cortes)[, `:=`(clas = NOM_CLAS[clasificador],
                          obj = factor(c(vigilancia = "Vigilancia (sensibilidad ≥ 0.80)", equilibrio = "Equilibrio (Youden)", actual = "Actual (prevalencia)")[objetivo],
                                       levels = c("Vigilancia (sensibilidad ≥ 0.80)", "Equilibrio (Youden)", "Actual (prevalencia)")))]
g <- ggplot(c4l, aes(corte, value, colour = metrica)) +
  geom_vline(data = cv3, aes(xintercept = corte, linetype = obj), colour = "grey40") +
  geom_line(linewidth = 0.6) + geom_point(size = 1) + facet_wrap(~clas) +
  scale_colour_manual(values = c("#D55E00", "#0072B2", "#009E73"), name = NULL) +
  scale_linetype_manual(values = c("dotted", "dashed", "solid"), name = NULL) +
  scale_x_continuous(breaks = seq(0.1, 0.6, 0.1)) + scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Corte de probabilidad", y = NULL) +
  guides(colour = guide_legend(nrow = 1, order = 1), linetype = guide_legend(nrow = 1, order = 2)) +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom", legend.box = "vertical", legend.spacing.y = unit(0, "pt"),
                                       panel.grid.minor = element_blank())
guardar(g, "metricas_por_corte_informe.png", 6.5, 3.0)


# ---- Bloque 13. RESUMEN.md ----------------------------------------------------------------------------------------------------
f3_ <- function(x) ifelse(is.na(x), "—", sprintf("%.3f", x))
f1_ <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))
fi <- function(x) format(x, big.mark = " ")
ic_ <- function(li, ls) sprintf("[%.3f, %.3f]", li, ls)
tabla_md <- function(dt) c(paste0("| ", paste(names(dt), collapse = " | "), " |"),
                          paste0("|", paste(rep("---", ncol(dt)), collapse = "|"), "|"),
                          apply(dt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
t_a1 <- a1[predictor %in% MET][match(MET, predictor), .(Variable = NOMBRES[predictor], `1 DE` = sprintf("%.2f %s", de_natural, UNIDADES[predictor]),
                                                        `OR por 1 DE [IC 95 %]` = sprintf("%.2f [%.2f, %.2f]", odds_ratio, or_li, or_ls),
                                                        `% mismo signo` = f1_(pct_mismo_signo), `Signo estable` = fifelse(signo_estable, "sí", "no"),
                                                        `Coincide con el LDA` = fifelse(coincide_signo_lda, "sí", "no"),
                                                        `Caída del AUC (permutación)` = sprintf("%.4f", caida_auc_permutacion))]
t_perm <- perm[, .(Grupo = fifelse(grupo %in% MET, NOMBRES[grupo], grupo), Clasificador = clasificador, `Caída del AUC` = sprintf("%.4f", caida_auc),
                   `Rango 95 % de las permutaciones` = sprintf("[%.4f, %.4f]", caida_li, caida_ls))]
t_edf <- edf[, .(Variable = NOMBRES[variable], edf = sprintf("%.2f", edf))]
t_a2c <- a2c[, .(Conjunto = conjunto, n = fi(n), `AUC M1 lineal` = f3_(auc_M1_lineal), `AUC M1 splines` = f3_(auc_M1_splines),
                 `Splines − lineal` = sprintf("%+.4f", dif_splines), `AUC M1 + llovió` = f3_(auc_M1_llovio), `Llovió − lineal` = sprintf("%+.4f", dif_llovio))]
t_b <- dcast(b_tabla, modelo ~ clasificador, value.var = "auc")[match(names(MODELOS_P), modelo)]
t_b <- t_b[, .(Modelo = modelo, `AUC LDA` = f3_(lda), `AUC logística` = f3_(logistica))]
t_bd <- dcast(b_dif[, .(clasificador, comparacion, v = paste(f3_(d_auc), ic_(d_auc_li, d_auc_ls)))], comparacion ~ clasificador, value.var = "v")
setnames(t_bd, c("Comparación", "LDA", "Logística"))
t_c3 <- c3[, .(Clasificador = NOM_CLAS[clasificador], Objetivo = objetivo, Corte = f3_(corte), Sensibilidad = f3_(sensibilidad),
               Especificidad = f3_(especificidad), VPP = f3_(vpp), `Falsas alarmas por detección` = sprintf("%.2f", falsas_por_detectada),
               `Exactitud balanceada` = f3_(exactitud_balanceada), `% días marcados` = f1_(pct_marcados))]
t_cp <- cortes_pliegues[, .(Clasificador = NOM_CLAS[clasificador], Objetivo = objetivo, Corte = f3_(corte), Sensibilidad = f3_(sensibilidad),
                            Especificidad = f3_(especificidad), VPP = f3_(vpp), `Exactitud balanceada` = f3_(exactitud_balanceada))]
t_c4 <- dcast(c4[, .(clasificador, corte, v = sprintf("%.2f / %.2f / %.2f", sensibilidad, especificidad, vpp))], corte ~ clasificador, value.var = "v")
setnames(t_c4, c("Corte", "LDA (sens. / espec. / VPP)", "Logística (sens. / espec. / VPP)"))
t_d <- d_est[, .(Clasificador = clasificador, `ΔAUC` = f3_(d_auc), `IC actual (bloques de 14 días)` = ic_(ic_actual_li, ic_actual_ls),
                 `IC estratificado por temporada` = ic_(ic_estratificado_li, ic_estratificado_ls), `Bloques por temporada` = bloques)]
t_e <- e_res[, .(Rachas = tipo, `Días-estación` = fi(dias_estacion), Episodios = fi(episodios), `Duración mediana` = f1_(duracion_mediana),
                 `Duración máxima` = fi(duracion_maxima), `% de un día` = f1_(pct_un_dia),
                 `% detectados M0 / M1` = sprintf("%.1f / %.1f", pct_detectados_M0, pct_detectados_M1),
                 `% primer día M0 / M1` = sprintf("%.1f / %.1f", pct_primer_dia_M0, pct_primer_dia_M1))]
t_f1 <- f1_total[, .(Causa = descripcion, `Estación-días` = fi(N), `%` = f1_(pct))]
t_f2 <- f2_total[, .(Grupo = CAUSAS[grupo], n = fi(n), `% superación` = f1_(pct_superacion), `Mediana PM2.5` = f1_(mediana_pm25), `% PM2.5 > 40` = f1_(pct_mayor_40))]
t_f2t <- f2_temporada[, .(Temporada = temporada, Grupo = grupo, n = fi(n), `% superación` = f1_(pct_superacion), `Mediana PM2.5` = f1_(mediana_pm25), `% > 40` = f1_(pct_mayor_40))]
t_f2e <- copy(f2_estacion)
for (k in grep("^pct", names(t_f2e), value = TRUE)) set(t_f2e, j = k, value = f1_(t_f2e[[k]]))
t_f3 <- f3_pm10[, .(Estación = estacion, `Días (a)` = fi(dias_a), `% con PM10` = f1_(pct_a_con_pm10), `PM10 mediana (a)` = f1_(pm10_mediana_a),
                    `PM10 mediana (con respuesta)` = f1_(pm10_mediana_con_respuesta))]
lineas <- c(
  "# Etapa 4 · Fase F: análisis posteriores a la retroalimentación final",
  "",
  sprintf("Generado por `scripts/10_analisis_retro_final.R` el %s. **Todo es posterior a la evaluación de la prueba (09a)**; no cambia el modelo principal (LDA: ΔAUC %s %s; logística: %s %s). Reglas en `docs/etapa4/decisiones_etapa4.md` (fase F). Bootstrap por bloques de 14 días, %d réplicas, semilla %d.",
          format(Sys.time(), "%Y-%m-%d %H:%M"), f3_(auc_m(y_te, m1$p) - auc_m(y_te, m0$p)), ic_(b_lda$ic$d_auc_li, b_lda$ic$d_auc_ls),
          f3_(auc_m(y_te, l1$p) - auc_m(y_te, l0$p)), ic_(b_log$ic$d_auc_li, b_log$ic$d_auc_ls), N_REPLICAS, SEMILLA),
  "", "## Decisiones tomadas con el entrenamiento (antes de la prueba)", "", tabla_md(decisiones), "",
  "## A1. Regresión logística: variables relevantes", "",
  sprintf("M1 logístico con los 22 predictores estandarizados del LDA; IC por bootstrap por bloques de 14 días en el entrenamiento (%d réplicas válidas). Importancia: caída media del AUC en la prueba al permutar la variable (%d permutaciones). Sin valores p (la dependencia los invalida).", nrow(B1), N_PERMUTACIONES),
  "", tabla_md(t_a1), "", "**Importancia por permutación (todos los grupos):**", "", tabla_md(t_perm), "",
  "## A2. Linealidad en la escala logit", "", "**Grados de libertad efectivos del GAM (entrenamiento; 1 = recta):**", "", tabla_md(t_edf), "",
  "**A2c. AUC de M1 logístico lineal, con splines y con «llovió»:**", "", tabla_md(t_a2c), "",
  sprintf("Regla: splines si suben el AUC de validación ≥ %.3f en los dos pliegues → **%s**.", MEJORA_MINIMA_SPLINES, if (ADOPTA_SPLINES) "se adoptan como tratamiento" else "no se adoptan; la forma lineal es una aproximación adecuada para clasificar"),
  sprintf("ΔAUC en la prueba de M1 con splines sobre M0 logístico: %s %s (lineal: %s %s).", f3_(a2_sens$d_auc[2]), ic_(a2_sens$d_auc_li[2], a2_sens$d_auc_ls[2]),
          f3_(a2_sens$d_auc[1]), ic_(a2_sens$d_auc_li[1], a2_sens$d_auc_ls[1])), "",
  "## B. Persistencia (PM2.5 del día anterior)", "", tabla_md(b_muestra[, .(parte, n_total, n_con_persistencia, pct_superacion_total = f1_(pct_superacion_total),
                                                                                pct_superacion_con_persistencia = f1_(pct_superacion_con_persistencia), escala,
                                                                                edf_spline_entrenamiento = sprintf("%.2f", edf_spline_entrenamiento),
                                                                                cor_spearman_pm_ayer_pm = sprintf("%.2f", cor_spearman_pm_ayer_pm))]), "",
  "**AUC en la prueba (submuestra con persistencia):**", "", tabla_md(t_b), "", "**Diferencias de AUC con IC 95 %:**", "", tabla_md(t_bd), "",
  "El PM2.5 del día anterior estaría disponible antes del día evaluado; la meteorología observada del mismo día no. La comparación es retrospectiva y no es una prueba de pronóstico.", "",
  "## C. Umbral de clasificación", "", "**Cortes elegidos con los pliegues (2022 y 2023) y su desempeño en esos pliegues:**", "", tabla_md(t_cp), "",
  "**C3. Los mismos cortes en la prueba (M1 del análisis final):**", "", tabla_md(t_c3), "",
  "**C4. Métricas en la prueba según el corte (sensibilidad / especificidad / VPP):**", "", tabla_md(t_c4), "",
  "Las probabilidades no están calibradas (pendiente de recalibración 0.82); los cortes se eligieron sin usar la prueba.", "",
  "## D. Bootstrap estratificado por temporada", "", tabla_md(t_d), "",
  "## E. Episodios frente a días-estación (prueba, corte actual)", "", tabla_md(t_e), "",
  "## F. Exclusiones y posible sesgo", "", "**F1. Causas (las causas (a)–(d) suman 23 738; (e) es parte de (b) y (c)):**", "", tabla_md(t_f1), "",
  "**F2. Respuesta por grupo:**", "", tabla_md(t_f2), "", "**F2 por temporada:**", "", tabla_md(t_f2t), "", "**F2 por estación (n y % de superación):**", "", tabla_md(t_f2e), "",
  "**Etapa 3 → etapa 4 (% de superación por estación):**", "", tabla_md(etapas[, .(estacion, dias_v12, pct_v12 = f1_(pct_superacion_v12), dias_v2, pct_v2 = f1_(pct_superacion_v2))]), "",
  "**F3. Días sin PM2.5 suficiente (a):**", "", tabla_md(f3_rachas[, lapply(.SD, function(x) if (is.numeric(x)) f1_(x) else x)]), "", tabla_md(t_f3), "",
  sprintf("Dentro de cada estación y temporada, la mediana del PM10 de los días (a) es menor que la de los días con respuesta en %d de %d combinaciones (mediana de la diferencia: %.1f µg/m³).",
          f3_et_resumen$con_pm10_menor_en_a, f3_et_resumen$combinaciones, f3_et_resumen$mediana_diferencia), "",
  "**Días (a) por año:**", "", tabla_md(f3_anio[order(anio), .(Año = anio, `Días (a)` = fi(dias_a), `%` = f1_(pct_a))]), "",
  "## Figuras", "", "`coef_lda_logistica_informe.png`, `linealidad_logit_informe.png`, `metricas_por_corte_informe.png`.")
con <- file(file.path(SALIDA, "RESUMEN.md"), "w", encoding = "UTF-8"); writeLines(lineas, con); close(con)
message("Listo: ", SALIDA)
