class_name AbstractNPC
extends RefCounted

var id: String
var nombre: String
var apellido: String
var personalidad: String
var rol: String
var carrera: String
var sprite_path: String
var cara_path: String
var ruta_sprite_npc: String
var incidencia: int = GlobalEnums.Incidencia.NINGUNA
var estado: int = GlobalEnums.NPCState.NUEVO
var documentos: Array[AbstractDocumentoNPC]
var dialogos: Dictionary = {}
var tipo_amenaza: String = ""

# Método abstracto
func post_accion():
	pass
