:- encoding(utf8).

:- use_module(library(main)).
:- use_module(modelo).
:- use_module(exportacion).



:- initialization(main, main).

main(Argv) :-
    (   argumentos(Argv, Entrada, Salida)
    ->  catch(ejecutar(Entrada, Salida),
              Error,
              ( print_message(error, Error), halt(1) ))
    ;   format(user_error,
               "Uso: swipl main.pl [combinaciones.json [resultado.json]]~n", []),
        halt(1)
    ).

argumentos([],        'Combinaciones.json', 'Resultado.json').
argumentos([E],       E,                    'Resultado.json').
argumentos([E, S],    E,                    S).

ejecutar(Entrada, Salida) :-
    cargar_combinaciones(Entrada),
    exportar_resultados(Salida),
    format("Resultado escrito en ~w~n", [Salida]).
