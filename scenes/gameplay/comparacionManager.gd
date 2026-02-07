## ComparacionManager: Sistema central de comparación estilo Papers Please
## Coordina las interacciones entre carnet, monitor y cara del NPC
## Detecta discrepancias y vincula cada tipo con la incidencia correspondiente
extends Node

class_name ComparacionManager

signal discrepancia_detectada(campo: int, valor_carnet: String, valor_sistema: String, incidencia_relacionada: int)
signal comparacion_correcta(campo: int)
signal comparacion_foto_resultado(coinciden: bool)
signal todas_comparaciones_hechas()

## Estado de la comparación actual
var seleccion_carnet: Dictionary = {}    # { campo: int, valor: String }
var seleccion_monitor: Dictionary = {}   # { campo: int, valor: String }
var seleccion_cara_npc: String = ""      # path de la cara real
var npc_actual: AbstractNPC = null

## Registro de comparaciones realizadas
var comparaciones_hechas: Dictionary = {}  # campo -> ResultadoComparacion
var discrepancias_encontradas: Array[Dictionary] = []

## Mapeo: campo de comparación → incidencia relacionada
## Esto permite que al detectar una discrepancia en un campo específico,
## se pueda inferir qué tipo de incidencia tiene el NPC
const MAPA_CAMPO_INCIDENCIA = {
	GlobalEnums.CampoComparacion.NOMBRE: [
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
	],
	GlobalEnums.CampoComparacion.APELLIDO: [
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
	],
	GlobalEnums.CampoComparacion.FOTO: [
		GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE,
	],
	GlobalEnums.CampoComparacion.CARRERA: [
		GlobalEnums.Incidencia.CARRERA_DIFERENTE,
	],
	GlobalEnums.CampoComparacion.FECHA_EXPIRACION: [
		GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA,
	],
	GlobalEnums.CampoComparacion.CODIGO_CARNET: [],
	GlobalEnums.CampoComparacion.NUMERO_CEDULA: [
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
	],
}

func iniciar_comparacion(npc: AbstractNPC) -> void:
	npc_actual = npc
	seleccion_carnet = {}
	seleccion_monitor = {}
	seleccion_cara_npc = ""
	comparaciones_hechas = {}
	discrepancias_encontradas = []

func resetear() -> void:
	npc_actual = null
	seleccion_carnet = {}
	seleccion_monitor = {}
	seleccion_cara_npc = ""
	comparaciones_hechas = {}
	discrepancias_encontradas = []

## Llamado cuando el jugador clickea un campo del carnet
func seleccionar_campo_carnet(campo: int, valor: String) -> void:
	seleccion_carnet = { "campo": campo, "valor": valor }
	print("[COMPARACION] Campo carnet seleccionado: ", _nombre_campo(campo), " = ", valor)
	_intentar_comparacion()

## Llamado cuando el jugador clickea un campo del monitor
func seleccionar_campo_monitor(campo: int, valor: String) -> void:
	seleccion_monitor = { "campo": campo, "valor": valor }
	print("[COMPARACION] Campo monitor seleccionado: ", _nombre_campo(campo), " = ", valor)
	_intentar_comparacion()

## Llamado cuando el jugador clickea la cara del NPC
func seleccionar_cara_npc(foto_real_path: String) -> void:
	seleccion_cara_npc = foto_real_path
	print("[COMPARACION] Cara NPC seleccionada: ", foto_real_path)
	_intentar_comparacion_foto()

## Intenta comparar si hay un campo seleccionado tanto en carnet como en monitor
func _intentar_comparacion() -> void:
	if seleccion_carnet.is_empty() or seleccion_monitor.is_empty():
		return
	
	var campo_carnet: int = seleccion_carnet.get("campo", GlobalEnums.CampoComparacion.NINGUNO)
	var campo_monitor: int = seleccion_monitor.get("campo", GlobalEnums.CampoComparacion.NINGUNO)
	var valor_carnet: String = seleccion_carnet.get("valor", "")
	var valor_monitor: String = seleccion_monitor.get("valor", "")
	
	# Solo comparar campos del mismo tipo
	if campo_carnet != campo_monitor:
		print("[COMPARACION] Campos diferentes seleccionados, no se puede comparar")
		# Resetear selecciones
		seleccion_carnet = {}
		seleccion_monitor = {}
		return
	
	var campo = campo_carnet
	var resultado: int
	
	if valor_carnet.strip_edges().to_lower() == valor_monitor.strip_edges().to_lower():
		resultado = GlobalEnums.ResultadoComparacion.COINCIDE
		comparaciones_hechas[campo] = resultado
		comparacion_correcta.emit(campo)
		print("[COMPARACION] ✓ COINCIDE: ", _nombre_campo(campo))
	else:
		resultado = GlobalEnums.ResultadoComparacion.NO_COINCIDE
		comparaciones_hechas[campo] = resultado
		var incidencia = _inferir_incidencia(campo)
		var info_discrepancia = {
			"campo": campo,
			"valor_carnet": valor_carnet,
			"valor_sistema": valor_monitor,
			"incidencia_inferida": incidencia
		}
		discrepancias_encontradas.append(info_discrepancia)
		discrepancia_detectada.emit(campo, valor_carnet, valor_monitor, incidencia)
		print("[COMPARACION] ✗ NO COINCIDE: ", _nombre_campo(campo), 
			" | Carnet: '", valor_carnet, "' vs Sistema: '", valor_monitor, "'",
			" | Incidencia inferida: ", incidencia)
	
	# Resetear selecciones después de comparar
	seleccion_carnet = {}
	seleccion_monitor = {}

## Intenta comparar la foto del carnet con la cara real del NPC
func _intentar_comparacion_foto() -> void:
	if seleccion_cara_npc.is_empty():
		return
	
	# Necesitamos la foto del carnet
	if npc_actual == null:
		return
	
	var foto_carnet = npc_actual.foto_carnet_path
	var foto_real = seleccion_cara_npc
	
	var coinciden = (foto_carnet == foto_real)
	
	comparaciones_hechas[GlobalEnums.CampoComparacion.FOTO] = \
		GlobalEnums.ResultadoComparacion.COINCIDE if coinciden else GlobalEnums.ResultadoComparacion.NO_COINCIDE
	
	if not coinciden:
		var info = {
			"campo": GlobalEnums.CampoComparacion.FOTO,
			"valor_carnet": foto_carnet,
			"valor_sistema": foto_real,
			"incidencia_inferida": GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE
		}
		discrepancias_encontradas.append(info)
		discrepancia_detectada.emit(
			GlobalEnums.CampoComparacion.FOTO, foto_carnet, foto_real,
			GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE
		)
		print("[COMPARACION] ✗ FOTO NO COINCIDE")
	else:
		comparacion_correcta.emit(GlobalEnums.CampoComparacion.FOTO)
		print("[COMPARACION] ✓ FOTO COINCIDE")
	
	comparacion_foto_resultado.emit(coinciden)
	seleccion_cara_npc = ""

## Infiere qué incidencia podría estar relacionada con una discrepancia en un campo
func _inferir_incidencia(campo: int) -> int:
	var posibles = MAPA_CAMPO_INCIDENCIA.get(campo, [])
	if posibles.is_empty():
		return GlobalEnums.Incidencia.NINGUNA
	# Si el NPC tiene incidencia y está en la lista de posibles, retornar esa
	if npc_actual and npc_actual.incidencia in posibles:
		return npc_actual.incidencia
	# Si no, retornar la primera posible
	return posibles[0]

## Evalúa si la decisión del guardia fue correcta
func evaluar_decision(decision: int) -> Dictionary:
	var npc_tiene_problema = npc_actual.tiene_incidencia() if npc_actual else false
	var decision_correcta: bool = false
	
	match decision:
		GlobalEnums.DecisionGuardia.APROBADO:
			# Correcto si NO tiene incidencia
			decision_correcta = not npc_tiene_problema
		GlobalEnums.DecisionGuardia.RECHAZADO:
			# Correcto si SÍ tiene incidencia
			decision_correcta = npc_tiene_problema
	
	var resultado = {
		"decision": decision,
		"correcta": decision_correcta,
		"incidencia_real": npc_actual.incidencia if npc_actual else GlobalEnums.Incidencia.NINGUNA,
		"discrepancias_encontradas": discrepancias_encontradas.size(),
		"comparaciones_hechas": comparaciones_hechas.size(),
	}
	
	print("[COMPARACION] Decisión: ", "APROBADO" if decision == GlobalEnums.DecisionGuardia.APROBADO else "RECHAZADO",
		" | Correcta: ", decision_correcta,
		" | Incidencia real: ", resultado.incidencia_real)
	
	return resultado

## Retorna la incidencia que el jugador debería haber encontrado (para feedback)
func obtener_incidencia_no_detectada() -> int:
	if npc_actual == null:
		return GlobalEnums.Incidencia.NINGUNA
	if not npc_actual.tiene_incidencia():
		return GlobalEnums.Incidencia.NINGUNA
	# Si la incidencia real no fue detectada en las comparaciones
	for disc in discrepancias_encontradas:
		if disc.get("incidencia_inferida", -1) == npc_actual.incidencia:
			return GlobalEnums.Incidencia.NINGUNA  # Ya la encontró
	return npc_actual.incidencia

# --- HELPERS ---

func _nombre_campo(campo: int) -> String:
	match campo:
		GlobalEnums.CampoComparacion.NOMBRE: return "NOMBRE"
		GlobalEnums.CampoComparacion.APELLIDO: return "APELLIDO"
		GlobalEnums.CampoComparacion.FOTO: return "FOTO"
		GlobalEnums.CampoComparacion.CODIGO_CARNET: return "CÓDIGO CARNET"
		GlobalEnums.CampoComparacion.CARRERA: return "CARRERA"
		GlobalEnums.CampoComparacion.NUMERO_CEDULA: return "NRO CÉDULA"
		GlobalEnums.CampoComparacion.FECHA_EXPIRACION: return "FECHA EXP"
		GlobalEnums.CampoComparacion.CARA_NPC: return "CARA NPC"
	return "DESCONOCIDO"
