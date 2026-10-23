"""Verificación (informe en LaTeX, 23 oct 2026): persistencia por temporada y correlaciones sin ajustar.

Reproduce con numpy el LDA de la Sección 6.5 (M0, M1, MP, MP1) sobre la base v2 y calcula
MP1 - MP y M1 - M0 por temporada con bootstrap pareado por bloques de 14 días (1 000 réplicas).
El AUC no depende del prior ni del intercepto, así que basta la dirección Sigma^-1 (mu1 - mu0).
Comprobación: total MP 0.8716, MP1 0.8875, MP1 - MP 0.016 [0.008, 0.025], igual que
output/etapa4/retro_final/b_persistencia_*.csv (script 10, en R).
Uso: python scripts/verificacion/persistencia_por_temporada.py   (desde la raíz del repositorio)
"""
import numpy as np, pandas as pd

d = pd.read_csv('data/clean/v2/diario_v2_imputado_2021_2025.csv', parse_dates=['fecha']).sort_values(['estacion', 'fecha'])
prev = d.loc[d.respuesta_valida == 1, ['estacion', 'fecha', 'PM2.5']].copy()
prev['fecha'] += pd.Timedelta(days=1)
d = d.merge(prev.rename(columns={'PM2.5': 'pm_ayer'}), on=['estacion', 'fecha'], how='left')
base = d[(d.respuesta_valida == 1) & (d.met_completa_tras_imputar == 1)]
tr = base[(base.anio <= 2023) & (base.sitio_valido == 1)].copy()
te = base[base.anio >= 2024].copy()
media_prs = tr.groupby('estacion').PRS.mean()
for x in (tr, te):
    x['PRSa'] = x.PRS - x.estacion.map(media_prs)
EST = [e for e in sorted(base.estacion.unique()) if e != 'CE']
MET = ['TOUT', 'RH', 'SR', 'PRSa', 'viento_u', 'viento_v', 'viento_rapidez_ms', 'horas_lluvia']

def X(df, met, pers):
    cols = [(df.estacion == e).astype(float) for e in EST] + [(df.temporada == t).astype(float) for t in ['seca_fria', 'seca_calida']]
    cols += [df[c].astype(float) for c in MET] if met else []
    cols += [df.pm_ayer.astype(float)] if pers else []
    return np.column_stack(cols)

def direccion(Xt, y):
    S = np.cov(Xt[y == 1].T) * (sum(y == 1) - 1) + np.cov(Xt[y == 0].T) * (sum(y == 0) - 1)
    return np.linalg.solve(S, Xt[y == 1].mean(0) - Xt[y == 0].mean(0))

def auc(y, s):
    r = pd.Series(s).rank().values; n1 = y.sum(); n0 = len(y) - n1
    return (r[y == 1].sum() - n1 * (n1 + 1) / 2) / (n1 * n0)

trp, tep = tr[tr.pm_ayer.notna()], te[te.pm_ayer.notna()].copy()
for nombre, (m, p) in {'M0': (0, 0), 'M1': (1, 0), 'MP': (0, 1), 'MP1': (1, 1)}.items():
    tep[nombre] = X(tep, m, p) @ direccion(X(trp, m, p), trp.supera_25.values)
tep['bloque'] = (tep.fecha - pd.Timestamp('2024-01-01')).dt.days // 14
TEMP = ['seca_fria', 'seca_calida', 'calida_humeda', 'total']

def resumen(df):
    out = {}
    for t in TEMP:
        g = df if t == 'total' else df[df.temporada == t]
        y = g.supera_25.values
        out[t] = (auc(y, g.MP1.values) - auc(y, g.MP.values), auc(y, g.M1.values) - auc(y, g.M0.values), auc(y, g.M0.values))
    return out

punto = resumen(tep)
rng = np.random.default_rng(2026)
grupos = {b: g for b, g in tep.groupby('bloque')}
bloques = list(grupos)
reps = [resumen(pd.concat([grupos[b] for b in rng.choice(bloques, len(bloques))])) for _ in range(1000)]
filas = []
for t in TEMP:
    for k, nombre in enumerate(['MP1_menos_MP', 'M1_menos_M0', 'AUC_M0']):
        v = np.array([r[t][k] for r in reps])
        filas.append(dict(temporada=t, medida=nombre, n=len(tep) if t == 'total' else int((tep.temporada == t).sum()),
                          estimacion=punto[t][k], ic_li=np.percentile(v, 2.5), ic_ls=np.percentile(v, 97.5)))
res = pd.DataFrame(filas)
res.to_csv('output/etapa4/verificacion/persistencia_por_temporada.csv', index=False)
print(res.round(3).to_string(index=False))

# Correlaciones sin ajustar dentro de cada temporada (entrenamiento), Sección 6.3
cor = []
for t, g in tr.groupby('temporada'):
    cor.append(dict(temporada=t, **{f'cor_{v}_supera': g[[v, 'supera_25']].corr().iloc[0, 1] for v in ['SR', 'PRSa', 'TOUT']},
                    cor_PRSa_TOUT=g[['PRSa', 'TOUT']].corr().iloc[0, 1]))
cor = pd.DataFrame(cor)
cor.to_csv('output/etapa4/verificacion/correlaciones_sin_ajustar.csv', index=False)
print(cor.round(3).to_string(index=False))
