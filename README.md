# CEmestre – Constructor de Horarios
## Etapa 1: Paradigma Imperativo 
## Lenguaje de Programación utilizado: C

Proyecto del curso CE1106 – Paradigmas de Programación  
Instituto Tecnológico de Costa Rica - Escuela de Ingeniería en Computadores

### Integrantes
- Litzy Casandra Bonilla Jimenez – Carné
- Daniel Roberto Ulate Solera – 2025082290
- Kristel Daniela Valverde Gómez – 2025143158

# 0. Instrucciones de uso

Primero se debe compilar el programa con el método de su preferencia. Una vez con el ejecutable, en la misma carpeta raíz se deben incluir los archivos de entrada. Dichos archivos son `Aprobados.csv`, `Horarios.csv`, `MatriculaSeleccionada.csv` y `PlanEstudios.csv`; los archivos pueden tener cualquier nombre, pero deben seguir el formato especificado más adelante (también existen ejemplos en el repositorio). Una vez con los archivos listos, existen dos maneras de ejecutar el programa:

1. **Ejecutar el programa sin parámetros:**

```bash
   ./main
```

   En este modo, el programa busca automáticamente los archivos con los nombres por
   defecto `PlanEstudios.csv`, `Horarios.csv` y `Aprobados.csv` en la misma carpeta
   desde donde se ejecuta el programa. Si alguno de estos archivos no existe con ese
   nombre exacto, el programa finaliza con un mensaje de error indicando cuál archivo
   no pudo abrirse.

2. **Ejecutar el programa indicando los archivos por línea de comandos:**

```bash
   ./main <ruta_plan_estudios> <ruta_horarios> <ruta_aprobados>
```

   Este modo permite usar archivos con nombres o ubicaciones distintas a los valores
   por defecto. Los tres argumentos son obligatorios y deben respetar este orden
   exacto: primero el plan de estudios, luego los horarios, y por último el historial
   de cursos aprobados. Por ejemplo:

```bash
   ./main data/PlanIC.csv data/HorariosIC.csv data/HistorialJuan.csv
```

   Si se proporciona una cantidad de argumentos distinta de 0 o de 3, el programa
   muestra un mensaje de uso y finaliza sin procesar ningún archivo:

Al finalizar la ejecución (en cualquiera de los dos modos), el programa genera el
archivo de salida `Catalogo.json` en la misma carpeta raíz, con el catálogo completo
procesado: choques de horario detectados y elegibilidad de matrícula calculada según
el historial proporcionado.

---
# 1. Arquitectura del proyecto

## 1.1 Organización de archivos

## 1.2 Responsabilidad de cada módulo

## 1.3 Flujo general del programa

---
# 2. Decisiones de diseño

## 2.1 Justificaciones de decisiones propias y específicas del dataset con ejemplos incluidos
**Uso de Web Scraper para la recolección de datos.** Debido al inconveniente de que la guía de horarios no presenta opciones para exportar datos se optó por el uso de una extensión de navegador (específicamente Web scraper), dicha extensión permite exportar todos lo datos de la guía de horarios en formato .csv, por lo que el formato predeterminado por esta herramienta fue el seleccionado para procesar todos los datos. No se optó por crear una herramienta propia o ingresar los datos a mano por el esfuerzo extra que esto requiere.

**Formato CSV con comillas en todos los campos.** Se definieron tres archivos de entrada (PlanEstudios.csv, Horarios.csv, Aprobados.csv) que siguieran el mismo contrato: cada campo entre comillas dobles, separado por comas (`"CE1101","Introducción a la Programación",...`). Esto simplificó el parser (`split_csv_line`) a una sola función reutilizable en los tres archivos, sin necesidad de manejar casos especiales de campos sin comillas ni comas escapadas.

**Normalización de encabezados del scraper.** El scraper utilizado para recolectar los datos exporta nombres de columna genéricos y no descriptivos (`data`, `data2`, `name`, `data8`, etc.) en vez de nombres semánticos. Renombramos manualmente estos encabezados a nombres descriptivos (`codigo`, `nombre`, `requisitos`, `correquisitos`, `creditos`) antes de procesar los archivos, y el programa busca las columnas por nombre en tiempo de ejecución (no por posición fija), de modo que el orden de columnas en el archivo fuente puede variar sin romper la carga. Si se desea usar la misma herramienta para recolectar datos propios debe asegurarse de seguir este mismo formato, sin importar el orden.

**Prerrequisitos y correquisitos como lista separada por comas dentro de una sola celda.** Un curso como CE1103 tiene tres prerrequisitos (CE1101, CE1104, MA1403); estos se representan en una única celda del CSV como `"CE1101,CE1104,MA1403"` y se separan en tiempo de carga con una función dedicada (`parse_codes`). Cuando un curso no tiene prerrequisitos o correquisitos (ejemplo: CE1101 no requiere ningún curso previo), la celda contiene el valor centinela `"No hay"`.

**Filtro por sede.** Horarios.csv incluye grupos de todas las sedes del TEC. Filtramos únicamente los grupos cuya sede coincide exactamente con "CAMPUS TECNOLOGICO CENTRAL CARTAGO", descartando el resto antes de intentar asociarlos a un curso del catálogo.

**Representación de horas en minutos desde medianoche.** Cada horario (ejemplo: grupo 10 de MA0101, que corre martes de 15:00 a 17:50) se almacena como enteros (`begin_time=900, end_time=1070`) en vez de strings de hora. Esto simplifica la comparación numérica para la detección de choques de horario, evitando parsear texto en cada comparación.


## 2.2 Caso límite real encontrado y su solución

Durante la recolección de datos con el scraper, notamos dos inconsistencias frente al
contrato de formato que habíamos definido:

1. La primera línea de cada CSV (los encabezados) se exportaba sin comillas (`web_scraper_order,web_scraper_start_url,...`), a diferencia de las filas de datos,que sí llevan comillas en cada campo. En vez de modificar el parser para tolerar dos formatos distintos según la fila (lo que hubiera complicado la lógica de `split_csv_line`, ejecutada miles de veces por archivo), optamos por normalizar el encabezado manualmente una sola vez por archivo, manteniendo el contrato de formato consistente.

2. Los archivos generados por el scraper incluían un BOM (Byte Order Mark, bytes `0xEF 0xBB 0xBF`) al inicio, propio de archivos codificados en UTF-8 desde ciertas herramientas. Sin manejarlo explícitamente, esos tres bytes quedaban pegados al primer campo de la primera línea leída, corrompiendo su valor. Resolvimos esto con una función `open_file_csv` que detecta el BOM al abrir el archivo y, si está presente, avanza el cursor de lectura más allá de esos bytes antes de procesar cualquier línea.

3. Para la validación de correquisitos, identificamos que el criterio "correcto" según la normativa del TEC permitiría matricular un correquisito si el estudiante lo va a cursar simultáneamente en el mismo ciclo, por lo que se debió agregar una archivo extra donde se indiquen los cursos a matricular.

## 2.3 Justificación del formato de salida

Elegimos JSON como formato de salida porque la estructura de los datos es naturalmente jerárquica: un curso contiene una lista de grupos, y cada grupo contiene una lista de horarios. JSON representa esta relación de forma directa mediante objetos y arreglos anidados, mientras que un formato plano como CSV requeriría aplanar esta jerarquía (por ejemplo, una fila por combinación curso-grupo-horario), complicando su reconstrucción en la siguiente etapa del proyecto (Racket).

Se decidió omitir el campo `aula` del `Schedule` en el archivo de salida, a pesar de estar presente en la estructura interna (`structs.h`), ya que no forma parte de los campos mínimos solicitados en el enunciado y no fue capturado consistentemente en el proceso de recolección de datos.
---
# 3. Estructuras de datos desarrolladas  


