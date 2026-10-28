#lang typed/racket

(require "types.rkt")

(provide schedules-clash? groups-clash?)

(: schedules-clash? (-> Schedule Schedule Boolean))
(define (schedules-clash? a b)
  (and (= (Schedule-day a) (Schedule-day b))
       (< (Schedule-begin-time a) (Schedule-end-time b))
       (< (Schedule-begin-time b) (Schedule-end-time a))))

;; Un bloque choca a algun bloque de una lista?
;; Caso base: lista vacia, no hay choque.
;; Si pisa al primero, hay choque.
;; Si no, se revisa el resto de la lista.
(: clashes-with-any? (-> Schedule (Listof Schedule) Boolean))
(define (clashes-with-any? s schedules)
  (cond
    [(null? schedules) #f]
    [(schedules-clash? s (first schedules)) #t]
    [else (clashes-with-any? s (rest schedules))]))

;; Algun bloque de la primera lista choca a algun bloque de la segunda?
;; Caso base: primera lista vacia, no hay choque.
;; Si el primer bloque choca a alguno de la segunda lista, hay choque.
;; Si no, se repite con el resto de la primera lista.
(: any-clash? (-> (Listof Schedule) (Listof Schedule) Boolean))
(define (any-clash? as bs)
  (cond
    [(null? as) #f]
    [(clashes-with-any? (first as) bs) #t]
    [else (any-clash? (rest as) bs)]))

;; Dos grupos chocan?
;; Tiene el tipo ClashPredicate, asi que se puede pasar
;; directamente al generador.
(: groups-clash? ClashPredicate)
(define (groups-clash? a b)
  (any-clash? (Group-schedules a) (Group-schedules b)))

