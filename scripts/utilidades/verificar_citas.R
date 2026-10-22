# =============================================================================================
# Verificacion de citas del informe final: toda cita del texto tiene su referencia (mismo autor y
# año) y toda referencia se cita al menos una vez. Las comunicaciones personales no van en la lista
# (APA 7), asi que no se buscan.
#
# Uso, desde la raiz:  Rscript scripts/utilidades/verificar_citas.R [quarto/etapa4_informe_final.qmd]
# Termina con error si encuentra una cita sin referencia o una referencia sin cita.
# =============================================================================================

args <- commandArgs(trailingOnly = TRUE)
archivo <- if (length(args)) args[1] else "quarto/etapa4_informe_final.qmd"
lineas <- readLines(archivo, encoding = "UTF-8", warn = FALSE)

# ---- Bloque 1. Separar la lista de referencias del resto del documento ---------------------------------
ini <- grep("^# Referencias", lineas)
fin <- ini + grep("^:::$", lineas[(ini + 1):length(lineas)])[1]           # cierre del div «Referencia»
refs <- lineas[(ini + 1):(fin - 1)]
refs <- refs[nzchar(trimws(refs)) & !grepl("^:::", refs)]
cuerpo <- paste(lineas[-(ini:fin)], collapse = "\n")
cuerpo <- gsub("(?s)^---.*?\n---", "", cuerpo, perl = TRUE)               # encabezado YAML

# Autores y año de cada referencia: el texto antes de «(AAAA» y el año.
ref_autor <- sub("^(.*?)\\(\\d{4}.*$", "\\1", refs, perl = TRUE)
ref_anio <- sub("^.*?\\((\\d{4}).*$", "\\1", refs, perl = TRUE)
ref_clave <- trimws(sub(",.*$", "", sub("\\.$", "", trimws(ref_autor))))    # primer autor u organizacion
ref_clave <- sub("^van ", "", ref_clave)

# ---- Bloque 2. Citas del texto: «Autor (AAAA)», «Autor, AAAA», «Autor et al.», «A y B», «A & B» -------------
# Siglas en mayusculas (codigos de estacion) solo cuentan si son alias de una organizacion.
alias <- c(SMA = "Secretaría de Medio Ambiente", CAI = "Clean Air Institute", WHO = "World Health Organization",
           SIMA = "Sistema Integral de Monitoreo Ambiental")
nombre <- "[A-ZÁÉÍÓÚÑ][\\p{L}'’\\-]+(?: [A-ZÁÉÍÓÚÑ][\\p{L}'’\\-]+)*"
patron <- paste0("(", nombre, ")(?: et al\\.)?(?: (?:y|&) (", nombre, "))?(?: \\[[A-Z]+\\])?,? \\(?((?:19|20)\\d{2})(?=[a-z]?(?:\\)|;|,))")
g <- regmatches(cuerpo, gregexec(patron, cuerpo, perl = TRUE))[[1]]          # fila 1: cita; 2: autor; 4: año
citas <- data.frame(texto = g[1, ], autor = g[2, ], anio = g[4, ])
es_sigla <- grepl("^[A-Z0-9]{2,5}$", citas$autor)
citas <- citas[!es_sigla | citas$autor %in% names(alias), ]
citas$autor_busqueda <- ifelse(citas$autor %in% names(alias), alias[citas$autor], citas$autor)
citas <- unique(citas)

tiene_ref <- mapply(function(a, y) any(ref_anio == y & grepl(a, ref_autor, fixed = TRUE)), citas$autor_busqueda, citas$anio)
citada <- mapply(function(k, y) any(citas$anio == y & (grepl(k, citas$autor_busqueda, fixed = TRUE) |
                                                       vapply(citas$autor_busqueda, function(a) grepl(a, k, fixed = TRUE), logical(1)))),
                 ref_clave, ref_anio)

# ---- Bloque 3. Informe ---------------------------------------------------------------------------------------
cat("Archivo:", archivo, "\n")
cat("Referencias en la lista:", length(refs), "| citas distintas en el texto:", nrow(citas), "\n\n")
cat("Referencias y si se citan:\n")
for (i in seq_along(refs)) cat(sprintf("  [%s] %s (%s)\n", if (citada[i]) "citada" else "SIN CITA", ref_clave[i], ref_anio[i]))
sin_ref <- citas[!tiene_ref, ]
cat("\nCitas sin referencia:", if (nrow(sin_ref)) "" else "ninguna", "\n")
if (nrow(sin_ref)) for (i in seq_len(nrow(sin_ref))) cat("  ", sin_ref$texto[i], "\n")
# APA: primero el apellido completo («nada precede a algo»: Gómez, E. antes que Gómez Santos), luego el resto.
normal <- function(s) tolower(stringi::stri_trans_general(s, "Latin-ASCII"))
orden <- order(normal(sub(",.*$|\\. \\(.*$", "", refs)), normal(refs))
cat("\nLista en orden alfabético:", if (identical(orden, seq_along(refs))) "sí" else "NO", "\n")
sin_enlace <- ref_clave[!grepl("https?://", refs)]
cat("Referencias sin DOI ni URL (libros, normas, boletines o trabajos no publicados):", paste(sin_enlace, collapse = "; "), "\n")
if (nrow(sin_ref) || !all(citada)) quit(status = 1)
