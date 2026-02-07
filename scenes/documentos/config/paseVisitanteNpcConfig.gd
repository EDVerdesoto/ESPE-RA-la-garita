class_name PaseVisitanteNPCConfig
extends AbstractDocumentoNPCConfig

var razon: String

func _init(
	p_nombre: String,
	p_apellido: String,
	p_ruta_sprite: String,
	p_razon: String
) -> void:
	super(p_nombre, p_apellido, p_ruta_sprite)
	razon = p_razon
