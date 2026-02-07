class_name CarnetUniversitarioNPCConfig
extends AbstractDocumentoNPCConfig

var carrera: String
var rol: String
var codigo_carnet: String    ## Código único del carnet (ej: "ESPE-2024-00143")
var foto_path: String        ## Ruta a la foto que aparece en el carnet

func _init(
	p_nombre: String,
	p_apellido: String,
	p_ruta_sprite: String,
	p_carrera: String,
	p_rol: String,
	p_codigo_carnet: String = "",
	p_foto_path: String = ""
) -> void:
	super(p_nombre, p_apellido, p_ruta_sprite)
	carrera = p_carrera
	rol = p_rol
	codigo_carnet = p_codigo_carnet
	foto_path = p_foto_path
