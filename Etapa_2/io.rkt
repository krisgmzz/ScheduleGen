#lang racket

;; Este módulo usa contratos explícitos
(require json racket/contract racket/sequence racket/stream "types.rkt")

(provide load-catalog load-preferences export-combinations)

;; load-catalog leer el catálogo producido en C
;; load-preferences leer las preferencias del estudiante 
;; export-combinations escribir el resultado

(define (fail format-text . arguments)
  (apply error 'io format-text arguments))

(define (field object key)
  (unless (hash? object) (fail "Se esperaba un objeto JSON: ~e" object))
  (hash-ref object key (lambda () (fail "Falta el campo ~a" key))))

(define (text value)
  (unless (and (string? value) (not (string=? value "")))
    (fail "Se esperaba un texto no vacío: ~e" value))
  value)

(define (natural value)
  (unless (exact-nonnegative-integer? value)
    (fail "Se esperaba un entero no negativo: ~e" value))
  value)

(define (boolean value)
  (unless (boolean? value) (fail "Se esperaba un booleano: ~e" value))
  value)

(define (array value)
  (unless (list? value) (fail "Se esperaba un arreglo JSON: ~e" value))
  value)

(define (unique values description)
  (unless (= (length values) (length (remove-duplicates values)))
    (fail "Hay duplicados en ~a" description)))

(define (read-document path)
  (call-with-input-file path
    (lambda (in)
      (define document (read-json in))
      (unless (eof-object? (read-json in))
        (fail "Hay contenido adicional después del JSON en ~a" path))
      document)))

(define (json->schedule value)
  (define day (natural (field value 'dia)))
  (define begin (natural (field value 'inicio)))
  (define end (natural (field value 'fin)))
  (unless (and (<= day 6) (< begin end) (<= end 1440))
    (fail "Franja horaria fuera de rango: ~e" value))
  (Schedule day begin end))

(define (json->group value)
  (define schedules (map json->schedule (array (field value 'horarios))))
  ;; Se rechazan horarios desconocidos: una lista vacía no significa libre.
  (when (null? schedules) (fail "Grupo sin horarios: ~e" value))
  (Group (natural (field value 'numero))
         (boolean (field value 'choca_horario))
         schedules))

(define (json->course value)
  (define groups (map json->group (array (field value 'grupos))))
  (unique (map Group-number groups) "grupos del mismo curso")
  (Course (text (field value 'codigo))
          (text (field value 'nombre))
          (natural (field value 'creditos))
          (map text (array (field value 'prerrequisitos)))
          (map text (array (field value 'correquisitos)))
          (boolean (field value 'choca_horario))
          (boolean (field value 'puede_matricular))
          (text (field value 'carrera))
          groups))

(define/contract (load-catalog path)
  (-> path-string? Catalog?)
  (define courses
    (map json->course (array (field (read-document path) 'cursos))))
  (unique (map Course-code courses) "códigos del catálogo")
  (Catalog courses))

(define (json->interest value)
  (define groups (map natural (array (field value 'grupos))))
  (when (null? groups) (fail "Debe indicar al menos un grupo por interés"))
  (unique groups "grupos de interés")
  (CourseInterest (text (field value 'codigo)) groups))

(define/contract (load-preferences path)
  (-> path-string? Preferences?)
  (define document (read-document path))
  (define interests
    (map json->interest (array (field document 'intereses))))
  (define minimum (natural (field document 'creditos_minimos)))
  (define maximum (natural (field document 'creditos_maximos)))
  (unless (<= minimum maximum)
    (fail "Los créditos mínimos no pueden superar los máximos"))
  (unique (map CourseInterest-code interests) "cursos de interés")
  (Preferences interests minimum maximum))

(define (selection->json selection)
  (hash 'curso (Selection-course selection)
        'grupo (Selection-group selection)
        'carrera (Selection-career selection)))

(define (combination->json combination)
  (unless (Combination? combination)
    (fail "El exportador recibió un valor que no es Combination: ~e" combination))
  (define selections (Combination-selections combination))
  (unique (map Selection-course selections) "cursos de una combinación")
  (for ([selection (in-list selections)])
    (text (Selection-course selection))
    (text (Selection-career selection))
    (natural (Selection-group selection))
    (natural (Selection-credits selection)))
  (define total (natural (Combination-total-credits combination)))
  (unless (= total (for/sum ([selection (in-list selections)])
                     (Selection-credits selection)))
    (fail "El total de créditos no coincide con las selecciones"))
  (hash 'selecciones (map selection->json selections)
        'creditos_totales total))

(define/contract (export-combinations path combinations)
  (-> path-string? sequence? void?)
  ;; Escribe una combinación por vez. Acepta un stream sin convertirlo a lista.
  ;; La recursión mantiene el separador sin set! ni contadores mutables.
  (call-with-output-file path
    (lambda (out)
      (display "{\"version\":1,\"combinaciones\":[\n  " out)
      (let loop ([remaining (sequence->stream combinations)] [first? #t])
        (unless (stream-empty? remaining)
          (unless first? (display ",\n  " out))
          (write-json (combination->json (stream-first remaining)) out)
          (loop (stream-rest remaining) #f)))
      (display "\n]}\n" out))
    #:exists 'truncate/replace)
  (void))
