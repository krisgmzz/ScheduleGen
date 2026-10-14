#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "prereq.validator.h"
#include "structs.h"

// Verifica si un codigo de curso esta aprobado en el historial del estudiante
static bool is_course_approved(const char *code, const Record *record) {
    for (int i = 0; i < record->num_completed_courses; i++) {
        if (strcmp(code, record->approved_courses[i]) == 0) {
            return true;
        }
    }
    return false;
}

bool is_course_selected(const char *course_code, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    for (int i = 0; i < num_selected_courses; i++) {
        if (strcmp(course_code, selected_courses[i]) == 0) {
            return true;
        }
    }
    return false;
}

// Verifica si un curso esta presente en la oferta del catalogo actual
static bool is_course_in_catalog(const char *code, const Catalog *catalog) {
    for (int i = 0; i < catalog->num_courses; i++) {
        if (strcmp(code, catalog->courses[i].code) == 0) {
            return true;
        }
    }
    return false;
}

// Prerrequisitos: solo se consideran cumplidos si ya fueron aprobados.
static bool check_prerequisites(const Curso *course, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    for (int i = 0; i < course->num_prerequisites; i++) {
        if (!is_course_approved(course->requisites[i], record)) {
            return false;
        }
    }
    return true;
}

// Correquisitos: se aceptan aprobados o ya seleccionados en la matrícula actual.
static bool check_corequisites(const Curso *course, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    for (int i = 0; i < course->num_corequisites; i++) {
        bool approved = is_course_approved(course->corequisites[i], record);
        bool selected = is_course_selected(course->corequisites[i], selected_courses, num_selected_courses);

        if (!approved && !selected) {
            return false;
        }
    }
    return true;
}

static bool is_course_eligible_for_enrollment(const Curso *course, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    if (is_course_approved(course->code, record)) {
        return false;
    }

    if (!check_prerequisites(course, record, selected_courses, num_selected_courses)) {
        return false;
    }

    if (!check_corequisites(course, record, selected_courses, num_selected_courses)) {
        return false;
    }

    return true;
}

bool validate_selected_enrollment(const Catalog *catalog, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    if (selected_courses == NULL || num_selected_courses <= 0) {
        printf("No hay cursos seleccionados para validar.\n");
        return false;
    }

    for (int i = 0; i < num_selected_courses; i++) {
        const char *course_code = selected_courses[i];
        int course_index = -1;

        for (int j = 0; j < catalog->num_courses; j++) {
            if (strcmp(catalog->courses[j].code, course_code) == 0) {
                course_index = j;
                break;
            }
        }

        if (course_index == -1) {
            printf("Curso %s no existe en el catálogo.\n", course_code);
            return false;
        }

        const Curso *course = &catalog->courses[course_index];
        if (!is_course_eligible_for_enrollment(course, record, selected_courses, num_selected_courses)) {
            return false;
        }
    }

    return true;
}

// Evalua y actualiza la elegibilidad de todos los cursos del catalogo con la matrícula actual
void validate_catalog_requirements(Catalog *catalog, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses) {
    printf("VALIDACION DE REQUISITOS Y CORREQUISITOS\n");

    for (int i = 0; i < catalog->num_courses; i++) {
        Curso *course = &catalog->courses[i];

        if (is_course_approved(course->code, record)) {
            course->can_enroll = false;
            printf("Curso %s ya fue aprobado previamente, no se requiere matricula.\n", course->code);
            continue;
        }

        course->can_enroll = is_course_eligible_for_enrollment(course, record, selected_courses, num_selected_courses);

        if (course->can_enroll) {
            printf("Curso %s cumple con requisitos o correquisitos.\n", course->code);
        } else {
            printf("Curso %s NO cumple con requisitos o correquisitos.\n", course->code);
        }
    }
    printf("\n");
}