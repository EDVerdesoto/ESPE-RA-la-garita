# RandomNPCFactory (La que usaremos para el martes)
class_name RandomNPCFactory
extends INPCFactory

func crear_npc() -> AbstractNPC:
	var nuevo_npc
	
	nuevo_npc = NPCGenerico.new()
	
	nuevo_npc.personalidad = ["Amable", "Nervioso", "Agresivo"].pick_random()
	
	# Generador de nombres
	GeneradorNombres.generar_nombre(nuevo_npc)
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(nuevo_npc)
	
	return nuevo_npc
