# Etapa 4: funciones del modelo, COPIADAS SIN CAMBIOS de scripts/07b_evaluar_prueba.R (bloques 3 a 5)
# para que 09a, 09b y 09c usen exactamente el mismo procedimiento que la etapa 3. El paso 0 de la
# tabla puente (09a) comprueba que con datos-v1.2 reproducen ΔAUC = 0.070 [0.047, 0.094].
# Solo se agregan argumentos con el mismo valor por defecto (no cambian el resultado):
#   - bootstrap(): `inicio` (fecha del primer bloque; por defecto INICIO_BLOQUES);
#   - comparar(): `n` y `semilla` del bootstrap (por defecto N_REPLICAS y SEMILLA);
#   - prs_anomalia() devuelve tambien las medias y ajustar() el escalado (como en 07c).
# Igual que en 07b, el script que las usa define ESTACIONES, TEMPORADAS, INICIO_BLOQUES,
# N_REPLICAS y SEMILLA antes de llamarlas.

# prs_anomalia(): D17. Resta a PRS la media de su estacion calculada SOLO con el entrenamiento,
#   y usa esas mismas medias en la prueba (sin fuga de informacion).
prs_anomalia <- function(tr, te) {
  medias <- tr[, .(media_prs = mean(PRS)), by = estacion]
  f <- function(d) { d <- merge(copy(d), medias, by = "estacion", sort = FALSE); d[, PRS := PRS - media_prs][, media_prs := NULL] }
  list(tr = f(tr), te = f(te), medias = medias)
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
    modelo <- MASS::lda(z_tr, grouping = tr[[y]], prior = c(1 - prev, prev))
    p <- predict(modelo, z_te)$posterior[, "1"]
  } else {
    modelo <- glm(yy ~ ., data = data.frame(yy = tr[[y]], z_tr), family = binomial)
    p <- as.vector(predict(modelo, data.frame(z_te), type = "response"))
  }
  list(p = p, corte = prev, modelo = modelo, z_tr = z_tr, z_te = z_te, medias = medias, desv = desv)
}

# AUC: area bajo la curva ROC (pROC para la cifra reportada). En el bootstrap se usa la formula
#   equivalente de Mann-Whitney con rangos, que da el mismo valor y es mucho mas rapida.
auc_proc <- function(y, p) as.numeric(pROC::auc(pROC::roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)))
auc_rapido <- function(y, p) {
  r <- rank(p); n1 <- sum(y == 1); n0 <- length(y) - n1
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
# Exactitud balanceada, sensibilidad y especificidad con el corte = prevalencia de entrenamiento;
#   Brier = error cuadratico medio de la probabilidad.
metricas <- function(y, p, corte) {
  clase <- as.integer(p >= corte)
  sens <- mean(clase[y == 1] == 1); espe <- mean(clase[y == 0] == 0)
  c(auc = auc_proc(y, p), exactitud_balanceada = (sens + espe) / 2, sensibilidad = sens,
    especificidad = espe, brier = mean((p - y)^2))
}
eb_rapida <- function(y, p, corte) { clase <- p >= corte; 0.5 * (mean(clase[y == 1]) + mean(!clase[y == 0])) }

# Bootstrap pareado por bloques de `dias` dias consecutivos desde `inicio`; cada bloque lleva TODAS
#   las estaciones de esas fechas. En cada replica se remuestrean bloques con reemplazo y se calcula
#   el AUC de los dos modelos sobre exactamente las mismas filas, con sus predicciones fijas.
bootstrap <- function(fechas, y, p_a, p_b, corte_a, corte_b, dias = 14L, n = N_REPLICAS, semilla = SEMILLA,
                      y_b = y, inicio = INICIO_BLOQUES) {
  bloque <- as.integer(fechas - inicio) %/% dias
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
comparar <- function(nombre, d_te, fit_a, fit_b, y = "supera_25", dias = 14L, n = N_REPLICAS, semilla = SEMILLA) {
  ya <- d_te[[y]]
  ma <- metricas(ya, fit_a$p, fit_a$corte); mb <- metricas(ya, fit_b$p, fit_b$corte)
  b <- bootstrap(d_te$fecha, ya, fit_a$p, fit_b$p, fit_a$corte, fit_b$corte, dias = dias, n = n, semilla = semilla)
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
