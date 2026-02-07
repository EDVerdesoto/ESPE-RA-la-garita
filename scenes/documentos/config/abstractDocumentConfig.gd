class_name AbstractDocumentoNPCConfig
extends RefCounted

var nombre: String
var apellido: String
var ruta_sprite: String

func _init(
	p_nombre: String,
	p_apellido: String,
	p_ruta_sprite: String
) -> void:
	nombre = p_nombre
	apellido = p_apellido
	ruta_sprite = p_ruta_sprite
