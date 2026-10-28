#lang typed/racket



(require "types.rkt"
         "lazy.rkt")

(provide generate-combinations)

;; El grupo choca con ALGUN grupo ya elegido?
;; Caso base: no hay grupos elegidos -> no hay choque.
(: clashes-with-chosen? (-> Group (Listof Group) ClashPredicate Boolean))
(define (clashes-with-chosen? g chosen clash?)
  (cond
    [(null? chosen) #f]
    [(clash? g (first chosen)) #t]
    [else (clashes-with-chosen? g (rest chosen) clash?)]))

;; Genera todas las combinaciones posibles a partir de los cursos que
;; faltan por decidir.
;;   courses       : cursos que faltan por decidir
;;   chosen-groups : grupos ya elegidos (para revisar choques)
;;   chosen        : selecciones ya elegidas (en orden inverso)
;;   credits       : creditos acumulados
;; Para cada curso hay dos opciones: saltarlo, o elegir uno de sus grupos.

(: build (-> (Listof Course) (Listof Group) (Listof Selection) Integer
             ClashPredicate CombinationStream))
(define (build courses chosen-groups chosen credits clash?)
  (cond
    ;; Caso base: ya se decidio sobre todos los cursos.
    ;; Se emite la combinacion, salvo que este vacia.
    [(null? courses)
     (if (null? chosen)
         empty-lazy
         (lazy-cons (Combination (reverse chosen) credits)
                    (lambda () empty-lazy)))]
    [else
     (let ([course (first courses)]
           [others (rest courses)])
       (lazy-append
        ;; Opcion 1: saltar este curso
        (build others chosen-groups chosen credits clash?)
        ;; Opcion 2: elegir uno de sus grupos
        (lambda ()
          (choose-group course (Course-groups course) others
                        chosen-groups chosen credits clash?))))]))

;; Prueba, uno por uno, los grupos de 'course'.
;;   groups : grupos del curso que faltan por probar
;;   others : cursos que faltan por decidir despues de este
(: choose-group (-> Course (Listof Group) (Listof Course) (Listof Group)
                    (Listof Selection) Integer ClashPredicate CombinationStream))
(define (choose-group course groups others chosen-groups chosen credits clash?)
  (cond
    [(null? groups) empty-lazy]
    [else
     (let ([g (first groups)])
       (if (clashes-with-chosen? g chosen-groups clash?)
           ;; Poda: este grupo choca, se descarta y se prueba el siguiente
           (choose-group course (rest groups) others
                         chosen-groups chosen credits clash?)
           (lazy-append
            ;; Se elige g y se sigue con los demas cursos
            (build others
                   (cons g chosen-groups)
                   (cons (Selection (Course-code course)
                                    (Group-number g)
                                    (Course-career course)
                                    (Course-credits course))
                         chosen)
                   (+ credits (Course-credits course))
                   clash?)
            ;; Despues, el siguiente grupo del mismo curso
            (lambda ()
              (choose-group course (rest groups) others
                            chosen-groups chosen credits clash?)))))]))

;; Punto de entrada: stream de combinaciones validas del catalogo.
(: generate-combinations (-> Catalog ClashPredicate CombinationStream))
(define (generate-combinations catalog clash?)
  (build (Catalog-courses catalog) '() '() 0 clash?))
