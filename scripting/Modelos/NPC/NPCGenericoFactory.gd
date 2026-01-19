# RandomNPCFactory (La que usaremos para el martes)
class_name NPCGenericoFactory
extends INPCFactory

func crear_npc(
	nombre:String, personalidad:String, ruta_sprite_npc:String,
	ruta_sprite_carnet:String, ruta_sprite_cedula:String,
	fecha_expiracion_cedula:Variant = null, carrera:Variant = null
) -> AbstractNPC:
	
	var nuevo_npc = NPCGenerico.new()
	
	nuevo_npc.nombre = nombre
	nuevo_npc.personalidad = personalidad
	nuevo_npc.ruta_sprite_npc = ruta_sprite_npc
	nuevo_npc.carrera = carrera
	
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(nuevo_npc)
	
	return nuevo_npc
