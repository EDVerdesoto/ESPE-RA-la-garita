## NivelGarita: Escena principal del juego
## Contiene el mundo visual + gameplay controller + UI overlay
## Este script inicializa y conecta todos los subsistemas
extends Node

@onready var gameplay_controller = $GameplayController
@onready var npc_node = $World/NpcVisual
@onready var pc_monitor = $World/DeskObjects/PC
@onready var dialogue_panel = $UI/DialoguePanel
@onready var hud_overlay = $UI/HudOverlay

func _ready():
	print("=== NIVEL GARITA CARGADO ===")
	
	# Configurar el gameplay controller con las referencias de escena
	if gameplay_controller:
		gameplay_controller.npc_visual = npc_node
		gameplay_controller.pc_monitor = pc_monitor
		gameplay_controller.dialogue_panel = dialogue_panel
		
		# Reconectar señales ahora que tenemos las referencias
		gameplay_controller._conectar_senales()
		
		# Iniciar el día
		gameplay_controller.iniciar_dia()
	
	# Configurar HUD
	_actualizar_hud()

func _process(_delta):
	_actualizar_hud()

func _actualizar_hud():
	if hud_overlay and hud_overlay.has_method("actualizar"):
		hud_overlay.actualizar({
			"dia": GlobalGameManager.dia_actual,
			"dinero": GlobalGameManager.dinero,
			"aciertos": GlobalGameManager.aciertos_hoy,
			"errores": GlobalGameManager.errores_hoy,
		})
