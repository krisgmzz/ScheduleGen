#ifndef STRUCTS_H
#define STRUCTS_H

#include <stdbool.h>
#include "constants.h"

// Representación de una franja horaria individual
typedef struct {
    int day; // Representación numérica 0=lunes, 1=martes, ..., 6=domingo
    int begin_time; // Minutos desde medianoche
    int end_time; // Minutos desde medianoche
    char aula[MAX_ROOM];
} Schedule;

// Representación de un grupo
typedef struct {
    int group_number;
    int num_schedules;
    bool schedule_clash; // 1=Sí tiene choque, 0=No tiene choque
    Schedule schedules[MAX_SCHEDULES_PER_GROUP];
} Group;

// Representación del curso 
typedef struct {
    char code[MAX_CODE];
    char name[MAX_NAME];
    int credits;
    
    // Lista de grupos ofertados
    int num_groups;
    Group groups[MAX_GROUPS_PER_COURSE];
    
    // Prerrequisitos y correquisitos (arreglos con los códigos de las materias)
    int num_prerequisites;
    char requisites[MAX_PREREQUISITES][MAX_CODE];
    
    int num_corequisites;
    char corequisites[MAX_COREQUISITES][MAX_CODE];
    
    //Variables calculadas por los algoritmos
    bool schedule_clash; // 1=Sí tiene choque, 0=No tiene choque
    bool can_enroll;  //1=Sí puede, 0=No cumple requisitos
} Curso;

// Catálogo completo
typedef struct {
    int num_courses;
    Curso courses[MAX_COURSES_IN_CATALOG];
} Catalog;

// Historial de cursos aprobados por el estudiante
typedef struct {
    int num_completed_courses ;
    char approved_courses[MAX_COMPLETED_COURSES][MAX_CODE];
} Record;

#endif