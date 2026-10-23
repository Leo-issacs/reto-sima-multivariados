# =============================================================================================
# Etapa 4: guarda el modelo final (base v2, paso 4 de 09a) para la app Shiny.
#
# NO cambia el analisis ni vuelve a decidir nada: reajusta M0 y M1 con las mismas funciones y los
# mismos datos que 09a (R/modelo_etapa4.R; entrenamiento 2021-2023 solo con sitio_valido = 1, D23;
# base v2 imputada) y empaqueta lo que app/predecir.R necesita, con la misma estructura que
# output/etapa3/modelo_final.rds. Control: las predicciones reproducen output/etapa4/
# prueba_v2_predicciones.csv (las de 09a) hasta 1e-12 y los AUC son los reportados.
#
# Ejecutar desde la raiz del proyecto:  Rscript scripts/12_exportar_modelo_app_v2.R
# Escribe: output/etapa4/modelo_final_v2.rds
# =============================================================================================


# ---- Bloque 0. Paquetes y constantes (iguales a 09a) --------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
})
source("R/modelo_etapa4.R")
ANIOS_ENTRENA <- 2021:2023
ANIOS_PRUEBA <- 2024:2025
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")
ESTACIONES <- sort(unique(fread("data/clean/muestra_pm25_2021_2025.csv")$estacion))   # como en 09a (v12)


# ---- Bloque 1. Datos del analisis final (paso 4 de 09a) -------------------------------------------------
d <- fread("data/clean/v2/diario_v2_imputado_2021_2025.csv")[anio %in% c(ANIOS_ENTRENA, ANIOS_PRUEBA)]
d[, fecha := as.Date(fecha)]
d[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
setorder(d, estacion, fecha)
d <- d[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
entrena <- d[anio %in% ANIOS_ENTRENA & sitio_valido == 1L]      # D23: sin dias previos a la reubicacion
prueba <- d[anio %in% ANIOS_PRUEBA]
stopifnot(identical(ESTACIONES, sort(unique(d$estacion))))


# ---- Bloque 2. Ajuste de M0 y M1 (igual que evaluar() de 09a) ---------------------------------------------
a <- prs_anomalia(entrena, prueba)
tr <- a$tr; te <- a$te
m0 <- ajustar(tr, te, character())
m1 <- ajustar(tr, te, MET)
stopifnot(m0$corte == m1$corte)


# ---- Bloque 3. Paquete para la app ---------------------------------------------------------------------------
# Mismos campos que modelo_final.rds de la etapa 3 (scripts/07c). Medianas y percentiles 1-99 por
# estacion x temporada con el entrenamiento v2 (PRS original, sin restar la media del sitio).
pred <- te[, .(estacion, fecha, anio, temporada, `PM2.5`, supera_25, p_M0 = m0$p, p_M1 = m1$p)]
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
  met = MET, corte = m1$corte,
  signo_ld1 = sign(mean(ld[tr$supera_25 == 1]) - mean(ld[tr$supera_25 == 0])),
  predicciones_prueba = pred,
  entrenamiento = list(medianas = mediana_ent, rangos = rango_ent, n = nrow(tr), anios = ANIOS_ENTRENA),
  creado = list(script = "scripts/12_exportar_modelo_app_v2.R", base = "v2 (09a, paso 4)", fecha = format(Sys.time(), "%Y-%m-%d %H:%M")))


# ---- Bloque 4. Controles ----------------------------------------------------------------------------------------
# a) Las predicciones son las de 09a (no se reevalua nada: solo se comprueba que el reajuste es identico).
ref <- fread("output/etapa4/prueba_v2_predicciones.csv")[, fecha := as.Date(fecha)]
stopifnot(nrow(pred) == nrow(ref), nrow(pred) == 6863L)
chk <- merge(pred, ref[, .(estacion, fecha, r0 = p_M0, r1 = p_M1)], by = c("estacion", "fecha"))
stopifnot(nrow(chk) == nrow(ref), max(abs(chk$p_M0 - chk$r0)) < 1e-12, max(abs(chk$p_M1 - chk$r1)) < 1e-12)
# b) Los AUC y el corte son los reportados.
auc0 <- auc_proc(pred$supera_25, pred$p_M0); auc1 <- auc_proc(pred$supera_25, pred$p_M1)
stopifnot(round(auc0, 3) == 0.713, round(auc1, 3) == 0.792, round(modelo_final$corte, 3) == 0.259)
# c) Las funciones de la app, con la meteorologia original (PRS sin restar), reproducen las predicciones.
source("app/predecir.R")
crudo <- merge(pred, prueba[, c("estacion", "fecha", MET), with = FALSE], by = c("estacion", "fecha"))
stopifnot(nrow(crudo) == nrow(pred),
          max(abs(predecir_modelo(modelo_final, crudo, "M0") - crudo$p_M0)) < 1e-10,
          max(abs(predecir_modelo(modelo_final, crudo, "M1") - crudo$p_M1)) < 1e-10)
saveRDS(modelo_final, "output/etapa4/modelo_final_v2.rds")
cat(sprintf("Listo: output/etapa4/modelo_final_v2.rds (entrenamiento n = %d, prueba n = %d, corte %.3f, AUC M0 %.3f, M1 %.3f)\n",
            nrow(tr), nrow(pred), modelo_final$corte, auc0, auc1))
