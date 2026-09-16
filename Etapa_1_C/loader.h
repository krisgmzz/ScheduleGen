#ifndef LOADER_H
#define LOADER_H

#include "structs.h"
#include "constants.h"
#include <stdio.h>

// Carga el plan de estudios y llena el catálogo
void load_catalog(const char *filename, Catalog *catalog);

// Carga los horarios y llena los grupos/schedules de cada curso ya cargado
void load_schedules(const char *filename, Catalog *catalog);

void load_record(const char *filename, Record *record);


#endif