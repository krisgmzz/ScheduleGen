# CEmestre – Constructor de Horarios
## Etapa 3: Paradigma Lógico 
## Lenguaje de Programación utilizado: Prolog

Proyecto del curso CE1106 – Paradigmas de Programación  
Instituto Tecnológico de Costa Rica - Escuela de Ingeniería en Computadores

### Integrantes
- Litzy Casandra Bonilla Jimenez – Carné
- Daniel Roberto Ulate Solera – 2025082290
- Kristel Daniela Valverde Gómez – 2025143158

# 0. Instrucciones de uso

La tercera etapa está escrita en SWI-Prolog. Usa `transaction/1` y diccionarios, así que conviene una versión reciente (serie 9.x). Su trabajo es leer el JSON versión 2 (versión que incluye áreas) que exporta la etapa de Racket, revisar cada combinación de cursos contra la política acordada por el grupo y escribir un nuevo JSON con el veredicto de cada una: si cumple, y si no cumple, por qué.

Se ejecuta desde la carpeta de la etapa con:

```bash
swipl main.pl [combinaciones.json [resultado.json]]
```

Sin argumentos, el programa busca `Combinaciones.json` en la carpeta actual y escribe `Resultado.json` al lado. Con un argumento se cambia el archivo de entrada, y con dos se cambian entrada y salida. Con más de dos argumentos muestra un mensaje de uso y termina con código 1. Lo mismo ocurre si la carga falla (archivo inexistente, versión distinta de 2, campos faltantes, créditos que no cuadran): el error se imprime y el programa termina con código 1 sin escribir nada.


# 1. Arquitectura del proyecto

La etapa 3 es la parte lógica del proyecto. Las etapas anteriores generan las combinaciones posibles; aquí se decide cuáles son aceptables. Lo dividimos en cinco archivos, cada uno con una sola responsabilidad, de manera que cambiar una regla de la política no obligue a tocar la lectura del JSON ni la escritura del resultado.

## 1.1 Organización de archivos

```text
Etapa_3/
│
├── main.pl            punto de entrada, argumentos y manejo de errores
├── modelo.pl          lectura, validación y almacenamiento de las combinaciones
├── politica.pl        parámetros de la política y las tres reglas
├── evaluacion.pl      prioridad entre reglas y veredicto final
├── exportacion.pl     escritura del JSON de resultados
│
├── Combinaciones.json     entrada (versión 2, generada por Racket)
└── Resultado.json         salida
```

## 1.2 Responsabilidad de cada módulo

**main.pl** es el único archivo que se ejecuta directamente. Interpreta los argumentos de la línea de comandos, decide los nombres de entrada y salida, llama a la carga y luego a la exportación. Envuelve todo en un `catch/3`, de modo que cualquier error de los otros módulos se convierte en un mensaje legible y en un `halt(1)`, en lugar de una traza de Prolog.

**modelo.pl** es el dueño de los datos. Lee el JSON, lo valida y guarda cada combinación como un hecho `combinacion/3`. Es el único lugar donde se modifica la base de hechos con las entradas. También ofrece `curso_en_combinacion/2` para buscar los cursos de una combinación o las combinaciones que contienen un curso.

**politica.pl** concentra todo lo que el grupo puede querer cambiar: el porcentaje máximo de créditos por carrera, el máximo de cursos por área y los pares incompatibles. Junto a esos parámetros están los tres predicados que dicen si una lista de cursos incumple cada regla. No decide cuál regla se reporta; solo responde sí o no a cada una.

**evaluacion.pl** pone el orden. Aquí vive la prioridad entre reglas y la construcción del veredicto (`aceptada` o `rechazada(Razon)`). También ofrece `rechazo_de/2`, pensado para consultar combinaciones por su razón de rechazo.

**exportacion.pl** recorre todas las combinaciones cargadas, pide el veredicto de cada una a `evaluacion.pl` y escribe un único documento JSON.

## 1.3 Flujo general del programa

El flujo es lineal y se parece al de la etapa 1: se carga, se procesa y se exporta. Lo único que cambia es que el procesamiento no es un recorrido explícito, sino consultas que Prolog resuelve por unificación y backtracking.

```text
 Combinaciones.json   (versión 2, exportado por Racket)
          │
          ▼
  ┌───────────────┐
  │   modelo.pl   │   valida y guarda  combinacion(Id, Cursos, Total)
  └───────┬───────┘
          │
          ▼
  ┌───────────────┐   veredicto(Cursos, V)   ┌────────────────┐
  │ exportacion.pl│ ───────────────────────► │ evaluacion.pl  │
  └───────┬───────┘                          └───────┬────────┘
          │                                          │ ¿viola esta regla?
          │                                          ▼
          │                                  ┌────────────────┐
          │                                  │  politica.pl   │
          │                                  └────────────────┘
          ▼
   Resultado.json
```

`main.pl` queda por fuera del diagrama porque solo coordina: llama a `cargar_combinaciones/1`, después a `exportar_resultados/1`, y avisa en pantalla dónde quedó el resultado.

El detalle es el siguiente. `main.pl` determina las rutas y llama a `cargar_combinaciones/1`, que lee el archivo, comprueba cada campo y, solo si todo está bien, reemplaza los hechos anteriores por los nuevos. Luego `exportar_resultados/1` recorre las combinaciones con `findall/3`; para cada una arma la lista de selecciones y le pregunta a `veredicto/2` si es aceptable. Ese predicado, a su vez, le pregunta a `politica.pl` regla por regla, en el orden acordado, y se queda con la primera que falla.

# 2. Decisiones de diseño

## 2.1 Criterio de asignación de áreas

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

Algunos ejemplos que justifican la clasificación:

`IA2204`, Programación Aplicada, pertenece a `computacion` aunque su código comience con `IA`. `CE1111`, Análisis Numérico para la Ingeniería, pertenece a `ciencias_basicas`, al igual que `MA3106`, Métodos Numéricos. `IA3501`, Electrificación Rural, pertenece a `electronica` por su contenido eléctrico. `CE5701` conserva el área `electivas` mientras represente una opción genérica; si se incorpora una materia concreta, su clasificación debe revisarse.

Si aparece un código que no tiene una asignación ni coincide con una regla conocida, el preparador de la etapa anterior informa un error. Esto evita asignar un área arbitraria. En Prolog el área llega ya resuelta dentro de cada selección y la regla de límite por área solo la usa para contar.

## 2.2 Pares incompatibles

Los pares incompatibles son una política de no duplicación temática: restricciones que el grupo eligió para evitar que una misma combinación contenga dos cursos que cubren lo mismo. La política vigente declara el par `MA2104` — `MA2105`.

La relación es simétrica. Los pares se escriben una sola vez en `politica.pl` y la regla no distingue el orden: comprueba por separado que ambos cursos estén en la combinación, de modo que da igual cuál aparezca primero en la lista y cuál esté a la izquierda en la declaración del par.

## 2.3 Prioridad de las reglas

El orden acordado es balance entre carreras, límite por área e incompatibilidad. Una combinación puede incumplir varias reglas a la vez, pero se reporta únicamente la primera según ese orden.

```text
  combinación
       │
       ▼
  ¿viola el balance entre carreras? ── sí ──► rechazada(balance_entre_carreras)
       │ no
       ▼
  ¿viola el límite por área? ──────── sí ──► rechazada(limite_por_area)
       │ no
       ▼
  ¿hay un par incompatible? ───────── sí ──► rechazada(incompatibilidad)
       │ no
       ▼
    aceptada
```

En el código ese orden es literalmente el orden de las tres cláusulas de `primera_violada/2`. Cada cláusula tiene un corte (`!`) después de comprobar su regla, así que en cuanto una falla las demás ni se miran. Si el grupo decide priorizar otra regla, basta con reordenar esas tres líneas.

Para ver un caso donde el orden cambia la razón, se considera una combinación con `CE1101` (3 créditos, Ingeniería en Computadores, área `computacion`) y `IA2204` (3 créditos, Ingeniería Agrícola, área `computacion`). Si se usan temporalmente un máximo de 40 % para Computadores, 100 % para Agrícola, un curso por área y el par `CE1101` — `IA2204` como incompatible, la combinación incumple las tres reglas: Computadores aporta 50 %, hay dos cursos de `computacion` y los dos forman un par incompatible. Con el orden acordado se reporta `balance_entre_carreras`; si se revisara primero el área, se reportaría `limite_por_area`.

Una consecuencia de usar cortes es que `primera_violada/2` por sí sola no sirve para preguntar «¿esta combinación se rechaza por la regla X?». Si la combinación viola el balance y el área, y se pregunta por el área, la cláusula del balance no unifica con ese átomo y la del área sí tendría éxito, aunque no sea la primera. Por eso existe `razon_rechazo/2`: primero calcula cuál es de verdad la primera regla violada y solo después la compara con la razón que se preguntó.

## 2.4 Caso límite y su solución: cursos de cero créditos

Si el total de créditos de una combinación es cero, se considera que cumple el balance: al no haber créditos, no existe una proporción significativa que comparar. Las reglas por área e incompatibilidad siguen aplicándose. Si el total es positivo, un curso de cero créditos aporta cero al porcentaje de su carrera.

En la práctica, `viola_balance/1` exige `Total > 0` antes de hacer cualquier otra cosa, así que con total cero simplemente falla, que en esta convención significa «no incumple».

## 2.5 Aritmética entera y aceptación por negación

Dos decisiones más pequeñas que vale la pena dejar escritas. La primera es que el balance no usa porcentajes con decimales. En lugar de calcular `creditos / total * 100` y comparar contra el máximo, se compara `creditos * 100 > maximo * total`, que es lo mismo pero con enteros, sin redondeos ni errores de coma flotante. Un 60 % exacto está permitido; solo se rechaza lo que supera estrictamente el máximo.

La segunda es que no existe una regla de aceptación. Una combinación se acepta cuando no existe ninguna regla violada, es decir, cuando `primera_violada/2` falla. Es negación por falla: si más adelante se agrega una regla, la aceptación se ajusta sola.

# 3. Representación de datos y predicados principales

Las combinaciones se leen del JSON versión 2 que exporta Racket. Cada selección incluye código, grupo, créditos, carrera y área. Prolog representa cada curso como

```prolog
curso(Codigo, Grupo, Creditos, Carrera, Area)
```

y cada combinación como

```prolog
combinacion(Id, Cursos, CreditosTotales)
```

El identificador se asigna en el orden en que aparecen las combinaciones en el archivo, empezando en 1. Los textos del JSON (código, carrera, área) se convierten a átomos al cargarlos; es necesario porque los parámetros de la política están escritos como átomos y solo así unifican.

`modelo:cargar_combinaciones/1` valida que la versión sea 2, que existan los campos requeridos y tengan el tipo correcto, que los cursos de una combinación no se repitan y que los créditos totales coincidan con la suma de las selecciones. Todo se procesa primero en memoria y solo al final se reemplazan los hechos, dentro de una transacción. Si algo falla, los hechos previamente cargados quedan intactos.

Los porcentajes máximos y el máximo de cursos por área se consultan de los hechos de `politica.pl`; son parámetros que el grupo puede cambiar. Con la política vigente, Ingeniería en Computadores puede aportar como máximo el 60 % de los créditos de una combinación, Ingeniería Agrícola hasta el 100 % (se permiten combinaciones de una sola carrera agrícola), y se aceptan hasta 2 cursos de una misma área. Si aparece una carrera sin porcentaje declarado, la evaluación lanza un error en lugar de suponer un valor.

Los predicados `politica:viola_balance/1`, `politica:viola_limite_area/1` y `politica:viola_incompatibilidad/1` reciben la lista de cursos de una combinación y tienen éxito si esa lista incumple la regla correspondiente. El balance compara créditos con una multiplicación entera equivalente al porcentaje, sin redondear; los límites por área cuentan cursos, no créditos; y los pares incompatibles se reconocen aunque los cursos aparezcan en cualquier orden.

Encima de esas reglas, `evaluacion.pl` ofrece:

`primera_violada(+Cursos, -Regla)` devuelve la primera regla incumplida según la prioridad. `razon_rechazo(+Cursos, ?Razon)` hace lo mismo pero permite preguntar por una razón concreta sin que el corte la deje pasar. `veredicto(+Cursos, ?Veredicto)` produce `aceptada` o `rechazada(Razon)`.

## 3.1 rechazo_de/2 y sus modos de uso

`rechazo_de(?Id, ?Razon)` trabaja sobre las combinaciones ya cargadas y se puede usar de cuatro maneras, según qué argumento esté ligado:

```prolog
?- rechazo_de(3, Razon).                    % (+,-) por qué se rechaza la combinación 3
?- rechazo_de(Id, limite_por_area).         % (-,+) cuáles se rechazan por esa razón
?- rechazo_de(Id, Razon).                   % (-,-) todas las rechazadas, con su razón
?- rechazo_de(3, balance_entre_carreras).   % (+,+) comprobar si esa es la razón
```

En los modos con `Id` sin ligar, Prolog va entregando una combinación tras otra por backtracking (`;` en el intérprete). Una combinación aceptada simplemente no aparece, porque no tiene razón de rechazo.

## 3.2 Formato de salida

El resultado es un único documento JSON con una entrada por combinación, en el mismo orden de ids. La salida lleva su propio número de versión.

```json
{
  "version": 1,
  "resultados": [
    {
      "id": 1,
      "selecciones": [
        { "curso": "CE1101", "grupo": 1, "creditos": 3,
          "carrera": "Ingeniería en Computadores", "area": "computacion" }
      ],
      "creditos_totales": 3,
      "cumple": false,
      "razon": "balance_entre_carreras"
    }
  ]
}
```

Cuando la combinación cumple, `cumple` es `true` y `razon` es `null`. Se repiten las selecciones completas en cada resultado para que quien consuma el archivo no necesite el de entrada para entender qué se evaluó.

## 3.3 Pruebas

Las pruebas de política están en `pruebas_politica.pl` y se ejecutan en SWI-Prolog con:

```prolog
?- [pruebas_politica].
?- run_tests.
```