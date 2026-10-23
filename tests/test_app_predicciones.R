# =============================================================================================
# Pruebas de la interfaz (app/). Ejecutar desde la raiz del proyecto, despues de scripts/12:
#   Rscript tests/test_app_predicciones.R
# Falla con stop() si algo no se cumple; si todo pasa, imprime "ok:" por cada prueba.
# =============================================================================================
suppressPackageStartupMessages({
  library(data.table)
  library(shiny)
})
source("app/predecir.R")
mf <- readRDS("output/etapa4/modelo_final_v2.rds")
MET <- mf$met
ok <- function(...) cat("ok:", ..., "\n")


# ---- 1. La funcion de prediccion de la app reproduce p_M0 y p_M1 de la prueba ----------------------
# Se toman 20 filas al azar de la prueba, se recupera su meteorologia original de la muestra
# (PRS sin restar) y se predice con las funciones de la app. Tolerancia 1e-10.
muestra <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[, fecha := as.Date(fecha)]
set.seed(2026)
filas <- mf$predicciones_prueba[sample.int(nrow(mf$predicciones_prueba), 20)]
filas <- merge(filas, muestra[, c("estacion", "fecha", MET), with = FALSE], by = c("estacion", "fecha"))
stopifnot(nrow(filas) == 20)
err0 <- max(abs(predecir_modelo(mf, filas, "M0") - filas$p_M0))
err1 <- max(abs(predecir_modelo(mf, filas, "M1") - filas$p_M1))
if (err0 > 1e-10 || err1 > 1e-10) stop(sprintf("Predicciones distintas: M0 %.2e, M1 %.2e", err0, err1))
stopifnot(nrow(mf$predicciones_prueba) == 6863L)
ok(sprintf("20 filas de la prueba reproducidas (error maximo M0 %.1e, M1 %.1e)", err0, err1))
# Una por una (como las pide la app) tambien coinciden.
una <- vapply(seq_len(nrow(filas)), function(i) predecir_modelo(mf, filas[i], "M1"), numeric(1))
stopifnot(max(abs(una - filas$p_M1)) < 1e-10)
ok("prediccion fila por fila igual a la de la tabla completa")


# ---- 2. Valores extremos de los deslizadores -------------------------------------------------------
# Todas las combinaciones de percentil 1 y 99 de las 8 variables (2^8 = 256), en cada estacion y
# temporada: las probabilidades deben ser numeros en [0, 1] y las contribuciones, finitas.
r <- as.data.frame(mf$entrenamiento$rangos)
extremos <- do.call(CJ, setNames(lapply(MET, function(v) c(r$p01[r$variable == v], r$p99[r$variable == v])), MET))
rejilla <- CJ(estacion = mf$niveles$estacion, temporada = mf$niveles$temporada)
d <- rejilla[rep(seq_len(.N), each = nrow(extremos))][, (MET) := extremos[rep(seq_len(nrow(extremos)), nrow(rejilla))]]
for (m in c("M0", "M1")) {
  p <- predecir_modelo(mf, d, m)
  stopifnot(length(p) == nrow(d), all(is.finite(p)), all(p >= 0 & p <= 1))
}
co <- vapply(c(1, nrow(d)), function(i) all(is.finite(contribuciones_m1(mf, d[i]))), logical(1))
stopifnot(all(co))
ok(sprintf("%s combinaciones extremas dan probabilidades en [0, 1]", format(nrow(d), big.mark = ",")))


# ---- 2b. «Todas / Todas» de la pestaña de desempeño da los AUC reportados (0.713 y 0.792) -----------
pp <- mf$predicciones_prueba
a0 <- function(y, p) { r <- rank(p); n1 <- sum(y == 1); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * (length(y) - n1)) }
stopifnot(round(a0(pp$supera_25, pp$p_M0), 3) == 0.713, round(a0(pp$supera_25, pp$p_M1), 3) == 0.792, round(mf$corte, 3) == 0.259)
ok("AUC de la prueba completa: M0 0.713, M1 0.792, corte 0.259")


# ---- 3. El servidor de la app no falla en los extremos -----------------------------------------------
# testServer() corre la logica de la app sin navegador: se fijan los deslizadores en sus limites
# y se piden las salidas (graficas, clasificacion, tabla de desempeño).
app <- shinyAppDir("app")
testServer(app, {
  for (lado in c("p01", "p99")) for (est in c(mf$niveles$estacion[1], "SE2")) {
    vals <- setNames(lapply(MET, function(v) r[[lado]][r$variable == v]), paste0("v_", MET))
    do.call(session$setInputs, c(list(estacion = est, modo = "temporada", temporada = "seca_fria",
                                      est_d = est, tem_d = "todas"), vals))
    stopifnot(all(is.finite(probs()$p)), !is.null(output$grafica_prob), !is.null(output$grafica_contrib),
              !is.null(output$clasificacion), !is.null(output$tabla_metricas), !is.null(output$serie_pm25))
  }
  session$setInputs(modo = "fecha", fecha = as.Date("2025-07-01"))
  stopifnot(temporada() == "calida_humeda", !is.null(output$grafica_prob))
  session$setInputs(est_d = "todas", tem_d = "seca_calida")
  stopifnot(!is.null(output$tabla_metricas))
})
ok("el servidor responde con deslizadores en los extremos, con fecha y con «Todas»")
cat("Todas las pruebas de la app pasaron.\n")
