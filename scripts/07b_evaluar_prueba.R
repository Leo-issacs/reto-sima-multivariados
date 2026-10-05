# =============================================================================================
# Etapa 3, fase B: evaluacion UNICA de la prueba (2024-2025).
#
# Solo se corre despues del commit que cierra las decisiones ("Cierra decisiones de la etapa 3
# antes de evaluar la prueba"). Las decisiones (D16, D17, metricas, sensibilidades) estan en
# docs/etapa2/protocolo.md (v4) y docs/etapa3/decisiones_etapa3.md: aqui NO se cambia ninguna.
#
# Modo ensayo (para revisar el codigo sin mirar la prueba):
#   ENSAYO=1 Rscript scripts/07b_evaluar_prueba.R
#   entrena con 2021-2022, "prueba" con 2023 y escribe en output/etapa3/ensayo/. No lee 2024-2025.
# Corrida oficial:
#   Rscript scripts/07b_evaluar_prueba.R
#   Si ya existe output/etapa3/registro_prueba.txt, exige MOTIVO_RECORRIDA="..." (solo para
#   corregir errores de codigo; el motivo queda en el registro).
#
# Como usarlo en RStudio: corre los bloques en orden. Cada uno explica que hace y por que.
# =============================================================================================


# ---- Bloque 0. Paquetes, modo y carpetas ------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
})
ENSAYO <- Sys.getenv("ENSAYO") == "1"
SALIDA <- if (ENSAYO) "output/etapa3/ensayo" else "output/etapa3"
FIGURAS <- file.path(SALIDA, "figuras")
dir.create(FIGURAS, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))
ANIOS_ENTRENA <- if (ENSAYO) 2021:2022 else 2021:2023
ANIOS_PRUEBA <- if (ENSAYO) 2023 else 2024:2025
INICIO_BLOQUES <- as.Date(if (ENSAYO) "2023-01-01" else "2024-01-01")
N_REPLICAS <- 1000L
SEMILLA <- 2026L


# ---- Bloque 1. Registro de la evaluacion (antes de mirar nada) --------------------------------
# Lo primero es dejar constancia de cuando se abrio la prueba y desde que commit de
# decisiones. Si el registro ya existe, una nueva corrida solo se permite para corregir un
# error de codigo, y el motivo se anexa.
git <- function(...) system2("git", c("-c", paste0("safe.directory=", normalizePath(getwd(), winslash = "/")), ...),
                             stdout = TRUE, stderr = FALSE)
hash_fase_a <- git("log", shQuote("--grep=Cierra decisiones de la etapa 3 antes de evaluar la prueba", type = "cmd"), "--format=%H", "-n", "1")
hash_actual <- git("rev-parse", "HEAD")
if (!length(hash_fase_a) || !nzchar(hash_fase_a)) stop("No encuentro el commit que cierra las decisiones (fase A).", call. = FALSE)
if (!ENSAYO) {
  registro <- "output/etapa3/registro_prueba.txt"
  motivo <- Sys.getenv("MOTIVO_RECORRIDA")
  if (file.exists(registro) && !nzchar(motivo))
    stop("La prueba ya se evaluo. Para volver a correr (solo por un error de codigo) define MOTIVO_RECORRIDA.", call. = FALSE)
  entrada <- c(
    if (!file.exists(registro)) c("# Registro de la evaluacion de la prueba (2024-2025)", "",
                                  paste("Commit que cierra las decisiones (fase A):", hash_fase_a), ""),
    paste0("## Corrida del ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("Commit de decisiones (fase A):", hash_fase_a),
    paste("Commit del codigo al correr:", hash_actual),
    if (nzchar(motivo)) paste("Motivo de la nueva corrida:", motivo) else "Primera (y unica prevista) evaluacion de la prueba.",
    "")
  cat(entrada, file = registro, sep = "\n", append = TRUE)
}


# ---- Bloque 2. Datos -------------------------------------------------------------------------
# Muestra del protocolo (15 390 estacion-dias). En modo ensayo se descartan 2024-2025 al leer.
muestra <- fread("data/clean/muestra_pm25_2021_2025.csv")[anio %in% c(ANIOS_ENTRENA, ANIOS_PRUEBA)]
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
muestra[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
muestra[, fecha := as.Date(fecha)]
ESTACIONES <- sort(unique(muestra$estacion))
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")
entrena <- muestra[anio %in% ANIOS_ENTRENA]
prueba <- muestra[anio %in% ANIOS_PRUEBA]
if (ENSAYO && any(muestra$anio >= 2024)) stop("El ensayo no debe leer 2024-2025.", call. = FALSE)
cat(sprintf("Entrenamiento: %d estacion-dias (%s). Prueba: %d (%s).\n", nrow(entrena),
            paste(range(ANIOS_ENTRENA), collapse = "-"), nrow(prueba), paste(range(ANIOS_PRUEBA), collapse = "-")))


# ---- Bloque 3. Funciones del modelo ---------------------------------------------------------------
# prs_anomalia(): D17. Resta a PRS la media de su estacion calculada SOLO con el entrenamiento,
#   y usa esas mismas medias en la prueba (sin fuga de informacion).
prs_anomalia <- function(tr, te) {
  medias <- tr[, .(media_prs = mean(PRS)), by = estacion]
  f <- function(d) { d <- merge(copy(d), medias, by = "estacion", sort = FALSE); d[, PRS := PRS - media_prs][, media_prs := NULL] }
  list(tr = f(tr), te = f(te))
}

# matriz_x(): indicadoras de estacion y temporada (con referencia), opcionalmente con la
#   interaccion, mas las columnas numericas pedidas.
matriz_x <- function(d, numericas, interaccion = FALSE) {
  est <- factor(d$estacion, levels = ESTACIONES); tem <- factor(d$temporada, levels = TEMPORADAS)
  x <- model.matrix(if (interaccion) ~ est * tem else ~ est + tem, data.frame(est, tem))[, -1, drop = FALSE]
  if (length(numericas)) x <- cbind(x, as.matrix(d[, ..numericas]))
  x
}

# ajustar(): entrena LDA (o logistica) y devuelve las probabilidades de la prueba.
#   Estandariza con medias y desviaciones del entrenamiento; prior y corte = prevalencia de
#   entrenamiento de la respuesta `y`.
ajustar <- function(tr, te, numericas, y = "supera_25", interaccion = FALSE, metodo = "lda") {
  x_tr <- matriz_x(tr, numericas, interaccion); x_te <- matriz_x(te, numericas, interaccion)
  medias <- colMeans(x_tr); desv <- apply(x_tr, 2, sd); desv[desv == 0] <- 1
  z_tr <- scale(x_tr, medias, desv); z_te <- scale(x_te, medias, desv)
  prev <- mean(tr[[y]])
  if (metodo == "lda") {
    modelo <- lda(z_tr, grouping = tr[[y]], prior = c(1 - prev, prev))
    p <- predict(modelo, z_te)$posterior[, "1"]
  } else {
    modelo <- glm(yy ~ ., data = data.frame(yy = tr[[y]], z_tr), family = binomial)
    p <- as.vector(predict(modelo, data.frame(z_te), type = "response"))
  }
  list(p = p, corte = prev, modelo = modelo, z_tr = z_tr)
}


# ---- Bloque 4. Metricas ------------------------------------------------------------------------
# AUC: area bajo la curva ROC (pROC para la cifra reportada). En el bootstrap usamos la formula
#   equivalente de Mann-Whitney con rangos, que da el mismo valor y es mucho mas rapida.
# Exactitud balanceada, sensibilidad y especificidad: con el corte = prevalencia de entrenamiento.
# Brier: error cuadratico medio de la probabilidad (mide calibracion; el AUC no).
auc_proc <- function(y, p) as.numeric(pROC::auc(pROC::roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)))
auc_rapido <- function(y, p) {
  r <- rank(p); n1 <- sum(y == 1); n0 <- length(y) - n1
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
metricas <- function(y, p, corte) {
  clase <- as.integer(p >= corte)
  sens <- mean(clase[y == 1] == 1); espe <- mean(clase[y == 0] == 0)
  c(auc = auc_proc(y, p), exactitud_balanceada = (sens + espe) / 2, sensibilidad = sens,
    especificidad = espe, brier = mean((p - y)^2))
}
eb_rapida <- function(y, p, corte) { clase <- p >= corte; 0.5 * (mean(clase[y == 1]) + mean(!clase[y == 0])) }


# ---- Bloque 5. Bootstrap pareado por bloques de fechas ----------------------------------------
# Se parte la prueba en bloques de `dias` dias consecutivos desde el 1 de enero del primer anio
# de prueba; cada bloque lleva TODAS las estaciones de esas fechas (un episodio afecta a varias).
# En cada replica se remuestrean bloques con reemplazo y se calcula el AUC de los dos modelos
# sobre exactamente las mismas filas, con sus predicciones fijas (sin reajustar).
bootstrap <- function(fechas, y, p_a, p_b, corte_a, corte_b, dias = 14L, n = N_REPLICAS, semilla = SEMILLA,
                      y_b = y) {
  bloque <- as.integer(fechas - INICIO_BLOQUES) %/% dias
  filas <- split(seq_along(bloque), bloque)
  set.seed(semilla)
  rep <- t(vapply(seq_len(n), function(i) {
    idx <- unlist(filas[sample.int(length(filas), length(filas), replace = TRUE)], use.names = FALSE)
    c(auc_a = auc_rapido(y[idx], p_a[idx]), auc_b = auc_rapido(y_b[idx], p_b[idx]),
      eb_a = eb_rapida(y[idx], p_a[idx], corte_a), eb_b = eb_rapida(y_b[idx], p_b[idx], corte_b))
  }, numeric(4)))
  rep <- as.data.table(rep)
  rep[, `:=`(d_auc = auc_b - auc_a, d_eb = eb_b - eb_a)]
  list(replicas = rep, n_bloques = length(filas),
       ic = rep[, .(d_auc_li = quantile(d_auc, 0.025), d_auc_ls = quantile(d_auc, 0.975),
                    d_eb_li = quantile(d_eb, 0.025), d_eb_ls = quantile(d_eb, 0.975),
                    auc_a_li = quantile(auc_a, 0.025), auc_a_ls = quantile(auc_a, 0.975),
                    auc_b_li = quantile(auc_b, 0.025), auc_b_ls = quantile(auc_b, 0.975))])
}

# comparar(): metricas puntuales de dos modelos (a = referencia, b = con meteorologia) y su
#   bootstrap. Devuelve una fila con AUC de cada uno, dAUC con IC y dEB con IC.
comparar <- function(nombre, d_te, fit_a, fit_b, y = "supera_25", dias = 14L) {
  ya <- d_te[[y]]
  ma <- metricas(ya, fit_a$p, fit_a$corte); mb <- metricas(ya, fit_b$p, fit_b$corte)
  b <- bootstrap(d_te$fecha, ya, fit_a$p, fit_b$p, fit_a$corte, fit_b$corte, dias = dias)
  stopifnot(abs(auc_rapido(ya, fit_a$p) - ma[["auc"]]) < 1e-10)   # rapido = pROC
  list(fila = data.table(analisis = nombre, n = nrow(d_te), prevalencia = mean(ya),
                         auc_M0 = ma[["auc"]], auc_M1 = mb[["auc"]], d_auc = mb[["auc"]] - ma[["auc"]],
                         d_auc_li = b$ic$d_auc_li, d_auc_ls = b$ic$d_auc_ls,
                         eb_M0 = ma[["exactitud_balanceada"]], eb_M1 = mb[["exactitud_balanceada"]],
                         d_eb = mb[["exactitud_balanceada"]] - ma[["exactitud_balanceada"]],
                         d_eb_li = b$ic$d_eb_li, d_eb_ls = b$ic$d_eb_ls, bloques = b$n_bloques, dias_bloque = dias),
       metricas = rbind(data.table(analisis = nombre, modelo = "M0", t(ma)), data.table(analisis = nombre, modelo = "M1", t(mb))),
       boot = b)
}


# ---- Bloque 6. Modelo final: M0 y M1 con LDA ------------------------------------------------------
# D17: PRS como anomalia de su estacion (medias de entrenamiento). D16: sin transformaciones.
a <- prs_anomalia(entrena, prueba)
tr <- a$tr; te <- a$te
m0 <- ajustar(tr, te, character())
m1 <- ajustar(tr, te, MET)
principal <- comparar("Principal: LDA, bloques de 14 dias", te, m0, m1)
escribir(principal$metricas, "prueba_metricas_m0_m1.csv")
escribir(principal$boot$replicas, "prueba_bootstrap_replicas.csv")
print(principal$metricas)
print(principal$fila[, .(auc_M0, auc_M1, d_auc, d_auc_li, d_auc_ls, d_eb, d_eb_li, d_eb_ls)])


# ---- Bloque 7. dAUC por temporada ------------------------------------------------------------------
# Mismo bootstrap, restringido a las filas de cada temporada (predicciones del modelo final).
por_temporada <- rbindlist(lapply(TEMPORADAS, function(tp) {
  k <- te$temporada == tp
  sub0 <- list(p = m0$p[k], corte = m0$corte); sub1 <- list(p = m1$p[k], corte = m1$corte)
  comparar(paste("Temporada:", tp), te[k], sub0, sub1)$fila
}))
escribir(por_temporada, "prueba_dauc_por_temporada.csv")


# ---- Bloque 8. Robustez: regresion logistica ---------------------------------------------------------
# Mismos predictores, particion y metricas; sin prueba de razon de verosimilitud.
l0 <- ajustar(tr, te, character(), metodo = "logistica")
l1 <- ajustar(tr, te, MET, metodo = "logistica")
logistica <- comparar("Robustez: logistica", te, l0, l1)


# ---- Bloque 9. Sensibilidades ------------------------------------------------------------------------
sens <- list()
# a) Bloques de 7 y 28 dias (mismas predicciones del modelo final).
sens$b7 <- comparar("a) bloques de 7 dias", te, m0, m1, dias = 7L)$fila
sens$b28 <- comparar("a) bloques de 28 dias", te, m0, m1, dias = 28L)$fila

# b) Umbral de 15 ug/m3 (guia OMS): se reajustan M0 y M1 con supera_15.
sens$u15 <- comparar("b) umbral 15 ug/m3", te, ajustar(tr, te, character(), y = "supera_15"),
                     ajustar(tr, te, MET, y = "supera_15"), y = "supera_15")$fila

# c) PM2.5 solo con horas observadas (>= 18 h, sin imputar); se excluyen los dias no evaluables
#    en entrenamiento y en prueba, y se reajustan los modelos con esa respuesta.
horario <- rbindlist(lapply(c(ANIOS_ENTRENA, ANIOS_PRUEBA), function(an) {
  h <- fread(sprintf("data/clean/sima_horario_limpio_%d.csv", an), select = c("estacion", "fecha_hora", "PM2.5", "f_PM2.5"),
             colClasses = list(character = "fecha_hora"))
  h[estacion %in% ESTACIONES]
}))
horario[, fecha := as.Date(substr(fecha_hora, 1, 10))]
obs <- horario[, .(n_obs = sum(f_PM2.5 %in% c("V", "C")),
                   pm25_obs = mean(`PM2.5`[f_PM2.5 %in% c("V", "C")])), by = .(estacion, fecha)]
obs <- obs[n_obs >= 18L, .(estacion, fecha, supera_25_obs = as.integer(pm25_obs > 25))]
tr_o <- merge(tr, obs, by = c("estacion", "fecha")); te_o <- merge(te, obs, by = c("estacion", "fecha"))
setorder(te_o, fecha, estacion)
sens$obs <- comparar("c) PM2.5 solo con horas observadas", te_o, ajustar(tr_o, te_o, character(), y = "supera_25_obs"),
                     ajustar(tr_o, te_o, MET, y = "supera_25_obs"), y = "supera_25_obs")$fila

# d) M1 con PC1-PC3 en lugar de las 8 variables. PCA de la version preferida (anomalia por
#    estacion): medias por estacion, escalado y componentes ajustados SOLO con el entrenamiento.
medias_est <- entrena[, lapply(.SD, mean), by = estacion, .SDcols = MET]
anomalia <- function(d) {
  d <- merge(copy(d), medias_est, by = "estacion", suffixes = c("", "_m"), sort = FALSE)
  for (v in MET) d[, (v) := get(v) - get(paste0(v, "_m"))]
  d[, paste0(MET, "_m") := NULL]
}
an_tr <- anomalia(entrena); an_te <- anomalia(prueba)
pca_tr <- prcomp(as.matrix(an_tr[, ..MET]), center = TRUE, scale. = TRUE)
k_kaiser <- sum(pca_tr$sdev^2 > 1)
stopifnot(k_kaiser == 3L)   # decision fijada en la fase A
pcs <- function(d_an) predict(pca_tr, as.matrix(d_an[, ..MET]))[, 1:3]
tr_pc <- cbind(an_tr[, .(estacion, fecha, temporada, supera_25)], pcs(an_tr))
te_pc <- cbind(an_te[, .(estacion, fecha, temporada, supera_25)], pcs(an_te))
setorder(tr_pc, fecha, estacion); setorder(te_pc, fecha, estacion)
sens$pcs <- comparar("d) M1 con PC1-PC3", te_pc, ajustar(tr_pc, te_pc, character()),
                     ajustar(tr_pc, te_pc, c("PC1", "PC2", "PC3")))$fila

# e) Interaccion estacion x temporada en M0 y en M1.
sens$inter <- comparar("e) interaccion estacion x temporada", te, ajustar(tr, te, character(), interaccion = TRUE),
                       ajustar(tr, te, MET, interaccion = TRUE))$fila

# f) Logaritmo de la rapidez del viento en M1 (D16: sensibilidad).
trl <- copy(tr)[, viento_rapidez_ms := log(viento_rapidez_ms)]; tel <- copy(te)[, viento_rapidez_ms := log(viento_rapidez_ms)]
sens$logv <- comparar("f) log de la rapidez del viento", tel, m0, ajustar(trl, tel, MET))$fila

# g) Solo M0, en la muestra con solo PM2.5 valido (sin exigir meteorologia; 19 918 estacion-dias
#    en 2021-2025). Se compara con M0 en la muestra principal con el mismo remuestreo de bloques.
diario <- fread("data/clean/sima_diario_2020_2025.csv")
pm <- diario[anio %in% c(ANIOS_ENTRENA, ANIOS_PRUEBA) & estacion %in% ESTACIONES & !is.na(`PM2.5`)]
pm[, `:=`(fecha = as.Date(fecha), supera_25 = as.integer(`PM2.5` > 25))]
if (!ENSAYO) stopifnot(nrow(pm) == 19918L)
pm_tr <- pm[anio %in% ANIOS_ENTRENA]; pm_te <- pm[anio %in% ANIOS_PRUEBA]
m0_pm <- ajustar(pm_tr, pm_te, character())
auc_m0_pm <- auc_proc(pm_te$supera_25, m0_pm$p)
b_pm <- bootstrap(pm_te$fecha, pm_te$supera_25, m0_pm$p, m0_pm$p, m0_pm$corte, m0_pm$corte)
sens$m0pm <- data.table(analisis = "g) solo M0 en la muestra con solo PM2.5 valido", n = nrow(pm_te),
                        prevalencia = mean(pm_te$supera_25), auc_M0 = auc_m0_pm, auc_M1 = NA_real_, d_auc = NA_real_,
                        d_auc_li = NA_real_, d_auc_ls = NA_real_,
                        eb_M0 = metricas(pm_te$supera_25, m0_pm$p, m0_pm$corte)[["exactitud_balanceada"]],
                        eb_M1 = NA_real_, d_eb = NA_real_, d_eb_li = NA_real_, d_eb_ls = NA_real_,
                        bloques = b_pm$n_bloques, dias_bloque = 14L,
                        auc_M0_li = b_pm$ic$auc_a_li, auc_M0_ls = b_pm$ic$auc_a_ls,
                        auc_M0_principal = principal$fila$auc_M0,
                        n_entrena = nrow(pm_tr))

tabla_sens <- rbindlist(c(list(principal$fila, logistica$fila), sens), fill = TRUE)
escribir(tabla_sens, "prueba_sensibilidades.csv")


# ---- Bloque 10. Interpretacion del modelo final ------------------------------------------------------
# Coeficientes estandarizados de M1 (divididos entre el maximo absoluto) y correlaciones de
# estructura (correlacion de cada predictor con la puntuacion discriminante en el entrenamiento).
w <- m1$modelo$scaling[, 1]
puntuacion <- as.vector(m1$z_tr %*% w)
interp <- data.table(predictor = colnames(m1$z_tr), coef_estandarizado = w / max(abs(w)),
                     correlacion_estructura = as.vector(cor(m1$z_tr, puntuacion)))
escribir(interp, "m1_coeficientes_estructura.csv")
# El signo de un componente es arbitrario: lo orientamos como en decisiones_etapa3.md
# (PC1 con TOUT positiva, PC2 con RH positiva, PC3 con PRS negativa). Solo afecta al reporte.
cargas_m <- pca_tr$rotation[, 1:3] %*% diag(pca_tr$sdev[1:3])
signo <- c(sign(cargas_m["TOUT", 1]), sign(cargas_m["RH", 2]), -sign(cargas_m["PRS", 3]))
cargas <- data.table(variable = MET, sweep(cargas_m, 2, signo, `*`))
setnames(cargas, c("variable", "PC1", "PC2", "PC3"))
escribir(cargas, "pca_cargas_anomalia.csv")
escribir(data.table(componente = paste0("PC", 1:8), valor_propio = pca_tr$sdev^2,
                    pct_varianza = 100 * pca_tr$sdev^2 / 8), "pca_valores_propios.csv")


# ---- Bloque 11. Figuras (sin "Figura N"; la numeracion la pone Quarto) -------------------------------
roc0 <- pROC::roc(te$supera_25, m0$p, levels = c(0, 1), direction = "<", quiet = TRUE)
roc1 <- pROC::roc(te$supera_25, m1$p, levels = c(0, 1), direction = "<", quiet = TRUE)
curvas <- rbind(data.table(modelo = sprintf("M0 (AUC %.3f)", principal$fila$auc_M0), fpr = 1 - roc0$specificities, tpr = roc0$sensitivities),
                data.table(modelo = sprintf("M1 (AUC %.3f)", principal$fila$auc_M1), fpr = 1 - roc1$specificities, tpr = roc1$sensitivities))
g1 <- ggplot(curvas[order(modelo, fpr, tpr)], aes(fpr, tpr, colour = modelo)) +
  geom_abline(linetype = "dotted", colour = "grey50") + geom_path(linewidth = 0.8) +
  scale_colour_manual(values = c("#0072B2", "#D55E00"), name = NULL) + coord_equal() +
  labs(x = "1 − especificidad", y = "Sensibilidad", title = "Curvas ROC en la prueba") +
  theme_minimal(base_size = 10) + theme(legend.position = c(0.7, 0.2))
ggsave(file.path(FIGURAS, "roc_m0_m1_prueba.png"), g1, width = 5, height = 5, dpi = 150)

g2 <- ggplot(principal$boot$replicas, aes(d_auc)) +
  geom_histogram(bins = 40, fill = "#8CA9C9", colour = "white") +
  geom_vline(xintercept = principal$fila$d_auc, colour = "#D55E00") +
  geom_vline(xintercept = c(principal$fila$d_auc_li, principal$fila$d_auc_ls), linetype = "dashed") +
  geom_vline(xintercept = 0, colour = "grey30") +
  labs(x = "ΔAUC (M1 − M0)", y = "Réplicas",
       title = sprintf("Bootstrap por bloques de 14 días (%d réplicas)", N_REPLICAS)) +
  theme_minimal(base_size = 10)
ggsave(file.path(FIGURAS, "bootstrap_dauc.png"), g2, width = 6, height = 3.8, dpi = 150)

ic <- copy(interp)[, predictor := sub("^est", "estación ", sub("^tem", "temporada ", predictor))]
ic[predictor == "PRS", predictor := "PRS (anomalía de su estación)"]
ic[, predictor := factor(predictor, levels = predictor[order(coef_estandarizado)])]
g3 <- ggplot(ic, aes(coef_estandarizado, predictor, fill = coef_estandarizado > 0)) +
  geom_col(show.legend = FALSE) + scale_fill_manual(values = c("#0072B2", "#D55E00")) +
  labs(x = "Coeficiente estandarizado (máximo absoluto = 1)", y = NULL,
       title = sprintf("Función discriminante de M1 (entrenamiento %s)", paste(range(ANIOS_ENTRENA), collapse = "–"))) +
  theme_minimal(base_size = 9)
ggsave(file.path(FIGURAS, "coeficientes_m1.png"), g3, width = 6.5, height = 5.5, dpi = 150)

cl <- melt(cargas, id.vars = "variable", variable.name = "componente", value.name = "carga")
cl[, variable := factor(variable, levels = rev(MET))]
g4 <- ggplot(cl, aes(componente, variable, fill = carga)) +
  geom_tile(colour = "white") + geom_text(aes(label = sprintf("%.2f", carga)), size = 3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), name = "Carga") +
  labs(x = NULL, y = NULL, title = "Cargas del PCA", subtitle = "Anomalía por estación, entrenamiento") +
  theme_minimal(base_size = 10) + theme(panel.grid = element_blank())
ggsave(file.path(FIGURAS, "pca_cargas.png"), g4, width = 5, height = 4.5, dpi = 150)


# ---- Bloque 12. RESUMEN.md ------------------------------------------------------------------------------
f3 <- function(x) ifelse(is.na(x), "—", sprintf("%.3f", x))
ic_txt <- function(li, ls) ifelse(is.na(li), "—", sprintf("[%.3f, %.3f]", li, ls))
tabla_md <- function(dt) c(paste0("| ", paste(names(dt), collapse = " | "), " |"),
                          paste0("|", paste(rep("---", ncol(dt)), collapse = "|"), "|"),
                          apply(dt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
pm_ <- principal$metricas
t_principal <- data.table(Métrica = c("AUC", "Exactitud balanceada", "Sensibilidad", "Especificidad", "Brier"),
  M0 = f3(unlist(pm_[modelo == "M0", .(auc, exactitud_balanceada, sensibilidad, especificidad, brier)])),
  M1 = f3(unlist(pm_[modelo == "M1", .(auc, exactitud_balanceada, sensibilidad, especificidad, brier)])))
t_principal[, `M1 − M0` := f3(unlist(pm_[modelo == "M1", .(auc, exactitud_balanceada, sensibilidad, especificidad, brier)]) -
                              unlist(pm_[modelo == "M0", .(auc, exactitud_balanceada, sensibilidad, especificidad, brier)]))]
t_principal[, `IC 95 %` := c(ic_txt(principal$fila$d_auc_li, principal$fila$d_auc_ls), ic_txt(principal$fila$d_eb_li, principal$fila$d_eb_ls), "—", "—", "—")]
t_sens <- tabla_sens[, .(Análisis = analisis, n, `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1), `ΔAUC` = f3(d_auc),
                         `IC 95 %` = ic_txt(d_auc_li, d_auc_ls))]
t_temp <- por_temporada[, .(Temporada = sub("Temporada: ", "", analisis), n, `% superación` = sprintf("%.1f", 100 * prevalencia),
                            `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1), `ΔAUC` = f3(d_auc), `IC 95 %` = ic_txt(d_auc_li, d_auc_ls))]
t_coef <- interp[order(-abs(coef_estandarizado))][1:10, .(Predictor = predictor, `Coef. estandarizado` = f3(coef_estandarizado),
                                                         `Corr. de estructura` = f3(correlacion_estructura))]
lineas <- c(
  if (ENSAYO) "# ENSAYO (entrena 2021–2022, «prueba» 2023): no es la evaluación oficial" else "# Etapa 3 · Evaluación de la prueba (2024–2025)",
  "",
  sprintf("Generado por `scripts/07b_evaluar_prueba.R` el %s. Decisiones cerradas en el commit `%s` (fase A); código al correr: `%s`. Entrenamiento %s (n = %s), prueba %s (n = %s, %.1f %% de superación). LDA con prior = prevalencia de entrenamiento (%.3f), corte en esa misma prevalencia; PRS como anomalía de su estación (D17); sin transformaciones (D16). Bootstrap pareado por bloques de 14 días (%d bloques, %d réplicas, semilla %d), con predicciones fijas.",
          format(Sys.time(), "%Y-%m-%d %H:%M"), substr(hash_fase_a, 1, 7), substr(hash_actual, 1, 7),
          paste(range(ANIOS_ENTRENA), collapse = "–"), format(nrow(tr), big.mark = ","),
          paste(range(ANIOS_PRUEBA), collapse = "–"), format(nrow(te), big.mark = ","), 100 * mean(te$supera_25),
          m1$corte, principal$fila$bloques, N_REPLICAS, SEMILLA),
  "", "## 1. Resultado principal (LDA)", "", tabla_md(t_principal), "",
  sprintf("ΔAUC = %.3f (IC 95 %% %s). Un AUC no es un porcentaje de aciertos ni implica probabilidades calibradas; el Brier sí mide calibración.",
          principal$fila$d_auc, ic_txt(principal$fila$d_auc_li, principal$fila$d_auc_ls)),
  "", "## 2. ΔAUC por temporada (descriptivo)", "", tabla_md(t_temp),
  "", "## 3. Robustez y sensibilidades", "",
  "Cada fila reajusta los modelos con entrenamiento y evalúa la prueba una vez; los IC son por bootstrap de bloques (14 días salvo que se indique).", "",
  tabla_md(t_sens), "",
  sprintf("g) M0 en la muestra con solo PM2.5 válido: entrenamiento n = %s, prueba n = %s; AUC %.3f (IC 95 %% [%.3f, %.3f]) frente a %.3f de M0 en la muestra principal.",
          format(sens$m0pm$n_entrena, big.mark = ","), format(sens$m0pm$n, big.mark = ","), sens$m0pm$auc_M0,
          sens$m0pm$auc_M0_li, sens$m0pm$auc_M0_ls, sens$m0pm$auc_M0_principal),
  "", "## 4. Interpretación de M1", "",
  "Coeficientes estandarizados (divididos entre el máximo absoluto) y correlaciones de estructura; se interpretan en conjunto. Los 10 de mayor magnitud:", "",
  tabla_md(t_coef), "",
  sprintf("PCA (anomalía por estación, entrenamiento): valores propios %s; k = %d por Kaiser. Cargas en `pca_cargas_anomalia.csv`.",
          paste(sprintf("%.2f", pca_tr$sdev[1:4]^2), collapse = ", "), k_kaiser),
  "", "## 5. Figuras", "",
  "`figuras/roc_m0_m1_prueba.png`, `figuras/bootstrap_dauc.png`, `figuras/coeficientes_m1.png`, `figuras/pca_cargas.png`.")
con <- file(file.path(SALIDA, "RESUMEN.md"), "w", encoding = "UTF-8"); writeLines(lineas, con); close(con)
if (!ENSAYO) cat("Salidas escritas. Resultados en output/etapa3/RESUMEN.md\n", file = "output/etapa3/registro_prueba.txt", append = TRUE)
cat("Listo:", SALIDA, "\n")
