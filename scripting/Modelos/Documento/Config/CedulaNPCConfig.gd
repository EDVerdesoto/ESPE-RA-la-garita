class_name CedulaNPCConfig
extends AbstractDocumentoNPCConfig

var numero_cedula: String
var fecha_emision: String
var fecha_expiracion: String

func _init(
	p_nombre: String,
	p_apellido: String,
	p_ruta_sprite: String,
	p_numero_cedula: String,
	p_fecha_emision: String,
	p_fecha_expiracion: String
) -> void:
	super(p_nombre, p_apellido, p_ruta_sprite)
	numero_cedula = p_numero_cedula
	fecha_emision = p_fecha_emision
	fecha_expiracion = p_fecha_expiracion
