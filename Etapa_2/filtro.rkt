#lang typed/racket

(require "types.rkt"
         "lazy.rkt")

(provide filter-stream filter-combinations)


;; se mantiene la evaluacion perezosa y se conservan los elementos aceptados.
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