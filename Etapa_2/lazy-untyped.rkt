#lang racket/base

(require racket/stream)

(provide lazy-cons empty-lazy lazy-first lazy-rest lazy-empty?
         lazy-append lazy->list lazy-take)

;; Construye un stream con 'x' al frente. 'rest-thunk' es una funcion
;; sin argumentos que produce el resto; NO se llama hasta que alguien
;; pide el segundo elemento (aqui esta la pereza).
(define (lazy-cons x rest-thunk)
  (stream-cons x (rest-thunk)))

(define empty-lazy empty-stream)

(define (lazy-first s) (stream-first s))
(define (lazy-rest s) (stream-rest s))
(define (lazy-empty? s) (stream-empty? s))

;; Concatena dos streams. El segundo viene como funcion sin argumentos
;; para que no se calcule hasta terminar de consumir el primero.
(define (lazy-append a b-thunk)
  (if (stream-empty? a)
      (b-thunk)
      (stream-cons (stream-first a)
                   (lazy-append (stream-rest a) b-thunk))))

(define (lazy->list s) (stream->list s))
(define (lazy-take s n) (stream-take s n))