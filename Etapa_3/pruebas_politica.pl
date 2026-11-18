:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(politica).

:- begin_tests(politica).

test(balance_supera_maximo,
     [setup((
          retractall(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', _)),
          assertz(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', 50))
      )),
      cleanup((
          retractall(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', _)),
          assertz(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', 100))
      ))]) :-
    Cursos = [
        curso('CE1101', 1, 3, 'Ingeniería en Computadores', computacion),
        curso('IA2204', 1, 1, 'Ingeniería Agrícola', computacion)
    ],
    viola_balance(Cursos).

test(balance_igual_al_maximo_no_viola,
     [setup((
          retractall(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', _)),
          assertz(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', 50))
      )),
      cleanup((
          retractall(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', _)),
          assertz(politica:max_porcentaje_carrera(
              'Ingeniería en Computadores', 100))
      )),
      fail]) :-
    Cursos = [
        curso('CE1101', 1, 2, 'Ingeniería en Computadores', computacion),
        curso('IA2204', 1, 2, 'Ingeniería Agrícola', computacion)
    ],
    viola_balance(Cursos).

test(balance_total_cero_no_viola, [fail]) :-
    Cursos = [
        curso('CE1101', 1, 0, 'Ingeniería en Computadores', computacion),
        curso('IA2204', 1, 0, 'Ingeniería Agrícola', computacion)
    ],
    viola_balance(Cursos).

test(area_supera_maximo) :-
    Cursos = [
        curso('A', 1, 1, 'Ingeniería en Computadores', computacion),
        curso('B', 1, 1, 'Ingeniería en Computadores', computacion),
        curso('C', 1, 1, 'Ingeniería en Computadores', computacion),
        curso('D', 1, 1, 'Ingeniería en Computadores', computacion)
    ],
    viola_limite_area(Cursos).

test(area_igual_al_maximo_no_viola, [fail]) :-
    Cursos = [
        curso('A', 1, 1, 'Ingeniería en Computadores', computacion),
        curso('B', 1, 1, 'Ingeniería en Computadores', computacion),
        curso('C', 1, 1, 'Ingeniería en Computadores', computacion)
    ],
    viola_limite_area(Cursos).

test(incompatibilidad_simetrica) :-
    Cursos = [
        curso('IA2204', 1, 3, 'Ingeniería Agrícola', computacion),
        curso('CE1101', 1, 3, 'Ingeniería en Computadores', computacion)
    ],
    once(viola_incompatibilidad(Cursos)).

test(un_solo_curso_no_es_incompatible, [fail]) :-
    viola_incompatibilidad([
        curso('CE1101', 1, 3, 'Ingeniería en Computadores', computacion)
    ]).

:- end_tests(politica).
