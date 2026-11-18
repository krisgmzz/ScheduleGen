:- encoding(utf8).

:- module(evaluacion, [
    primera_violada/2,
    razon_rechazo/2,
    veredicto/2,
    rechazo_de/2
]).

:- use_module(modelo).
:- use_module(politica).

% ============================================================
% evaluacion.pl - Veredicto de cada combinación
%
% Usa los predicados viola_* de politica.pl, que tienen éxito
% cuando la combinación INCUMPLE la regla correspondiente.
% No guarda estado: todo se resuelve con argumentos y unificación.
% ============================================================

% primera_violada(+Cursos, -Regla)
% Regla es la PRIMERA regla incumplida, en este orden:
%   1. balance_entre_carreras
%   2. limite_por_area
%   3. incompatibilidad
% El orden de las cláusulas ES el orden de las reglas: si se quiere
% priorizar otra, basta con reordenar estas tres líneas.
% El corte (!) compromete la búsqueda con la primera regla violada,
% de modo que nunca se reporta más de una razón.
primera_violada(Cursos, balance_entre_carreras) :-
    viola_balance(Cursos), !.
primera_violada(Cursos, limite_por_area) :-
    viola_limite_area(Cursos), !.
primera_violada(Cursos, incompatibilidad) :-
    viola_incompatibilidad(Cursos), !.

% razon_rechazo(+Cursos, ?Razon)
% Igual que primera_violada, pero la razón se unifica DESPUÉS de
% calcular cuál es la primera. Así, consultar con Razon ya conocida
% solo tiene éxito si esa es de verdad la primera regla violada
% (sin esto, el corte dejaría pasar una regla posterior).
razon_rechazo(Cursos, Razon) :-
    primera_violada(Cursos, Primera),
    Razon = Primera.

% veredicto(+Cursos, ?Veredicto)
% Veredicto es aceptada o rechazada(Razon).
% Negación por falla: la combinación se acepta cuando NO existe
% ninguna regla violada. No hay una regla de "aceptación" aparte.
veredicto(Cursos, aceptada) :-
    \+ primera_violada(Cursos, _).
veredicto(Cursos, rechazada(Razon)) :-
    razon_rechazo(Cursos, Razon).

% rechazo_de(?Id, ?Razon)
% Predicado usable en varios modos (ver README):
%   (+,-)  razón de rechazo de una combinación concreta
%   (-,+)  combinaciones rechazadas por una razón (backtracking)
%   (-,-)  todas las combinaciones rechazadas con su razón
%   (+,+)  comprobar si una combinación se rechaza por esa razón
rechazo_de(Id, Razon) :-
    combinacion(Id, Cursos, _),
    razon_rechazo(Cursos, Razon).
