:- encoding(utf8).

:- module(modelo, [
    combinacion/3,
    curso_en_combinacion/2
]).

% Solo se modifican estos hechos para cargar las entradas del JSON.
% Los resultados intermedios de la evaluación se manejan con argumentos.
:- dynamic combinacion/3.

% Permite buscar cursos de una combinación o combinaciones de un curso.
curso_en_combinacion(Id, Curso) :-
    combinacion(Id, Cursos, _),
    member(Curso, Cursos).
