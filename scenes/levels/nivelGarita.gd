## NivelGarita: Escena principal del juego
## Contiene el mundo visual + gameplay controller + UI overlay
## Este script inicializa y conecta todos los subsistemas
extends Node

@onready var gameplay_controller = $GameplayController
@onready var npc_node = $Npc
@onready var pc_monitor = $Pc
@onready var ui = $UI

func _ready():
	print("=== NIVEL GARITA CARGADO ===")
	
	# Configurar el gameplay controller con las referencias de escena
	if gameplay_controller:
		gameplay_controller.npc_visual = npc_node
		gameplay_controller.pc_monitor = pc_monitor
		gameplay_controller.dialogue_panel = ui
		
		# Reconectar señales ahora que tenemos las referencias
		gameplay_controller._conectar_senales()
		
		# Iniciar el día
		gameplay_controller.iniciar_dia()
	
	# Configurar HUD
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
