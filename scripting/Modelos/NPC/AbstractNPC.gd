class_name AbstractNPC
extends RefCounted # Usamos RefCounted para que se borre solo de memoria

var nombre: String
var apellido: String
var personalidad: String
var carrera: String
var incidencia: int = GlobalEnums.Incidencia.NINGUNA
var estado: int = GlobalEnums.NPCState.NUEVO
var ruta_sprite_npc: String
var carnet: Carnet
var cedula: Cedula

# Método abstracto
func post_accion():
	pass
