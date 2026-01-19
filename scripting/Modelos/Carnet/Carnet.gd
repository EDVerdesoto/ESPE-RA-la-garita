# Carnet.gd
class_name Carnet
extends RefCounted

var nombre: String
var apellido: String
var carrera: String
var ruta_sprite: String


func _init(
	p_nombre : String = "",
	p_apellido : String = "",
	p_carrera : String = "",
	p_ruta_sprite : String = ""
):
	nombre = p_nombre
	apellido = p_apellido
	carrera = p_carrera
	ruta_sprite = p_ruta_sprite
