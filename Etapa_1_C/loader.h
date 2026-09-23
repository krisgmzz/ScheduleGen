#ifndef LOADER_H
#define LOADER_H

#include "structs.h"
#include "constants.h"
#include <stdio.h>


// Carga los horarios y llena los grupos/schedules de cada curso ya cargado
void load_schedules(const char *filename, Catalog *catalog);

void load_record(const char *filename, Record *record);

bool load_selected_enrollment(const char *filename, char selected_courses[][MAX_CODE], int *num_selected_courses);

void load_study_plan(const char *filename, Catalog *catalog);


#endif