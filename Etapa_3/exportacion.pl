:- encoding(utf8).

:- module(exportacion, [exportar_resultados/1]).

:- use_module(library(http/json)).
:- use_module(modelo).
:- use_module(evaluacion).

% exportar_resultados(+Ruta)
% Recorre TODAS las combinaciones cargadas por backtracking
% (findall sobre combinacion/3) y escribe un solo documento JSON.
exportar_resultados(Ruta) :-
    findall(Resultado,
            ( combinacion(Id, Cursos, Total),
              resultado(Id, Cursos, Total, Resultado) ),
            Resultados),
    Documento = _{version: 1, resultados: Resultados},
    setup_call_cleanup(
        open(Ruta, write, Salida, [encoding(utf8)]),
        ( json_write_dict(Salida, Documento), nl(Salida) ),
        close(Salida)).

% resultado(+Id, +Cursos, +Total, -Dict)
resultado(Id, Cursos, Total, _{id: Id,
                               selecciones: Selecciones,
                               creditos_totales: Total,
                               cumple: Cumple,
                               razon: Razon}) :-
    maplist(seleccion_dict, Cursos, Selecciones),
    veredicto(Cursos, Veredicto),
    veredicto_campos(Veredicto, Cumple, Razon).

% Traduce aceptada/rechazada(R) a los campos "cumple" y "razon".
veredicto_campos(aceptada, true, null).
veredicto_campos(rechazada(Razon), false, Razon).

seleccion_dict(curso(Codigo, Grupo, Creditos, Carrera, Area),
               _{curso: Codigo, grupo: Grupo, creditos: Creditos,
                 carrera: Carrera, area: Area}).
