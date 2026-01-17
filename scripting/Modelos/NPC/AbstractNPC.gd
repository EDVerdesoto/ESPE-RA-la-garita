class_name AbstractNPC
extends RefCounted # Usamos RefCounted para que se borre solo de memoria

var nombre: String
var personalidad: String
var incidencia: int = GlobalEnums.Incidencia.NINGUNA
var estado: int = GlobalEnums.NPCState.NUEVO

# Método abstracto
func post_accion():
	pass
