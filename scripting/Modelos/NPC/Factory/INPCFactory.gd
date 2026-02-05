# INPCFactory (Interfaz conceptual)
class_name INPCFactory
extends Node

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
	return null
