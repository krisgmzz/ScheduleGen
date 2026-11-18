:- encoding(utf8).

:- module(politica, [
    max_porcentaje_carrera/2,
    max_cursos_area/1,
    par_incompatible/2,
    viola_balance/1,
    viola_limite_area/1,
    viola_incompatibilidad/1
]).

:- use_module(library(error)).

:- dynamic max_porcentaje_carrera/2.

% Porcentaje máximo de créditos que puede aportar cada carrera.
% Con 100 se permiten combinaciones de una sola carrera.
% El valor de 100 es un parámetro modificable.
max_porcentaje_carrera('Ingeniería en Computadores', 60).
max_porcentaje_carrera('Ingeniería Agrícola', 100).

% Máximo de cursos de una misma área dentro de una combinación.
% El valor 3 es un parámetro modificable
max_cursos_area(2).

% Pares incompatibles por la política de no duplicación temática.
% La regla de evaluación debe considerar ambos sentidos.
par_incompatible('MA2104', 'MA2105').

% Cada predicado tiene éxito únicamente si la lista incumple esa regla.
% Los cursos tienen la forma curso(Codigo, Grupo, Creditos, Carrera, Area).
viola_balance(Cursos) :-
    must_be(list, Cursos),
    creditos_de_lista(Cursos, Total),
    Total > 0,
    findall(Carrera,
            member(curso(_, _, _, Carrera, _), Cursos),
            CarrerasConRepetidos),
    sort(CarrerasConRepetidos, Carreras),
    member(Carrera, Carreras),
    creditos_por_carrera(Cursos, Carrera, CreditosCarrera),
    maximo_porcentaje(Carrera, Maximo),
    CreditosCarrera * 100 > Maximo * Total.

viola_limite_area(Cursos) :-
    must_be(list, Cursos),
    maximo_cursos_area(Maximo),
    findall(Area,
            member(curso(_, _, _, _, Area), Cursos),
            AreasConRepetidos),
    sort(AreasConRepetidos, Areas),
    member(Area, Areas),
    contar_cursos_area(Cursos, Area, Cantidad),
    Cantidad > Maximo.

viola_incompatibilidad(Cursos) :-
    must_be(list, Cursos),
    par_incompatible(CodigoA, CodigoB),
    member(curso(CodigoA, _, _, _, _), Cursos),
    member(curso(CodigoB, _, _, _, _), Cursos).

creditos_de_lista([], 0).
creditos_de_lista([curso(_, _, Creditos, _, _)|Cursos], Total) :-
    creditos_de_lista(Cursos, Resto),
    Total is Creditos + Resto.

creditos_por_carrera([], _, 0).
creditos_por_carrera(
    [curso(_, _, Creditos, Carrera, _)|Cursos], Carrera, Total) :-
    !,
    creditos_por_carrera(Cursos, Carrera, Resto),
    Total is Creditos + Resto.
creditos_por_carrera([_|Cursos], Carrera, Total) :-
    creditos_por_carrera(Cursos, Carrera, Total).

contar_cursos_area([], _, 0).
contar_cursos_area([curso(_, _, _, _, Area)|Cursos], Area, Total) :-
    !,
    contar_cursos_area(Cursos, Area, Resto),
    Total is Resto + 1.
contar_cursos_area([_|Cursos], Area, Total) :-
    contar_cursos_area(Cursos, Area, Total).

maximo_porcentaje(Carrera, Maximo) :-
    (   max_porcentaje_carrera(Carrera, Maximo)
    ->  must_be(integer, Maximo),
        (   between(0, 100, Maximo)
        ->  true
        ;   throw(error(domain_error(porcentaje_entre_0_y_100, Maximo), _))
        )
    ;   throw(error(existence_error(politica_porcentaje_carrera, Carrera), _))
    ).

maximo_cursos_area(Maximo) :-
    (   max_cursos_area(Maximo)
    ->  must_be(nonneg, Maximo)
    ;   throw(error(existence_error(politica_maximo_cursos_area, _), _))
    ).
