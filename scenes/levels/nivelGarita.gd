## NivelGarita: Escena principal del juego
## Contiene el mundo visual + gameplay controller + UI overlay
extends Node

# CORRECCIÓN 1: Usamos preload. Esto ya guarda la ESCENA en la variable, no la ruta.
var escena_pausa = preload("res://scenes/ui/menus/menuPausa.tscn")
var escena_reglas = preload("res://scenes/ui/ReglasDia.tscn")

@onready var gameplay_controller = $GameplayController
@onready var npc_node = $Npc
@onready var pc_monitor = $Pc
@onready var ui = $UI
@onready var carpeta = $CarpetaDocumentos
@onready var boton_alarma: TextureButton = $BotonAlarma
@onready var guardia1 = $Guardia1
@onready var guardia2 = $Guardia2

var reglas_visibles: bool = false
var guardias_en_npc: int = 0        ## Contador de guardias que llegaron al NPC
var alarma_activada: bool = false    ## Evita activar la alarma dos veces
var guardias_fuera: int = 0         ## Contador de guardias que salieron de escena

func _ready():
	print("=== NIVEL GARITA CARGADO ===")
	
	if gameplay_controller:
		gameplay_controller.npc_visual = npc_node
		gameplay_controller.pc_monitor = pc_monitor
		gameplay_controller.dialogue_panel = ui
		gameplay_controller._conectar_senales()
		
		# Conectar señal de fin de día → mostrar reporte
		if not gameplay_controller.dia_finalizado.is_connected(_on_dia_finalizado):
			gameplay_controller.dia_finalizado.connect(_on_dia_finalizado)
		
		gameplay_controller.iniciar_dia()
	
	# Conectar señal de cierre de reporte
	if ui and ui.has_signal("reporte_fin_dia_cerrado"):
		if not ui.reporte_fin_dia_cerrado.is_connected(_on_reporte_cerrado):
			ui.reporte_fin_dia_cerrado.connect(_on_reporte_cerrado)
	# Conectar señal de carpeta para abrir reglas del día
	if carpeta:
		carpeta.carpeta_abierta.connect(_on_carpeta_abierta)
	
	# --- ALARMA Y GUARDIAS ---
	if boton_alarma:
		boton_alarma.pressed.connect(_on_alarma_presionada)
	
	if guardia1:
		guardia1.guardia_llego_a_npc.connect(_on_guardia_llego_a_npc)
		guardia1.guardia_salio_de_escena.connect(_on_guardia_salio_de_escena)
	if guardia2:
		guardia2.guardia_llego_a_npc.connect(_on_guardia_llego_a_npc)
		guardia2.guardia_salio_de_escena.connect(_on_guardia_salio_de_escena)
	
	_actualizar_hud()

func _process(_delta):
	_actualizar_hud()

func _actualizar_hud():
	if ui and ui.has_method("actualizar"):
		var tiempo_restante = -1.0
		if gameplay_controller and gameplay_controller.timer_npc and not gameplay_controller.timer_npc.is_stopped():
			tiempo_restante = gameplay_controller.timer_npc.time_left
		ui.actualizar({
			"dia": GlobalGameManager.dia_actual,
			"dinero": GlobalGameManager.dinero,
			"aciertos": GlobalGameManager.aciertos_hoy,
			"errores": GlobalGameManager.errores_hoy,
			"tiempo": tiempo_restante,
		})

# Detectar tecla ESC
func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pausa"):
		# Solo pausamos si NO está pausado ya
		if not get_tree().paused:
			pausar_juego()

# CORRECCIÓN 2: Lógica limpia
func pausar_juego():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if escena_pausa:
		var menu_instance = escena_pausa.instantiate()
		
		# Envolvemos en un CanvasLayer para que se renderice ENCIMA del UI
		# (UI es un CanvasLayer en layer 1, así que usamos layer 110)
		var overlay = CanvasLayer.new()
		overlay.layer = 110
		add_child(overlay)
		overlay.add_child(menu_instance)
		
		# Cuando el menú se destruya (queue_free), destruir el overlay también
		menu_instance.tree_exited.connect(overlay.queue_free)
		
		# CONGELAMOS EL TIEMPO
		get_tree().paused = true
		print("Juego Pausado")
	else:
		print("Error: No se cargó la escena de pausa")

# =====================================================
# FIN DE DÍA → REPORTE → NUEVO DÍA
# =====================================================

## Cuando el GameplayController termina todos los NPCs del día
func _on_dia_finalizado(resumen: Dictionary):
	print("[NIVEL] Día finalizado, mostrando reporte...")
	if ui and ui.has_method("mostrar_reporte_fin_de_dia"):
		ui.mostrar_reporte_fin_de_dia(resumen)

## Cuando el jugador cierra el reporte de fin de día
func _on_reporte_cerrado():
	print("[NIVEL] Reporte cerrado, preparando nuevo día...")
	GlobalGameManager.confirmar_fin_de_dia()
	
	# Iniciar nuevo día
	if gameplay_controller:
		gameplay_controller.iniciar_dia()
	_actualizar_hud()
	
# --- CARPETA DE REGLAS ---
func _on_carpeta_abierta():
	if reglas_visibles:
		return
	reglas_visibles = true
	var reglas_instance = escena_reglas.instantiate()
	add_child(reglas_instance)
	# Cuando se cierre (clic en cualquier lugar), actualizar estado
	reglas_instance.tree_exited.connect(func():
		reglas_visibles = false
		if carpeta:
			carpeta.esta_abierta = false
	)

# =====================================================
# SISTEMA DE ALARMA Y GUARDIAS MILITARES
# =====================================================

## El jugador presiona el botón de alarma
func _on_alarma_presionada():
	if alarma_activada:
		return
	
	# Solo activar si hay un NPC visible en la escena
	if not npc_node or not npc_node.visible:
		print("[ALARMA] No hay NPC en escena para aprehender")
		return
	
	# Permite alarma si el NPC está visible: ventanilla, saliendo, o atacante
	var estados_validos = [
		npc_node.State.EN_VENTANILLA,
		npc_node.State.SALIENDO_APROBADO,
		npc_node.State.SALIENDO_RECHAZADO,
		npc_node.State.ATACANTE_CORRIENDO,
		npc_node.State.ATACANTE_DETENIDO,
		npc_node.State.ENTRANDO,
	]
	if npc_node.estado_actual not in estados_validos:
		print("[ALARMA] El NPC no está en posición para ser aprehendido")
		return
	
	alarma_activada = true
	guardias_en_npc = 0
	guardias_fuera = 0
	print("[ALARMA] ¡¡¡ALARMA ACTIVADA!!! Enviando guardias...")
	
	# Pausar el timer del gameplay para que no cuente tiempo mientras la aprehensión
	if gameplay_controller and gameplay_controller.timer_npc:
		gameplay_controller.timer_npc.stop()
	
	# Activar ambos guardias para que corran hacia el NPC
	if guardia1:
		guardia1.activar_alarma(npc_node)
	if guardia2:
		guardia2.activar_alarma(npc_node)

## Un guardia llegó al NPC (se llama por cada guardia)
func _on_guardia_llego_a_npc():
	guardias_en_npc += 1
	print("[ALARMA] Guardia llegó al NPC (", guardias_en_npc, "/2)")
	
	# Cuando el PRIMER guardia llega, detener al NPC para que no siga caminando
	if guardias_en_npc == 1 and npc_node:
		npc_node.estado_actual = npc_node.State.ESPERANDO
		print("[ALARMA] NPC detenido por el primer guardia")
	
	# Cuando AMBOS guardias llegan, iniciar aprehensión del NPC
	if guardias_en_npc >= 2:
		_iniciar_aprehension()

## Inicia la secuencia de aprehensión
func _iniciar_aprehension():
	print("[ALARMA] ¡Ambos guardias en posición! Iniciando aprehensión...")
	
	# Esperar un momento para que se vea los guardias llegando
	await get_tree().create_timer(0.8).timeout
	
	# Ocultar los guardias ANTES de cambiar al sprite de aprehensión
	# (el sprite de aprehensión ya incluye a los militares llevándose al NPC)
	if guardia1:
		guardia1.visible = false
	if guardia2:
		guardia2.visible = false
	
	# Cambiar el sprite del NPC al de aprehensión (incluye militares en la imagen)
	if npc_node and npc_node.has_method("aprehender"):
		npc_node.aprehender()
	
	# Emitir señales de salida de guardias directamente (ya están ocultos)
	_guardias_ocultos_tras_aprehension()

## Los guardias se ocultan tras la aprehensión (ya no se mueven visiblemente)
func _guardias_ocultos_tras_aprehension():
	print("[ALARMA] Guardias ocultos. NPC con sprite de aprehensión caminando...")
	# Resetear estado de alarma y guardias
	alarma_activada = false
	guardias_en_npc = 0
	guardias_fuera = 0
	
	if guardia1:
		guardia1.resetear()
	if guardia2:
		guardia2.resetear()

## Un guardia salió de escena (fallback, por si se usa salir_de_escena)
func _on_guardia_salio_de_escena():
	guardias_fuera += 1
	print("[ALARMA] Guardia salió de escena (", guardias_fuera, "/2)")
