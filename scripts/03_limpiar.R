# Etapa 1, tarea B: limpieza, agregado diario y CSV publicables. No modifica los Excel.
# Ejecutar desde la raiz:  SIMA_DATA_DIR="C:/ruta" Rscript scripts/03_limpiar.R
# Escribe data/clean/ (CSV publicables) y output/diagnostico/ (sensibilidades y nucleos).
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R")

carpeta_datos <- Sys.getenv("SIMA_DATA_DIR", unset = "data/raw")
dir.create("data/clean", showWarnings = FALSE)
dir.create("output/diagnostico", recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, ruta) {
  utils::write.csv(x, ruta, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
redondear <- function(x) round(x, 3)

verificar_huellas(carpeta_datos)
message("Importando hojas (aprox. 1 min)...")
imp <- suppressMessages(importar_sima(carpeta_datos))
rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()

message("Limpiando por estacion...")
hojas <- sort(unique(imp$datos$hoja))
res <- setNames(lapply(hojas, function(h) {
  limpiar_hoja(imp$datos[imp$datos$hoja == h, ], rangos_op, rangos_fab)
}), hojas)

# ---- Tabla horaria (una fila por estacion-hora de la malla completa del anio) ----------
cols_val <- c(VARIABLES_SIMA, "viento_u", "viento_v")
horario <- do.call(rbind, lapply(hojas, function(h) {
  r <- res[[h]]
  fl <- r$flags[, c(VARIABLES_SIMA, "f_uv")]
  colnames(fl) <- c(paste0("f_", VARIABLES_SIMA), "f_uv")
  # WSR/WDR se publican validados pero sin imputar; el resto, ya interpolado
  val <- r$imp[, cols_val]; val[, c("WSR", "WDR")] <- r$obs[, c("WSR", "WDR")]
  d <- data.frame(estacion = h, fecha_hora = format(r$fecha, "%Y-%m-%d %H:%M:%S"),
                  anio = r$anio, stringsAsFactors = FALSE)
  d$confinamiento_2020 <- as.integer(r$fecha >= as.POSIXct("2020-04-01", tz = "UTC") &
                                       r$fecha < as.POSIXct("2020-06-01", tz = "UTC"))
  cbind(d, as.data.frame(apply(val, 2L, redondear)), as.data.frame(fl, stringsAsFactors = FALSE),
        nox_inconsistente = r$nox_inconsistente)
}))
stopifnot(anyDuplicated(names(horario)) == 0L)

for (a in sort(unique(horario$anio))) {
  d <- horario[horario$anio == a, setdiff(names(horario), "anio")]
  data.table::fwrite(d, sprintf("data/clean/sima_horario_limpio_%d.csv", a))
}

# ---- Tabla diaria ------------------------------------------------------------------------
diario_hoja <- function(h, version) {
  r <- res[[h]]; M <- if (version == "imp") r$imp else r$obs_completa
  ag <- agregar_diario(r$fecha, M)
  n <- length(ag$dia)
  d <- data.frame(estacion = h, fecha = ag$dia, anio = as.integer(format(ag$dia, "%Y")),
                  stringsAsFactors = FALSE)
  d$temporada <- temporada_regional(d$fecha)
  d$confinamiento_2020 <- as.integer(d$fecha >= as.Date("2020-04-01") & d$fecha <= as.Date("2020-05-31"))
  orden <- c("CO", "NO", "NO2", "NOX", "O3_max8h", "PM10", "PM2.5", "SO2", "TOUT", "RH", "SR",
             "PRS", "RAINF_suma", "RAINF_max_h", "viento_u", "viento_v", "viento_rapidez_ms")
  for (v in orden) d[[v]] <- redondear(ag$valores[[v]])
  nh <- ag$n_horas
  names(nh)[names(nh) == "viento_u"] <- "viento"
  nh$viento_v <- NULL
  for (v in names(nh)) d[[paste0("n_horas_", v)]] <- nh[[v]]
  d$n_horas_nox_inconsistente <- colSums(matrix(r$nox_inconsistente, nrow = 24L), na.rm = TRUE)
  d
}
for (h in hojas) res[[h]]$obs_completa <- res[[h]]$obs   # matriz sin imputar (con u/v)
diario <- do.call(rbind, lapply(hojas, diario_hoja, version = "imp"))
diario_obs <- do.call(rbind, lapply(hojas, diario_hoja, version = "obs"))
data.table::fwrite(diario, "data/clean/sima_diario_2020_2025.csv")

# ---- Cobertura de dias validos por hoja-anio x variable -----------------------------------
var_dia <- c(CO = "CO", NO = "NO", NO2 = "NO2", NOX = "NOX", O3 = "O3_max8h", PM10 = "PM10",
             PM2.5 = "PM2.5", SO2 = "SO2", TOUT = "TOUT", RH = "RH", SR = "SR", PRS = "PRS",
             RAINF = "RAINF_suma", viento_uv = "viento_u")
dia_valido <- function(d, v) !is.na(d[[var_dia[[v]]]])
cob <- do.call(rbind, lapply(names(var_dia), function(v) {
  z <- aggregate(list(dias_validos = dia_valido(diario, v)),
                 diario[c("estacion", "anio")], sum)
  z$dias_totales <- as.vector(table(diario$estacion, diario$anio)[cbind(z$estacion, as.character(z$anio))])
  z$variable <- v
  z
}))
cob$pct_dias_validos <- round(100 * cob$dias_validos / cob$dias_totales, 1)
cob$cobertura_baja <- as.integer(cob$pct_dias_validos < 75)
cob <- cob[order(cob$estacion, cob$anio, match(cob$variable, names(var_dia))),
           c("estacion", "anio", "variable", "dias_totales", "dias_validos", "pct_dias_validos", "cobertura_baja")]
escribir(cob, "data/clean/cobertura_dias_validos_hoja_anio.csv")

# ---- Paso 0: dias completos por nucleo (estacion x anio x temporada) -----------------------
var_dia_n <- c(PM10 = "PM10", O3_max8h = "O3_max8h", NO2 = "NO2", CO = "CO", SO2 = "SO2",
               TOUT = "TOUT", RH = "RH", SR = "SR", viento_u = "viento_u", PRS = "PRS",
               RAINF = "RAINF_suma", PM2.5 = "PM2.5")
comp_n <- function(d, vars) Reduce(`&`, lapply(vars, function(v) !is.na(d[[var_dia_n[[v]]]])))
claves <- c("estacion", "anio", "temporada")
nucleo <- function(d, sufijo) {
  z <- data.frame(d[claves], A = comp_n(d, NUCLEO_A), B = comp_n(d, NUCLEO_B))
  z <- aggregate(cbind(A, B) ~ estacion + anio + temporada, z, sum)
  names(z)[4:5] <- paste0(c("dias_completos_A", "dias_completos_B"), sufijo)
  z
}
tot <- aggregate(list(dias_totales = diario$fecha), diario[claves], length)
nuc <- Reduce(function(a, b) merge(a, b, by = claves),
              list(tot, nucleo(diario, ""), nucleo(diario_obs, "_sin_imputar")))
nuc$pct_A <- round(100 * nuc$dias_completos_A / nuc$dias_totales, 1)
nuc$pct_B <- round(100 * nuc$dias_completos_B / nuc$dias_totales, 1)
nuc <- nuc[order(nuc$estacion, nuc$anio, nuc$temporada), ]
escribir(nuc, "output/diagnostico/dias_completos_nucleo.csv")

# ---- Tabla para el informe: flujo de cada variable -------------------------------------------
fl_obs <- do.call(rbind, lapply(hojas, function(h) cbind(res[[h]]$flags_obs)))
fl_fin <- do.call(rbind, lapply(hojas, function(h) cbind(res[[h]]$flags)))
den <- nrow(fl_obs)
filas <- lapply(c(VARIABLES_SIMA, "f_uv"), function(v) {
  o <- fl_obs[, v]; f <- fl_fin[, v]
  n <- function(cod) sum(o == cod)
  invalida <- n("N") + n("F") + n("P") + n("S") + n("R") + n("K")
  data.frame(
    variable = sub("^f_", "", v), horas_esperadas = den,
    faltante_original_n = n("N"), invalidada_F_rango_n = n("F"), invalidada_P_nota_pdf_n = n("P"),
    invalidada_S_salto_n = n("S"), invalidada_R_pm25_gt_pm10_n = n("R"),
    invalidada_K_racha24_n = n("K"), marcada_C_racha6_conservada_n = sum(f == "C"),
    imputada_n = sum(f == "I"), faltante_final_n = invalida - sum(f == "I"),
    stringsAsFactors = FALSE)
})
tab <- do.call(rbind, filas)
tab$variable[tab$variable == "uv"] <- "viento_uv"
for (k in grep("_n$", names(tab), value = TRUE)) tab[[sub("_n$", "_pct", k)]] <- round(100 * tab[[k]] / den, 3)
stopifnot(all(tab$faltante_final_n >= 0))
escribir(tab, "data/clean/tabla_informe_limpieza.csv")

# ---- Sensibilidad TOUT/PRS: rango de operacion estricto vs rango adoptado ------------------
sens <- do.call(rbind, lapply(res, `[[`, "sens"))
sens_t <- do.call(rbind, lapply(split(sens, list(sens$variable, sens$anio)), function(z) data.frame(
  variable = z$variable[1L], anio = z$anio[1L], horas_validas_adoptado = nrow(z),
  fuera_operacion_bajo = sum(z$bajo), fuera_operacion_alto = sum(z$alto),
  eliminadas_con_operacion_estricta = sum(z$bajo) + sum(z$alto),
  pct = round(100 * (sum(z$bajo) + sum(z$alto)) / nrow(z), 3))))
tot_s <- do.call(rbind, lapply(split(sens_t, sens_t$variable), function(z) data.frame(
  variable = z$variable[1L], anio = "total", horas_validas_adoptado = sum(z$horas_validas_adoptado),
  fuera_operacion_bajo = sum(z$fuera_operacion_bajo), fuera_operacion_alto = sum(z$fuera_operacion_alto),
  eliminadas_con_operacion_estricta = sum(z$eliminadas_con_operacion_estricta),
  pct = round(100 * sum(z$eliminadas_con_operacion_estricta) / sum(z$horas_validas_adoptado), 3))))
sens_t$anio <- as.character(sens_t$anio)
escribir(rbind(sens_t, tot_s), "output/diagnostico/sensibilidad_rango_TOUT_PRS.csv")

# ---- Consistencia NOX por estacion (con la tolerancia adoptada) --------------------------------
nox <- do.call(rbind, lapply(hojas, function(h) {
  r <- res[[h]]
  do.call(rbind, lapply(split(r$nox_inconsistente, r$anio), function(z) data.frame(
    horas_comparables = sum(!is.na(z)), inconsistentes = sum(z == 1, na.rm = TRUE))))
}))
nox$estacion <- rep(hojas, times = vapply(hojas, function(h) length(unique(res[[h]]$anio)), 1L))
nox$anio <- unlist(lapply(hojas, function(h) sort(unique(res[[h]]$anio))))
por_est <- aggregate(cbind(horas_comparables, inconsistentes) ~ estacion, nox, sum)
por_est$pct_inconsistente <- round(100 * por_est$inconsistentes / por_est$horas_comparables, 2)
escribir(por_est, "output/diagnostico/nox_inconsistencia_por_estacion.csv")
nox$pct_inconsistente <- round(100 * nox$inconsistentes / nox$horas_comparables, 2)
escribir(nox[c("estacion", "anio", "horas_comparables", "inconsistentes", "pct_inconsistente")],
         "output/diagnostico/nox_inconsistencia_por_estacion_anio.csv")

# ---- Distribucion de RAINF (sin conversion) -----------------------------------------------------
lluvia <- do.call(rbind, lapply(hojas, function(h) data.frame(
  anio = res[[h]]$anio, x = res[[h]]$obs[, "RAINF"])))
lluvia <- lluvia[!is.na(lluvia$x), ]
resumen_ll <- function(z, etiqueta) {
  p <- z$x[z$x > 0]
  top <- sort(table(p), decreasing = TRUE)[1:6]
  data.frame(anio = etiqueta, horas_validas = nrow(z), maximo = max(z$x),
             pct_horas_mayor_0 = round(100 * mean(z$x > 0), 2),
             minimo_positivo = min(p), mediana_positivos = median(p),
             p90_positivos = unname(quantile(p, 0.90)), p99_positivos = unname(quantile(p, 0.99)),
             valores_positivos_mas_frecuentes = paste0(names(top), " (", as.integer(top), ")", collapse = "; "))
}
ll <- rbind(do.call(rbind, lapply(sort(unique(lluvia$anio)), function(a)
  resumen_ll(lluvia[lluvia$anio == a, ], as.character(a)))), resumen_ll(lluvia, "total"))
escribir(ll, "output/diagnostico/rainf_distribucion.csv")

# ---- Resumen en consola para revisar --------------------------------------------------------------
message("Filas horario: ", nrow(horario), "; diario: ", nrow(diario))
message("Archivos escritos en data/clean/ y output/diagnostico/.")
saveRDS(list(tab = tab, nuc = nuc), file.path(tempdir(), "resumen_limpieza.rds"))
print(tab[, c("variable", "faltante_original_pct", "invalidada_F_rango_pct", "invalidada_P_nota_pdf_pct",
              "invalidada_S_salto_pct", "invalidada_R_pm25_gt_pm10_pct", "invalidada_K_racha24_pct",
              "imputada_pct", "faltante_final_pct")], row.names = FALSE)
