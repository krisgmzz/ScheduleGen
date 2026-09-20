#include "collision.h"

bool schedules_clash(const Schedule *first, const Schedule *second) {
    if (first->day != second->day) {
        return false;
    }

    // Intervalos semiabiertos [inicio, fin): si uno termina exactamente
    // cuando el otro inicia, ambos cursos se pueden matricular.
    return first->begin_time < second->end_time &&
           second->begin_time < first->end_time;
}

bool groups_clash(const Group *first, const Group *second) {
    for (int i = 0; i < first->num_schedules; i++) {
        for (int j = 0; j < second->num_schedules; j++) {
            if (schedules_clash(&first->schedules[i], &second->schedules[j])) {
                return true;
            }
        }
    }

    return false;
}

void detect_schedule_clashes(Catalog *catalog) {
    // Reiniciar las marcas permite llamar esta funcion mas de una vez.
    for (int i = 0; i < catalog->num_courses; i++) {
        Curso *course = &catalog->courses[i];
        course->schedule_clash = false;

        for (int j = 0; j < course->num_groups; j++) {
            course->groups[j].schedule_clash = false;
        }
    }

    // Solo se comparan cursos distintos. Dos grupos del mismo curso son
    // alternativas de matricula, no dos lecciones que deban llevarse juntas.
    for (int first_course = 0; first_course < catalog->num_courses; first_course++) {
        Curso *course_a = &catalog->courses[first_course];

        for (int second_course = first_course + 1;
             second_course < catalog->num_courses;
             second_course++) {
            Curso *course_b = &catalog->courses[second_course];

            for (int first_group = 0; first_group < course_a->num_groups; first_group++) {
                Group *group_a = &course_a->groups[first_group];

                for (int second_group = 0;
                     second_group < course_b->num_groups;
                     second_group++) {
                    Group *group_b = &course_b->groups[second_group];

                    if (groups_clash(group_a, group_b)) {
                        group_a->schedule_clash = true;
                        group_b->schedule_clash = true;
                        course_a->schedule_clash = true;
                        course_b->schedule_clash = true;
                    }
                }
            }
        }
    }
}

