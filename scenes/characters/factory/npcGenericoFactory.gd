class_name NPCGenericoFactory
extends INPCFactory

func crear_npc(
	nombre : String, 
	apellido : String, 
	personalidad : String, 
	ruta_sprite_npc : String, 
	carrera : String,
	cedula_config : CedulaNPCConfig,
	carnet_universitario_config : CarnetUniversitarioNPCConfig,
	pase_visitante_config : PaseVisitanteNPCConfig
) -> AbstractNPC:
	
	var nuevo_npc = NPCGenerico.new()
	
	nuevo_npc.nombre = nombre
	nuevo_npc.apellido = apellido
	nuevo_npc.personalidad = personalidad
	nuevo_npc.ruta_sprite_npc = ruta_sprite_npc
	nuevo_npc.carrera = carrera
	
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(
		nuevo_npc, 
		cedula_config,
		carnet_universitario_config,
		pase_visitante_config
	)
	
	return nuevo_npc
