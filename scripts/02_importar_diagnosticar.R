# Etapa 1, tarea A: importar los Excel SIMA y diagnosticar. NO limpia ni modifica datos.
# Ejecutar desde la raiz del proyecto:
#   SIMA_DATA_DIR="C:/ruta/a/los/BD_AAAA" Rscript scripts/02_importar_diagnosticar.R
# Lee: BD 2020..2025.xlsx, config/rangos_operacion.csv, data/metadata/inventario_archivos_inicial.csv
# Escribe: output/diagnostico/ (tablas, heatmaps y RESUMEN.md). output/ no se versiona.
if (!file.exists("sima.Rproj")) {
  stop("Abre sima.Rproj y ejecuta desde la raiz del proyecto.", call. = FALSE)
}
source("R/importar_sima.R")
source("R/diagnostico.R")

carpeta_datos <- Sys.getenv("SIMA_DATA_DIR", unset = "data/raw")
salida <- "output/diagnostico"
dir.create(file.path(salida, "heatmaps"), recursive = TRUE, showWarnings = FALSE)
escribir <- function(x, nombre) {
  utils::write.csv(x, file.path(salida, nombre), row.names = FALSE, na = "",
                   fileEncoding = "UTF-8")
}

# 0. Huellas: los Excel deben ser los inventariados el 25 de septiembre.
inv <- utils::read.csv("data/metadata/inventario_archivos_inicial.csv", stringsAsFactors = FALSE)
huellas <- tools::md5sum(file.path(carpeta_datos, inv$archivo))
huellas_ok <- unname(huellas) == inv$md5
if (!all(huellas_ok)) {
  stop("Huella distinta a la del inventario en: ",
       paste(inv$archivo[!huellas_ok], collapse = ", "), call. = FALSE)
}
message("Huellas MD5 verificadas (", nrow(inv), " archivos).")

# 1-2. Importacion sin transformar.
message("Importando hojas (aprox. 1 min)...")
imp <- suppressMessages(importar_sima(carpeta_datos))
datos <- imp$datos
rangos <- cargar_rangos()
no_num <- imp$no_numericos
if (is.null(no_num)) {
  no_num <- data.frame(archivo = character(), hoja = character(), fila_origen = integer(),
                       variable = character(), texto = character())
}

# 1. Fecha y resolucion.
fechas <- resumen_fechas(datos, imp$info)
solar <- centroide_solar(datos)
escribir(fechas, "fechas_por_hoja.csv")
escribir(solar, "centroide_solar_por_temporada.csv")

# 2-5. Diagnostico por hoja x anio.
message("Diagnosticando series...")
dg <- diagnosticar(datos, rangos, imp$no_numericos)
cobertura <- tabla_cobertura_diaria(dg$diaria)
cobertura$cumple_75 <- cobertura$pct_dias_ge18_validos >= 75
matriz <- reshape(cobertura[, c("hoja", "anio", "variable", "pct_dias_ge18_validos")],
                  idvar = c("hoja", "anio"), timevar = "variable", direction = "wide")
names(matriz) <- sub("^pct_dias_ge18_validos\\.", "", names(matriz))
matriz[VARIABLES_SIMA] <- lapply(matriz[VARIABLES_SIMA], round, 1)

escribir(no_num, "no_numericos.csv")
escribir(dg$hoja_anio, "hoja_anio_resumen.csv")
escribir(dg$bloques, "horas_ausentes_bloques.csv")
escribir(if (is.null(dg$duplicadas)) data.frame(archivo = character(), hoja = character(),
                                                 fecha_hora = character()) else dg$duplicadas,
         "marcas_duplicadas.csv")
escribir(dg$series, "series_estacion_anio_variable.csv")
escribir(cobertura, "cobertura_diaria.csv")
escribir(matriz, "cobertura_diaria_matriz_pct.csv")
escribir(dg$cobertura_conjunta, "cobertura_conjunta_dias.csv")
escribir(dg$cons_nox, "consistencia_nox.csv")
escribir(dg$cons_pm, "consistencia_pm25_pm10.csv")
escribir(dg$mensual, "faltantes_mensual.csv")

# 6. Heatmaps estacion x mes.
message("Heatmaps...")
hojas <- sort(unique(datos$hoja))
for (v in VARIABLES_SIMA) {
  heatmap_faltantes(dg$mensual, hojas, v,
                    file.path(salida, "heatmaps", paste0("faltantes_", v, ".png")))
}

# 7. Tamano estimado de los CSV.
message("Estimando tamano de CSV...")
tam <- estimar_tamanos_csv(datos)
escribir(as.data.frame(tam), "tamanos_csv_estimados.csv")

# Resumen por variable (denominadores: horas esperadas de todas las hojas-anio).
s <- dg$series
por_var <- do.call(rbind, lapply(split(s, s$variable), function(z) data.frame(
  variable = z$variable[1L], horas_esperadas = sum(z$horas_esperadas),
  horas_presentes = sum(z$horas_presentes),
  pct_faltante = 100 * (1 - sum(z$horas_presentes) / sum(z$horas_esperadas)),
  fuera_rango = sum(z$fuera_rango_bajo) + sum(z$fuera_rango_alto),
  fuera_rango_bajo = sum(z$fuera_rango_bajo), fuera_rango_alto = sum(z$fuera_rango_alto),
  pct_fuera_rango = 100 * (sum(z$fuera_rango_bajo) + sum(z$fuera_rango_alto)) / sum(z$horas_presentes),
  negativos = sum(z$negativos), rachas_horas = sum(z$rachas_horas),
  rachas_horas_no_cero = sum(z$rachas_horas_no_cero))))
por_var <- por_var[match(VARIABLES_SIMA, por_var$variable), ]
escribir(por_var, "resumen_por_variable.csv")

# ---- RESUMEN.md ------------------------------------------------------------------
n_hojas <- nrow(dg$hoja_anio); n_est <- length(hojas)
esp <- por_var$horas_esperadas[1L]
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
por_anio <- table(dg$hoja_anio$anio)
ok_tab <- xtabs(cumple_75 ~ variable + anio, cobertura)[VARIABLES_SIMA, , drop = FALSE]
ok_tot <- rowSums(ok_tab)
fila_var <- vapply(seq_len(nrow(por_var)), function(i) {
  v <- por_var$variable[i]
  sprintf("| %s | %s | %s | %s | %s | %s | %s |", v, fmt(por_var$pct_faltante[i], 1),
          fmt(por_var$pct_fuera_rango[i], 2), fmt(por_var$negativos[i]),
          fmt(por_var$rachas_horas_no_cero[i]),
          paste(ok_tab[v, ], collapse = " / "), ok_tot[v])
}, character(1L))
ausentes_tot <- sum(dg$hoja_anio$horas_ausentes)
mayor <- dg$hoja_anio[which.max(dg$hoja_anio$horas_ausentes), ]
saltos1 <- mean(fechas$pct_saltos_1h)
n_comp_nox <- sum(dg$cons_nox$horas_comparables)
n_comp_pm <- sum(dg$cons_pm$horas_comparables)
c_ver <- solar$centroide_hora[solar$temporada == "jun-ago" & solar$anio == 2020]
c_inv <- solar$centroide_hora[solar$temporada == "dic-feb" & solar$anio == 2020]
cc <- dg$cobertura_conjunta
sin_pm25 <- s$hoja[s$variable == "PM2.5" & s$horas_presentes == 0]
lineas <- c(
  "# Diagnóstico y limpieza de datos SIMA 2020–2025 (etapa 1)",
  "",
  "## Parte A. Diagnóstico de los datos originales (sin limpiar)",
  "",
  sprintf("Generado por `scripts/02_importar_diagnosticar.R` el %s. Huellas MD5 de los 6 Excel = inventario del 25-sep. Tablas y heatmaps en `output/diagnostico/`.", format(Sys.Date())),
  "",
  sprintf("**Denominadores.** %d hojas estación-año (%d estaciones; por año: %s), %s filas. Horas esperadas por variable = %s (24 × días del año de cada hoja-año, incluye horas sin fila). Cobertura diaria: %d hojas-año por variable.",
          n_hojas, n_est, paste(names(por_anio), por_anio, sep = ": ", collapse = ", "),
          fmt(nrow(datos)), fmt(esp), n_hojas),
  "",
  sprintf("**1. Fecha y resolución.** Todas las celdas de fecha son datetime nativo de Excel (%s de %s; ninguna texto). Sin zona horaria en el archivo (readxl la rotula UTC; es hora local ingenua). Nombre de columna: `Fecha y hora` (2020–24) y `date` (2025). **Resolución horaria, no diaria**: %.2f%% de los saltos entre marcas son de 1 h, todas las marcas caen en punto y la mediana es de 24 filas/día; la nota de Etiquetas sobre «promedios diarios» no describe estos archivos. Sin marcas duplicadas ni filas fuera del año; orden creciente en las %d hojas. Sin cambio de horario visible: no hay hora repetida ni ausente en abril/octubre y el centroide de SR 2020 es %.2f h (dic–feb) vs %.2f h (jun–ago), sin el salto de ~1 h que dejaría el horario de verano. Parece hora fija; confirmar con SIMA.",
          fmt(sum(fechas$fecha_celdas_datetime)), fmt(nrow(datos)), saltos1, nrow(fechas), c_inv, c_ver),
  "",
  sprintf("**2. Celdas no numéricas: %d** de %s celdas de medición (ni texto ni banderas). No hay banderas en los archivos: una celda vacía no dice si fue falla, calibración o invalidación.",
          nrow(no_num), fmt(nrow(datos) * length(VARIABLES_SIMA))),
  "",
  sprintf("**3. Faltantes, rango y rachas** (faltante: %% de %s h esperadas; fuera de rango: %% de horas presentes contra el rango de operación de ese año; rachas: horas en rachas ≥ %d h idénticas y distintas de 0; última columna: hojas-año con ≥ 75 %% de los días con ≥ %d h válidas, por año 2020/…/2025, y total sobre %d).",
          fmt(esp), RACHA_MIN_HORAS, HORAS_MIN_DIA, n_hojas),
  "",
  "| Variable | % falt. | % fuera rango | Negativos | Horas en rachas | Cobertura ≥75 % por año | Total |",
  "|---|---|---|---|---|---|---|",
  fila_var,
  "",
  sprintf("Horas sin fila: %s (%.2f%% de %s); %s son de %s %d, que empieza el %s.",
          fmt(ausentes_tot), 100 * ausentes_tot / esp, fmt(esp), fmt(mayor$horas_ausentes),
          mayor$hoja, mayor$anio, mayor$primera_marca),
  "",
  sprintf("**4. Consistencia.** |NOX − (NO + NO2)| > 1 ppb: %s de %s h comparables (%.2f%%); > 5 ppb: %s (%.2f%%). PM2.5 > PM10: %s de %s h comparables (%.3f%%). Hojas-año sin ningún valor de PM2.5: %d (hojas: %s).",
          fmt(sum(dg$cons_nox$dif_gt_1ppb)), fmt(n_comp_nox), 100 * sum(dg$cons_nox$dif_gt_1ppb) / n_comp_nox,
          fmt(sum(dg$cons_nox$dif_gt_5ppb)), 100 * sum(dg$cons_nox$dif_gt_5ppb) / n_comp_nox,
          fmt(sum(dg$cons_pm$pm25_gt_pm10)), fmt(n_comp_pm), 100 * sum(dg$cons_pm$pm25_gt_pm10) / n_comp_pm,
          sum(s$variable == "PM2.5" & s$horas_presentes == 0),
          paste(sort(unique(sin_pm25)), collapse = ", ")),
  "",
  sprintf("**5. Cobertura conjunta** (días con ≥ %d h válidas en PM10, PM2.5, O3, NO2, CO, TOUT, RH, WSR y WDR a la vez, %% de días del año): mediana por hoja-año %.0f%%; %d de %d hojas-año ≥ 75%%. Detalle en `cobertura_conjunta_dias.csv`.",
          HORAS_MIN_DIA, median(100 * cc$dias_completos_todo / cc$dias_esperados),
          sum(100 * cc$dias_completos_todo / cc$dias_esperados >= 75), nrow(cc)),
  "",
  sprintf("**6. Heatmaps** de faltantes (estación × mes, 15 variables): `output/diagnostico/heatmaps/faltantes_<VAR>.png`. **Alertas de rango:** TOUT tiene %s h bajo el mínimo del rango cuando ese mínimo es 0 (2020 y 2023; pueden ser temperaturas reales bajo cero); PRS concentra %s h fuera de rango en pocas hojas-año (p. ej. %s %d: %s h), consistente con un rango único para estaciones a distinta altitud.",
          fmt(sum(s$fuera_rango_bajo[s$variable == "TOUT" & s$rango_min == 0])),
          fmt(por_var$fuera_rango[por_var$variable == "PRS"]),
          s$hoja[s$variable == "PRS"][which.max((s$fuera_rango_bajo + s$fuera_rango_alto)[s$variable == "PRS"])],
          s$anio[s$variable == "PRS"][which.max((s$fuera_rango_bajo + s$fuera_rango_alto)[s$variable == "PRS"])],
          fmt(max((s$fuera_rango_bajo + s$fuera_rango_alto)[s$variable == "PRS"]))),
  "",
  sprintf("**7. Tamaño estimado del CSV limpio** (escrito de prueba, 15 variables a 2 decimales): horario %s filas ≈ **%.0f MB** (≈ %.0f MB con una columna bandera por variable; año mayor ≈ %.0f MB); diario %s filas ≈ **%.1f MB**. Un solo CSV horario supera 50 MB: dividir por año o publicar solo el diario.",
          fmt(tam$filas_horario), tam$mb_horario, tam$mb_horario_con_flags,
          tam$mb_horario_anio_mayor_con_flags, fmt(tam$filas_diario), tam$mb_diario)
)
con <- file(file.path(salida, "RESUMEN.md"), "w", encoding = "UTF-8")
writeLines(lineas, con)
close(con)
message("Listo: ", normalizePath(salida))
