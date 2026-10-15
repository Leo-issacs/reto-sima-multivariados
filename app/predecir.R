# =============================================================================================
# Funciones del modelo final (M0 y M1, LDA) que comparten la app, scripts/07c y las pruebas.
# Usan solo lo guardado en output/etapa3/modelo_final.rds: no reajustan nada.
# =============================================================================================

# ---- 1. Temporada a partir de la fecha ------------------------------------------------------------
# Misma definicion que la limpieza: seca_fria (nov-feb), seca_calida (mar-may), calida_humeda (jun-oct).
temporada_de_fecha <- function(fecha) {
  m <- as.integer(format(as.Date(fecha), "%m"))
  ifelse(m %in% c(11, 12, 1, 2), "seca_fria", ifelse(m %in% 3:5, "seca_calida", "calida_humeda"))
}

# ---- 2. Matriz de predictores ---------------------------------------------------------------------
# Indicadoras de estacion y temporada (primera categoria como referencia) y, en M1, las 8
# meteorologicas. PRS entra como anomalia: se le resta la media de su estacion en el entrenamiento.
matriz_modelo <- function(mf, d, cual) {
  est <- factor(d[["estacion"]], levels = mf$niveles$estacion)
  tem <- factor(d[["temporada"]], levels = mf$niveles$temporada)
  if (anyNA(est) || anyNA(tem)) stop("Estacion o temporada desconocida.", call. = FALSE)
  x <- model.matrix(~ est + tem, data.frame(est, tem))[, -1, drop = FALSE]
  if (cual == "M1") {
    met <- do.call(cbind, lapply(mf$met, function(v) as.numeric(d[[v]])))
    colnames(met) <- mf$met
    met[, "PRS"] <- met[, "PRS"] - unname(mf$medias_prs[as.character(d[["estacion"]])])
    x <- cbind(x, met)
  }
  x
}

# ---- 3. Valores estandarizados con las medias y desviaciones del entrenamiento ---------------------
estandarizar <- function(mf, d, cual) {
  x <- matriz_modelo(mf, d, cual)
  esc <- mf$escalado[[cual]]
  stopifnot(identical(colnames(x), names(esc$medias)))
  scale(x, esc$medias, esc$desv)
}

# ---- 4. Probabilidad de superacion (posterior de la clase 1 en la LDA) ----------------------------
predecir_modelo <- function(mf, d, cual = c("M0", "M1")) {
  cual <- match.arg(cual)
  if (!isNamespaceLoaded("MASS")) loadNamespace("MASS")   # registra predict() para objetos lda
  as.vector(predict(mf$modelos[[cual]], estandarizar(mf, d, cual))$posterior[, "1"])
}

# ---- 5. Contribucion de cada variable al puntaje discriminante de M1 --------------------------------
# Coeficiente discriminante x valor estandarizado. El signo se orienta para que un valor positivo
# empuje hacia "superacion". Las indicadoras de estacion y de temporada se suman en una barra cada una.
contribuciones_m1 <- function(mf, d) {
  z <- estandarizar(mf, d, "M1")
  aporte <- sweep(z, 2, mf$modelos$M1$scaling[, 1], `*`) * mf$signo_ld1
  grupo <- ifelse(grepl("^est", colnames(z)), "estación", ifelse(grepl("^tem", colnames(z)), "temporada", colnames(z)))
  tapply(aporte[1, ], factor(grupo, levels = unique(grupo)), sum)
}
