import csv
import shutil
from pathlib import Path

# Excepciones por contenido: no se clasifica todo solo por el prefijo.
AREAS = {
    "ciencias_basicas": "CE1111 PI2609 IA3202",
    "computacion":
        "CE1101 CE1103 CE2103 CE1106 CE3101 CE1108 CE4303 CE5301 IA2204",
    "arquitectura_digital":
        "CE1104 CE1107 CE3201 CE4301 CE4302 CE1113",
    "electronica":
        "CE2201 CE1109 CE1110 CE1112 IA3208 IA3501",
    "gestion_diseno":
        "CE1105 CE1116 AE4208 PI5516",
    "agua_suelo_ambiente":
        "IA2105 IA2107 IA3105 IA3203 IA3210 IA3212 IA3213 IA5601 "
        "IA4307 IA4311 IA4312 IA4313 IA4314 IA4315",
    "mecanica_topografia":
        "IA1203 IA3302 IA2202 IA3303 IA3206 IA3401 "
        "IA4402 IA4407 IA4403 IA5402",
    "produccion_agricola": "IA1002 IA2106",
    "electivas": "CE5701",
}

AREA_POR_CODIGO = {
    codigo: area
    for area, codigos in AREAS.items()
    for codigo in codigos.split()
}


def area_de(codigo):
    # Primero revisar las asignaciones específicas.
    if codigo in AREA_POR_CODIGO:
        return AREA_POR_CODIGO[codigo]

    if codigo.startswith(("MA", "FI", "QU", "BI", "CM")):
        return "ciencias_basicas"

    if codigo.startswith("EL"):
        return "electronica"

    if codigo.startswith(("CI", "CS", "FH", "SE", "SO")):
        return "formacion_general"

    # Obliga a decidir el área si aparece un curso desconocido.
    raise ValueError(f"Falta clasificar el curso {codigo}")


# Formato: código|nombre|créditos|requisitos|correquisitos.
# Primeras 5 filas: semestre 7. Siguientes 5: semestre 8.
NUEVOS_CE = """CE1111|análisis numérico para la ingeniería|3|MA2105|No hay
CE1112|taller de señales mixtas|3|CE1109, CE1110|No hay
CE1116|diseño y calidad en productos tecnológicos|4|CE3101, CE4301, PI5516|No hay
CE4302|arquitectura de computadores II|4|CE4301|CE4303
CE4303|principios de sistemas operativos|4|CE1108|No hay
AE4208|desarrollo de emprendedores|4|CS2101|No hay
CE1113|sistemas empotrados|3|CE4303|No hay
CE5301|redes de computadores|4|CE1116, CE4303|No hay
CE5701|electiva i|3|CE4302, CI3203|No hay
CS3404|seminario de ética para la ingeniería|2|CS2101|No hay"""

# Primeras 7 filas: semestre 7. Siguientes 7: semestre 8.
NUEVOS_IA = """CS3404|seminario de ética para la ingeniería|2|CS1502|No hay
IA4307|diseño estructuras hidráulicas|3|IA3213|No hay
IA4311|riego superficial|3|IA3105, IA3303|No hay
IA4312|drenaje superficial|2|IA3203, IA3213|No hay
IA4402|motores de combustión interna|3|CM2103, IA3401|No hay
IA4407|tractores agrícolas|2|No hay|IA4402
PI5516|ingeniería económica|3|MA3106|No hay
CS4402|seminario de estudios costarricenses|2|CS3404|No hay
IA3501|electrificación rural|3|IA3208|No hay
IA4313|riego a presión|3|IA3212, IA4311|No hay
IA4314|drenaje sub-superficial|3|IA4312|No hay
IA4315|manejo de suelos, aguas y diseño de obras de conservación|3|IA3203, IA4312|No hay
IA4403|mecanización agrícola|2|IA4407|No hay
IA5402|laboratorio de tractores y mecanización|2|No hay|IA4403"""


def actualizar(ruta, carrera, nuevos):
    with ruta.open(encoding="utf-8-sig", newline="") as entrada:
        lector = csv.DictReader(entrada)
        columnas = list(lector.fieldnames or [])
        filas = list(lector)

    obligatorias = {
        "codigo", "nombre", "creditos",
        "requisitos", "correquisitos", "carrera"
    }

    if not obligatorias.issubset(columnas):
        raise ValueError(f"Encabezado incompleto en {ruta}")

    if "area" not in columnas:
        columnas.append("area")

    existentes = {fila["codigo"] for fila in filas}

    if len(existentes) != len(filas):
        raise ValueError(f"Hay códigos duplicados en {ruta}")

    # Si ya se ejecutó anteriormente, no vuelve a agregar los cursos.
    for linea in nuevos.splitlines():
        codigo, nombre, creditos, requisitos, correquisitos = linea.split("|")

        if codigo not in existentes:
            fila = dict.fromkeys(columnas, "")
            fila.update(
                codigo=codigo,
                nombre=nombre,
                creditos=creditos,
                requisitos=requisitos,
                correquisitos=correquisitos,
                carrera=carrera
            )
            filas.append(fila)
            existentes.add(codigo)

    # También asignar área a los cursos de los primeros seis semestres.
    for fila in filas:
        fila["carrera"] = carrera
        fila["area"] = area_de(fila["codigo"])

    respaldo = ruta.with_suffix(".csv.bak")
    if not respaldo.exists():
        shutil.copy2(ruta, respaldo)

    # Mantener todos los campos entre comillas, como espera C.
    temporal = ruta.with_suffix(".csv.tmp")
    with temporal.open("w", encoding="utf-8", newline="") as salida:
        escritor = csv.DictWriter(
            salida,
            fieldnames=columnas,
            quoting=csv.QUOTE_ALL
        )
        escritor.writeheader()
        escritor.writerows(filas)

    temporal.replace(ruta)
    print(f"{ruta.name}: {len(filas)} cursos, todos con área")


if __name__ == "__main__":
    base = (
        Path(__file__).resolve().parent
        / "Etapa_1_C"
        / "ArchivosPrueba"
    )

    actualizar(
        base / "PlanEstudios.csv",
        "Ingeniería en Computadores",
        NUEVOS_CE
    )

    actualizar(
        base / "PlanEstudiosIA.csv",
        "Ingeniería Agrícola",
        NUEVOS_IA
    )
