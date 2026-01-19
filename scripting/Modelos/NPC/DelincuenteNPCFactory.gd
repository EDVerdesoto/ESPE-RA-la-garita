class_name DelincuenteNPCFactory
extends INPCFactory

func crear_npc(
	nombre:String, apellido:String, personalidad:String, ruta_sprite_npc:String, carrera:String,
	carnet: Carnet, cedula: Cedula
) -> AbstractNPC:
	
	var nuevo_delincuente = NPCDelincuente.new()
	
	nuevo_delincuente.nombre = nombre
	nuevo_delincuente.apellido = apellido
	nuevo_delincuente.personalidad = personalidad
	nuevo_delincuente.ruta_sprite_npc = ruta_sprite_npc
	
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(nuevo_delincuente)
	
	return nuevo_delincuente
