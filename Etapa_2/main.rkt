#lang racket

(require "io.rkt"
         "generator.rkt"
         "clash.rkt"
         "filtro.rkt"
         racket/runtime-path)

(define-runtime-path catalogo-path "../Etapa_1_C/Catalogo.json")
(define-runtime-path preferencias-path "Preferencias.json")
(define-runtime-path salida-path "Combinaciones.json")

;;leer json generado en C y convertirlo en un Catalog
(define catalogo
  (load-catalog catalogo-path))

;; Leo las preferencias para elegir cursos, grupos y rango de creditos.
(define preferencias
  (load-preferences preferencias-path))

;; Primero reduzco el catalogo a cursos habilitados y grupos de interes.
(define catalogo-candidato
  (filter-candidate-courses catalogo preferencias))

;; Genero combinaciones y luego filtro el rango de creditos.
(define combinaciones
  (generate-combinations catalogo-candidato groups-clash?))

(define combinaciones-validas
  (filter-combinations combinaciones preferencias))

;;escribir combinaciones resultantes en un json 
(export-combinations
 salida-path
 combinaciones-validas)
