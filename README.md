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

Para representar el problema decidimos organizar la información en varias capas, primero está cada horario puntual, luego cada grupo que agrupa esos horarios, después el curso completo con sus requisitos y por último el catálogo general del plan de estudios, esta forma especifíca de estructurar los datos hace que el programa sea más claro y que cada parte del código se encargue de una cosa puntualmente, sin mezclar mucho las responsabilidades.

## 3.1 Schedule: el bloque básico del horario

La estructura más pequeña es `Schedule` y es la que representa una franja horaria concreta dentro de un grupo. Aquí guardamos:

- `day`: el día de la semana.
- `begin_time` y `end_time`: la hora de inicio y finalización, convertidas a minutos desde la medianoche.
- `aula`: el lugar donde se imparte la clase.

Esto nos sirve mucho porque cuando convertimos las horas a números, la comparación entre horarios queda mucho más simple, ya que en vez de estar revisando cadenas como "15:00" y "17:50", el programa compara enteros directamente para saber si hay solapamiento.

## 3.2 Group: varios horarios para un mismo grupo

Luego tenemos `Group`, que agrupa todas las franjas horarias de un mismo grupo. Un curso puede tener varios grupos, y cada grupo tiene su propia lista de horarios.

Dentro de esta estructura se guarda:

- el número del grupo.
- cuántos horarios tiene.
- si ese grupo presenta choque con otro.
- la lista de horarios asociados.

Es decir, `Group` es la representación de todas las clases que ofrece este grupo en particular. Aquí ya se empieza a ver cómo se modela la realidad del problema: cada curso no es solo un código, sino una oferta académica con varias opciones de horario.

## 3.3 Curso: la materia con sus requisitos y grupos

La estructura `Curso` es la más importante del sistema, porque representa la materia completa. 
Aquí se guarda la información que define al curso:

- código.
- nombre.
- créditos.
- cantidad de grupos disponibles.
- lista de grupos.
- prerrequisitos.
- correquisitos.
- dos banderas calculadas: si tiene choque de horario y si el estudiante puede matricularlo.

Esto hace que cada curso sea una entidad completa y propia. No solo conoce sus datos básicos,pero también si cumple con las condiciones académicas y si su oferta horaria es viable.

## 3.4 Catalog: el conjunto completo de cursos

`Catalog` es la estructura que reúne todos los cursos del plan de estudios. Tiene la cantidad total de cursos y un arreglo con ellos, es como la vista global del problema.

Con esta estructura el programa puede recorrer todo el catálogo para:

- revisar requisitos.
- detectar choques de horario.
- y generar el JSON final con la información procesada.

Es como tener el plan completo del estudiante en una sola estructura para poder analizarlo de manera ordenada.

## 3.5 Record: el historial del estudiante

Por otro lado, `Record` guarda los cursos aprobados por el estudiante. Esto es lo que permite validar si una materia realmente puede ser elegida, según lo que ya ha cursado.

En otras palabras, `Record` es la memoria académica del estudiante y sirve como base para decidir si cumple con los prerrequisitos y correquisitos.

## 3.6 Cómo encajan todas estas estructuras

La relación entre todo esto es bastante directa:

1. `Schedule` representa un horario puntual.
2. `Group` agrupa varios horarios de un grupo.
3. `Curso` reúne la información del curso y sus grupos.
4. `Catalog` reúne todos los cursos.
5. `Record` representa el historial académico del estudiante.

Y esta organización es útil porque cada parte del programa trabaja con la estructura adecuada, primero que todo los horarios se comparan para detectar choques, los cursos se validan según requisitos y el catálogo se recorre para obtener el resultado final. No hay una mezcla enorme de información ni una lógica dispersa por todos lados.

En resumen, el diseño busca que cada estructura represente bien una parte del problema sin complicar demasiado el código. Eso hace que el proyecto sea más mantenible y más fácil de extender cuando se necesite seguir desarrollando en la siguiente etapa.

---

