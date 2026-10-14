#lang typed/racket

(provide (all-defined-out))

;; 1. Catalogo (viene de Catalogo.json, generado por la Etapa 1)

;; Un bloque horario de un grupo.
;; day: 0=lunes ... 6=domingo (igual que en C)
;; begin-time, end-time: minutos desde medianoche, intervalo [begin, end)
(struct Schedule ([day : Integer]
                  [begin-time : Integer]
                  [end-time : Integer])
  #:transparent)

;; Un grupo ofertado de un curso.
;; schedule-clash: viene calculado por C (choca con ALGUN otro grupo).
;; No dice con cual: el choque entre pares se recalcula en Racket.
(struct Group ([number : Integer]
               [schedule-clash : Boolean]
               [schedules : (Listof Schedule)])
  #:transparent)

;; Un curso del catalogo.
(struct Course ([code : String]
                [name : String]
                [credits : Integer]
                [prerequisites : (Listof String)]
                [corequisites : (Listof String)]
                [schedule-clash : Boolean]
                [can-enroll : Boolean]
                [career : String]
                [groups : (Listof Group)])
  #:transparent)

;; Catalogo completo al cargar. La persona 3 elimina cursos que no interesan.
(struct Catalog ([courses : (Listof Course)])
  #:transparent)

;; 2. Preferencias del estudiante

;; Interes en un curso: codigo + los grupos que le interesan.
(struct CourseInterest ([code : String]
                        [groups : (Listof Integer)])
  #:transparent)

;; Preferencias completas.
(struct Preferences ([interests : (Listof CourseInterest)]
                     [min-credits : Integer]
                     [max-credits : Integer])
  #:transparent)

;; Cursos ya filtrados por preferencias: lo que recibe el generador.
(define-type CandidateCourses (Listof Course))

;; 3. Combinaciones 

;; Un par curso-grupo elegido dentro de una combinacion.
;; Lleva career y credits para que exportar y filtrar no
;; tengan que volver a buscar el curso en el catalogo.
(struct Selection ([course : String]
                   [group : Integer]
                   [career : String]
                   [credits : Integer])
  #:transparent)

;; Una combinacion valida: un grupo por curso, sin choques.
(struct Combination ([selections : (Listof Selection)]
                     [total-credits : Integer])
  #:transparent)

;; 4. Alias de tipos (documentan intencion en las firmas)

;; Predicado de choque: recibe dos grupos y dice si chocan.
;; El generador lo recibe como parametro.
(define-type ClashPredicate (-> Group Group Boolean))

;; Flujo perezoso de combinaciones (lo que produce el generador).
(define-type CombinationStream (Sequenceof Combination))