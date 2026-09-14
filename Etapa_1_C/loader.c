#include "loader.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>



FILE* open_file_csv(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        fprintf(stderr, "No se pudo abrir el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    unsigned char buffer[3];
    int read = fread(buffer, 1, 3, file);
    if (!(read == 3 && buffer[0]==0xEF && buffer[1]==0xBB && buffer[2]==0xBF)) {
        rewind(file);
    }
    return file;
}

void split_csv_line(char *line, char fields[][MAX_LEN], int max_fields, int *num_fields) {
    char* end_quote = NULL;
    *num_fields = 0;
    while (line != NULL && *num_fields < max_fields) {
        end_quote = strchr(line + 1, '"');
        if (end_quote == NULL) {
            fprintf(stderr, "Formato de línea CSV incorrecto: falta una comilla de cierre\n");
            exit(EXIT_FAILURE);
        }
        if (end_quote - line - 1 >= MAX_LEN) {
            fprintf(stderr, "Campo en la línea excede el tamaño máximo permitido (%d)\n", MAX_LEN);
            exit(EXIT_FAILURE);
        }
        strncpy(fields[*num_fields], line + 1, end_quote - line - 1);
        fields[*num_fields][end_quote - line - 1] = '\0';
        (*num_fields)++;
        line = strchr(end_quote + 1, '"');
    }
        if (line != NULL) {
        fprintf(stderr, "Número de campos en la línea excede el máximo permitido (%d)\n", max_fields);
        exit(EXIT_FAILURE);
    }
    return;
}

void load_study_plan(const char *filename, Catalog *catalog) {
    FILE *study_plan = open_file_csv(filename);
    if (study_plan == NULL) {
        fprintf(stderr, "No se pudo abrir el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    char line[1024];
    char fields[MAX_COLS][MAX_LEN];
    int num_cols = 0;
    int course_index = 0;
    if(fgets(line, sizeof(line), study_plan) == NULL) { // Leer y descartar la primera línea
        fprintf(stderr, "Error al leer el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    while(fgets(line, sizeof(line), study_plan) != NULL) {
        if (course_index >= MAX_COURSES_IN_CATALOG) {
            fprintf(stderr, "Número de cursos en el plan de estudios excede el máximo permitido (%d)\n", MAX_COURSES_IN_CATALOG);
            exit(EXIT_FAILURE);
        }
        split_csv_line(line, fields, MAX_COLS, &num_cols);
        strncpy(catalog->courses[course_index].code, fields[2], MAX_CODE - 1);  // Codigo de curso
        strncpy(catalog->courses[course_index].name, fields[4], MAX_NAME - 1); // Nombre de curso
        catalog->courses[course_index].code[MAX_CODE - 1] = '\0';
        catalog->courses[course_index].name[MAX_NAME - 1] = '\0';
        parse_codes(fields[6], catalog->courses[course_index].requisites, MAX_PREREQUISITES, &catalog->courses[course_index].num_prerequisites);
        parse_codes(fields[5], catalog->courses[course_index].corequisites, MAX_COREQUISITES, &catalog->courses[course_index].num_corequisites); 
        catalog->courses[course_index].credits = atoi(fields[11]); // Número de prerrequisitos
        catalog->courses[course_index].num_prerequisites = 0;
        catalog->courses[course_index].num_corequisites = 0;
        catalog->courses[course_index].num_groups = 0;
        course_index++;
    }
    catalog->num_courses = course_index;
    fclose(study_plan);
    return;
}

void parse_codes(const char *str, char destination[][MAX_CODE], int max_codes, int *num_codes) {
    *num_codes = 0;
    if (strcmp(str, "No hay") == 0) {
        return;
    }
    const char *delimit = " ,";
    char copy[MAX_LEN];
    strncpy(copy, str, MAX_LEN - 1);
    copy[MAX_LEN - 1] = '\0';

    char *token = strtok(copy, ",");
    while (token != NULL && *num_codes < max_codes) {
        // Saltar posibles espacios al inicio del token
        while (*token == ' ') {
            token++;
        }

        strncpy(destination[*num_codes], token, MAX_CODE - 1);
        destination[*num_codes][MAX_CODE - 1] = '\0';
        (*num_codes)++;

        token = strtok(NULL, ",");
    }
    if (token != NULL) {
        fprintf(stderr, "Advertencia: se excedió el máximo de cursos permitidos (%d) en \"%s\"\n", max_codes, str);
        exit(EXIT_FAILURE);
    }
}
