# Diseño de la base de trabajo

## Objetivo y alcance

Preparar un repositorio comprensible para cuatro estudiantes principiantes, con cinco avances semanales, análisis reproducible en R y reporte acumulativo en Quarto. La base permite organizar tareas y revisar encabezados reales sin decidir prematuramente una hipótesis ni construir modelos.

## Decisión de arquitectura

Se recomienda **un único repositorio con scripts de R y un reporte Quarto**. Es fácil de explicar y permite mantener juntos decisiones, código y resultados documentados.

Alternativas consideradas: trabajar solo en un proyecto compartido de Posit reduce el arranque pero dificulta separar cambios; crear desde el inicio un paquete de R, un sistema de ejecución complejo y una aplicación completa añade mantenimiento innecesario para cinco semanas. La estructura podrá crecer si el método elegido lo exige.

## Flujo de información

```text
Archivos originales conservados
          ↓ lectura
Inventario y diccionario confirmado
          ↓ reglas documentadas
Datos preparados y control de calidad
          ↓ selección por pregunta y validación
Exploración → modelos → evaluación
          ↓ resultados comprobados
Reporte + presentación + interfaz + reflexión personal
```

Cada resultado debe poder vincularse con archivo de entrada, script y decisión. Los datos originales no se sobrescriben. No se confunden los códigos de hoja `NO2` y `SO2` con las columnas de contaminantes del mismo nombre.

## Piezas y límites

- `data/metadata` y `config`: información sobre archivos y variables. Las unidades permanecen por confirmar.
- `R` y `scripts`: funciones pequeñas y pasos ejecutables, empezando por el inventario.
- `quarto`: reporte acumulativo y materiales de entrega.
- `docs`: objetivos, fases, responsabilidades, decisiones y evidencia de revisión.
- `app`: especificación mínima de la interfaz cuando el modelo y el uso estén definidos.

RStudio en Posit Cloud es el entorno preferido. Cada integrante tendrá una copia conectada al mismo GitHub. Los archivos grandes se distribuirán por un medio común autorizado y se verificarán mediante su huella de archivo. La estructura no depende de rutas personales de Windows.

## Criterios de aceptación de esta base

- Plan de cinco semanas con responsable, revisión, producto y condición de cierre.
- Instrucciones separadas para acciones manuales y comandos.
- Reporte inicial generable en HTML y Word sin datos ni resultados ficticios.
- Archivos de entrada excluidos de Git; inventario que los lee sin modificarlos.
- Evidencia de revisión estructural, sin presentar dimensiones de Excel como cobertura validada.
- Modelos, interfaz y decisiones pendientes claramente diferenciados del trabajo completado.

## Adaptación al curso del 25 de septiembre de 2026

Se conserva el entorno real de la plantilla indicada, incluida su licencia, y se integra la planificación previa. Se usa `quarto/` para documentos fuente, `docs/quarto/` para reportes y `output/` para resultados intermedios. `sima.Rproj` mantiene el nombre del proyecto del equipo y evita restaurar sesiones anteriores. El remoto debe ser público con cuatro editores; no se configura Python como segundo entorno.
