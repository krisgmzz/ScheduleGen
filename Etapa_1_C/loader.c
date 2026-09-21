#include "loader.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void parse_codes(const char *str, char destination[][MAX_CODE], int max_codes, int *num_codes) {
    *num_codes = 0;
    if (strcmp(str, "No hay") == 0) {
        return;
    }
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
    //Variables campos de field
    int code_index = -1; // índice del campo de código en el CSV
    int name_index = -1; // índice del campo de nombre en el CSV
    int prerequisites_index = -1; // índice del campo de prerrequisitos en el CSV
    int corequisites_index = -1; // índice del campo de correquisitos en el CSV
    int credits_index = -1; // índice del campo de créditos en el CSV

    // Obtener campos de la primera línea para verificar el formato
    if(fgets(line, sizeof(line), study_plan) == NULL) {
        fprintf(stderr, "Error al leer el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    split_csv_line(line, fields, MAX_COLS, &num_cols);
    for (int i = 0; i < num_cols; i++){
        if (strcmp(fields[i], "codigo") == 0) {
            code_index = i;
        } else if (strcmp(fields[i], "nombre") == 0) {
            name_index = i;
        } else if (strcmp(fields[i], "requisitos") == 0) {
            prerequisites_index = i;
        } else if (strcmp(fields[i], "correquisitos") == 0) {
            corequisites_index = i;
        } else if (strcmp(fields[i], "creditos") == 0) {
            credits_index = i;
        }
    }
    if (code_index == -1 || name_index == -1 || prerequisites_index == -1 || corequisites_index == -1 || credits_index == -1) {
        fprintf(stderr, "El archivo %s no tiene el formato esperado\n", filename);
        exit(EXIT_FAILURE);
    }
    // Recorrer el archivo línea por línea y llenar el catálogo
    while(fgets(line, sizeof(line), study_plan) != NULL) {
        if (course_index >= MAX_COURSES_IN_CATALOG) {
            fprintf(stderr, "Número de cursos en el plan de estudios excede el máximo permitido (%d)\n", MAX_COURSES_IN_CATALOG);
            exit(EXIT_FAILURE);
        }
        split_csv_line(line, fields, MAX_COLS, &num_cols);

        // Copiar los campos relevantes a la estructura Curso dentro del catálogo
        strncpy(catalog->courses[course_index].code, fields[code_index], MAX_CODE - 1);  // Codigo de curso
        strncpy(catalog->courses[course_index].name, fields[name_index], MAX_NAME - 1); // Nombre de curso
        catalog->courses[course_index].code[MAX_CODE - 1] = '\0';
        catalog->courses[course_index].name[MAX_NAME - 1] = '\0';
        parse_codes(fields[prerequisites_index], catalog->courses[course_index].requisites, MAX_PREREQUISITES, &catalog->courses[course_index].num_prerequisites);
        parse_codes(fields[corequisites_index], catalog->courses[course_index].corequisites, MAX_COREQUISITES, &catalog->courses[course_index].num_corequisites); 
        catalog->courses[course_index].credits = atoi(fields[credits_index]); // Número de créditos
        catalog->courses[course_index].num_groups = 0;
        course_index++;
    }


    catalog->num_courses = course_index;
    fclose(study_plan);
    return;
}

int find_course(Catalog *catalog, const char *code) { // Devuelve el índice en catalog->courses[] si lo encuentra, o -1 si no existe.
    for (int i = 0; i < catalog->num_courses; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return i;
        }
    }
    return -1;
}

int day_to_number(const char *day) {
    if (strncmp(day, "LUN", 3) == 0) return 0;
    if (strncmp(day, "MAR", 3) == 0) return 1;
    if (strncmp(day, "MIE", 3) == 0) return 2;
    if (strncmp(day, "JUE", 3) == 0) return 3;
    if (strncmp(day, "VIE", 3) == 0) return 4;
    if (strncmp(day, "SAB", 3) == 0) return 5;
    if (strncmp(day, "DOM", 3) == 0) return 6;
    return -1;
}

void parse_schedule_field(const char *raw, Group *group) {
    group->num_schedules = 0;

    char copy[MAX_LEN];
    strncpy(copy, raw, MAX_LEN - 1);
    copy[MAX_LEN - 1] = '\0';

    char *token = strtok(copy, " ");
    while (token != NULL) {
        if (group->num_schedules >= MAX_SCHEDULES_PER_GROUP) {
            fprintf(stderr, "Advertencia: se excedió el máximo de horarios por grupo (%d) en \"%s\"\n",
                    MAX_SCHEDULES_PER_GROUP, raw);
            exit(EXIT_FAILURE);
        }

        char *corchete = strchr(token, '[');
        if (corchete == NULL) {
            fprintf(stderr, "Formato de horario inválido (falta '['): \"%s\"\n", token);
            exit(EXIT_FAILURE);
        }

        int day = day_to_number(token);
        if (day == -1) {
            fprintf(stderr, "Día no reconocido en horario: \"%s\"\n", token);
            exit(EXIT_FAILURE);
        }

        int h1, m1, h2, m2;
        if (sscanf(corchete, "[%d:%d-%d:%d]", &h1, &m1, &h2, &m2) != 4) {
            fprintf(stderr, "Formato de horas inválido: \"%s\"\n", token);
            exit(EXIT_FAILURE);
        }

        Schedule *new_schedule = &group->schedules[group->num_schedules];
        new_schedule->day = day;
        new_schedule->begin_time = h1 * 60 + m1;
        new_schedule->end_time = h2 * 60 + m2;
        snprintf(new_schedule->aula, sizeof(new_schedule->aula), "N/A");

        group->num_schedules++;
        token = strtok(NULL, " ");
    }
}

void load_schedules(const char *filename, Catalog *catalog) {
    FILE *schedules = open_file_csv(filename);
    if (schedules == NULL) {
        fprintf(stderr, "No se pudo abrir el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }

    char line[1024];
    char fields[MAX_COLS][MAX_LEN];
    int num_cols = 0;

    //Variables campos de field
    int sede_index = -1;
    int codigo_index = -1;
    int grupo_index = -1;
    int horario_index = -1;

    if (fgets(line, sizeof(line), schedules) == NULL) {
        fprintf(stderr, "Error al leer el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    split_csv_line(line, fields, MAX_COLS, &num_cols);
    for (int i = 0; i < num_cols; i++){
        if (strcmp(fields[i], "sede") == 0) {
            sede_index = i;
        } else if (strcmp(fields[i], "codigo") == 0) {
            codigo_index = i;
        } else if (strcmp(fields[i], "grupo") == 0) {
            grupo_index = i;
        } else if (strcmp(fields[i], "horario") == 0) {
            horario_index = i;
        }
    }
    if (sede_index == -1 || codigo_index == -1 || grupo_index == -1 || horario_index == -1) {
        fprintf(stderr, "El archivo %s no tiene el formato esperado\n", filename);
        exit(EXIT_FAILURE);
    }
    while (fgets(line, sizeof(line), schedules) != NULL) {
        split_csv_line(line, fields, MAX_COLS, &num_cols);

        // Filtro por sede
        if (strcmp(fields[sede_index], "CAMPUS TECNOLOGICO CENTRAL CARTAGO") != 0) {
            continue;
        }

        // Filtro por codigo conocido ya en el catalogo
        int idx = find_course(catalog, fields[codigo_index]);
        if (idx == -1) {
            continue; // curso que no pertenece al plan de estudios, se ignora
        }

        // Límite de grupos por curso antes de escribir
        if (catalog->courses[idx].num_groups >= MAX_GROUPS_PER_COURSE) {
            fprintf(stderr, "El curso %s excede el máximo de grupos permitido (%d)\n", catalog->courses[idx].code, MAX_GROUPS_PER_COURSE);
            exit(EXIT_FAILURE);
        }

        Group *nuevo_grupo = &catalog->courses[idx].groups[catalog->courses[idx].num_groups];
        nuevo_grupo->group_number = atoi(fields[grupo_index]);  // índice 8 = grupo
        nuevo_grupo->schedule_clash = false;

        parse_schedule_field(fields[horario_index], nuevo_grupo);

        catalog->courses[idx].num_groups++;
    }

    fclose(schedules);
}

bool existent_code(Record* record, const char* code){
    for (int i =0; i < record->num_completed_courses; i++){
        if (strcmp(record->approved_courses[i], code) == 0){
            return true;
        }
    }
    return false;
}

void load_record(const char *filename, Record *record) {
    FILE *file = open_file_csv(filename);
    if (file == NULL) {
        fprintf(stderr, "No se pudo abrir el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }

    char line[1024];
    char fields[1][MAX_LEN];
    int num_cols = 1;
    record->num_completed_courses = 0;

    
    if (fgets(line, sizeof(line), file) == NULL) {
        fprintf(stderr, "Error al leer el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }
    split_csv_line(line, fields, 1, &num_cols);
    if (num_cols != 1 || strcmp(fields[0], "codigos_aprobados") != 0) {
        fprintf(stderr, "El archivo %s no tiene el formato esperado\n", filename);
        exit(EXIT_FAILURE);
    }

    while (fgets(line, sizeof(line), file) != NULL) {
        split_csv_line(line, fields, 1, &num_cols);
        if (num_cols != 1) {
            fprintf(stderr, "Formato de línea incorrecto en %s: se esperaba un solo campo\n", filename);
            exit(EXIT_FAILURE);
        }
        if (record->num_completed_courses >= MAX_COMPLETED_COURSES) {
            fprintf(stderr, "Número de cursos completados excede el máximo permitido (%d)\n", MAX_COMPLETED_COURSES);
            exit(EXIT_FAILURE);
        }
        if (existent_code(record, fields[0])){
            continue;
        }
        strncpy(record->approved_courses[record->num_completed_courses], fields[0], MAX_CODE - 1);
        record->approved_courses[record->num_completed_courses][MAX_CODE - 1] = '\0';
        record->num_completed_courses++;
    }

    fclose(file);
}
