class_name CarnetUniversitarioNPCConfig
extends AbstractDocumentoNPCConfig

var carrera : String
var rol : String

func _init(
	p_nombre : String,
	p_apellido : String,
	p_ruta_sprite : String,
	p_carrera : String,
	p_rol : String
) -> void:
	super(p_nombre, p_apellido, p_ruta_sprite)
	carrera = p_carrera
	rol = p_rol
