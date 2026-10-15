# =============================================================================================
# Interfaz grafica del modelo final de la etapa 3 (reto SIMA).
#
# Usa el modelo congelado de output/etapa3/modelo_final.rds (lo escribe scripts/07c): no reentrena.
# Para correrla desde la raiz del proyecto:  shiny::runApp("app")
# Pestañas: «Calcular» (probabilidad para una combinacion de valores), «Desempeño 2024–2025»
# (metricas y serie de tiempo de la prueba) y «Acerca de».
# =============================================================================================


# ---- 1. Paquetes, funciones y modelo ---------------------------------------------------------
# predecir.R tiene las funciones de prediccion; las mismas que verifican scripts/07c y las pruebas.
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(ggplot2)
})
source("predecir.R", local = TRUE)
# Si la app se publica sola, modelo_final.rds va junto a app.R; en el repositorio se lee de output/.
ruta_modelo <- if (file.exists("modelo_final.rds")) "modelo_final.rds" else "../output/etapa3/modelo_final.rds"
mf <- readRDS(ruta_modelo)
# Las tablas se usan como data.frame comunes (mas simple de indexar en la app).
mf$entrenamiento$medianas <- as.data.frame(mf$entrenamiento$medianas)
mf$entrenamiento$rangos <- as.data.frame(mf$entrenamiento$rangos)
mf$predicciones_prueba <- as.data.frame(mf$predicciones_prueba)
MET <- mf$met
CORTE <- mf$corte
pred <- mf$predicciones_prueba
REPO <- "https://github.com/Leo-issacs/reto-sima-multivariados"


# ---- 2. Textos y formatos de la interfaz -----------------------------------------------------------
NOMBRES <- c(TOUT = "Temperatura (°C)", RH = "Humedad relativa (%)", SR = "Radiación solar (kW/m²)",
             PRS = "Presión atmosférica (mm Hg)", viento_rapidez_ms = "Rapidez del viento (m/s)",
             viento_u = "Viento u, este–oeste (m/s)", viento_v = "Viento v, norte–sur (m/s)",
             horas_lluvia = "Horas con lluvia en el día")
PASO <- c(TOUT = 0.1, RH = 0.5, SR = 0.005, PRS = 0.1, viento_rapidez_ms = 0.05, viento_u = 0.05,
          viento_v = 0.05, horas_lluvia = 1)
TEMPORADAS <- c("Seca fría (nov–feb)" = "seca_fria", "Seca cálida (mar–may)" = "seca_calida",
                "Cálida húmeda (jun–oct)" = "calida_humeda")
AVISO <- "Clasificación retrospectiva con meteorología observada. No es un pronóstico."
COLORES <- c(M0 = "#0072B2", M1 = "#D55E00")
tema <- theme_minimal(base_size = 15)
pct <- function(x) sprintf("%.1f %%", 100 * x)

# Valores iniciales y rangos de los deslizadores: mediana de la estacion x temporada y percentiles
# 1-99 del entrenamiento (2021-2023).
valor_inicial <- function(estacion, temporada, v) {
  m <- mf$entrenamiento$medianas
  x <- m[m$estacion == estacion & m$temporada == temporada, v]
  if (!length(x)) x <- median(m[[v]])
  r <- mf$entrenamiento$rangos[mf$entrenamiento$rangos$variable == v, ]
  min(max(x, r$p01), r$p99)
}

# Metricas de un subconjunto de la prueba con el corte fijo.
metricas_sub <- function(d) {
  fila <- function(p) {
    y <- d$supera_25; clase <- p >= CORTE
    auc <- if (length(unique(y)) == 2) { r <- rank(p); n1 <- sum(y == 1); n0 <- sum(y == 0)
      (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) } else NA
    sens <- if (any(y == 1)) mean(clase[y == 1]) else NA
    espe <- if (any(y == 0)) mean(!clase[y == 0]) else NA
    c(AUC = auc, `Exactitud balanceada` = mean(c(sens, espe)), Sensibilidad = sens, Especificidad = espe,
      Brier = mean((p - y)^2), VP = sum(clase & y == 1), FN = sum(!clase & y == 1),
      FP = sum(clase & y == 0), VN = sum(!clase & y == 0))
  }
  m <- rbind(M0 = fila(d$p_M0), M1 = fila(d$p_M1))
  out <- data.frame(Métrica = colnames(m), M0 = m["M0", ], M1 = m["M1", ], check.names = FALSE, row.names = NULL)
  dec <- out$Métrica %in% c("AUC", "Exactitud balanceada", "Sensibilidad", "Especificidad", "Brier")
  out$M0 <- ifelse(dec, sprintf("%.3f", out$M0), sprintf("%.0f", out$M0))
  out$M1 <- ifelse(dec, sprintf("%.3f", out$M1), sprintf("%.0f", out$M1))
  out[out == "NA"] <- "—"
  out
}


# ---- 3. Interfaz (UI) ------------------------------------------------------------------------------
ui <- page_navbar(
  id = "pestana", fillable = FALSE,
  title = "Superación de PM2.5 en el AMM",
  theme = bs_theme(version = 5, bootswatch = "flatly", base_font = font_collection("Segoe UI", "Arial", "sans-serif"),
                   font_scale = 1.1),

  # 3a. Calcular: elegir estacion, temporada (o fecha) y meteorologia.
  nav_panel("Calcular", value = "calcular",
    layout_sidebar(
      sidebar = sidebar(width = 360,
        selectInput("estacion", "Estación", choices = mf$niveles$estacion, selected = "CE"),
        radioButtons("modo", "Definir la temporada por", c("Temporada" = "temporada", "Fecha" = "fecha"), inline = TRUE),
        conditionalPanel("input.modo == 'temporada'", selectInput("temporada", "Temporada", TEMPORADAS)),
        conditionalPanel("input.modo == 'fecha'", dateInput("fecha", "Fecha", value = "2024-03-15", language = "es")),
        actionButton("reiniciar", "Volver a las medianas", class = "btn-outline-secondary btn-sm"),
        hr(),
        uiOutput("deslizadores")),
      div(class = "alert alert-warning fs-5", AVISO),
      layout_columns(col_widths = c(6, 6),
        card(card_header("Probabilidad de superación (PM2.5 > 25 µg/m³)"),
             plotOutput("grafica_prob", height = "300px"), uiOutput("clasificacion")),
        card(card_header("Contribución de cada variable al puntaje de M1"),
             plotOutput("grafica_contrib", height = "300px"),
             p(class = "text-muted small", "Coeficiente discriminante × valor estandarizado (0 = media del entrenamiento).",
               "Positivo empuja hacia superación.")))
    )),

  # 3b. Desempeño en la prueba 2024-2025.
  nav_panel("Desempeño 2024–2025", value = "desempeno",
    layout_sidebar(
      sidebar = sidebar(width = 300,
        selectInput("est_d", "Estación", choices = c("Todas" = "todas", mf$niveles$estacion), selected = "CE"),
        selectInput("tem_d", "Temporada", choices = c("Todas" = "todas", TEMPORADAS)),
        p(class = "text-muted", sprintf("Corte de clasificación: %.3f (prevalencia del entrenamiento).", CORTE))),
      layout_columns(col_widths = c(4, 8),
        card(card_header(textOutput("titulo_tabla")), tableOutput("tabla_metricas")),
        card(card_header("PM2.5 observado y probabilidad de M1"),
             plotOutput("serie_pm25", height = "260px"), plotOutput("serie_prob", height = "220px")))
    )),

  # 3c. Acerca de.
  nav_panel("Acerca de", value = "acerca",
    div(class = "container", style = "max-width: 900px; font-size: 1.1rem;",
      h3("Datos"),
      p("Muestra de la etapa 2: 13 estaciones del SIMA (sin NE3 ni NO3), 2021–2025, días con PM2.5 diario válido (≥ 18 h)",
        sprintf("y los 8 predictores meteorológicos completos. Entrenamiento: 2021–2023 (%s días). Prueba: 2024–2025 (%s días), evaluada una sola vez.",
                format(mf$entrenamiento$n, big.mark = " "), format(nrow(pred), big.mark = " "))),
      h3("Modelo"),
      p("Análisis discriminante lineal (LDA) con prior igual a la prevalencia del entrenamiento.",
        "M0 usa solo estación y temporada; M1 agrega temperatura, humedad, radiación, presión (como anomalía de su estación),",
        "rapidez y componentes del viento y horas con lluvia, sin transformaciones. Corte de clasificación:", sprintf("%.3f.", CORTE)),
      h3("Limitaciones"),
      tags$ul(
        tags$li(AVISO, "Usa la meteorología medida ese día, que no se conoce de antemano."),
        tags$li("Asociación, no causalidad. «Superación» es PM2.5 diario > 25 µg/m³, una referencia fija de comparación, no una evaluación normativa."),
        tags$li("Las probabilidades de la LDA no están bien calibradas (pendiente de recalibración ≈ 0.76): úsalas para ordenar días, no como frecuencias exactas."),
        tags$li("La normalidad multivariada no se cumple; los residuos están correlacionados en el tiempo y entre estaciones."),
        tags$li("Los deslizadores de viento son independientes; en datos reales la rapidez media es al menos la magnitud del vector (u, v)."),
        tags$li("SIMA renovó sensores de viento en 2021 y equipos de PM2.5 en 2025 en algunas estaciones (ver RESUMEN_DIAGNOSTICO.md).")),
      h3("Repositorio"),
      p(a(REPO, href = REPO, target = "_blank"), br(),
        "Modelo: output/etapa3/modelo_final.rds (scripts/07c_diagnostico_errores.R)."))
  )
)


# ---- 4. Servidor ------------------------------------------------------------------------------------
server <- function(input, output, session) {

  # 4a. Permite abrir una pestaña desde la URL (?pestana=desempeno&est_d=SE2), util para capturas.
  observe({
    q <- parseQueryString(session$clientData$url_search)
    if (!is.null(q$pestana)) nav_select("pestana", q$pestana)
    if (!is.null(q$est_d)) updateSelectInput(session, "est_d", selected = q$est_d)
    if (!is.null(q$estacion)) updateSelectInput(session, "estacion", selected = q$estacion)
  })

  # 4b. Temporada vigente: la elegida o la que corresponde a la fecha.
  temporada <- reactive({
    if (identical(input$modo, "fecha")) { req(input$fecha); temporada_de_fecha(input$fecha) } else req(input$temporada)
  })

  # 4c. Deslizadores: se rehacen al cambiar estacion, temporada o al pulsar «Volver a las medianas».
  output$deslizadores <- renderUI({
    input$reiniciar
    est <- req(input$estacion); tem <- temporada()
    lapply(MET, function(v) {
      r <- mf$entrenamiento$rangos[mf$entrenamiento$rangos$variable == v, ]
      sliderInput(paste0("v_", v), NOMBRES[[v]], min = floor(r$p01 / PASO[[v]]) * PASO[[v]],
                  max = ceiling(r$p99 / PASO[[v]]) * PASO[[v]], value = round(valor_inicial(est, tem, v), 3),
                  step = PASO[[v]], width = "100%")
    })
  })

  # 4d. Fila con los valores elegidos (mismo formato que los datos).
  entrada <- reactive({
    vals <- lapply(MET, function(v) req(input[[paste0("v_", v)]]))
    d <- data.frame(estacion = req(input$estacion), temporada = temporada())
    for (i in seq_along(MET)) d[[MET[i]]] <- vals[[i]]
    d
  })

  # 4e. Probabilidades y clasificacion de M0 y M1.
  probs <- reactive({
    d <- entrada()
    data.frame(modelo = c("M0", "M1"), p = c(predecir_modelo(mf, d, "M0"), predecir_modelo(mf, d, "M1")))
  })
  output$grafica_prob <- renderPlot({
    pr <- probs()
    ggplot(pr, aes(modelo, p, fill = modelo)) + geom_col(width = 0.6, show.legend = FALSE) +
      geom_hline(yintercept = CORTE, linetype = "dashed") +
      annotate("text", x = 0.45, y = CORTE + 0.04, label = sprintf("corte %.3f", CORTE), hjust = 0, size = 4.5) +
      geom_text(aes(label = pct(p)), vjust = -0.4, size = 6) +
      scale_fill_manual(values = COLORES) + scale_y_continuous(limits = c(0, 1.05), labels = function(x) paste0(100 * x, " %")) +
      scale_x_discrete(labels = c(M0 = "M0\n(estación y temporada)", M1 = "M1\n(+ meteorología)")) +
      labs(x = NULL, y = "Probabilidad") + tema
  })
  output$clasificacion <- renderUI({
    pr <- probs()
    txt <- ifelse(pr$p >= CORTE, "superación", "sin superación")
    tags$p(class = "fs-5", HTML(sprintf("Clasificación con el corte %.3f: M0 → <b>%s</b>; M1 → <b>%s</b>.", CORTE, txt[1], txt[2])))
  })

  # 4f. Contribuciones al puntaje discriminante de M1.
  output$grafica_contrib <- renderPlot({
    co <- contribuciones_m1(mf, entrada())
    etiquetas <- c(NOMBRES, estación = "Estación", temporada = "Temporada")
    d <- data.frame(variable = etiquetas[names(co)], aporte = as.vector(co))
    d$variable <- factor(d$variable, levels = d$variable[order(d$aporte)])
    ggplot(d, aes(aporte, variable, fill = aporte > 0)) + geom_col(show.legend = FALSE) +
      geom_vline(xintercept = 0, colour = "grey40") +
      scale_fill_manual(values = c(`FALSE` = "#0072B2", `TRUE` = "#D55E00")) +
      labs(x = "Aporte al puntaje\n(positivo = hacia superación)", y = NULL) + theme_minimal(base_size = 17)
  })

  # 4g. Desempeño en la prueba para el subconjunto elegido.
  sub <- reactive({
    d <- pred
    if (input$est_d != "todas") d <- d[d$estacion == input$est_d, ]
    if (input$tem_d != "todas") d <- d[d$temporada == input$tem_d, ]
    d
  })
  output$titulo_tabla <- renderText({
    d <- sub(); sprintf("Métricas (n = %d días, %.1f %% con superación)", nrow(d), 100 * mean(d$supera_25))
  })
  output$tabla_metricas <- renderTable({ validate(need(nrow(sub()) > 0, "Sin días en este subconjunto.")); metricas_sub(sub()) },
                                       align = "lrr")

  # 4h. Serie de tiempo: PM2.5 observado coloreado por el resultado de M1, y la probabilidad de M1.
  resultado <- function(d) {
    clase <- d$p_M1 >= CORTE
    factor(ifelse(d$supera_25 == 1, ifelse(clase, "Acierto (superación)", "Falso negativo"),
                  ifelse(clase, "Falso positivo", "Acierto (sin superación)")),
           levels = c("Acierto (sin superación)", "Acierto (superación)", "Falso positivo", "Falso negativo"))
  }
  COL_RES <- c("Acierto (sin superación)" = "grey70", "Acierto (superación)" = "grey35",
               "Falso positivo" = "#E69F00", "Falso negativo" = "#CC0000")
  output$serie_pm25 <- renderPlot({
    validate(need(input$est_d != "todas", "Elige una estación para ver la serie de tiempo."))
    d <- sub(); validate(need(nrow(d) > 0, "Sin días en este subconjunto.")); d$res <- resultado(d)
    ggplot(d, aes(fecha, `PM2.5`, colour = res)) + geom_hline(yintercept = 25, linetype = "dashed") +
      geom_point(size = 1.6) + scale_colour_manual(values = COL_RES, name = NULL, drop = FALSE) +
      labs(x = NULL, y = "PM2.5 (µg/m³)") + theme_minimal(base_size = 16) + theme(legend.position = "top", legend.text = element_text(size = 14))
  })
  output$serie_prob <- renderPlot({
    req(input$est_d != "todas")
    d <- sub(); req(nrow(d) > 0); d$res <- resultado(d)
    ggplot(d, aes(fecha, p_M1, colour = res)) + geom_hline(yintercept = CORTE, linetype = "dashed") +
      geom_point(size = 1.6, show.legend = FALSE) + scale_colour_manual(values = COL_RES, drop = FALSE) +
      scale_y_continuous(limits = c(0, 1)) + labs(x = NULL, y = "Probabilidad M1") + theme_minimal(base_size = 16)
  })
}

shinyApp(ui, server)
