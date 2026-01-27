class_name AbstractNPC
extends RefCounted

var nombre: String
var apellido: String
var personalidad: String
var carrera: String
var incidencia: int = GlobalEnums.Incidencia.NINGUNA
var estado: int = GlobalEnums.NPCState.NUEVO
var documentos: Array[AbstractDocumentoNPC]

# Método abstracto
func post_accion():
	pass
