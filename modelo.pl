:- encoding(utf8).

:- module(modelo, [
    combinacion/3,
    curso_en_combinacion/2,
    cargar_combinaciones/1
]).

:- use_module(library(error)).
:- use_module(library(http/json)).

% Solo se modifican estos hechos para cargar las entradas del JSON.
% Los resultados intermedios de la evaluación se manejan con argumentos.
:- dynamic combinacion/3.

% Permite buscar cursos de una combinación o combinaciones de un curso.
curso_en_combinacion(Id, Curso) :-
    combinacion(Id, Cursos, _),
    member(Curso, Cursos).

% El JSON de Racket (version 2) incluye créditos y área por selección.
cargar_combinaciones(Ruta) :-
    setup_call_cleanup(
        open(Ruta, read, Entrada, [encoding(utf8)]),
        json_read_dict(Entrada, Documento),
        close(Entrada)),
    documento_combinaciones(Documento, Combinaciones),
    transaction((
        retractall(combinacion(_, _, _)),
        maplist(assertar_combinacion, Combinaciones)
    )).

documento_combinaciones(Documento, Combinaciones) :-
    must_be(dict, Documento),
    campo_requerido(Documento, version, Version),
    must_be(integer, Version),
    (   Version =:= 2
    ->  true
    ;   throw(error(domain_error(version_json_soportada, Version), _))
    ),
    campo_requerido(Documento, combinaciones, Entradas),
    must_be(list, Entradas),
    parsear_combinaciones(Entradas, 1, Combinaciones).

parsear_combinaciones([], _, []).
parsear_combinaciones([Entrada|Entradas], Id,
                      [combinacion(Id, Cursos, Total)|Combinaciones]) :-
    parsear_combinacion(Entrada, Cursos, Total),
    SiguienteId is Id + 1,
    parsear_combinaciones(Entradas, SiguienteId, Combinaciones).

parsear_combinacion(Entrada, Cursos, Total) :-
    must_be(dict, Entrada),
    campo_requerido(Entrada, selecciones, Selecciones),
    must_be(list, Selecciones),
    maplist(parsear_curso, Selecciones, Cursos),
    codigos_curso(Cursos, Codigos),
    sort(Codigos, CodigosUnicos),
    (   same_length(Codigos, CodigosUnicos)
    ->  true
    ;   throw(error(domain_error(cursos_unicos_en_combinacion, Codigos), _))
    ),
    campo_requerido(Entrada, creditos_totales, Total),
    must_be(nonneg, Total),
    creditos_de_cursos(Cursos, CreditosCalculados),
    (   Total =:= CreditosCalculados
    ->  true
    ;   throw(error(domain_error(creditos_totales, Total), _))
    ).

parsear_curso(Entrada, curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    must_be(dict, Entrada),
    campo_requerido(Entrada, curso, CodigoTexto),
    texto_a_atomo(CodigoTexto, Codigo),
    campo_requerido(Entrada, grupo, Grupo),
    must_be(nonneg, Grupo),
    campo_requerido(Entrada, creditos, Creditos),
    must_be(nonneg, Creditos),
    campo_requerido(Entrada, carrera, CarreraTexto),
    texto_a_atomo(CarreraTexto, Carrera),
    campo_requerido(Entrada, area, AreaTexto),
    texto_a_atomo(AreaTexto, Area).

campo_requerido(Dict, Campo, Valor) :-
    (   get_dict(Campo, Dict, Valor)
    ->  true
    ;   throw(error(existence_error(campo_json, Campo), _))
    ).

texto_a_atomo(Texto, Atomo) :-
    must_be(string, Texto),
    (   Texto \= ""
    ->  atom_string(Atomo, Texto)
    ;   throw(error(domain_error(texto_no_vacio, Texto), _))
    ).

codigos_curso([], []).
codigos_curso([curso(Codigo, _, _, _, _)|Cursos], [Codigo|Codigos]) :-
    codigos_curso(Cursos, Codigos).

creditos_de_cursos([], 0).
creditos_de_cursos([curso(_, _, Creditos, _, _)|Cursos], Total) :-
    creditos_de_cursos(Cursos, Resto),
    Total is Creditos + Resto.

assertar_combinacion(combinacion(Id, Cursos, Total)) :-
    assertz(combinacion(Id, Cursos, Total)).
