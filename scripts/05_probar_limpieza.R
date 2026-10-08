# Pruebas sinteticas de R/limpieza.R (no usan los Excel). Falla si una regla no se comporta.
#   Rscript scripts/05_probar_limpieza.R
if (!file.exists("sima.Rproj")) stop("Ejecuta desde la raiz del proyecto.", call. = FALSE)
source("R/importar_sima.R"); source("R/diagnostico.R"); source("R/limpieza.R")
library(data.table)
rangos_op <- cargar_rangos(); rangos_fab <- cargar_rangos_fabricante()

# Serie base valida: valores dentro de rango, variables sin rachas ni saltos, NOX = NO + NO2.
base_hoja <- function(hoja, anios) {
  do.call(rbind, lapply(anios, function(a) {
    f <- seq(as.POSIXct(sprintf("%d-01-01 00:00:00", a), tz = "UTC"),
             as.POSIXct(sprintf("%d-12-31 23:00:00", a), tz = "UTC"), by = "hour")
    t <- seq_along(f)
    d <- data.frame(archivo = sprintf("BD %d.xlsx", a), hoja = hoja, anio_archivo = a,
                    fila_origen = t + 1L, fecha_hora = f, stringsAsFactors = FALSE)
    d$CO <- 1 + 0.1 * sin(t / 7); d$NO <- 5 + sin(t / 5); d$NO2 <- 20 + sin(t / 6)
    d$NOX <- d$NO + d$NO2; d$O3 <- 40 + sin(t / 9); d$PM10 <- 100 + sin(t / 4)
    d$PM2.5 <- 20 + sin(t / 3); d$PRS <- 715 + sin(t / 40); d$RAINF <- 0
    d$RH <- 50 + sin(t / 8); d$SO2 <- 3 + sin(t / 11) * 0.5
    d$SR <- ifelse((t - 1) %% 24 %in% 7:18, 0.3 + 0.1 * sin(t / 13), 0)   # cero de noche
    d$TOUT <- 20 + 5 * sin(t / 50); d$WSR <- 5 + sin(t / 12); d$WDR <- 180 + 50 * sin(t / 15)
    d
  }))
}
pos <- function(d, txt) which(format(d$fecha_hora, "%Y-%m-%d %H:%M") == txt)
ok <- function(cond, msg) { if (!isTRUE(cond)) stop("PRUEBA FALLIDA: ", msg, call. = FALSE); message("ok: ", msg) }

# 1. Hueco solo en PM2.5: el candidato imputado supera a PM10 y se revierte; PM10 intacta.
d <- base_hoja("T1", 2022); i <- 1000:1002
d$PM10[i] <- 30; d$PM2.5[i] <- NA; d$PM2.5[999] <- 20; d$PM2.5[1003] <- 80
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(all(is.na(r$imp[i, "PM2.5"])) && all(r$flags[i, "PM2.5"] == "X"), "hueco solo PM2.5: imputacion revertida (X)")
ok(all(r$imp[i, "PM10"] == 30) && all(r$flags[i, "PM10"] %in% c("V", "C")), "hueco solo PM2.5: PM10 original intacta")

# 2. Hueco solo en PM10: se revierten los candidatos < PM2.5 y se conserva el que cumple.
d <- base_hoja("T2", 2022); i <- 2000:2002
d$PM10[i] <- NA; d$PM10[1999] <- 100; d$PM10[2003] <- 22; d$PM2.5[i] <- 70
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(!is.na(r$imp[2000, "PM10"]) && r$flags[2000, "PM10"] == "I" &&
   all(r$flags[2001:2002, "PM10"] == "X") && all(r$imp[i, "PM2.5"] == 70), "hueco solo PM10: revierte lo que viola, conserva lo valido y no toca PM2.5")

# 3. Hueco que cruza 2023 (max PM10 900) -> 2024 (max 999).
d <- base_hoja("T3", 2023:2024)
a <- pos(d, "2023-12-31 22:00"); i <- a:(a + 2)
d$PM10[i] <- NA; d$PM10[a - 1] <- 880; d$PM10[a + 3] <- 990
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(all(r$flags[a:(a + 1), "PM10"] == "X") && is.na(r$imp[a, "PM10"]) && is.na(r$imp[a + 1, "PM10"]),
   "hueco entre anios: 2023 imputado > 900 se revierte")
ok(r$flags[a + 2, "PM10"] == "I" && r$imp[a + 2, "PM10"] <= 999, "hueco entre anios: valor de 2024 (<= 999) se conserva")

# 4a. O3 2020 NTE2: el maximo original (159) esta fuera de rango; el 134 NO se elimina por la nota.
d <- base_hoja("NTE2", 2020)
a <- pos(d, "2020-02-18 19:00"); d$O3[a] <- 159; d$O3[a + 1] <- 134
r <- limpiar_hoja(d, rangos_op, rangos_fab)
# (el hueco de 1 h se puede imputar despues; el motivo de invalidez queda en flags_obs)
ok(r$flags_obs[a, "O3"] == "F" && r$obs[a, "O3"] %in% NA, "nota O3: el 159 queda invalidado (F, fuera de rango)")
ok(r$flags_obs[a + 1, "O3"] %in% c("V", "C") && r$obs[a + 1, "O3"] == 134 && r$imp[a + 1, "O3"] == 134, "nota O3: el 134 sigue valido")
ok(sum(r$flags_obs[, "O3"] == "P") == 0, "nota O3: ningun otro valor eliminado por P")
# 4b. Maximo original dentro de rango: si requiere P.
d <- base_hoja("NTE2", 2020)
a <- pos(d, "2020-02-18 19:00"); d$O3[a] <- 140; d$O3[a + 1] <- 134
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(r$flags_obs[a, "O3"] == "P" && r$flags_obs[a + 1, "O3"] %in% c("V", "C") && sum(r$flags_obs[, "O3"] == "P") == 1,
   "nota O3: maximo dentro de rango se invalida con P y solo ese")

# 5. nox_inconsistente sobre valores finales: NO imputado que rompe NO + NO2 = NOX.
d <- base_hoja("T5", 2022); k <- 3000
d$NO[k] <- NA; d$NO[k - 1] <- 1; d$NO[k + 1] <- 1; d$NO2[k] <- 13.7; d$NOX[k] <- 22.4
d$NOX[3010:3020] <- NA   # hueco de 11 h: no se imputa
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(r$flags[k, "NO"] == "I" && isTRUE(r$nox_inconsistente[k] == 1L), "NOX: terna con NO imputado queda con bandera final = 1")
ok(is.na(r$nox_inconsistente[3010]), "NOX: terna incompleta queda sin bandera")
comp <- !is.na(r$imp[, "NO"]) & !is.na(r$imp[, "NO2"]) & !is.na(r$imp[, "NOX"])
ok(all(!is.na(r$nox_inconsistente[comp])) && all(is.na(r$nox_inconsistente[!comp])), "NOX: bandera definida exactamente donde la terna final es completa")

# 6. Nunca se modifica un valor original valido.
orig <- d[, c("NO", "NO2", "PM10", "PM2.5")]; g <- malla_hoja(d)$X[, c("NO", "NO2", "PM10", "PM2.5")]
for (v in colnames(g)) { m <- r$flags[, v] %in% c("V", "C"); ok(all(r$imp[m, v] == g[m, v]), paste("originales validos intactos:", v)) }

# 7. Consistencia espacial (regla E), saturacion (L) y revalidacion de imputados contra la red.
est <- paste0("R", 1:6)
red_datos <- setNames(lapply(est, function(h) base_hoja(h, 2022)), est)
d0 <- red_datos[[1]]
kE <- pos(d0, "2022-05-10 12:00"); kN <- pos(d0, "2022-05-11 12:00"); kL <- pos(d0, "2022-05-12 12:00")
kR <- pos(d0, "2022-05-13 12:00"); kI <- pos(d0, "2022-06-01 08:00")
# (un salto de >10 C en 1 h lo atrapa antes la regla S; E se prueba con una deriva en pasos de 8 C)
red_datos$R1$TOUT[kE + 0:2] <- red_datos$R1$TOUT[kE + 0:2] + c(8, 16, 16)   # +16 C sobre la red con 6 estaciones -> E
for (h in est[3:6]) red_datos[[h]]$TOUT[kN + 0:1] <- NA                    # solo 2 estaciones reportan (< 5)
red_datos$R2$TOUT[kN + 0:1] <- red_datos$R2$TOUT[kN + 0:1] + c(8, 16)      # desvio de 16 C pero n < 5: no se evalua
red_datos$R3$TOUT[kL] <- -50                                               # saturacion -> L
red_datos$R4$RH[kR] <- 95; red_datos$R5$RH[kR] <- 50; red_datos$R4$RH[kR - 1] <- 50; red_datos$R4$RH[kR + 1] <- 50
red_datos$R6$RH[kR] <- 40                                                  # (referencia: mediana ~ 50)
# R6 imputado contra la red: los demas suben en rampa (pasos < 10 C) y R6 tiene un hueco de 3 h entre 20 y 20
for (h in est[1:5]) red_datos[[h]]$TOUT[kI + (-1:3)] <- c(20, 29, 38, 38, 29)
red_datos$R6$TOUT[kI + (-1:3)] <- c(20, NA, NA, NA, 20)
fase1 <- lapply(red_datos, function(d) limpiar_hoja(d, rangos_op, rangos_fab, solo_fase1 = TRUE))
esp <- red_espacial(fase1)
rr <- lapply(red_datos, function(d) limpiar_hoja(d, rangos_op, rangos_fab, red = esp$red))
ok(all(rr$R1$flags_obs[kE + 1:2, "TOUT"] == "E") && all(is.na(rr$R1$obs[kE + 1:2, "TOUT"])), "E: TOUT a +16 C de la mediana con 6 estaciones se invalida")
ok(rr$R1$flags_obs[kE, "TOUT"] %in% c("V", "C"), "E: a +8 C (dentro del umbral) se conserva")
ok(all(rr$R2$flags_obs[kN + 0:1, "TOUT"] %in% c("V", "C")), "E: horas con < 5 estaciones no se evaluan (el valor se conserva)")
ok(rr$R3$flags_obs[kL, "TOUT"] == "L", "L: TOUT = -50 se invalida como saturacion del sensor")
ok(rr$R4$flags_obs[kR, "RH"] == "E", "E: RH a +45 pp de la mediana se invalida")
ok(rr$R6$flags[kI, "TOUT"] == "I", "E imputado: la hora dentro de 10 C de la red se conserva (I)")
ok(all(rr$R6$flags[kI + 1:2, "TOUT"] == "X") && all(is.na(rr$R6$imp[kI + 1:2, "TOUT"])), "E imputado: horas a > 10 C de la red observada se revierten (X)")
ok(rr$R6$imp[kI - 1, "TOUT"] == 20 && rr$R6$imp[kI + 3, "TOUT"] == 20, "E imputado: los originales vecinos no se tocan")

# 8. Caso de la revision (PR #7): E rechaza una lectura y deja < 5 estaciones. La hora anulada NO se imputa.
h5 <- paste0("Q", 1:5)
q <- setNames(lapply(h5, function(h) base_hoja(h, 2022)), h5)
kq <- pos(q$Q1, "2022-07-20 12:00")
for (h in h5) q[[h]]$RH[kq + (-1:1)] <- c(90, if (h == "Q1") 90 else 40, 90)   # S1: 90/90/90; S2-S5: 90/40/90
q$Q1$TOUT[kq + (-1:1)] <- c(20, -50, 20)                                         # y saturacion (L) entre dos 20 validos
f1 <- lapply(q, function(d) limpiar_hoja(d, rangos_op, rangos_fab, solo_fase1 = TRUE))
e5 <- red_espacial(f1)
rq <- lapply(q, function(d) limpiar_hoja(d, rangos_op, rangos_fab, red = e5$red))
ok(rq$Q1$flags_obs[kq, "RH"] == "E", "5 -> 4 estaciones: E rechaza el 90 % de S1 (mediana 40)")
ok(is.na(rq$Q1$imp[kq, "RH"]) && rq$Q1$flags[kq, "RH"] == "E", "5 -> 4 estaciones: la hora rechazada NO se imputa (queda NA, bandera E)")
ok(all(rq$Q2$imp[kq + (-1:1), "RH"] == c(90, 40, 90)), "5 -> 4 estaciones: las otras estaciones no cambian")
ok(rq$Q1$flags_obs[kq, "TOUT"] == "L" && is.na(rq$Q1$imp[kq, "TOUT"]) && rq$Q1$flags[kq, "TOUT"] == "L",
   "L: la hora saturada entre dos valores validos NO se imputa (queda NA, bandera L)")

# 9. D15, SR nocturna (bandera M): media 00-04 h > 0.02 con >= 3 lecturas invalida SR de todo el dia.
d <- base_hoja("T9", 2022)
a <- pos(d, "2022-03-10 00:00"); d$SR[a + 0:4] <- 0.05                        # 5 lecturas, media 0.05
b <- pos(d, "2022-03-12 00:00"); d$SR[b + 0:1] <- 0.05; d$SR[b + 2:4] <- NA     # solo 2 lecturas
c0 <- pos(d, "2022-03-14 00:00"); d$SR[c0 + 0:4] <- c(0.02, 0.02, 0.02, NA, NA)  # media = 0.02 (no >)
r <- limpiar_hoja(d, rangos_op, rangos_fab)
ok(all(r$flags[a + 0:23, "SR"] == "M") && all(is.na(r$imp[a + 0:23, "SR"])), "M: dia con media nocturna 0.05 invalida SR en las 24 h y no se imputa")
ok(all(r$flags[a + 24:47, "SR"] %in% c("V", "C")), "M: el dia siguiente no se toca")
ok(all(r$flags_obs[b + 0:1, "SR"] %in% c("V", "C")), "M: con < 3 lecturas nocturnas no se evalua")
ok(all(r$flags[b + 2:4, "SR"] == "X") && all(is.na(r$imp[b + 2:4, "SR"])), "M: imputados que elevan la media nocturna sobre 0.02 se revierten (X)")
ok(all(r$flags_obs[c0 + 0:23, "SR"] != "M"), "M: media nocturna igual a 0.02 no se invalida")

# 10. D15, viento contra la red (bandera E en WSR, WDR y u/v).
estw <- paste0("W", 1:6)
dw <- setNames(lapply(estw, function(h) base_hoja(h, 2022)), estw)
k1 <- pos(dw$W1, "2022-05-10 10:00"); dw$W1$WSR[k1 + 0:2] <- dw$W1$WSR[k1 + 0:2] + 40    # 3 horas -> dia
k2 <- pos(dw$W1, "2022-05-11 10:00"); dw$W2$WSR[k2] <- dw$W2$WSR[k2] + 40                # 1 hora -> hora
k3 <- pos(dw$W1, "2022-05-12 10:00")
for (h in c("W5", "W6")) dw[[h]]$WSR[k3 + 0:2] <- NA                                     # 4 estaciones
dw$W3$WSR[k3 + 0:2] <- dw$W3$WSR[k3 + 0:2] + 60                                          # sin evaluar
f1 <- lapply(dw, function(d) limpiar_hoja(d, rangos_op, rangos_fab, solo_fase1 = TRUE))
redw <- c(red_espacial(f1)$red, list(WSR = red_viento(f1)$red))
rw <- lapply(dw, function(d) limpiar_hoja(d, rangos_op, rangos_fab, red = redw))
dia1 <- pos(dw$W1, "2022-05-10 00:00") + 0:23
ok(all(rw$W1$flags[dia1, "WSR"] == "E") && all(rw$W1$flags[dia1, "WDR"] == "E") && all(rw$W1$flags[dia1, "f_uv"] == "E"),
   "viento: 3 horas a > 30 km/h de la red invalidan WSR, WDR y u/v de todo el dia")
ok(all(is.na(rw$W1$imp[dia1, "viento_u"])), "viento: el dia invalidado no se imputa")
ok(rw$W2$flags[k2, "WSR"] == "E" && rw$W2$flags[k2, "f_uv"] == "E" && is.na(rw$W2$imp[k2, "viento_u"]),
   "viento: una hora aislada a > 30 km/h se invalida y no se imputa")
ok(all(rw$W2$flags[setdiff(pos(dw$W1, "2022-05-11 00:00") + 0:23, k2), "WSR"] %in% c("V", "C")),
   "viento: con < 3 horas marcadas el resto del dia se conserva")
ok(all(rw$W3$flags[k3 + 0:2, "WSR"] %in% c("V", "C")), "viento: horas con < 5 estaciones no se evaluan")
ok(all(rw$W4$flags[dia1, "WSR"] %in% c("V", "C")), "viento: las otras estaciones no cambian")
message("Todas las pruebas de limpieza pasaron.")
