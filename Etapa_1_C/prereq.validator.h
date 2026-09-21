#ifndef PREREQ_VALIDATOR_H
#define PREREQ_VALIDATOR_H

#include "structs.h"

/* Unica funcion necesaria para procesar la validacion en el main */
void validate_catalog_requirements(Catalog *catalog, const Record *record);

#endif /* PREREQ_VALIDATOR_H */