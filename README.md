# CEmestre – Constructor de Horarios
## Etapa 2: Paradigma Funcional
## Lenguaje de Programación utilizado: Racket

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
## 2. Decisiones de Diseño

Para la segunda etapa del proyecto CEmestre se decidió implementar una arquitectura modular utilizando Racket y los principios del paradigma funcional. El objetivo es generar combinaciones de horarios sin choques y filtrarlas según un rango de créditos, aprovechando el catálogo previamente procesado en la etapa desarrollada en C.

Las decisiones de diseño se enfocaron en separar responsabilidades, utilizar estructuras de datos inmutables y evitar la generación de listas completas de combinaciones, ya que la cantidad de posibilidades puede aumentar considerablemente según los cursos y grupos disponibles.

### 2.1. Justificación de las decisiones de implementación

**Separación del programa en módulos**

Se decidió dividir la implementación en diferentes archivos, cada uno con una responsabilidad específica. `io.rkt` se encarga de la lectura y escritura de archivos JSON; `types.rkt` define las estructuras de datos; `clash.rkt` implementa la detección de choques; `generator.rkt` construye las combinaciones; y `filtro.rkt` aplica los criterios de filtrado.

Adicionalmente, `lazy.rkt` y `lazy-untyped.rkt` proporcionan las operaciones necesarias para trabajar con streams, mientras que `main.rkt` coordina la ejecución general del programa.

Esta organización facilita las pruebas, el mantenimiento y la identificación de errores, ya que permite modificar una funcionalidad sin afectar directamente las responsabilidades de los demás módulos.

**Uso de streams y evaluación perezosa**

Se eligió utilizar streams en lugar de generar todas las combinaciones mediante listas completas. Esta decisión responde a que cada curso puede tener varios grupos, lo que aumenta significativamente la cantidad de combinaciones posibles.

Mediante la evaluación perezosa, las combinaciones se producen conforme se necesitan, sin almacenar necesariamente todas las alternativas en memoria. Para ello se implementaron operaciones como `lazy-cons` y `lazy-append`, que permiten construir y recorrer los resultados de forma progresiva.

**Generación mediante recursión e inmutabilidad**

La generación de combinaciones se desarrolló mediante funciones recursivas. Para cada curso, el programa considera la posibilidad de omitirlo o seleccionar uno de sus grupos disponibles. Antes de incorporar un grupo, verifica que no presente choques con los grupos seleccionados previamente.

Cuando se detecta una incompatibilidad, esa alternativa se descarta sin continuar construyendo la combinación. Esto reduce la exploración de opciones inválidas.

Además, el estado de cada combinación se transmite mediante parámetros de las funciones, sin modificar variables globales ni utilizar operaciones de mutación como `set!`. De esta manera, se respetan los principios del paradigma funcional.

**Uso de tipos explícitos y polimorfismo paramétrico**

Se utilizó Typed Racket para definir estructuras como `Course`, `Group`, `Schedule`, `Selection` y `Combination`, junto con sus respectivos tipos de datos.

Para las operaciones de entrada y salida se incorporaron contratos que permiten comprobar los datos recibidos y detectar errores en su estructura.

Asimismo, se implementó la función genérica `filter-stream`, utilizando polimorfismo paramétrico. Esta función recibe una secuencia y un predicado, por lo que puede reutilizarse para filtrar diferentes tipos de elementos sin desarrollar una función distinta para cada caso.

### 2.2. Caso límite identificado y solución implementada

Uno de los casos límite considerados fue la existencia de grupos cuyos horarios terminan exactamente cuando comienza otra clase.

Por ejemplo, si un grupo tiene una lección de 7:30 a 9:20 y otro comienza a las 9:20 del mismo día, ambos deben considerarse compatibles, ya que no existe una superposición real de tiempo.

Para resolverlo, en `clash.rkt` se implementó la comparación utilizando intervalos semiabiertos, donde el inicio pertenece al intervalo y el instante final queda excluido. De esta forma, únicamente se considera un choque cuando ambas franjas horarias presentan una superposición efectiva.

Esta decisión evita descartar combinaciones válidas debido a clases consecutivas y permite mantener un criterio consistente de detección de choques.

Adicionalmente, durante la lectura de archivos se contemplan situaciones como campos obligatorios ausentes, grupos sin horarios y códigos duplicados. En estos casos, `io.rkt` genera errores explícitos en lugar de continuar procesando información incorrecta.

### 2.3. Justificación del formato de salida

Se decidió utilizar JSON como formato de salida debido a que permite representar las combinaciones mediante una estructura jerárquica, clara y fácil de interpretar por las siguientes etapas del proyecto.

Cada combinación contiene una lista de selecciones, donde se identifica el código del curso, su grupo y la carrera de origen. También incluye el total de créditos correspondiente.

La estructura general es la siguiente:

```json
{
  "version": 1,
  "combinaciones": [
    {
      "selecciones": [
        {
          "curso": "CE1103",
          "grupo": 2,
          "carrera": "Ingeniería en Computadores"
        },
        {
          "curso": "MA1103",
          "grupo": 1,
          "carrera": "Ingeniería en Computadores"
        }
      ],
      "creditos_totales": 8
    }
  ]
}
```

*El ejemplo anterior es ilustrativo y no representa una combinación verificada con el catálogo.*

Una ventaja de este formato es que permite asociar directamente los cursos seleccionados con sus respectivos grupos y carreras, sin depender de posiciones específicas dentro de un archivo CSV.

Además, se decidió incluir el campo `version`, que permite identificar la estructura utilizada y facilita posibles modificaciones futuras al contrato de datos.

La exportación se implementó en `io.rkt`, escribiendo las combinaciones progresivamente conforme se recorren los streams. Esto evita convertir todos los resultados en una lista antes de generar el archivo.

Finalmente, JSON facilita la comunicación con la siguiente etapa desarrollada en Prolog, ya que proporciona una estructura organizada que puede ser interpretada para aplicar las restricciones adicionales del proyecto, sin necesidad de reconstruir las combinaciones desde cero.
---
# 3. Estructuras de datos desarrolladas

Para esta etapa se definieron las estructuras de datos en `types.rkt`, utilizando Typed Racket. Todas son inmutables, por lo que no se utiliza `#:mutable` ni `set!`. Cuando es necesario modificar algún dato, se crea una nueva instancia de la estructura. Por ejemplo, esto se utiliza al reducir los grupos disponibles de un curso mediante `struct-copy`.

Los nombres de las estructuras y sus campos están en inglés, mientras que las claves de los archivos JSON se mantienen en español. La conversión entre ambos se realiza desde `io.rkt`.

### Flujo de los datos

```text
Catalogo.json ──► Catalog ──► Catalog reducido ──► CombinationStream ──► CombinationStream ──► Combinaciones.json
Preferencias.json ─► Preferences   
```

### Catálogo

El catálogo utiliza estructuras similares a las que se desarrollaron en la primera etapa en C. La principal diferencia es que los arreglos con contadores, como `schedules[]` y `num_schedules`, se sustituyeron por listas, ya que en Racket estas permiten manejar los elementos sin tener que llevar un contador por separado.

| Struct | Campos | Descripción |
|---|---|---|
| `Schedule` | `day`, `begin-time`, `end-time` | Representa el horario de un grupo. Los días van de 0 (lunes) a 6 (domingo), y las horas se guardan como minutos desde la medianoche. |
| `Group` | `number`, `schedule-clash`, `schedules` | Contiene el número del grupo, sus horarios y un indicador de choque que viene calculado desde C. |
| `Course` | `code`, `name`, `credits`, `prerequisites`, `corequisites`, `schedule-clash`, `can-enroll`, `career`, `groups` | Almacena la información de cada curso. Se agregó el campo `career` para identificar a cuál de las dos carreras pertenece. |
| `Catalog` | `courses` | Contiene una lista de cursos. Se utiliza tanto para el catálogo original como para el catálogo reducido que se obtiene durante el filtrado. |

Se decidió utilizar el mismo tipo `Catalog` para ambas versiones, de manera que el generador pueda trabajar con cualquiera de ellas sin necesitar cambios adicionales.

Un detalle importante es que `schedule-clash`, en los grupos, indica si existe algún choque con otro grupo, pero no especifica con cuál. Por esta razón, los choques entre grupos se vuelven a calcular en Racket cuando se generan las combinaciones.

### Preferencias del estudiante

Para representar las preferencias se definieron dos estructuras:

| Struct | Campos | Descripción |
|---|---|---|
| `CourseInterest` | `code`, `groups` | Identifica un curso de interés y los grupos que el estudiante desea llevar. Se permiten varios grupos para un mismo curso. |
| `Preferences` | `interests`, `min-credits`, `max-credits` | Contiene los cursos de interés y el rango de créditos que se desea obtener. |

Esto permite representar las preferencias del estudiante de forma sencilla y facilita el filtrado inicial de los cursos y grupos disponibles.

### Combinaciones

Las combinaciones generadas también tienen sus propias estructuras:

| Struct | Campos | Descripción |
|---|---|---|
| `Selection` | `course`, `group`, `career`, `credits` | Representa un curso junto con el grupo seleccionado. También guarda la carrera y los créditos para evitar tener que consultar nuevamente el catálogo. |
| `Combination` | `selections`, `total-credits` | Representa una posible matrícula, con un máximo de un grupo por curso y sin choques de horario. |

Las selecciones se mantienen en el mismo orden en que aparecen los cursos en el catálogo. Además, no se genera una combinación vacía, ya que no representa una matrícula válida.

### Alias de tipos

También se definieron algunos alias para facilitar la lectura del código y especificar qué espera cada función:

- `ClashPredicate`: representa una función que recibe dos grupos y devuelve un booleano indicando si tienen un choque de horario. El generador recibe esta función como parámetro, por lo que no necesita conocer cómo se determina un choque. Esto permitió probar el generador utilizando una función sencilla mientras se desarrollaba la implementación definitiva (`groups-clash?`).
- `CombinationStream`: representa un flujo de combinaciones y se define como `(Sequenceof Combination)`. Es el tipo utilizado tanto por el generador como por el filtro de créditos.

### Uso de streams

Una de las principales consideraciones de esta etapa fue la cantidad de combinaciones que se pueden generar. Por ejemplo, con 12 cursos y 3 grupos disponibles para cada uno, se pueden obtener alrededor de 16 millones de posibilidades.

Generar todas esas combinaciones y almacenarlas en una lista consumiría demasiada memoria. Para evitarlo, se utilizaron streams de `racket/stream`, que permiten generar los resultados conforme se van necesitando, sin calcularlos todos desde el inicio.

Durante el desarrollo surgió un inconveniente con Typed Racket 8.10, ya que algunas operaciones de streams, como `stream-cons`, `stream` y `stream-first`, no cuentan con tipos disponibles para utilizarse directamente desde un módulo tipado.

Para resolverlo se separó esta funcionalidad en dos archivos:

- `lazy-untyped.rkt`: contiene las operaciones de `racket/stream` dentro de un módulo sin tipos.
- `lazy.rkt`: importa esas operaciones mediante `require/typed`, asignándoles los tipos genéricos correspondientes. Por ejemplo, `lazy-cons` recibe un elemento y una función que produce el resto del stream.

De esta forma, el resto del programa puede utilizar los streams sin tener que trabajar directamente con las operaciones sin tipos.

La generación perezosa se consigue utilizando una función sin argumentos (thunk) para representar el resto del stream. Esta función solamente se ejecuta cuando se solicita el siguiente elemento.

### Funcionamiento interno del generador

El generador no necesita variables mutables para llevar el control de la búsqueda. En su lugar, utiliza parámetros que se van pasando entre las llamadas recursivas:

- `courses`: contiene los cursos que todavía faltan por procesar.
- `chosen-groups`: guarda los grupos que ya fueron seleccionados. Se utiliza para comprobar si un nuevo grupo produce un choque con alguno de los anteriores.
- `chosen`: almacena las selecciones realizadas hasta el momento. Se utiliza `cons` para agregarlas al inicio de la lista y luego se invierte el orden al generar la combinación.
- `credits`: lleva la suma de los créditos de los cursos seleccionados.

Esta forma de trabajar permite mantener el estado de cada búsqueda de manera independiente. También facilita descartar posibilidades tan pronto como se detecta un choque de horario, sin necesidad de continuar explorando esa rama.

### Lectura, validación y escritura de datos

Toda la comunicación con los archivos JSON se maneja desde `io.rkt`. Al leer los archivos, `read-json` devuelve tablas hash, que posteriormente se convierten en las estructuras definidas en `types.rkt`.

Durante este proceso también se realizan varias validaciones para evitar trabajar con información incorrecta:

- No se permiten códigos de curso ni números de grupo duplicados.
- Los días deben estar dentro del rango de 0 a 6.
- La hora de inicio debe ser menor que la hora de finalización.
- Los horarios deben estar dentro de las 24 horas del día.
- Cada grupo debe tener al menos un horario.
- Los créditos mínimos no pueden ser mayores que los máximos.

Al escribir los resultados también se comprueba que los créditos totales de cada combinación coincidan con la suma de los créditos de sus selecciones.

Finalmente, los resultados se guardan en un archivo JSON que contiene una versión del formato y una lista llamada `combinaciones`. Cada elemento incluye sus `selecciones` (curso, grupo y carrera) y sus `creditos_totales`.

La escritura se realiza una combinación a la vez, directamente desde el stream. Así se evita convertir todos los resultados en una lista y se mantiene el uso de memoria bajo incluso cuando se generan muchas combinaciones.
