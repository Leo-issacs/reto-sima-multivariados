# =============================================================================================
# Etapa 4, fase D: sensibilidades POSTERIORES a la evaluacion unica de la prueba con la base v2.
#
# Se decidieron despues de ver el resultado de 09a, con informacion nueva (retroalimentacion de SIMA
# del 15-oct-2026 y hallazgos de las fases B y C). Por eso NO reemplazan el analisis final
# (dAUC = 0.079 [0.054, 0.104]): se reportan aparte, declaradas como posteriores, y se anota en
# output/etapa4/registro_prueba_v2.txt.
#
#   a) SR >= 0: la imputacion diaria dejo 398 valores de SR negativos (casi todos en NO2 y NTE, cuyos
#      sensores de radiacion leen muy bajo); se truncan en 0.
#   b) Reubicaciones segun SIMA: SIMA confirmo las de SUR, SE, NE y NO (y NO3, fuera de la muestra), sin
#      fechas, y no menciono SO ni NTE. Se aplica D23 solo a SUR, SE, NE y NO, con las fechas del PIGECA;
#      SO y NTE entrenan con todos sus dias.
#   c) Sin NO2: su PM2.5 cambia de nivel entre mediados de 2023 y enero de 2025 (09f); se quita la
#      estacion del entrenamiento y de la prueba.
#
# Mismo procedimiento que 09a (funciones de R/modelo_etapa4.R; evaluar() copiada de 09a sin cambios).
# Ejecutar desde la raiz:  Rscript scripts/09e_sensibilidades_posteriores.R   (despues de 09a)
# Escribe: output/etapa4/sensibilidades_posteriores/
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y constantes (iguales a 09a) --------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
})
source("R/modelo_etapa4.R")
SALIDA <- "output/etapa4/sensibilidades_posteriores"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
ANIOS_ENTRENA <- 2021:2023; ANIOS_PRUEBA <- 2024:2025
INICIO_BLOQUES <- as.Date("2024-01-01"); N_REPLICAS <- 1000L; SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")


# ---- Bloque 1. Nota en el registro de la prueba (una sola vez) ---------------------------------------------
registro <- "output/etapa4/registro_prueba_v2.txt"
nota <- c("", "## Sensibilidades posteriores (09e)",
          "Decididas despues de ver el resultado de 09a, con la retroalimentacion de SIMA del 15-oct-2026 y hallazgos",
          "de las fases B y C (SR >= 0, reubicaciones confirmadas por SIMA, sin NO2). No reemplazan el analisis final.")
if (!any(grepl("Sensibilidades posteriores (09e)", readLines(registro, encoding = "UTF-8"), fixed = TRUE)))
  cat(nota, file = registro, sep = "\n", append = TRUE)


# ---- Bloque 2. Datos del analisis final y evaluar() (copiada de 09a) -----------------------------------------
d <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
d[, fecha := as.Date(fecha)][, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
setorder(d, estacion, fecha)
ESTACIONES <- sort(unique(d$estacion))
evaluar <- function(nombre, d, solo_sitio_valido = FALSE, y = "supera_25", metodo = "lda", dias = 14L,
                    n = N_REPLICAS, semilla = SEMILLA) {
  tr <- d[anio %in% ANIOS_ENTRENA]; te <- d[anio %in% ANIOS_PRUEBA]
  if (solo_sitio_valido) tr <- tr[sitio_valido == 1L]
  a <- prs_anomalia(tr, te)
  m0 <- ajustar(a$tr, a$te, character(), y = y, metodo = metodo)
  m1 <- ajustar(a$tr, a$te, MET, y = y, metodo = metodo)
  r <- comparar(nombre, a$te, m0, m1, y = y, dias = dias, n = n, semilla = semilla)
  r$fila[, `:=`(n_entrena = nrow(a$tr), prevalencia_entrena = m1$corte)]
  c(r, list(tr = a$tr, te = a$te, m0 = m0, m1 = m1))
}


# ---- Bloque 3. Sensibilidades -----------------------------------------------------------------------------------
res <- list()
# Analisis final, como referencia (debe dar lo mismo que 09a).
res$final <- evaluar("Análisis final (09a)", d, solo_sitio_valido = TRUE)$fila
ref <- fread("output/etapa4/prueba_v2_sensibilidades.csv")[1]
stopifnot(abs(res$final$d_auc - ref$d_auc) < 1e-12, abs(res$final$d_auc_li - ref$d_auc_li) < 1e-12)
# a) SR >= 0 en los valores imputados.
d_sr <- copy(d)
n_neg <- d_sr[imp_SR == 1L & SR < 0, .N]
d_sr[imp_SR == 1L & SR < 0, SR := 0]
res$sr <- evaluar(sprintf("a) SR imputada truncada en 0 (%d valores)", n_neg), d_sr, solo_sitio_valido = TRUE)$fila
# b) D23 solo con las reubicaciones que confirmo SIMA (SUR, SE, NE y NO; fechas del PIGECA).
REUB_SIMA <- c(NO = "2021-07-01", SE = "2021-10-01", SUR = "2021-10-01", NE = "2022-03-01")
d_sima <- copy(d)[, sitio_valido := 1L]
for (e in names(REUB_SIMA)) d_sima[estacion == e & fecha < as.Date(REUB_SIMA[[e]]), sitio_valido := 0L]
res$sima <- evaluar("b) Reubicaciones según SIMA (SUR, SE, NE, NO; SO y NTE sin quitar días)", d_sima, solo_sitio_valido = TRUE)$fila
# c) Sin NO2.
ESTACIONES <- setdiff(sort(unique(d$estacion)), "NO2")
res$sin_no2 <- evaluar("c) Sin NO2 (entrenamiento y prueba)", d[estacion != "NO2"], solo_sitio_valido = TRUE)$fila
ESTACIONES <- sort(unique(d$estacion))
tabla <- rbindlist(res, fill = TRUE)
fwrite(tabla, file.path(SALIDA, "sensibilidades_posteriores.csv"))
print(tabla[, .(analisis, n_entrena, n, auc_M0, auc_M1, d_auc, d_auc_li, d_auc_ls)])
message("Listo: ", SALIDA)
