#lang racket

(require rackunit
         racket/sequence
         racket/stream
         "../filtro.rkt"
         "../types.rkt")

(module+ test
  (check-equal?
   (sequence->list (filter-stream (stream 1 2 3 4) even?))
   '(2 4))

  (define preferences (Preferences '() 12 18))
  (define combinations
    (stream (Combination '() 11)
            (Combination '() 12)
            (Combination '() 18)
            (Combination '() 19)))
  (check-equal?
   (map Combination-total-credits
        (sequence->list (filter-combinations combinations preferences)))
   '(12 18)))