# =============================================================================================
# Etapa 3, fase A: validacion progresiva (SOLO 2021-2023) y reproduccion de
# docs/etapa3/decisiones_etapa3.md (prototipo en Python) con R.
#
# Regla central del protocolo: la prueba (2024-2025) se evalua UNA sola vez, en
# scripts/07b_evaluar_prueba.R, despues de cerrar las decisiones. Este script NO debe
# ver esos anios: si los encuentra, se detiene.
#
# Como usarlo en RStudio: abre sima.Rproj y corre los bloques en orden (Ctrl + Enter
# linea por linea, o selecciona un bloque completo). Cada bloque empieza con un
# comentario que explica que hace y por que.
#
# Escribe: output/etapa3/validacion/ (tablas CSV y comparacion_python.csv)
# =============================================================================================


# ---- Bloque 0. Paquetes y carpetas ------------------------------------------------------------
# MASS trae lda() (analisis discriminante lineal); pROC calcula el AUC; data.table lee y
# transforma tablas rapido.
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
})
SALIDA <- "output/etapa3/validacion"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre))


# ---- Bloque 1. Datos: solo 2021-2023 -----------------------------------------------------------
# Leemos la muestra del protocolo y nos quedamos SOLO con el entrenamiento. Despues
# comprobamos que no quede ninguna fila de 2024-2025: si la hubiera, el script se detiene,
# porque usar la prueba para decidir invalidaria la evaluacion final.
datos <- fread("data/clean/muestra_pm25_2021_2025.csv")[anio <= 2023]
if (any(datos$anio >= 2024)) stop("Hay filas de 2024-2025 en la fase A. Detente.", call. = FALSE)
stopifnot(nrow(datos) == 10170L)   # n del entrenamiento segun decisiones_etapa3.md

MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
datos[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]   # horas_lluvia es entera: evitar truncar
ESTACIONES <- sort(unique(datos$estacion))
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")


# ---- Bloque 2. Funciones de apoyo ---------------------------------------------------------------
# matriz_x(): arma los predictores. Estacion y temporada entran como indicadoras (0/1) con
#   una categoria de referencia; con `interaccion = TRUE` se agregan los productos
#   estacion x temporada. Despues se pegan las variables meteorologicas que se pidan.
matriz_x <- function(d, met, interaccion = FALSE) {
  est <- factor(d$estacion, levels = ESTACIONES)
  tem <- factor(d$temporada, levels = TEMPORADAS)
  formula <- if (interaccion) ~ est * tem else ~ est + tem
  x <- model.matrix(formula, data.frame(est, tem))[, -1, drop = FALSE]   # quita el intercepto
  if (length(met)) x <- cbind(x, as.matrix(d[, ..met]))
  x
}

# auc(): area bajo la curva ROC. direction = "<" significa "probabilidad mas alta = clase 1".
auc <- function(y, p) as.numeric(pROC::auc(pROC::roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)))

# exactitud_balanceada(): promedio de sensibilidad y especificidad con un punto de corte.
exactitud_balanceada <- function(y, p, corte) {
  clase <- as.integer(p >= corte)
  0.5 * (mean(clase[y == 1] == 1) + mean(clase[y == 0] == 0))
}

# ajustar_y_predecir(): entrena en `entrena` y predice en `valida`.
#   - Estandariza con medias y desviaciones SOLO del entrenamiento (sin fuga de informacion).
#   - LDA con prior = prevalencia de entrenamiento; corte = esa misma prevalencia.
#   - `metodo = "logistica"` usa glm() sin penalizacion, solo como comprobacion de robustez.
#   - `transformar` permite aplicar log a algunas variables (seccion de transformaciones).
ajustar_y_predecir <- function(entrena, valida, met, interaccion = FALSE, metodo = "lda",
                               transformar = function(d) d) {
  entrena <- transformar(copy(entrena)); valida <- transformar(copy(valida))
  x_tr <- matriz_x(entrena, met, interaccion); x_va <- matriz_x(valida, met, interaccion)
  medias <- colMeans(x_tr); desv <- apply(x_tr, 2, sd); desv[desv == 0] <- 1
  z_tr <- scale(x_tr, medias, desv); z_va <- scale(x_va, medias, desv)
  prev <- mean(entrena$supera_25)
  if (metodo == "lda") {
    modelo <- lda(z_tr, grouping = entrena$supera_25, prior = c(1 - prev, prev))
    p <- predict(modelo, z_va)$posterior[, "1"]
  } else {
    modelo <- glm(y ~ ., data = data.frame(y = entrena$supera_25, z_tr), family = binomial)
    p <- predict(modelo, data.frame(z_va), type = "response")
  }
  c(auc = auc(valida$supera_25, p), ba = exactitud_balanceada(valida$supera_25, p, prev))
}


# ---- Bloque 3. Pliegues de la validacion progresiva ---------------------------------------------
# Dos pliegues: entrena 2021 -> valida 2022; entrena 2021-2022 -> valida 2023.
pliegues <- list(
  "2022" = list(entrena = datos[anio == 2021], valida = datos[anio == 2022]),
  "2023" = list(entrena = datos[anio <= 2022], valida = datos[anio == 2023]))


# ---- Bloque 4. Seccion 1: M0 frente a M1 (LDA), interaccion y logistica --------------------------
# M0 = estacion + temporada; M1 = M0 + 8 meteorologicas. Repetimos con la interaccion
# estacion x temporada y con regresion logistica.
modelos <- list(
  M0 = list(met = character(), inter = FALSE, metodo = "lda"),
  M1 = list(met = MET, inter = FALSE, metodo = "lda"),
  M0_interaccion = list(met = character(), inter = TRUE, metodo = "lda"),
  M1_interaccion = list(met = MET, inter = TRUE, metodo = "lda"),
  M0_logistica = list(met = character(), inter = FALSE, metodo = "logistica"),
  M1_logistica = list(met = MET, inter = FALSE, metodo = "logistica"))
tabla1 <- rbindlist(lapply(names(modelos), function(nm) {
  md <- modelos[[nm]]
  rbindlist(lapply(names(pliegues), function(pl) {
    r <- ajustar_y_predecir(pliegues[[pl]]$entrena, pliegues[[pl]]$valida, md$met, md$inter, md$metodo)
    data.table(modelo = nm, valida = pl, auc = r[["auc"]], exactitud_balanceada = r[["ba"]])
  }))
}))
escribir(tabla1, "seccion1_m0_m1.csv")
print(dcast(tabla1, modelo ~ valida, value.var = "auc"))


# ---- Bloque 5. Seccion 2: transformaciones de M1 (D16) -------------------------------------------
# Comparamos M1 sin transformar con tres variantes. D16 decide NO transformar; el log de la
# rapidez del viento queda como sensibilidad.
log_lluvia <- function(d) d[, horas_lluvia := log1p(horas_lluvia)]
log_lluvia_viento <- function(d) d[, `:=`(horas_lluvia = log1p(horas_lluvia), viento_rapidez_ms = log(viento_rapidez_ms))]
variantes <- list(
  sin_transformar = list(met = MET, f = function(d) d),
  log1p_lluvia = list(met = MET, f = log_lluvia),
  llovio_en_lugar_de_horas = list(met = c(setdiff(MET, "horas_lluvia"), "llovio"), f = function(d) d),
  log1p_lluvia_y_log_viento = list(met = MET, f = log_lluvia_viento))
tabla2 <- rbindlist(lapply(names(variantes), function(nm) {
  v <- variantes[[nm]]
  rbindlist(lapply(names(pliegues), function(pl) data.table(
    variante = nm, valida = pl,
    auc = ajustar_y_predecir(pliegues[[pl]]$entrena, pliegues[[pl]]$valida, v$met, transformar = v$f)[["auc"]])))
}))
escribir(tabla2, "seccion2_transformaciones.csv")


# ---- Bloque 6. Seccion 3: PRS como anomalia de su estacion (D17) ---------------------------------
# PRS_anom = PRS - media de su estacion, calculada SOLO con el entrenamiento de cada pliegue.
# Es una combinacion lineal de PRS y de las indicadoras de estacion: el AUC debe ser identico.
con_prs_anom <- function(entrena, valida) {
  medias <- entrena[, .(m = mean(PRS)), by = estacion]
  f <- function(d) { d <- merge(copy(d), medias, by = "estacion"); d[, PRS := PRS - m][, m := NULL] }
  list(entrena = f(entrena), valida = f(valida))
}
tabla3 <- rbindlist(lapply(names(pliegues), function(pl) {
  a <- con_prs_anom(pliegues[[pl]]$entrena, pliegues[[pl]]$valida)
  data.table(valida = pl,
             auc_prs_crudo = ajustar_y_predecir(pliegues[[pl]]$entrena, pliegues[[pl]]$valida, MET)[["auc"]],
             auc_prs_anomalia = ajustar_y_predecir(a$entrena, a$valida, MET)[["auc"]])
}))
tabla3[, diferencia := auc_prs_anomalia - auc_prs_crudo]
escribir(tabla3, "seccion3_prs_anomalia.csv")
print(tabla3)


# ---- Bloque 7. Coeficientes estandarizados y correlaciones de estructura (M1, 2021-2023) ----------
# Ajustamos M1 con los tres anios. Coeficiente estandarizado = coeficiente de la funcion
# discriminante sobre predictores estandarizados, dividido entre el maximo absoluto (asi lo
# reporta el prototipo: PRS = -1.00). Correlacion de estructura = correlacion entre cada
# predictor y la puntuacion discriminante; con predictores correlacionados es mas facil de
# interpretar que el coeficiente.
coeficientes <- function(d, etiqueta) {
  x <- matriz_x(d, MET); z <- scale(x)
  prev <- mean(d$supera_25)
  modelo <- lda(z, grouping = d$supera_25, prior = c(1 - prev, prev))
  w <- modelo$scaling[, 1]
  puntuacion <- as.vector(z %*% w)
  data.table(version = etiqueta, predictor = colnames(x), coef_estandarizado = w / max(abs(w)),
             correlacion_estructura = as.vector(cor(z, puntuacion)))
}
datos_prs_anom <- copy(datos)[, PRS := PRS - mean(PRS), by = estacion]
tabla_coef <- rbind(coeficientes(datos, "PRS crudo"), coeficientes(datos_prs_anom, "PRS anomalia (D17)"))
escribir(tabla_coef, "coeficientes_m1_2021_2023.csv")


# ---- Bloque 8. Seccion 4: supuestos del LDA ---------------------------------------------------------
# M de Box: prueba si las matrices de covarianza de las dos clases son iguales (8 variables
# meteorologicas, gl = 36). Con n grande rechaza casi cualquier diferencia, por eso tambien
# miramos la razon de desviaciones estandar (clase 1 / clase 0) y la asimetria.
m_de_box <- function(x, g) {
  grupos <- split(as.data.frame(x), g); p <- ncol(x); k <- length(grupos); n <- sapply(grupos, nrow)
  covs <- lapply(grupos, cov)
  comun <- Reduce(`+`, Map(function(s, ni) (ni - 1) * s, covs, n)) / (sum(n) - k)
  M <- (sum(n) - k) * log(det(comun)) - sum((n - 1) * sapply(covs, function(s) log(det(s))))
  c1 <- (sum(1 / (n - 1)) - 1 / (sum(n) - k)) * (2 * p^2 + 3 * p - 1) / (6 * (p + 1) * (k - 1))
  chi2 <- M * (1 - c1); gl <- p * (p + 1) / 2 * (k - 1)
  c(chi2 = chi2, gl = gl, p = pchisq(chi2, gl, lower.tail = FALSE))
}
asimetria <- function(x) { x <- x - mean(x); mean(x^3) / mean(x^2)^1.5 }
supuestos <- function(d, etiqueta) {
  y <- d$supera_25; b <- m_de_box(as.matrix(d[, ..MET]), y)
  rbind(
    data.table(version = etiqueta, medida = "M de Box chi2", variable = "8 meteorologicas", valor = b[["chi2"]]),
    data.table(version = etiqueta, medida = "M de Box gl", variable = "8 meteorologicas", valor = b[["gl"]]),
    data.table(version = etiqueta, medida = "razon DE clase1/clase0", variable = MET,
               valor = sapply(MET, function(v) sd(d[[v]][y == 1]) / sd(d[[v]][y == 0]))),
    data.table(version = etiqueta, medida = "asimetria clase 0", variable = "horas_lluvia", valor = asimetria(d$horas_lluvia[y == 0])),
    data.table(version = etiqueta, medida = "asimetria clase 1", variable = "horas_lluvia", valor = asimetria(d$horas_lluvia[y == 1])),
    data.table(version = etiqueta, medida = "asimetria", variable = "viento_rapidez_ms", valor = asimetria(d$viento_rapidez_ms)),
    data.table(version = etiqueta, medida = "asimetria de log", variable = "viento_rapidez_ms",
               valor = if (all(d$viento_rapidez_ms > 0)) asimetria(log(d$viento_rapidez_ms)) else NA_real_),
    data.table(version = etiqueta, medida = "% de dias sin lluvia", variable = "horas_lluvia", valor = 100 * mean(d$horas_lluvia == 0)))
}
# Se reporta con las variables sin transformar, coherente con D16.
tabla_sup <- supuestos(datos, "sin transformar (D16)")
escribir(tabla_sup, "seccion4_supuestos.csv")


# ---- Bloque 9. Seccion 5: PCA exploratorio -----------------------------------------------------------
# prcomp() con scale. = TRUE estandariza las 8 variables. Cargas = vector propio x raiz del
# valor propio (correlacion variable-componente). KMO mide si las correlaciones parciales son
# pequenas (bueno para PCA); Bartlett prueba si la matriz de correlacion es la identidad.
kmo <- function(R) {
  P <- solve(R); A <- -P / sqrt(outer(diag(P), diag(P))); diag(A) <- 0
  R0 <- R; diag(R0) <- 0
  sum(R0^2) / (sum(R0^2) + sum(A^2))
}
bartlett <- function(R, n) c(chi2 = -(n - 1 - (2 * ncol(R) + 5) / 6) * log(det(R)), gl = ncol(R) * (ncol(R) - 1) / 2)
pca <- function(d, version, anomalia) {
  d <- copy(d)
  if (anomalia) d[, (MET) := lapply(.SD, function(x) x - mean(x)), by = estacion, .SDcols = MET]
  x <- as.matrix(d[, ..MET]); R <- cor(x)
  p <- prcomp(x, scale. = TRUE); ev <- p$sdev^2
  cargas <- p$rotation[, 1:3] %*% diag(p$sdev[1:3]); colnames(cargas) <- c("PC1", "PC2", "PC3")
  b <- bartlett(R, nrow(x))
  list(resumen = data.table(version = version, tipo = if (anomalia) "anomalia por estacion" else "cruda",
                            valor_propio_1 = ev[1], valor_propio_2 = ev[2], valor_propio_3 = ev[3], valor_propio_4 = ev[4],
                            n_mayor_1 = sum(ev > 1), varianza_acum_3 = 100 * sum(ev[1:3]) / sum(ev),
                            kmo = kmo(R), bartlett_chi2 = b[["chi2"]], bartlett_gl = b[["gl"]]),
       cargas = data.table(version = version, tipo = if (anomalia) "anomalia por estacion" else "cruda",
                           variable = MET, cargas))
}
corridas <- list(pca(datos, "sin transformar (D16)", FALSE), pca(datos, "sin transformar (D16)", TRUE))
escribir(rbindlist(lapply(corridas, `[[`, "resumen")), "seccion5_pca_resumen.csv")
escribir(rbindlist(lapply(corridas, `[[`, "cargas")), "seccion5_pca_cargas.csv")


# ---- Bloque 10. Comparacion con el prototipo en Python ---------------------------------------------
# Comparamos cada cifra del .md (version corregida del 5 oct) con la de R. Tolerancia: 0.002,
# o media unidad de la ultima cifra que reporta el .md si esta redondeada a menos decimales
# (por ejemplo, KMO 0.64 -> 0.005). La asimetria usa +/-0.05, porque Python y R pueden usar
# definiciones distintas (con o sin correccion por tamano de muestra). Las cargas del PCA se
# comparan en valor absoluto, porque el signo de un componente es arbitrario.
g1 <- function(m, v) tabla1[modelo == m & valida == v]
g2 <- function(nm, v) tabla2[variante == nm & valida == v, auc]
gs <- function(ver, med, var) tabla_sup[version == ver & medida == med & variable == var, valor]
gp <- function(ver, tipo_, col) rbindlist(lapply(corridas, `[[`, "resumen"))[version == ver & tipo == tipo_][[col]]
gc <- function(ver, tipo_, var, pc) abs(rbindlist(lapply(corridas, `[[`, "cargas"))[version == ver & tipo == tipo_ & variable == var][[pc]])
coef_d16 <- function(pred, col) tabla_coef[version == "PRS crudo" & predictor == pred][[col]]
D16 <- "sin transformar (D16)"; AN <- "anomalia por estacion"
fila <- function(seccion, cifra, md, r, decimales, tol = NULL) data.table(seccion, cifra, valor_md = md, valor_r = r,
  tolerancia = if (is.null(tol)) max(0.002, 0.5 * 10^-decimales) else tol)
comparacion <- rbind(
  fila("1", "AUC M0 valida 2022", 0.711, g1("M0", "2022")$auc, 3),
  fila("1", "AUC M0 valida 2023", 0.749, g1("M0", "2023")$auc, 3),
  fila("1", "AUC M1 valida 2022", 0.777, g1("M1", "2022")$auc, 3),
  fila("1", "AUC M1 valida 2023", 0.829, g1("M1", "2023")$auc, 3),
  fila("1", "EB M0 2022", 0.640, g1("M0", "2022")$exactitud_balanceada, 3),
  fila("1", "EB M0 2023", 0.689, g1("M0", "2023")$exactitud_balanceada, 3),
  fila("1", "EB M1 2022", 0.704, g1("M1", "2022")$exactitud_balanceada, 3),
  fila("1", "EB M1 2023", 0.734, g1("M1", "2023")$exactitud_balanceada, 3),
  fila("1", "dAUC 2022", 0.066, g1("M1", "2022")$auc - g1("M0", "2022")$auc, 3),
  fila("1", "dAUC 2023", 0.080, g1("M1", "2023")$auc - g1("M0", "2023")$auc, 3),
  fila("1", "AUC M0 interaccion 2022", 0.689, g1("M0_interaccion", "2022")$auc, 3),
  fila("1", "AUC M0 interaccion 2023", 0.752, g1("M0_interaccion", "2023")$auc, 3),
  fila("1", "AUC M1 interaccion 2022", 0.756, g1("M1_interaccion", "2022")$auc, 3),
  fila("1", "AUC M1 interaccion 2023", 0.835, g1("M1_interaccion", "2023")$auc, 3),
  fila("1", "EB M0 interaccion 2022", 0.640, g1("M0_interaccion", "2022")$exactitud_balanceada, 3),
  fila("1", "EB M0 interaccion 2023", 0.691, g1("M0_interaccion", "2023")$exactitud_balanceada, 3),
  fila("1", "EB M1 interaccion 2022", 0.685, g1("M1_interaccion", "2022")$exactitud_balanceada, 3),
  fila("1", "EB M1 interaccion 2023", 0.747, g1("M1_interaccion", "2023")$exactitud_balanceada, 3),
  fila("1", "AUC logistica M0 2022", 0.717, g1("M0_logistica", "2022")$auc, 3),
  fila("1", "AUC logistica M1 2022", 0.771, g1("M1_logistica", "2022")$auc, 3),
  fila("1", "AUC logistica M0 2023", 0.752, g1("M0_logistica", "2023")$auc, 3),
  fila("1", "AUC logistica M1 2023", 0.828, g1("M1_logistica", "2023")$auc, 3),
  fila("2", "sin transformar 2022", 0.7767, g2("sin_transformar", "2022"), 4),
  fila("2", "sin transformar 2023", 0.8286, g2("sin_transformar", "2023"), 4),
  fila("2", "log1p lluvia 2022", 0.7774, g2("log1p_lluvia", "2022"), 4),
  fila("2", "log1p lluvia 2023", 0.8282, g2("log1p_lluvia", "2023"), 4),
  fila("2", "llovio 2022", 0.7772, g2("llovio_en_lugar_de_horas", "2022"), 4),
  fila("2", "llovio 2023", 0.8277, g2("llovio_en_lugar_de_horas", "2023"), 4),
  fila("2", "log lluvia + log viento 2022", 0.7802, g2("log1p_lluvia_y_log_viento", "2022"), 4),
  fila("2", "log lluvia + log viento 2023", 0.8355, g2("log1p_lluvia_y_log_viento", "2023"), 4),
  fila("2", "asimetria viento (entrenamiento)", 0.37, gs(D16, "asimetria", "viento_rapidez_ms"), 2, tol = 0.05),
  fila("2", "asimetria log viento (entrenamiento)", -0.98, gs(D16, "asimetria de log", "viento_rapidez_ms"), 2, tol = 0.05),
  fila("3", "PRS anomalia: diferencia de AUC 2022", 0, tabla3[valida == "2022", diferencia], 6),
  fila("3", "PRS anomalia: diferencia de AUC 2023", 0, tabla3[valida == "2023", diferencia], 6),
  fila("3", "coef. estandarizado PRS (crudo)", -1.00, coef_d16("PRS", "coef_estandarizado"), 2),
  fila("3", "coef. estandarizado SE3", 0.40, coef_d16("estSE3", "coef_estandarizado"), 2),
  fila("3", "correlacion de estructura SE3", -0.17, coef_d16("estSE3", "correlacion_estructura"), 2),
  fila("4", "asimetria lluvia clase 0", 7.2, gs(D16, "asimetria clase 0", "horas_lluvia"), 1, tol = 0.05),
  fila("4", "asimetria lluvia clase 1", 21.1, gs(D16, "asimetria clase 1", "horas_lluvia"), 1, tol = 0.05),
  fila("4", "% dias sin lluvia (entrenamiento)", 94, gs(D16, "% de dias sin lluvia", "horas_lluvia"), 0),
  fila("4", "M de Box chi2", 3651, gs(D16, "M de Box chi2", "8 meteorologicas"), 0),
  fila("4", "M de Box gl", 36, gs(D16, "M de Box gl", "8 meteorologicas"), 0),
  fila("4", "razon DE lluvia", 0.38, gs(D16, "razon DE clase1/clase0", "horas_lluvia"), 2),
  fila("4", "razon DE rapidez viento", 1.08, gs(D16, "razon DE clase1/clase0", "viento_rapidez_ms"), 2),
  fila("4", "razon DE minima sin lluvia", 0.81, min(tabla_sup[version == D16 & medida == "razon DE clase1/clase0" & variable != "horas_lluvia", valor]), 2),
  fila("4", "razon DE maxima sin lluvia", 1.08, max(tabla_sup[version == D16 & medida == "razon DE clase1/clase0" & variable != "horas_lluvia", valor]), 2),
  fila("5", "PCA cruda: valor propio 1", 2.50, gp(D16, "cruda", "valor_propio_1"), 2),
  fila("5", "PCA cruda: valor propio 2", 1.37, gp(D16, "cruda", "valor_propio_2"), 2),
  fila("5", "PCA cruda: valor propio 3", 1.04, gp(D16, "cruda", "valor_propio_3"), 2),
  fila("5", "PCA cruda: varianza acumulada 3 (%)", 61, gp(D16, "cruda", "varianza_acum_3"), 0),
  fila("5", "PCA cruda: KMO", 0.64, gp(D16, "cruda", "kmo"), 2),
  fila("5", "PCA cruda: Bartlett chi2", 15402, gp(D16, "cruda", "bartlett_chi2"), 0),
  fila("5", "PCA anomalia: valor propio 1", 2.92, gp(D16, AN, "valor_propio_1"), 2),
  fila("5", "PCA anomalia: valor propio 2", 1.36, gp(D16, AN, "valor_propio_2"), 2),
  fila("5", "PCA anomalia: valor propio 3", 1.04, gp(D16, AN, "valor_propio_3"), 2),
  fila("5", "PCA anomalia: varianza acumulada 3 (%)", 67, gp(D16, AN, "varianza_acum_3"), 0),
  fila("5", "PCA anomalia: KMO", 0.65, gp(D16, AN, "kmo"), 2),
  fila("5", "PCA anomalia: Bartlett chi2", 24798, gp(D16, AN, "bartlett_chi2"), 0),
  fila("5", "PCA anomalia: componentes con valor propio > 1", 3, gp(D16, AN, "n_mayor_1"), 0),
  fila("5", "|carga| PC1 TOUT", 0.84, gc(D16, AN, "TOUT", "PC1"), 2),
  fila("5", "|carga| PC1 SR", 0.82, gc(D16, AN, "SR", "PC1"), 2),
  fila("5", "|carga| PC1 rapidez", 0.67, gc(D16, AN, "viento_rapidez_ms", "PC1"), 2),
  fila("5", "|carga| PC1 PRS", 0.61, gc(D16, AN, "PRS", "PC1"), 2),
  fila("5", "|carga| PC1 u", 0.64, gc(D16, AN, "viento_u", "PC1"), 2),
  fila("5", "|carga| PC2 RH", 0.67, gc(D16, AN, "RH", "PC2"), 2),
  fila("5", "|carga| PC2 lluvia", 0.48, gc(D16, AN, "horas_lluvia", "PC2"), 2),
  fila("5", "|carga| PC2 v", 0.43, gc(D16, AN, "viento_v", "PC2"), 2),
  fila("5", "|carga| PC2 u", 0.58, gc(D16, AN, "viento_u", "PC2"), 2),
  fila("5", "|carga| PC3 PRS", 0.63, gc(D16, AN, "PRS", "PC3"), 2),
  fila("5", "|carga| PC3 TOUT", 0.33, gc(D16, AN, "TOUT", "PC3"), 2),
  fila("5", "|carga| PC3 u", 0.32, gc(D16, AN, "viento_u", "PC3"), 2),
  fila("5", "|carga| PC3 rapidez", 0.43, gc(D16, AN, "viento_rapidez_ms", "PC3"), 2),
  fila("5", "|carga| PC3 lluvia", 0.34, gc(D16, AN, "horas_lluvia", "PC3"), 2),
  fila("5", "|carga| PC3 RH", 0.32, gc(D16, AN, "RH", "PC3"), 2),
  fila("5", "% varianza PC1 (anomalia)", 36, 100 * gp(D16, AN, "valor_propio_1") / 8, 0),
  fila("5", "% varianza PC2 (anomalia)", 17, 100 * gp(D16, AN, "valor_propio_2") / 8, 0),
  fila("5", "% varianza PC3 (anomalia)", 13, 100 * gp(D16, AN, "valor_propio_3") / 8, 0))
comparacion[, diferencia := valor_r - valor_md]
comparacion[, cuadra := abs(diferencia) <= tolerancia]

escribir(comparacion, "comparacion_python.csv")


# ---- Bloque 11. Veredicto ------------------------------------------------------------------------
# Si alguna cifra de la version oficial (D16) no cuadra, el script se detiene con error y
# NO se debe pasar a la fase B (07b) hasta resolverlo.
no_cuadran <- comparacion[cuadra == FALSE]
cat(sprintf("\nCifras comparadas: %d. Cuadran: %d. No cuadran: %d.\n",
            nrow(comparacion), sum(comparacion$cuadra), nrow(no_cuadran)))
if (nrow(no_cuadran)) {
  print(no_cuadran[, .(seccion, cifra, valor_md, valor_r = round(valor_r, 4), diferencia = round(diferencia, 4))])
  stop("La reproduccion en R no cuadra con decisiones_etapa3.md. NO pases a la fase B.", call. = FALSE)
}
cat("Todo cuadra con decisiones_etapa3.md (+/-0.002). Se puede cerrar la fase A.\n")
