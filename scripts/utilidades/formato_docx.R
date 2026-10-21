# =============================================================================================
# Ajuste de formato del informe en Word, despues de renderizarlo con Quarto. No cambia ningun texto.
#
# Quarto mete cada tabla y cada figura con referencia cruzada en una tabla contenedora de una fila
# (pie + contenido). Si esa fila se parte entre dos paginas, el pie queda separado de su tabla o de su
# figura. Este script:
#   1. marca todas las filas como «no dividir entre paginas» (w:cantSplit): ninguna fila de datos se
#      corta y cada figura viaja con su pie;
#   2. en las tablas (contenedor con marcador «tbl-»), quita el contenedor y deja el pie y la tabla
#      como elementos sueltos, en el mismo orden y con el mismo marcador. Word no parte bien una fila
#      que contiene otra tabla; sin contenedor, una tabla larga sigue en la pagina siguiente entre
#      filas (el encabezado se repite) y el pie queda pegado a la primera fila con «conservar con el
#      siguiente» (w:keepNext).
#
# Uso, desde la raiz:
#   Rscript scripts/utilidades/formato_docx.R docs/quarto/etapa4_informe_final.docx docs/etapa4/Informe_final_SIMA_Equipo1.docx
# =============================================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Uso: Rscript scripts/utilidades/formato_docx.R <entrada.docx> <salida.docx>", call. = FALSE)
entrada <- normalizePath(args[1], mustWork = TRUE)
salida <- file.path(normalizePath(dirname(args[2]), mustWork = TRUE), basename(args[2]))

tmp <- tempfile("docx_"); dir.create(tmp)
archivos <- utils::unzip(entrada, list = TRUE)$Name                 # orden original del paquete
utils::unzip(entrada, exdir = tmp)
doc_xml <- file.path(tmp, "word", "document.xml")
x <- readChar(doc_xml, file.info(doc_xml)$size, useBytes = TRUE)
Encoding(x) <- "UTF-8"

# Filas que ya traen propiedades (encabezado de tabla): se agrega cantSplit dentro de w:trPr.
x <- gsub("<w:tr>(\\s*)<w:trPr>", "<w:tr>\\1<w:trPr><w:cantSplit />", x, perl = TRUE)
# Filas sin propiedades: se les crea w:trPr con cantSplit.
x <- gsub("<w:tr>(?!\\s*<w:trPr>)", "<w:tr><w:trPr><w:cantSplit /></w:trPr>", x, perl = TRUE)
# Contenedores de tablas: marcador + pie + tabla interior + fin del marcador, fuera del contenedor.
n_antes <- lengths(regmatches(x, gregexpr("<w:tbl>", x, fixed = TRUE)))
x <- gsub(paste0("(?s)<w:tbl><w:tblPr>(?:(?!</w:tblPr>).)*</w:tblPr><w:tblGrid><w:gridCol w:w=\"\\d+\" /></w:tblGrid>",
                 "<w:tr>(?:<w:trPr><w:cantSplit /></w:trPr>)?<w:tc><w:tcPr />",
                 "(<w:bookmarkStart w:id=\"(\\d+)\" w:name=\"tbl-[^\"]*\" />)(<w:p>(?:(?!</w:p>).)*</w:p>)",
                 "(<w:tbl>(?:(?!</w:tbl>).)*</w:tbl>)(<w:bookmarkEnd w:id=\"\\2\" />)<w:p />\\s*</w:tc></w:tr></w:tbl>"),
          "\\1\\3\\4\\5", x, perl = TRUE)
n_sueltas <- n_antes - lengths(regmatches(x, gregexpr("<w:tbl>", x, fixed = TRUE)))
# Celdas: el escritor de Word repite la alineacion (la de la columna y luego «centrada») y Word usa
# la ultima. Se deja solo la de la columna, que es la que pide cada tabla del .qmd.
x <- gsub("<w:jc w:val=\"(left|right)\" /><w:jc w:val=\"center\" />", "<w:jc w:val=\"\\1\" />", x, perl = TRUE)
# Pie de tabla: conservar con el siguiente parrafo (la primera fila de la tabla).
x <- gsub("(<w:pStyle w:val=\"ImageCaption\" />\\s*)(</w:pPr>\\s*<w:r><w:t xml:space=\"preserve\">Tabla)", "\\1<w:keepNext />\\2", x, perl = TRUE)
# Filas que viajan con la siguiente: en tablas de hasta 4 filas de datos, todas menos la ultima (la
# tabla no se parte); en las mas largas, el encabezado y la primera fila (el encabezado nunca queda
# con menos de dos filas) y la penultima (la ultima fila nunca queda sola en una pagina).
conservar_filas <- function(t) {
  rx <- gregexpr("(?s)<w:tr>(?:(?!</w:tr>).)*</w:tr>", t, perl = TRUE)
  filas <- regmatches(t, rx)[[1]]
  n <- length(filas)
  if (n <= 1) return(t)
  idx <- if (n <= 5) seq_len(n - 1) else unique(c(1L, 2L, n - 1L))
  filas[idx] <- gsub("<w:pStyle w:val=\"Compact\" />", "<w:pStyle w:val=\"Compact\" /><w:keepNext />", filas[idx], fixed = TRUE)
  regmatches(t, rx) <- list(filas)
  t
}
rx_tabla <- gregexpr("(?s)<w:tbl>(?:(?!</w:tbl>).)*</w:tbl>", x, perl = TRUE)
regmatches(x, rx_tabla) <- list(vapply(regmatches(x, rx_tabla)[[1]], conservar_filas, character(1), USE.NAMES = FALSE))

con <- file(doc_xml, open = "wb"); writeChar(x, con, eos = NULL, useBytes = TRUE); close(con)
if (file.exists(salida)) file.remove(salida)
zip::zip(salida, files = archivos, root = tmp, mode = "mirror")
unlink(tmp, recursive = TRUE)
cuenta <- function(p) lengths(regmatches(x, gregexpr(p, x, fixed = TRUE)))
message("Tablas sin contenedor: ", n_sueltas, "; filas sin dividir: ", cuenta("<w:cantSplit />"),
        "; parrafos con conservar con el siguiente: ", cuenta("<w:keepNext />"), " -> ", salida)
