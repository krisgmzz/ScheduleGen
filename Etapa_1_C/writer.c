#include "writer.h"
#include <stdlib.h>

void write_indent(FILE *f, int nivel) {
    for (int i = 0; i < nivel; i++) fprintf(f, "    ");
}

void write_schedule(FILE *file, Schedule *schedule, int indent){
    write_indent(file, indent);
    fprintf(file, "{\"dia\": %d, \"inicio\": %d, \"fin\": %d}", schedule->day, schedule->begin_time, schedule->end_time);
}

void write_group(FILE *file, Group *group, int indent){
    write_indent(file, indent);
    fprintf(file, "{\n");

    write_indent(file, indent+1);
    fprintf(file, "\"numero\": %d,\n", group->group_number);

    write_indent(file, indent+1);
    fprintf(file, "\"choca_horario\": %s,\n", group->schedule_clash ? "true" : "false");

    write_indent(file, indent+1);
    fprintf(file, "\"horarios\": [\n");

    for (int i = 0; i < group->num_schedules; i++){
        write_schedule(file, &group->schedules[i], indent+2 );
        if (i != group->num_schedules -1) fprintf(file, ",\n");
    }

    fprintf(file, "\n");
    write_indent(file, indent+1);

    fprintf(file, "]\n");
    write_indent(file, indent);

    fprintf(file, "}");
}

void write_code_array(FILE *file, char codes[][MAX_CODE], int count, int indent) {
    fprintf(file, "[");

    if (count == 0) {
        fprintf(file, "]");
        return;
    }

    fprintf(file, "\n");

    for (int i = 0; i < count; i++) {
        write_indent(file, indent + 1);
        fprintf(file, "\"%s\"", codes[i]);
        if (i != count - 1) fprintf(file, ",");
        fprintf(file, "\n");
    }

    write_indent(file, indent);
    fprintf(file, "]");
}

void write_curso(FILE *file, Curso *curso, int indent) {
    write_indent(file, indent);
    fprintf(file, "{\n");

    write_indent(file, indent + 1);
    fprintf(file, "\"codigo\": \"%s\",\n", curso->code);

    write_indent(file, indent + 1);
    fprintf(file, "\"nombre\": \"%s\",\n", curso->name);

    write_indent(file, indent + 1);
    fprintf(file, "\"creditos\": %d,\n", curso->credits);

    write_indent(file, indent + 1);
    fprintf(file, "\"prerrequisitos\": ");
    write_code_array(file, curso->requisites, curso->num_prerequisites, indent + 1);
    fprintf(file, ",\n");

    write_indent(file, indent + 1);
    fprintf(file, "\"correquisitos\": ");
    write_code_array(file, curso->corequisites, curso->num_corequisites, indent + 1);
    fprintf(file, ",\n");

    write_indent(file, indent + 1);
    fprintf(file, "\"choca_horario\": %s,\n", curso->schedule_clash ? "true" : "false");

    write_indent(file, indent + 1);
    fprintf(file, "\"puede_matricular\": %s,\n", curso->can_enroll ? "true" : "false");

    write_indent(file, indent + 1);
    fprintf(file, "\"grupos\": [\n");
    for (int i = 0; i < curso->num_groups; i++) {
        write_group(file, &curso->groups[i], indent + 2);
        if (i != curso->num_groups - 1) fprintf(file, ",");
        fprintf(file, "\n");
    }
    write_indent(file, indent + 1);
    fprintf(file, "]\n");

    write_indent(file, indent);
    fprintf(file, "}");
}

void export_catalog(const char *filename, Catalog *catalog) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        fprintf(stderr, "No se pudo crear el archivo %s\n", filename);
        exit(EXIT_FAILURE);
    }

    fprintf(file, "{\n");
    write_indent(file, 1);
    fprintf(file, "\"cursos\": [\n");

    for (int i = 0; i < catalog->num_courses; i++) {
        write_curso(file, &catalog->courses[i], 2);
        if (i != catalog->num_courses - 1) fprintf(file, ",");
        fprintf(file, "\n");
    }

    write_indent(file, 1);
    fprintf(file, "]\n");
    fprintf(file, "}\n");

    fclose(file);
}