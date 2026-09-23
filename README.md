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
La primera etapa del proyecto está implementada en lenguaje C y sigue una organización modular. Cada archivo se encarga de una responsabilidad específica, como la lectura de datos, la representación de las estructuras, la validación de requisitos, la detección de choques de horario y la generación del archivo de salida.

La lógica principal se concentra en main.c, mientras que las demás funcionalidades se distribuyen en módulos independientes mediante archivos .c y .h.

## 1.1 Organización de archivos
La estructura principal de la etapa 1 es la siguiente:
```text
ScheduleGen/
│
├── README.md
│
└── Etapa_1_C/
    │
    ├── main.c
    ├── structs.h
    ├── constants.h
    │
    ├── loader.c
    ├── loader.h
    │
    ├── collision.c
    ├── collision.h
    │
    ├── prereq.validator.c
    ├── prereq.validator.h
    │
    ├── writer.c
    ├── writer.h
    │
    ├── CMakeLists.txt
    │
    ├── Catalogo.json
    │
    └── ArchivosPrueba/
        ├── PlanEstudios.csv
        ├── Horarios.csv
        └── Aprobados.csv
```
Los archivos ubicados en ArchivosPrueba/ corresponden a las entradas utilizadas por el programa:

- PlanEstudios.csv: contiene los cursos del plan de estudios, sus créditos, prerrequisitos y correquisitos.
- Horarios.csv: contiene los grupos y horarios disponibles para los cursos.
- Aprobados.csv: contiene los códigos de los cursos que el estudiante ya aprobó.

Como resultado del procesamiento, el programa genera el archivo Catalogo.json, que contiene la información organizada del catálogo de cursos y los resultados de las validaciones realizadas.

## 1.2 Responsabilidad de cada módulo
## main.c

Es el punto de entrada del programa y funciona como coordinador de los distintos módulos.

Sus principales responsabilidades son:

- Determinar los archivos de entrada que se utilizarán.
- Permitir recibir las rutas de los tres archivos CSV mediante argumentos de línea de comandos.
- Crear las estructuras principales Catalog y Record.
 -Invocar las funciones encargadas de cargar los archivos.
- Ejecutar la validación de prerrequisitos y correquisitos.
- Ejecutar la detección de choques de horario.
- Generar finalmente el archivo Catalogo.json.

También contiene funciones auxiliares para imprimir en consola el catálogo cargado y el historial de cursos aprobados, utilizadas principalmente para verificar el funcionamiento del programa.

## structs.h

Define las estructuras de datos principales utilizadas por todos los módulos.

Las estructuras definidas son:

- Schedule: representa una franja horaria mediante día, hora de inicio, hora de finalización y aula.
- Group: representa un grupo de un curso y contiene sus diferentes franjas horarias.
- Curso: representa un curso con su código, nombre, créditos, grupos, prerrequisitos y correquisitos.
- Catalog: almacena el conjunto completo de cursos.
- Record: almacena los códigos de los cursos aprobados por el estudiante.

Además, Group y Curso poseen variables booleanas que permiten almacenar resultados calculados por otros módulos, como la existencia de choques de horario.

## constants.h

Centraliza las constantes utilizadas para definir los tamaños máximos de cadenas y arreglos.

Entre ellas se encuentran:

- Cantidad máxima de cursos.
- Cantidad máxima de grupos por curso.
- Cantidad máxima de horarios por grupo.
- Cantidad máxima de prerrequisitos y correquisitos.
- Cantidad máxima de cursos aprobados.
- Tamaños máximos para códigos, nombres y otros campos.

Esto permite mantener los límites del programa en un único archivo y evita utilizar valores numéricos directamente en diferentes módulos.

## loader.c / loader.h

Este módulo se encarga de la lectura, validación básica y transformación de los archivos CSV de entrada.

Sus tres operaciones principales son:

- load_study_plan() procesa el archivo del plan de estudios y crea los cursos iniciales dentro del catálogo.

- load_schedules() procesa el archivo de horarios, busca cada curso previamente cargado y añade sus grupos y franjas horarias. Además, filtra únicamente los cursos correspondientes al Campus Tecnológico Central Cartago.

- load_record() procesa el archivo de cursos aprobados y construye el historial del estudiante evitando códigos duplicados.

El módulo también contiene funciones auxiliares para:

Abrir y validar archivos CSV.
Separar los campos de cada línea.
Convertir los días de la semana a números.
Convertir horarios a minutos desde medianoche.
Buscar cursos dentro del catálogo.
Procesar listas de prerrequisitos y correquisitos.

## prereq.validator.c / prereq.validator.h

Este módulo se encarga de validar los requisitos académicos de cada curso con respecto al historial del estudiante.

Primero comprueba si un determinado código se encuentra entre los cursos aprobados. Posteriormente revisa los prerrequisitos y correquisitos asociados a cada curso.

La función principal expuesta por el módulo es:

validate_catalog_requirements()

Esta función recorre todos los cursos del catálogo y determina si los requisitos académicos correspondientes se cumplen de acuerdo con el registro de cursos aprobados.

## collision.c / collision.h

Este módulo implementa la detección de choques entre horarios.

El proceso se divide en tres niveles:

- schedules_clash() compara dos franjas horarias y determina si se superponen durante el mismo día.

- groups_clash() compara todas las franjas horarias pertenecientes a dos grupos.

- Finalmente, detect_schedule_clashes() recorre los grupos de cursos distintos dentro del catálogo y marca aquellos que presentan al menos un choque.

La comparación utiliza intervalos semiabiertos:

[inicio, fin)

Por lo tanto, si una clase termina exactamente cuando otra inicia, no se considera que exista un choque.

## writer.c / writer.h

Este módulo se encarga de generar el archivo JSON de salida.

Su función principal es:

export_catalog()

La función recorre la estructura Catalog y escribe de manera jerárquica:

- Información de cada curso.
- Créditos.
- Prerrequisitos.
- Correquisitos.
- Indicadores calculados.
- Grupos.
- Horarios de cada grupo.

Las funciones auxiliares del módulo permiten escribir individualmente cursos, grupos, horarios y arreglos de códigos, manteniendo separada la lógica de serialización.

## CMakeLists.txt

Define la configuración necesaria para compilar el proyecto mediante CMake.

El proyecto utiliza el estándar C11 y genera un ejecutable denominado main a partir de los siguientes archivos:

- main.c
- loader.c
- writer.c
- collision.c
- prereq.validator.c

## 1.3 Flujo general del programa
El programa sigue un flujo secuencial en el que la información se carga, procesa y finalmente se exporta.
```text
        Archivos CSV de entrada
        ┌──────────────────────┐
        │ PlanEstudios.csv     │
        │ Horarios.csv         │
        │ Aprobados.csv        │
        └──────────┬───────────┘
                   │
                   ▼
              loader.c
                   │
                   ▼
        ┌──────────────────────┐
        │ Catalog              │
        │ Record               │
        └──────────┬───────────┘
                   │
           ┌───────┴────────┐
           ▼                ▼
 prereq.validator.c     collision.c
           │                │
           └───────┬────────┘
                   ▼
          Catálogo procesado
                   │
                   ▼
               writer.c
                   │
                   ▼
             Catalogo.json
```
De forma detallada, el flujo es el siguiente:

1. El programa inicia en main.c.

2. Se determinan los archivos de entrada. Por defecto se utilizan:

- PlanEstudios.csv
- Horarios.csv
- Aprobados.csv

También es posible indicar otras rutas mediante argumentos de línea de comandos.

- load_study_plan() lee el plan de estudios y crea los cursos dentro de la estructura Catalog.
- load_schedules() añade a esos cursos los grupos y horarios disponibles.
- load_record() carga en la estructura Record los cursos que el estudiante ya aprobó.  
Una vez construidas las estructuras principales, validate_catalog_requirements() analiza los prerrequisitos y correquisitos de los cursos utilizando el historial del estudiante.  
Posteriormente, detect_schedule_clashes() compara los horarios de los diferentes grupos y marca aquellos que presentan superposición horaria.

3. Finalmente, export_catalog() recorre el catálogo procesado y genera el archivo:

Catalogo.json

De esta manera, el programa mantiene separadas las responsabilidades de entrada, procesamiento y salida, mientras que main.c únicamente coordina el orden en que se ejecutan los diferentes módulos.

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


