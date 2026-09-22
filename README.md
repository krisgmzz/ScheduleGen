# CEmestre – Constructor de Horarios
## Etapa 1: Paradigma Imperativo 
## Lenguaje de Programación utilizado: C

Proyecto del curso CE1106 – Paradigmas de Programación  
Instituto Tecnológico de Costa Rica - Escuela de Ingeniería en Computadores

### Integrantes
- Litzy Casandra Bonilla Jimenez – Carné
- Daniel Roberto Ulate Solera – Carné
- Kristel Daniela Valverde Gómez – 2025143158

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

## 2.2 Caso límite real encontrado y su solución

## 2.3 Justificación del formato de salida

---
# 3. Estructuras de datos desarrolladas  


