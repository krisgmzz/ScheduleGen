#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "prereq.validator.h"
#include "structs.h"

// Verifica si un codigo de curso esta aprobado en el historial
static bool is_course_approved(const char *code, const Record *record) {
    for (int i = 0; i < record->num_completed_courses; i++) {
        if (strcmp(code, record->approved_courses[i]) == 0) {
            return true;
        }
    }
    return false;
}

// Valida los prerrequisitos de un curso
static bool check_prerequisites(const Curso *course, const Record *record) {
    for (int i = 0; i < course->num_prerequisites; i++) {
        if (!is_course_approved(course->requisites[i], record)) {
            return false;
        }
    }
    return true;
}

// Valida los correquisitos de un curso
static bool check_corequisites(const Curso *course, const Record *record) {
    for (int i = 0; i < course->num_corequisites; i++) {
        // Un correquisito se cumple si ya fue aprobado o si se encuentra en el
        // catalogo como curso que el estudiante ya va a matricular en este ciclo.
        // En esta version, como no se tiene una lista de cursos matriculados, el
        // criterio valido es que el correquisito haya sido aprobado previamente.
        if (!is_course_approved(course->corequisites[i], record)) {
            return false;
        }
    }
    return true;
}

// Evalua y valida todos los cursos presentes en el catalogo
void validate_catalog_requirements(Catalog *catalog, const Record *record) {
    printf("VALIDACION DE REQUISITOS Y CORREQUISITOS\n");

    for (int i = 0; i < catalog->num_courses; i++) {
        Curso *course = &catalog->courses[i];

        // Si el curso ya fue aprobado, no debe evaluarse como pendiente.
        if (is_course_approved(course->code, record)) {
            printf("[OK] Course %s already approved; no validation required.\n", course->code);
            continue;
        }

        bool prereqs_ok = check_prerequisites(course, record);
        bool coreqs_ok = check_corequisites(course, record);

        if (prereqs_ok && coreqs_ok) {
            printf("[OK] Course %s meets all requirements.\n", course->code);
        } else {
            printf("[ERROR] Course %s missing prerequisites or corequisites.\n", course->code);
        }
    }
    printf("\n");
}