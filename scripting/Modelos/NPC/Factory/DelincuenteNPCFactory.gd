class_name DelincuenteNPCFactory
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
	
	var nuevo_delincuente = NPCDelincuente.new()
	
	nuevo_delincuente.nombre = nombre
	nuevo_delincuente.apellido = apellido
	nuevo_delincuente.personalidad = personalidad
	nuevo_delincuente.ruta_sprite_npc = ruta_sprite_npc
	
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(
		nuevo_delincuente, 
		cedula_config, 
		carnet_universitario_config,
		pase_visitante_config
	)
	
	return nuevo_delincuente
