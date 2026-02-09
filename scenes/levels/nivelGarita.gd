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

var reglas_visibles: bool = false

func _ready():
	print("=== NIVEL GARITA CARGADO ===")
	
	if gameplay_controller:
		gameplay_controller.npc_visual = npc_node
		gameplay_controller.pc_monitor = pc_monitor
		gameplay_controller.dialogue_panel = ui
		gameplay_controller._conectar_senales()
		gameplay_controller.iniciar_dia()
	
	# Conectar señal de carpeta para abrir reglas del día
	if carpeta:
		carpeta.carpeta_abierta.connect(_on_carpeta_abierta)
	
	_actualizar_hud()

func _process(_delta):
	_actualizar_hud()

func _actualizar_hud():
	if ui and ui.has_method("actualizar"):
		ui.actualizar({
			"dia": GlobalGameManager.dia_actual,
			"dinero": GlobalGameManager.dinero,
			"aciertos": GlobalGameManager.aciertos_hoy,
			"errores": GlobalGameManager.errores_hoy,
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
