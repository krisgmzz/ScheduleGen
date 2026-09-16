#include "structs.h"
#include "loader.h"
#include "writer.h"
#include <stdio.h>
#include <stdlib.h>

void imprimir_catalogo(Catalog *catalog) {
    printf("CATALOGO (%d cursos)\n", catalog->num_courses);
    for (int i = 0; i < catalog->num_courses; i++) {
        Curso *c = &catalog->courses[i];
        printf("\n[%d] %s - %s (%d creditos)\n", i, c->code, c->name, c->credits);

        printf("Prerrequisitos (%d): ", c->num_prerequisites);
        for (int j = 0; j < c->num_prerequisites; j++) {
            printf("%s ", c->requisites[j]);
        }
        printf("\n");

        printf("Correquisitos (%d): ", c->num_corequisites);
        for (int j = 0; j < c->num_corequisites; j++) {
            printf("%s ", c->corequisites[j]);
        }
        printf("\n");

        printf("Grupos (%d):\n", c->num_groups);
        for (int j = 0; j < c->num_groups; j++) {
            Group *g = &c->groups[j];
            printf("    Grupo %d - %d horario(s):\n", g->group_number, g->num_schedules);
            for (int k = 0; k < g->num_schedules; k++) {
                Schedule *s = &g->schedules[k];
                printf("      dia=%d %02d:%02d-%02d:%02d aula=%s\n",
                       s->day, s->begin_time / 60, s->begin_time % 60,
                       s->end_time / 60, s->end_time % 60, s->aula);
            }
        }
    }
    printf("\n");
}

void imprimir_record(Record *record) {
    printf("HISTORIAL (%d cursos aprobados)\n", record->num_completed_courses);
    for (int i = 0; i < record->num_completed_courses; i++) {
        printf("  %s\n", record->approved_courses[i]);
    }
    printf("\n");
}

int main(int argc, char *argv[]) {
    const char *plan_file = "PlanEstudios.csv";
    const char *horarios_file = "Horarios.csv";
    const char *record_file = "Aprobados.csv";

    if (argc == 4) {
        plan_file = argv[1];
        horarios_file = argv[2];
        record_file = argv[3];
    } else if (argc != 1) {
        fprintf(stderr, "Uso: %s [plan.csv horarios.csv aprobados.csv]\n", argv[0]);
        fprintf(stderr, "Sin argumentos, se usan los nombres por defecto.\n");
        exit(EXIT_FAILURE);
    }

    Record record;
    Catalog catalog;

    load_study_plan(plan_file, &catalog);
    load_schedules(horarios_file, &catalog);
    load_record(record_file, &record);

    imprimir_catalogo(&catalog);
    imprimir_record(&record);

    // Procesar requisitos y correquisitos 
    // Procesar choques de horario 

    export_catalog("Catalogo.csv", &catalog);

    return 0;
}