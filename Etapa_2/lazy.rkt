#lang typed/racket

(require/typed "lazy-untyped.rkt"
  [lazy-cons (All (A) (-> A (-> (Sequenceof A)) (Sequenceof A)))]
  [empty-lazy (Sequenceof Nothing)]
  [lazy-first (All (A) (-> (Sequenceof A) A))]
  [lazy-rest (All (A) (-> (Sequenceof A) (Sequenceof A)))]
  [lazy-empty? (All (A) (-> (Sequenceof A) Boolean))]
  [lazy-append (All (A) (-> (Sequenceof A) (-> (Sequenceof A)) (Sequenceof A)))]
  [lazy->list (All (A) (-> (Sequenceof A) (Listof A)))]
  [lazy-take (All (A) (-> (Sequenceof A) Integer (Sequenceof A)))])

(provide lazy-cons empty-lazy lazy-first lazy-rest lazy-empty?
         lazy-append lazy->list lazy-take)