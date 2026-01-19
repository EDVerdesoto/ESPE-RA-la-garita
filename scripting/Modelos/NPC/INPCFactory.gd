# INPCFactory (Interfaz conceptual)
class_name INPCFactory
extends Node

func crear_npc(
	nombre:String, personalidad:String, ruta_sprite_npc:String,
	ruta_sprite_carnet:String, ruta_sprite_cedula:String, 
	fecha_expiracion_cedula:Variant = null, carrera:Variant = null
) -> AbstractNPC:
	return null
