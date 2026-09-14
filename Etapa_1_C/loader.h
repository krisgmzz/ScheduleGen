#ifndef LOADER_H
#define LOADER_H

#include "structs.h"
#include "constants.h"

// Carga el plan de estudios y llena el catálogo
void load_catalog(const char *filename, Catalog *catalog);

// Carga los horarios y llena los grupos/schedules de cada curso ya cargado
void load_schedules(const char *filename, Catalog *catalog);

FILE* open_file_csv(const char *filename);

void split_csv_line(char *line, char fields[][MAX_LEN], int max_fields, int *num_fields);

void load_study_plan(const char *filename, Catalog *catalog);

void parse_codes(const char *raw, char destination[][MAX_CODE], int max_codes, int *num_codes);

#endif