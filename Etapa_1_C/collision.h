#ifndef COLLISION_H
#define COLLISION_H

#include <stdbool.h>
#include "structs.h"

// Indica si dos franjas horarias se superponen el mismo dia.
bool schedules_clash(const Schedule *first, const Schedule *second);

// Indica si algun horario del primer grupo choca con alguno del segundo.
bool groups_clash(const Group *first, const Group *second);

// Recorre todos los grupos de cursos distintos y actualiza
// Group.schedule_clash y Curso.schedule_clash.
void detect_schedule_clashes(Catalog *catalog);

#endif
