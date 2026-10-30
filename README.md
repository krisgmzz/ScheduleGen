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
# 1. Arquitectura del proyecto: Etapa 2

La segunda etapa está implementada en Racket y aplica una organización modular. Recibe el catálogo JSON generado por la Etapa 1 y las preferencias del estudiante, genera combinaciones de cursos y grupos que no presentan choques, filtra los resultados por créditos y los exporta a otro archivo JSON.

## 1.1 Organización de archivos

La parte del proyecto correspondiente a esta etapa se organiza de la siguiente manera:

```text
ScheduleGen/
├── Etapa_1_C/
│   └── Catalogo.json          # Catálogo procesado por la primera etapa
└── Etapa_2/
    ├── main.rkt               # Punto de entrada y coordinación
    ├── types.rkt              # Estructuras y tipos del dominio
    ├── io.rkt                 # Lectura y escritura de archivos JSON
    ├── clash.rkt              # Detección de choques entre horarios
    ├── generator.rkt          # Generación perezosa de combinaciones
    ├── filtro.rkt             # Filtros de cursos y combinaciones
    ├── lazy.rkt               # Interfaz tipada para operaciones perezosas
    ├── lazy-untyped.rkt       # Implementación de operaciones sobre streams
    ├── Preferencias.json      # Preferencias de cursos, grupos y créditos
    ├── Combinaciones.json     # Archivo de salida
    └── pruebas/
        ├── demo-io.rkt
        ├── filtro-test.rkt
        └── io-test.rkt
```

`Catalogo.json` es la entrada que conecta ambas etapas. Contiene los cursos, sus grupos y horarios, además de información como créditos y elegibilidad. `Preferencias.json` indica los cursos y grupos de interés y el rango de créditos deseado. La Etapa 2 escribe las combinaciones resultantes en `Combinaciones.json`.

## 1.2 Responsabilidad de cada módulo

### `main.rkt`

Es el punto de entrada y coordina el proceso: carga el catálogo y las preferencias, inicia la generación de combinaciones, aplica el filtro de créditos y envía los resultados al módulo de salida.

### `types.rkt`

Define las estructuras y los tipos utilizados entre módulos. Entre ellos están `Schedule`, `Group`, `Course` y `Catalog` para representar la información de entrada; `Preferences` y `CourseInterest` para las preferencias; y `Selection` y `Combination` para representar las selecciones generadas. Sus anotaciones de tipos se escriben con Typed Racket.

### `io.rkt`

Lee y valida los archivos JSON, convierte sus datos en las estructuras del programa y exporta las combinaciones. Comprueba campos requeridos, tipos de datos, valores fuera de rango y duplicados, y reporta errores si los datos no cumplen con el formato esperado. La exportación escribe las combinaciones progresivamente, sin convertir todo el flujo en una lista.

### `clash.rkt`

Compara franjas horarias y grupos. Dos horarios chocan si ocurren el mismo día y sus intervalos se superponen; se usan intervalos semiabiertos `[inicio, fin)`, por lo que una clase puede empezar justo cuando termina otra.

### `generator.rkt`

Explora las opciones de cada curso: omitirlo o elegir uno de sus grupos. Antes de continuar con una selección, comprueba los choques contra los grupos ya elegidos y descarta las alternativas incompatibles. Los resultados se producen como un flujo perezoso.

### `filtro.rkt`

Contiene operaciones para conservar cursos habilitados que aparecen en las preferencias y limitar sus grupos a los seleccionados. También filtra el flujo de combinaciones para conservar únicamente las que están dentro del rango de créditos indicado.

### `lazy.rkt` y `lazy-untyped.rkt`

`lazy-untyped.rkt` implementa operaciones sobre streams, como construir un flujo, concatenarlo y obtener sus elementos. `lazy.rkt` ofrece esas operaciones a los módulos tipados mediante declaraciones de tipos.

## 1.3 Flujo general del programa

```text
Etapa 1                         Etapa 2
Catalogo.json ─────┐
                   ├──> io.rkt ──> Catalog + Preferences
Preferencias.json ─┘                         │
                                             ▼
                                    filtro.rkt: cursos y grupos
                                             │
                                             ▼
                              generator.rkt + clash.rkt
                                  combinaciones sin choques
                                             │
                                             ▼
                                 filtro.rkt: rango de créditos
                                             │
                                             ▼
                           io.rkt ──> Combinaciones.json
```

En resumen, `main.rkt` coordina la lectura de los datos, el filtrado y la generación, mientras que cada módulo se ocupa de una responsabilidad concreta. Los streams permiten producir y exportar las combinaciones progresivamente, sin requerir que todas se almacenen simultáneamente en memoria.

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

<<<<<<< HEAD
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
=======
>>>>>>> 4781d0d064757d39ce5cb1b400e4913c10ef2f87
