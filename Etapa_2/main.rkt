#lang racket

;;ajusten los nombres a los archivos reales de cada uno 
(require "io.rkt"
         "generador.rkt"
         "filtro.rkt")

;;leer json generado en C y convertirlo en un Catalog
(define catalogo
  (load-catalog "../Etapa_1_C/Catalogo.json"))

;;leer preferencias del estudiante: cursos, grupos, créditos deseados
(define preferencias
  (load-preferences "Preferencias.json"))

;;llamar al generador para obtener combinaciones 
(define combinaciones
  (generar-combinaciones catalogo preferencias))

;;filtrar combinaciones
(define combinaciones-validas
  (filtrar-combinaciones combinaciones preferencias))

;;escribir combinaciones resultantes en un json 
(export-combinations
 "Combinaciones.json"
 combinaciones-validas)
