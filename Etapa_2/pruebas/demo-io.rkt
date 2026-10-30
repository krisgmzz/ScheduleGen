#lang racket

(require racket/stream racket/runtime-path "../types.rkt" "../io.rkt")
(define-runtime-path catalog-path "../../Etapa_1_C/Catalogo.json")
(define-runtime-path preferences-path "../Preferencias.json")
(define-runtime-path output-path "Combinaciones.demo.json")

(define catalog (load-catalog catalog-path))
(define preferences (load-preferences preferences-path))
(printf "Catálogo cargado: ~a cursos\n" (length (Catalog-courses catalog)))
(printf "Rango solicitado: ~a a ~a créditos\n"
        (Preferences-min-credits preferences)
        (Preferences-max-credits preferences))

;; DEMOSTRACIÓN de escritura, NO es el generador de horarios.
(define demonstration
  (stream
   (Combination
    (list (Selection "DEMO01" 1 "Carrera A" 3)
          (Selection "DEMO02" 2 "Carrera B" 4))
    7)))
(export-combinations output-path demonstration)
(printf "Ejemplo ficticio exportado: ~a\n" output-path)
