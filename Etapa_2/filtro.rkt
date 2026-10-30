#lang typed/racket

(require "types.rkt"
         "lazy.rkt")

(provide filter-stream filter-candidate-courses filter-combinations)


;;busca el interes asociado al codigo de curso.
(: find-interest (-> String (Listof CourseInterest) (U False CourseInterest)))
(define (find-interest code interests)
  (cond
    [(null? interests) #f]
    [(string=? code (CourseInterest-code (first interests))) (first interests)]
    [else (find-interest code (rest interests))]))

;; Yo reviso si el numero de grupo aparece entre los grupos de interes.
(: selected-group? (-> Integer (Listof Integer) Boolean))
(define (selected-group? group-number selected-groups)
  (cond
    [(null? selected-groups) #f]
    [(= group-number (first selected-groups)) #t]
    [else (selected-group? group-number (rest selected-groups))]))

(: candidate-course (-> Course Preferences (U False Course)))
(define (candidate-course course preferences)
  (define interest
    (find-interest (Course-code course) (Preferences-interests preferences)))
  (cond
    [(not (Course-can-enroll course)) #f]
    [(not interest) #f]
    [else
     (define groups
       (filter (lambda ([group : Group])
                 (selected-group? (Group-number group)
                                  (CourseInterest-groups interest)))
               (Course-groups course)))
     (if (null? groups)
         #f
         (struct-copy Course course [groups groups]))]))

;; Yo conservo solo cursos habilitados escritos en intereses y sus grupos elegidos.
(: filter-candidate-courses (-> Catalog Preferences Catalog))
(define (filter-candidate-courses catalog preferences)
  (Catalog
   (let loop ([courses (Catalog-courses catalog)])
     (cond
       [(null? courses) '()]
       [else
        (define candidate (candidate-course (first courses) preferences))
        (if candidate
            (cons candidate (loop (rest courses)))
            (loop (rest courses)))]))))

;; Yo mantengo la evaluacion perezosa y solo conservo elementos aceptados.
(: filter-stream (All (A) (-> (Sequenceof A) (-> A Boolean) (Sequenceof A))))
(define (filter-stream items predicate)
  (cond
    [(lazy-empty? items) empty-lazy]
    [else
     (define item (lazy-first items))
     (if (predicate item)
         (lazy-cons item
                    (lambda ()
                      (filter-stream (lazy-rest items) predicate)))
         (filter-stream (lazy-rest items) predicate))]))

(: filter-combinations
   (-> CombinationStream Preferences CombinationStream))
(define (filter-combinations combinations preferences)
  ;;rango de creditos.
  (filter-stream
   combinations
   (lambda ([combination : Combination])
     (<= (Preferences-min-credits preferences)
         (Combination-total-credits combination)
         (Preferences-max-credits preferences)))))