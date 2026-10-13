// =============================================================================================
// Presentacion de la etapa 3 para SIMA (portada + 3 diapositivas, <= 5 minutos).
// Requiere pptxgenjs (npm install pptxgenjs). Desde la raiz del proyecto:
//   node docs/presentacion/crear_presentacion.js
// Lee las figuras de docs/presentacion/figuras/ (docs/presentacion/figuras_presentacion.R) y
// output/etapa3/figuras/app_calcular.png; las notas del orador vienen de docs/etapa3/guion_exposicion.md.
// Escribe docs/presentacion/Presentacion_Etapa3_SIMA.pptx.
// Cifras: output/etapa3 (07b y 07c) y data/clean/tabla_informe_limpieza.csv; no se calculan aqui.
// =============================================================================================
const pptxgen = require("pptxgenjs");
const fs = require("fs");
const path = require("path");

// ---- 1. Paleta y tipografia (coherentes con las figuras: M0 azul, M1 naranja) --------------------
const COL = {
  texto: "1F2933", gris: "52606D", grisClaro: "9AA5B1", tarjeta: "F1F3F5", tarjetaFria: "EEF4F9",
  m0: "0072B2", m1: "D55E00", blanco: "FFFFFF",
};
const FONT = "Calibri";
const RAIZ = path.resolve(__dirname, "..", "..");
const fig = (p) => path.join(RAIZ, p);

// ---- 2. Notas del orador: secciones del guion ----------------------------------------------------
const guion = fs.readFileSync(fig("docs/etapa3/guion_exposicion.md"), "utf8");
function nota(encabezado) {
  const i = guion.indexOf("## " + encabezado);
  if (i < 0) throw new Error("No encuentro la seccion del guion: " + encabezado);
  const resto = guion.slice(i).split("\n").slice(1).join("\n");
  const fin = resto.search(/\n## |\n---/);
  return (fin < 0 ? resto : resto.slice(0, fin)).replace(/\*\*/g, "").trim();
}

// ---- 3. Presentacion y layouts ---------------------------------------------------------------------
const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";            // 13.333 x 7.5 in
pres.theme = { headFontFace: FONT, bodyFontFace: FONT };
pres.title = "¿Cuánto ayuda el clima a identificar los días de PM2.5 alto en Monterrey?";
pres.author = "Equipo 1 · Grupo 201 · MA2003B";
pres.company = "Reto SIMA";

pres.defineSlideMaster({
  title: "CONTENIDO",
  background: { color: COL.blanco },
  objects: [
    { placeholder: { options: { name: "titulo", type: "title", x: 0.5, y: 0.3, w: 12.33, h: 0.75,
      fontFace: FONT, fontSize: 32, bold: true, color: COL.texto, valign: "middle", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({ title: "PORTADA", background: { color: COL.blanco } });

// Utilidades: tarjeta con fondo suave y texto con viñetas.
function tarjeta(slide, x, y, w, h, color, nombre) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.12,
    fill: { color: color || COL.tarjeta }, line: { color: color || COL.tarjeta }, objectName: nombre });
}
function vinetas(items, size) {
  return items.map((t, k) => ({
    text: t, options: { bullet: { indent: 18 }, fontSize: size || 20, color: COL.texto,
      breakLine: k < items.length - 1, paraSpaceAfter: 8 },
  }));
}
const T = (opts) => Object.assign({ isTextBox: true, fontFace: FONT, margin: 0 }, opts);

// ---- 4. Portada ---------------------------------------------------------------------------------------
{
  const s = pres.addSlide({ masterName: "PORTADA" });
  s.addText("Reto SIMA · Etapa 3: modelado y evaluación", T({ x: 0.6, y: 0.55, w: 7.4, h: 0.45,
    fontSize: 22, color: COL.m1, bold: true, objectName: "subtitulo" }));
  s.addText("¿Cuánto ayuda el clima a identificar los días de PM2.5 alto en Monterrey?", T({
    x: 0.6, y: 1.1, w: 7.4, h: 2.2, fontSize: 40, bold: true, color: COL.texto, valign: "top", objectName: "titulo" }));
  s.addText([
    { text: "Equipo 1 · Grupo 201 · Análisis multivariado (MA2003B)", options: { breakLine: true } },
    { text: "Socio formador: SIMA" },
  ], T({ x: 0.6, y: 3.5, w: 7.4, h: 0.85, fontSize: 20, color: COL.gris, paraSpaceAfter: 4, objectName: "curso" }));
  const nombres = ["Leonardo Orozco", "Pablo Alonso Robles Nava", "Daniel Ayala", "Ignacio Kume"];
  nombres.forEach((n, k) => {
    const x = 0.6 + (k % 2) * 3.75, y = 4.75 + Math.floor(k / 2) * 1.05;
    s.addText([
      { text: n, options: { bold: true, color: COL.texto, breakLine: true } },
      { text: "Matrícula: ________", options: { color: COL.gris } },
    ], T({ x, y, w: 3.6, h: 0.85, fontSize: 20, valign: "top", objectName: "integrante_" + (k + 1) }));
  });
  s.addImage({ path: fig("docs/presentacion/figuras/roc_m0_m1_diapositiva.png"), x: 8.35, y: 0.9, w: 4.5, h: 4.5,
    altText: "Curvas ROC de M0 y M1 en la prueba 2024–2025", objectName: "figura_roc" });
  s.addText("Detección frente a falsas alarmas en 2024–2025", T({ x: 8.35, y: 5.5, w: 4.5, h: 0.75,
    fontSize: 20, color: COL.gris, align: "center", objectName: "pie_roc" }));
  s.addNotes(nota("Portada"));
}

// ---- 5. Diapositiva 1: que queremos hacer y con que datos ----------------------------------------------
{
  const s = pres.addSlide({ masterName: "CONTENIDO" });
  s.addText("Qué queremos hacer y con qué datos", { placeholder: "titulo" });
  s.addText([
    { text: "Objetivo: ", options: { bold: true } },
    { text: "medir cuánto mejora la meteorología del día la identificación de días-estación con PM2.5 > 25 µg/m³ (24 h, NOM-025-SSA1-2021), frente a solo conocer estación y temporada.", options: { breakLine: true } },
    { text: "Por qué: ", options: { bold: true } },
    { text: "el PM2.5 se asocia con efectos en la salud por exposición de corto plazo; orienta la vigilancia de SIMA.", options: { breakLine: true } },
    { text: "Datos: ", options: { bold: true } },
    { text: "13 estaciones · 2021–2025 · PM2.5 + 8 variables meteorológicas · 15 390 estación-días" },
  ], T({ x: 0.5, y: 1.2, w: 6.2, h: 3.55, fontSize: 20, color: COL.texto, valign: "top", paraSpaceAfter: 8,
         objectName: "objetivo_datos" }));
  s.addImage({ path: fig("docs/presentacion/figuras/mapa_estaciones_diapositiva.png"), x: 6.95, y: 1.15, w: 5.88, h: 5.88 * 3.2 / 6.2,
    altText: "Mapa de las 13 estaciones con el porcentaje de días con superación", objectName: "mapa" });
  s.addText("% de días con superación, 2021–2025", T({ x: 6.95, y: 4.22, w: 5.88, h: 0.4, fontSize: 20,
    color: COL.gris, align: "center", objectName: "pie_mapa" }));

  // Tarjetas de preparacion de datos.
  const tarjetas = [
    { n: "12.3 %", t: "faltantes de origen", d: "de los valores horarios (PM2.5: 26 %)" },
    { n: "0.7 %", t: "inconsistentes eliminados", d: "radiación nocturna, viento distinto al de la red, repetidos 24 h, saltos, fuera de rango" },
    { n: "1.0 %", t: "imputados", d: "solo huecos ≤ 3 h" },
  ];
  const w = 3.95, g = 0.24, y = 4.85, h = 2.25;
  tarjetas.forEach((c, k) => {
    const x = 0.5 + k * (w + g);
    tarjeta(s, x, y, w, h, COL.tarjeta, "tarjeta_datos_" + (k + 1));
    s.addText(c.n, T({ x: x + 0.25, y: y + 0.1, w: w - 0.5, h: 0.75, fontSize: 44, bold: true, color: COL.texto,
      objectName: "cifra_datos_" + (k + 1) }));
    s.addText([
      { text: c.t, options: { bold: true, breakLine: true } },
      { text: c.d, options: { color: COL.gris } },
    ], T({ x: x + 0.25, y: y + 0.85, w: w - 0.5, h: h - 0.95, fontSize: 20, color: COL.texto, valign: "top",
           objectName: "texto_datos_" + (k + 1) }));
  });
  s.addNotes(nota("Diapositiva 1"));
}

// ---- 6. Diapositiva 2: como lo analizamos y que encontramos -------------------------------------------
{
  const s = pres.addSlide({ masterName: "CONTENIDO" });
  s.addText("Cómo lo analizamos y qué encontramos", { placeholder: "titulo" });
  const y = 1.2, h = 2.05, g = 0.15;
  const ws = [3.75, 3.75, 2.25, 2.13];
  const tarjetas = [
    { n: [{ text: "0.72", options: { color: COL.m0 } }, { text: " → ", options: { color: COL.grisClaro } }, { text: "0.79", options: { color: COL.m1 } }],
      d: "AUC de M0 → M1: +0.07 (IC 95 %: 0.05–0.09)" },
    { n: [{ text: "73 %", options: { color: COL.m1 } }, { text: " vs ", options: { color: COL.grisClaro, fontSize: 30 } }, { text: "58 %", options: { color: COL.m0 } }],
      d: "de las superaciones detectadas (M1 vs M0)" },
    { n: [{ text: "89 %", options: { color: COL.m1 } }], d: "de los episodios > 40 µg/m³ (M1)" },
    { n: [{ text: "+0.14", options: { color: COL.m1 } }], d: "en mar–may; casi nada en lluvias" },
  ];
  let x = 0.5;
  tarjetas.forEach((c, k) => {
    const w = ws[k];
    tarjeta(s, x, y, w, h, COL.tarjeta, "tarjeta_resultado_" + (k + 1));
    s.addText(c.n, T({ x: x + 0.2, y: y + 0.18, w: w - 0.4, h: 0.75, fontSize: k < 2 ? 40 : 44, bold: true, objectName: "cifra_resultado_" + (k + 1) }));
    s.addText(c.d, T({ x: x + 0.2, y: y + 0.98, w: w - 0.4, h: h - 1.1, fontSize: 20, color: COL.gris, valign: "top",
                       objectName: "texto_resultado_" + (k + 1) }));
    x += w + g;
  });
  s.addText(vinetas([
    "PCA (interdependencia): 3 ejes del clima explican el 67 %",
    "LDA (dependencia): M0 estación + temporada frente a M1 + clima",
    "Entrenamiento 2021–2023, prueba 2024–2025; decisiones fijadas antes",
    "Se asocia con presión baja, más temperatura y menos viento",
  ]), T({ x: 0.5, y: 3.6, w: 5.85, h: 3.4, valign: "top", objectName: "tecnicas" }));
  s.addImage({ path: fig("docs/presentacion/figuras/dauc_temporada_diapositiva.png"), x: 6.6, y: 3.5, w: 6.23, h: 3.5,
    altText: "Mejora del AUC por temporada con intervalos de confianza", objectName: "dauc_temporada" });
  s.addNotes(nota("Diapositiva 2"));
}

// ---- 7. Diapositiva 3: problemas, que sigue y preguntas para SIMA ----------------------------------------
{
  const s = pres.addSlide({ masterName: "CONTENIDO" });
  s.addText("Problemas, qué sigue y preguntas para SIMA", { placeholder: "titulo" });
  const encabezado = (t, color) => ({ text: t, options: { bold: true, fontSize: 22, color: color || COL.texto, breakLine: true, paraSpaceAfter: 6 } });

  s.addText([encabezado("Problemas"), ...vinetas([
    "Viento (SO2, NE2 en 2021) y radiación nocturna (NO2, SE3, CE): regla nueva",
    "Cambios de equipos 2021/2025: revisados, no cambian la conclusión",
    "Retención desigual entre estaciones",
  ])], T({ x: 0.5, y: 1.25, w: 4.35, h: 3.35, valign: "top", objectName: "problemas" }));
  s.addText([encabezado("Qué sigue"), ...vinetas([
    "Meteorología pronosticada (alerta real)",
    "PM2.5 del día anterior",
    "Cortes por estación",
  ])], T({ x: 0.5, y: 4.75, w: 4.35, h: 2.3, valign: "top", objectName: "que_sigue" }));

  // Hecho: captura de la interfaz.
  tarjeta(s, 5.05, 1.25, 4.05, 5.8, COL.tarjeta, "tarjeta_app");
  s.addText("Hecho: interfaz Shiny", T({ x: 5.27, y: 1.4, w: 3.6, h: 0.45, fontSize: 22, bold: true, color: COL.texto, objectName: "titulo_app" }));
  s.addImage({ path: fig("output/etapa3/figuras/app_calcular.png"), x: 5.27, y: 2.0, w: 3.6, h: 3.6 * 1386 / 1500,
    altText: "Captura de la interfaz Shiny: pestaña Calcular", objectName: "captura_app" });
  s.addText("Estación, temporada y clima → probabilidad de superación", T({ x: 5.27, y: 5.5, w: 3.6, h: 1.4,
    fontSize: 20, color: COL.gris, valign: "top", objectName: "pie_app" }));

  // Preguntas para SIMA.
  tarjeta(s, 9.3, 1.25, 3.53, 5.8, COL.tarjetaFria, "tarjeta_preguntas");
  s.addText([encabezado("Preguntas para SIMA", COL.m0), ...vinetas([
    "Fechas de cambio de sensores; ¿reubicaciones en 2021?",
    "¿Hora local? ¿Unidad de la lluvia?",
    "¿Qué fuentes explican Juárez (SE2) y Santa Catarina (SO)?",
    "¿Les serviría una alerta con pronóstico?",
  ])], T({ x: 9.5, y: 1.4, w: 3.18, h: 5.5, valign: "top", objectName: "preguntas" }));
  s.addNotes(nota("Diapositiva 3"));
}

// ---- 8. Guardar -------------------------------------------------------------------------------------------
pres.writeFile({ fileName: path.join(RAIZ, "docs/presentacion/Presentacion_Etapa3_SIMA.pptx") })
  .then((f) => console.log("Escrito:", f));
