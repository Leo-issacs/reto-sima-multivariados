# Trabajo en equipo

`main` es la versión compartida del proyecto. Una rama permite trabajar en un cambio; una pull request permite que otra persona lo revise antes de incorporarlo.

## Antes de trabajar

1. Revisa las [tareas abiertas](https://github.com/Leo-issacs/reto-sima-multivariados/issues) y acuerda cuál vas a tomar.
2. Guarda tus cambios y actualiza tu copia con **Pull**.
3. En R, ejecuta `renv::restore()` y `renv::status()`.
4. Crea una rama con un nombre claro, por ejemplo `datos/diccionario` o `reporte/semana-1`.

## Antes de compartir

- Ejecuta el script o genera el documento que cambiaste.
- Revisa qué archivos entran en el commit. Las bases de datos y los archivos de sesión quedan fuera.
- Escribe un mensaje concreto: `Completa unidades del diccionario` o `Agrega revisión de faltantes`.
- Haz **Push**, abre una pull request y pide revisión a otro integrante.

En la revisión, comprobar que el cambio se puede repetir y que las cifras y explicaciones coinciden. Si hay conflictos, comparar las dos versiones con su autor antes de resolverlos. Evitar que dos personas editen al mismo tiempo la misma sección del reporte.

## Paquetes de R

Para una dependencia nueva:

```r
renv::install("nombre_del_paquete")
# Usarlo en el código o declararlo en _dependencies.R.
renv::snapshot()
renv::status()
```

Revisar los cambios de `renv.lock` antes de subirlos. `_dependencies.R` conserva los paquetes de la plantilla aunque todavía no los usemos; no hay que ejecutar ese archivo. Si `snapshot()` propone retirarlos, revisar la causa antes de aceptar. Coordinar los cambios de paquetes con el equipo para evitar conflictos.

## Datos y resultados

Guardar las entradas en `data/raw/` y los derivados en `data/processed/` u `output/`. Registrar la fuente y las decisiones de limpieza. Las unidades y códigos se confirman con la documentación del SIMA; no se deducen solo por el nombre de una columna.

Quien incorpora código o texto, incluido el que se prepare con ayuda de herramientas de IA, debe poder explicarlo y comprobarlo. Las conclusiones deben salir del análisis y la reflexión individual debe recoger el aprendizaje de cada persona.
