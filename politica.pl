:- encoding(utf8).

:- module(politica, [
    max_porcentaje_carrera/2,
    max_cursos_area/1,
    par_incompatible/2
]).

% Porcentaje máximo de créditos que puede aportar cada carrera.
% Con 100 se permiten combinaciones de una sola carrera.
% El valor de 100 es un parámetro modificable.
max_porcentaje_carrera('Ingeniería en Computadores', 100).
max_porcentaje_carrera('Ingeniería Agrícola', 100).

% Máximo de cursos de una misma área dentro de una combinación.
% El valor 3 es un parámetro modificable
max_cursos_area(3).

% Pares incompatibles por la política de no duplicación temática.
% La regla de evaluación debe considerar ambos sentidos.
par_incompatible('CE1101', 'IA2204').
par_incompatible('CE1111', 'MA3106').
