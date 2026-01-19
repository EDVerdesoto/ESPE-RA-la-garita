# INPCFactory (Interfaz conceptual)
class_name INPCFactory
extends Node

func crear_npc(
	nombre:String, apellido:String, personalidad:String, ruta_sprite_npc:String, carrera:String,
	carnet: Carnet, cedula: Cedula
) -> AbstractNPC:
	return null
