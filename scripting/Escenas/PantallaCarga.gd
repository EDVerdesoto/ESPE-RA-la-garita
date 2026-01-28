extends Control

# Configuración
# Para el MVP - reducido a 3 para pruebas más rápidas
const NPCS_POR_DIA = 3
# Procesar de 3 en 3 para no saturar
const BATCH_SIZE = 3

var daily_manager = DailyManager.new()
# Lista temporal
var raw_npcs = []
var procesados_count = 0

# Pon un Label en tu escena
@onready var label_estado = $LabelEstado
# Pon una barra
@onready var barra = $ProgressBar

# Flag para modo sin IA (para testing)
var MODO_SIN_IA = false  # Cambiar a false cuando tengas API key de Gemini

func _ready():
	start_dia_process()

func start_dia_process():
	label_estado.text = "Consultando base de datos..."
	
	# 1. Limpiar día anterior
	GlobalGameManager.iniciar_nuevo_dia()
	
	# 2. Obtener NPCs lógicos (sin dialogo aún)
	raw_npcs = daily_manager.preparar_npcs_para_hoy(NPCS_POR_DIA)
	
	# 3. Empezar a pedir diálogos a Gemini por lotes
	_procesar_siguiente_lote()

func _procesar_siguiente_lote():
	if procesados_count >= raw_npcs.size():
		_finalizar_carga()
		return
	
	label_estado.text = "Generando personalidades con IA..."
	
	# Modo sin IA para testing rápido
	if MODO_SIN_IA:
		# Simular diálogos básicos sin llamar a Gemini
		var fin = min(procesados_count + BATCH_SIZE, raw_npcs.size())
		var lote = raw_npcs.slice(procesados_count, fin)
		
		for npc in lote:
			npc.dialogos = {
				"saludo_inicial": "Hola, soy %s y vengo a %s." % [npc.nombre, npc.carrera],
				"respuesta_decision": "Gracias por procesar mi entrada."
			}
		
		procesados_count += lote.size()
		barra.value = (float(procesados_count) / NPCS_POR_DIA) * 100
		
		# Recursividad: Siguiente lote
		await get_tree().create_timer(0.5).timeout  # Simular delay de red
		_procesar_siguiente_lote()
		return
	
	# Modo con IA (requiere API key)
	# Cortar el lote actual (ej: del 0 al 3)
	var fin = min(procesados_count + BATCH_SIZE, raw_npcs.size())
	var lote = raw_npcs.slice(procesados_count, fin)
	
	# LLAMADA A TU SCRIPT DE GEMINI (adaptado a lotes)
	# Nota: Pasamos el clima actual del GlobalManager para que influya
	GeminiManager.solicitar_dialogos_batch(lote, GlobalGameManager.clima_actual)
	
	# Esperar señal (Asegúrate que GeminiManager emita 'batch_completed' con la data)
	if not GeminiManager.is_connected("batch_completed", _on_gemini_batch_ready):
		GeminiManager.batch_completed.connect(_on_gemini_batch_ready, CONNECT_ONE_SHOT)

func _on_gemini_batch_ready(dialogos_json_array: Array):
	# Pegar los diálogos recibidos a los objetos NPC
	for i in range(dialogos_json_array.size()):
		var dialogo = dialogos_json_array[i]
		# Asumiendo que el orden se mantiene (Gemini es ordenado si el prompt es bueno)
		var npc = raw_npcs[procesados_count + i]
		npc.dialogos = dialogo # ¡Aquí guardamos el JSON complejo!
		
	procesados_count += dialogos_json_array.size()
	barra.value = (float(procesados_count) / NPCS_POR_DIA) * 100
	
	# Recursividad: Siguiente lote
	_procesar_siguiente_lote()

func _finalizar_carga():
	label_estado.text = "¡Todo listo!"
	
	# Guardar la lista final completa en el Global
	GlobalGameManager.npcs_del_dia = raw_npcs
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://escenas/mesa principal.tscn")
