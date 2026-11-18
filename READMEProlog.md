# CEmestre – Constructor de Horarios
## Etapa 3: Paradigma Lógico 
## Lenguaje de Programación utilizado: Prolog

Proyecto del curso CE1106 – Paradigmas de Programación  
Instituto Tecnológico de Costa Rica - Escuela de Ingeniería en Computadores

### Integrantes
- Litzy Casandra Bonilla Jimenez – Carné
- Daniel Roberto Ulate Solera – 2025082290
- Kristel Daniela Valverde Gómez – 2025143158

## 1. Arquitectura del proyecto 
## 2. Decisiones de diseño 
### 2.1. Criterio de asignación de áreas

El área representa el contenido predominante del curso.

Cada curso tiene una sola área. Cursos de carreras distintas pueden compartirla cuando trabajan contenidos semejantes.

La clasificación combina asignaciones explícitas por código con reglas generales para prefijos conocidos. Las asignaciones explícitas tienen prioridad.

| Identificador | Contenido | Ejemplos |
|---|---|---|
| `ciencias_basicas` | Matemática, física, química, biología y métodos numéricos | `MA1103`, `FI1101`, `CE1111`, `MA3106` |
| `computacion` | Programación, algoritmos, bases de datos, compiladores, sistemas operativos y redes | `CE1101`, `CE3101`, `IA2204` |
| `arquitectura_digital` | Sistemas computacionales, diseño digital, arquitectura y sistemas empotrados | `CE1107`, `CE4302`, `CE1113` |
| `electronica` | Circuitos, electricidad, electrónica y señales | `EL2207`, `CE1112`, `IA3501` |
| `gestion_diseno` | Modelado, calidad de productos, economía y emprendimiento | `CE1105`, `CE1116`, `PI5516` |
| `agua_suelo_ambiente` | Suelos, hidráulica, hidrología, riego, drenaje y conservación | `IA2107`, `IA4307`, `IA4313` |
| `mecanica_topografia` | Dibujo, topografía, estática, materiales y maquinaria agrícola | `IA1203`, `IA3302`, `IA4403` |
| `produccion_agricola` | Fundamentos y sistemas de producción agrícola | `IA1002`, `IA2106` |
| `formacion_general` | Comunicación, idiomas, humanidades, legislación, ética y seguridad ocupacional | `CI1407`, `CS3404`, `SO4604` |
| `electivas` | Electivas genéricas cuyo contenido concreto no está identificado | `CE5701` |

Ejemplos que justifican la clasificación:

- `IA2204`, Programación Aplicada, pertenece a `computacion`, aunque su código comienza con `IA`.
- `CE1111`, Análisis Numérico para la Ingeniería, pertenece a `ciencias_basicas`, al igual que `MA3106`, Métodos Numéricos.
- `IA3501`, Electrificación Rural, pertenece a `electronica` por su contenido eléctrico.
- `CE5701` conserva el área `electivas` mientras represente una opción genérica. Si se incorpora una materia concreta, su clasificación debe revisarse.

Si aparece un código que no tiene una asignación ni coincide con una regla conocida, el preparador informa un error. Esto evita asignar un área arbitraria.

### 2.2. Pares incompatibles

La política acordada declara estos pares:

| Par | Justificación |
|---|---|
| `CE1101` — `IA2204` | Se decide evitar la selección simultánea de dos cursos que trabajan programación |
| `CE1111` — `MA3106` | Se decide evitar la selección simultánea de dos cursos relacionados con métodos numéricos |

Son restricciones elegidas por el grupo como política de no duplicación temática.

La relación es simétrica: si un par declara incompatibles A y B, también se consideran incompatibles B y A.

Los pares se escriben una sola vez en el archivo de política. La regla debe reconocer ambos sentidos.

### 2.3. Prioridad de las reglas

El orden acordado es:

1. Balance entre carreras.
2. Límite por área.
3. Incompatibilidad.

Una combinación puede incumplir varias reglas, pero se reporta únicamente la primera según ese orden.

#### Caso donde el orden modifica la razón

Se considera una combinación con:

- `CE1101`: 3 créditos, Ingeniería en Computadores, área `computacion`.
- `IA2204`: 3 créditos, Ingeniería Agrícola, área `computacion`.

Para este caso se utiliza temporalmente:

- Máximo de Computadores: 40 %.
- Máximo de Agrícola: 100 %.
- Máximo por área: 1 curso.
- Par incompatible: `CE1101` — `IA2204`.

La combinación incumple las tres reglas:

- Computadores aporta 50 %, superior a 40 %.
- Hay dos cursos de `computacion`, superior al máximo de uno.
- Ambos cursos forman un par incompatible.

Con el orden acordado se reporta `balance_carreras`. Si se revisara primero el área, se reportaría `limite_area`.

### 2.4. Caso límite y su solución: cursos de cero créditos

Si el total de créditos de una combinación es cero, se considera que cumple el
balance: al no haber créditos, no existe una proporción significativa que
comparar. Las reglas por área e incompatibilidad siguen aplicándose. Si el
total es positivo, un curso de cero créditos aporta cero al porcentaje de su
carrera.

## 3. Representación de datos y predicados principales

Las combinaciones se leen del JSON versión 2 que exporta Racket. Cada selección
incluye código, grupo, créditos, carrera y área. Prolog representa cada curso
como `curso(Codigo, Grupo, Creditos, Carrera, Area)` y cada combinación como
`combinacion(Id, Cursos, CreditosTotales)`. El identificador se asigna en el
orden en que aparecen las combinaciones en el archivo.

Los porcentajes máximos y el máximo de cursos por área se consultan de los
hechos de `politica.pl`; los valores son parámetros de política que el grupo
puede cambiar. Con los valores iniciales de 100 % para ambas carreras, el
balance no rechazará una combinación normal; acuerden los porcentajes finales
antes de la entrega.

`modelo:cargar_combinaciones/1` valida la versión y los campos requeridos,
comprueba que los cursos no se repitan y verifica que los créditos totales
coincidan con la suma de las selecciones. Si la carga falla, no reemplaza los
hechos previamente cargados.

Los predicados `politica:viola_balance/1`,
`politica:viola_limite_area/1` y
`politica:viola_incompatibilidad/1` reciben la lista de cursos de una
combinación y tienen éxito si esa lista incumple la regla correspondiente.
Balance compara créditos con una multiplicación entera equivalente al
porcentaje, sin redondear; los límites por área cuentan cursos, no créditos.
Los pares incompatibles se reconocen aunque los cursos aparezcan en cualquier
orden.

Las pruebas de política se ejecutan en SWI-Prolog con
`[pruebas_politica].` y `run_tests.`. El archivo de combinaciones generado
actualmente en `Etapa_2` es versión 1, no contiene créditos ni áreas y tiene
bytes nulos después del JSON. Hay que regenerarlo desde el exportador
actualizado de Racket (versión 2) antes de cargarlo en Prolog.
