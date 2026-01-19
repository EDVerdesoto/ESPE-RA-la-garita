# Carnet.gd
class_name Carnet
extends RefCounted

var nombre: String
var carrera: String
var ruta_sprite: String


func _init(
	p_nombre := "",
	p_carrera := "",
	p_ruta_sprite := ""
):
	nombre = p_nombre
	carrera = p_carrera
	ruta_sprite = p_ruta_sprite
