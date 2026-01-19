class_name GeneradorIncidencias
extends Node

const PROBABILIDAD_INCIDENCIA_GENERIC = 0.3      # 30% para estudiantes/profesores
const PROBABILIDAD_INCIDENCIA_DELINCUENTE = 0.9  # 90% para delincuentes 

static func generar_incidencias(
	npc: AbstractNPC, 
	ruta_sprite_carnet:String, ruta_sprite_cedula:String,
	fecha_expiracion_cedula:Variant = null, carrera:Variant = null
) -> void:
	var probabilidad_base: float = 0.0
	
	# Identificamos el tipo de NPC para decidir la probabilidad
	if npc is NPCDelincuente:
		probabilidad_base = PROBABILIDAD_INCIDENCIA_DELINCUENTE
	elif npc is NPCGenerico:
		probabilidad_base = PROBABILIDAD_INCIDENCIA_GENERIC

	# Aplicamos el azar
	if randf() < probabilidad_base:
		_seleccionar_error_por_tipo(npc)
	else:
		npc.incidencia = GlobalEnums.Incidencia.NINGUNA

# Función privada de apoyo para mantener el código limpio
static func _seleccionar_error_por_tipo(npc: AbstractNPC) -> void:
	if npc is NPCDelincuente:
		# Los delincuentes suelen tener problemas graves o estar en la lista de baneo
		# TODO: lógica de baneo
		npc.incidencia = GlobalEnums.Incidencia.SOSPECHOSO
		
	else:
		# Los personajes genéricos tienen errores burocráticos comunes
		var errores_burocraticos = [
			GlobalEnums.Incidencia.CARNET_INVALIDO,
			GlobalEnums.Incidencia.FECHA_VENCIDA,
			GlobalEnums.Incidencia.FOTO_FALSA
		]
		npc.incidencia = errores_burocraticos.pick_random()
