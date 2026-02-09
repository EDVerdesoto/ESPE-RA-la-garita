## NivelGarita: Escena principal del juego
## Contiene el mundo visual + gameplay controller + UI overlay
extends Node

# CORRECCIÓN 1: Usamos preload. Esto ya guarda la ESCENA en la variable, no la ruta.
var escena_pausa = preload("res://scenes/ui/menus/menuPausa.tscn")

@onready var gameplay_controller = $GameplayController
@onready var npc_node = $Npc
@onready var pc_monitor = $Pc
@onready var ui = $UI

func _ready():
	print("=== NIVEL GARITA CARGADO ===")
	
	if gameplay_controller:
		gameplay_controller.npc_visual = npc_node
		gameplay_controller.pc_monitor = pc_monitor
		gameplay_controller.dialogue_panel = dialogue_panel
		gameplay_controller._conectar_senales()
		gameplay_controller.iniciar_dia()
	
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
		# Instanciamos directo de la variable (porque ya hicimos preload arriba)
		var menu_instance = escena_pausa.instantiate()
		
		# Añadimos al HUD (Para que quede encima de todo y fijo en pantalla)
		if hud_overlay:
			hud_overlay.add_child(menu_instance)
		else:
			# Por si acaso no tengas HUD, lo ponemos directo al nivel
			add_child(menu_instance)
		
		# CONGELAMOS EL TIEMPO
		get_tree().paused = true
		print("Juego Pausado")
	else:
		print("Error: No se cargó la escena de pausa")
