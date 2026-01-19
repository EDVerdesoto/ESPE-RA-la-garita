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
	p_numero_cedula := "",
	p_nombre := "",
	p_apellido := "",
	p_fecha_emision := "",
	p_fecha_expiracion := "",
	p_ruta_sprite := ""
):
	numero_cedula = p_numero_cedula
	nombre = p_nombre
	apellido = p_apellido
	fecha_emision = p_fecha_emision
	fecha_expiracion = p_fecha_expiracion
	ruta_sprite = p_ruta_sprite
