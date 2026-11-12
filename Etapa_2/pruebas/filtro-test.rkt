#lang racket

(require rackunit
         racket/sequence
         racket/stream
         racket/runtime-path
         "../filtro.rkt"
         "../generator.rkt"
         "../clash.rkt"
         "../io.rkt"
         "../types.rkt")

(define-runtime-path catalog-path "../../Etapa_1_C/Catalogo.json")

(module+ test
  (check-equal?
   (sequence->list (filter-stream (stream 1 2 3 4) even?))
   '(2 4))

  (define course-groups
    (list (Group 1 #f (list (Schedule 0 480 540)))
          (Group 2 #f (list (Schedule 1 480 540)))))
  (define eligible-course
    (Course "CS101" "Programacion" 4 '() '() #f #t "Computacion" course-groups))
  (define ineligible-course
    (Course "CS102" "Requisitos pendientes" 3 '() '() #f #f "Computacion" course-groups))
  (define unrelated-course
    (Course "CS103" "No solicitado" 3 '() '() #f #t "Computacion" course-groups))
  (define candidate-preferences
    (Preferences (list (CourseInterest "CS101" '(2))
                       (CourseInterest "CS102" '(1)))
                 4 8))
  (define candidates
    (filter-candidate-courses
     (Catalog (list eligible-course ineligible-course unrelated-course))
     candidate-preferences))
    (check-equal? (map Course-code (Catalog-courses candidates)) '("CS101"))
  (check-equal? (map Group-number
                     (Course-groups (first (Catalog-courses candidates))))
                '(2))
    (check-equal?
     (map Combination-total-credits
       (sequence->list
        (generate-combinations
         (Catalog (list (first (Catalog-courses candidates))))
         groups-clash?)))
     '(4))

  (define preferences (Preferences '() 12 18))
  (define combinations
    (stream (Combination '() 11)
            (Combination '() 12)
            (Combination '() 18)
            (Combination '() 19)))
  (check-equal?
   (map Combination-total-credits
        (sequence->list (filter-combinations combinations preferences)))
   '(12 18))

  (define real-catalog (load-catalog catalog-path))
  (define real-preferences
    (Preferences (list (CourseInterest "CE1103" '(1))) 4 4))
  (define real-candidates
    (filter-candidate-courses real-catalog real-preferences))
  (check-not-false
   (member "CE1103" (map Course-code (Catalog-courses real-candidates))))
  (check-true
   (andmap Course-can-enroll (Catalog-courses real-candidates)))
  (define real-ce1103
    (filter-candidate-courses
     (Catalog (filter (lambda (course)
                        (string=? (Course-code course) "CE1103"))
                      (Catalog-courses real-catalog)))
     real-preferences))
  (check-equal? (map Course-code (Catalog-courses real-ce1103)) '("CE1103"))
  (check-equal?
   (map Combination-total-credits
        (sequence->list
         (filter-combinations
          (generate-combinations real-ce1103 groups-clash?)
          real-preferences)))
   '(4)))