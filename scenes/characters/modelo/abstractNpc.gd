class_name AbstractNPC
extends RefCounted

var id: String
var nombre: String
var apellido: String
var personalidad: String
var rol: String
var carrera: String
var sprite_path: String
var cara_path: String          ## Cara REAL del NPC (la que se ve en la ventanilla)
var foto_carnet_path: String   ## Foto que aparece en el carnet (puede diferir si hay incidencia)
var ruta_sprite_npc: String
var codigo_carnet: String      ## Código único del carnet universitario
var numero_cedula: String      ## Número de cédula (para el sistema/monitor)
var incidencia: int = GlobalEnums.Incidencia.NINGUNA
var estado: int = GlobalEnums.NPCState.NUEVO
var documentos: Array[AbstractDocumentoNPC]
var dialogos: Dictionary = {}
var dialogos_ia: Dictionary = {}  ## Diálogos generados por Gemini
var tipo_amenaza: String = ""

## Datos de cédula almacenados internamente (se muestran en el monitor, NO como documento físico)
var datos_sistema: Dictionary = {}  # {nombre, apellido, numero_cedula, fecha_expiracion, carrera}

func post_accion():
	pass

## Retorna true si este NPC tiene alguna incidencia real
func tiene_incidencia() -> bool:
	return incidencia != GlobalEnums.Incidencia.NINGUNA

## Retorna los datos que el sistema mostraría en el monitor al escanear el carnet
func obtener_datos_sistema() -> Dictionary:
	return datos_sistema
