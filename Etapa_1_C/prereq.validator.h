#ifndef PREREQ_VALIDATOR_H
#define PREREQ_VALIDATOR_H

#include "structs.h"

bool is_course_selected(const char *course_code, const char selected_courses[][MAX_CODE], int num_selected_courses);

bool validate_selected_enrollment(const Catalog *catalog, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses);

// Validación del catálogo tomando en cuenta la matrícula actual
void validate_catalog_requirements(Catalog *catalog, const Record *record, const char selected_courses[][MAX_CODE], int num_selected_courses);

#endif // PREREQ_VALIDATOR_H