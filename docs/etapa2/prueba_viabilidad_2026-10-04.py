"""
Prueba de viabilidad (exploratoria) — Opus, 4 de octubre de 2026.
NO es un resultado del informe. Se documenta porque usó los años 2024–2025,
que después serán el conjunto de prueba. A partir del protocolo acordado (docs/etapa2/protocolo.md)
no se ajustan decisiones del modelo con base en 2024–2025.

Datos: data/clean/sima_diario_2020_2025.csv (datos-v1.1, commit b272aec en main).
Ejecución: python docs/etapa2/prueba_viabilidad_2026-10-04.py  (pandas, scikit-learn)
"""
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, balanced_accuracy_score

d = pd.read_csv("data/clean/sima_diario_2020_2025.csv")
m = d[(d.en_periodo_modelado == 1) & (~d.estacion.isin(["NE3", "NO3"]))].copy()
met = ["TOUT", "RH", "SR", "PRS", "viento_u", "viento_v", "horas_lluvia", "viento_rapidez_ms"]
m = m[m["PM2.5"].notna() & m[met].notna().all(axis=1)].copy()          # 16,461 estación-días
m["y"] = (m["PM2.5"] > 25).astype(int)                                  # 26.6 %
m = m.sort_values(["estacion", "fecha"])
m["pm25_lag"] = m.groupby("estacion")["PM2.5"].shift(1)                 # fila previa disponible (no necesariamente el día calendario previo)

X0 = pd.get_dummies(m[["estacion", "temporada"]], drop_first=True).astype(float)
tr, te = m.anio <= 2023, m.anio >= 2024                                  # separación temporal

# Referencia: estación + temporada (logística, sin escalar)
ref = LogisticRegression(max_iter=2000, class_weight="balanced").fit(X0[tr], m.y[tr])
p = ref.predict_proba(X0[te])[:, 1]
print("M0 estación+temporada  logit AUC=%.3f BA=%.3f" % (roc_auc_score(m.y[te], p), balanced_accuracy_score(m.y[te], p > 0.5)))

def correr(cols, incluir_dummies, nombre):
    X = pd.concat([m[cols]] + ([X0] if incluir_dummies else []), axis=1)
    ok = X.notna().all(axis=1)
    trk, tek = tr & ok, te & ok
    sc = StandardScaler().fit(X[trk])                                   # escalado ajustado solo con entrenamiento
    for mdl, nm, umbral in [(LogisticRegression(max_iter=2000, class_weight="balanced"), "logit", 0.5),
                            (LinearDiscriminantAnalysis(), "LDA", m.y[trk].mean())]:
        mdl.fit(sc.transform(X[trk]), m.y[trk])
        pp = mdl.predict_proba(sc.transform(X[tek]))[:, 1]
        print(f"{nombre:38s} {nm:5s} AUC={roc_auc_score(m.y[tek], pp):.3f} "
              f"BA={balanced_accuracy_score(m.y[tek], pp > umbral):.3f} n_prueba={tek.sum()}")

correr(met, False, "solo meteorología")
correr(met, True, "M1 meteorología+estación+temporada")
correr(met + ["pm25_lag"], True, "M1 + PM2.5 fila previa (extensión)")

# Salida obtenida el 4 oct 2026:
# M0 estación+temporada  logit AUC=0.718 BA=0.635
# solo meteorología                      logit AUC=0.661 BA=0.612 ; LDA AUC=0.627 BA=0.582
# M1 meteorología+estación+temporada     logit AUC=0.790 BA=0.713 ; LDA AUC=0.781 BA=0.706
# M1 + PM2.5 fila previa                 logit AUC=0.882 BA=0.801 ; LDA AUC=0.877 BA=0.792
# n_prueba = 5,427 ; prevalencia en prueba = 27.3 %
# Limitaciones: una sola corrida; sin intervalos de confianza; sin revisión de supuestos;
# la referencia M0 se ajustó con logística sin escalar (no con LDA); el "lag" toma la fila previa disponible.
