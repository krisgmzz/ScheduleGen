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

;; Las preferencias se leen, pero en esta etapa solo se usan los créditos.
(define preferencias
  (load-preferences preferencias-path))

;; Generar combinaciones sin choques y conservar solo las del rango de créditos.
(define combinaciones
  (generate-combinations catalogo groups-clash?))

(define combinaciones-validas
  (filter-combinations combinaciones preferencias))

;;escribir combinaciones resultantes en un json 
(export-combinations
 salida-path
 combinaciones-validas)
