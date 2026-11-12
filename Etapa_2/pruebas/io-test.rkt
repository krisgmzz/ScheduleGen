#lang racket
(require rackunit json racket/file racket/stream "../types.rkt" "../io.rkt")

(module+ test
  (define directory (make-temporary-file "schedulegen-~a" 'directory))
  (define input (build-path directory "entrada.json"))
  (define output (build-path directory "salida.json"))
  (define (put value)
    (call-with-output-file input
      (lambda (out) (write-json value out)) #:exists 'truncate/replace))
  (define schedule (hash 'dia 0 'inicio 480 'fin 530))
  (define group (hash 'numero 1 'choca_horario #f 'horarios (list schedule)))
  (define course
    (hash 'codigo "TEST01" 'nombre "Curso de prueba" 'creditos 3
          'carrera "Carrera A" 'prerrequisitos '() 'correquisitos '()
          'choca_horario #f 'puede_matricular #t 'grupos (list group)))
  (dynamic-wind
    void
    (lambda ()
      (put (hash 'cursos (list course)))
      (define catalog (load-catalog input))
      (check-equal? (Course-career (first (Catalog-courses catalog))) "Carrera A")
      (put (hash 'cursos (list (hash-remove course 'carrera))))
      (check-exn exn:fail? (lambda () (load-catalog input)))
      (put (hash 'cursos (list course course)))
      (check-exn exn:fail? (lambda () (load-catalog input)))
      (put (hash 'cursos (list (hash-set course 'puede_matricular "false"))))
      (check-exn exn:fail? (lambda () (load-catalog input)))
      (put (hash 'intereses (list (hash 'codigo "TEST01" 'grupos '(1 2)))
                 'creditos_minimos 3 'creditos_maximos 6))
      (check-equal? (CourseInterest-groups
                     (first (Preferences-interests (load-preferences input))))
                    '(1 2))
      (put (hash 'intereses '() 'creditos_minimos 7 'creditos_maximos 3))
      (check-exn exn:fail? (lambda () (load-preferences input)))
      (export-combinations output
        (stream (Combination (list (Selection "TEST01" 1 "Carrera A" 3)) 3)
                (Combination (list (Selection "TEST01" 2 "Carrera A" 3)) 3)))
      (define raw-output (file->string output))
      (check-true (regexp-match? #rx"},\n  {" raw-output))
      (define result (call-with-input-file output read-json))
      (check-equal? (hash-ref result 'version) 1)
      (check-equal? (length (hash-ref result 'combinaciones)) 2)
      (check-equal? (hash-ref (first (hash-ref result 'combinaciones)) 'creditos_totales) 3)
      (check-equal? (hash-ref
                     (first (hash-ref (first (hash-ref result 'combinaciones)) 'selecciones))
                     'carrera)
                    "Carrera A")
      (export-combinations output empty-stream)
      (check-equal? (hash-ref (call-with-input-file output read-json) 'combinaciones) '())
      (check-exn exn:fail?
        (lambda ()
          (export-combinations output
            (stream (Combination (list (Selection "TEST01" 1 "Carrera A" 3)) 9))))))
    (lambda () (delete-directory/files directory))))
