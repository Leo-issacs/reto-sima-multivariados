# =============================================================================================
# Etapa 4, fase B2: evaluacion UNICA de la prueba (2024-2025) con la base v2.
#
# Las decisiones estan cerradas en la etiqueta `etapa4-decisiones-cerradas` (docs/etapa4/
# decisiones_etapa4.md, con su registro de cambios). Aqui no se cambia ninguna: el resultado se
# reporta tal cual salga, aunque la mejora baje.
#
# Mismo procedimiento que 07b (funciones copiadas en R/modelo_etapa4.R): LDA con prior y corte = la
# prevalencia de entrenamiento, PRS como anomalia de su estacion (medias de entrenamiento), sin
# transformaciones, logistica como robustez y bootstrap pareado por bloques de 14 dias (1 000 replicas).
#
# Tabla puente: cada paso cambia UNA cosa respecto del anterior.
#   0 = datos-v1.2 (etapa 3; debe dar 0.070 [0.047, 0.094]);
#   1 = + respuesta solo con horas observadas (D18);
#   2 = + imputacion horaria D19 (base v2, casos completos);
#   3 = + imputacion diaria con la mediana de la red ajustada (D20);
#   4 = + entrenamiento sin los dias previos a la reubicacion (D23) = ANALISIS FINAL.
# Sensibilidades del analisis final: MICE (m = 20), <= 2 faltantes, PM2.5 interpolado <= 3 h y
# casos completos v2 sin imputacion diaria.
#
# Modo ensayo (para revisar el codigo sin mirar la prueba):
#   ENSAYO=1 Rscript scripts/09a_evaluar_prueba_v2.R
#   entrena con 2021-2022, "prueba" con 2023 y escribe en output/etapa4/ensayo/. No lee 2024-2025.
# Corrida oficial:
#   Rscript scripts/09a_evaluar_prueba_v2.R
#   Exige que el codigo y la base v2 esten en un commit (sin cambios pendientes). Si ya existe
#   output/etapa4/registro_prueba_v2.txt, exige MOTIVO_RECORRIDA="..." (solo para corregir errores de
#   codigo; el motivo queda en el registro).
# =============================================================================================


# ---- Bloque 0. Paquetes, modo y carpetas -------------------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages({
  library(data.table)
  library(MASS)
  library(pROC)
  library(ggplot2)
})
source("R/modelo_etapa4.R")
ENSAYO <- Sys.getenv("ENSAYO") == "1"
SALIDA <- if (ENSAYO) "output/etapa4/ensayo" else "output/etapa4"
FIGURAS <- file.path(SALIDA, "figuras")
dir.create(FIGURAS, recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) fwrite(x, file.path(SALIDA, nombre), eol = "\n")
ANIOS_ENTRENA <- if (ENSAYO) 2021:2022 else 2021:2023
ANIOS_PRUEBA <- if (ENSAYO) 2023 else 2024:2025
ANIOS <- c(ANIOS_ENTRENA, ANIOS_PRUEBA)
INICIO_BLOQUES <- as.Date(if (ENSAYO) "2023-01-01" else "2024-01-01")
N_REPLICAS <- 1000L
N_REPLICAS_MICE <- 200L     # por base imputada; 20 x 200 = 4 000 replicas combinadas
SEMILLA <- 2026L
MET <- c("TOUT", "RH", "SR", "PRS", "viento_rapidez_ms", "viento_u", "viento_v", "horas_lluvia")   # orden de 07b
TEMPORADAS <- c("calida_humeda", "seca_calida", "seca_fria")


# ---- Bloque 1. Registro de la evaluacion (antes de mirar nada) ------------------------------------------
# Se deja constancia de cuando se abrio la prueba, del commit de la etiqueta de decisiones y del commit
# del codigo. Para que ese commit sea de verdad el codigo que corrio, no se permiten cambios pendientes
# en R/, scripts/ ni data/clean/v2/. git status compara bytes en los binarios (el .csv.gz de MICE) y, si
# 08b y 08d se vuelven a correr, sus archivos pueden diferir del commit solo en los finales de linea; por
# eso un archivo cuenta como pendiente solo si su contenido sin "\r" (descomprimido si es .gz) difiere del
# de HEAD.
git_args <- c("-c", paste0("safe.directory=", normalizePath(getwd(), winslash = "/")))
git <- function(...) system2("git", c(git_args, ...), stdout = TRUE, stderr = FALSE)
contenido <- function(ruta, gz) {
  b <- readBin(ruta, "raw", file.info(ruta)$size)
  if (gz) b <- memDecompress(b, "gzip")
  b[b != as.raw(13L)]
}
igual_a_head <- function(ruta) {
  if (!file.exists(ruta)) return(FALSE)
  en_head <- tempfile(); on.exit(unlink(en_head))
  if (system2("git", c(git_args, "cat-file", "blob", paste0("HEAD:", ruta)), stdout = en_head, stderr = FALSE) != 0) return(FALSE)
  gz <- grepl("\\.gz$", ruta)
  identical(contenido(en_head, gz), contenido(ruta, gz))
}
hash_etiqueta <- git("rev-list", "-n", "1", "etapa4-decisiones-cerradas")
hash_actual <- git("rev-parse", "HEAD")
if (!length(hash_etiqueta) || !nzchar(hash_etiqueta)) stop("No encuentro la etiqueta etapa4-decisiones-cerradas.", call. = FALSE)
if (!ENSAYO) {
  pendientes <- git("status", "--porcelain", "--", "R", "scripts", "data/clean/v2")
  pendientes <- pendientes[!vapply(substring(pendientes, 4), igual_a_head, logical(1))]
  if (length(pendientes)) stop("Hay cambios sin commit en R/, scripts/ o data/clean/v2/:\n", paste(pendientes, collapse = "\n"), call. = FALSE)
  registro <- "output/etapa4/registro_prueba_v2.txt"
  motivo <- Sys.getenv("MOTIVO_RECORRIDA")
  if (file.exists(registro) && !nzchar(motivo))
    stop("La prueba v2 ya se evaluo. Para volver a correr (solo por un error de codigo) define MOTIVO_RECORRIDA.", call. = FALSE)
  entrada <- c(
    if (!file.exists(registro)) c("# Registro de la evaluacion de la prueba (2024-2025) con la base v2", "",
                                  paste("Commit de la etiqueta etapa4-decisiones-cerradas:", hash_etiqueta), ""),
    paste0("## Corrida del ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("Commit de la etiqueta etapa4-decisiones-cerradas:", hash_etiqueta),
    paste("Commit del codigo al correr:", hash_actual),
    if (nzchar(motivo)) paste("Motivo de la nueva corrida:", motivo) else "Primera (y unica prevista) evaluacion de la prueba con la base v2.",
    "")
  cat(entrada, file = registro, sep = "\n", append = TRUE)
}


# ---- Bloque 2. Datos -----------------------------------------------------------------------------------
# En modo ensayo se descartan 2024-2025 al leer cada archivo.
leer <- function(ruta) {
  d <- fread(ruta)[anio %in% ANIOS]
  d[, fecha := as.Date(fecha)]
  d[, (intersect(MET, names(d))) := lapply(.SD, as.numeric), .SDcols = intersect(MET, names(d))]
  setorder(d, estacion, fecha)
  d
}
v12 <- leer("data/clean/muestra_pm25_2021_2025.csv")                   # muestra de la etapa 3
v2 <- leer("data/clean/v2/diario_v2_2021_2025.csv")                    # D18 + D19, sin imputacion diaria
v2i <- leer("data/clean/v2/diario_v2_imputado_2021_2025.csv")          # + D20 (mediana de la red ajustada)
d12 <- leer("data/clean/sima_diario_2020_2025.csv")                    # PM2.5 de la etapa 1 (interpolado <= 3 h)
mice_l <- fread("data/clean/v2/muestra_v2_mice_m20.csv.gz")[, fecha := as.Date(fecha)][year(fecha) %in% ANIOS]
mice_l[, (MET) := lapply(.SD, as.numeric), .SDcols = MET]
if (ENSAYO && any(c(v12$anio, v2$anio, v2i$anio, d12$anio, year(mice_l$fecha)) >= 2024)) stop("El ensayo no debe leer 2024-2025.", call. = FALSE)
ESTACIONES <- sort(unique(v12$estacion))
stopifnot(identical(ESTACIONES, sort(unique(v2$estacion))))

pasos_datos <- list()
pasos_datos[["0"]] <- v12
p1 <- merge(v12[, -c("supera_25", "PM2.5")], v2[!is.na(supera_25), .(estacion, fecha, `PM2.5`, supera_25)], by = c("estacion", "fecha"))
pasos_datos[["1"]] <- p1
pasos_datos[["2"]] <- v2[respuesta_valida == 1L & met_completa == 1L]
pasos_datos[["3"]] <- v2i[respuesta_valida == 1L & met_completa_tras_imputar == 1L]
pasos_datos[["4"]] <- pasos_datos[["3"]]
for (k in names(pasos_datos)) setorder(pasos_datos[[k]], estacion, fecha)


# ---- Bloque 3. Ajuste y comparacion de M0 y M1 en un conjunto de datos ----------------------------------
# evaluar(): parte en entrenamiento y prueba, PRS como anomalia (medias del entrenamiento que queda),
#   ajusta M0 y M1 y compara con el bootstrap por bloques. `solo_sitio_valido` aplica D23: quita del
#   ENTRENAMIENTO los dias previos a la reubicacion (la prueba es toda posterior).
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


# ---- Bloque 4. Tabla puente ------------------------------------------------------------------------------
CAMBIOS <- c("0" = "datos-v1.2 (etapa 3)", "1" = "+ respuesta solo con horas observadas (D18)",
             "2" = "+ imputación horaria D19 (casos completos v2)", "3" = "+ imputación diaria con mediana de la red ajustada (D20)",
             "4" = "+ entrenamiento sin días previos a la reubicación (D23) = análisis final")
puente_res <- lapply(names(CAMBIOS), function(k) evaluar(paste("Paso", k), pasos_datos[[k]], solo_sitio_valido = k == "4"))
names(puente_res) <- names(CAMBIOS)
puente <- rbindlist(lapply(names(CAMBIOS), function(k) {
  f <- puente_res[[k]]$fila
  data.table(paso = as.integer(k), cambio = CAMBIOS[[k]], n_entrena = f$n_entrena, n_prueba = f$n,
             pct_superacion_prueba = 100 * f$prevalencia, auc_M0 = f$auc_M0, auc_M1 = f$auc_M1,
             d_auc = f$d_auc, d_auc_li = f$d_auc_li, d_auc_ls = f$d_auc_ls)
}))
escribir(puente, "tabla_puente.csv")
print(puente)
# Paso 0: debe reproducir 07b (prueba_sensibilidades.csv de la etapa 3, fila principal).
if (!ENSAYO) {
  ref <- fread("output/etapa3/prueba_sensibilidades.csv")[1]
  dif0 <- c(puente[paso == 0, d_auc] - ref$d_auc, puente[paso == 0, d_auc_li] - ref$d_auc_li, puente[paso == 0, d_auc_ls] - ref$d_auc_ls)
  if (any(abs(dif0) > 1e-12)) stop("El paso 0 no reproduce la etapa 3 (0.070 [0.047, 0.094]). Me detengo.", call. = FALSE)
  message("Paso 0 reproduce la etapa 3: ", sprintf("%.3f [%.3f, %.3f]", ref$d_auc, ref$d_auc_li, ref$d_auc_ls))
}


# ---- Bloque 5. Analisis final (paso 4): metricas, temporada, logistica, bloques y anio --------------------
fin <- puente_res[["4"]]
tr <- fin$tr; te <- fin$te; m0 <- fin$m0; m1 <- fin$m1
escribir(fin$metricas, "prueba_v2_metricas_m0_m1.csv")
escribir(fin$boot$replicas, "prueba_v2_bootstrap_replicas.csv")
print(fin$metricas)
# dAUC por temporada y por anio: mismas predicciones del modelo final, bootstrap restringido a esas filas.
sub_cmp <- function(nombre, k) comparar(nombre, te[k], list(p = m0$p[k], corte = m0$corte), list(p = m1$p[k], corte = m1$corte))$fila
por_temporada <- rbindlist(lapply(TEMPORADAS, function(tp) sub_cmp(paste("Temporada:", tp), te$temporada == tp)))
por_anio <- rbindlist(lapply(ANIOS_PRUEBA, function(an) sub_cmp(paste("Año", an), te$anio == an)))
escribir(por_temporada, "prueba_v2_dauc_por_temporada.csv")
escribir(por_anio, "prueba_v2_dauc_por_anio.csv")
logistica <- evaluar("Robustez: logística", pasos_datos[["4"]], solo_sitio_valido = TRUE, metodo = "logistica")
robustez <- rbind(fin$fila, logistica$fila,
                  comparar("Bloques de 7 días", te, m0, m1, dias = 7L)$fila,
                  comparar("Bloques de 28 días", te, m0, m1, dias = 28L)$fila, fill = TRUE)
robustez[1, analisis := "Análisis final: LDA, bloques de 14 días"]


# ---- Bloque 6. Sensibilidades del analisis final -----------------------------------------------------------
sens <- list()
# a) MICE (pmm, m = 20): en cada base se ajustan M0 y M1 sobre las MISMAS filas del analisis final; la
#    dAUC es el promedio de las 20 (regla de Rubin para la estimacion puntual) y el IC sale de los
#    percentiles de las 20 x 200 replicas del bootstrap combinadas (una semilla distinta por base).
claves <- pasos_datos[["4"]][, .(estacion, fecha)]
por_base <- lapply(sort(unique(mice_l$.imp)), function(k) {
  b <- merge(pasos_datos[["4"]][, -MET, with = FALSE], mice_l[.imp == k, c("estacion", "fecha", MET), with = FALSE], by = c("estacion", "fecha"))
  stopifnot(nrow(b) == nrow(claves))
  setorder(b, estacion, fecha)
  evaluar(paste("MICE base", k), b, solo_sitio_valido = TRUE, n = N_REPLICAS_MICE, semilla = SEMILLA + k)
})
filas_mice <- rbindlist(lapply(por_base, `[[`, "fila"))
rep_mice <- rbindlist(lapply(por_base, function(r) r$boot$replicas))
escribir(filas_mice, "prueba_v2_mice_por_base.csv")
sens$mice <- data.table(analisis = sprintf("MICE (pmm, m = %d; %d réplicas combinadas)", nrow(filas_mice), nrow(rep_mice)),
                        n = filas_mice$n[1], prevalencia = filas_mice$prevalencia[1], auc_M0 = mean(filas_mice$auc_M0),
                        auc_M1 = mean(filas_mice$auc_M1), d_auc = mean(filas_mice$d_auc),
                        d_auc_li = quantile(rep_mice$d_auc, 0.025), d_auc_ls = quantile(rep_mice$d_auc, 0.975),
                        eb_M0 = mean(filas_mice$eb_M0), eb_M1 = mean(filas_mice$eb_M1), d_eb = mean(filas_mice$d_eb),
                        d_eb_li = quantile(rep_mice$d_eb, 0.025), d_eb_ls = quantile(rep_mice$d_eb, 0.975),
                        bloques = filas_mice$bloques[1], dias_bloque = 14L, n_entrena = filas_mice$n_entrena[1],
                        prevalencia_entrena = filas_mice$prevalencia_entrena[1])
# b) Limite de <= 2 meteorologicas faltantes para imputar (D20): se quitan los dias con 3 o 4.
sens$max2 <- evaluar("Límite de ≤ 2 faltantes", pasos_datos[["4"]][n_met_faltantes <= 2L], solo_sitio_valido = TRUE)$fila
# c) Respuesta con el PM2.5 de la etapa 1 (incluye horas interpoladas <= 3 h; D18, sensibilidad).
d_interp <- merge(v2i[met_completa_tras_imputar == 1L, -c("PM2.5", "supera_25", "supera_15")],
                  d12[!is.na(`PM2.5`), .(estacion, fecha, `PM2.5`)], by = c("estacion", "fecha"))
d_interp[, supera_25 := as.integer(`PM2.5` > 25)]
setorder(d_interp, estacion, fecha)
sens$interp <- evaluar("Respuesta con PM2.5 interpolado ≤ 3 h", d_interp, solo_sitio_valido = TRUE)$fila
# d) Casos completos v2, sin imputacion diaria (con D23).
sens$cc <- evaluar("Casos completos v2 sin imputación diaria", pasos_datos[["2"]], solo_sitio_valido = TRUE)$fila
tabla_sens <- rbindlist(c(list(robustez), sens), fill = TRUE)
escribir(tabla_sens, "prueba_v2_sensibilidades.csv")
print(tabla_sens[, .(analisis, n, n_entrena, auc_M0, auc_M1, d_auc, d_auc_li, d_auc_ls)])


# ---- Bloque 7. Dias y superacion por estacion: v1.2 frente a v2 -------------------------------------------
# Para la seccion de area de estudio: dias de cada estacion en la muestra de la etapa 3 y en el analisis
# final v2 (entrenamiento con D23 + prueba), y % de dias con superacion en v2.
v2fin <- rbind(tr[, .(estacion, anio, supera_25, parte = "entrenamiento")], te[, .(estacion, anio, supera_25, parte = "prueba")])
por_est <- merge(v12[, .(dias_v12 = .N, pct_superacion_v12 = 100 * mean(supera_25)), by = estacion],
                 v2fin[, .(dias_v2 = .N, dias_v2_entrena = sum(parte == "entrenamiento"), dias_v2_prueba = sum(parte == "prueba"),
                           pct_superacion_v2 = 100 * mean(supera_25), pct_superacion_v2_prueba = 100 * mean(supera_25[parte == "prueba"])),
                       by = estacion], by = "estacion", all = TRUE)
por_est[, diferencia_dias := dias_v2 - dias_v12]
por_est <- rbind(por_est, data.table(estacion = "Total", dias_v12 = nrow(v12), pct_superacion_v12 = 100 * mean(v12$supera_25),
                                     dias_v2 = nrow(v2fin), dias_v2_entrena = nrow(tr), dias_v2_prueba = nrow(te),
                                     pct_superacion_v2 = 100 * mean(v2fin$supera_25), pct_superacion_v2_prueba = 100 * mean(te$supera_25),
                                     diferencia_dias = nrow(v2fin) - nrow(v12)))
escribir(por_est, "dias_superacion_por_estacion.csv")


# ---- Bloque 8. Predicciones del analisis final (para los diagnosticos de 09b y 09c) -------------------------
pred <- te[, .(estacion, fecha, anio, temporada, `PM2.5`, supera_25, p_M0 = m0$p, p_M1 = m1$p)]
setorder(pred, fecha, estacion)
escribir(pred, "prueba_v2_predicciones.csv")


# ---- Bloque 9. Figuras (estilo de la etapa 3) -----------------------------------------------------------------
COLORES <- c(M0 = "#0072B2", M1 = "#D55E00")
tema <- theme_minimal(base_size = 10)
roc0 <- pROC::roc(te$supera_25, m0$p, levels = c(0, 1), direction = "<", quiet = TRUE)
roc1 <- pROC::roc(te$supera_25, m1$p, levels = c(0, 1), direction = "<", quiet = TRUE)
curvas <- rbind(data.table(modelo = sprintf("M0 (AUC %.3f)", fin$fila$auc_M0), fpr = 1 - roc0$specificities, tpr = roc0$sensitivities),
                data.table(modelo = sprintf("M1 (AUC %.3f)", fin$fila$auc_M1), fpr = 1 - roc1$specificities, tpr = roc1$sensitivities))
g <- ggplot(curvas[order(modelo, fpr, tpr)], aes(fpr, tpr, colour = modelo)) +
  geom_abline(linetype = "dotted", colour = "grey50") + geom_path(linewidth = 0.8) +
  scale_colour_manual(values = unname(COLORES), name = NULL) + coord_equal() +
  labs(x = "1 − especificidad", y = "Sensibilidad", title = "Curvas ROC en la prueba (base v2, análisis final)") +
  tema + theme(legend.position = c(0.7, 0.2))
ggsave(file.path(FIGURAS, "roc_m0_m1_prueba_v2.png"), g, width = 5, height = 5, dpi = 150)
dt_temp <- copy(por_temporada)[, temporada := sub("Temporada: ", "", analisis)]
g <- ggplot(dt_temp, aes(d_auc, temporada)) + geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = d_auc_li, xmax = d_auc_ls), colour = "#D55E00") +
  labs(x = "ΔAUC (M1 − M0) e IC 95 % por bloques de 14 días", y = NULL, title = "ΔAUC por temporada en la prueba (base v2)") + tema
ggsave(file.path(FIGURAS, "dauc_temporada_v2.png"), g, width = 6, height = 3, dpi = 150)
dp <- copy(puente)[, etiqueta := factor(sprintf("%d. %s", paso, cambio), levels = rev(sprintf("%d. %s", paso, cambio)))]
g <- ggplot(dp, aes(d_auc, etiqueta)) + geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = d_auc_li, xmax = d_auc_ls), colour = "#D55E00") +
  geom_text(aes(label = sprintf("%.3f", d_auc)), vjust = -0.9, size = 3) +
  labs(x = "ΔAUC (M1 − M0) e IC 95 % por bloques de 14 días", y = NULL, title = "Tabla puente: de la etapa 3 a la base v2") + tema
ggsave(file.path(FIGURAS, "tabla_puente.png"), g, width = 8, height = 3.6, dpi = 150)
g <- ggplot(fin$boot$replicas, aes(d_auc)) + geom_histogram(bins = 40, fill = "#8CA9C9", colour = "white") +
  geom_vline(xintercept = fin$fila$d_auc, colour = "#D55E00") +
  geom_vline(xintercept = c(fin$fila$d_auc_li, fin$fila$d_auc_ls), linetype = "dashed") + geom_vline(xintercept = 0, colour = "grey30") +
  labs(x = "ΔAUC (M1 − M0)", y = "Réplicas", title = sprintf("Bootstrap por bloques de 14 días (%d réplicas), base v2", N_REPLICAS)) + tema
ggsave(file.path(FIGURAS, "bootstrap_dauc_v2.png"), g, width = 6, height = 3.8, dpi = 150)


# ---- Bloque 10. RESUMEN.md -------------------------------------------------------------------------------------
f3 <- function(x) ifelse(is.na(x), "—", sprintf("%.3f", x))
f1 <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))
fi <- function(x) format(x, big.mark = ",")
ic_txt <- function(li, ls) ifelse(is.na(li), "—", sprintf("[%.3f, %.3f]", li, ls))
tabla_md <- function(dt) c(paste0("| ", paste(names(dt), collapse = " | "), " |"),
                          paste0("|", paste(rep("---", ncol(dt)), collapse = "|"), "|"),
                          apply(dt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
pm_ <- fin$metricas
met_cols <- c("auc", "exactitud_balanceada", "sensibilidad", "especificidad", "brier")
v0 <- unlist(pm_[modelo == "M0", ..met_cols]); v1 <- unlist(pm_[modelo == "M1", ..met_cols])
t_fin <- data.table(Métrica = c("AUC", "Exactitud balanceada", "Sensibilidad", "Especificidad", "Brier"),
                    M0 = f3(v0), M1 = f3(v1), `M1 − M0` = f3(v1 - v0),
                    `IC 95 %` = c(ic_txt(fin$fila$d_auc_li, fin$fila$d_auc_ls), ic_txt(fin$fila$d_eb_li, fin$fila$d_eb_ls), "—", "—", "—"))
t_puente <- puente[, .(Paso = paso, Cambio = cambio, `n entrenamiento` = fi(n_entrena), `n prueba` = fi(n_prueba),
                       `% superación (prueba)` = f1(pct_superacion_prueba), `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1),
                       `ΔAUC [IC 95 %]` = paste(f3(d_auc), ic_txt(d_auc_li, d_auc_ls)))]
t_sub <- function(d, col) d[, .(Grupo = sub("^(Temporada: |Año )", "", analisis), n = fi(n), `% superación` = f1(100 * prevalencia),
                                `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1), `ΔAUC [IC 95 %]` = paste(f3(d_auc), ic_txt(d_auc_li, d_auc_ls)))] |> setnames("Grupo", col)
t_sens <- tabla_sens[, .(Análisis = analisis, `n entrenamiento` = fi(n_entrena), `n prueba` = fi(n), `AUC M0` = f3(auc_M0), `AUC M1` = f3(auc_M1),
                         `ΔAUC [IC 95 %]` = paste(f3(d_auc), ic_txt(d_auc_li, d_auc_ls)))]
t_sens[Análisis %in% c("Bloques de 7 días", "Bloques de 28 días"), `n entrenamiento` := fi(fin$fila$n_entrena)]
t_est <- por_est[, .(Estación = estacion, `Días v1.2` = fi(dias_v12), `Días v2` = fi(dias_v2), Diferencia = fi(diferencia_dias),
                     `% superación v1.2` = f1(pct_superacion_v12), `% superación v2` = f1(pct_superacion_v2),
                     `% superación v2 (prueba)` = f1(pct_superacion_v2_prueba))]
lineas <- c(
  if (ENSAYO) "# ENSAYO (entrena 2021–2022, «prueba» 2023): no es la evaluación oficial" else "# Etapa 4 · Evaluación única de la prueba (2024–2025) con la base v2",
  "",
  sprintf("Generado por `scripts/09a_evaluar_prueba_v2.R` el %s. Decisiones cerradas en la etiqueta `etapa4-decisiones-cerradas` (commit `%s`); código al correr: `%s`. Mismo procedimiento que la etapa 3 (07b): LDA con prior y corte = prevalencia de entrenamiento, PRS como anomalía de su estación con medias de entrenamiento, sin transformaciones; bootstrap pareado por bloques de 14 días (%d réplicas, semilla %d) con predicciones fijas.",
          format(Sys.time(), "%Y-%m-%d %H:%M"), substr(hash_etiqueta, 1, 7), substr(hash_actual, 1, 7), N_REPLICAS, SEMILLA),
  "", "## 1. Tabla puente", "", "Cada paso cambia una sola cosa respecto del anterior.", "", tabla_md(t_puente), "",
  if (!ENSAYO) "El paso 0 reproduce exactamente la etapa 3 (comprobado contra `output/etapa3/prueba_sensibilidades.csv`)." else "",
  "", "## 2. Análisis final (paso 4)", "",
  sprintf("Entrenamiento %s (n = %s, solo `sitio_valido` = 1; prevalencia %.3f = corte), prueba %s (n = %s, %.1f %% de superación).",
          paste(range(ANIOS_ENTRENA), collapse = "–"), fi(nrow(tr)), m1$corte, paste(range(ANIOS_PRUEBA), collapse = "–"), fi(nrow(te)), 100 * mean(te$supera_25)),
  "", tabla_md(t_fin), "",
  "**ΔAUC por temporada** (descriptivo):", "", tabla_md(t_sub(por_temporada, "Temporada")), "",
  "**ΔAUC por año de la prueba:**", "", tabla_md(t_sub(por_anio, "Año")), "",
  "## 3. Robustez y sensibilidades", "",
  "Todas con el entrenamiento del análisis final (D23); la de MICE promedia 20 bases y combina 20 × 200 réplicas.", "",
  tabla_md(t_sens), "",
  "## 4. Días y superación por estación (v1.2 frente a v2)", "",
  "v1.2 = muestra de la etapa 3 (2021–2025); v2 = análisis final (entrenamiento con D23 + prueba).", "",
  tabla_md(t_est), "",
  "## 5. Figuras", "",
  "`figuras/tabla_puente.png`, `figuras/roc_m0_m1_prueba_v2.png`, `figuras/dauc_temporada_v2.png`, `figuras/bootstrap_dauc_v2.png`.")
con <- file(file.path(SALIDA, "RESUMEN.md"), "w", encoding = "UTF-8"); writeLines(lineas, con); close(con)
if (!ENSAYO) cat("Salidas escritas. Resultados en output/etapa4/RESUMEN.md\n", file = "output/etapa4/registro_prueba_v2.txt", append = TRUE)
cat("Listo:", SALIDA, "\n")
