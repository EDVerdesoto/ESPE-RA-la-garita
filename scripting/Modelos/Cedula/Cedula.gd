# Cedula.gd
class_name Cedula
extends RefCounted

var numero_cedula: String
var nombre: String
var apellido: String
var fecha_emision: String
var fecha_expiracion: String
var ruta_sprite: String

func _init(
	p_numero_cedula : String = "",
	p_nombre : String = "",
	p_apellido : String = "",
	p_fecha_emision : String = "",
	p_fecha_expiracion : String = "",
	p_ruta_sprite : String = ""
):
	numero_cedula = p_numero_cedula
	nombre = p_nombre
	apellido = p_apellido
	fecha_emision = p_fecha_emision
	fecha_expiracion = p_fecha_expiracion
	ruta_sprite = p_ruta_sprite
