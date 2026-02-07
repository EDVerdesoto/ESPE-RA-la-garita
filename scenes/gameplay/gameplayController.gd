## GameplayController: Orquestador principal del flujo de juego estilo Papers Please
## Coordina: NPCs → Carnet → Monitor → Comparaciones → Decisiones → Economía
extends Node

# --- REFERENCIAS DE ESCENA (configurar en editor) ---
@export_group("Nodos Principales")
@export var npc_visual_node: NodePath       ## Nodo NPC visual (Area2D con carnet)
@export var pc_monitor_node: NodePath       ## Nodo PC/Monitor del guardia
@export var dialogue_panel_node: NodePath   ## Panel de diálogo y decisión

@export_group("Configuración")
@export var npcs_por_dia: int = 5
@export var tiempo_por_npc: float = 60.0    ## Segundos antes de timeout

# --- NODOS RESUELTOS ---
var npc_visual: Node = null         # El nodo NPC visual en escena
var pc_monitor: Node = null         # El PC/Monitor  
var dialogue_panel: Node = null     # Panel de diálogos

# --- MANAGERS ---
var comparacion_manager: ComparacionManager = ComparacionManager.new()
var daily_manager: DailyManager = DailyManager.new()

# --- ESTADO ---
var npc_actual: AbstractNPC = null
var timer_npc: Timer = null
var dia_en_curso: bool = false
var esperando_gemini: bool = false

func _ready():
	# Crear timer para tiempo límite por NPC
	timer_npc = Timer.new()
	timer_npc.one_shot = true
	timer_npc.wait_time = tiempo_por_npc
	timer_npc.timeout.connect(_on_tiempo_agotado)
	add_child(timer_npc)
	
	# Add comparacion_manager to tree to avoid orphan leak
	add_child(comparacion_manager)
	
	# NOTE: No llamamos _conectar_senales() ni iniciar_dia() aquí.
	# nivelGarita.gd asigna las referencias de nodos y llama ambos métodos
	# después de configurar npc_visual, pc_monitor y dialogue_panel.
	# Si se usa standalone (sin nivelGarita), resolver desde @export:
	if npc_visual_node and not npc_visual_node.is_empty():
		npc_visual = get_node_or_null(npc_visual_node)
	if pc_monitor_node and not pc_monitor_node.is_empty():
		pc_monitor = get_node_or_null(pc_monitor_node)
	if dialogue_panel_node and not dialogue_panel_node.is_empty():
		dialogue_panel = get_node_or_null(dialogue_panel_node)
	
	# Solo auto-iniciar si las referencias se obtuvieron de @export
	if npc_visual or pc_monitor or dialogue_panel:
		_conectar_senales()
		iniciar_dia()

func _conectar_senales():
	# --- NPC Visual ---
	if npc_visual:
		if npc_visual.has_signal("npc_llego_a_ventanilla"):
			npc_visual.npc_llego_a_ventanilla.connect(_on_npc_llego)
		if npc_visual.has_signal("npc_salio"):
			npc_visual.npc_salio.connect(_on_npc_salio)
		if npc_visual.has_signal("cara_clickeada"):
			npc_visual.cara_clickeada.connect(_on_cara_npc_clickeada)
		if npc_visual.has_signal("carnet_campo_clickeado"):
			npc_visual.carnet_campo_clickeado.connect(_on_carnet_campo_click)
		if npc_visual.has_signal("carnet_escaneado"):
			npc_visual.carnet_escaneado.connect(_on_carnet_escaneado)
	
	# --- Monitor ---
	if pc_monitor:
		if pc_monitor.has_signal("campo_monitor_clickeado"):
			pc_monitor.campo_monitor_clickeado.connect(_on_monitor_campo_click)
	
	# --- Dialogue Panel ---
	if dialogue_panel:
		if dialogue_panel.has_signal("decision_tomada"):
			dialogue_panel.decision_tomada.connect(_on_decision_tomada)
		if dialogue_panel.has_signal("incidencia_reportada"):
			dialogue_panel.incidencia_reportada.connect(_on_incidencia_reportada)
	
	# --- Comparación Manager ---
	comparacion_manager.discrepancia_detectada.connect(_on_discrepancia_detectada)
	comparacion_manager.comparacion_correcta.connect(_on_comparacion_correcta)
	comparacion_manager.comparacion_foto_resultado.connect(_on_foto_comparada)

# =====================================================
# FLUJO PRINCIPAL DEL DÍA
# =====================================================

func iniciar_dia():
	print("=== INICIANDO DÍA ", GlobalGameManager.dia_actual, " ===")
	dia_en_curso = true
	GlobalGameManager.aciertos_hoy = 0
	GlobalGameManager.errores_hoy = 0
	
	# Generar NPCs
	var lista_npcs = daily_manager.generar_npcs_para_hoy(npcs_por_dia)
	GlobalGameManager.npcs_del_dia = lista_npcs
	GlobalGameManager.npc_actual_index = 0
	
	# Solicitar diálogos a Gemini (si está configurado)
	if GeminiManager and GeminiManager.API_KEY and not GeminiManager.API_KEY.is_empty():
		esperando_gemini = true
		if not GeminiManager.batch_completed.is_connected(_on_gemini_completed):
			GeminiManager.batch_completed.connect(_on_gemini_completed)
		if not GeminiManager.error_ocurred.is_connected(_on_gemini_error):
			GeminiManager.error_ocurred.connect(_on_gemini_error)
		GeminiManager.solicitar_dialogos_batch(lista_npcs, "soleado")
	else:
		# Sin Gemini, usar diálogos por defecto
		print("[GAMEPLAY] Sin API de Gemini, usando diálogos por defecto")
		cargar_npc_siguiente()

func _on_gemini_completed(dialogos_array: Array):
	esperando_gemini = false
	var lista_npcs = GlobalGameManager.npcs_del_dia
	for i in range(min(lista_npcs.size(), dialogos_array.size())):
		if dialogos_array[i] is Dictionary:
			lista_npcs[i].dialogos_ia = dialogos_array[i]
	print("[GAMEPLAY] Diálogos de IA cargados")
	cargar_npc_siguiente()

func _on_gemini_error(mensaje: String):
	esperando_gemini = false
	print("[GAMEPLAY] Error de Gemini: ", mensaje, " - continuando sin IA")
	cargar_npc_siguiente()

# =====================================================
# FLUJO DE NPC INDIVIDUAL
# =====================================================

func cargar_npc_siguiente():
	# Limpiar estado anterior
	_limpiar_estado()
	
	if GlobalGameManager.npc_actual_index >= GlobalGameManager.npcs_del_dia.size():
		finalizar_dia()
		return
	
	npc_actual = GlobalGameManager.npcs_del_dia[GlobalGameManager.npc_actual_index]
	GlobalGameManager.npc_actual_index += 1
	
	print("\n--- NPC #", GlobalGameManager.npc_actual_index, ": ", 
		npc_actual.nombre, " ", npc_actual.apellido, 
		" | Incidencia: ", npc_actual.incidencia, " ---")
	
	# Iniciar comparación
	comparacion_manager.iniciar_comparacion(npc_actual)
	
	# Cargar NPC visual (esto inicia la animación de entrada)
	if npc_visual and npc_visual.has_method("cargar_npc"):
		npc_visual.cargar_npc(npc_actual)
	else:
		# Si no hay nodo visual, simular la llegada
		_on_npc_llego(npc_actual)

func _on_npc_llego(npc_data: AbstractNPC):
	print("[GAMEPLAY] NPC llegó a la ventanilla: ", npc_data.nombre)
	
	# Iniciar timer
	timer_npc.start(tiempo_por_npc)
	
	# Configurar panel de diálogo
	if dialogue_panel and dialogue_panel.has_method("configurar_npc"):
		dialogue_panel.configurar_npc(npc_data)

func _on_tiempo_agotado():
	print("[GAMEPLAY] ¡TIEMPO AGOTADO!")
	# El NPC pasa sin revisión - cuenta como error si tenía incidencia
	if npc_actual and npc_actual.tiene_incidencia():
		GlobalGameManager.errores_hoy += 1
		print("[GAMEPLAY] Error: NPC con incidencia pasó sin revisión")
	
	if npc_visual and npc_visual.has_method("forzar_salida"):
		npc_visual.forzar_salida()
	else:
		_on_npc_salio()

# =====================================================
# INTERACCIONES DEL JUGADOR
# =====================================================

## Click en un campo del carnet → registrar en comparación manager
func _on_carnet_campo_click(campo: int, valor: String):
	comparacion_manager.seleccionar_campo_carnet(campo, valor)

## Click en un campo del monitor → registrar en comparación manager
func _on_monitor_campo_click(campo: int, valor: String):
	comparacion_manager.seleccionar_campo_monitor(campo, valor)

## Click en la cara del NPC → comparar foto
func _on_cara_npc_clickeada(foto_real_path: String):
	comparacion_manager.seleccionar_cara_npc(foto_real_path)

## Carnet escaneado (click derecho) → mostrar datos en monitor
func _on_carnet_escaneado(datos_carnet: Dictionary):
	print("[GAMEPLAY] Carnet escaneado, cargando datos del sistema en monitor...")
	if pc_monitor and npc_actual and pc_monitor.has_method("mostrar_datos_sistema"):
		# El monitor muestra los datos del SISTEMA (cédula), no los del carnet
		pc_monitor.mostrar_datos_sistema(npc_actual.datos_sistema)

## Se detectó discrepancia entre carnet y monitor
func _on_discrepancia_detectada(campo: int, val_carnet: String, val_sistema: String, incidencia: int):
	print("[GAMEPLAY] ¡DISCREPANCIA! Campo: ", campo, 
		" | Carnet: ", val_carnet, " vs Sistema: ", val_sistema)
	
	# Resaltar en rojo en el carnet y monitor
	if npc_visual and npc_visual.has_method("get_node"):
		var carnet = npc_visual.get_node_or_null("CarnetVisual")
		if carnet and carnet.has_method("mostrar_resultado"):
			carnet.mostrar_resultado(campo, GlobalEnums.ResultadoComparacion.NO_COINCIDE)
	if pc_monitor and pc_monitor.has_method("mostrar_resultado"):
		pc_monitor.mostrar_resultado(campo, GlobalEnums.ResultadoComparacion.NO_COINCIDE)
	
	# Disparar diálogo de incidencia correcta
	if dialogue_panel and dialogue_panel.has_method("mostrar_dialogo_incidencia_correcta"):
		dialogue_panel.mostrar_dialogo_incidencia_correcta()

## Comparación correcta (campo coincide)
func _on_comparacion_correcta(campo: int):
	# Resaltar en verde
	if npc_visual:
		var carnet = npc_visual.get_node_or_null("CarnetVisual") if npc_visual.has_method("get_node_or_null") else null
		if carnet and carnet.has_method("mostrar_resultado"):
			carnet.mostrar_resultado(campo, GlobalEnums.ResultadoComparacion.COINCIDE)
	if pc_monitor and pc_monitor.has_method("mostrar_resultado"):
		pc_monitor.mostrar_resultado(campo, GlobalEnums.ResultadoComparacion.COINCIDE)

## Resultado de comparación de foto
func _on_foto_comparada(coinciden: bool):
	if not coinciden:
		print("[GAMEPLAY] ¡La foto del carnet NO coincide con la cara real!")
		if dialogue_panel and dialogue_panel.has_method("mostrar_dialogo_incidencia_correcta"):
			dialogue_panel.mostrar_dialogo_incidencia_correcta()

# =====================================================
# DECISIÓN DEL GUARDIA
# =====================================================

func _on_decision_tomada(decision: int):
	timer_npc.stop()
	
	if decision == GlobalEnums.DecisionGuardia.APROBADO:
		_procesar_aprobacion()
	# Rechazado se maneja después de que el jugador seleccione el motivo

func _on_incidencia_reportada(incidencia_reportada: int):
	# El guardia rechaza y reporta una incidencia específica
	_procesar_rechazo(incidencia_reportada)

func _procesar_aprobacion():
	var resultado = comparacion_manager.evaluar_decision(GlobalEnums.DecisionGuardia.APROBADO)
	
	if resultado.correcta:
		GlobalGameManager.aciertos_hoy += 1
	else:
		GlobalGameManager.errores_hoy += 1
	
	# Mostrar feedback
	if dialogue_panel and dialogue_panel.has_method("mostrar_feedback"):
		dialogue_panel.mostrar_feedback(resultado)
	if dialogue_panel and dialogue_panel.has_method("mostrar_dialogo_aprobado"):
		dialogue_panel.mostrar_dialogo_aprobado()
	
	# NPC se va aprobado
	if npc_visual and npc_visual.has_method("aprobar"):
		npc_visual.aprobar()
	else:
		# Sin visual, avanzar directamente
		await get_tree().create_timer(2.0).timeout
		_on_npc_salio()

func _procesar_rechazo(incidencia_reportada: int):
	var resultado = comparacion_manager.evaluar_decision(GlobalEnums.DecisionGuardia.RECHAZADO)
	
	# Verificar si la incidencia reportada es la correcta
	var reporte_correcto = (incidencia_reportada == npc_actual.incidencia) if npc_actual else false
	
	if resultado.correcta and reporte_correcto:
		GlobalGameManager.aciertos_hoy += 1
		resultado["correcta"] = true
	elif resultado.correcta and not reporte_correcto:
		# Rechazó correctamente pero motivo equivocado - medio punto
		GlobalGameManager.aciertos_hoy += 1
		resultado["correcta"] = true
		print("[GAMEPLAY] Rechazo correcto pero motivo inexacto")
	else:
		GlobalGameManager.errores_hoy += 1
		resultado["correcta"] = false
	
	if dialogue_panel and dialogue_panel.has_method("mostrar_feedback"):
		dialogue_panel.mostrar_feedback(resultado)
	if dialogue_panel and dialogue_panel.has_method("mostrar_dialogo_rechazado"):
		dialogue_panel.mostrar_dialogo_rechazado()
	
	if npc_visual and npc_visual.has_method("rechazar"):
		npc_visual.rechazar()
	else:
		await get_tree().create_timer(2.0).timeout
		_on_npc_salio()

# =====================================================
# TRANSICIONES
# =====================================================

func _on_npc_salio():
	print("[GAMEPLAY] NPC salió de escena")
	# Esperar un momento antes del siguiente
	await get_tree().create_timer(1.5).timeout
	cargar_npc_siguiente()

func finalizar_dia():
	dia_en_curso = false
	print("\n========== FIN DEL DÍA ", GlobalGameManager.dia_actual, " ==========")
	print("Aciertos: ", GlobalGameManager.aciertos_hoy)
	print("Errores: ", GlobalGameManager.errores_hoy)
	GlobalGameManager.calcular_fin_de_dia()

func _limpiar_estado():
	timer_npc.stop()
	comparacion_manager.resetear()
	
	if pc_monitor and pc_monitor.has_method("resetear"):
		pc_monitor.resetear()
	if npc_visual and npc_visual.has_method("resetear"):
		npc_visual.resetear()
	if dialogue_panel and dialogue_panel.has_method("ocultar_todo"):
		dialogue_panel.ocultar_todo()
