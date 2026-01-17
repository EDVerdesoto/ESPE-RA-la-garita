extends RefCounted
class_name GeneradorNombres

const NOMBRES_GENERICOS = [
	"Carlos", "Andrés", "Miguel", "José",
	"Luis", "Daniel", "Fernando", "Javier"
]

const NOMBRES_DELINCUENTES = [
	"Kevin", "Brayan", "Jhon", "Dilan",
	"Steven", "Maikel", "Cristian"
]

const APELLIDOS = [
	"Pérez", "Gómez", "Rodríguez",
	"Torres", "Mendoza", "Ramírez"
]

static func generar_nombre(npc: AbstractNPC) -> void:
	var nombre_base: String

	if npc is NPCDelincuente:
		nombre_base = NOMBRES_DELINCUENTES.pick_random()
	elif npc is NPCGenerico:
		nombre_base = NOMBRES_GENERICOS.pick_random()
	else:
		push_warning("Tipo de NPC desconocido en NameGenerator")
		nombre_base = NOMBRES_GENERICOS.pick_random()

	npc.nombre = "%s %s" % [nombre_base, APELLIDOS.pick_random()]
