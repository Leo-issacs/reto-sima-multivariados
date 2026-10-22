# =============================================================================================
# Etapa 4, fase A2 (D18, D19 y D23 de docs/etapa4/decisiones_etapa4.md): base diaria `datos-v2.0`.
#
#   - D18: el PM2.5 diario (la respuesta) se calcula SOLO con horas observadas y exige >= 18 h.
#   - D19: la meteorologia horaria se imputa con el metodo y el maxgap elegidos en 08a, por variable.
#          Se conservan las reglas de la etapa 1: nunca se imputan horas E, L ni M, y todo valor
#          imputado se revalida (si incumple una regla vuelve a NA con bandera X). Se reutilizan las
#          funciones de R/limpieza.R (reglas_hoja e imputar_y_revalidar), las mismas de 03_limpiar.R.
#   - D23: columna `sitio_valido` (0 = dia previo a la reubicacion de la estacion).
#
# La imputacion se hace por separado en 2021-2023 y en 2024-2025: asi ningun dato de la prueba
# informa a la imputacion del entrenamiento (con la interpolacion solo cambiaria en el 31-dic-2023).
# Este script no ajusta modelos ni calcula AUC.
#
# Ejecutar desde la raiz:  Rscript scripts/08b_construir_base_v2.R   (no necesita los Excel)
# Lee:     data/clean/sima_horario_limpio_2020..2025.csv, data/clean/sima_diario_2020_2025.csv,
#          data/clean/muestra_pm25_2021_2025.csv, output/etapa4/imputacion/eleccion_metodo_horario.csv
# Escribe: data/clean/v2/diario_v2_2021_2025.csv, output/etapa4/imputacion/ (comprobacion con
#          datos-v1.2, perdidas v1.2 vs v2, faltantes por variable, dias por estacion y anio)
# =============================================================================================


# ---- Bloque 0. Paquetes, funciones y carpetas ----------------------------------------------------
if (!file.exists("sima.Rproj")) stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
suppressPackageStartupMessages(library(data.table))
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R"); source("R/imputacion.R")
SALIDA <- "output/etapa4/imputacion"
dir.create(SALIDA, recursive = TRUE, showWarnings = FALSE)
dir.create("data/clean/v2", recursive = TRUE, showWarnings = FALSE)
EST <- estaciones_muestra()
UMBRAL_PM25 <- 25; UMBRAL_OMS <- 15
MAX_FALTANTES_MICE <- 4L       # D20: no se imputa un estacion-dia con mas de 4 de las 8 faltantes
rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()


# ---- Bloque 1. Datos horarios publicados (datos-v1.2) y serie sin imputar --------------------------
# Leemos 2020-2025 de TODAS las estaciones: la red (mediana por hora) que revalida los imputados usa
# todas las estaciones, igual que en la etapa 1. Despues regresamos a NA las horas que la etapa 1
# imputo (bandera I): esa es la serie validada antes de imputar.
message("Leyendo los CSV horarios 2020-2025...")
h_pub <- leer_horario_csv(2020:2025)
red <- red_desde_csv(h_pub)
h0 <- quitar_imputacion(h_pub)


# ---- Bloque 2. Comprobacion: con el metodo de la etapa 1 se reproduce datos-v1.2 -------------------
# Antes de usar las funciones con los metodos nuevos, comprobamos que con el metodo de la etapa 1
# (lineal, huecos <= 3 h, serie continua 2020-2025) reproducen lo publicado: mismas horas imputadas,
# mismas banderas I y X y mismos valores. Los CSV publican a 3 decimales, asi que aqui se interpola
# entre extremos ya redondeados y un imputado puede diferir en 0.001 (una unidad del ultimo decimal);
# esa es la unica diferencia aceptada. Si hay otra, la reconstruccion esta mal y el script se detiene.
message("Comprobando que se reproduce la imputacion de datos-v1.2...")
comprobacion <- rbindlist(lapply(EST, function(e) {
  m <- matrices_hoja(h0[estacion == e])
  rg <- reglas_hoja(m$fecha, rangos_op, rangos_fab, red)
  ir <- imputar_y_revalidar(m$V0, m$flags0, rg, METODOS_V12)
  pub <- h_pub[estacion == e]
  rbindlist(lapply(VARS_IMPUTAR, function(v) {
    a <- round(ir$imp[, v], 3); b <- pub[[v]]
    fa <- ir$flags[, if (v %in% c("viento_u", "viento_v")) "f_uv" else v]; fb <- pub[[col_bandera(v)]]
    data.table(estacion = e, variable = v, horas_imputadas_v12 = sum(fb == "I"),
               horas_imputadas_reproducidas = sum(fa == "I"),
               na_distintos = sum(is.na(a) != is.na(b)),
               valores_distintos = sum(!is.na(a) & !is.na(b) & abs(a - b) > 1e-9),
               valores_distintos_en_horas_I = sum(fb == "I" & !is.na(a) & !is.na(b) & abs(a - b) > 1e-9),
               dif_maxima = max(c(0, abs(a - b)), na.rm = TRUE),
               banderas_IX_distintas = sum((fa %in% c("I", "X")) != (fb %in% c("I", "X")) | (fa == "I") != (fb == "I")))
  }))
}))
escribir_csv(comprobacion, file.path(SALIDA, "comprobacion_reproduce_v12.csv"))
dif <- comprobacion[, .(na = sum(na_distintos), val = sum(valores_distintos), val_en_I = sum(valores_distintos_en_horas_I),
                        dif_max = max(dif_maxima), band = sum(banderas_IX_distintas))]
print(dif)
if (dif$na > 0 || dif$band > 0 || dif$val != dif$val_en_I || dif$dif_max > 0.001 + 1e-9)
  stop("La imputacion reconstruida no reproduce datos-v1.2. Ver comprobacion_reproduce_v12.csv", call. = FALSE)
message(sprintf("Reproduce datos-v1.2: mismas horas y banderas I/X; %d imputados difieren en 0.001 por el redondeo.", dif$val))


# ---- Bloque 3. Metodos elegidos en 08a (D19) -------------------------------------------------------
# Una entrada por variable horaria: metodo y maxgap. Si maxgap es 0, esa variable no se imputa.
eleccion <- fread(file.path(SALIDA, "eleccion_metodo_horario.csv"))
stopifnot(setequal(eleccion$variable, MET_HORARIA))
metodos_v2 <- setNames(lapply(MET_HORARIA, function(v) list(
  metodo = eleccion[variable == v, metodo_elegido], maxgap = as.integer(eleccion[variable == v, maxgap_h]))), MET_HORARIA)
print(eleccion[, .(variable, metodo_elegido, maxgap_h)])


# ---- Bloque 4. Imputacion horaria v2 y agregado diario ---------------------------------------------
# Por estacion y por periodo (2021-2023 y 2024-2025, por separado): se imputa la meteorologia con los
# metodos elegidos y se revalida. Los contaminantes NO se imputan, asi que el PM2.5 diario sale solo
# de horas observadas (D18). agregar_diario() es la misma funcion de la etapa 1 (>= 18 h por variable;
# la rapidez del viento sale de u y v horarios; horas_lluvia no se imputa).
PERIODOS <- list("2021-2023" = 2021:2023, "2024-2025" = 2024:2025)
h0[, anio_h := as.integer(format(fecha, "%Y"))]
conteo_imp <- list(); diarios <- list()
for (e in EST) for (p in names(PERIODOS)) {
  m <- matrices_hoja(h0[estacion == e & anio_h %in% PERIODOS[[p]]])
  rg <- reglas_hoja(m$fecha, rangos_op, rangos_fab, red)
  ir <- imputar_y_revalidar(m$V0, m$flags0, rg, metodos_v2)
  ag <- agregar_diario(m$fecha, ir$imp)
  d <- data.table(estacion = e, fecha = ag$dia)
  # set() agrega columnas por referencia (sin copiar la tabla)
  for (v in c("PM2.5", MET_DIARIA, "llovio")) set(d, j = v, value = round(ag$valores[[v]], 3))
  set(d, j = "n_horas_PM2.5", value = ag$n_horas[["PM2.5"]])
  for (v in c("TOUT", "RH", "SR", "PRS")) set(d, j = paste0("n_horas_", v), value = ag$n_horas[[v]])
  set(d, j = "n_horas_viento", value = ag$n_horas[["viento_u"]])
  set(d, j = "n_horas_RAINF", value = ag$n_horas[["RAINF"]])
  for (v in MET_HORARIA) set(d, j = paste0("n_imputadas_", v), value = colSums(matrix(ir$IMP[, v], nrow = 24L)))
  diarios[[length(diarios) + 1L]] <- d
  conteo_imp[[length(conteo_imp) + 1L]] <- data.table(
    estacion = e, periodo = p, variable = MET_HORARIA,
    horas = nrow(m$V0), faltantes_antes = colSums(is.na(m$V0[, MET_HORARIA])),
    imputadas = colSums(ir$IMP[, MET_HORARIA]), revertidas_X = colSums(ir$revertida[, MET_HORARIA]))
}
v2 <- rbindlist(diarios)
v2[, `:=`(anio = as.integer(format(fecha, "%Y")), temporada = temporada_regional(fecha))]
stopifnot(nrow(v2) == length(EST) * 1826L, !anyDuplicated(v2[, .(estacion, fecha)]))


# ---- Bloque 5. Respuesta, faltantes y sitio valido (D18, D20, D23) ----------------------------------
# supera_25 solo existe si el PM2.5 diario es valido (>= 18 h observadas). n_met_faltantes cuenta
# cuantas de las 8 meteorologicas diarias faltan; un dia con respuesta valida y 1 a 4 faltantes es
# candidato a MICE (fase B). sitio_valido = 0 en los dias previos a la reubicacion (PIGECA, p. 91):
# NO antes del 2021-07-01; SE, SO, NTE y SUR antes del 2021-10-01; NE antes del 2022-03-01.
v2[, supera_25 := as.integer(`PM2.5` > UMBRAL_PM25)]
v2[, supera_15 := as.integer(`PM2.5` > UMBRAL_OMS)]
v2[, n_met_faltantes := Reduce(`+`, lapply(MET_DIARIA, function(v) as.integer(is.na(get(v)))))]
v2[, respuesta_valida := as.integer(!is.na(`PM2.5`))]
v2[, met_completa := as.integer(n_met_faltantes == 0L)]
v2[, candidato_mice := as.integer(respuesta_valida == 1L & n_met_faltantes >= 1L & n_met_faltantes <= MAX_FALTANTES_MICE)]
REUBICACION <- c(NO = "2021-07-01", SE = "2021-10-01", SO = "2021-10-01", NTE = "2021-10-01",
                 SUR = "2021-10-01", NE = "2022-03-01")
v2[, sitio_valido := 1L]
for (e in names(REUBICACION)) v2[estacion == e & fecha < as.Date(REUBICACION[[e]]), sitio_valido := 0L]
setcolorder(v2, c("estacion", "fecha", "anio", "temporada", "PM2.5", "supera_25", "supera_15", "n_horas_PM2.5",
                  MET_DIARIA, "llovio", "n_horas_TOUT", "n_horas_RH", "n_horas_SR", "n_horas_PRS",
                  "n_horas_viento", "n_horas_RAINF", paste0("n_imputadas_", MET_HORARIA),
                  "n_met_faltantes", "respuesta_valida", "met_completa", "candidato_mice", "sitio_valido"))
setorder(v2, estacion, fecha)
escribir_csv(v2, "data/clean/v2/diario_v2_2021_2025.csv")


# ---- Bloque 6. Comparacion con datos-v1.2: perdidas ------------------------------------------------
# Mismo universo (13 estaciones x 2021-2025). En v1.2 el PM2.5 diario incluye horas imputadas <= 3 h
# y la meteorologia solo tiene imputacion lineal <= 3 h; en v2, el PM2.5 es solo observado y la
# meteorologia usa los metodos de D19.
v12 <- fread("data/clean/sima_diario_2020_2025.csv")[estacion %in% EST & anio %in% 2021:2025]
v12[, n_met_faltantes := Reduce(`+`, lapply(MET_DIARIA, function(v) as.integer(is.na(get(v)))))]
REUB_FECHA <- function(d) {
  s <- rep(1L, nrow(d))
  for (e in names(REUBICACION)) s[d$estacion == e & d$fecha < as.Date(REUBICACION[[e]])] <- 0L
  s
}
v12[, sitio_valido := REUB_FECHA(.SD)]
perdidas_base <- function(d) {
  rv <- !is.na(d[["PM2.5"]]); k <- d$n_met_faltantes
  ent <- d$anio <= 2023
  c(universo = nrow(d), respuesta_valida = sum(rv), pierde_por_pm25 = sum(!rv),
    casos_completos = sum(rv & k == 0L), con_1_a_4_faltantes = sum(rv & k >= 1L & k <= 4L),
    con_5_a_8_faltantes = sum(rv & k >= 5L), disponibles_con_mice = sum(rv & k <= 4L),
    entrenamiento_con_mice = sum(rv & k <= 4L & ent),
    entrenamiento_previo_reubicacion = sum(rv & k <= 4L & ent & d$sitio_valido == 0L),
    entrenamiento_final_d23 = sum(rv & k <= 4L & ent & d$sitio_valido == 1L),
    prueba_con_mice = sum(rv & k <= 4L & !ent))
}
etiquetas <- c(universo = "Universo (13 estaciones x 2021-2025)",
               respuesta_valida = "Con respuesta válida (PM2.5 diario con >= 18 h; v1.2 cuenta horas imputadas, v2 solo observadas)",
               pierde_por_pm25 = "Pierde por PM2.5",
               casos_completos = "Respuesta válida y las 8 meteorológicas completas (casos completos)",
               con_1_a_4_faltantes = "Respuesta válida y 1 a 4 meteorológicas faltantes (candidatos a MICE)",
               con_5_a_8_faltantes = "Respuesta válida y 5 a 8 faltantes (no se imputan)",
               disponibles_con_mice = "Disponibles tras MICE (casos completos + 1 a 4 faltantes)",
               entrenamiento_con_mice = "  de ellos en entrenamiento (2021-2023)",
               entrenamiento_previo_reubicacion = "    previos a la reubicación (sitio_valido = 0; D23, se quitan del entrenamiento)",
               entrenamiento_final_d23 = "    entrenamiento final (sitio_valido = 1)",
               prueba_con_mice = "  de ellos en prueba (2024-2025)")
p12 <- perdidas_base(v12); p2 <- perdidas_base(v2)
perdidas <- data.table(requisito = etiquetas[names(p12)], n_v12 = p12, pct_v12 = round(100 * p12 / p12[["universo"]], 1),
                       n_v2 = p2, pct_v2 = round(100 * p2 / p2[["universo"]], 1), diferencia = p2 - p12)
escribir_csv(perdidas, file.path(SALIDA, "perdidas_v12_v2.csv"))
print(perdidas)
# Comprobaciones con cifras conocidas: casos completos de v1.2 = muestra de la etapa 3 (15 390) y
# dias previos a la reubicacion en esa muestra (decisiones_etapa4.md, D23: 1 012).
muestra12 <- fread("data/clean/muestra_pm25_2021_2025.csv")
stopifnot(p12[["casos_completos"]] == nrow(muestra12))
dias_d23_v12 <- sum(REUB_FECHA(muestra12) == 0L)
message(sprintf("Dias de la muestra de la etapa 3 previos a la reubicacion: %d (D23 dice 1 012).", dias_d23_v12))


# ---- Bloque 7. Faltantes por variable entre los candidatos a MICE (tabla A2) -------------------------
# Proporcion de dias, entre los que tienen respuesta valida y 1 a 4 faltantes, en que falta cada
# variable (un dia puede faltar en varias). 08c imita este patron, con los dias de 2021-2023.
falt_var <- rbindlist(lapply(list("2021-2023" = 2021:2023, "2024-2025" = 2024:2025, "2021-2025" = 2021:2025), function(a) {
  z <- v2[candidato_mice == 1L & anio %in% a]
  data.table(variable = MET_DIARIA, dias_candidatos = nrow(z),
             dias_con_faltante = vapply(MET_DIARIA, function(v) sum(is.na(z[[v]])), 1L))
}), idcol = "periodo")
falt_var[, pct_de_candidatos := round(100 * dias_con_faltante / dias_candidatos, 1)]
escribir_csv(falt_var, file.path(SALIDA, "faltantes_por_variable_candidatos_mice.csv"))
# Patrones conjuntos (que variables faltan juntas), solo 2021-2023: los usa 08c.
patrones <- v2[candidato_mice == 1L & anio <= 2023, lapply(.SD, function(x) as.integer(is.na(x))), .SDcols = MET_DIARIA]
patrones <- patrones[, .N, by = MET_DIARIA][order(-N)]
escribir_csv(patrones, file.path(SALIDA, "patrones_faltantes_2021_2023.csv"))


# ---- Bloque 8. Dias por estacion y anio: v1.2 frente a v2 ---------------------------------------------
# v1.2 = muestra de la etapa 3; v2 en tres versiones: casos completos, con MICE (<= 4 faltantes) y el
# analisis final (con MICE y, en el entrenamiento, solo sitio_valido = 1).
v2[, final := respuesta_valida == 1L & n_met_faltantes <= MAX_FALTANTES_MICE & (anio >= 2024 | sitio_valido == 1L)]
dias <- merge(muestra12[, .(v12_muestra = .N), by = .(estacion, anio)],
              v2[, .(v2_casos_completos = sum(respuesta_valida == 1L & met_completa == 1L),
                     v2_con_mice = sum(respuesta_valida == 1L & n_met_faltantes <= MAX_FALTANTES_MICE),
                     v2_final = sum(final)), by = .(estacion, anio)],
              by = c("estacion", "anio"), all = TRUE)
for (k in names(dias)[-(1:2)]) set(dias, which(is.na(dias[[k]])), k, 0L)
dias[, diferencia_final_vs_v12 := v2_final - v12_muestra]
setorder(dias, estacion, anio)
escribir_csv(dias, file.path(SALIDA, "dias_por_estacion_anio_v12_v2.csv"))
v2[, final := NULL]


# ---- Bloque 9. Horas imputadas y revertidas: v1.2 frente a v2 ----------------------------------------
# Horas de meteorologia de las 13 estaciones en 2021-2025: faltantes antes de imputar, imputadas y
# revertidas (X) con cada base.
ci <- rbindlist(conteo_imp)[, .(faltantes_antes = sum(faltantes_antes), imputadas_v2 = sum(imputadas),
                                revertidas_X_v2 = sum(revertidas_X)), by = variable]
pub13 <- h_pub[estacion %in% EST & as.integer(format(fecha, "%Y")) >= 2021]
ci[, imputadas_v12 := vapply(variable, function(v) sum(pub13[[col_bandera(v)]] == "I"), 1L)]
ci[, revertidas_X_v12 := vapply(variable, function(v) sum(pub13[[col_bandera(v)]] == "X"), 1L)]
ci <- merge(ci, eleccion[, .(variable, metodo_elegido, maxgap_h)], by = "variable", sort = FALSE)
escribir_csv(ci, file.path(SALIDA, "imputacion_horaria_v12_v2.csv"))
print(ci)
message("Listo: data/clean/v2/diario_v2_2021_2025.csv y ", SALIDA)
